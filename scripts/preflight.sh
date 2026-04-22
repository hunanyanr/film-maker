#!/usr/bin/env bash
# preflight.sh — verify environment before any generation work
# Usage: scripts/preflight.sh
# Exits 0 if environment is ready, non-zero with a specific error otherwise.

set -euo pipefail

fail() { echo "✗ $1" >&2; exit 1; }
ok()   { echo "✓ $1"; }

# Node 22+
if ! command -v node >/dev/null; then
  fail "node not found — install Node 22+ (https://nodejs.org or via nvm)"
fi
node_major=$(node --version | sed 's/^v//' | cut -d. -f1)
if [ "$node_major" -lt 22 ]; then
  fail "Node 22+ required (you have $(node --version)). Run: nvm install 22 && nvm use 22"
fi
ok "node $(node --version)"

# gen-ai CLI
if ! command -v gen-ai >/dev/null; then
  fail "gen-ai CLI not found — install with: npm install -g @picsart/gen-ai"
fi
ok "gen-ai $(gen-ai --version 2>/dev/null | head -1 || echo installed)"

# gen-ai auth
if ! gen-ai whoami >/dev/null 2>&1; then
  fail "not authenticated — run: gen-ai login (or set PICSART_ACCESS_TOKEN + PICSART_USER_ID)"
fi
ok "gen-ai authenticated"

# ffmpeg
if ! command -v ffmpeg >/dev/null; then
  fail "ffmpeg not found — install with: brew install ffmpeg (or apt/yum equivalent)"
fi
ok "ffmpeg $(ffmpeg -version | head -1 | cut -d' ' -f3)"

# jq
if ! command -v jq >/dev/null; then
  fail "jq not found — install with: brew install jq"
fi
ok "jq $(jq --version)"

# curl
if ! command -v curl >/dev/null; then
  fail "curl not found"
fi
ok "curl available"

echo "✓ Environment ready."
