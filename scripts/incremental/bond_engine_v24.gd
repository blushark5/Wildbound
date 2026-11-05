extends "res://scripts/incremental/bond_engine_v23.gd"
## v0.24: Ascension is a new playable run, not a paused leftover stage.
## Runtime pause is owned by the UI, never persisted in save files.
func ascend() -> bool:
    var succeeded: bool = super.ascend()
    if not succeeded:
        return false
    # Explicitly reset temporary battle gates even when an older save or
    # modal flow left a pending NEXT or a first-start flag behind.
    battle_started = true
    awaiting_next = false
    repeat_wave = false
    replay_frontier_reached = false
    # Replay may auto-advance only through the already-cleared run stages.
    auto_advance_enabled = replay_route_enabled and is_replay_eligible()
    last_clash = "NEW ASCENSION RUN • STAGE 1 READY"
    _setup_trainer_fight()
    _report("ASCENSION %d • Stage 1 is ready. Resume fighting to grow your permanent power." % ascensions)
    return true
