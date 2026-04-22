#!/usr/bin/env bash
# produce-scenario.sh — process one scenario's beats + concat + social copy
# Usage: scripts/produce-scenario.sh <project-dir> <scenario-json-path>

set -euo pipefail

PROJECT_DIR="$1"
SCENARIO="$2"

cd "$PROJECT_DIR"
SCENARIO_DIR=$(dirname "$SCENARIO")
SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"

[ -f "$SCENARIO" ] || { echo "✗ $SCENARIO not found" >&2; exit 1; }

echo "═══ Processing scenario: $SCENARIO ═══"

# 1. Generate every beat in order
for beat_id in $(jq -r '.beats[].id' "$SCENARIO"); do
  if ! "$SKILL_DIR/generate-beat.sh" "$PROJECT_DIR" "$SCENARIO" "$beat_id"; then
    echo "✗ Beat $beat_id failed — continuing with remaining beats" >&2
  fi
done

# 2. Concatenate beats
beat_files=()
for beat_id in $(jq -r '.beats[].id' "$SCENARIO"); do
  f="${SCENARIO_DIR}/beats/${beat_id}/beat.mp4"
  if [ -f "$f" ]; then
    beat_files+=("$f")
  else
    echo "⚠ Missing $f — skipping from concat"
  fi
done

if [ "${#beat_files[@]}" -eq 0 ]; then
  echo "✗ No beat mp4s available to concat" >&2
  exit 1
fi

xfade=$(jq -r '.transition.duration // 0.5' "$SCENARIO")

# Output name: movie.mp4 for single-film projects, episode.mp4 for episodes
if [ "$SCENARIO" = "scenario.json" ]; then
  out_path="movie.mp4"
else
  out_path="${SCENARIO_DIR}/episode.mp4"
fi

"$SKILL_DIR/concat-with-xfade.sh" "$out_path" "$xfade" "${beat_files[@]}"

# 3. Social copy per character
for char in $(jq -r '.socialCopyTemplates // {} | keys[]' "$SCENARIO"); do
  out_txt="${SCENARIO_DIR}/social-copy-${char}.txt"
  "$SKILL_DIR/format-social-copy.sh" "$SCENARIO" "$char" > "$out_txt"
  echo "✓ social-copy-${char}.txt"
done

echo "═══ Done: $out_path ═══"
