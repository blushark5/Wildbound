# Wildbound Creature Ascension — Visual Integration v0.5

## Purpose
Visual production follows the approved Verdant Meadow and Azure Shore UI mockups and original six-creature bestiary concept. The images are reference artwork, not functional Godot interfaces or importable transparent monster sprites.

## Implemented in the first engineering pass
- Reusable original-art UI presentation layer in scripts/incremental/visual_skin_v05.gd.
- Decorative header and creature-card scenery reuse original Wildbound image assets that are already in the repository.
- Creature-specific visual accents, richer borders and more prominent battle action controls.
- The live battle now features the player's actual independent back-facing creature artwork opposite the enemy; this changes with strongest owned creature and evolution.
- An original region scene can change independently of all combat labels and controls.
- Actual Godot Buttons/labels remain fully interactive, and save data/gameplay are not modified.
- tests/check_visual_v05.gd asserts required assets, UI nodes, region scene art, evolution/back sprites and the real Strike control.
- CI continues through real rendering/screenshot and HTML5 export.

## Art-quality gate: NOT yet approved
This is an engineering foundation, not a complete recreation of the approved polished mockup. Current battle backgrounds and small existing sprites remain from the earlier prototype. The approved full-screen mockup has artwork, buttons, monsters and text baked together. Using that entire image as a game background would repeat the old architecture mistake. The bestiary is a composite illustrated reference, not a transparent sprite atlas.

## Required production assets
- Six original individually illustrated transparent creature sprite portraits (Spriglet, Thornhart, Brinlet, Tidemare, Cindlet, Blazetail), consistent proportions and pixel density.
- Separate front/back combat poses and intentional animation frames for each creature.
- Standalone scenery-only pixel-art backgrounds for Verdant Meadow, Moonlit Shore, Ember Hollow and Skyglass Peaks: **NO baked UI, words, health bars or combatants**.
- Illustrated nine-slice panel frames and corner details, resource and element icons, styled ability/action icons.
- Godot web-quality imports: texture filtering nearest, RGBA transparency, pivot and ground alignment, reasonable compressed export size.

## Release gates
1. Production asset import and sprites replacement with fallbacks.
2. Screenshot inspect: no blurred imagery, clipping, occluded controls or illegible text.
3. Original v0.1-v0.4 progression tests and visual v0.5 tests.
4. HTML5 Web export and manual browser playtest with saved progress, four regions and seven tabs.
5. Only then promote to /reboot/. Stable / and /dev/ remain untouched.
