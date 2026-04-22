# Pacing — Beat-to-Beat Rhythm

Pacing is the invisible force that makes a scenario feel cinematic vs. feel like a slideshow. Same beats, same prompts, different order — completely different experience for the viewer.

## The fundamental principle: contrast

**Never have two beats in a row doing the same thing.** After a wide, go close. After close, go wide. After held, go kinetic. After silent, go verbal. After tense, give a breath (then rip it away again).

This is called "cutting for contrast" and it's the single biggest pacing lever you have.

## The rhythm patterns

### Opening — hook + setup
First 2–3 beats. Shortest sequence. Hook the viewer (question, image, inciting moment), then establish where we are.

```
b01 — HOOK        3-5s   close, provocative, does not explain itself
b02 — ESTABLISH   4-6s   wide, locates the viewer in the world
b03 — INTRO       4-6s   medium, introduces the protagonist
```

### Middle — build + escalate
Most of the runtime. Alternating pacing. Each beat should be doing work: either raising tension, advancing plot, revealing character, or releasing pressure (briefly, to raise it again).

```
b04 — DIALOG      6-10s  character states a desire or concern
b05 — REACTION    3-5s   another character hears, visual response (no words)
b06 — ESCALATE    5-8s   something changes — a doorway opens, a message arrives, a glance is caught
b07 — DIALOG      6-10s  character responds to the escalation
b08 — PRESSURE    4-6s   close-up, intensity rising
```

### Climax — compress
Shorter beats, tighter framing, faster cuts. The rhythm itself escalates.

```
b09 — ECU         2-3s   extreme close-up, decision moment
b10 — HARD CUT    3-4s   the action, the consequence
b11 — HARD CUT    2-3s   the reaction
```

### Close — breath + final image
The last beat is almost always wider than the one before it. Release. Let the viewer exhale. End on an image that lingers.

```
b12 — WIDE        5-8s   pull-back, reveal scale, final image
```

## Duration rules of thumb

| Purpose | Typical duration |
|---|---|
| ECU emotional moment | 2–4s |
| CU character beat | 3–5s |
| Medium dialog line | 6–10s |
| Wide establishing | 4–8s |
| Hold-for-reveal | 2–3s |
| Silence beat (no dialog, letting a moment land) | 3–6s |

Most content models cap around 15s per beat. If a moment genuinely needs more (a long monologue), split into 2–3 beats at the same camera position with slight framing shifts.

## Dialog density

Don't pack back-to-back dialog beats. A five-beat sequence that's all dialog reads as a radio play. Break up dialog with:

- **Reaction beats** — cut to the listener after each line
- **Environment beats** — the setting reacts (wind, a clock, a distant siren) between lines
- **Close-ups on objects** — the thing being discussed gets its own beat

In villa-7 E01, the ratio was roughly **1 dialog : 2 non-dialog beats**. That's a healthy baseline.

## The "one thing per beat" rule

Each beat does one thing. Don't try to land a reveal, a character introduction, AND an emotional turn in a single beat. You'll muddy all three. Split into two beats — one to do the reveal (image/motion), one for the emotional response to the reveal (character reaction).

If your beat description has more than one "and then" in it, split it.

## Length calibration

Given duration options for kling-3.0-pro (3-15s) and kling-omni (3/5/8/10/12/15s), plan like this:

| Total content | Beat count | Avg duration |
|---|---|---|
| 15s reel | 2–3 | 5–7s |
| 30s reel | 3–5 | 6–8s |
| 60s reel | 6–8 | 7–8s |
| 3 min film | 18–25 | 7–10s |
| 5 min film | 30–40 | 7–10s |
| 30s episode in a series | 3–5 | 6–8s |
| 2 min episode | 10–14 | 8–10s |

Longer content needs more beats, not longer beats. Beat length over ~12s breaks viewer attention unless justified.

## Transitions

Default: **crossfade, 0.5s**. Clean, cinematic, doesn't call attention to itself.

When to break it:
- **Hard cut, no fade**: dramatic moments, shocks, scene changes with emotional whiplash
- **Dip to black, 1s**: scene breaks, time jumps
- **Match cut**: when composition/motion allows it (ball tossed in beat 3, landing in beat 4 — no fade, just continuous action) — this is rare but gold

Set the transition at the scenario level in `scenario.transition`, and override per-beat-pair via a `transitionOverride` field if you want something specific between a particular beat and the next.

## Testing your own pacing

Before handing off to production, read the beat list aloud in order with the durations. If it feels flat or lumpy, it is. Good pacing you can feel — it breathes.
