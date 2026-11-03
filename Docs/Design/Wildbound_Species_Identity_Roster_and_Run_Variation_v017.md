# WILDBOUND • Species Identity, Creature Tone & Run Variation
**Design authority v0.17 • November 3, 2026 • Production-ready roster brief (not yet gameplay code)**

## Vision and priorities

Wildbound is an original elemental creature incremental battler, not a collection of uniformly cute pets. Design primarily for the fantasy of commanding dangerous, powerful, distinctive elemental beasts. Charm is a contrast ingredient, not the dominant art style. Individual lines may be noble, terrifying, uncanny, grotesque, sleek, brutal, or occasionally charming.

**Anatomy is sacred.** A fox is visibly a fox at BASE, EVOLVED, and ASCENDED; an air fox may have storm antlers, feathers, electricity, or extra ethereal tails, but must never have a bird's, deer’s, lizard's, or bear's primary skeleton. Apply the same rule to birds and lizards. Ascension means greater power and elemental exaggeration, never a taxonomic replacement.

**First 12:** three creature body families × four combat elements. **Later 24:** add serpent, bear, and insect body families across all four elements (four lines per new family). Each line has a core temperament and a recognizably consistent face, limb arrangement, silhouette and signature markings across three visual tiers.

Four combat elements remain **Earth, Water, Fire, Air**. Do not change the existing elemental advantage loop merely for the art pass.

### Core 12-line roster

| Element | Body family | Legacy stable ID for save migration | Line (Base → Evolved → Ascended visual) | Primary mood | Anatomical anchor / escalation |
|---|---|---|---|---|---|
| Earth | Fox | `spriglet` | **Spriglet → Briarvex → Thornreign** | Wary → formidable → primal sovereign | Fox muzzle, canid paws, upright triangular ears, bushy tail all stages. Antlers/leaf armor only as fantasy additions. **Preserve approved base art as the standard**; revise later forms only if fox identity slips. |
| Earth | Bird | `mossling` | **Mosswing → Cragowl → Dreadcanopy** | Ominous, ancient | Raptor/owl skull, beak, two bird legs, wings and feather fans. Bark-plated wings, moss mantle, hollow-grove eyes. Not a furry quadruped. |
| Earth | Lizard | `pebblit` | **Pebblit → Shaleback → Monolisk** | Stubborn → relentless → colossal | Low reptilian torso, four splayed lizard legs, long balancing tail, scaled jaws. Mineral scales and basalt dorsal plates; must not become a turtle or bear. |
| Water | Fox | `brinlet` | **Brinlet → Riptail → Abyssvex** | Curious → sleek → cold regal | Unmistakable fox head, four canine paws and multi-stream tail; fins or gills only secondary. **Approved base art defines facial style**; do not evolve into a horse, seahorse, or sea dragon. |
| Water | Bird | `tidefin` | **Tidecrest → Reefhunter → Maelstromwing** | Predatory, resolute | Diving seabird silhouette: beak, wings, feathered body, webbed claws; later forms get blade-like water plumes and storm-surge pinions. |
| Water | Lizard | `driplet` | **Rillisk → Fenmaw → Thalassaur** | Uncanny, eerie | Salamander/newt-like elongated head, four reptile limbs and tail; translucent water fins and abyssal glows; never a shapeless blob. |
| Fire | Fox | `cindlet` | **Cindlet → Blazetail → Infernovex** | Scrappy → savage → infernal apex | Sharp fox head, four lean paws, multiple recognizable fiery tails. Magma antlers allowed. **Preserve approved base art**; maintain fox anatomy as flames intensify. |
| Fire | Bird | `emberlyn` | **Emberwing → Pyretalon → Sunrend** | Violent, fierce, mythic | War-hawk/phoenix: hooked beak, raptorial talons, two legs, giant feathered wings. Flames replace feathers gradually but never wing anatomy. |
| Fire | Lizard | `ashcub` | **Scorlisk → Magmaw → Cataclysk** | Brutal, volcanic | Armored gecko/drake, four clawed reptile limbs, broad lizard skull, thick tail; cracked magma plates and horns, not a bear cub. |
| Air | Fox | `gustling` | **Zephvex → Galewraith → Skyreign** | Proud, elusive, mythic | Long-muzzled fox with four paws and sweeping tails. Wind-maned fur, lightning antlers and levitation still preserve canid anatomy. |
| Air | Bird | `zephlet` | **Zephlet → Stormtalon → Tempestroc** | Fierce, majestic | Falcon/eagle body with sharp beak, claws, massive layered feather wings; lightning crests and clouds emphasize flight. |
| Air | Lizard | `skyray` | **Glidescale → Voltrake → Skyrend** | Strange, agile, electric | Draco-gliding lizard: reptilian jaw, four limbs and long tail; extended rib membranes may form wings. Never a manta ray/bird. |

