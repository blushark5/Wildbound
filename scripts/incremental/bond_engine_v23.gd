extends "res://scripts/incremental/bond_engine_v22.gd"
## Wildbound v0.23: optional historical route replay, three permanent
## tactical squad presets, recorded Ascension history and real permanent
## speed research effects for the full 12-creature combat roster.
const SQUAD_PRESET_COUNT: int = 3
const CHRONICLE_LIMIT: int = 12

var squad_presets: Dictionary = {}
var replay_route_enabled: bool = false
var replay_frontier_reached: bool = false
var ascension_chronicle: Array[Dictionary] = []
var run_started_seconds: float = 0.0

func combat_damage(kind: String) -> float:
    # Alpha intended this +8% per permanent Speed rank, but collection v12
    # used its own combat formula. Apply the earned bonus to all 12 species.
    return super.combat_damage(kind)*pow(1.08,float(int(research.get("speed",0))))

func combat_interval(kind: String) -> float:
    # The matching 3% interval reduction was previously absent from the
    # unique-species squad combat route. It is still subject to the floor.
    return maxf(0.16,super.combat_interval(kind)*pow(0.97,float(int(research.get("speed",0)))))

func is_replay_eligible(stage: int = -1) -> bool:
    var target: int = wave if stage < 1 else stage
    return ascensions >= 1 and lifetime_cleared_stage >= 1 and target >= 1 and (
        target <= lifetime_cleared_stage) and not repeat_wave and battle_started

func replay_status() -> String:
    if ascensions <= 0:
        return "Unlocks at first Ascension"
    if not replay_route_enabled:
        return "OFF • choose to replay familiar stages"
    if repeat_wave:
        return "PAUSED • manual Gold farming"
    if wave > lifetime_cleared_stage or replay_frontier_reached:
        return "FRONTIER • new stages stay manual"
    return "ACTIVE • auto-advance through Stage %d" % lifetime_cleared_stage

func toggle_replay_route() -> bool:
    if ascensions <= 0:
        _report("REPLAY ROUTE unlocks after your first Ascension.")
        return false
    replay_route_enabled = not replay_route_enabled
    replay_frontier_reached = not is_replay_eligible()
    auto_advance_enabled = replay_route_enabled and is_replay_eligible()
    if auto_advance_enabled and awaiting_next:
        awaiting_next = false
        # Only stage entrances reassign squads. Respect a manual swap on
        # the current stage rather than overwriting the player's selection.
        _apply_autoform_stage(wave)
    _report("REPLAY ROUTE: "+replay_status())
    return true

func preset_team(index: int) -> Array[String]:
    var team: Array[String] = []
    if index < 1 or index > SQUAD_PRESET_COUNT:
        return team
    var raw: Variant = squad_presets.get(str(index),[])
    if not (raw is Array) or raw.size() != SQUAD_SIZE:
        return team
    var seen: Dictionary = {}
    for item in raw:
        var kind: String = String(item)
        if not has_instance(kind) or seen.has(kind):
            return []
        seen[kind] = true
        team.append(kind)
    return team

func save_squad_preset(index: int) -> bool:
    if index < 1 or index > SQUAD_PRESET_COUNT:
        return false
    var seen: Dictionary = {}
    for kind in squad_slots:
        if not has_instance(kind) or seen.has(kind):
            return false
        seen[kind] = true
    if seen.size() != SQUAD_SIZE:
        return false
    squad_presets[str(index)] = squad_slots.duplicate()
    _report("SQUAD PRESET %d SAVED • %s" % [index,preset_summary(index)])
    return true

func preset_summary(index: int) -> String:
    var members: Array[String] = preset_team(index)
    if members.size() < SQUAD_SIZE:
        return "EMPTY"
    var names: Array[String] = []
    for kind in members:
        names.append(display_name(kind))
    return ", ".join(names)

func load_squad_preset(index: int) -> bool:
    var members: Array[String] = preset_team(index)
    if members.size() != SQUAD_SIZE:
        _report("Preset %d is empty or contains an unowned creature." % index)
        return false
    if squad_slots != members:
        squad_slots = members.duplicate()
        _setup_trainer_fight()
    manual_override_stage = wave
    last_autoformed_stage = wave
    last_autoform_summary = "MANUAL PRESET %d" % index
    _report("PRESET %d LOADED • Team is manually chosen for Stage %d." % [index,wave])
    return true

