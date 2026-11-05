# Wildbound v0.24 — Ascension Battle Unblock & Interface Cleanup

## Blocking player issue
A real issue in v0.22 and v0.23 could leave battle progression disabled after the player confirmed Ascension. The Ascension confirmation already paused gameplay, so the inherited results popup recorded `playing=false`. Closing that popup incorrectly restored the false pause state, while the large attack/action button was disabled whenever `playing=false`. This created an unrecoverable in-game lock.

v0.24 resolves this in two layers:
1. Engine always resets to an actually playable Stage 1 on successful Ascension, with `battle_started=true`, no `awaiting_next` and no farm state. It preserves the historical record, collections, presets, and optional Replay and Auto-Form preferences.
2. The results dialog now says **START NEW ASCENSION RUN**. After it closes, the UI explicitly clears both old modal-pause variables and resumes fighting. The primary battle button is enabled as **RESUME BATTLE** when a saved/current session is paused, so even an older corrupted modal state is recoverable without deleting data.
3. First new game remains explicitly gated by START FIRST BATTLE. No changes to Stage 17/20 difficulty, Gold, Bond, or Essence rules.

## Interface cleanup
- Field Guide shortcut was obscured by Auto-Form. It now has its own visible touch-sized button between Buy x1 and Replay Route.
- Replay and Auto-Form buttons no longer overlap the Field Guide button.
- Remove an obsolete "Squad slot selected" text strip floating across the right navigation buttons. Slot assignment stays in the Field Guide.
- Hide clipped/duplicate legacy notification ticker at bottom screen edge, retain compact temporary battle notifications.
- Increase font size on key action buttons and normalize button sizes.
- Ascension confirmation, Ascension results, Matchup details and Chronicle now use bounded word-wrapped scrollable text instead of over-wide native dialog text. Opening guide remains wrapped as in v0.21.

## Validation
`tests/check_ascension_recovery_v24.gd` reproduces the real v0.23 results-close freeze, checks an enabled RESUME BATTLE recovery action, responsive clock, UI control rectangles, modal wrap/scroll, New Game / save switching and old-save compatibility.

`tests/capture_ascension_recovery_v24.gd` captures the real Godot HUD after Ascending and while manually paused and the updated Field Guide. All existing v0.15–v0.23 tests must also pass. Same /bond/ browser route and browser save identity.
