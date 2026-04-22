# Location Design — Empty Plates That Come Alive

Locations are environments. Just the environment. No characters. Characters get composited in later at the beat layer.

Think of a location plate like a movie set photographed before the actors arrive for the day. The lighting is set, the dressing is done, the mood is cast — but the stage is empty and waiting.

## What a location plate MUST be

1. **No characters.** Not even at a distance. Not even in silhouette.
2. **Full environment visible.** The space, its scale, its key features.
3. **Specific time of day.** Morning, golden hour, blue hour, night, etc. Locks the light.
4. **Specific mood.** Inviting, ominous, sterile, intimate, decayed. The mood shapes the lighting and dressing.
5. **Generated at the project's aspect ratio.** If the project is 9:16, location plates are 9:16. Matching frames means composites don't crop weirdly.

## `locations/locations.json` structure

**Important:** `locations` is a **dict keyed by location id** — NOT an array. Production scripts look up locations by id (`.locations.neon-alley`), so the array form breaks them.

```json
{
  "locations": {
    "neon-alley": {
      "id": "neon-alley",
      "name": "Neon-lit Alley Behind the Club",
      "description": "Narrow brick alley behind a basement jazz bar. Wet pavement, steaming vent, bent dumpsters, dead neon sign overhead. Night.",
      "prompt": "<full T2I prompt — see below>",
      "mood": "isolated, predatory, nocturnal",
      "timeOfDay": "2am, after rain",
      "scenes": ["b05", "b07"],
      "canonicalImage": null
    },
    "rooftop": {
      "id": "rooftop",
      "name": "...",
      ...
    }
  }
}
```

**Not this** (common mistake — array form):
```json
{ "locations": [ { "locationId": "neon-alley", ... } ] }   // ← breaks lookups
```

## The location prompt template

```
A cinematic wide shot of {{name}}: {{description}}. {{specific visual details —
walls, floor, props, set dressing, what's in foreground vs midground vs background}}.
{{lighting — sources, color temp, shadows}}. {{atmospheric — fog, dust, rain, snow}}.
No people, no characters, empty environment. {{aesthetic}}. {{aspectRatio}}
portrait/landscape, photorealistic/Pixar-style/etc, ultra detailed.
```

### Example

Villa-7 kitchen:
> *"A cinematic wide shot of a bright modern luxury Mediterranean villa kitchen. White marble countertops with gold veining, warm wood open shelving with ceramic bowls, copper pots hanging from a rack, a large window overlooking a garden. Warm overhead pendant lights casting soft gold pools, bright morning light streaming through the window. A fresh fruit bowl on the counter, a half-made sandwich on a cutting board — the set has been lived in moments ago. No people, no characters, empty kitchen. 3D Pixar-style render, brainrot fruitdrama aesthetic. 9:16 portrait, ultra detailed."*

Notice:
- It describes the **set** thoroughly (countertops, shelving, pots, window)
- It sets the **light** explicitly (pendant lights + morning window light)
- It includes **set dressing** that implies story without needing people (half-made sandwich = someone was just here)
- **No characters mentioned**
- Aspect ratio locked

## Time of day — lock it

Every location has a specific time of day. This isn't optional — it determines all the lighting downstream. If a scenario visits the same location at two different times (morning + night), that's **two separate location plates**: `kitchen-morning.png` and `kitchen-night.png`, both in `locations.json` as separate entries.

## Mood via set dressing, not people

How do you convey that something happened here without a character in frame? **Set dressing.** A half-drunk glass of wine. An overturned chair. A dress on the floor. A window left open with curtain blowing. A crumpled photograph. The dressing suggests what just was, or what will be.

Use it liberally — but only when it serves the story. Don't dress a location with ominous objects just for vibes if the plot doesn't pay it off.

## Count-sensitive elements in the prompt

If the location includes **specific quantities** of objects (the sixth chair at a table set for five, three wine glasses, two doors at opposite ends of the hallway), follow the counting rules in `references/prompt-craft.md` — state the number in words AND digits, describe spatial layout, and forbid extras. *"Six chairs around the table"* often produces 5 or 7. *"A table set for SIX (6) — three chairs down each long side"* produces 6 reliably.

## Generation call

```bash
gen-ai generate -m gemini-3.1-flash-image \
  -p "<location-prompt>" \
  --aspect-ratio "<project.aspectRatio>" \
  --script | jq -r .url
```

Save the result URL into `locations.json[<id>].canonicalImage` and download to `locations/<id>.png`.

## How many locations?

- **Reel** (15-60s): 1–2 locations
- **Short film** (1-5 min): 3–6 locations
- **Episode**: 4–8 locations
- **Series**: 8–15 shared locations across episodes, with 1–2 new per episode

Don't over-invent locations. Better to return to a location and have it feel richer than fragment the viewer's sense of place by teleporting to a new setting every beat.

## Shared locations across episodes

In a series, most locations recur. Write `locations.json` at the **project level**, not per-episode — one canonical plate per location, reused across every episode that visits it. Episode-specific locations (a one-off setting) still go in the project-level `locations.json` but their `scenes` array will only reference beats from that one episode.
