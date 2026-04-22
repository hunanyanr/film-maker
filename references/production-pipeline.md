# Production Pipeline — Exact Commands

This is what runs after the review checkpoint. You've already got the full plan (plot, bibles, locations, scenario). Now you produce.

**Every step here is deterministic.** If the plan is good, production works. If a step fails, it fails on an API call — re-run that step. Never silently skip.

## Environment check (run once, at start)

```bash
# Ensure Node 22+ and gen-ai + ffmpeg are available
node --version | grep -qE 'v(2[2-9]|[3-9][0-9])' || { echo "Node 22+ required"; exit 1; }
command -v gen-ai >/dev/null || { echo "gen-ai CLI not found — npm install -g @picsart/gen-ai"; exit 1; }
gen-ai whoami >/dev/null 2>&1 || { echo "Not logged in — run: gen-ai login"; exit 1; }
command -v ffmpeg >/dev/null || { echo "ffmpeg required — brew install ffmpeg"; exit 1; }
command -v jq >/dev/null || { echo "jq required — brew install jq"; exit 1; }
```

The skill script `scripts/preflight.sh` wraps this.

## Step 1 — Generate character canonicals

One turnaround sheet per character. Read from `characters/<id>/bible.json`. Skip if `turnaround.png` already exists.

```bash
for char in $(jq -r 'keys[]' <(ls characters/)); do
  bible_path="characters/${char}/bible.json"
  out_path="characters/${char}/turnaround.png"
  [ -f "$out_path" ] && continue  # resume-safe: skip existing

  prompt=$(scripts/build-canonical-prompt.sh "$bible_path")

  url=$(gen-ai generate \
    -m gemini-3.1-flash-image \
    -p "$prompt" \
    --aspect-ratio "3:2" \
    --script 2>/dev/null | jq -r .url)

  curl -sL "$url" -o "$out_path"
  jq --arg url "$url" --arg path "$out_path" \
     '.canonicalImage = $url | .turnaroundPath = $path' \
     "$bible_path" > "${bible_path}.tmp" && mv "${bible_path}.tmp" "$bible_path"
done
```

**If the generated turnaround has emotion or isn't 5-view:** delete the png, sharpen the prompt (lead with structural instruction, add "NEUTRAL EXPRESSION, 5-VIEW TURNAROUND, WHITE BG" verbatim at the top), re-run. Don't settle for a bad canonical — everything downstream depends on it.

## Step 2 — Generate location plates

One per location. Skip existing.

```bash
jq -r '.locations | keys[]' locations/locations.json | while read loc; do
  out_path="locations/${loc}.png"
  [ -f "$out_path" ] && continue

  prompt=$(jq -r ".locations.${loc}.prompt" locations/locations.json)
  aspect=$(jq -r '.aspectRatio' project.json)

  url=$(gen-ai generate \
    -m gemini-3.1-flash-image \
    -p "$prompt" \
    --aspect-ratio "$aspect" \
    --script 2>/dev/null | jq -r .url)

  curl -sL "$url" -o "$out_path"
  jq --arg loc "$loc" --arg url "$url" \
     '.locations[$loc].canonicalImage = $url' \
     locations/locations.json > locations/locations.json.tmp && \
     mv locations/locations.json.tmp locations/locations.json
done
```

## Step 3 — Generate beats (per-scenario)

For each scenario (`scenario.json` or `episodes/eNN-slug/scenario.json`), process beats in order.

### Per-beat steps:

**3a. Composite the scene image.** Nano Banana 2 takes N reference images and paints them into one scene. This locks character + location identity into a single composed image before video generation.

```bash
beat_id=$(jq -r .id <<< "$beat")
beat_dir="beats/${beat_id}"
mkdir -p "$beat_dir"
[ -f "$beat_dir/composite.png" ] && composite_url=$(jq -r .compositeUrl "$beat_dir/metadata.json" 2>/dev/null)

if [ -z "$composite_url" ] || [ "$composite_url" = "null" ]; then
  char_refs=$(jq -r '.references.images[]' <<< "$beat" | while read c; do
    echo "-i characters/${c}/turnaround.png"
  done | xargs)
  loc_refs=$(jq -r '.references.locations[]' <<< "$beat" | while read l; do
    echo "-i locations/${l}.png"
  done | xargs)
  prop_refs=$(jq -r '.references.props // [] | .[]' <<< "$beat" | while read p; do
    echo "-i props/${p}.png"
  done | xargs)
  aspect=$(jq -r '.aspectRatio' project.json)

  # Composite prompt — describes the SCENE COMPOSITION, not motion.
  # Derived from beat.prompt but framed as a still image description.
  composite_prompt=$(scripts/extract-composite-prompt.sh "$beat")

  composite_url=$(gen-ai generate \
    -m gemini-3.1-flash-image \
    $char_refs $loc_refs $prop_refs \
    -p "$composite_prompt" \
    --aspect-ratio "$aspect" \
    --script 2>/dev/null | jq -r .url)

  curl -sL "$composite_url" -o "$beat_dir/composite.png"
fi
```

