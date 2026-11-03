extends "res://scripts/incremental/bond_engine_v19.gd"
## v0.20 • Field-ready farming QoL.
## A saved winning squad is tied to a STAGE in the current Ascension run;
## every farming defeat steps down a stage rather than trapping the player.
## Gold/Bond/Essence rules and Guardian scaling stay exactly as before.

var stage_winning_teams: Dictionary = {}
var push_return_stage: int = 0
var auto_farm_retreats: int = 0

func last_cleared_run_stage() -> int:
    # run_peak is one past the last cleared stage. On Ascension it resets to 1.
    return maxi(0,run_peak-1)

func winning_team_for(stage: int) -> Array[String]:
    var result: Array[String] = []
    var stored: Variant = stage_winning_teams.get(str(stage),[])
    if not (stored is Array) or stored.size() != SQUAD_SIZE:
        return result
    var already: Dictionary = {}
    for entry in stored:
        var kind: String = String(entry)
        if kind == "" or not has_instance(kind) or already.has(kind):
            return []
        already[kind] = true
        result.append(kind)
    return result

func _restore_winning_team(stage: int) -> bool:
    var saved: Array[String] = winning_team_for(stage)
    if saved.size() != SQUAD_SIZE:
        return false
    # Do not call assign_creature three times. That would repeatedly spawn
    # enemies and displace/reorder teammates during an in-progress lineup.
    for i in range(SQUAD_SIZE):
        squad_slots[i] = saved[i]
    return true

func farm_stage(stage: int) -> bool:
    var maximum: int = last_cleared_run_stage()
    if stage < 1 or stage > maximum:
        _report("Clear a stage this Ascension before farming it. Available stages: 1-%d." % maximum)
        return false
    if not repeat_wave:
        # Remember the WALL or next unplayed stage so RESUME PUSH jumps
        # straight back after training, even if the player farms Stage 1.
        push_return_stage = maxi(1,wave)
    var restored: bool = _restore_winning_team(stage)
    wave = stage
    repeat_wave = true
    awaiting_next = false
    last_clash = "FARMING • EARN GOLD AND BOND XP • NO ESSENCE"
    _spawn_enemy()
    _fit_enemy_to_region()
    _setup_trainer_fight()
    _report("FARM STAGE %d • %s. Gold + Bond XP, no Essence. RESUME PUSH returns to Stage %d." % [
        stage,"last winning squad restored" if restored else "current squad kept (no recorded winner)",push_return_stage])
    return true

func set_farming() -> bool:
    if repeat_wave:
        var target: int = maxi(1,push_return_stage if push_return_stage > 0 else run_peak)
        # A stage may be carried on old saves with no farm target; clamp to
        # the furthest point reached THIS run. Never teleport beyond it.
        target = mini(target,maxi(1,run_peak))
        repeat_wave = false
        awaiting_next = false
        push_return_stage = 0
        wave = target
        last_clash = "PUSH RESUMED • RETRY YOUR HIGHEST STAGE"
        _spawn_enemy()
        _fit_enemy_to_region()
        _setup_trainer_fight()
        _report("PUSH RESUMED • Stage %d. Farm any cleared stage if this matchup is still too strong." % wave)
        return true
    return farm_stage(last_cleared_run_stage())

func _enemy_defeated() -> void:
    var completed: int = wave
    var roster: Array[String] = squad_slots.duplicate()
    super._enemy_defeated()
    # The player genuinely defeated all three opponents. Update even on a
    # farm replay: the most recently successful team best reflects upgrades
    # and matchup changes. Never record a loss or a partial victory.
    var distinct: Dictionary = {}
    for kind in roster:
        if kind != "" and has_instance(kind):
            distinct[kind] = true
    if distinct.size() == SQUAD_SIZE:
        stage_winning_teams[str(completed)] = roster.duplicate()
    if repeat_wave:
        auto_farm_retreats = 0

func _regroup() -> void:
    var farming_before: bool = repeat_wave
    var failed_stage: int = wave
    var original_push_target: int = push_return_stage
    super._regroup()
    if not farming_before:
        return
    if failed_stage > 1 and last_cleared_run_stage() >= failed_stage-1:
        auto_farm_retreats += 1
        var fallback: int = failed_stage-1
        if farm_stage(fallback):
            push_return_stage = original_push_target if original_push_target > 0 else maxi(run_peak,failed_stage)
            _report("AUTO-RETREAT • Could not farm Stage %d. Trying Stage %d with its last winning squad. Gold/Bond only." % [failed_stage,fallback])
            return
    # Stage 1 is the bottom of the retreat ladder. Stop and allow team
    # selection / Gold upgrades rather than auto-losing forever.
    repeat_wave = false
    awaiting_next = true
    last_clash = "SQUAD DEFEATED • FARM FLOOR REACHED"
    _report("FARM FLOOR • Stage 1 defeated your squad. Train or change the team and press RETRY.")

func ascend() -> bool:
    var success: bool = super.ascend()
    if success:
        stage_winning_teams.clear()
        push_return_stage = 0
        auto_farm_retreats = 0
    return success

func to_dict() -> Dictionary:
    var data: Dictionary = super.to_dict()
    data["v20_stage_winning_teams"] = stage_winning_teams.duplicate(true)
    data["v20_push_return_stage"] = push_return_stage
    data["v20_retreats"] = auto_farm_retreats
    return data

func load_save() -> bool:
    var success: bool = super.load_save()
    stage_winning_teams.clear()
    push_return_stage = 0
    auto_farm_retreats = 0
    if not success:
        return false
    var file: FileAccess = FileAccess.open(SAVE_FILE,FileAccess.READ)
    if file == null:
        return success
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary):
        return success
    var data: Dictionary = parsed
    # Only accept historical squads that are complete, owned and stage-bound
    # within this Ascension cycle; junk/corrupt save values are ignored.
    var history: Variant = data.get("v20_stage_winning_teams",{})
    if history is Dictionary:
        for stage_key in history:
            var stage: int = int(String(stage_key))
            var found: Variant = history[stage_key]
            if stage < 1 or stage > last_cleared_run_stage() or not (found is Array):
                continue
            var roster: Array[String] = []
            var seen: Dictionary = {}
            for entry in found:
                var kind: String = String(entry)
                if not has_instance(kind) or seen.has(kind):
                    break
                roster.append(kind)
                seen[kind] = true
            if roster.size() == SQUAD_SIZE:
                stage_winning_teams[str(stage)] = roster
    push_return_stage = clampi(int(data.get("v20_push_return_stage",0)),0,maxi(1,run_peak))
    auto_farm_retreats = clampi(int(data.get("v20_retreats",0)),0,1000000)
    return success
