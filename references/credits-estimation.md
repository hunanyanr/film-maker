# Credits Estimation

Rough credit costs for the review checkpoint. Always present an estimate before the user approves production.

## Per-model credit costs (approximate)

| Model | Unit | Credits |
|---|---|---|
| `gemini-3.1-flash-image` (T2I, per image) | per image | 2–5 |
| `kling-3.0-pro` (video, 1080p + native audio) | per second | ~2–3 |
| `kling-avatar` (dialog, image + audio → lip-sync) | per second | ~2–3 |
| `kling-omni` (multi-ref video, silent) | per second | ~2 |
| `kling-v2a` (video → ambient audio) | per second of video | ~1 |
| `eleven-v3` (TTS) | per minute of audio | ~5 |

Prices may shift — always defer to `gen-ai pricing` for authoritative numbers.

## Per-beat cost breakdown

| Beat type | Image composite | TTS | Video | Typical total |
|---|---|---|---|---|
| Establishing (5s, no dialog) | 1 composite (~3) | 0 | 5s × 2 = 10 | **~13 credits** |
| Reaction (6s, no dialog, 2 chars) | 1 composite (~3) | 0 | 6s × 2 = 12 | **~15 credits** |
| Dialog (8s, 1 char) | 1 composite (~3) | ~1 (8s line) | 8s × 2 = 16 | **~20 credits** |

Add **~10 credits** per character for the initial turnaround (once per project, cached).
Add **~5 credits** per location for the plate (once per project, cached).

## Project-level estimates

| Project | Characters | Locations | Beats | Rough credits |
|---|---|---|---|---|
| **15s reel** | 1 | 1 | 2–3 | 40–80 |
| **30s reel** | 1–2 | 2 | 4–5 | 80–150 |
| **60s reel** | 2–3 | 2–3 | 7–10 | 200–350 |
| **3-min short film** | 3–5 | 4–6 | 20 | 500–900 |
| **5-min short film** | 4–6 | 5–8 | 35 | 1000–1500 |
| **30s episode** (in series) | 3–5 (shared) | 2–3 (shared) | 5 | 150–250 |
| **2-min episode** (in series) | 3–5 (shared) | 3–5 (shared) | 12 | 400–700 |
| **5-episode series** (2-min each) | 5–7 shared | 6–10 shared | 60 total | 2000–3500 |

**Caching saves a lot on series.** Canonicals and location plates are generated once and reused across all episodes. The incremental cost per additional episode is only the beats, so a 10-episode series isn't 10x a 1-episode cost.

## Cost-saving moves for the review checkpoint

If the estimate looks high, offer the user these levers:

1. **Shorter beats** — trim 7s beats to 5s. 30% reduction on video cost.
3. **Fewer beats** — cut the rhythm down. Sometimes two beats can be one held shot.
4. **Smaller cast** — fewer canonicals up front. Each character dropped saves ~10 credits + all their composites.
5. **Fewer locations** — revisit one location instead of inventing a new one.
6. **720p instead of 1080p** — Kling Omni etc. have resolution tiers; check `gen-ai pricing` for delta.

Don't reach for these levers unless the user is cost-sensitive. Quality-first is the default.

## How to present the estimate

At the review checkpoint:

```
Estimated credits: ~350 (≈ $X.XX at current rates)
  • 3 character canonicals: ~30
  • 3 location plates: ~15
  • 8 beats (avg 20 credits): ~160
  • TTS for 5 dialog beats: ~20
  • Buffer for retries: ~30
```

Round up generously. It's better to come in under estimate than over.
