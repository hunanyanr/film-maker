# Prompt Craft — Avoiding Common AI Generation Traps

Image and video models fail in predictable ways. Professional output means writing prompts that pre-empt those failures. This reference covers the specific traps the skill has hit during production and the patterns that work around them.

## 1. Counting — the single most common failure

AI image models struggle with exact quantities. *"A pair of shoes"* routinely yields 3 shoes, 1 shoe, or 4 shoes. *"Two characters"* yields 3 or 4 shadowy extras.

**The fix: reinforce the count at least twice, using different phrasings, and include a concrete spatial layout.**

### Bad — ambiguous count
```
A pair of tan oxford shoes on wet pavement.
```
Result: model might render 3 shoes, or a single shoe and its reflection interpreted as another, or a line of shoes.

### Good — count reinforced three ways
```
EXACTLY TWO SHOES, NO MORE NO LESS. A single pair of tan oxford shoes —
one left shoe and one right shoe — placed neatly side-by-side on wet pavement.
Two shoes total, positioned parallel, visible from above at 3/4 angle.
Do not include extra shoes, stray footwear, or multiple pairs.
```

### The counting-lock pattern, generalized

For any count-sensitive element:
1. **State the number in words AND digits**: "two (2) shoes"
2. **Describe the spatial layout**: "one left, one right, placed parallel"
3. **Say what it's NOT**: "no additional shoes in the background"
4. **Add to negative prompt** (when model supports): "extra shoes, multiple pairs, stray footwear"

| Element | Count-sensitive? | Prompt rule |
|---|---|---|
| Shoes, gloves, eyes, earrings (pairs) | Yes | "exactly two ... one left, one right" |
| Single prop (photograph, letter, vial) | Yes | "a single ... only one ... no duplicates" |
| Small groups (3-6 people, candles) | Yes | Spell out each position |
| Large crowds | Less sensitive | "a crowd of ~20" is fine |
| Uncountable (grass, rain, stars) | No | Describe by density instead |

## 2. Characters in multi-person scenes

Two-character composites frequently produce three-character outputs (the model invents a background figure) or merge features across characters.

### Rules
- **State the exact number of people in frame at the top**: "TWO PEOPLE IN FRAME — no one else visible."
- **Describe each character with a spatial anchor**: "Nova on the left / Zara on the right"
- **Give each character distinct attire**: if both wear similar colors, the model may blend them
- **Forbid extras**: "no background figures, no onlookers, no passersby, no reflections of people"

### Example (from Villa-7)
```
TWO PEOPLE IN FRAME — no one else visible. On the LEFT: @Image1 Nova, a pregnant
strawberry character in a red satin gown, seated at the table. On the RIGHT,
approaching from behind: @Image2 Zara, a dragon fruit character in a black
leather jacket, holding a silver tray. No additional people, no reflections of
other figures, no shadows suggesting a third person.
```

## 3. Negative prompts — use them for every image and video call

Most gen-ai models support `--negative-prompt`. Use it. A strong negative prompt prevents:
- Extra limbs (hands, fingers, arms)
- Duplicate/mirror artifacts
- Text or logos sneaking in
- Low-quality textures, blur, ugly hands
- AI-style artifacts the model falls back to when uncertain

### Default negative prompt for the film-maker skill

```
extra limbs, duplicate limbs, malformed hands, extra fingers, missing fingers,
extra characters, duplicate characters, ghost figures, background people,
text, watermark, logo, signature, caption, subtitles, timestamps,
blurry, low resolution, pixelated, oversaturated, bad composition,
deformed face, asymmetric eyes, distorted features,
plastic skin, uncanny valley, amateur lighting, harsh flash.
```

For count-sensitive prompts, add the specific forbidden items:
`..., extra shoes, three shoes, multiple pairs of shoes, ...`

## 4. Hands and extremities

Hands are where image models most often collapse. Extra fingers, merged fingers, unnatural poses.

- **If hands are not important to the shot**, keep them out: "hands out of frame" or "hands in pockets" or "hands tucked behind back"
- **If hands are in frame and doing something specific**, describe the pose precisely: "her right hand rests on the glass, fingers relaxed and visible, thumb and index finger curled around the stem"
- **For motion control/video**: always append "preserve natural hand and finger structure, do not distort extremities" — this is the standard villa-7 motion-control safeguard

## 5. Text in images

Models produce garbled text most of the time. If the shot needs legible text (a letter, a sign, a newspaper):

- **Keep text short** — one line, 3–5 words max
- **Specify it exactly in quotes**: `the sign reads "PARADISO" in red neon`
- **Use models that handle text well** — `gemini-3.1-flash-image` (Nano Banana 2) has a "Text Rendering" feature
- **Otherwise blur the text**: "illegible newspaper on the counter" is more reliable than specific copy

## 6. Identity consistency traps

When generating composites with multiple character refs:

- **Name each character inline with their tag**: `@Image1 Nova (the pregnant strawberry character)` not just `@Image1`
- **Repeat distinguishing features** in the prompt, not just in the bible: "@Image1 Nova — note her green leaf crown and long dark hair with red highlights"
- **Never describe a character differently** than their bible says. If the bible says "long dark hair" and the prompt says "blonde hair", the model will compromise and produce inconsistent output.

## 7. Verify every generated image before moving on

Before producing a video from a composite scene image, look at the composite:

- Count the characters (match the scenario's `characters[]`?)
- Count the props (correct quantity?)
- Check hands and extremities
- Check that no extra figures/objects appeared
- Verify character identity matches canonical

If any of these fail, **regenerate the composite** — cheaper than regenerating a full video call.

**This is a production-quality discipline, not a nice-to-have.** A scene with 3 shoes in the composite produces a video with 3 shoes. A misplaced shadow figure persists across every frame.

## 8. Video motion prompts — describe intention, not just movement

Weak motion prompt: *"Nova walks across the room."*

Strong motion prompt: *"Nova (center of frame, entering from right) takes three deliberate steps toward the window (left of frame), her pace slowing on the last step. Camera dollies in slightly, matching her pace for the first two steps then holding as she slows. At her third step, rack focus from her silhouette to the rain-streaked window behind her. Emotional beat: the moment she decides not to answer the phone ringing offscreen."*

Specificity gives the video model the temporal structure it needs. Generic motion prompts produce generic motion.

## 9. Always re-read your prompt before submitting

Before every gen-ai call, read the assembled prompt as though you're the model:
- Do I know exactly how many of each thing?
- Do I know who is on the left vs right?
- Do I know what the camera does?
- Do I know what the viewer feels?

If any answer is vague, tighten the prompt before spending the credit.

## 10. Regenerate is cheap, debugging bad output is expensive

When a composite or video comes back wrong, don't try to fix it in post. Regenerate with a sharpened prompt. Image gen (Nano Banana 2) is ~3 credits per try — cheaper than patching a flawed output for an hour.

The skill's resume-safe design supports this: delete the offending `composite.png` and `metadata.json` for the affected beat, re-run `produce.sh`, and only that beat will regenerate.
