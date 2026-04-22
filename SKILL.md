---
name: film-maker
description: Use whenever the user wants to create narrative video content — a reel, short film, movie, music video, trailer, promo, teaser, episode, or multi-episode series — from a story premise or idea. Triggers on phrases like "make me a reel", "create a short film", "generate a movie", "I want an episode about", "turn this into a video", "make a cinematic clip", or any request where a story or scene is described and video is the expected output. Always use this skill for narrative video work; it handles the entire pipeline from plot writing to character design to final concatenated mp4 using the Picsart gen-ai CLI. Do not try to generate individual video clips without this skill — character consistency, pacing, and cinematic quality depend on the full pipeline.
---

# Film Maker

Turn one sentence into a complete piece of cinematic video. Handles reels, short films, episodes, and multi-episode series in any genre — drama, thriller, noir, comedy, sci-fi, soap opera, fable, anything.

You (Claude) do the creative work — writing the plot cinematically, designing the cast and world, breaking the story into shot-level beats. Then you run a deterministic production pipeline that calls `gen-ai` (Picsart's CLI) for images and video, and `ffmpeg` for concatenation. The user gets a finished mp4.

## Why this skill exists

Generic "prompt a video model" workflows skip the hard part: professional writing, cast consistency across shots, cinematic camera language, emotional pacing. This skill bakes those in. Without this, characters change face every beat, plots feel like AI slop, and the video model gets asked to invent everything from a single flat prompt.

## Prerequisites — check before starting

Run this check silently before the first generation call. If anything is missing, tell the user what to install and stop.

```bash
node --version                         # must be v22 or higher
command -v gen-ai                      # must resolve
gen-ai whoami                          # must show an authenticated user
command -v ffmpeg                      # must resolve
command -v jq                          # must resolve (for parsing gen-ai --script output)
```

If `gen-ai whoami` fails, tell the user to run `gen-ai login` or set `PICSART_ACCESS_TOKEN` + `PICSART_USER_ID`.

## The workflow

The skill is an **eight-step pipeline**. Do them in order. Steps 1–6 are creative + planning work you do yourself. Step 7 runs the generation scripts. Step 8 delivers.

**When the user invokes the skill with `--plan-only` or says "just plan, don't generate yet", stop after Step 6.** See the `--plan-only` section below.

---

### Step 1 — Understand intent

Extract from the user's message:
- **Premise** — the story seed
- **Format** — reel (vertical short, 10-60s) / short film / feature / series? If unclear, infer from phrasing ("reel" → 9:16 short; "movie"/"film" → 16:9 longer)
- **Genre + tone** — see `references/genre-catalog.md` for the 14 core genres and tone modifiers. If the user didn't specify, propose 1–2 candidates from the premise and ask
- **Length** — seconds, minutes, episode count (episodes × length-per-episode)
- **Aspect ratio** — infer from format (reel → 9:16, film → 16:9, square post → 1:1), or ask. Video models only support 9:16 / 16:9 / 1:1 — don't offer others
- **Episodes vs continuous** — if it's more than ~3 minutes of content, ask: continuous single film, or split into episodes? Episodes unlock arcs and cliffhangers; continuous is simpler
- **Project name** — short slug for the output folder (e.g. `noir-alley`, `mars-gardener`)

If any of these are unclear after reading the premise, ask exactly the needed clarifiers (not a bulk form — pick the 1–3 that matter most for their request).

Create the project folder at `./<project-name>/` relative to current working directory unless the user specifies a different location. Write `project.json` from `templates/project.json.template` with the resolved settings.

---

### Step 2 — Write the plot

This is where amateur AI video generation dies. Spend real thought here.

**Load the right playbook.** Read `references/genre-playbooks/<genre>.md` for structural rules. For blends (e.g. sci-fi thriller), read both and merge: primary genre drives act structure + pacing, secondary genre contributes tonal texture + setting logic.

**Write the plot as `plot.md` in the project folder.** Structure:

```markdown
# <Title>

## Logline
One sentence. Who wants what, what stands in their way, what's at stake.

## Act I — Setup
## Act II — Escalation
## Act III — Resolution

## Character arcs
Per character: where they start emotionally, where they end, the turning point.

## Tone and visual texture
Color palette, lighting philosophy, shot rhythm.
```

**Craft rules — apply them consciously:**

- **Start with a hook in the first 3 seconds.** Short content = no ramp. Even features open on a question or an image that can't be ignored.
- **Emotional contrast.** Tension → release → tension. No flat plateaus. The rule of 3 (setup, reinforce, subvert) works at every scale.
- **Subtext over exposition.** Characters don't announce their feelings — they show them through action, what they don't say, what they misread. If a character tells another character what they already know, that line needs to die.
- **Motivation drives action.** Every beat happens because someone wants something. "And then X happens" without a why is AI slop rhythm.
- **One memorable image per act.** A recurring visual that carries meaning — the vial, the photograph, the dying seedling, the neon reflection. Viewers remember images, not dialog.
- **Anti-patterns to avoid:** summary rhythm ("and then… and then…"), characters agreeing too easily, clean moral resolution in genres that need ambiguity, exposition dumps, climax arriving too early.

If the user gave a thin premise (one sentence), expand it into a real story — don't literally narrate the sentence.

---

### Step 3 — Design the cast

**Every character in a film needs a full bible.** Read `templates/character-bible.json.template` for the schema. Read `references/character-design.md` for the prompt-writing rules.

**Per character, write the bible:**

- `id` — short slug (e.g. `nova`, `detective-cole`)
- `name` — display name
- `role` — archetype (protagonist, antagonist, mentor, foil, comic relief, etc.)
- `form` — species/type, free-form. "Human, late 30s" / "anthropomorphic strawberry" / "golden retriever" / "android unit K-7" / "shapeshifting fog"
- `physicalDescription` — 4–8 sentences of visual specificity. What would you see in a mugshot?
- `consistencyAnchors` — 4–8 bullets of visually-identifying features that **must lock across every generation** (e.g., "green leaf crown", "scar above left eyebrow", "always wears the gold bracelet")
- `colorPalette` — 5 hex values that recur in their styling
- `wardrobe` — signature pieces the character is almost always in
- `voiceConfig` — TTS model + settings tuned to personality (see `references/voice-tuning.md`)
- `personality` — core traits, quirks, speech patterns, catchphrases

**Hard rule: canonicals are blank slates, not emotional portraits.** The canonical image used for every downstream generation is a **5-view turnaround sheet on pure white**, neutral expression only. Read `references/canonical-turnaround-rules.md` — those rules are non-negotiable. Emotions, expressions, and scene context come in at the beat layer, never baked into the canonical.

**Write one file per character** at `characters/<char-id>/bible.json`.

---

### Step 4 — Design the world (locations + props)

**Locations are empty environments.** No characters in them. Characters composite into them later via Nano Banana 2 at the beat layer.

Read `references/location-design.md`. For each location the plot needs:

```
locations/locations.json:
  {
    "locationId": "neon-alley",
    "name": "Neon-lit alley behind the club",
    "description": "Narrow brick alley, wet pavement, neon signage reflecting in puddles, dumpsters",
    "prompt": "<full T2I prompt for generating the empty plate>",
    "mood": "tense, isolated, cold",
    "timeOfDay": "night",
    "scenes": [<list of beat IDs that use this location>]
  }
```

**Props** (optional) — key objects that appear across scenes go under `props/` as separate images (e.g. `poison-vial.png`, `gold-bracelet.png`). Only add props that recur or matter plot-wise. One-off set dressing lives in the scene composite prompt.

---

### Step 5 — Write the scenario (the beats)

This is the shot-level breakdown. Each beat is one shot or one tight multi-shot sequence. Read `references/beat-types.md` and `references/shot-cards.md` before writing.

**Beat types:**

| Type | Description | Characters in frame |
|---|---|---|
| `establishing` | Wide shot / mood setter | 0–N |
| `reaction` | Visual storytelling, no dialog | 1–N |
| `dialog` | One character speaks | **1 only** (lip-sync works best solo) |

**Shot-card prompt style.** Each beat's prompt reads like a director's shot card, not a paragraph. Specify:
- **Shot size** (ECU / CU / medium / wide / establishing)
- **Camera movement** (dolly, orbit, handheld, locked, push-in, rack focus)
- **Lens feel** (85mm portrait, anamorphic wide, etc. — optional but adds grammar)
- **Emotional beat** (what the viewer should feel at second 3 vs second 10)
- **Lighting** (golden rim / harsh overhead / soft window / neon reflection)
- **Reference tags**: `@Image1`, `@Image2`, `@Audio1` to bind refs to entities. Required.

**Write `scenario.json`** (for single film) or `episodes/e01-slug/scenario.json` (for series) using `templates/scenario.json.template`. Per beat:

```json
{
  "id": "b01-alley-reveal",
  "type": "reaction",
  "character": "cole",
  "characters": ["cole"],
  "description": "Detective Cole rounds the corner and sees the body",
  "references": {
    "images": ["cole"],
    "locations": ["neon-alley"],
    "props": []
  },
  "prompt": "Medium wide shot. @Image1 Detective Cole in a tan trench coat rounds the corner into @Image2 a neon-lit alley at night, handheld camera tight on his shoulders as he moves, his breath visible. He stops dead — rack focus from his face to a body crumpled against the dumpsters at the end of the alley. Neon signs reflect blood-red in the wet pavement. Slow push-in on his face — the moment he realizes who it is. 9:16 vertical, high contrast, teal-and-red color grade.",
  "duration": 5,
  "dialog": null
}
```

**Beat rhythm across the scenario.** Alternate pacing: wide after close, quiet after loud, slow push after hard cut. Villa-7 has this intuitively — steal its rhythm. Read `references/pacing.md`.

**For dialog beats**, fill the `dialog` block:

```json
"dialog": {
  "speaker": "cole",
  "text": "She wasn't supposed to be here.",
  "emotion": "flat, devastated, almost a whisper"
}
```

Dialog beats will get TTS audio generated in Step 7 and passed to Kling Avatar (image + audio → lip-synced talking head).

**Write social copy templates** per posting character inside `scenario.json` at `socialCopyTemplates[charId]` — see `references/social-copy.md` for platform rules (Instagram / TikTok / YouTube with required hashtags).

---

### Step 6 — Review checkpoint

**Before spending any credits**, show the user the full plan and wait for approval.

Present:

```
## Plan for <project-name>

**Format**: <reel | short film | series>
**Genre**: <primary> + <secondary?> / <tone modifiers>
**Aspect ratio**: <9:16 | 16:9 | 1:1>
**Length**: <seconds or N episodes × seconds>
**Estimated credits**: <rough total, from references/credits-estimation.md>

### Plot
<3-sentence summary of plot.md>

### Cast (<N> characters)
- <name> (<role>) — <1-line visual hook>
- ...

### Locations (<N>)
- <name> — <1-line mood>
- ...

### Structure
<N beats total | N episodes × N beats>

Approve to proceed, or tell me what to change.
```

If the user wants changes: edit only what they asked for and re-present. Do not regenerate everything. Common asks: "fewer characters", "swap the cat for a fox", "punchier dialog in beat 4", "make it 4:3", "add an episode".

If the user invoked with `--plan-only`, stop here. Tell them: *"Plan written to `<project-name>/`. Re-run without `--plan-only` to produce."*

---

### Step 7 — Produce

**Read `references/production-pipeline.md` for the full command sequences.** The short version:

1. **Generate canonical turnarounds** (one per character) — `gen-ai generate -m gemini-3.1-flash-image -p <turnaround-prompt> --script | jq -r .url` → save URL into `bible.json`. Reuse if `turnaround.png` already exists (resumable).

2. **Generate location plates** — same call, one per location. Cache via URL in `locations.json`.

3. **For each beat**, in order:
   a. **Composite scene image** — `gen-ai generate -m gemini-3.1-flash-image -i <char-refs...> -i <location> -i <props...> -p <scene-composite-prompt>` → single scene image with all characters + location locked.
   b. **Generate TTS** (dialog beats only) — `gen-ai generate -m eleven-v3 -p "<dialog text>" --voice <voiceId>` → audio URL.
   c. **Generate video** — type-aware routing:
      - Dialog beats: `gen-ai generate -m kling-avatar -i <scene-composite-url> --audio <tts-url> -p <motion-prompt>` → lip-synced talking head.
      - Non-dialog beats: `gen-ai generate -m kling-3.0-pro -i <scene-composite-url> -p <motion-prompt> -d <duration> --aspect-ratio <ratio>` → beat mp4 with native ambient audio.
      - Fallback on content-filter rejection: `kling-omni` (multi-ref, silent → layer ambient with `kling-v2a`).
   d. Write `metadata.json` with all URLs + model used + resolved prompt. This is the resume token — if a beat fails, the script re-runs only that beat next invocation.

4. **Concatenate** — ffmpeg xfade concat of all beat mp4s → `movie.mp4` (single film) or `episodes/e01-slug/episode.mp4` (per episode).

5. **Write social copy** — render `socialCopyTemplates` through `references/social-copy-format.md` into `social-copy.txt` + `social-copy-<char>.txt` per posting character.

**Hard rules enforced by scripts:**
- Before any video call: assert at least one `-i` ref image is passed (the composite). **T2V is forbidden.** Script errors out if the beat has zero refs.
- Aspect ratio is read once from `project.json` and passed to every video call. Mixing ratios breaks concat — `concat-with-xfade.sh` normalizes (scale + pad) to a common resolution as a safety net.
- If a beat already has a valid `metadata.json` with a downloaded `beat.mp4`, skip it (resume-safe).
- **Type-aware routing with fallback:** dialog beats → `kling-avatar` (lip-sync) → `kling-omni` (silent fallback); non-dialog beats → `kling-3.0-pro` (1080p + native audio) → `kling-omni` (silent fallback). When Kling Omni is used, the pipeline layers ambient audio back on with `kling-v2a`. `metadata.json.model` records which model actually produced the clip.

Run scripts via the bundled helpers:

```bash
bash ~/.claude/skills/film-maker/scripts/produce.sh <project-dir>
```

---

### Step 8 — Deliver

Tell the user exactly where the output is and what to check:

```
✓ Done.

Final video: ./<project-name>/movie.mp4
   (or episodes/e01-slug/episode.mp4, e02-slug/episode.mp4, ...)

Social copy: ./<project-name>/social-copy.txt
   Per-character: ./<project-name>/social-copy-<char>.txt

Resume anytime by re-running — completed beats are cached.
```

If any beat failed during production, surface the failure clearly — don't silently skip. Include the specific error and the re-run command for that beat.

---

## Hard rules (non-negotiable)

1. **No text-to-video, ever.** Every video beat must pass at least one reference image. Scripts enforce.
2. **Character image MUST flow through to video generation.** When a beat has characters, the video model receives:
   - **Single-ref primary** (kling-3.0-pro, kling-avatar): the composite.png (itself generated by Nano Banana 2 from character canonicals + location plate). The composite is the carrier — it must be high quality and identity-faithful.
   - **Multi-ref fallback** (kling-omni): composite.png **+ each character's turnaround.png** as parallel refs, used when the primary model rejects the scene.
3. **Audio must be natively generated, never overlaid as voice-over.** Every beat ships with scene audio produced by a model:
   - `kling-3.0-pro` generates ambient natively during the video call.
   - `kling-avatar` is the dialog path — it reads the TTS waveform and drives the lips to it, producing genuine lip-synced speech (not "voice-over on a face").
   - `kling-omni` output is silent; the pipeline layers ambient back on with `kling-v2a` from the same motion prompt.
4. **Canonicals are neutral 5-view turnaround sheets on white.** Never bake emotion, scene, or pose into the canonical. Emotions live at the beat layer.
5. **Aspect ratio locks at the project level.** All beats in a project share the same ratio. Mixing breaks concat — `concat-with-xfade.sh` normalizes as a safety net.
6. **Dialog beats are solo AND speaker-focused.** One character in frame when they speak, and NO props or competing animate-able subjects. Shot size is MCU or tighter. Video models match mouth motion to audio — if a prop is in frame, the prop can "start talking." Whatever the character is reacting TO goes in a SEPARATE beat before/after (classic shot/reverse-shot). Beat duration ≈ TTS line length + small pad, not arbitrary 5s.
7. **Every character referenced in a prompt must be in `references.images`.** No "ghost" characters — Claude must not describe a character in a prompt that isn't passed as a ref.
8. **Resumable by design.** Never delete existing `metadata.json` or `beat.mp4` during a re-run. Each beat is atomic.

## Folder structure

Every project follows this layout. Don't improvise.

```
<project-name>/
  project.json                 # genre, aspect, aesthetic, status
  plot.md                      # written story, human-readable
  characters/
    <char-id>/
      bible.json
      turnaround.png           # 5-view canonical grid (cached, reused)
      assets/                  # per-scene composites if cached
  locations/
    locations.json
    <location-id>.png          # empty plate (cached)
  props/
    <prop-id>.png              # optional
  # If single film:
  scenario.json
  beats/
    b01-<name>/
      metadata.json
      composite.png
      audio.wav                # only if dialog
      beat.mp4
  movie.mp4
  social-copy.txt
  social-copy-<char>.txt
  # If series:
  episodes/
    e01-<slug>/
      scenario.json
      beats/ ...
      episode.mp4
      social-copy.txt
```

## `--plan-only` mode

If the user invokes with `--plan-only` or says "just plan", "don't generate yet", "I want to see the plan first":
- Do Steps 1–6 fully
- **Skip Step 7 entirely** (no `gen-ai` calls for images, video, or audio)
- Still write the full project folder structure (plot.md, character bibles, scenario.json, locations.json) — everything except the generated binary assets
- Tell the user: *"Plan written. Re-run without `--plan-only` to produce."*

This lets users (and the film-maker eval suite) inspect the creative output before committing credits. It's also how tests run — zero credits spent.

## References — read when relevant

- `references/genre-catalog.md` — the 14 core genres + tone modifiers + blend rules
- `references/genre-playbooks/<genre>.md` — per-genre structural + tonal rules (read the one(s) that apply)
- `references/character-design.md` — bible-writing rules, visual specificity techniques
- `references/canonical-turnaround-rules.md` — the mandatory 5-view sheet spec + prompt template
- `references/location-design.md` — empty-plate prompt rules
- `references/beat-types.md` — dialog / reaction / establishing conventions
- `references/shot-cards.md` — camera vocabulary + how to write director-quality beat prompts
- `references/pacing.md` — beat-to-beat rhythm rules
- `references/voice-tuning.md` — TTS voiceConfig per personality type
- `references/social-copy.md` — platform captions (IG / TikTok / YouTube) + required hashtags
- `references/production-pipeline.md` — full `gen-ai` CLI commands per step
- `references/model-cheatsheet.md` — which gen-ai model for which task + fallbacks
- `references/credits-estimation.md` — rough credit cost per beat type (for the review checkpoint)
- `references/prompt-craft.md` — **read before writing any prompt** — counting rules, negative prompts, hand/extremity safeguards, identity consistency, quality-control patterns. Skipping this is how you end up with 3 shoes instead of 2.

## Common user asks

- *"Make me a reel about X"* — full pipeline, 9:16, 1 beat or a short multi-beat reel
- *"Turn this premise into a short film"* — 16:9 default, multi-beat, one continuous narrative
- *"Create an N-episode series about..."* — episodic structure, N scenarios, per-episode outputs
- *"Just plan it first"* / *"don't spend credits yet"* — `--plan-only`
- *"Fix beat 4"* / *"regenerate the Nova canonical"* — targeted re-run; change the relevant file + delete the stale `metadata.json` for that beat, then re-run produce.sh
- *"Add a character"* / *"drop a location"* — edit `scenario.json` + `characters/` or `locations/`, re-run produce.sh (it's resumable)
