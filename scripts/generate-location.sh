#!/usr/bin/env bash
# generate-location.sh — generate an empty location plate
# Usage: scripts/generate-location.sh <project-dir> <location-id>

set -euo pipefail

PROJECT_DIR="$1"
LOC_ID="$2"

cd "$PROJECT_DIR"
LOC_JSON="locations/locations.json"
OUT="locations/${LOC_ID}.png"

[ -f "$LOC_JSON" ] || { echo "✗ No $LOC_JSON" >&2; exit 1; }

if [ -f "$OUT" ]; then
  echo "↷ $LOC_ID plate already exists, skipping"
  exit 0
fi

prompt=$(jq -r --arg id "$LOC_ID" '.locations[$id].prompt' "$LOC_JSON")
aspect=$(jq -r '.aspectRatio' project.json)

if [ -z "$prompt" ] || [ "$prompt" = "null" ]; then
  echo "✗ No prompt for location $LOC_ID in $LOC_JSON" >&2
  exit 1
fi

echo "→ Generating location plate for $LOC_ID..."
url=$(gen-ai generate \
  -m gemini-3.1-flash-image \
  -p "$prompt" \
  --aspect-ratio "$aspect" \
  --script 2>/dev/null | jq -r .url)

[ -n "$url" ] && [ "$url" != "null" ] || { echo "✗ No URL returned for $LOC_ID" >&2; exit 1; }

curl -sL "$url" -o "$OUT"
[ -s "$OUT" ] || { echo "✗ Download failed for $OUT" >&2; exit 1; }

tmp=$(mktemp)
jq --arg id "$LOC_ID" --arg url "$url" \
   '.locations[$id].canonicalImage = $url' \
   "$LOC_JSON" > "$tmp" && mv "$tmp" "$LOC_JSON"

echo "✓ $LOC_ID plate: $OUT"
