#!/usr/bin/env bash
# generate-canonical.sh — generate a character turnaround (5-view, neutral, white bg)
# Usage: scripts/generate-canonical.sh <project-dir> <char-id>
# Reads characters/<char-id>/bible.json, writes characters/<char-id>/turnaround.png
# and updates bible.json with canonicalImage URL.

set -euo pipefail

PROJECT_DIR="$1"
CHAR_ID="$2"

cd "$PROJECT_DIR"
BIBLE="characters/${CHAR_ID}/bible.json"
OUT="characters/${CHAR_ID}/turnaround.png"

[ -f "$BIBLE" ] || { echo "✗ No bible at $BIBLE" >&2; exit 1; }

if [ -f "$OUT" ]; then
  echo "↷ $CHAR_ID turnaround already exists, skipping"
  exit 0
fi

# Build the turnaround prompt from bible fields
form=$(jq -r '.form' "$BIBLE")
physical=$(jq -r '.physicalDescription' "$BIBLE")
anchors=$(jq -r '.consistencyAnchors | map("- " + .) | join("\n")' "$BIBLE")
wardrobe=$(jq -r '.wardrobe.signature | join(", ")' "$BIBLE")
aesthetic=$(jq -r '.aesthetic // "cinematic photorealistic"' project.json)

prompt="A character turnaround reference sheet showing the same character from FIVE angles (front view, 3/4 front view, side view, 3/4 back view, back view), arranged left to right across a single image, all at the same scale and eye line.

Subject: ${form}. ${physical}

Consistency anchors that MUST appear identically in every view:
${anchors}

Outfit: ${wardrobe} — same outfit across all 5 views.

NEUTRAL EXPRESSION ONLY — closed mouth, no smile, no frown, no emotion, eyes forward. Default posture — standing upright, arms at sides. No dynamic pose, no action.

Pure solid white background. No scene, no props, no environment, no story. Soft even studio lighting, no dramatic shadows, identical lighting across all views. Character turnaround reference sheet / model sheet style.

Style: ${aesthetic}

3:2 horizontal aspect, ultra detailed."

CANONICAL_MODEL="${CANONICAL_MODEL:-grok-imagine}"
echo "→ Generating canonical for $CHAR_ID via $CANONICAL_MODEL..."
set +e
url=$(gen-ai generate \
  -m "$CANONICAL_MODEL" \
  -p "$prompt" \
  --aspect-ratio "3:2" \
  --script 2>/dev/null | jq -r '.url // empty' 2>/dev/null)
set -e

# Fallback to Nano Banana 2 if primary model fails or isn't available
if [ -z "$url" ] || [ "$url" = "null" ]; then
  echo "  ↳ $CANONICAL_MODEL didn't produce, falling back to gemini-3.1-flash-image..."
  url=$(gen-ai generate \
    -m gemini-3.1-flash-image \
    -p "$prompt" \
    --aspect-ratio "3:2" \
    --script 2>/dev/null | jq -r .url)
fi

if [ -z "$url" ] || [ "$url" = "null" ]; then
  echo "✗ gen-ai returned no URL for $CHAR_ID" >&2
  exit 1
fi

curl -sL "$url" -o "$OUT"
[ -s "$OUT" ] || { echo "✗ Download failed for $OUT" >&2; exit 1; }

# Update bible with canonicalImage URL
tmp=$(mktemp)
jq --arg url "$url" --arg path "$OUT" \
   '.canonicalImage = $url | .turnaroundPath = $path' \
   "$BIBLE" > "$tmp" && mv "$tmp" "$BIBLE"

echo "✓ $CHAR_ID canonical: $OUT"
