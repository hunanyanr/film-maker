#!/usr/bin/env bash
# format-social-copy.sh — render a socialCopyTemplates[char] block into
# the standard IG/TikTok/YouTube/ALT TEXT text format.
# Usage: scripts/format-social-copy.sh <scenario-json> <char-id>
# Emits to stdout; redirect to social-copy-<char>.txt

set -euo pipefail

SCENARIO="$1"
CHAR="$2"

block=$(jq --arg c "$CHAR" '.socialCopyTemplates[$c]' "$SCENARIO")
[ -n "$block" ] && [ "$block" != "null" ] || { echo "No socialCopyTemplates for $CHAR" >&2; exit 1; }

caption=$(jq -r '.caption' <<< "$block")
tiktok=$(jq -r '.tiktokCaption' <<< "$block")
youtube=$(jq -r '.youtubeCaption' <<< "$block")
alt=$(jq -r '.altText // ""' <<< "$block")

# Hashtags — ensure required Picsart tags are present
tags=$(jq -r '.hashtags | map("#" + .) | join(" ")' <<< "$block")
for req in "#picsart" "#picsartaiinfluencer" "#picartinfluencer"; do
  [[ " $tags " == *" $req "* ]] || tags="$tags $req"
done

cat <<EOF
INSTAGRAM
────────────────────────────────────────
$caption

$tags


TIKTOK
────────────────────────────────────────
$tiktok

$tags


YOUTUBE
────────────────────────────────────────
$youtube

$tags
EOF

if [ -n "$alt" ] && [ "$alt" != "null" ]; then
  cat <<EOF


ALT TEXT
────────────────────────────────────────
$alt
EOF
fi
