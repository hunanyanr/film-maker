# film-maker

A Claude Code skill that turns a one-sentence story premise into a finished cinematic video — reel, short film, or multi-episode series — using the [Picsart gen-ai CLI](https://www.npmjs.com/package/@picsart/gen-ai) for image, video, and audio generation and `ffmpeg` for final assembly.

Built for creators who want **cinematic quality, character consistency, and native audio** out of the box. No text-to-video slop; every beat passes a real reference image and every character keeps a locked voice.

---

## What it does

Given a premise like *"a retired detective gets one last case in a rainy neon city"*, the skill:

1. **Writes a plot** using a genre playbook (14 genres + tone modifiers including `brainrot`).
2. **Designs a cast** — neutral 5-view canonical turnarounds per character, locked ElevenLabs voice IDs.
3. **Builds locations and props**, each with a canonical plate.
4. **Breaks the story into shot-card beats** (`establishing` / `reaction` / `dialog`) with real cinematic grammar.
5. **Shows you the plan for review before spending any credits.**
6. **Produces every beat** — composite scene image (Nano Banana 2 multi-ref) → video (Kling 3.0 Pro for non-dialog, Kling Avatar for lip-synced dialog, Kling Omni as filter-rescue fallback) → native ambient audio.
7. **Concatenates with crossfade** into `movie.mp4` or `episodes/eNN-slug/episode.mp4`.
8. **Renders social copy** for Instagram, TikTok, and YouTube per posting character.

Every step is **resume-safe** — re-run at any point and completed work is cached via `metadata.json`.

---

## Requirements

| Tool | Version | Install |
|---|---|---|
| [Claude Code](https://claude.com/product/claude-code) | latest | — |
| Node.js | 22+ | `brew install node` |
| [@picsart/gen-ai](https://www.npmjs.com/package/@picsart/gen-ai) | 1.151.0+ | `npm install -g @picsart/gen-ai` |
| `ffmpeg` | 6+ | `brew install ffmpeg` |
| `jq` | 1.6+ | `brew install jq` |

Authenticate the Picsart CLI once before first run:

```bash
gen-ai login
```

The CLI handles OAuth and persists credentials (`PICSART_ACCESS_TOKEN` + `PICSART_USER_ID`) for you.

---

## Install

### Option A — symlink from this repo (recommended for development)

```bash
git clone https://github.com/hunanyanr/film-maker.git
ln -s "$(pwd)/film-maker" ~/.claude/skills/film-maker
```

### Option B — install from a `.skill` release bundle

Grab the latest `film-maker.skill` from the [Releases](https://github.com/hunanyanr/film-maker/releases) page, then unzip into `~/.claude/skills/`:

```bash
unzip film-maker.skill -d ~/.claude/skills/film-maker
```

Verify it loaded — start a new Claude Code session and ask:

> Make me a 15-second reel about a cat who thinks it's a barista.

If the skill is picked up, Claude will open the intake step (format, genre, aspect ratio, project name).

---

## Quickstart

```
You: make me a 30-second moody noir reel about a detective who finds their own name in a dead woman's notebook

Claude: [intake → plot → cast → world → scenario]
Claude: Plan written to ./noir-notebook/. Approve to produce, or tell me what to change.

You: go

Claude: [produces all beats, concatenates, writes social copy]
Claude: ✓ Done.
        Final video: ./noir-notebook/movie.mp4
        Social copy: ./noir-notebook/social-copy.txt
```

Want to stop after planning (no credits spent)? Say `--plan-only` in your first message.

---

## How it works

```
premise ─► plot.md ─► bibles + voiceIds ─► locations.json ─► scenario.json
                                                                   │
                                       REVIEW CHECKPOINT ──────────┤
                                                                   ▼
  canonicals (Nano Banana 2) ─► location plates ─► per-beat:
     composite.png (multi-ref i2i)
       └─► Kling 3.0 Pro (non-dialog) ──or── Kling Avatar (dialog + TTS)
             └─► fallback: Kling Omni ─► Kling V2A (ambient)
                                                                   ▼
                                    ffmpeg xfade concat ─► movie.mp4
                                    social-copy-<char>.txt per poster
```

### The 8 hard rules

1. **No text-to-video, ever.** Every video beat passes at least one reference image.
2. **Character image flows through to video generation.** The composite (Nano Banana 2 multi-ref) carries identity into every clip.
3. **Audio is natively generated, never overlaid as voice-over.** Kling 3.0 Pro generates ambient; Kling Avatar drives lips from TTS; Kling Omni output gets Kling V2A ambient layered on.
4. **Canonicals are neutral 5-view turnarounds on white.** Emotion and scene live at the beat layer, not the canonical.
5. **Aspect ratio locks at the project level.** Mixing ratios breaks concat.
6. **Dialog beats are solo and speaker-focused.** One character in frame, MCU or tighter, no props — otherwise video models will animate the wrong object (the "talking shoes" failure).
7. **Every character in a prompt must be in `references.images`.** No ghost characters.
8. **Resumable by design.** `metadata.json` is the resume token; never delete it during a re-run.

---

## Model matrix

| Step | Primary | Fallback | Why |
|---|---|---|---|
| Character turnaround (T2I) | `gemini-3.1-flash-image` (Nano Banana 2) | `grok-imagine` | Highest identity fidelity on the Picsart CLI. |
| Location plate (T2I) | `gemini-3.1-flash-image` | — | Multi-ratio, consistent with character canonicals. |
| Scene composite (multi-ref i2i) | `gemini-3.1-flash-image` | — | Up to 14 refs in one image; the carrier for identity. |
| Beat video (non-dialog) | `kling-3.0-pro` | `kling-omni` → `kling-v2a` | 1080p + native ambient audio. |
| Beat video (dialog) | `kling-avatar` | `kling-omni` → `kling-v2a` | Reads TTS waveform, drives real lip-sync. |
| TTS | `eleven-v3` | — | Voice library locked per character in `references/voice-tuning.md`. |

See [`references/model-cheatsheet.md`](references/model-cheatsheet.md) for the full routing logic.

---

## Repository layout

```
film-maker/
├── SKILL.md                 # Workflow — the 8 steps from intake to delivery
├── references/              # Deep-dive docs Claude loads on demand
│   ├── genre-catalog.md         # 14 genres + tone modifiers
│   ├── genre-playbooks/         # Per-genre structural rules
│   ├── character-design.md      # Bible schema + visual discipline
│   ├── canonical-turnaround-rules.md
│   ├── location-design.md
│   ├── beat-types.md            # establishing / reaction / dialog
│   ├── shot-cards.md            # How to write director-quality prompts
│   ├── prompt-craft.md          # Negative prompts, counting, hands, text
│   ├── voice-tuning.md          # ElevenLabs voice library
│   ├── pacing.md                # Beat duration + rhythm
│   ├── social-copy.md           # IG / TikTok / YouTube format
│   ├── production-pipeline.md   # Exact CLI commands per step
│   ├── model-cheatsheet.md      # Model routing + fallbacks
│   └── credits-estimation.md    # Rough costs for the review checkpoint
├── scripts/                 # Bash scripts that orchestrate gen-ai + ffmpeg
│   ├── preflight.sh             # Verify Node, gen-ai, ffmpeg, jq
│   ├── generate-canonical.sh    # Character turnarounds
│   ├── generate-location.sh     # Location plates
│   ├── generate-beat.sh         # Per-beat: composite → TTS → video → ambient
│   ├── concat-with-xfade.sh     # ffmpeg crossfade concat
│   ├── produce-scenario.sh
│   ├── produce.sh               # Full orchestration
│   └── format-social-copy.sh
├── templates/               # JSON scaffolds for projects / bibles / scenarios
└── evals/                   # Test prompts for iteration
```

---

## Known limitations

- **`seedance2-ref` is gated on the Picsart CLI** — currently capped at 1 image input with no audio. When the Picsart team raises the cap to match fal's multi-ref + audio variant, it will slot in as a third video path.
- **Kling Omni output is silent.** The pipeline handles this via `kling-v2a` post-processing, but this adds one extra call per fallback beat.
- **Dialog lip-sync reliability** depends on a clean composite (speaker's face dominating, no props, no other characters). The skill enforces the speaker-focused composition rule, but occasionally a reshoot is needed — re-run with a tighter prompt.

---

## Contributing

Issues and pull requests welcome. Before opening a PR:

1. Run your change through a real test project end-to-end.
2. Keep `SKILL.md` under 500 lines; push depth into `references/` files.
3. Follow the existing bash style (`set -euo pipefail`, `set +e` only around `gen-ai` calls).

---

## License

MIT — see [LICENSE](LICENSE).
