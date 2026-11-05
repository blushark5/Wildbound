# Wildbound v0.25 — Unified Mobile Interface Pass

This iteration deliberately changes **presentation only**. All v0.24 creature battle effects, Gold costs, stage gates, saved squads, Autos, Ascension rewards and Essence rules remain unchanged. Same browser `/bond/` address and safe slot 1–3 persistence.

## What changes in the game

- **Collapsible Journey panel.** In its new default compact presentation, Journey occupies 115px rather than 198px. Essential quest title, progress and the working CLAIM button remain visible. A MORE button expands the description, rewards and progress rail. This increases the right-side shop scrolling area by 83px, making upgrades easier to read without scrolling so frequently.
- **Dedicated shop context header.** Under the tabs, show GOLD UPGRADES + chosen x1/x10/x25/MAX, NEST + real owned collection count, PERMANENT POWER + Echo currency, or WORLD & TACTICS + current stage. Tab controls and scrolling rows adjust vertically when Journey expands/collapses.
- **A+ type mode.** A persistent TEXT A+/TEXT A− control in the free header space enlarges key creature names, battle status labels, Field Guide details and descriptions in the upgrade shop without destroying the fixed 1280×720 mobile-landscape layout. Each browser save slot remembers its own preference.
- **Combat hierarchy.** Larger and clearer touch targets for the core attack/resonance/farm/speed controls. Shorter primary call-to-action text and a strong emphasis on the three active creatures. Each squad card has a 01/02/03 badge and abbreviated, more legible species names.
- **Non-overlapping notifications.** A short-lived toast temporarily replaces the small encounter hint at the top of the arena rather than covering it. The v0.24 Ascension RESUME BATTLE action remains accessible.
- **Field Guide clarity.** Element columns retain their original order and show live owned species count per element. The selected slot reads REPLACE SLOT N; an owned creature's button says EQUIP IN SLOT N or SWAP INTO SLOT N (rather than vague MOVE HERE). The exact selected creature shows IN SLOT N and cannot be reassigned accidentally.
- **Stage and Ascension dialogs** retain all v0.24 wrapping/scrolling. Full competitive difficulty, Auto-Form, Replay Route, and Gold growth are preserved.

## Save compatibility

`bond_engine_v25.gd` extends v24 and adds only `v25_compact_journey` (defaults true) and `v25_large_text` (defaults false). Both persist per browser slot. Older saves with no v25 keys load as normal; New Game and switching slots recreate the newest engine.

## Acceptance

`tests/check_interface_v25.gd` asserts real Godot layout rectangles (both quest modes), independently saved large text, header button collision avoidance, Field Guide action vocabulary, element ownership counts, historical save migration and post-Ascension battle recovery.

`tests/capture_interface_v25.gd` exports five genuine 1280×720 screenshots for human review before web deployment. All prior v0.15–v0.24 regressions must continue to pass.