**Naming note:** The legacy IDs above are implementation identifiers only and should be retained for save compatibility. Player-facing display names should follow the proposed line names when their new art has shipped. Existing evolved-form IDs/name references and UI strings must be audited. Do not superficially rename incompatible old artwork and call it a taxonomy fix.

### Character and mood targets

- Base: approximately **two charming**, **four scrappy/intense**, **three fierce**, and **three eerie/stoic/odd**; not twelve wide-eyed smiling infants.
- Evolved: predominantly skilled, dangerous, resilient, or unsettling with only carefully chosen approachable exceptions.
- Ascended: mythic apex predators/guardians, with stronger material variation, more imposing scale, cinematic poses, and elemental FX. **All remain anatomically the same species**.
- Visual identity check at thumbnail size: obscure color and effects. A player should still identify Fox vs Bird vs Lizard instantly by silhouette.
- Another identity check: hide the creature name; a player should still guess Earth vs Water vs Fire vs Air from color, texture and elemental anatomy.
- A third check: place all three stages beside each other. The middle should bridge the first and final; the final should resemble the base at a glance, rather than becoming a new animal.

### Production art rules

1. Painterly, highly rendered, crisply matted transparent creature assets compatible with approved v0.7 starter quality. No flat polygonal SVG substitution or blurry contact-sheet crops.
2. Independently rendered BASE, EVOLVED, ASCENDED forms; evolved and ascended are not stretched copies and should use distinct poses without losing signature anatomical features.
3. Attack frames may be genuine painted alternate poses or existing Godot animation of a single painted frame; never swap to a derpy low-quality version when attacking.
4. For each line, write one **immutable anatomy anchor** (muzzle/beak, limb count, body plan, tail/wings) and a small **signature motif** (e.g. Spriglet's ivy brow or Brinlet's waterstream ear).
5. Art director review gates: compare the 12 forms at base, then 12 evolved, then 12 ascended; check individual full-resolution render for transparency, overlap, edges and legibility.
6. Fix known problematic old art in the next complete family pass: `ashcub` is currently bear-like, `emberlyn` fox-like, and several water/air art IDs are anatomically incompatible with the new body-family plan. These are placeholders until corresponding new art is approved.
7. Do not silently retcon the **approved Spriglet, Brinlet, and Cindlet base portraits** to new shapes; they are our initial fox-family benchmarks. If an evolved portrait no longer reads as a fox, replace only that stage with a quality-matched fox redesign.

## Run variation specification

### New save: randomized opening squad
- For a **new game only**, grant **three distinct creatures**, one Fox, one Bird, one Lizard, drawn from their respective four-element pools. Randomize elements with a strong preference for **three different elements**, leaving one element uncovered; no duplicates of exact species, no three-of-a-kind element starts.
- Do not force Spriglet. Make the opening trio visible immediately; explain ELEMENT ADVANTAGES and FARM versus PUSH.
- Do **not** reroll or delete a player's existing collection or opened eggs when upgrading from v0.16.
- The original individual trait rolls are still randomized, saved and persistent. Preserve unique hatch collection and all owned creatures across Ascensions. A starting trio is a *per-new-save starter hand*, not a set of creatures re-granted each Ascension.

