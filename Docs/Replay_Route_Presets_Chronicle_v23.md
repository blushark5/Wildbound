# Wildbound v0.23 — Replay Route, Tactical Squad Presets & Ascension Chronicle

Built on v0.22 (all prior art, combat, economy and save slots intact).

## Optional Replay Route
- Unlocks on the *first Ascension*. It is OFF until deliberately enabled, and persists between sessions and subsequent Ascensions when the player chooses to use it.
- A clearly labeled **REPLAY** toggle beside **AUTO-FORM** drives stage auto-advancement. They are independent: Replay controls travel; Auto-Form controls team choice.
- Replays only stages the player has already completed over their lifetime. For stages below the historical high-water mark, the engine uses the existing automatic trainer progression.
- On clearing the lifetime frontier stage, **NEXT** stays paused before the next, never-before-cleared stage. That next stage requires a human choice and manual entry. No automatic stage skips, Essence repeats, or extra rewards.
- A defeat stops Replay immediately instead of endlessly wiping. Gold farming separately pauses Replay progression and still auto-retreats as in v0.20. Manual lineup overrides remain in effect through the current battle.
- Stage 20 Ascension and difficulty remain identical.

## Three tactical presets
- The Field Guide's bottom bar has three **USE/SAVE** preset pairs; each stores an ordered trio of **owned, distinct** species, not new recruits. Disabled USE controls are clearly marked EMPTY.
- A successful USE swaps directly to that lineup and counts as a manual choice for Auto-Form. Presets survive Ascension, reload, and other progression but are separate for each save slot.
- The new save-slot restore path instantiates the v0.23 engine, fixing a previous inherited behavior where selecting a different slot recreated v0.19 and silently dropped newer runtime systems.

## Meaningful permanent Echo research
- **ASCEND** now shows per-rank effects and current-to-next totals for all eight Echo research tracks, rather than only generic "permanent" text:
  - Might: ×1.22 damage per rank
  - Heart: ×1.18 Ward per rank
  - Bounty: ×1.12 Gold per rank
  - Speed: ×1.08 damage and ×0.97 attack interval per rank
  - Scavenge: +1 boss Nest shard per rank and +3.5 percentage points to Relic drop chance (80% cap)
  - Incubator: +0.04 maximum Ward multiplier per rank
  - Automation/Instinct: unlock automated Gold spending and combat abilities, respectively
- **Critical fix:** Existing alpha Speed research was not being applied to v0.12's unique 12-creature squad calculations. It now takes effect when bought, on reload and after Ascension. Other combat stats and module prices are unchanged.

## Ascension Chronicle
- Every newly completed Ascension adds a local run-summary record: number, highest completed stage, earned Echoes, active run's simulation minutes, and creature collection size.
- The latest twelve Ascensions are retained per save slot, and a new **CHRONICLE** card in ASCEND opens a compact summary of the most recent six.
- Old v0.22 saves migrate without fabricated past records. Lifetime stage achievements, real run history, your presets, and Replay ON/OFF preference persist.

## Acceptance tests
The CI workflow must pass `tests/check_replay_presets_v23.gd` and the real UI capture `tests/capture_replay_presets_v23.gd`, in addition to the full existing v0.15–v0.22 suite. Publish to the existing `/bond/` browser route after validation.
