# Willowrest Complete Environment v1.0 — art-integrated game branch

The previous procedural SVG scenery and add-on tree sprites were incompatible with the approved concept. This branch **replaces the whole map art** with the user's approved original pixel-art environment and switches the playable grid to 48×14 at 24 pixels/tile.

## Code completed
- Complete 24 px overworld map geometry, keeper position, town paths and encounter grass in `scripts/willowrest_map.gd`
- `main.gd` supports the upgraded illustrated environment without changing battle, capture, evolution, party, or input logic
- Old `world.png`, world SVG and extra-tree overlay are disabled automatically in the new environment
- Subtle animated lake-water shader, with no fade/transparency logic around the player
- Camera limits, protagonist/NPC positions, walk movement and blocking updated to the new tile grid
- New save namespace to avoid incorrectly interpreting older 16-pixel map coordinates
- GitHub Actions CI tests the old fallback, new environment path, navigable route, import and web export

## One image still needed for the live web preview

The actual 1152×336 PNG was created from the approved concept and distributed as part of the generated **Wildbound_Willowrest_Complete_Environment_v1.zip** in the ChatGPT conversation. GitHub connector currently accepts source code but not direct transfer of container-generated PNG files.

**To activate this already-implemented build:**
1. Download/extract the package from the conversation.
2. In GitHub Desktop fetch this feature branch: `feature/willowrest-full-environment-v1`.
3. Copy `Wildbound_Environment_v1_Package/assets/willowrest_world.png` to the repository's `assets/willowrest_world.png` (keep the exact filename).
4. Commit and Push to the feature branch. The environment CI workflow checks the actual imported art file.
5. After validating it, merge the feature into `develop`. The existing main-branch web deployment will then publish it to `/Wildbound/dev/`.

The package also includes transparent extracted sprites, tiles, houses, props and four original water animation source frames, ready for a later modular TileMapLayer conversion. The new scene is intentionally a **baked full-environment map** to retain concept quality and avoid patchwork visual mismatches. The extracted source pieces are included for future editing, not falsely described as a complete standalone tileset implementation.

Existing `main` stable release is untouched until approved.
