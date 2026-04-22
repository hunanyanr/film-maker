# Voice Tuning — TTS Settings Cookbook

Each character in the bible gets a `voiceConfig` block. The `settings` inside control how ElevenLabs v3 delivers their lines. Tune per personality — the same text with different settings becomes a completely different character.

## The four knobs

| Setting | Range | Effect |
|---|---|---|
| `stability` | 0.0–1.0 | How "flat" the pitch is. Low = expressive/variable. High = consistent/flat. |
| `similarityBoost` | 0.0–1.0 | How closely it matches the reference voice. Higher = more like the voice, less improvisation. |
| `style` | 0.0–1.0 | How much emotional range. Low = measured/controlled. High = animated/theatrical. |
| `useSpeakerBoost` | bool | Enhances clarity at the cost of some naturalness. Usually `true`. |

Default safe starting point for any character: `0.6 / 0.8 / 0.3 / true`. Adjust from there.

## Recipes per personality type

### Soft-spoken, precise (Nova, quiet protagonist)
```json
{ "stability": 0.65, "similarityBoost": 0.85, "style": 0.25, "useSpeakerBoost": true }
```
Low style keeps delivery quiet. Higher stability prevents melodrama. The line "it's fine." lands devastating because nothing in the voice breaks.

### Declarative, unbothered (Zara, villain-who's-right)
```json
{ "stability": 0.75, "similarityBoost": 0.80, "style": 0.20, "useSpeakerBoost": true }
```
Flat pitch (high stability), minimal emotional range (low style). "she could've just asked" delivered as a verdict.

### Charming, smooth (Dante, seducer/manipulator)
```json
{ "stability": 0.50, "similarityBoost": 0.75, "style": 0.60, "useSpeakerBoost": true }
```
Higher style = more warmth/performance. Lower stability = natural pitch variation. Charming voices need range.

### Measured, formal (Elena, elder power player)
```json
{ "stability": 0.80, "similarityBoost": 0.85, "style": 0.15, "useSpeakerBoost": true }
```
Very stable + low style = gravitas. Every word sounds chosen.

### Chaotic, expressive (Bean, chaotic intern / Marco, rambler)
```json
{ "stability": 0.40, "similarityBoost": 0.70, "style": 0.55, "useSpeakerBoost": true }
```
Lower stability lets pitch range wildly. High style allows the voice to carry emotion all over the place. Good for stream-of-consciousness.

### Deadpan comedy
```json
{ "stability": 0.75, "similarityBoost": 0.80, "style": 0.20, "useSpeakerBoost": true }
```
Flat delivery makes punchlines land. The joke is in the contrast between ridiculous content and deadpan voice.

### Cynical noir detective
```json
{ "stability": 0.70, "similarityBoost": 0.80, "style": 0.30, "useSpeakerBoost": true }
```
Slight range (0.30 style) to allow weariness, but still measured. Voice-over friendly.

### Excited hype (ALL CAPS Nugget-type character)
```json
{ "stability": 0.35, "similarityBoost": 0.70, "style": 0.70, "useSpeakerBoost": true }
```
Low stability + high style = maximum expression. Voice can crack into caps.

### Android / emotionally reserved AI
```json
{ "stability": 0.90, "similarityBoost": 0.85, "style": 0.10, "useSpeakerBoost": true }
```
Near-flat delivery. The smallest style variation reads as a glitch — emotional signal becomes rare and therefore meaningful.

### Dramatic, heightened (soap opera villain speech)
```json
{ "stability": 0.45, "similarityBoost": 0.75, "style": 0.65, "useSpeakerBoost": true }
```
Lower stability + high style = operatic. Good for monologue reveals.

## Choosing a `voiceId` — MANDATORY when writing every bible

**`voiceId` must NEVER be `null` in a shipped bible.** If it's null at TTS time, the pipeline falls back to a generic voice (Rachel), and every character ends up sounding the same. Voice consistency across a project depends on each character having a **locked, unique voiceId** that's picked when the bible is written and reused for every line that character speaks.

### The rule when writing a bible

For each character, match their `voiceDescription` / `personality` / `form` to the closest entry in the library below, and write that voice's ID into `voiceConfig.voiceId`. Once set, **never change it** within a project — the whole point is that Cole always sounds like Cole.

### Voice library — curated ElevenLabs presets

**Female voices:**

