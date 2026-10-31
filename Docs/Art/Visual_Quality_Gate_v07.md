# Wildbound v0.7 — Battle-first interface + six original creatures

## Why we replaced the previous visual approach
The v0.6 screenshots showed nearly the same three-column UI, tiny upscaled placeholder creatures, overlapping combat labels and little scenery compared to the approved artwork. A successful CI build was not evidence of successful art direction.

## What is actually implemented
- True structural reflow: battle stage expands from ~480 x 281 px to 712 x 340 px, with pack cards reflowed left and progress cards reflowed into a narrow scrolling inventory at right.
- Individual original transparent sprites extracted from the approved Wildbound bestiary: three starters and all three evolved forms, rather than enlarging the legacy 24 x 32 creatures.
- Native standalone RGBA WebP sprite atlases decoded at runtime; the actual combatants remain independent drawable nodes and can animate or change with evolution.
- The live roster/battle uses the correct original art per species and evolution state, including evolved Guardian encounters.
- A dedicated source-separated meadow image remains behind the characters; no gameplay buttons, health bars, text, or monsters are baked into scene backgrounds.
- Genuine Godot buttons, seven existing tabs, research, abilities, prestige, relics, goals and autosaves remain on the original engine.
- Alpha v0.1 to v0.6 regression suites, the new v0.7 functional/visual test, two real Godot-rendered screenshots (starter and evolved encounters), HTML5 export.

## What isn't finished
- The backdrop images in other regions still use earlier artwork; original standalone four-region art is needed.
- These sprite assets are first-pass masks from the concept illustration, not a production-ready multi-frame animated sprite atlas. Hand cleanup of alpha edges and idle/attack/hit/death animations remain.
- Font hierarchy, mobile touch layout, upgrade cards and battle indicators still need actual human QA.
- The design must be assessed against *actual* v0.7 screenshots before promotion. Automated tests do not assess attractiveness.

## Release rule
Remain on isolated feature/wildbound-true-visual-rebuild-v07 until visuals and all tests pass. Keep /reboot/ and /visual/ untouched until art review. Do not claim this as a completed visual overhaul based on the concept picture.