### Ascension: fresh tactical run, enduring collection
- At Ascension, preserve the collection, mutations/traits, species, evolved forms, Bond XP, Bond ranks, world progress and unlocks as currently designed.
- Generate a **new encounter seed** for the Ascension cycle. The previously earned Essence remains earned; previously cleared stage numbers cannot mint it again.
- Optionally present a **randomized recommended starting squad** from owned creatures as a convenience only, without forcibly unequipping a player's intentional squad. Three unique species, bonus to diverse elements. Any chosen squad is valid.
- Reset only the run-level resources already governed by Ascension. No destructive creature re-roll.

### Random enemies/stages, deterministic once generated
- Use one saved random `run_seed` per Ascension cycle; derive each stage's three-enemy lineup from `hash(run_seed,stage,slot)` or an equivalent locally seeded RandomNumberGenerator. Do not roll a new enemy every time the screen refreshes, reloads, or the player farms.
- Weighted lineups: stages 1–3 use lower-power, readable enemies with 1–2 elements; stages 4–9 mix 2–3 elements; stage 10 and every tenth remain Guardian, with a stronger themed boss and 1–2 supporting creatures; later tiers unlock genuinely dangerous formations.
- The **same stage in the same Ascension cycle must be identical** when replayed or farmed. New Ascension cycles may change lineup/element composition and biome flavor.
- Stage strength and rewards still scale with **stage number**, not random enemy type. Rerolling is never an economic exploit.
- Keep meaningful unfavorable matchups possible; Gold upgrades, Bond XP and manual assists give a recovery path. Early difficulty should occasionally push players into FARM, not strand them.
- Never give Essence for replays, farmed battles or reclearing a previously completed stage after Ascension. **First-ever lifetime stage clear only**, following v0.15 rules: +1 per new stage, +4 for each tenth Guardian.
- Upgrade earlier fixed onboarding goals that currently assume Spriglet ownership, a Fire-first egg or particular enemy lineup. Tutorial targets should describe **your starter**, a **fourth distinct hatch**, elemental coverage, and first Guardian; no impossible scripted prerequisite.

### Economy/UX compatibility checkpoints
- Current v0.16 awards one starter and calculates `hatch_cost()` from total collection size; changing to three starters **would accidentally make the first earned hatch substantially more expensive**. Price from actual `new_hatches` or a clearly defined "earned eggs" tier, retaining a 5-Essence first hatch.
- The current UI grow cards, event prompts and v0.12 starting quest order assume fixed creatures. Make them render the actual three opening team members before activating the new starter-trio randomizer.
- Existing saves get an explicit migration path with their current roster preserved; new-save randomness must not be applied in `load_save()` blindly.
- Use golden-seed regression tests for identical rosters after reload, correct Gold/Bond/Essence on farming, boss schedule, old-save migration, fresh new-game element balance and no duplicate individuals.

## Implementation order and gates
1. **Art bible**: lock 12 line anatomy, temperament and signed-off base-to-ascended silhouette sheet. Hold finished assets to approved starter-paint quality.
2. **Game data**: separate stable species IDs from display names, add `family`, `element`, `tone`, and `form_art` keys in a non-breaking way.
3. **Opening squad**: three distinct seeded starters on a new save only, dynamic UI, balanced first-hatch pricing; no resets to existing saves.
4. **Encounter seed**: saved cycle seed, deterministic weighted stage lineup and fixed Guardian intervals.
5. **Visual integration**: implement three hand-painted sprites/poses per family (36 base/evolved/ascended portraits), inspect in real Godot battle/Field Guide screenshots and check the art gates.
6. **Tests/build**: full Godot GDScript import, all v0.15+ regressions, starter/seed tests, web export and GitHub Pages deploy, all without changing existing `/bond/` save identity.

**Status at authoring:** This document records the agreed direction and design; it **does not claim** that the 12 corrected families, three-form artwork, three-starter new game or encounter randomizer are already integrated into the live v0.16 game.
