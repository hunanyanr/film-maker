# Beat Types

A beat is one shot or one tight multi-shot sequence. Every scenario breaks into a sequence of beats. There are three types — each has different rules, different reference requirements, and different video models behind it.

## The three types

### `establishing`
**Purpose:** Set location, mood, or time. Wide or environmental. Sometimes includes characters at distance, sometimes just the empty world.

- **Characters in frame:** 0 to N
- **Dialog:** No
- **References required:** location plate (always), character canonicals (if any visible)
- **Typical duration:** 3–6 seconds
- **Camera defaults:** slow dolly, slow push-in, or locked
- **Why it exists:** Grounds the viewer in where/when. Without it, every scene starts floating in nowhere.

**Example:** *"Wide establishing shot of the neon alley at 2am, rain-slick pavement, steam from a vent, distant police sirens. No people. Slow dolly in from street mouth toward the dumpsters at the far end."*

### `reaction`
**Purpose:** Visual storytelling. Characters do things, see things, react to things — but don't talk.

- **Characters in frame:** 1 to N
- **Dialog:** No
- **References required:** every character visible + location + any props
- **Typical duration:** 4–8 seconds
- **Camera defaults:** medium shot, rack focus, orbit, handheld, push-in
- **Why it exists:** This is where story happens. Well-chosen reaction beats do more narrative work than any line of dialog.

**Example:** *"Close-up on Nova's hand as she places the photograph face-down on the desk. Rack focus to her face — she looks past camera at the door, waiting. She exhales slowly. 6 seconds."*

### `dialog`
**Purpose:** One character speaks. A line, a monologue, a confession, a threat, a question.

- **Characters in frame:** **1 only** (SOLO — see below)
- **Dialog:** Yes (`dialog.text` required, `dialog.emotion` required)
- **References required:** speaker's canonical + location + audio (TTS will be generated)
- **Typical duration:** 5–15 seconds (matches spoken length + beat of silence)
- **Camera defaults:** medium close-up, close-up, ECU for intimacy; slow push-in during the line
- **Why solo:** `kling-avatar` (the dialog path) reads the audio waveform and drives the lips to match. It is reliable when there's exactly one face to animate. Multiple characters in frame during a dialog beat = garbled lip-sync, wrong speaker animated, or both mouths moving. Cut to the listener in a separate reaction beat if you need their reaction.

**Example:**
```json
{
  "type": "dialog",
  "character": "cole",
  "characters": ["cole"],
  "description": "Cole's confession that he knew she was at risk",
  "references": {
    "images": ["cole"],
    "locations": ["hospital-hallway"],
    "audio": "cole"
  },
  "prompt": "Medium close-up. @Image1 Cole sits slumped in a plastic hospital chair, lit by harsh fluorescents, his tie loosened. Slow push-in on his face during the line. He doesn't look at camera — he looks at the closed door where she was wheeled in. @Image1 speaks with the voice from @Audio1. Exhausted, stripped of charm, truth leaking out. 8s.",
  "duration": 8,
  "dialog": {
    "speaker": "cole",
    "text": "I knew. I knew she was going to be there. And I let her go anyway.",
    "emotion": "flat, devastated, each sentence a small collapse"
  }
}
```

## The solo rule for dialog

**This is a hard rule. Dialog beats have exactly one character in `characters[]`.** If two characters need to talk in a scene, you write TWO dialog beats back to back — one per speaker — with appropriate reaction cuts between if needed. Think of it as classic shot/reverse-shot coverage:

```
b03-cole-asks       dialog    [cole]       "Where were you last night?"
b04-nova-reacts     reaction  [nova]       Nova looks at him, unflinching, doesn't answer immediately. 3s.
b05-nova-answers    dialog    [nova]       "Somewhere you wouldn't follow."
```

Three beats, two speakers, clean lip-sync on each, and the reaction beat gives the scene breath. This is how cinema has always worked.

## The speaker-focused composition rule for dialog beats

**Dialog beats must be tight on the speaker's face. No competing animate-able subjects in frame.**

