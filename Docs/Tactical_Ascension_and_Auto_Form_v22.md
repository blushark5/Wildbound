# Wildbound v0.22 — Tactical Ascension & Intelligent Auto-Form

**Live implementation** on `/bond/` after Godot validation. Retains all v0.15–0.21 features, browser save identity, and the intentionally challenging Stage 17 wall / Stage 20 first Ascension.

## Lifetime stage-limited Auto-Form
- Auto-Form is **locked during the first adventure**, and defaults ON after your first Ascension, with a persistent manual ON/OFF toggle in the team header.
- The engine saves **highest stage actually completed**, not a wall merely reached. That permanent record survives Ascension and save-slot reloads.
- The engine separately saves lifetime teams that truly won previous stages; v0.20 stage-specific winners are imported on upgrade. The current-run farm lineup history is still intentionally cleared on Ascension.
- On entering a stage in a subsequent Ascension run, **only stages <= highest lifetime cleared** are eligible. New or unbeaten stages are **never auto-selected**, preserving user control and new-territory challenge.
- Because every Ascension rerolls the enemies, Auto-Form compares the *current* stage lineup against all owned creature combinations. It balances actual damage and elemental target coverage, preferring a historical winning squad when within 8% of the best current combination. Recommendations are optional, never unlock creatures, and never change economic multipliers.
- Manual Field Guide swaps are always respected on that stage; automatic selection resumes on a later eligible stage. No mid-battle unsolicited health reset. Toggling OFF persists through Ascensions and reloads.
- The GROW header indicates when Auto-Form is active, locked, manually overridden, disabled or beyond the lifetime record.

## Strategic counters
- Battle HUD displays the number of currently assigned allies whose best possible target is STRONG / EVEN / WEAK against the actual enemy trio.
- MATCHUPS details show each ally's relation to each of the three rivals. Original strong 2x and weak 0.45x damage multipliers remain intact; no rebalancing.
- Field Guide action tooltips describe elemental advantage and whether auto-form is eligible.

## Ascension preview and permanent result
- Before confirmation, show exact currently earnable Echoes, which specific creatures have enough XP for +1 Bond Rank, lifetime stage cleared, saved mechanics and reset mechanics.
- After confirming, report earned Echoes, promoted Bond companions, enduring stage record, new enemy set, and Auto-Form eligibility. Stage 10, 15 and 20 lifetime milestone flags appear in ASCEND for shorter session recognition.

## Bulk Gold convenience
- GROW begins with four touch-sized purchasing buttons: **x1, x10, x25, MAX**.
- Fixed amounts require full affordability; never silently buy a partial 10 or 25.
- MAX purchases all affordable ranks with a safe 1000-rank cap.
- The engine quotes exact cumulative geometric cost of each rank (1.58x per original core module, 1.56x per extra), then verifies actual charges during real `buy_module()` calls.
- Current and next Gold upgrade effect percentages from v0.21 remain visible. Does not change Gold prices or bonuses.

## Compatibility and acceptance
- Fresh game must not autoform; first Ascension starts an eligible repeated run.
- Existing saves use `best_wave-1` as a conservative migration baseline and import v0.20 stage winning lineups when present.
- Lifetime record, Auto-Form switch and historical winners persist per v0.19 save slot.
- Regression test: `tests/check_tactical_ascension_v22.gd`; actual UI screenshots: `tests/capture_tactical_ascension_v22.gd`. All prior v0.15–0.21 tests must also pass.
