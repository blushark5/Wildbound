# Wildbound v0.13 — World and Interface Visual Overhaul

## Art direction
A refined hand-illustrated fantasy creature RPG, preserving Wildbound's approachable 3v3 live combat and long-term incremental progression. This is a **visual-only** pass: do not flatten the existing difficult stage walls or combine Gold and Essence.

## New assets
- Four original SVG duel arenas, Earth, Water, Fire and Air. Each has layered atmospheric mountains, soft particles, opposing summoning circles, and subtle ornamental structures. The battlefield selects the arena to match the rival trainer's leading element, so the world looks different as opponent types change.
- Illustrated Hatch Egg, Gold coin, Essence crystal and Echo icon. The currency chips separate the distinct economies visually.

## Redesigned game shell
- Improved dark teal / muted gold design system: raised cards, fine light edging, hover feedback, clearer heading hierarchy, and consistent panel spacing.
- Battle area: colored creature podiums, elemental highlight around the six independent combatants, clarified target/DPS readouts, central duel sigil and subtle idle motion.
- Squad cards: element-colored wells, type chips, individual Bond progress bars, prominent Gold level-up controls, and distinct ability/slot-selection buttons.
- Header: illustrated currency emblems; Gold remains for upgrades, Essence for earned new discoveries, Echoes for permanent research. Current Essence shows progress toward next hatch.
- Quest and upgrade panels have stronger visual hierarchy and consistent typography.

## Full Field Guide
A **separate full-screen overlay** replaces the hard-to-navigate twelve-row narrow inventory. Four colored columns organize 3 distinct Earth, Water, Fire and Air species each. Every species has a large illustrated portrait. Locked species appear as dark silhouettes with mystery labels. Discovered species display actual individual trait, level, current squad assignment and ASSIGN action. A clear slot picker supports all 3 unique active positions. Hatch Egg, Essence progress and next cost remain visible at the top. Opening the Guide pauses the ongoing live battle, and closing resumes its previous state.

The right-side COLLECT tab and a prominent FIELD GUIDE shortcut open this collection view. A small preview of hatch/discovery information remains available in the sidebar. Hatching only consumes existing Essence and creates the existing original individual; no extra currencies or direct Gold-recruit controls.

## Preservation and QA
- Preserve v0.12 original engine, per-individual levels, unique ownership, hatching, evolution, Essence slope, Gold upgrades, elemental counter AI, manual Next/Farm, progression, autosave and Ascension.
- Test full Field Guide render, UI control bindings, pause/resume, live hatch/assign, 12 actual art textures, duel arena selection per type, and the real split-currency state.
- Capture four actual 1280×720 Godot screenshots: fresh arena, full Field Guide, live 3v3 mixed team, discovered individuals.
- Publish as an independent /world/ preview with its own save; preserve /collection/, /squads/ and other historic versions.
