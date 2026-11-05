# Wildbound v0.21 • Mobile Guide & Upgrade Metrics

This update changes UI presentation only. Actual battle multipliers, Gold prices, enemy curve, stage 17 progression, Ascension requirements, and all saved browser-game data stay the same.

## Guide
The original `AcceptDialog.dialog_text` label rendered paragraphs as unwrapped horizontal lines on phones. Replace the text field with a bounded scrollable `RichTextLabel` (592×378 in a 630×484 centered window on the 1280×720 scene), enable word wrapping and logical sections. Contents cover Start Battle, elemental counter cycle, Farm/Resume Push, upgrading, Stage 20 Ascension and save slots. Restore a guide button's visibility and the paused-game modal behavior.

## Whole-number DPS
The old `collection_ui_v12.gd` interpolated `game.squad_dps()` directly as `%s`, resulting in long floating-point digits on the actual live 3v3 battle HUD. On the final v0.21 scene, override the HUD's DPS readout after the inherited refresh with a rounded integer display. Preserve transient hit/crit messages. Currency formatting is unchanged.

## Real Gold upgrade statistics
The `GROW` sidebar shows exact each-rank math, cumulative current bonuses, and the next-rank outcome rather than generic description plus rank:
- **Power:** each rank multiplies all damage by 1.13; cumulative bonus = `(1.13^rank−1)×100%`.
- **Tempo:** each rank reduces attack interval to 94% of the previous interval; attack-rate increase = `(1/0.94^rank−1)×100%`.
- **Guard:** +22 base maximum Ward HP per rank, before permanent multipliers. Show actual effective maximum Ward now and next.
- **Crit:** starts at 5%, +3.5 percentage points per rank, maximum 70%. Crit hits deal 2.5×. Tooltip includes expected attack-damage multiplier.
- **Bounty:** every rank multiplies victory Gold by 1.15. Show cumulative % bonus and estimated actual Gold per victory at current stage before/after next rank.
- **Recovery:** 1.0% of max HP per second baseline, +0.7 percentage points per rank (the 0.25-second pulse calculation in 3v3 engine). Show current/next percentage of maximum HP per second.
- **Pierce:** +20% damage *versus Guardians only* per rank, additive in its boss-only multiplier.
- Upgrade tooltip additionally describes exact formulas and current values. Updates during buys and across save reloads; no extra save keys needed.

Validation: `tests/check_readability_v21.gd` asserts actual live guide, math precision, purchases, integer DPS and legacy save loading. `tests/capture_readability_v21.gd` renders real mobile-scaled Godot screenshot review.
