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

## Side-facing idle correction — October 28, 2026

The `develop` build includes `assets/hero_idle_sides.png`, two neutral standing side poses, each 24×32. The previously selected center side frames looked as though the player was mid-stride while stationary. The corrected standing sprites keep the current hairstyle and outfit but align both boots under the character. The four-direction walk animation frames, camera movement, collision and saves are unchanged. Preview test at `/dev/` before promoting to stable.

## Side idle invisibility hotfix

The first neutral side-idle PNG was malformed, causing the player to disappear while standing left or right. The fixed `develop` build uses a structurally verified 48×32 PNG and a fallback to the normal walk-sheet idle pose if that image fails to load. The development workflow now runs `tests/check_side_idle.gd` to require **visible nontransparent pixels** in both idle poses before exporting. This repair does not change movement timing, maps, creatures, or save data.

Please test side-facing idle at https://blushark5.github.io/Wildbound/dev/ and refresh with Ctrl+F5 if needed.

## Environment tree atlas pilot — October 28, 2026

The `develop` preview contains the first **approved-concept-derived environmental sprites**, isolated as four transparent 64×80 PNG frames in `assets/trees_atlas.png`. Three are broadleaf variations, one is evergreen. The game instantiates them using `scripts/tree_art.gd` at **already blocked tiles** of the central forest boundary (x=25, y=5/10/22/26). No new collision or encounter positions are added.

- This is an intentional small pilot, not a completed forest or terrain replacement.
- Art was extracted from Wildbound's original environment concept, cleaned into a transparent atlas and palette-limited for a pixel RPG.
- The existing background art and geometry remain in place so placement can be reviewed in the browser.
- `tests/check_tree_art.gd` validates atlas dimensions, visible pixels, four instantiated sprites and blocked trunk locations.
- Review size, overlap, style consistency and tree placement at `https://blushark5.github.io/Wildbound/dev/` before making a broader environment change.

Stable release on `main` remains unchanged.

## Smaller forest study — no player overlap

The latest `develop` art test changes the four prototype trees from 64×80 pixels to 32×40 native-size nearest-neighbor sprites. Their positions were moved away from the narrow central divider to blocked perimeter forest cells, so canopies do not overlap the player on walkable tiles. No tree fading/transparency logic, collision changes, save changes, or gameplay modifications were added.

The Godot development workflow now tests each full tree sprite footprint against the 24×32 player rectangle at every accessible tile; it fails the build if any tree can cover the character. Check the result at https://blushark5.github.io/Wildbound/dev/ .

## Willowrest complete scene — browser art acceptance pass

- The uploaded `assets/willowrest_world.png` is an **original** 1152×336 full-scene illustration used by the `develop` branch after PR #1.
- Development now activates the dedicated 24-pixel tile-grid path and associated map geometry, not the old layered procedural village art.
- The new save namespace avoids loading old map coordinates into the redesigned layout.
- The main web address retains the previously approved playable release. The experimental complete-scene game is at `https://blushark5.github.io/Wildbound/dev/`.
- Preview is pending in-browser visual/playability approval, especially collision boundaries, path alignment, keeper placement, water shimmer, and wild encounters.

## Keeper Vale and movement / collision repair — October 28, 2026

The full illustrated Willowrest in `develop` now includes a new original 24×32 Keeper Vale NPC (white cap and brown apron) instead of a tinted protagonist. The map collision uses blocked tree, building, flowerbed, bench and fence footprints aligned to the environment art. The player sprite's feet are aligned with its collision position, and holding a movement key now chains walking steps without forced idle pauses. The new `tests/check_willowrest_collision.gd` ensures encounter grass and Keeper Vale are reachable and key scenery cells cannot be entered. All Godot checks and web export passed on the feature branch.

Please test the repaired version at https://blushark5.github.io/Wildbound/dev/ before promoting it to stable.
