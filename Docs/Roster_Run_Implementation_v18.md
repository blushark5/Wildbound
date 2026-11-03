# Wildbound v0.18 — Live Implementation: Elemental Families and Seeded Runs

This version replaces v0.16's nine inconsistent creature illustrations and fox-only starter art in the active browser page with the approved twelve-line Fire/Water/Earth/Air × Fox/Bird/Lizard roster. All 36 concept-derived transparent raster forms are included in three dedicated 512×384 WebP atlases (base, evolved, ascended), with 128×128 portrait frames, a separate brightened strike texture, and the existing live attack-lunge/effect animation. The approved concept art is the input; this is a prototype art extraction, with painted individual asset redraws still desirable for maximum quality.

## Production roster
- Fire: Cindlet → Blazetail → Infernovex (fox); Emberwing → Pyretalon → Sunrend (bird); Scorlisk → Magmaw → Cataclysk (lizard).
- Water: Brinlet → Riptail → Tidefang (fox); Tidecrest → Reefhunter → Tideroc (bird); Rillisk → Fenmaw → Thalassaur (lizard).
- Earth: Spriglet → Briarvex → Thornreign (fox); Mosswing → Cragowl → Dreadcanopy (bird); Pebblit → Shaleback → Monolisk (lizard).
- Air: Zephvex → Galewraith → Skyreign (fox); Zephlet → Stormtalon → Tempestroc (bird); Glidescale → Voltrake → Skyrend (lizard).

Existing twelve internal IDs remain stable, including old art names such as `ashcub`, `mossling`, `gustling`, and `skyray`, so browser save collections migrate safely. UI display names use their new lines; physical anatomy and temperament remain distinct. Rank 4 plus personal evolution triggers the mythic Ascended art to allow both evolved and ascended stages to appear in a long playthrough.

## Randomization and preservation
- A newly created save gets **three distinct creatures**, one Fox, Bird, Lizard, with unique elements. Existing saved collections are preserved with no starter reroll and no gifted duplicates.
- First **earned egg** still costs five Essence despite three free starters. Each paid egg is a new species and prioritizes a missing fourth element.
- A persistent run seed deterministically generates each stage's three opponents. First three stages have limited elemental variety, later stages can mix all elements; every 10th stage is a Guardian with one fox, bird and lizard enemy. Farming/retries/reloads do not reroll opponents.
- Ascension regenerates the encounter seed, retaining creatures, form progression, Bond Ranks, traits, Genes and Essence. Only first-ever lifetime stage clears award Essence.
- Dynamic starter, hatch, element-coverage, and quest tutorial descriptions replace old Spriglet/Fire-only onboarding assumptions.
- The preview keeps the same `/bond/` browser route, user save directory and persistent JSON filename. Older v0.14/15/16 regression scenes and textures are retained independently.

## QA and known art limitations
The cropped concept-sheet art is suited to a first in-engine full-roster review and may have clipping/edge artifacts on individual 128px frames because the approved concepts were composed as a group, not full isolated source paintings. Those should be replaced by separately authored high-resolution transparent creature sprites in a later dedicated art quality pass. Do not claim these are full hand-rendered production assets. Validate stage randomization, economy, exact 36 portraits and migration via `tests/check_roster_v18.gd`, and inspect true Godot screenshots from `tests/capture_roster_v18.gd`.
