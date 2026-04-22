#!/usr/bin/env bash
# produce.sh — top-level orchestrator: turn a planned project folder into finished video
# Usage: scripts/produce.sh <project-dir>
#
# Assumes the project folder already contains:
#   project.json, plot.md, characters/*/bible.json, locations/locations.json,
#   scenario.json (or episodes/*/scenario.json)
#
# Does NOT write the plan — that's Claude's job via SKILL.md steps 1-6.
# This script only executes steps 7-8 (produce + deliver).

set -euo pipefail

PROJECT_DIR="${1:-.}"
SKILL_DIR="$(cd "$(dirname "$0")" && pwd)"

[ -d "$PROJECT_DIR" ] || { echo "✗ $PROJECT_DIR not a directory" >&2; exit 1; }
[ -f "$PROJECT_DIR/project.json" ] || { echo "✗ No project.json in $PROJECT_DIR — run the planning steps first" >&2; exit 1; }

# Preflight check
"$SKILL_DIR/preflight.sh"

cd "$PROJECT_DIR"

# 1. Generate all character canonicals
echo ""
echo "═══ Character canonicals ═══"
if [ -d characters ]; then
  for char_dir in characters/*/; do
    char=$(basename "$char_dir")
    [ -f "${char_dir}bible.json" ] || continue
    "$SKILL_DIR/generate-canonical.sh" "$(pwd)" "$char"
  done
fi

# 2. Generate all location plates
echo ""
echo "═══ Location plates ═══"
if [ -f locations/locations.json ]; then
  for loc in $(jq -r '.locations | keys[]' locations/locations.json); do
    "$SKILL_DIR/generate-location.sh" "$(pwd)" "$loc"
  done
fi

# 3. Process scenario(s)
echo ""
if [ -f scenario.json ]; then
  echo "═══ Single-film mode ═══"
  "$SKILL_DIR/produce-scenario.sh" "$(pwd)" "scenario.json"
elif [ -d episodes ]; then
  echo "═══ Episodic mode ═══"
  for ep_scenario in episodes/*/scenario.json; do
    [ -f "$ep_scenario" ] || continue
    "$SKILL_DIR/produce-scenario.sh" "$(pwd)" "$ep_scenario"
  done
else
  echo "✗ No scenario.json or episodes/ found" >&2
  exit 1
fi

# 4. Final summary
echo ""
echo "═══ Complete ═══"
if [ -f movie.mp4 ]; then
  echo "✓ movie.mp4"
  ls -lh movie.mp4
fi
if ls episodes/*/episode.mp4 >/dev/null 2>&1; then
  echo "✓ episodes:"
  for ep in episodes/*/episode.mp4; do
    echo "  $ep ($(ffprobe -v error -show_entries format=duration -of csv=p=0 "$ep" | awk '{printf "%.1fs", $0}'))"
  done
fi
echo ""
echo "Social copy files:"
find . -name 'social-copy*.txt' -not -path './node_modules/*' | sort
