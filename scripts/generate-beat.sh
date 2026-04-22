#!/usr/bin/env bash
# generate-beat.sh — composite scene + TTS (if dialog) + video for one beat
# Usage: scripts/generate-beat.sh <project-dir> <scenario-json-path> <beat-id>
# Atomic: writes beat.mp4 + metadata.json into beats/<beat-id>/
# Resume-safe: skips steps that already produced outputs.
#
# HARD RULE: every video call must have at least one -i ref. T2V forbidden.

set -euo pipefail

PROJECT_DIR="$1"
SCENARIO="$2"     # e.g. scenario.json or episodes/e01-x/scenario.json
BEAT_ID="$3"

cd "$PROJECT_DIR"

[ -f "$SCENARIO" ] || { echo "✗ $SCENARIO not found" >&2; exit 1; }
SCENARIO_DIR=$(dirname "$SCENARIO")
BEAT=$(jq --arg id "$BEAT_ID" '.beats[] | select(.id == $id)' "$SCENARIO")
[ -n "$BEAT" ] || { echo "✗ Beat $BEAT_ID not in $SCENARIO" >&2; exit 1; }

BEAT_DIR="${SCENARIO_DIR}/beats/${BEAT_ID}"
mkdir -p "$BEAT_DIR"

# If the final beat.mp4 exists AND metadata.json looks complete, skip entirely.
if [ -f "${BEAT_DIR}/beat.mp4" ] && [ -f "${BEAT_DIR}/metadata.json" ]; then
  echo "↷ $BEAT_ID already complete, skipping"
  exit 0
fi

# ── 1. Composite the scene image (char + loc + props → one image) ──────────
COMPOSITE_IMG="${BEAT_DIR}/composite.png"
composite_url=""

if [ ! -f "$COMPOSITE_IMG" ]; then
  refs_args=()

  # Character refs
  for c in $(jq -r '.references.images[]' <<< "$BEAT"); do
    ref_path="characters/${c}/turnaround.png"
    [ -f "$ref_path" ] || { echo "✗ Missing canonical: $ref_path" >&2; exit 1; }
    refs_args+=(-i "$ref_path")
  done

  # Location refs
  for l in $(jq -r '.references.locations[]' <<< "$BEAT"); do
    ref_path="locations/${l}.png"
    [ -f "$ref_path" ] || { echo "✗ Missing location plate: $ref_path" >&2; exit 1; }
    refs_args+=(-i "$ref_path")
  done

  # Prop refs (optional)
  for p in $(jq -r '.references.props // [] | .[]' <<< "$BEAT"); do
    ref_path="props/${p}.png"
    [ -f "$ref_path" ] && refs_args+=(-i "$ref_path")
  done

  # HARD RULE: need at least one reference
  [ "${#refs_args[@]}" -gt 0 ] || {
    echo "✗ Beat $BEAT_ID has zero reference images — T2V forbidden." >&2; exit 1;
  }

  aspect=$(jq -r '.aspectRatio' project.json)
  description=$(jq -r '.description' <<< "$BEAT")
  beat_prompt=$(jq -r '.prompt' <<< "$BEAT")

  # Composite prompt = still-image description derived from the beat description + first-frame framing
  composite_prompt="A cinematic still image composing the following characters and location into a single scene. Scene: ${description}. Composition derived from this shot description: ${beat_prompt}. Render as a still frame suitable as the opening moment of the shot. Lock character identity exactly to the reference images provided. Match the aspect ratio exactly."

  echo "→ $BEAT_ID: compositing scene image..."
  composite_url=$(timeout 300 gen-ai generate \
    -m gemini-3.1-flash-image \
    "${refs_args[@]}" \
    -p "$composite_prompt" \
    --aspect-ratio "$aspect" \
    --script 2>/dev/null | jq -r .url)

  [ -n "$composite_url" ] && [ "$composite_url" != "null" ] || { echo "✗ Composite failed for $BEAT_ID" >&2; exit 1; }
  curl -sL "$composite_url" -o "$COMPOSITE_IMG"
fi