func _enemy_defeated() -> void:
    var completed: int = wave
    var farming: bool = repeat_wave
    # Crucial: Challenge v10 reads auto_advance_enabled inside super().
    # It must be TRUE for old completed stages, FALSE at the frontier.
    # The historical cap is captured before this victory can raise it.
    var cap_before: int = lifetime_cleared_stage
    if replay_route_enabled:
        auto_advance_enabled = (
            ascensions > 0 and not farming and completed < cap_before)
    super._enemy_defeated()
    if replay_route_enabled and not farming and completed >= cap_before:
        replay_frontier_reached = true
        auto_advance_enabled = false
        awaiting_next = true
        _report("NEW FRONTIER • Stage %d is next. REPLAY ROUTE is paused; choose NEXT STAGE and your team." % wave)
    elif replay_route_enabled and not farming:
        replay_frontier_reached = false

func _regroup() -> void:
    var was_replaying: bool = replay_route_enabled and not repeat_wave
    super._regroup()
    if was_replaying:
        replay_route_enabled = false
        replay_frontier_reached = true
        auto_advance_enabled = false
        _report("REPLAY STOPPED AT STAGE %d • A loss requires your tactical choices or farming." % wave)

func enter_next_stage() -> bool:
    var ok: bool = super.enter_next_stage()
    if ok:
        # A manual NEXT into an uncleared stage is never switched to automatic.
        replay_frontier_reached = not is_replay_eligible()
        auto_advance_enabled = replay_route_enabled and is_replay_eligible()
    return ok

func farm_stage(stage: int) -> bool:
    var ok: bool = super.farm_stage(stage)
    if ok:
        auto_advance_enabled = false
    return ok

func set_farming() -> bool:
    var ok: bool = super.set_farming()
    if ok:
        auto_advance_enabled = replay_route_enabled and is_replay_eligible()
    return ok

func ascend() -> bool:
    var earned: int = available_echoes()
    if earned < 1:
        return false
    var old_stage: int = maxi(lifetime_cleared_stage,maxi(0,best_wave-1))
    var seconds: float = maxf(0.0,total_seconds-run_started_seconds)
    var owned: int = collection_count()
    var next_number: int = ascensions+1
    var did: bool = super.ascend()
    if not did:
        return false
    var entry: Dictionary = {
        "number":next_number,"best_stage":old_stage,
        "echoes":earned,"duration":seconds,
        "creatures":owned,"lifetime":lifetime_cleared_stage
    }
    ascension_chronicle.push_front(entry)
    if ascension_chronicle.size() > CHRONICLE_LIMIT:
        ascension_chronicle.resize(CHRONICLE_LIMIT)
    run_started_seconds = total_seconds
    replay_frontier_reached = false
    auto_advance_enabled = replay_route_enabled and is_replay_eligible()
    _report("ASCENSION #%d • +%d Echoes. REPLAY %s through Stage %d; %d runs recorded." % [
        next_number,earned,"ON" if auto_advance_enabled else "OFF",
        lifetime_cleared_stage,ascension_chronicle.size()])
    return true

