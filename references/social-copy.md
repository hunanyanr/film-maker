# Social Copy — Captions Per Platform, Per Character

Every reel/episode/film should ship with ready-to-post social copy. Each posting character gets their own captions across three platforms, written in that character's voice.

## File structure

Per project, emit:

- `social-copy.txt` — the episode-wide recap copy (generic, narrator voice, for the main post)
- `social-copy-<char>.txt` — one file per posting character, in their voice

Both are plain text files, ready to copy-paste. **Never output social copy as JSON** — the `socialCopyTemplates` in `scenario.json` stores the raw data; the `.txt` files are the formatted copy-pasteable version.

## The format

Every `.txt` file follows this structure:

```
INSTAGRAM
────────────────────────────────────────
[Instagram caption in character voice]

#hashtag #hashtag #hashtag


TIKTOK
────────────────────────────────────────
[TikTok caption — shorter, punchier, trend-aware]

#hashtag #hashtag #hashtag


YOUTUBE
────────────────────────────────────────
[YouTube description — longer, more context]

#hashtag #hashtag #hashtag


ALT TEXT
────────────────────────────────────────
[Accessibility description]
```

## Platform guidelines

| Platform | Voice + length |
|---|---|
| **Instagram** | Polished, aesthetic. Hook + story + CTA. Paragraph form okay. Character voice loud. |
| **TikTok** | Shorter, punchier, trend-aware, more casual. One-liner to short paragraph. Works with trending audio cues. |
| **YouTube** | Longer, descriptive. Works as a proper video description — context, characters, teaser. Paragraph form. |

All three must maintain the character's voice. A Mochi caption should sound like Mochi on IG, on TikTok, and on YouTube — just with platform-appropriate register.

## Hashtag rules

**Every section MUST end with hashtags.** No exceptions. If the scenario didn't include hashtags, derive from tags + character tags + genre.

**Required universal hashtags** (append to every hashtag block):
- `#picsart`
- `#picsartaiinfluencer`
- `#picartinfluencer`

Plus any project- or character-specific trend tags.

Pattern:
```
#villa7 #fruitdrama #brainrot #aidrama #episode1 #picsart #picsartaiinfluencer #picartinfluencer
```

## Writing tips per character

- **Pull catchphrases from the bible.** If the character has catchphrases, include at least one in at least one platform.
- **Match speech patterns from the bible.** Lowercase character stays lowercase in copy. Deadpan character's captions are short and final. Chaotic character uses CAPS and ??.
- **Hook in first sentence.** Social feeds scroll fast. The first line either stops the thumb or doesn't.
- **Don't announce the plot.** Tease it. Captions work like trailers, not summaries.
- **End on something reactive.** A question, a cliffhanger, a one-liner that invites reply.

## Example — villa-7 Zara, Episode 1

```
INSTAGRAM
────────────────────────────────────────
served her juice this morning. she smiled at me like i'm the wallpaper. looked at
her belly like the whole world lives in there. he used to look at me like that.
before this villa. before her. she walked into everything that was supposed to be
mine. and she has no idea i'm even standing there. she will.

#villa7 #fruitdrama #brainrot #aidrama #hewasminefirst #villain #episode1
#picsart #picsartaiinfluencer #picartinfluencer


TIKTOK
────────────────────────────────────────
served her juice. she smiled. she doesn't know he was mine first. she will.

#villa7 #fruitdrama #brainrot #episode1 #picsart #picsartaiinfluencer #picartinfluencer


YOUTUBE
────────────────────────────────────────
Zara watches from the doorway as Nova and Dante live the life that was supposed
to be hers. She serves. She smiles. She waits. He was hers first. And she hasn't
forgotten.

#villa7 #fruitdrama #brainrot #aidrama #villain #episode1 #picsart
#picsartaiinfluencer #picartinfluencer


ALT TEXT
────────────────────────────────────────
A dragon fruit character in a black leather jacket stands in the shadow of a villa
doorway, watching a pregnant strawberry character and a pineapple character embrace
on a sunlit terrace.
```

Notice: her voice is consistent across all three — declarative, short sentences, no softening. Pulls "she will." as the close on IG and TikTok. YouTube gets more context because its reader is deciding whether to click the video.

## Social copy goes last in the plan, first in the mind

When writing `scenario.json`, fill `socialCopyTemplates` **after** the beats are done. But conceptually, the social copy shapes how the story will be received — a strong caption can rescue a middling reel, a weak caption buries a great one.

## Scripted rendering

The production pipeline reads `socialCopyTemplates` from scenario.json and renders each posting character's block through this template into `social-copy-<char>.txt`. Also emits a synthesized `social-copy.txt` with a narrator/recap caption (short one-liner + hashtags) for the main post.
