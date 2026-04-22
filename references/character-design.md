# Character Design — Writing Bibles That Hold

A character bible isn't flavor text. It's the contract the model uses to redraw the same person across 30 different beats. If the bible is vague, every beat produces a different character. If the bible is specific, you get identity consistency.

## The rule: specific beats impressionistic

Amateur prompt: *"a tough detective"*.
Professional prompt: *"A 42-year-old man with a boxer's nose broken twice, salt-and-pepper stubble, a scar that splits his left eyebrow, dark brown eyes that don't blink often, wearing a charcoal wool coat he's slept in, gold wedding band on his left ring finger — except the ring is on a chain around his neck now."*

The second one tells you who he is and what the image should look like. The first one is a coin flip.

## The five slots that matter most

When writing `physicalDescription` + `consistencyAnchors`, prioritize these:

1. **Face signature** — one or two specific facial features that lock identity. Scar, mole, distinctive nose, specific eye color, jaw shape, jewelry in the face.
2. **Hair** — length, texture, color (hex if possible), how it's worn (up/down/braided), the way it moves.
3. **Skin** — color if not default, texture (freckles? visible pores? scars? tattoos?), distinguishing marks.
4. **Silhouette-defining wardrobe** — the one item that, in shadow from across a room, identifies them. The trench coat. The leaf crown. The combat boots. The silver chain.
5. **Body language signature** — the posture or gesture that is visible even in a still (slouched vs. ramrod, crossed arms as default, hands in pockets, chin up, shoulders tight).

If those five are specific and locked, the rest handles itself.

## Consistency anchors — the commitment list

`consistencyAnchors` in the bible is the 4–8 bullets that **must be visible in every generation**. These get injected into every downstream prompt (turnaround, scene composite, beat). Examples:

Villa-7 Nova:
```
- Bright red strawberry head covered in yellow seeds
- Green leaf crown at top like a tiara
- Long dark hair with red highlights from under leaf crown
- Gorgeous doe brown eyes with long lashes
- Pregnant belly
- Off-shoulder red satin maternity gown
- Gold chains and gold cuff bracelet
- White sneakers with red accents
```

Realistic detective:
```
- 42 years old, weathered face
- Scar splitting left eyebrow
- Salt-and-pepper stubble, dark hair going gray at temples
- Gold wedding ring worn on chain around neck (not on finger)
- Charcoal wool coat, slightly oversized
- Dark brown eyes, rarely blinks
- 6'1", broad-shouldered but slightly hunched
```

Rule of thumb: if a bullet is true in Act I, it's true in Act III. If it changes during the story (wedding ring comes back onto finger as emotional beat), capture the change as a **scene-specific prompt override**, not in the canonical anchors.

## Form — the genre-agnostic slot

The bible's `form` slot tells every prompt how to describe the character. It's free-form:

| Form value | How the turnaround + scene prompts read |
|---|---|
| "human, female, late 20s" | "A woman in her late 20s, [descriptors]..." |
| "anthropomorphic strawberry with human female body" | "A 3D anthropomorphic strawberry character with a full female body, strawberry head, [descriptors]..." |
| "Golden Retriever dog, male, 3 years old" | "A golden retriever dog, [descriptors]..." |
| "android unit, humanoid, chrome-and-glass aesthetic" | "A humanoid android with chrome and glass surfaces, [descriptors]..." |
| "sentient fog entity, shifting form" | "A shifting fog-like sentient entity, [descriptors]..." |

Don't let the form constrain creative latitude — but it does determine what "a character turnaround" means (a humanoid gets 5 views; a fog entity gets 3–4 representative views).

## Personality drives dialog tone

`personality` doesn't affect the image, but it governs how you write this character's dialog lines. Fill it:

- **coreTraits** — 3–5 adjectives
- **quirks** — observable behaviors (touches their wedding ring when lying, looks out windows during confrontations, taps a pen while thinking)
- **speechPatterns** — how do they construct sentences? Lowercase? Fragments? Formal? Profanity? Quotes philosophers?
- **catchphrases** — 2–4 recurring short lines you can reach for in dialog beats
- **contradictions** — the tension inside them; the thing that makes them interesting (seems cold but is protecting vulnerability, the most honest person reads as the most dangerous)

When you write a dialog beat for this character, read their personality slot first. Every line should sound like them, not generic human speech.

## Every bible MUST ship with a locked voiceId

A bible where `voiceConfig.voiceId` is `null` will make that character sound like a default (generic Rachel voice). Every character loses their distinctiveness. Voice consistency across a project requires that when the bible is written, Claude picks a specific voiceId from the library in `references/voice-tuning.md` and writes it into the bible permanently.

**Step when drafting a bible:** open `references/voice-tuning.md`, match the character's form/voice-description/personality to the closest preset, and copy that voiceId + suggested settings into `voiceConfig`. Never leave `voiceId: null`.

## The voice config guide

`voiceConfig.settings` tune the TTS voice. Some rough recipes:

| Character type | stability | similarityBoost | style | notes |
|---|---|---|---|---|
| Soft-spoken, precise | 0.65 | 0.85 | 0.25 | Low style keeps delivery quiet |
| Declarative, unbothered | 0.75 | 0.8 | 0.2 | High stability = flat pitch |
| Charming, smooth | 0.5 | 0.75 | 0.6 | Higher style = more warmth/expression |
| Measured, formal | 0.8 | 0.85 | 0.15 | Very stable + low style = gravitas |
| Chaotic, expressive | 0.4 | 0.7 | 0.55 | Lower stability lets it range |
| Deadpan comedy | 0.75 | 0.8 | 0.2 | Flat delivery makes punchlines land |

`voiceConfig.description` in the bible is a one-sentence note to yourself on how the character sounds — use it when writing dialog lines to stay in voice.

## When a character is described too vaguely

If the user hands you a premise where characters are one-word sketches ("the villain", "a gardener"), **invent specificity** when writing the bible. Pick a face signature, a distinctive feature, a wardrobe signature, a body language signature. Show the bible to the user in the Review checkpoint — they'll redirect if they had something specific in mind. Vague bibles = identity drift in the final video. Don't let that happen.
