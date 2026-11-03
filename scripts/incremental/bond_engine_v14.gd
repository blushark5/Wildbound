extends "res://scripts/incremental/collection_engine_v12.gd"
## v0.14: leveling is bounded by permanent Bond Rank, advanced only by Ascension.
## Battle victories grant Bond EXPERIENCE, which is preserved but cannot itself
## increase the per-run Gold leveling ceiling. General Gold modules stay uncapped.
const FIRST_CAP: int = 8
const CAP_STEP: int = 5
const MAX_BOND_RANK: int = 40
var bond_ranks: Dictionary = {}
var last_promotion: String = ""

func unit_bond_rank(kind: String) -> int:
    if not has_instance(kind):
        return 0
    return clampi(int(bond_ranks.get(kind,1)),1,MAX_BOND_RANK)

func bond_level_cap(kind: String) -> int:
    if not has_instance(kind):
        return 0
    return FIRST_CAP+CAP_STEP*(unit_bond_rank(kind)-1)

func next_bond_goal(kind: String) -> int:
    # A few battles to first mastery, then a deliberately slower climb.
    var rank: int = unit_bond_rank(kind)
    return 8+12*(rank-1)+3*maxi(0,rank-2)*(rank-1)/2

func previous_bond_goal(kind: String) -> int:
    var rank: int = unit_bond_rank(kind)
    if rank <= 1:
        return 0
    return 8+12*(rank-2)+3*maxi(0,rank-3)*(rank-2)/2

func bond_progress(kind: String) -> float:
    var start: int = previous_bond_goal(kind)
    var end: int = next_bond_goal(kind)
    return clampf(float(unit_bond(kind)-start)/maxf(1.0,float(end-start)),0.0,1.0)

func has_bond_training(kind: String) -> bool:
    return has_instance(kind) and unit_level(kind) < bond_level_cap(kind)

func level_batch_available(kind: String,quantity: int = 1) -> int:
    if not has_instance(kind):
        return 0
    return maxi(0,mini(clampi(quantity,1,25),bond_level_cap(kind)-unit_level(kind)))

func creature_level_price(kind: String,amount: int = 1) -> float:
    var actual: int = level_batch_available(kind,amount)
    if actual <= 0:
        return INF
    return super.creature_level_price(kind,actual)

func level_creature(kind: String,amount: int = 1) -> bool:
    var actual: int = level_batch_available(kind,amount)
    if actual <= 0:
        if has_instance(kind):
            _report("%s reached Bond Rank %d's level %d cap. Ascend after earning %d Bond XP to grow its ceiling." % [
                combat_name(kind),unit_bond_rank(kind),bond_level_cap(kind),next_bond_goal(kind)])
        return false
    var ok: bool = super.level_creature(kind,actual)
    if ok and unit_level(kind) == bond_level_cap(kind):
        _report("%s mastered this Bond Rank! General Gold upgrades remain available until your next Ascension." % combat_name(kind))
    return ok

func automate_purchase() -> void:
    # Unlike the legacy autobuyer, never attempt to purchase a capped level.
    # The lowest affordable general upgrade is considered before creature XP,
    # so saved Gold keeps improving the entire team beyond creature caps.
    var best: String = ""
    var cheapest: float = INF
    for key in modules:
        var cost: float = module_cost(String(key))
        if cost <= gold and cost < cheapest:
            cheapest = cost
            best = String(key)
    if best != "":
        buy_module(best)
        return
    for kind in owned_creatures:
        if not has_bond_training(String(kind)):
            continue
        var cost: float = creature_level_price(String(kind),1)
        if cost <= gold and cost < cheapest:
            cheapest = cost
            best = String(kind)
    if best != "":
        level_creature(best,1)

func ascend() -> bool:
    if available_echoes() < 1:
        return false
    var prepared: Dictionary = {}
    for key in owned_creatures:
        var kind: String = String(key)
        var rank: int = unit_bond_rank(kind)
        prepared[kind] = rank < MAX_BOND_RANK and unit_bond(kind) >= next_bond_goal(kind)
    var ok: bool = super.ascend()
    if not ok:
        return false
    var promoted: Array[String] = []
    for key in prepared:
        if bool(prepared[key]):
            bond_ranks[key] = unit_bond_rank(String(key))+1
            promoted.append(combat_name(String(key)))
    last_promotion = ", ".join(promoted)
    _report("ASCENSION %d: %d creatures advanced a Bond Rank. Level caps are permanent; Gold modules and creature levels reset." % [
        ascensions,promoted.size()])
    return true

func to_dict() -> Dictionary:
    var saved: Dictionary = super.to_dict()
    saved["v14_bond_ranks"] = bond_ranks.duplicate()
    saved["v14_last_promotion"] = last_promotion
    return saved

func load_save() -> bool:
    var loaded: bool = super.load_save()
    bond_ranks.clear()
    var file: FileAccess = FileAccess.open(SAVE_FILE,FileAccess.READ)
    if file != null:
        var data: Variant = JSON.parse_string(file.get_as_text())
        if data is Dictionary:
            var ranks: Dictionary = data.get("v14_bond_ranks",{})
            for kind in ranks:
                if has_instance(String(kind)):
                    bond_ranks[String(kind)] = clampi(int(ranks[kind]),1,MAX_BOND_RANK)
            last_promotion = String(data.get("v14_last_promotion",""))
    return loaded

func _ally_hit(index: int) -> void:
    if index >= 0 and index < ally_units.size() and float(ally_units[index]["hp"]) > 0.0 and not awaiting_next:
        ally_units[index]["action"] = 0.26
    super._ally_hit(index)

func _rival_hit(index: int) -> void:
    if index >= 0 and index < rival_units.size() and float(rival_units[index]["hp"]) > 0.0 and not awaiting_next:
        rival_units[index]["action"] = 0.26
    super._rival_hit(index)

func tick(delta: float) -> void:
    var dt: float = clampf(delta,0.0,0.25)
    for unit in ally_units:
        unit["action"] = maxf(0.0,float(unit.get("action",0.0))-dt)
    for unit in rival_units:
        unit["action"] = maxf(0.0,float(unit.get("action",0.0))-dt)
    super.tick(delta)
