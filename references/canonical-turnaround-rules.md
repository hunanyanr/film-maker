# Canonical Turnaround Rules

The canonical image is the **identity anchor for every downstream generation**. It must be a professional character reference sheet — not a mood portrait, not an emotional beat, not a hero pose. Think of it as a passport photo combined with a model sheet.

This is non-negotiable. Every character in the project gets a canonical turnaround, generated once and reused everywhere.

## What a canonical MUST be

1. **5-view turnaround grid** on a single image: **front / 3/4 front / side / 3/4 back / back**, evenly spaced, same scale, same eye line.
2. **Pure white background.** No environment, no props, no set dressing, no ambient color.
3. **Neutral expression only.** No smile, no frown, no smirk, no emotion of any kind. Mouth closed. Eyes forward and open.
4. **Default posture.** Arms at sides or slightly relaxed, standing upright. No dynamic pose, no action, no attitude.
5. **Uniform studio lighting** across all 5 views. Soft, even, no dramatic shadows.
6. **Identical outfit in all 5 views** — the character's signature/default wardrobe. No costume changes.
7. **Consistency anchors visible.** If the bible says "green leaf crown", "scar over left eyebrow", "always wears the gold bracelet" — those features must be clearly visible in front, 3/4, and side views.

## What a canonical MUST NOT be

- Smiling or emoting
- Set in a scene or environment
- Holding a prop (unless the prop is part of their permanent look)
- In a dynamic pose (running, reaching, turning mid-stride)
- Dramatically lit
- In a single view only (must be 5-view)
- In their character's emotional state (angry warrior, sad mother, etc.) — that all comes later at the beat layer

## Why it matters

Every beat image generation uses this canonical as one of the reference inputs. If the canonical carries emotion or a specific pose, those leak into every beat regardless of what the beat prompt asks for. If the canonical is a front-only portrait, the video model has to guess at angles it's never seen, and identity drifts shot-to-shot.

A proper 5-view turnaround on white gives the downstream models a full 3D identity signal they can rotate, reposition, and re-light freely.

## The canonical prompt template

Use this structure verbatim, substituting bible fields:

```
A character turnaround reference sheet showing the same character from FIVE angles
(front view, 3/4 front view, side view, 3/4 back view, back view), arranged left to
right across a single image, all at the same scale and eye line.

Subject: {{physicalDescription}}

Consistency anchors that MUST appear identically in every view:
{{consistencyAnchors as bulleted list}}

Outfit: {{wardrobe.signature joined}} — same outfit across all 5 views.

NEUTRAL EXPRESSION ONLY — closed mouth, no smile, no frown, no emotion, eyes
forward. Default posture — standing upright, arms at sides. No dynamic pose.

Pure solid white background. No scene, no props, no environment, no story.
Soft even studio lighting, no dramatic shadows, identical lighting across all
views. Character turnaround reference sheet / model sheet style.

Style: {{aesthetic}}

Aspect: 3:2 horizontal (wide frame to fit 5 views side by side)
```

The **aspect ratio for the canonical is always 3:2 horizontal**, regardless of the project's delivery aspect ratio. The turnaround is a reference artifact, not a delivery frame.

## Generation call

```bash
gen-ai generate -m gemini-3.1-flash-image \
  -p "<turnaround-prompt>" \
  --aspect-ratio "3:2" \
  --script | jq -r .url
```

Download to `characters/<char-id>/turnaround.png` and write the URL + local path back into `bible.json` (`canonicalImage` + `turnaroundPath`).

**If the first generation carries emotion or drops to single-view:** regenerate with a sharper prompt — lead with the "5-VIEW TURNAROUND SHEET, NEUTRAL EXPRESSION, WHITE BACKGROUND" instruction first, then the bible description. Most models respond well to structural instructions placed before subject description.

## Adaptive view counts (edge case)

Most characters (humanoids, animals, humanoid-hybrids like villa-7 fruit-characters, robots) work with the standard 5-view. For highly abstract forms — sentient fog, geometric beings, non-directional entities — fall back to **3–4 views at angles that make sense** (e.g. "from above", "close-up of distinctive feature", "full form at distance"). The rule is still: neutral, on white, same lighting, same scale.

Set `form` in the bible to flag this. If `form` implies non-humanoid abstraction, the canonical prompt should say "multiple representative views" instead of "5 views front / 3/4 / side / 3/4 back / back".
