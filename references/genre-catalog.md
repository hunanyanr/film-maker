# Genre Catalog

The skill supports **14 core genres**, orthogonal **tone modifiers**, and **free blending** (primary + optional secondary).

## The 14 core genres

| Genre | What it does | Default tone |
|---|---|---|
| **drama** | Character-driven, grounded, emotional truth. Internal conflict. | grounded, earnest |
| **thriller** | Rising tension, stakes, twist. Pressure-test protagonists. | propulsive |
| **romance** | Relationship arc, vulnerability, shifting power. | earnest |
| **comedy** | Timing, rule-of-3, subverted expectation, escalating absurdity. | light |
| **horror** | Dread, reveal, psychological threat. Withhold what scares. | dark, slow-burn |
| **action** | Physicality, escalation, kinetic shots, clear stakes. | propulsive |
| **sci-fi** | Speculative premise, world logic, ideas-driven. | grounded |
| **fantasy** | Mythic, enchanted, heroic quest, rules of magic. | heightened |
| **mystery** | Clue-laying, revelation, detective logic. Fair play with audience. | slow-burn |
| **noir** | Moral ambiguity, shadows, fatalism. Cynical voice. | dark, slow-burn |
| **fable** | Short moral allegory, clean archetypes, childlike clarity. | earnest |
| **slice-of-life** | Observational, mundane-made-magical, small moments. | grounded |
| **soap-opera** | Ensemble cast, interpersonal conflicts, cliffhangers, dramatic reveals, heightened emotion. Covers classic soap, telenovela, modern prestige soap. | heightened |
| **satire** | Cultural critique through exaggeration. | ironic |

## Tone modifiers — orthogonal, stack freely

| Modifier | What it does to the output |
|---|---|
| `heightened` ↔ `grounded` | Melodrama / big gestures  ↔  naturalism, small gestures |
| `dark` ↔ `light` | Ambiguity, bleakness  ↔  hope, warmth |
| `earnest` ↔ `ironic` | Plays it straight  ↔  winks, distance, meta |
| `slow-burn` ↔ `propulsive` | Held shots, ambient dread  ↔  hard cuts, momentum |
| `brainrot` | Meme-aware, gen-Z cadence, internet-native voice, CAPS for emphasis, lowercase where appropriate. Villa-7 lineage. Applies on top of any genre. |

## Blending

**Any two genres can combine.** The user picks primary + optional secondary. Both playbooks get loaded and merged:

- **Act structure + pacing** → from primary
- **Camera language + shot rhythm** → from primary
- **World rules + setting logic** → from secondary
- **Dialog tone + subtext** → blend
- **Palette + lighting** → blend, leaning primary
- **Character archetypes** → blend

**Equal-weight blends** (`rom-com`, `horror-comedy`, `dramedy`, `sci-fi-thriller`): rotate which playbook leads per scene. Rom-com: romance leads emotional beats, comedy leads setpieces.

**Weird blends are allowed.** `noir fable`, `satirical horror`, `soap-opera thriller`. Just merge honestly — don't reject unusual combinations.

## How to pick when the user is ambiguous

If the user didn't name a genre:
1. Read their premise for markers — keywords, setting, emotional register
2. Propose **1–2 candidates** from the 14 — one obvious, one interesting
3. Show both as one-line hooks so they feel the difference
4. Let them pick or redirect

Example:
> User: *"robot and a bird in space"*
> Propose:
> - **sci-fi fable** (whimsical, hopeful — the robot learns something from the bird)
> - **sci-fi drama** (melancholic, existential — the bird is the last of its kind, robot is an archivist)

## Genre playbooks

Once genre is locked, read the matching file(s) in `genre-playbooks/`:
- `noir.md`, `sci-fi.md`, `soap-opera.md`, `drama.md`, `thriller.md`, `comedy.md`, `horror.md`, `romance.md`, `fantasy.md`, `mystery.md`, `fable.md`, `slice-of-life.md`, `action.md`, `satire.md`

Each playbook covers: act structure, pacing, camera language, lighting palette, dialog tone, cast conventions, emotion curve, common pitfalls.
