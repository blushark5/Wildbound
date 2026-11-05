extends "res://scripts/incremental/bond_engine_v20.gd"
## Wildbound v0.22: smart optional Auto-Form for repeat Ascension runs,
## persistent lifetime victories, and exact-batch module purchasing.
## Zero changes to damage coefficients, monster health or Gold inflation.
const BULK_MAX_SAFE: int = 1000
const EXTRA_MODULE_COSTS: Dictionary = {
    "crit":140.0,"bounty":90.0,"recovery":110.0,"pierce":180.0
}
const CORE_MODULE_COSTS: Dictionary = {
    "power":85.0,"guard":70.0,"tempo":120.0
}
var lifetime_cleared_stage: int = 0
var lifetime_winning_teams: Dictionary = {}
var auto_form_enabled: bool = true
var manual_override_stage: int = -1
var last_autoformed_stage: int = -1
var last_autoform_summary: String = ""

func is_autoform_eligible(stage: int) -> bool:
    return (ascensions > 0 and auto_form_enabled and
        stage >= 1 and stage <= lifetime_cleared_stage and not repeat_wave)

func toggle_auto_form() -> bool:
    if ascensions <= 0:
        _report("AUTO-FORM unlocks after your first Ascension. Manual team selection always remains available.")
        return false
    auto_form_enabled = not auto_form_enabled
    _report("AUTO-FORM %s • only through previously cleared Stage %d. Manual swaps remain yours." %
        ["ON" if auto_form_enabled else "OFF",lifetime_cleared_stage])
    return true

func matchup_analysis(kind: String,stage: int=-1) -> Dictionary:
    if not has_instance(kind):
        return {"strong":0,"neutral":0,"weak":0,"best":0.0}
    var enemies: Array = roster_for(maxi(1,wave if stage < 1 else stage))
    var strong: int = 0
    var weak: int = 0
    var neutral: int = 0
    var best: float = 0.0
    for enemy in enemies:
        var factor: float = multiplier(kind,String(enemy))
        best = maxf(best,factor)
        if factor > 1.0:
            strong += 1
        elif factor < 1.0:
            weak += 1
        else:
            neutral += 1
    return {"strong":strong,"neutral":neutral,"weak":weak,"best":best}

func _lineup_score(lineup: Array[String],stage: int) -> float:
    if lineup.size() != SQUAD_SIZE:
        return -1.0
    var rivals: Array = roster_for(stage)
    var total: float = 0.0
    var coverage: float = 0.0
    var elements: Dictionary = {}
    for kind in lineup:
        if not has_instance(kind):
            return -1.0
        elements[String(CATALOG[kind]["element"])] = true
        var dps: float = combat_damage(kind)/maxf(0.1,combat_interval(kind))
        var best: float = 0.0
        for enemy in rivals:
            best = maxf(best,multiplier(kind,String(enemy)))
        total += dps*best
    # Reward all three opposing elemental matchups, not simply choosing
    # three high-DPS attackers that all target the same vulnerable foe.
    for enemy in rivals:
        var best_foe: float = 0.0
        for kind in lineup:
            var dps: float = combat_damage(kind)/maxf(0.1,combat_interval(kind))
            best_foe = maxf(best_foe,dps*multiplier(kind,String(enemy)))
        coverage += best_foe
    var diversity: float = 1.0+0.025*float(elements.size()-1)
    return (total*0.58+coverage*0.42)*diversity

