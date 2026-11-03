# Wildbound v0.20 — Elemental Readability & Safe Farming Quality-of-Life

## Readability
Four individually drawn elemental emblem assets are added in `assets/incremental/v20`: Earth (stone/green), Water (droplet/blue), Fire (flame/orange) and Air (wind/purple). Every battle ally and enemy has an icon by its portrait. All three active squad cards show the same emblems and names. Field Guide cards now display element emblems, while the slot selection buttons explicitly show *slot number + currently assigned creature name + element icon*, with the selected slot called out. No changes to original v0.18 creature art or elemental counters.

## Farming
- A prominent **CHOOSE FARM STAGE** button opens a stage picker above the battle field. Select any numbered stage already cleared in the **current Ascension run**. The popup previews all three opposing creatures, their elements, and (where available) the last squad that successfully cleared that stage.
- Each time the player wins a real three-on-three stage, that stage's three distinct creature IDs are recorded as its latest winning squad, including during farming. Saved squads persist through reload and slot switching and retain element/trait identity.
- Selecting a farm stage restores its known winner automatically (if still owned), avoiding a new bad matchup caused by the player's temporary push team. If no historical winner exists for a migrated save, it keeps the player's current team.
- **FARM** on the battle HUD still instantly chooses the most recently cleared stage. If a farming attempt loses, the engine automatically retreats by one stage, restores that earlier stage's winning squad if recorded, and continues farming. It repeats until it reaches a beatable stage, and stops safely at Stage 1 if even that cannot be won.
- **RESUME PUSH** returns DIRECTLY to the prior push wall/next unplayed stage; players no longer have to manually replay every cleared stage after farming somewhere earlier.
- Ascension regenerates stage encounters and clears stage-bound winning history, while preserving ownership, trait, levels per original Ascension mechanics, Bond rank/XP, and lifetime first-clear Essence gating.
- Gold/Bond XP continue on replay; Essence is awarded only on the first-ever **lifetime** clear of a new stage number (Guardian +4), never while farming. This intentionally does not alter Stage 15's difficulty, mastery cap, upgrades or Ascension at Stage 20.

## Compatibility / test
Browser save path and identity unchanged on `/bond/`; v0.19's three slots/explicit first-start/Ascend shortcut remain unchanged. Old saves without `v20_stage_winning_teams` load normally with empty history; the first new win creates its record. Tests: `tests/check_farm_icons_v20.gd`, visual screenshots `tests/capture_farm_icons_v20.gd`; all prior v0.15–v0.19 tests must pass.
