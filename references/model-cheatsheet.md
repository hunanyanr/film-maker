# Model Cheatsheet

Which gen-ai model to call per pipeline step, and the automatic fallback chain when the primary fails (content filter, rate limit, capability gap, etc).

## Primary picks

| Step | Model | CLI invocation |
|---|---|---|
| Character turnaround (T2I) | **`gemini-3.1-flash-image`** (Nano Banana 2) | `gen-ai generate -m gemini-3.1-flash-image -p "..." --aspect-ratio 3:2` |
| Location plate (T2I) | **`gemini-3.1-flash-image`** | `gen-ai generate -m gemini-3.1-flash-image -p "..." --aspect-ratio <project>` |
| Scene composite (multi-image i2i) | **`gemini-3.1-flash-image`** | `gen-ai generate -m gemini-3.1-flash-image -i char1.png -i char2.png -i location.png -p "..."` (up to 14 refs) |
| Beat video (non-dialog) | **`kling-3.0-pro`** (1080p, 1 ref image, native audio) | `gen-ai generate -m kling-3.0-pro -i composite.png -p "<motion>" -d <3-15> --resolution 1080p` |
| Beat video (dialog) | **`kling-avatar`** (image + TTS → lip-sync) | `gen-ai generate -m kling-avatar -i composite.png --audio line.wav -p "<motion>"` |
| TTS for dialog | **`eleven-v3`** | `gen-ai generate -m eleven-v3 -p "<line>" --voice <voiceId>` |
| Ambient audio for silent clips | **`kling-v2a`** (video → audio) | `gen-ai generate -m kling-v2a -i clip.mp4 -p "<ambient>"` |

## Video routing — `scripts/generate-beat.sh` runs this automatically

Routing splits on beat type, because different models are good at different things:

**Dialog beats → `kling-avatar` (primary) → `kling-omni` (fallback)**
Kling Avatar is purpose-built for image + audio → lip-synced talking head. It matches mouth motion to the TTS track. Kling Omni is a multi-ref scene model — useful when avatar rejects the composite.

**Non-dialog beats → `kling-3.0-pro` (primary) → `kling-omni` (fallback)**
Kling 3.0 Pro takes 1 image and produces 1080p video with natural ambient audio. Kling Omni accepts multi-ref and handles more complex scenes when 3.0 Pro hits a content filter.

| Priority | Model | Good for | Constraints |
|---|---|---|---|
| **1 (non-dialog)** | `kling-3.0-pro` | Single-image i2v, 1080p, native audio | 1080p, 1 image, durations 3–15s |
| **1 (dialog)** | `kling-avatar` | Image + TTS → lip-synced speech | One face in frame; treats the audio as the mouth movement source |
| **2** | `kling-omni` | Multi-image + scene-aware motion | 1080p, accepts 10+ image refs, durations 3/5/8/10/12/15 — note: output is silent, post-process with `kling-v2a` |

**Why this routing:**
- Dialog beats need mouth-sync precision — Kling Avatar reads the audio waveform to drive the lips, which nothing else in this chain does. Omni's mouth motion is cosmetic; it doesn't actually read the audio, which produces the "voiceover" feel.
- Non-dialog beats benefit from Kling 3.0 Pro's higher fidelity and native ambient audio (foley, room tone).
- Kling Omni is the one-size-fits-all fallback: it accepts any input shape and has a different filter surface, so it catches content that other models reject. But its output is silent — the pipeline layers ambient back on with `kling-v2a`.

**Seedance note:** Seedance 2.0 is available on the Picsart CLI but currently capped at 1 image and no audio input, which makes it a worse fit than Kling 3.0 Pro for the same shape. When the Picsart team raises the cap to match fal's `seedance2-ref` (multi-image + audio), reconsider.

Every metadata.json records which model actually produced the clip in its `model` field, so debugging and reruns target the right layer.

## Image fallback (T2I)

| Primary | Fallback 1 | Fallback 2 | When |
|---|---|---|---|
| `gemini-3.1-flash-image` (T2I) | `grok-imagine` | `seedream-5.0-lite` | Primary rate-limited or down. Grok caps at 1 ref — only use for canonicals or single-ref tasks. |
| `gemini-3.1-flash-image` (multi-ref composite) | — | Skip composite; pass raw refs to video step (Path B) | If >1 ref needed and primary fails. |

## What NOT to use

- Any `t2v`-only model **without image input** — violates Hard Rule #1 (no T2V). Check `editWorkflow` on the model's `models info` output; if it has one, the model accepts images via `-i`.
- `wan-2.7-r2v` — requires a reference video input, not what we have.
- Avatar models for non-dialog beats — `kling-avatar` expects audio input and drives lips to it; don't route non-dialog beats through it.

## Resolution + aspect ratio

Lock at project level, pass to every call. Different models cap at different tiers:

| Model | Supported resolutions | Supported aspect ratios |
|---|---|---|
| `gemini-3.1-flash-image` | up to 4K | most ratios |
| `kling-3.0-pro` | 720p, 1080p | 16:9, 9:16, 1:1 |
| `kling-omni` | 720p, 1080p | 16:9, 9:16, 1:1 |
| `kling-avatar` | varies | 9:16 recommended for talking-head vertical |
| `kling-v2a` | matches input video | matches input |

Project-level aspect stays **9:16** / **16:9** / **1:1** (the three every model in the chain supports). Canonical turnaround is always **3:2 horizontal** regardless (reference sheet, not delivery frame).

## Always pass `--script` for automation

Every gen-ai call in the pipeline uses `--script` (= `--silent --quiet --json`). Parse with `jq`:

```bash
url=$(gen-ai generate -m <model> -p "..." --script 2>/dev/null | jq -r '.url // empty')
```

Catching empty output explicitly is important because failed gen-ai calls don't always print parseable JSON. The skill scripts wrap calls with `set +e` around them to avoid `pipefail` aborting before the fallback check can run.

## Download outputs locally

gen-ai returns a CDN URL (expires eventually). Always download to the project folder for persistence:

```bash
curl -sL "$url" -o <output-path>
```

This makes the project self-contained and shareable without depending on Picsart's CDN.