func recommended_team_for(stage: int) -> Array[String]:
    var empty: Array[String] = []
    if stage < 1 or stage > lifetime_cleared_stage:
        return empty
    var owned: Array[String] = []
    for kind in COLLECTION_ORDER:
        if has_instance(kind):
            owned.append(kind)
    if owned.size() < SQUAD_SIZE:
        return empty
    var best_team: Array[String] = []
    var best_score: float = -INF
    # 12 owned lines => only 220 triples, cheap on mobile. Elemental
    # target selection is already automated, so slot permutation does not
    # change output damage; retain the current positions if tied.
    for a in range(owned.size()-2):
        for b in range(a+1,owned.size()-1):
            for c in range(b+1,owned.size()):
                var candidate: Array[String] = [owned[a],owned[b],owned[c]]
                var score: float = _lineup_score(candidate,stage)
                if score > best_score:
                    best_score = score
                    best_team = candidate
    # Historical last winner is a useful tie-break even if the rerolled
    # encounter differs. If within 8% of optimal, favor familiarity.
    var historical: Variant = lifetime_winning_teams.get(str(stage),[])
    if historical is Array and historical.size() == SQUAD_SIZE:
        var retained: Array[String] = []
        var seen: Dictionary = {}
        for value in historical:
            var kind: String = String(value)
            if not has_instance(kind) or seen.has(kind):
                retained.clear()
                break
            seen[kind] = true
            retained.append(kind)
        if retained.size() == SQUAD_SIZE and _lineup_score(retained,stage) >= best_score*0.92:
            return retained
    return best_team

func _apply_autoform_stage(stage: int) -> bool:
    if not is_autoform_eligible(stage) or manual_override_stage == stage:
        return false
    if last_autoformed_stage == stage:
        return false
    var recommended: Array[String] = recommended_team_for(stage)
    if recommended.size() != SQUAD_SIZE:
        return false
    last_autoformed_stage = stage
    # Keep a historical team's slot locations when the same 3 species were
    # already assigned. Otherwise the 3 creatures appear in stable order.
    var same_members: bool = true
    for kind in recommended:
        if not squad_slots.has(kind):
            same_members = false
            break
    if not same_members:
        for i in range(SQUAD_SIZE):
            squad_slots[i] = recommended[i]
        _setup_trainer_fight()
    var names: Array[String] = []
    for kind in squad_slots:
        names.append(combat_name(kind))
    last_autoform_summary = "STAGE %d • %s" % [stage,", ".join(names)]
    _report("AUTO-FORM • "+last_autoform_summary)
    return true

func assign_creature(slot: int,kind: String) -> bool:
    var ok: bool = super.assign_creature(slot,kind)
    if ok:
        manual_override_stage = wave
        last_autoform_summary = "MANUAL TEAM • Stage %d" % wave
    return ok

func enter_next_stage() -> bool:
    var ok: bool = super.enter_next_stage()
    if ok and not repeat_wave:
        manual_override_stage = -1
        last_autoformed_stage = -1
        _apply_autoform_stage(wave)
    return ok

func _enemy_defeated() -> void:
    var cleared: int = wave
    var winners: Array[String] = squad_slots.duplicate()
    super._enemy_defeated()
    lifetime_cleared_stage = maxi(lifetime_cleared_stage,cleared)
    var seen: Dictionary = {}
    for kind in winners:
        if kind != "" and has_instance(kind):
            seen[kind] = true
    if seen.size() == SQUAD_SIZE:
        lifetime_winning_teams[str(cleared)] = winners.duplicate()
    # Optional auto-advance bypasses NEXT STAGE, so handle this route too.
    if not repeat_wave and wave != cleared and not awaiting_next:
        manual_override_stage = -1
        last_autoformed_stage = -1
        _apply_autoform_stage(wave)

func set_farming() -> bool:
    var previously_farming: bool = repeat_wave
    var ok: bool = super.set_farming()
    if ok and previously_farming and not repeat_wave:
        manual_override_stage = -1
        last_autoformed_stage = -1
        _apply_autoform_stage(wave)
    return ok

func ascend() -> bool:
    # Highest COMPLETED stage is best_wave - 1, not the stage reached
    # before a wall; only a genuine finished stage may enable Auto-Form.
    lifetime_cleared_stage = maxi(lifetime_cleared_stage,maxi(0,best_wave-1))
    var ok: bool = super.ascend()
    if ok:
        manual_override_stage = -1
        last_autoformed_stage = -1
        # v0.20 intentionally clears current-Ascension farming history.
        # v0.22 keeps a separate LIFE-TIME cache, so its new enemy seed
        # can be countered with actual owned creatures.
        _apply_autoform_stage(wave)
    return ok