# ── 2. TTS audio (dialog beats only) ───────────────────────────────────────
AUDIO_PATH=""
audio_url=""
audio_flag=()
dialog=$(jq -r '.dialog // empty' <<< "$BEAT")

if [ -n "$dialog" ] && [ "$dialog" != "null" ]; then
  AUDIO_PATH="${BEAT_DIR}/audio.wav"
  if [ ! -f "$AUDIO_PATH" ]; then
    speaker=$(jq -r '.speaker' <<< "$dialog")
    text=$(jq -r '.text' <<< "$dialog")
    # HARD RULE: voiceId must be set in the character bible. Silent fallback to
    # a generic voice destroys voice consistency across projects. If you hit
    # this error, open references/voice-tuning.md and pick a voiceId from the
    # library for this character's archetype.
    voice_id=$(jq -r '.voiceConfig.voiceId // ""' "characters/${speaker}/bible.json")
    [ -n "$voice_id" ] && [ "$voice_id" != "null" ] || {
      echo "✗ Character '${speaker}' bible has null voiceId. Fill it from references/voice-tuning.md before generating dialog beats." >&2
      exit 1
    }

    echo "→ $BEAT_ID: generating TTS (${speaker} via voice ${voice_id})..."
    audio_url=$(timeout 180 gen-ai generate \
      -m eleven-v3 \
      -p "$text" \
      --voice "$voice_id" \
      --script 2>/dev/null | jq -r .url)

    [ -n "$audio_url" ] && [ "$audio_url" != "null" ] || { echo "✗ TTS failed for $BEAT_ID" >&2; exit 1; }
    curl -sL "$audio_url" -o "$AUDIO_PATH"
  fi
fi

# ── 3. Video generation ────────────────────────────────────────────────────
BEAT_MP4="${BEAT_DIR}/beat.mp4"

