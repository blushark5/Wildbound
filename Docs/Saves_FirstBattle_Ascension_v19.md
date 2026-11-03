# Wildbound v0.19 — Save Slots, First Battle & Ascension UX

## In-game save manager
The existing top-right SAVE control is now **SAVES**. Clicking it saves immediately and opens the manager. Three independent local browser slots are available. Selecting another slot stores the current canonical save in its slot snapshot, restores the target into the canonical file and reloads the gameplay engine without changing the /bond/ address or Godot project identity. The old player save stays in Slot 1 by default, with no migration required; all three slots are private to that browser/device.

Manager options:
- Select **Slot 1 / 2 / 3**: continue saved progress or begin a new unstarted adventure in an empty slot.
- **New Game in Current Slot**: explicitly confirm the replacement. Resets the active slot only.
- **Delete Current Slot's Save**: explicitly confirm and clear active canonical + snapshot, preserving other slots.
- **Delete All 3 Local Saves**: separately confirm a destructive total reset.

The new in-memory adventure remains unsaved until a player clicks START BATTLE or manually SAVES. Clicking SAVES is also the explicit save action; autosave during a paused first introduction is suppressed to prevent unintentionally recreating just-deleted saves.

## First battle start
Newly created games have `v19_battle_started=false` in game state and no combat time, damage, loot, Essence or stage progression accrues before a deliberate **START FIRST BATTLE** click. The first-time guide explicitly says to close it, then press START. Reopening the guide or other modal windows during a battle temporarily pauses combat; play resumes after dismissing them. Existing v0.18 and older saves lack this field and are considered already started, so they never reset or get stuck at the gate.

## Ascension clarity
A persistent top-header shortcut shows **ASCEND LOCKED – STAGE X / 20** until the current run reaches Stage 20 (the engine's existing `run_peak >= 20` rule). Clicking it while locked explains progress, permanent gains and temporary resets. Once eligible, the same control becomes **ASCEND +N ECHOES** and opens the existing confirmation. The previously buried LEGACY tab is labeled ASCEND as well.

Ascension mechanics remain those of the previous engine: resets Gold, levels and temporary modules; carries creatures, collection, genes, traits, evolution, Bond XP and ranks, research and Essence; and regenerates encounter seed.

## Test gate and deployment
`tests/check_saves_v19.gd` runs the actual v0.19 Godot scene and verifies first-battle inactivity, guide/help, stage-20 shortcut, three independent saves, selective new/delete, total wipe and backward compatibility. `tests/capture_saves_v19.gd` renders actual UI screenshots for review. Earlier v0.15–0.18 regressions run without modifications. Published /bond/ route and app identity do not change.
