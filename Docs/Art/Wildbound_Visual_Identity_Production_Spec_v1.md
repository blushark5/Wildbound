# Wildbound Visual Identity v1 — production specification

Status: Art direction exploration, NOT an approved asset replacement.

## Reason for reset

The previous Godot art experiments layered procedural SVG shapes over a pre-rendered world image, causing inconsistent anatomy, indistinct treetops, poorly aligned houses and flat water. This branch starts from the last verified stable `main` code rather than inheriting those experiments.

## Goal

An original, commercially usable creature-collecting RPG with the production clarity and nostalgic visual craft of high-quality 2004 Game Boy Advance RPGs. FireRed/LeafGreen is a reference for **discipline and readability**, not a source of assets to copy.

## Pixel-art rules

- Overworld logical camera framing: target **240×160** gameplay pixels (or equivalent 2× zoom from the current 480×320 viewport), scaled by integer multiples with nearest-neighbor filtering.
- Map ground tile grid: **16×16** pixels.
- Player: **16×24 or 16×32** base sprites, with *matching* front, back, left and right silhouettes, proportions, clothing and palette. No rescaled AI concepts as production frames.
- Walking: at least three authored steps per cardinal direction; left/right can mirror if props and clothing permit.
- Trees: hand-designed 2–3-tile-wide and 3–4-tile-high foliage clusters, stable trunk silhouettes, readable shadow and layered depth. Every tree should read as a tree at native size.
- Buildings: coherent tile sets (roof, cornice, walls, windows, doors, foundation), consistent light direction and doorway centered precisely on an accessible approach tile.
- Water: original 3–4-frame water surface with subtle horizontal flow/ripples; shoreline edge tiles separately drawn to make a recognizable pond or stream rather than a solid rectangle.
- Limit palettes intentionally (roughly 12–16 colors per small sprite where feasible); reuse shared environment lighting colors.
- Only original or explicitly commercially licensed source assets.
- Never place transparent SVG decorations over a static screenshot and call it a tileset.

## Real asset deliverables for first approval gate

1. A polished character turnaround (front, back, side) at native resolution, inspected enlarged using nearest-neighbor.
2. One manually designed overworld tree tile family including canopies/trunks and transparent overlap behavior.
3. One 16×16 water animation family with a single shoreline corner and a small 4-frame looping preview.
4. A 15×10 tile crop of Willowrest containing one house, walkable entrance, trees and shoreline, assembled from source tiles.
5. Godot screenshots at logical and browser resolution showing character movement and overlays.

## Engine integration quality gates

- Use SpriteFrames/AnimatedSprite2D or AnimationPlayer for movement, and AnimatedTexture/AnimatedSprite2D or tile animation for water.
- TileMapLayer or separate art layers enforce depth and sensible collision without baked collision geometry inside background images.
- Do not change the creature battle loop, encounter rates, inventory or save schema while evaluating art.
- Test all four movement directions; the blue/white shirt mismatch must be impossible by construction.
- Screenshots for all four facings + shoreline must pass human visual review before merge.
- Validate export, startup and in-game camera framing using the Godot 4.7.2 CI workflow.
- Stable `main` stays available until visual QA is signed off.

## Scope control

Visual identity first. One player, one house, one tree set, one small water area. Do not add more NPCs, creatures, towns, procedural art embellishments or gamification until these assets are approved.

## Pipeline notes

Concept illustrations are *reference only*: a nice-looking concept image is not evidence of useful 16×16 tiles or correctly aligned animation frames. Production PNG assets need careful pixel editing, consistency and gameplay integration.
