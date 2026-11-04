# Wildbound v0.26 • Visual Reset: The Living Arena

This is a visible visual overhaul, not a balance update. In v0.25, a 414px Quest/Upgrade dashboard constantly competed with 826px of actual 3v3 combat. v0.26 instead makes the **battle a full-width 1252px arena by default**. All game systems remain live, accessible and compatible with existing browser saves.

## New hierarchy
The normal screen shows only: (1) header with Gold/Essence/Echoes, Ascend and Saves, (2) wide elemental battle with six framed creatures and its stage/farm/counter feedback, (3) three significantly larger creature cards with their art, level purchase, ability and swap, (4) an intentional battle action bar.

- A new original, lightweight SVG rune/sigil in the center and restrained team/enemy panel borders visually identify two sides of the battle.
- Creature portraits, name/HP readouts, elemental icons and halos are spread across the arena, rather than confined to a small row.
- Each active squad card is now ~400px wide (formerly 256px), with larger art and visible skill and level controls.
- Field Guide, Upgrades and Tactics buttons are the *only* secondary actions next to the team title. Auto-Form, Replay and font-size controls are no longer always on-screen.
- Main battle controls are significantly wider, with prominent START/RESUME/NEXT / ASSIST, and distinct Resonance, Farm/Push and Speed.

## Intentional shop drawer
**UPGRADES** opens the former right-side Journey, Gold, Nest, Ascend and World interfaces as a layered right drawer. It has its own CLOSE control, retains all four tabs and honors the v0.25 More/Less Journey preference. The panel is absent when the player is battling, rather than constantly taking up over a third of the screen. Players can still claim rewards, hatch eggs, spend Echoes and access all original functions.

## Advanced tactics, not a permanent button row
**TACTICS • MORE** reveals optional Auto-Form, Replay Route, Choose Farm Stage, Matchups and Text Size. Actions are *real working controls*, not placeholders. The compact menu marks automation locked until Ascension and farming locked until Stage 1 is cleared. Original stage picker and elemental matchups remain available from the arena header too.

## Requirements
- No changes to creature identity/art, unlocked collection, element matchups, enemy difficulty, Bond caps, Gold price, Essence awards, Stage 20 Ascension, Echo research, presets, stored save slots or automation semantics.
- The v0.24 Ascension results-close recovery remains protected and tested.
- Existing v0.25 accessibility and compact Journey preferences carry over.
- Tests: `tests/check_visual_reset_v26.gd`, actual Godot screenshots `tests/capture_visual_reset_v26.gd`, *all* prior v0.15–25 regressions.
- Only the validated development branch should be published to the existing `https://blushark5.github.io/Wildbound/bond/`.