func _module_cost_at(kind: String,rank: int) -> float:
    var first: float = float(EXTRA_MODULE_COSTS.get(kind,CORE_MODULE_COSTS.get(kind,INF)))
    if is_inf(first) or rank < 0:
        return INF
    var exponent: float = 1.56 if EXTRA_MODULE_COSTS.has(kind) else 1.58
    var amount: float = first*pow(exponent,float(rank))
    if is_inf(amount) or is_nan(amount):
        return INF
    return ceil(amount)

func module_batch_quote(kind: String,quantity: int) -> Dictionary:
    # quantity=0 => Buy Max, otherwise an EXACT x1/x10/x25 purchase.
    var out: Dictionary = {"count":0,"cost":0.0,"full":false}
    if not modules.has(kind) or quantity < 0:
        return out
    var target: int = BULK_MAX_SAFE if quantity == 0 else mini(quantity,BULK_MAX_SAFE)
    var funds: float = maxf(0.0,gold)
    var price: float = 0.0
    var count: int = 0
    var rank: int = int(modules[kind])
    for _i in range(target):
        var next_price: float = _module_cost_at(kind,rank+count)
        if is_inf(next_price) or next_price > funds-price:
            break
        price += next_price
        count += 1
    out["count"] = count
    out["cost"] = price
    out["full"] = count > 0 and (quantity == 0 or count == target)
    return out

func buy_module_batch(kind: String,quantity: int) -> int:
    var quote: Dictionary = module_batch_quote(kind,quantity)
    if not bool(quote["full"]):
        return 0
    var bought: int = 0
    for _i in range(int(quote["count"])):
        if not buy_module(kind):
            break
        bought += 1
    if bought > 0:
        _report("%s • bought %d rank%s. Rank %d; cumulative gains are visible in GROW." %
            [String(MODULE_NAMES.get(kind,kind)),bought,"s" if bought != 1 else "",int(modules[kind])])
    return bought

func to_dict() -> Dictionary:
    var data: Dictionary = super.to_dict()
    data["v22_lifetime_cleared"] = lifetime_cleared_stage
    data["v22_lifetime_winning_teams"] = lifetime_winning_teams.duplicate(true)
    data["v22_autoform_enabled"] = auto_form_enabled
    data["v22_manual_override_stage"] = manual_override_stage
    data["v22_last_autoformed_stage"] = last_autoformed_stage
    return data

func load_save() -> bool:
    var ok: bool = super.load_save()
    lifetime_cleared_stage = maxi(0,best_wave-1)
    lifetime_winning_teams.clear()
    auto_form_enabled = true
    manual_override_stage = -1
    last_autoformed_stage = -1
    if not ok:
        return false
    var file: FileAccess = FileAccess.open(SAVE_FILE,FileAccess.READ)
    if file == null:
        return true
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary):
        return true
    var data: Dictionary = parsed
    lifetime_cleared_stage = maxi(lifetime_cleared_stage,
        clampi(int(data.get("v22_lifetime_cleared",0)),0,1000000000))
    auto_form_enabled = bool(data.get("v22_autoform_enabled",true))
    manual_override_stage = int(data.get("v22_manual_override_stage",-1))
    last_autoformed_stage = int(data.get("v22_last_autoformed_stage",-1))
    # On v0.21 migration, copy existing current-run winning teams into the
    # lifetime history. Older unrecorded stages use a matchup optimizer.
    var history: Variant = data.get("v22_lifetime_winning_teams",
        data.get("v20_stage_winning_teams",{}))
    if history is Dictionary:
        for key in history:
            var stage: int = int(String(key))
            if stage < 1 or stage > lifetime_cleared_stage:
                continue
            var values: Variant = history[key]
            if not (values is Array) or values.size() != SQUAD_SIZE:
                continue
            var chosen: Array[String] = []
            var seen: Dictionary = {}
            for value in values:
                var kind: String = String(value)
                if not has_instance(kind) or seen.has(kind):
                    chosen.clear()
                    break
                chosen.append(kind)
                seen[kind] = true
            if chosen.size() == SQUAD_SIZE:
                lifetime_winning_teams[str(stage)] = chosen
    return true
