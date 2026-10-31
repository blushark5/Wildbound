# WILDBOUND — Creature Ascension v0.1

## Design reset (October 2026)
Wildbound is now a creature-collection incremental battler, not a top-down RPG.
The original GBA-exploration build remains preserved on main/develop, and modular experiment in its isolated branch. This development branch runs a clean creature-focused prototype.

Inspiration is high-level genre design only: Clicker Heroes (automatic damage, waves, upgrades, prestige) and The Perfect Tower (wave pressure, build research and automation). All characters and code remain original Wildbound property.

## Implemented vertical slice
- Original three creature families: Spriglet > Thornhart; Brinlet > Tidemare; Cindlet > Blazetail, using existing original Wildbound sprites.
- Creatures auto-attack waves with distinct speed/base damage; tap-to-hit offers optional manual engagement.
- Gold scales exponentially with the wave; spend it to recruit/level creatures and upgrade Power, Ward or Speed.
- Enemy retaliation lowers the Sanctuary Ward; defeat makes the pack regroup four waves back while retaining run upgrades.
- Every 10th wave is a boss (extra health, stronger attacks and gold reward).
- Repeating waves to farm gold and build bonds is available.
- Evolve a recruited creature at Lv. 15 with at least 25 cumulative kills while owned.
- Ascend starting at wave 20, resetting waves, gold and temporary levels/modules in exchange for permanent Echo research; owned creatures, bonds and evolved forms persist.
- Persistent separate save file user://wildbound_incremental_reboot_v1.json (never writes over the old RPG save).
- Godot native UI at 960x540, no exploration map, single-scene web export.
- Automated engine economy, battle, recruiting, evolution, ascend, save/load and UI tests, plus screenshot and web-export CI.

## Play
On the isolated branch open Godot and press F6 on scenes/incremental/wildbound_idle.tscn, or press F5 to launch this branch's default scene.
Browser artifact is produced by Actions and can be served via a local static HTTP server. Existing GitHub Pages root and /dev remain unchanged.

## Not yet present
- Distinct wild enemy art, damage feedback/VFX, health-bar tween or full soundscape.
- Offline earnings (avoid simulating giant wave jumps before balance review).
- Dedicated collection/capture/egg mechanics, regional affinities, equipable module inventory, formations/synergies, late game progression or monetization.
- Creature sprite enlargement and richer UI artwork, mobile UX, accessibility pass, automated user interaction playtest.
- Visual/playtest acceptance. A screenshot or successful CI does not prove game feel.

## Next steps after first playtest
1. Tune first 15-minute pacing and early purchasing unlocks.
2. Improve visual battle feedback and original creature artwork; make evolution feel significant.
3. Add modular ability slots and elemental counterplay, then collection/drops.
4. Add limited offline resource income, improve prestige research and establish longer exponential growth.
5. Create a distinct public browser preview only after verified playtest, leaving main untouched.

## Scope gate
Do NOT add towns, explorable world, crafting mini-games, gacha/IAP, 100 creatures, PVP or a vast skill tree now. Small polished incremental loop first.
