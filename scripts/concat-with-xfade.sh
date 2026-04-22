#!/usr/bin/env bash
# concat-with-xfade.sh — ffmpeg xfade concat of multiple mp4s into one.
# Normalizes inputs to a common resolution and ensures every input has an audio
# track (injecting silence if needed) so the filtergraph doesn't break when
# different upstream models produce different specs.
#
# Usage: concat-with-xfade.sh <output.mp4> <xfade-seconds> <input1.mp4> [<input2.mp4> ...]

set -euo pipefail

OUT="$1"; shift
XFADE="$1"; shift
INPUTS=("$@")

[ "${#INPUTS[@]}" -ge 1 ] || { echo "✗ No input files" >&2; exit 1; }

# Single input — just copy, no concat required
if [ "${#INPUTS[@]}" -eq 1 ]; then
  cp "${INPUTS[0]}" "$OUT"
  echo "✓ Single beat, copied to $OUT"
  exit 0
fi

# Determine target resolution: use the most common (or first) width x height
# This keeps things deterministic when inputs mix tiers (e.g. 720p + 1080p clips).
target_w=0
target_h=0
for f in "${INPUTS[@]}"; do
  w=$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=p=0 "$f")
  h=$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=p=0 "$f")
  # pick the largest (avoids upscaling 1080p → 720p which loses quality)
  if [ "$w" -gt "$target_w" ]; then
    target_w=$w
    target_h=$h
  fi
done
echo "→ Normalizing to ${target_w}x${target_h}"

# Pre-process each input into a normalized temp mp4:
#   • scale + pad to target resolution
#   • guarantee an audio track (silent AAC if missing)
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# Determine the source framerate of the first input; use that across inputs
# so we don't force a 30fps interpolation where the model produced 24fps.
# Falls back to 24 if the probe can't read the rate.
src_fps_raw=$(ffprobe -v error -select_streams v:0 -show_entries stream=r_frame_rate -of csv=p=0 "${INPUTS[0]}")
target_fps=$(python3 -c "
raw = '$src_fps_raw'.strip()
if '/' in raw:
  n, d = raw.split('/')
  try:
    v = float(n) / float(d) if float(d) else 24.0
  except Exception:
    v = 24.0
else:
  try:
    v = float(raw)
  except Exception:
    v = 24.0
# round to sensible integer when close
if abs(v - round(v)) < 0.05:
  print(int(round(v)))
else:
  print(v)
")
echo "→ Target framerate: ${target_fps} fps"

normalized=()
durations=()
for i in "${!INPUTS[@]}"; do
  src="${INPUTS[$i]}"
  dst="${TMPDIR}/norm-${i}.mp4"

  has_audio=$(ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$src" | head -1)

  if [ -n "$has_audio" ]; then
    # Has audio — re-encode video to target res, keep audio
    ffmpeg -y -hide_banner -loglevel error \
      -i "$src" \
      -vf "scale=w=${target_w}:h=${target_h}:force_original_aspect_ratio=decrease,pad=${target_w}:${target_h}:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1,fps=${target_fps}" \
      -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p \
      -c:a aac -b:a 192k -ar 48000 \
      "$dst"
  else
    # No audio — inject silent audio track matching video duration
    ffmpeg -y -hide_banner -loglevel error \
      -i "$src" \
      -f lavfi -i "anullsrc=channel_layout=stereo:sample_rate=48000" \
      -vf "scale=w=${target_w}:h=${target_h}:force_original_aspect_ratio=decrease,pad=${target_w}:${target_h}:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1,fps=${target_fps}" \
      -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p \
      -c:a aac -b:a 192k \
      -shortest \
      "$dst"
  fi

  normalized+=("$dst")
  d=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$dst")
  durations+=("$d")
done

# Build ffmpeg xfade + acrossfade filtergraph on normalized inputs
input_args=()
for f in "${normalized[@]}"; do input_args+=(-i "$f"); done

filter=""
prev_v="[0:v]"
prev_a="[0:a]"
cumulative=${durations[0]}

for i in $(seq 1 $((${#normalized[@]} - 1))); do
  offset=$(python3 -c "print(max(0, ${cumulative} - ${XFADE}))")
  out_v="[v${i}]"
  out_a="[a${i}]"
  filter+="${prev_v}[${i}:v]xfade=transition=fade:duration=${XFADE}:offset=${offset}${out_v};"
  filter+="${prev_a}[${i}:a]acrossfade=d=${XFADE}${out_a};"
  prev_v="$out_v"
  prev_a="$out_a"
  cumulative=$(python3 -c "print(${cumulative} + ${durations[$i]} - ${XFADE})")
done

filter="${filter%;}"

echo "→ Concatenating ${#normalized[@]} beats with ${XFADE}s xfade → $OUT"
ffmpeg -y -hide_banner -loglevel error \
  "${input_args[@]}" \
  -filter_complex "$filter" \
  -map "$prev_v" -map "$prev_a" \
  -c:v libx264 -pix_fmt yuv420p -preset medium -crf 18 \
  -c:a aac -b:a 192k \
  -movflags +faststart \
  "$OUT"

echo "✓ $OUT"
