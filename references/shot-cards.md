# Shot Cards — How to Write Director-Quality Beat Prompts

A beat prompt is not a paragraph. It's a shot card. A director writing on an index card for a DP. Tight, specific, grammatical.

The difference between AI slop and cinematic output is almost entirely in how these prompts are written.

## The shot-card grammar

Every beat prompt should answer these four questions in this order:

1. **WHAT SHOT** — shot size + framing
2. **WHAT HAPPENS** — the character action, the event, the reveal
3. **HOW IT MOVES** — camera movement, lens feel
4. **HOW IT FEELS** — lighting, mood, emotional beat for the viewer

## Vocabulary — use these, don't invent

### Shot sizes
| Term | Meaning |
|---|---|
| ECU (extreme close-up) | Eye, mouth, hand — fills frame |
| CU (close-up) | Head, shoulders |
| MCU (medium close-up) | Chest up |
| Medium | Waist up |
| Cowboy | Mid-thigh up |
| Wide | Full body + space |
| Extreme wide | Character tiny in environment |
| Establishing | Location only or location with figures at distance |

### Camera movement
| Term | Meaning |
|---|---|
| **Locked** | Tripod, no movement. Stability implies control or dread. |
| **Dolly in / push-in** | Camera moves toward subject. Intensifies. |
| **Dolly out / pull-back** | Camera moves away. Reveals, isolates, or releases. |
| **Tracking** | Camera moves parallel to moving subject. |
| **Orbit / arc** | Camera circles subject. Cinematic for reveals. |
| **Handheld** | Organic shake, imperfect. Urgency, chaos, documentary. |
| **Steadicam** | Smooth following movement. Immersive. |
| **Rack focus** | Focus shifts between two planes. Reveals connections. |
| **Tilt up / down** | Frame pivots vertically. Reveals scale. |
| **Pan left / right** | Frame pivots horizontally. Follows action. |
| **Whip pan** | Fast pan, motion blur. Transition energy. |
| **Crane / aerial** | Lifts, reveals geography. |
| **Slow zoom** | Emotional intensification without movement. |

### Lens feel (optional but adds grammar)
| Term | Meaning |
|---|---|
| Wide anamorphic | 35mm-ish, slight distortion at edges, cinematic wide |
| 85mm portrait | Compressed, background blur, intimate |
| Macro | Extreme close-up, texture |
| Fish-eye | Heavy distortion, surreal/chaotic |
| Wide-angle POV | Subject looks handheld, you-are-there |

### Light direction + mood
| Term | Feel |
|---|---|
| Golden hour rim | Warm, hopeful, romantic, sunset-backed |
| Harsh overhead fluorescent | Clinical, exposed, unflattering (hospital, interrogation) |
| Soft window light | Gentle, intimate, morning |
| Neon reflection | Urban, nocturnal, noir |
| Single-source candlelight | Intimate, ceremonial, secretive |
| Chiaroscuro | Deep shadows with one light source, dramatic |
| Blue-hour ambient | Moody, pre-dawn, transitional |
| Top-down harsh | Interrogation, trapped, exposed |
| Backlit silhouette | Mysterious, anonymous, reveal-deferred |

## Examples — good vs bad

### Bad (AI-slop rhythm)
> *"Nova is in the kitchen making coffee. She looks sad. The camera shows her."*

Why it's bad: no shot, no movement, tells-not-shows ("sad"), generic "camera shows her."

### Good
> *"Medium close-up. @Image1 Nova stands at the kitchen counter, hands on the edge, head dropped. The kettle whistles — she doesn't move to get it. Slow push-in on her face, her eyes closed, shoulders tight. Warm morning window light, but she's half in shadow. 6s, no dialog."*

Why it works: specific shot size, specific action (doesn't move to the whistling kettle = grief), specific camera (slow push-in = intensifying), specific light (warm but she's in shadow = visual contradiction of her emotion), specific duration.

### Bad
> *"Cole walks down the alley at night. It's dark and scary."*

### Good
> *"Handheld, medium tracking behind @Image1 Cole's shoulders as he moves down @Image2 a narrow neon-lit alley at 2am. His breath visible in cold air. The camera matches his pace — slightly faster when he speeds up, then catches itself. He stops dead. Rack focus from his tense back to a body crumpled against the dumpsters at the alley's end. The neon signs above reflect blood-red in the wet pavement. Hold 2 seconds on the body before cutting. 8s, no dialog."*

## Emotional beat — the "how it feels"

This is the part most AI prompts skip. Tell the video model what the viewer should be feeling at specific moments:

- *"Slow push-in so the viewer feels the same dread she does."*
- *"The orbit continues even after she stops speaking — the camera doesn't let her escape."*
- *"Hard cut mid-phrase, leaving the line unfinished."*
- *"Hold beat of silence at the end. Viewer should feel like something is about to happen."*

This language isn't wasted — the Kling family and most modern video models respond to emotional + temporal cues.

## The `@Image` / `@Audio` binding

Always bind references by tag in the prompt text:

```
@Image1 Nova stands on @Image3 a sunlit terrace ... @Image2 Zara watches from @Image4 the shadows of the hallway ... @Image1 speaks with the voice from @Audio1.
```

**Tag order = order of `references.images[]` then `references.locations[]` then `references.props[]` then `references.audio`.** Never skip numbers; never mention a character in prose without tagging their image.

## Dialog beat shot-card template — speaker ONLY in frame

Dialog beats have an additional hard constraint: **the speaker's face must be the only animate-able element.** If any prop, character, or background element could read as "a mouth" to the model, it can start animating to the audio — the infamous "talking shoes" failure. See `references/beat-types.md` "speaker-focused composition rule" for the full explanation.

**Dialog beat shot card template:**

```
{MCU|CU|ECU} on @Image1 [character], {facing camera/3-quarter angle},
{lighting description}, background soft/out-of-focus/static.
[ACTION: character's mouth/face doing the talking — describe the specific
delivery: eyes flicker down, jaw tightens, swallows before speaking, etc.]
@Image1 speaks with the voice from @Audio1. Emotional beat: [what the
viewer feels at this line]. NO other characters, NO props, NO readable text,
NO swaying or rhythmic background elements in frame. {duration in seconds,
close to TTS line length}.
```

Example:

```
MCU on @Image1 Detective Cole, lit by a single flickering red neon source,
deep alley bokeh behind him out of focus, his face half in shadow. He looks
down at something offscreen (camera never cuts to it), jaw tightens, he
exhales once before the line, eyes unfocus — the grief catching up. @Image1
speaks with the voice from @Audio1. Emotional beat: the moment the
professional gives way to the man. NO other characters, NO props in frame,
NO movement in the background other than slow soft rain out of focus. 4s.
```

Notice: no shoes, no letter, no phone, nothing that could grow a mouth. The shoes Cole is reacting to live in the beat BEFORE this one (reaction beat, CU on the shoes, no Cole's face).

## One final rule

**Write the prompt you'd pay a human crew for.** If your prompt wouldn't make sense to a DP reading it cold on a shooting day, it won't make sense to a video model either. Specificity is kindness.