| Archetype | Name | voiceId | Best for |
|---|---|---|---|
| Young, warm, approachable | Rachel | `21m00Tcm4TlvDq8ikWAM` | protagonist, girl-next-door, friendly narrator |
| Mature, measured, regal | Dorothy | `ThT5KcBeYPX3keUQqHPh` | matriarch, elder mentor, authority figure |
| Sultry, confident | Bella | `EXAVITQu4vr4xnSDxMAl` | femme fatale, villain-who's-right, seductress |
| Flat, deadpan, cool | Domi | `AZnzlk1XvdvUeBnXmlld` | unbothered villain, dry comedy, android |
| Warm, older, grandmother-ish | Elli | `MF3mGyEYCl7XYWbV9V6O` | fable narrator, maternal figure |
| Young, expressive, chaotic | Freya | `jsCqWAovK2LkecY7zXl4` | chaotic intern, gen-z, brainrot voice |

**Male voices:**

| Archetype | Name | voiceId | Best for |
|---|---|---|---|
| Young, warm, earnest | Josh | `TxGEqnHWrfWFTfGW9XjX` | idealist, young hero, romantic lead |
| Mature, smooth, charming | Arnold | `VR6AewLTigWG4xSOukaG` | charming villain, seducer, Italian playboy |
| Deep, warm, grounded | Daniel | `onwK4e9ZLuTAKqWW03F9` | weary detective, father figure, noir protagonist |
| Gravelly, weathered | Adam | `pNInz6obpgDQGcFmaJgB` | old cop, grizzled veteran, cynical narrator |
| Authoritative, mature | Antoni | `ErXwobaYiN019PkySvjV` | CEO, king, commanding authority |
| Soft-spoken, thoughtful | Clyde | `2EiwWnXFnvU5JabPnv8n` | philosopher, gentle mentor, quiet confession |
| Young, energetic, upbeat | Sam | `yoZ06aMxZJJ28mfd3POQ` | comic relief, excited friend, hype voice |

**Androgynous / distinctive:**

| Archetype | Name | voiceId | Best for |
|---|---|---|---|
| Dry, non-binary, cryptic | Glinda | `z9fAnlkpzviPz146aGWa` | wildcard character, mysterious arrival |
| Theatrical, melodramatic | Charlie | `IKne3meq5aSn9XLyUdCD` | soap-opera villain, heightened performer |

### Matching logic — what to read from the bible

Look at these fields to pick the voice:

1. **`form`** — gender, age range, species (if non-human, still pick nearest human analog)
2. **`voiceConfig.description`** — the 1–2 sentence voice note you wrote when drafting the bible
3. **`personality.coreTraits`** — calm/chaotic, measured/expressive, warm/cold
4. **`role`** — protagonist, villain, mentor, etc.

Example match for a Villa-7-style character:

```
Bible: Nova — strawberry character, late 20s female, "soft-spoken but precise. When hurt she gets quieter, not louder."
→ voiceId: Rachel (young warm female) + low style setting for the soft-spoken precision
  = { voiceId: "21m00Tcm4TlvDq8ikWAM", stability: 0.65, similarityBoost: 0.85, style: 0.25 }

Bible: Zara — dragon fruit character, late 20s female, "declarative, unbothered, flat delivery"
→ voiceId: Domi (flat deadpan)
  = { voiceId: "AZnzlk1XvdvUeBnXmlld", stability: 0.75, similarityBoost: 0.80, style: 0.20 }

Bible: Dante — pineapple character, early 30s male, "charming, confident, smooth talker"
→ voiceId: Arnold (mature smooth charming)
  = { voiceId: "VR6AewLTigWG4xSOukaG", stability: 0.50, similarityBoost: 0.75, style: 0.60 }
```

### When none fit

If the library doesn't have a match, default to the closest gender/age voice and raise the `style` to compensate (expressive) or lower `stability` (ranges more). Still prefer a locked preset over a null voiceId — consistency beats perfection.

### Future: custom voice generation

For projects needing truly unique voices per character, `eleven-voice-design-v3` on the gen-ai CLI generates a voice from a text description. The returned voiceId gets locked into the bible the same way. This is a future enhancement; the preset library above is the default today.

## Writing the `description` field in voiceConfig

Always fill `voiceConfig.description` with a one-line note to yourself. This is what you read when writing dialog beats to stay in voice. Examples:

- *"Quiet. Precise. Every word chosen. When hurt, gets quieter not louder."*
- *"Flat, declarative, unbothered. Never rises in pitch. Short sentences delivered like verdicts."*
- *"Charming, confident, slightly poetic. Italian accent undertone. Smooth talker."*
- *"Measured, deliberate, formal. Every word chosen with precision. Low register."*

This field has no effect on TTS generation — it's for Claude's own dialog-writing consistency. But it's essential.

## Tuning mid-project

If a generated voice doesn't feel right, adjust the settings in the bible and re-run TTS for the affected beats. Settings changes are fast — you don't need to regenerate video (you can overlay new audio with ffmpeg if needed). Don't be afraid to iterate on voice.
