# Willowrest modular environment foundation

**Status:** isolated engineering and original-art extraction study, NOT an approved Willowrest replacement.

The separate test scene is scenes/environment/willowrest_modular_test.tscn. Existing main.tscn, battle/capture/evolution/save systems, stable Pages site, and /dev preview are unchanged.

## Implemented
- Four real Godot TileMapLayer instances for ground, paths, water and vegetation at 24 logical pixels per cell.
- A reproducible 384x24 PNG terrain study atlas baked from 16 unchanged pixel samples of the approved Willowrest illustration already in the repo.
- Independently placeable tree objects from the original illustrated transparent tree atlas, with foot-level trunk collision and separate canopy graphics.
- Water TileSet physics polygons; consistent grid blocking and encounter metadata; unchanged approved hero texture loader.
- An isolated movement test scene, automated grid/physics/asset assertions, and GitHub Actions web export artifact.

## Open the scene
Run the Godot scene scenes/environment/willowrest_modular_test.tscn (F6). If the atlas does not exist locally, run:
godot --headless --path . --script res://scripts/environment/bake_terrain.gd
Then reimport. WASD/arrow controls are available in the test scene. The regular project startup remains the original game.

## Important quality gate
The terrain samples reuse original illustrated Wildbound pixels, not geometrical redraws. Cropped textures, however, do not automatically become seamless tiles. Repeated grass, road and water textures, missing shore transitions and broader proportions require visual evaluation. **Do not accept automated import/export success as evidence of art quality.** This pack is NOT approved as production art.

## Remaining
- New manually illustrated cohesive grass/path/water edge and shoreline tiles, including organic variation and subtle animation.
- Standalone red/blue building scenes, props, tall grass animation and scene-level collision.
- Screenshot review at native pixel resolution and live browser playtest.
- Integrate approved map behind an explicit feature gate, not by rewriting battle systems or silently changing save coordinates.
- Only then consider promoting to develop and publishing in /dev.
