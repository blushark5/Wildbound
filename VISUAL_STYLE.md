# Wildbound — Pixel Art Direction (development)

## Goal
Create an original, readable, charming GBA-era creature RPG. Use FireRed/LeafGreen only as a high-level visual reference. Do not use Nintendo sprites, maps, music, textures, or other proprietary content.

## Approved visual principles
- Source-size terrain: 16 × 16 logical pixels. Pixel edges must stay crisp.
- Color palette: warm plaster, muted brick and ocean-blue roofs, complementary sage and forest greens, earthy ochre paths.
- Environmental hierarchy: first read the path/buildings/grass, then read the decorative details.
- NPCs, doors, tall grass, landmarks, and wild-encounter areas must remain recognizable.
- Keep every existing collision tile and saved world coordinate unchanged through this polish phase.
- Pixel-art texture filtering: nearest neighbor. Don't blur with linear filtering.
- Prefer a small coherent set of reusable motifs over unbounded generated detail.

## Current first art pass
`assets/world_polish.svg` layers additional original pixel details on top of `assets/world.png` while retaining original collision and route layout:
- Brick and blue-roof buildings with architectural depth, window reflections, doors, and landscaping.
- Richer multi-tone tall grass, foliage details, and treetop highlights.
- Dirt path stones and edge accents.
- Water ripples and small vegetation.

## Follow-up art batches (not yet implemented)
1. Animated hero/NPC walking cycles and unique trainer silhouettes.
2. Sprite studies for all three base families and their evolved counterparts.
3. Richer battle backgrounds and proportional attack effects.
4. Readable GBA-inspired menu art and consistent pixel-font treatment.
5. At least one gameplay screenshot for every PR before merging to `main`.

## Playtest checklist
- Walk in all four directions around Willowrest, through its central path, and into Fernpath Meadow.
- Look for invisible walls where decorative art may imply there should be a path.
- Check that trees don't appear over the player or Keeper Vale.
- Check the artwork at 1× logical resolution and full browser zoom.
- Confirm the battle scene, captures, saves, and pause menu still work normally.
