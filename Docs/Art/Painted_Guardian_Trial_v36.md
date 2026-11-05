# Wildbound v0.36 — Painted Battle Asset Manifest

## Source of art

The original v0.36 raster artwork is derived from the Wildbound Guardian Trial visual direction approved by the project owner. The new assets were manually separated into independently rendered scene and creature layers, not used as one static interface screenshot.

## Game-ready atlas

`assets/duel/v36/concept_atlas.webp.base64` is a WebP/RGBA atlas encoded as base64 for reliable import in this Godot project. It is decoded and cached by `scripts/duel/painted_art_v36.gd`. Native atlas resolution: **1280 × 1104**.

- **Scenery:** `Rect2i(0,0,1280,720)` — clean Verdant Grove painting with falls, glowing guardian, ruins, flowers and reflective platform.
- **Cindlet:** `Rect2i(0,720,426,384)` — transparent illustrated Fire fox.
- **Brinlet:** `Rect2i(426,720,426,384)` — transparent aquatic fox with gills and water-tail forms.
- **Spriglet:** `Rect2i(852,720,426,384)` — an Earth fox treatment with plant/leaf accents, based on the Cindlet anatomy. A completely distinct Earth-character illustration remains a future art requirement.

The loader trims transparent margins, caches the creature textures, and makes runtime attack/damage color variants without changing the battle engine. Evolved creature gameplay states and save data remain preserved, but commissioned illustration-quality unique evolved poses are still outstanding.

## Composition

`scripts/duel/duel_ui_v36.gd` uses the painted scenery as a **separate TextureRect**. Cindlet, Brinlet, Spriglet, HUD portraits, health bars, buttons, roster selection, menu navigation, and victory messaging are live Godot nodes. No screenshot of an interface is rendered as a control layer.

The art composition is designed for the 1280×720 gameplay viewport. The existing project identity and `user://wildbound_duel_v30.json` save file remain unchanged.

## QA

`tests/check_duel_v36.gd` prevents fallback to the old atlas, ensures creatures are transparent and appropriately sized, and exercises real combat and progression. `tests/capture_duel_v36.gd` saves six live rendered screenshots for visual inspection.
