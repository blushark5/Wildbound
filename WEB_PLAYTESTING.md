# Wildbound browser playtesting

- Stable: https://blushark5.github.io/Wildbound/
- Development preview: https://blushark5.github.io/Wildbound/dev/
- Stable game source: `main`. Development source: `develop`.
- The GitHub Actions deployment builds both, while the `develop` branch also performs its own Godot import/export/startup validation.
- Only merge tested gameplay changes into `main`.
- In the current PC build, use arrow keys or WASD to move, E or Enter to interact, Esc for the menu, and Tab for the creature party.
- Browser save files are local to that browser/device; the preview build uses a different save filename so it does not overwrite stable progress.
- Browser audio may require an initial click or keypress. Music and sound can be switched on or off from the pause menu.

## Current art review
- `develop` now includes the first GBA-inspired environment art pass (`assets/world_polish.svg`).
- Test the art only at `/dev/`; gameplay on `/` remains stable.
- Evaluate readability, tree/door alignment, buildings, route landmarks and the sense of depth before promoting it.

## Art alignment review — October 28, 2026

The `develop` preview includes an art-correction pass in response to playtesting:
- Red house doorway has been positioned over the walkable approach near tile (12, 9).
- Decorations near the west side of the red house no longer intersect the facade.
- New original player graphics have consistent blue clothing across all directions.
- Border forest includes larger tree canopies and trunks instead of only hedge-like tiles.
- Pond art includes a shaped shoreline, water depth and sparse ripples.
- No changes to collision coordinates, party data, or saves.

Review on `/dev/` before promoting to `main`.

## Concept-art sprite experiment — October 28, 2026

The `develop` browser preview tests four directional character sprites extracted from the original Wildbound concept sheet and downsampled to 24 × 32 with transparent backgrounds. They are prototype sprites, not finished hand-cleaned walking animations.

The same preview corrects the blue-roof house doorway to the tile-20 approach and adds a connecting footpath. No collision/save schema change. Please compare the new sprite at true game scale and report clipping, color/alpha issues, and visual quality before approval.

Other concept-board illustration pieces (houses, foliage, water animation frames) are not tile-ready and have not been placed over gameplay.

## Walk animation prototype — October 28, 2026

- Development version now cycles **idle / stride A / stride B** using the approved concept-art protagonist in each of four facings.
- The gait is implemented as pixel-level lower-body adjustments to the existing 24×32 sprite, not a new player design.
- Footstep frames display only during **valid** tile movement, return to idle on arrival, and alternate on consecutive steps.
- Existing camera synchronization, collisions, encounters, and browser save formats remain unchanged.
- This is the first movement polish candidate; inspect at in-game scale and watch for leg clipping or a flickering walk cycle.
- Continue testing at https://blushark5.github.io/Wildbound/dev/ and compare to stable https://blushark5.github.io/Wildbound/ .

## Footstep correction — revised development preview

The October 28 gait hotfix replaces the earlier ankle-only wobble: each alternate stride now moves the full leg *and* boot, with a visible leading shoe and lifted foot. These are small 24×32 pixel edits to the approved protagonist artwork. Movement speed, camera timing, encounters and saves are unchanged.

Review the new motion on `/dev/` before promoting to stable. Existing character stills and gameplay remain unchanged.

## Full-sprite walking animation concept — October 28, 2026

The development build now uses `assets/hero_walk_sheet.png`, a new **3-column by 4-row original sprite atlas** (24×32 pixels per frame), produced from a Wildbound walking-animation concept. `scripts/character_art.gd` selects *complete* directional poses instead of deforming the previous standing sprite's legs and boots. Each facing has separate left-step, centered idle, and right-step artwork. The old procedural leg manipulation has been removed. Movement speed, camera easing, collisions, creatures, and saves are unchanged. This is an art playtest, not a stable release; check all directions for foot motion, color consistency, and silhouette alignment.