if [ ! -f "$BEAT_MP4" ]; then
  # Composite is the primary ref (scene + identity baked by Nano Banana 2).
  video_refs=(-i "$COMPOSITE_IMG")

  # Extra identity + location refs for multi-image models (kling-omni):
  # char turnarounds for stronger identity preservation, location plates for scene lock.
  char_refs=()
  for c in $(jq -r '.references.images[]' <<< "$BEAT"); do
    if [ -f "characters/${c}/turnaround.png" ]; then
      char_refs+=(-i "characters/${c}/turnaround.png")
    fi
  done

  loc_refs=()
  for l in $(jq -r '.references.locations[]' <<< "$BEAT"); do
    if [ -f "locations/${l}.png" ]; then
      loc_refs+=(-i "locations/${l}.png")
    fi
  done

  [ -f "$AUDIO_PATH" ] && audio_flag=(--audio "$AUDIO_PATH")

  duration=$(jq -r '.duration' <<< "$BEAT")
  aspect=$(jq -r '.aspectRatio' project.json)
  motion_prompt=$(jq -r '.prompt' <<< "$BEAT")

  # Helper: call gen-ai and capture URL without aborting on pipefail.
  # --generate-audio always on: the model synthesises scene-matching ambient
  # (rain, footsteps, room tone). For dialog beats, --audio <tts> is passed so
  # kling-3.0-pro can natively lip-sync to the TTS instead of us overlaying it.
  _try_kling_3_pro() {
    local out
    set +e
    out=$(timeout 300 gen-ai generate \
      -m kling-3.0-pro \
      "${video_refs[@]}" \
      -p "$motion_prompt" \
      -d "$duration" \
      --aspect-ratio "$aspect" \
      --resolution "1080p" \
      --generate-audio \
      --script 2>/dev/null | jq -r '.url // empty' 2>/dev/null)
    set -e
    [ -n "$out" ] && [ "$out" != "null" ] && echo "$out"
  }

  # kling-omni durations: 3, 5, 8, 10, 12, 15 — clamp to nearest
  _kling_dur() {
    case "$1" in
      1|2|3) echo 3 ;;
      4|5)   echo 5 ;;
      6|7|8) echo 8 ;;
      9|10)  echo 10 ;;
      11|12) echo 12 ;;
      *)     echo 15 ;;
    esac
  }

  beat_type=$(jq -r '.type' <<< "$BEAT")
  video_url=""
  model_used=""

  # ROUTING — dialog beats use kling-avatar for proper lip-sync (image + TTS →
  # mouth matched to speech phonemes). Non-dialog beats use kling-3.0-pro
  # primary (1 image + native ambient), falling to kling-omni (multi-ref,
  # silent → kling-v2a ambient).

  if [ "$beat_type" = "dialog" ] && [ -f "$AUDIO_PATH" ]; then
    # DIALOG BEAT — kling-avatar: image + TTS → lip-synced talking head.
    # This is the only model on the Picsart CLI that produces matched
    # mouth motion to speech. Output includes the TTS baked into audio,
    # so no further TTS mix step is needed.
    echo "→ $BEAT_ID: DIALOG BEAT — trying kling-avatar (image + TTS → lip-sync)..."
    set +e
    video_url=$(timeout 420 gen-ai generate \
      -m kling-avatar \
      -i "$COMPOSITE_IMG" \
      --audio "$AUDIO_PATH" \
      -p "$motion_prompt" \
      --script 2>/dev/null | jq -r '.url // empty' 2>/dev/null)
    set -e
    [ -n "$video_url" ] && [ "$video_url" != "null" ] && model_used="kling-avatar" || video_url=""

    # Fallback for dialog if kling-avatar fails: kling-omni (will not be
    # lip-synced but at least preserves identity via multi-ref; TTS will
    # be mixed post-hoc below — expect voice-over feel).
    if [ -z "$video_url" ]; then
      kdur=$(_kling_dur "$duration")
      echo "  ↳ kling-avatar didn't produce, falling back to kling-omni (${kdur}s) — WARNING: no lip-sync..."
      set +e
      video_url=$(gen-ai generate \
        -m kling-omni \
        "${video_refs[@]}" \
        ${char_refs[@]+"${char_refs[@]}"} \
        ${loc_refs[@]+"${loc_refs[@]}"} \
        ${audio_flag[@]+"${audio_flag[@]}"} \
        -p "$motion_prompt" \
        -d "$kdur" \
        --aspect-ratio "$aspect" \
        --resolution "1080p" \
        --generate-audio \
        --script 2>/dev/null | jq -r '.url // empty' 2>/dev/null)
      set -e
      [ -n "$video_url" ] && [ "$video_url" != "null" ] && model_used="kling-omni" || video_url=""
    fi
  else
    # NON-DIALOG BEAT — kling-3.0-pro primary, kling-omni fallback
    echo "→ $BEAT_ID: trying kling-3.0-pro (${duration}s)..."
    video_url=$(_try_kling_3_pro || true)
    [ -n "$video_url" ] && model_used="kling-3.0-pro"

    if [ -z "$video_url" ]; then
      kdur=$(_kling_dur "$duration")
      n_extra=$(( ${#char_refs[@]} / 2 + ${#loc_refs[@]} / 2 ))
      echo "  ↳ kling-3.0-pro didn't produce, trying kling-omni (${kdur}s) with composite + ${n_extra} extra refs..."
      set +e
      video_url=$(gen-ai generate \
        -m kling-omni \
        "${video_refs[@]}" \
        ${char_refs[@]+"${char_refs[@]}"} \
        ${loc_refs[@]+"${loc_refs[@]}"} \
        ${audio_flag[@]+"${audio_flag[@]}"} \
        -p "$motion_prompt" \
        -d "$kdur" \
        --aspect-ratio "$aspect" \
        --resolution "1080p" \
        --generate-audio \
        --script 2>/dev/null | jq -r '.url // empty' 2>/dev/null)
      set -e
      [ -n "$video_url" ] && [ "$video_url" != "null" ] && model_used="kling-omni" || video_url=""
    fi
  fi

  [ -n "$video_url" ] && [ "$video_url" != "null" ] || { echo "✗ All video models failed for $BEAT_ID" >&2; exit 1; }
  echo "  ✓ ${model_used} produced the beat"
  curl -sL "$video_url" -o "$BEAT_MP4"

  # If the generated video has no audio track (kling-omni's output is silent because
  # --generate-audio is ignored), run it through kling-v2a to synthesize matching
  # scene audio from the video frames + the motion prompt. This keeps audio native
  # to the scene — not a voice-over.
  has_video_audio=$(ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$BEAT_MP4" | head -1)
  if [ -z "$has_video_audio" ]; then
    echo "  → ${model_used} produced silent video; generating ambient via kling-v2a..."
    set +e
    ambient_url=$(timeout 300 gen-ai generate -m kling-v2a \
      --video "$BEAT_MP4" \
      -p "$motion_prompt" \
      --script 2>/dev/null | jq -r '.url // empty')
    set -e
    if [ -n "$ambient_url" ] && [ "$ambient_url" != "null" ]; then
      tmp_v2a="${BEAT_DIR}/beat.v2a.mp4"
      curl -sL "$ambient_url" -o "$tmp_v2a"
      if [ -s "$tmp_v2a" ]; then
        mv "$tmp_v2a" "$BEAT_MP4"
        echo "  ✓ ambient track added by kling-v2a"
      else
        rm -f "$tmp_v2a"
      fi
    fi
  fi

  # Mix TTS into the audio for dialog beats. SKIP when kling-avatar produced
  # the beat — kling-avatar already bakes the TTS in with matched lip-sync;
  # mixing would double the voice.
  if [ -f "$AUDIO_PATH" ] && [ "$model_used" != "kling-avatar" ]; then
    has_v_audio=$(ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$BEAT_MP4" | head -1)
    tmp_mixed="${BEAT_DIR}/beat.mixed.mp4"

    if [ -n "$has_v_audio" ]; then
      echo "  → Mixing TTS with native ambient on ${BEAT_MP4##*/} (voice-forward mix)..."
      # Character voice MUST dominate the mix — ambient ducked to 20%, voice
      # at 1.25x nominal. After the TTS ends, fade the entire audio track to
      # silence within 0.3s so the model's invented "speech-like ambient"
      # (which kling-v2a generates for lip-motion beats) doesn't leak through
      # as phantom voiceover-y chatter. Video keeps moving — character
      # finishes the thought in silence (a noir-friendly beat anyway).
      tts_dur=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$AUDIO_PATH")
      fade_start=$(python3 -c "print(max(0, $tts_dur + 0.1))")
      ffmpeg -y -hide_banner -loglevel error \
        -i "$BEAT_MP4" -i "$AUDIO_PATH" \
        -filter_complex "[0:a]volume=0.20[bg];[1:a]volume=1.25[vox];[bg][vox]amix=inputs=2:duration=first:dropout_transition=0,afade=t=out:st=${fade_start}:d=0.3[a]" \
        -map 0:v:0 -map "[a]" \
        -c:v copy -c:a aac -b:a 192k -ar 48000 \
        "$tmp_mixed" && mv "$tmp_mixed" "$BEAT_MP4"
    else
      echo "  → Video has no audio track; muxing TTS directly onto ${BEAT_MP4##*/}..."
      ffmpeg -y -hide_banner -loglevel error \
        -i "$BEAT_MP4" -i "$AUDIO_PATH" \
        -map 0:v:0 -map 1:a:0 \
        -c:v copy -c:a aac -b:a 192k -ar 48000 \
        -shortest \
        "$tmp_mixed" && mv "$tmp_mixed" "$BEAT_MP4"
    fi
  fi
fi

# ── 4. Write metadata.json (via jq for proper JSON encoding) ──────────────
jq -n \
  --arg beatId "$BEAT_ID" \
  --arg generatedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg model "${model_used:-unknown}" \
  --arg compositeUrl "${composite_url:-}" \
  --arg audioUrl "${audio_url:-}" \
  --arg videoUrl "${video_url:-}" \
  --argjson duration "${duration:-0}" \
  '{
    beatId: $beatId,
    generatedAt: $generatedAt,
    model: $model,
    compositeUrl: (if $compositeUrl == "" then null else $compositeUrl end),
    audioUrl: (if $audioUrl == "" then null else $audioUrl end),
    videoUrl: (if $videoUrl == "" then null else $videoUrl end),
    duration: $duration
  }' > "${BEAT_DIR}/metadata.json"

echo "✓ $BEAT_ID complete"