**3b. Generate TTS audio (dialog beats only).**

```bash
dialog=$(jq -r '.dialog // empty' <<< "$beat")
audio_url=""
if [ -n "$dialog" ]; then
  [ -f "$beat_dir/audio.wav" ] && audio_url=$(jq -r .audioUrl "$beat_dir/metadata.json" 2>/dev/null)

  if [ -z "$audio_url" ] || [ "$audio_url" = "null" ]; then
    speaker=$(jq -r .speaker <<< "$dialog")
    text=$(jq -r .text <<< "$dialog")
    emotion=$(jq -r .emotion <<< "$dialog")
    voice_id=$(jq -r .voiceConfig.voiceId "characters/${speaker}/bible.json")

    audio_url=$(gen-ai generate \
      -m eleven-v3 \
      -p "$text" \
      --voice "$voice_id" \
      --script 2>/dev/null | jq -r .url)

    curl -sL "$audio_url" -o "$beat_dir/audio.wav"
  fi
fi
```

**3c. Generate the beat video.** Pass the composite image as the **single** reference. Routing is type-aware:

- **Dialog beats** → `kling-avatar` (image + TTS → lip-synced talking head). Falls back to `kling-omni` if avatar rejects the composite.
- **Non-dialog beats** → `kling-3.0-pro` (1080p, native audio). Falls back to `kling-omni` on content-filter rejection.
- **Kling Omni output is silent** — post-process with `kling-v2a` to lay ambient audio back on top.

`scripts/generate-beat.sh` implements this.

```bash
[ -f "$beat_dir/beat.mp4" ] && continue  # resume-safe

video_refs=(-i "$beat_dir/composite.png")   # SINGLE image — composite already has everything
duration=$(jq -r .duration <<< "$beat")       # durations 3–15s depending on model
aspect=$(jq -r '.aspectRatio' project.json)   # 9:16, 16:9, or 1:1
motion_prompt=$(jq -r .prompt <<< "$beat")
beat_type=$(jq -r .type <<< "$beat")

# HARD RULE: at least one -i ref. Composite guarantees this.
model_used=""

if [ "$beat_type" = "dialog" ] && [ -f "$beat_dir/audio.wav" ]; then
  # Primary for dialog: kling-avatar (image + audio → lip-sync)
  set +e
  video_url=$(gen-ai generate -m kling-avatar \
    -i "$beat_dir/composite.png" \
    --audio "$beat_dir/audio.wav" \
    -p "$motion_prompt" \
    --script 2>/dev/null | jq -r '.url // empty')
  set -e
  [ -n "$video_url" ] && model_used="kling-avatar"
else
  # Primary for non-dialog: kling-3.0-pro (1080p, native ambient audio)
  set +e
  video_url=$(gen-ai generate -m kling-3.0-pro \
    "${video_refs[@]}" \
    -p "$motion_prompt" -d "$duration" \
    --aspect-ratio "$aspect" --resolution "1080p" \
    --script 2>/dev/null | jq -r '.url // empty')
  set -e
  [ -n "$video_url" ] && model_used="kling-3.0-pro"
fi

# Fallback: kling-omni (multi-ref, different filter surface, but silent output)
if [ -z "$video_url" ]; then
  kdur=$(bash -c 'case $1 in 1|2|3) echo 3;; 4|5) echo 5;; 6|7|8) echo 8;; 9|10) echo 10;; 11|12) echo 12;; *) echo 15;; esac' _ "$duration")
  set +e
  video_url=$(gen-ai generate -m kling-omni \
    "${video_refs[@]}" \
    -p "$motion_prompt" -d "$kdur" \
    --aspect-ratio "$aspect" --resolution "1080p" \
    --script 2>/dev/null | jq -r '.url // empty')
  set -e
  [ -n "$video_url" ] && model_used="kling-omni"
fi

[ -n "$video_url" ] || { echo "✗ All video models failed for $beat_id" >&2; exit 1; }
curl -sL "$video_url" -o "$beat_dir/beat.mp4"

# If kling-omni produced the clip, it's silent — layer ambient audio back with kling-v2a
if [ "$model_used" = "kling-omni" ]; then
  ambient_url=$(gen-ai generate -m kling-v2a \
    -i "$beat_dir/beat.mp4" \
    -p "$motion_prompt" \
    --script 2>/dev/null | jq -r '.url // empty')
  [ -n "$ambient_url" ] && curl -sL "$ambient_url" -o "$beat_dir/beat.mp4"
fi
```