func research_details(kind: String) -> Dictionary:
    if not research.has(kind):
        return {"summary":"Unknown","effect":"Unknown"}
    var rank: int = int(research[kind])
    var next: int = rank+1
    var summary: String = ""
    var effect: String = ""
    match kind:
        "might":
            summary = "+22% damage per rank • multiplies"
            effect = "Total %.2fx → %.2fx damage" % [pow(1.22,float(rank)),pow(1.22,float(next))]
        "heart":
            summary = "+18% maximum Ward per rank"
            effect = "Total %.2fx → %.2fx Ward" % [pow(1.18,float(rank)),pow(1.18,float(next))]
        "bounty":
            summary = "+12% victory Gold per rank"
            effect = "Total %.2fx → %.2fx Gold" % [pow(1.12,float(rank)),pow(1.12,float(next))]
        "speed":
            summary = "+8% damage, -3% attack interval/rank"
            effect = "Damage %.2fx → %.2fx • interval %.3fx → %.3fx" % [
                pow(1.08,float(rank)),pow(1.08,float(next)),
                pow(0.97,float(rank)),pow(0.97,float(next))]
        "scavenge":
            summary = "+1 Guardian shard, +3.5pt Relic chance"
            effect = "Guardian shards %d → %d • relic chance %.1f%% → %.1f%%" % [
                3+rank,4+rank,
                minf(0.80,0.35+0.035*float(rank))*100.0,
                minf(0.80,0.35+0.035*float(next))*100.0]
        "incubator":
            summary = "+4% base maximum Ward per rank"
            effect = "Ward multiplier %.2fx → %.2fx" % [1.0+0.04*rank,1.0+0.04*next]
        "automation":
            summary = "Rank 1 unlocks automatic Gold spending"
            effect = "Autobuyer unlocked" if rank >= 1 else "Next rank unlocks autobuyer"
        "instinct":
            summary = "Rank 1 unlocks automatic creature skills"
            effect = "Auto-skills unlocked" if rank >= 1 else "Next rank unlocks auto-skills"
    return {"summary":summary,"effect":effect,"rank":rank,"next_cost":research_cost(kind)}

func to_dict() -> Dictionary:
    var data: Dictionary = super.to_dict()
    data["v23_squad_presets"] = squad_presets.duplicate(true)
    data["v23_replay_enabled"] = replay_route_enabled
    data["v23_replay_frontier"] = replay_frontier_reached
    data["v23_chronicle"] = ascension_chronicle.duplicate(true)
    data["v23_run_started_seconds"] = run_started_seconds
    return data

func load_save() -> bool:
    var ok: bool = super.load_save()
    squad_presets.clear()
    replay_route_enabled = false
    replay_frontier_reached = false
    ascension_chronicle.clear()
    run_started_seconds = total_seconds
    if not ok:
        return false
    var file: FileAccess = FileAccess.open(SAVE_FILE,FileAccess.READ)
    if file == null:
        return true
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary):
        return true
    var data: Dictionary = parsed
    var presets: Variant = data.get("v23_squad_presets",{})
    if presets is Dictionary:
        for index in range(1,SQUAD_PRESET_COUNT+1):
            var raw: Variant = presets.get(str(index),[])
            if not (raw is Array) or raw.size() != SQUAD_SIZE:
                continue
            var seen: Dictionary = {}
            var members: Array[String] = []
            for value in raw:
                var kind: String = String(value)
                if not has_instance(kind) or seen.has(kind):
                    members.clear()
                    break
                seen[kind] = true
                members.append(kind)
            if members.size() == SQUAD_SIZE:
                squad_presets[str(index)] = members
    replay_route_enabled = bool(data.get("v23_replay_enabled",false)) and ascensions > 0
    replay_frontier_reached = bool(data.get("v23_replay_frontier",false))
    var history: Variant = data.get("v23_chronicle",[])
    if history is Array:
        for entry in history:
            if not (entry is Dictionary) or ascension_chronicle.size() >= CHRONICLE_LIMIT:
                break
            var index: int = int(entry.get("number",0))
            if index < 1 or index > ascensions:
                continue
            ascension_chronicle.append({
                "number":index,
                "best_stage":clampi(int(entry.get("best_stage",0)),0,1000000000),
                "echoes":maxi(0,int(entry.get("echoes",0))),
                "duration":maxf(0.0,float(entry.get("duration",0.0))),
                "creatures":clampi(int(entry.get("creatures",0)),0,12),
                "lifetime":clampi(int(entry.get("lifetime",0)),0,1000000000)
            })
    run_started_seconds = clampf(float(data.get("v23_run_started_seconds",total_seconds)),0.0,total_seconds)
    # Old v0.22 auto-advance may have been left on. Keep it only on
    # already-beaten stages if Replay Route is explicitly enabled.
    if replay_route_enabled:
        auto_advance_enabled = is_replay_eligible() and not replay_frontier_reached
    return true