Why this matters — learned the hard way:

Video models (kling-omni, kling-avatar, etc.) try to match mouth motion to the audio track. If the composite has a face AND another object that could plausibly be "a mouth" (an open shoe, a pair of lips on a poster, a slightly parted door, a letter opening in the wind, even a fork), the model can pick the wrong thing to animate. Result: **the object starts "talking"** — shoes wobble to the rhythm of the dialog, posters flutter like lips, fabric ripples in sync with syllables. This is the *"talking shoes" failure mode*.

Avoid it by making the speaker's face the **only** candidate for lip-motion animation:

- **Shot size**: MCU (medium close-up) at widest, CU (close-up) ideal, ECU (extreme close-up) for intimate moments
- **Frame content**: speaker's face dominates. Background clean / soft / out of focus
- **NO PROPS in frame** during dialog beats. If a prop matters to the scene, it gets its **own reaction beat** BEFORE or AFTER the dialog beat, never during
- **NO other characters**, even in background, even silhouetted (see solo rule above)
- **NO text that could be read** (signs, captions, readable objects)
- **Background elements should be static or softly moving** (rain, steam, shadow) — not anything with a mouth-like opening or that could sway rhythmically

**Wrong (composite leads to talking shoes):**
> Cole kneels in the alley, camera low, Cole's face and a pair of tan oxford shoes both prominent in frame. Dialog: "She wasn't supposed to be here."

**Right (separate beats):**
> b03 — reaction — CU on the shoes on wet pavement. Rack focus hint of Cole's knee in background. 4s. No dialog.
> b04 — dialog — MCU on Cole's face, out-of-focus alley bokeh behind him, shoes NOT in frame. 4s. Dialog: "She wasn't supposed to be here."

This is the same discipline as classic cinema coverage: show what the character sees, then cut to the character reacting/speaking. Never the two in one shot when the character has a line.

### Quick checklist when writing a dialog beat

Before finalizing a dialog beat, verify:
- [ ] Only the speaker is in `characters[]`
- [ ] `references.props` is EMPTY or contains only stationary non-mouth-like elements (a ring on the finger is fine; a pair of shoes, a letter, a phone, a book are NOT)
- [ ] Shot size is MCU, CU, or ECU (not Medium-Wide or wider)
- [ ] Prompt explicitly describes the speaker's mouth/face doing the talking
- [ ] Beat duration is close to the TTS line length + small pad (not 5s for a 1.5s line)

Fail any of these → reframe the beat.

## Distribution in a well-paced scenario

A good scenario mixes beat types. Don't do 8 dialog beats in a row (it becomes a radio play with static images) or 8 reaction beats in a row (the audience loses plot).

Rough rhythm guide:
- **Opening:** 1 establishing
- **Mid:** alternate reaction / dialog, with occasional re-establishing when location changes
- **Climax:** close-ups dominate (reactions + dialog at tight framing)
- **Close:** 1 wide reaction or re-establishing to release tension

Villa-7 Episode 1 is a good reference — 8 beats: 1 establishing, 4 reactions, 3 dialog, alternating.

## Reference binding via `@Image` / `@Audio` tags

Every beat prompt binds references to entities using tags. The tag numbering matches the **order** in `references.images[]` + `references.locations[]` + `references.props[]` + (for dialog) `references.audio`:

```json
"references": {
  "images": ["cole", "nova"],
  "locations": ["hospital-hallway"],
  "audio": "cole"
}
"prompt": "... @Image1 Cole slumps in a chair ... @Image2 Nova stands in the doorway ... in @Image3 a sterile hospital hallway ... @Image1 speaks with the voice from @Audio1..."
```

Order: images (in order), then locations, then props, then audio. `@Image1` = first char, `@Image2` = second char, `@Image3` = first location, etc.

**Every character, location, and prop mentioned in the prompt text must exist in the references array.** Don't describe "a pomegranate on the counter" in the prompt if the pomegranate prop isn't in `references.props`.