**Why `set +e` around each call:** `set -o pipefail` at the script level would abort the entire script when gen-ai returns non-zero (which happens on content-filter rejections, rate limits, etc). Wrapping with `set +e` lets us inspect `video_url` and fall through to the next model.

**Why the composite is a single image:** Kling 3.0 Pro's image-to-video path takes one reference. The composite (from Nano Banana 2 multi-image) already embeds all the identity — one image is enough to animate. Kling Omni accepts multi-ref but is the fallback, not the default.

**Why dialog routes through Kling Avatar:** Avatar reads the audio waveform to drive the lips, producing genuine lip-sync. The other video models only do cosmetic mouth motion and ignore the audio signal, which reads as "voiceover" instead of "character speaking."

**3d. Write `metadata.json`.** This is the resume token — future re-runs check this before regenerating. Use `jq -n` to build the JSON safely (bash heredoc with URLs containing special chars produces broken JSON).

```bash
jq -n \
  --arg beatId "$beat_id" \
  --arg generatedAt "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
  --arg model "$model_used" \
  --arg compositeUrl "$composite_url" \
  --arg audioUrl "$audio_url" \
  --arg videoUrl "$video_url" \
  --arg prompt "$motion_prompt" \
  --argjson duration "$duration" \
  '{beatId: $beatId, generatedAt: $generatedAt, model: $model,
    compositeUrl: $compositeUrl, audioUrl: $audioUrl, videoUrl: $videoUrl,
    prompt: $prompt, duration: $duration}' \
  > "$beat_dir/metadata.json"
```

## Step 4 — Concatenate beats

After all beats in a scenario are generated, ffmpeg concat with crossfade. One final mp4 per scenario.

```bash
scenario_dir=$(dirname "$scenario_json_path")
output_path="${scenario_dir}/episode.mp4"  # or movie.mp4 for single-film projects

# Collect beat mp4s in scenario order
beat_ids=$(jq -r '.beats[].id' "$scenario_json_path")
beat_files=()
for id in $beat_ids; do
  f="${scenario_dir}/beats/${id}/beat.mp4"
  [ -f "$f" ] && beat_files+=("$f")
done

transition_duration=$(jq -r '.transition.duration // 0.5' "$scenario_json_path")

scripts/concat-with-xfade.sh "$output_path" "$transition_duration" "${beat_files[@]}"
```

The `concat-with-xfade.sh` helper does the ffmpeg xfade filter_complex — it's tedious and error-prone to write inline.

## Step 5 — Render social copy

For each posting character in `scenario.socialCopyTemplates`:

```bash
jq -r '.socialCopyTemplates | keys[]' "$scenario_json_path" | while read char; do
  block=$(jq --arg c "$char" '.socialCopyTemplates[$c]' "$scenario_json_path")
  scripts/format-social-copy.sh "$block" > "${scenario_dir}/social-copy-${char}.txt"
done

# Also write the episode-wide recap
scripts/write-recap-copy.sh "$scenario_json_path" > "${scenario_dir}/social-copy.txt"
```

## Full orchestration

The whole thing wraps in `scripts/produce.sh`:

```bash
cd "$PROJECT_DIR"
scripts/preflight.sh
scripts/generate-all-canonicals.sh
scripts/generate-all-locations.sh

if [ -f scenario.json ]; then
  scripts/produce-scenario.sh scenario.json
else
  for ep in episodes/*/scenario.json; do
    scripts/produce-scenario.sh "$ep"
  done
fi

echo "✓ Done. Final output at $(find . -name 'movie.mp4' -o -name 'episode.mp4')"
```

## Failure modes

| Failure | What to do |
|---|---|
| `gen-ai` returns 401 | User needs to `gen-ai login` or set `PICSART_ACCESS_TOKEN` |
| `gen-ai` returns 402 (no credits) | Stop, tell user, don't retry |
| `gen-ai` returns 429 (rate limit) | Backoff 30s, retry up to 3 times |
| `gen-ai` returns 500 (model failed) | Retry once; if still failing, log and continue with other beats; surface the failed beat at end |
| Invalid payload (e.g. image URL expired) | Refresh URL by re-running the upstream step |
| Network failure during download | Retry 3x with backoff, then fail the beat |

Always surface failures. Never claim success if any beat failed.

## `--plan-only` short-circuit

If the invocation was `--plan-only`, return before Step 1. Tell the user:

```
✓ Plan written to <project-dir>/.
Review plot.md, characters/*/bible.json, locations/locations.json, and scenario.json.
Re-run without --plan-only to produce.
```

No gen-ai calls made, no credits spent, no binary artifacts generated.
