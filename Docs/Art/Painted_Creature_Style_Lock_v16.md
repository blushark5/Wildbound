# Wildbound v0.16 — Painted creature art authority

## Non-negotiable visual reference
The original v0.7 `v07_bestiary_atlas.webp.base64` and `v07_evolved_bestiary.webp.base64` are the APPROVED Spriglet, Brinlet and Cindlet illustrations. Never replace those with simplified vector geometry, polygonal mascots or procedural SVGs. The original three should always render straight from the approved atlas.

## This art-only correction
The other nine species (Pebblit, Mossling, Driplet, Tidefin, Ashcub, Emberlyn, Zephlet, Gustling and Skyray) now use original painted, transparent raster artwork at 128x128 portrait resolution for both normal and evolved forms. Unlike the rejected v0.14 flat SVG silhouettes, these have painterly lighting, expressive eyes, distinct anatomy, textured fur/stone/leaves/scales/feathers, and a matching softly illustrated visual quality bar. The nine evolved paintings are separately cut from a designed art review illustration and alpha-matted for gameplay; small edge effects around the silhouettes may be polished further.

Combat animation is driven by the pre-existing attack lunge, reaction and elemental FX system. The renderer selects separate real raster idle and attack textures, but does not use vector redraws as substitutes. All original v0.15 mechanics (Essence first clears, Farm/Push, Bond and Ascension) remain unchanged, as does its browser save namespace.

## Art acceptance criteria
- Starters must be pixel-for-pixel the original approved illustrations, normal AND evolved.
- Every new creature must render a painted PNG/WebP texture (never the old simplified SVG).
- Nine species have distinct normal/evolved high-quality portrait art in battles and Field Guide.
- Validate with `tests/check_painted_v16.gd` plus v0.15 gameplay regressions and full Godot Web export.
