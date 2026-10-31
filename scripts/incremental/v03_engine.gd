extends "res://scripts/incremental/alpha_engine.gd"
## Wildbound Alpha v0.3. Small persistent additions; fully compatible with v0.1/v0.2.
const STANCES: Array[String] = ["Balanced", "Feral", "Bulwark", "Forager"]
const CONTRACTS: Array[String] = ["battles", "guardians", "abilities"]
const CONTRACT_TITLES: Dictionary = {
    "battles":"Trailblazer", "guardians":"Guardian Hunter", "abilities":"Wild Arts"
}
const CONTRACT_DESCRIPTIONS: Dictionary = {
    "battles":"Win wild encounters", "guardians":"Defeat guardians", "abilities":"Activate creature abilities"
}
const CAMP_UPGRADES: Dictionary = {
    "nest":"Nest Expansion", "pack":"Pack Lodgings", "altar":"Echo Altar"
}
const CAMP_DESCRIPTIONS: Dictionary = {
    "nest":"+8% chance to find Nest Shards per rank",
    "pack":"+10% all creature damage per rank",
    "altar":"+8% Echoes from Ascensions per rank"
}
var stance: String = "Balanced"
var overdrive: float = 0.0
var overdrive_left: float = 0.0
var guardians_won: int = 0
var abilities_used: int = 0
var contracts_claimed: int = 0
var contract_stage: Dictionary = {"battles":0,"guardians":0,"abilities":0}
var contract_start: Dictionary = {"battles":0,"guardians":0,"abilities":0}
var camp: Dictionary = {"nest":0,"pack":0,"altar":0}
var all_time_taps: int = 0
var overdrive_used: int = 0
var _last_ability: String = ""
var _regen_overflow: float = 0.0

func set_stance(next: String) -> bool:
    if not STANCES.has(next):
        return false
    stance = next
    _report("Pack tactic: %s. %s" % [stance,stance_description()])
    return true

func stance_description() -> String:
    match stance:
        "Feral":
            return "Pack damage +30%; incoming damage +20%."
        "Bulwark":
            return "Pack damage -18%; incoming damage -35%, faster Ward renewal."
        "Forager":
            return "Pack damage -20%; Gold +40%, Nest drop bonus."
    return "Balanced attack, defense and expedition rewards."

func species_damage(kind: String) -> float:
    var result: float = super.species_damage(kind)
    var tactics: float = 1.30 if stance == "Feral" else (0.82 if stance == "Bulwark" else (0.80 if stance == "Forager" else 1.0))
    var crescendo: float = 2.0 if overdrive_left > 0.0 else 1.0
    return result * tactics * crescendo * pow(1.10,float(int(camp["pack"])))

func enemy_damage() -> float:
    var result: float = super.enemy_damage()
    if stance == "Feral":
        result *= 1.20
    elif stance == "Bulwark":
        result *= 0.65
    if enemy_mutator() == "Frenzied":
        result *= 1.55
    return result

func wave_reward() -> float:
    var result: float = super.wave_reward()
    if stance == "Forager":
        result *= 1.40
    if enemy_mutator() == "Gilded":
        result *= 1.85
    return result

func available_echoes() -> int:
    var initial: int = super.available_echoes()
    if initial < 1:
        return 0
    return maxi(1,int(ceil(float(initial)*pow(1.08,float(int(camp["altar"]))))))

func enemy_mutator() -> String:
    if enemy_is_boss():
        return "Guardian"
    if wave >= 15 and wave % 13 == 0:
        return "Gilded"
    if wave >= 12 and wave % 11 == 0:
        return "Frenzied"
    if wave >= 10 and wave % 7 == 0:
        return "Armored"
    return ""

func _fit_enemy_to_region() -> void:
    super._fit_enemy_to_region()
    if enemy_mutator() == "Armored":
        var ratio: float = clampf(enemy_hp/maxf(enemy_max_hp,1.0),0.0,1.0)
        enemy_max_hp *= 1.65
        enemy_hp = maxf(1.0,enemy_max_hp*ratio)

func _enemy_defeated() -> void:
    var boss: bool = enemy_is_boss()
    super._enemy_defeated()
    overdrive = minf(100.0,overdrive + (16.0 if boss else 3.0))
    if boss:
        guardians_won += 1
    # Permanent camp improves only earned shard probability.
    var extra_chance: float = 0.08*float(int(camp["nest"])) + (0.17 if stance == "Forager" else 0.0)
    if not boss and _rng.randf() < minf(0.75,extra_chance):
        nests += 1

func tap() -> void:
    all_time_taps += 1
    overdrive = minf(100.0,overdrive+0.7)
    super.tap()

func use_ability(kind: String) -> bool:
    var result: bool = super.use_ability(kind)
    if result:
        abilities_used += 1
        _last_ability = kind
    return result

func activate_overdrive() -> bool:
    if overdrive < 99.99 or overdrive_left > 0.0:
        return false
    overdrive = 0.0
    overdrive_left = 12.0
    overdrive_used += 1
    _report("WILD RESONANCE! Pack damage doubles for 12 seconds.")
    return true

func tick(delta: float) -> void:
    var duration: float = clampf(delta,0.0,0.25)*game_speed
    overdrive_left = maxf(0.0,overdrive_left-duration)
    super.tick(delta)
    # Slow extra regeneration is meaningful without replacing Sanctuary mechanics.
    if stance == "Bulwark":
        _regen_overflow += duration
        if _regen_overflow >= 0.25:
            ward = minf(max_ward(),ward+max_ward()*0.004*(_regen_overflow/0.25))
            _regen_overflow = 0.0

func contract_target(key: String) -> int:
    var stage: int = maxi(0,int(contract_stage.get(key,0)))
    match key:
        "battles":
            return 12 + stage*8
        "guardians":
            return 1 + stage/3
        "abilities":
            return 4 + stage*2
    return 1

func contract_count(key: String) -> int:
    match key:
        "battles":
            return kills
        "guardians":
            return guardians_won
        "abilities":
            return abilities_used
    return 0

func contract_progress(key: String) -> int:
    return maxi(0,contract_count(key)-int(contract_start.get(key,0)))

func contract_ready(key: String) -> bool:
    return CONTRACTS.has(key) and contract_progress(key) >= contract_target(key)

func contract_rewards(key: String) -> Dictionary:
    var level: int = int(contract_stage.get(key,0))
    var earned_gold: float = 75.0 * pow(1.37,float(level)) * (1.25 if key == "guardians" else 1.0)
    var shards: int = 2+level/3
    var echoes: int = 1 if level >= 2 and key == "guardians" else 0
    return {"gold":earned_gold,"shards":shards,"echoes":echoes}

func claim_contract(key: String) -> bool:
    if not contract_ready(key):
        return false
    var bonus: Dictionary = contract_rewards(key)
    gold += float(bonus["gold"])
    nests += int(bonus["shards"])
    echoes += int(bonus["echoes"])
    lifetime_gold += float(bonus["gold"])
    lifetime_echoes += int(bonus["echoes"])
    contracts_claimed += 1
    contract_stage[key] = int(contract_stage[key])+1
    contract_start[key] = contract_count(key)
    _report("%s complete! +%s Gold, +%d Nest Shards." % [
        CONTRACT_TITLES[key],format_number(float(bonus["gold"])),int(bonus["shards"])])
    return true

func camp_cost(key: String) -> int:
    if not CAMP_UPGRADES.has(key):
        return 999999
    return 9 + int(camp[key])*7

func buy_camp_upgrade(key: String) -> bool:
    var cost: int = camp_cost(key)
    if not CAMP_UPGRADES.has(key) or nests < cost:
        return false
    nests -= cost
    camp[key] = int(camp[key])+1
    _report("%s upgraded to rank %d. The upgrade survives Ascension." % [
        CAMP_UPGRADES[key],int(camp[key])])
    return true

func to_dict() -> Dictionary:
    var result: Dictionary = super.to_dict()
    result["v03"] = 3
    result["stance"] = stance
    result["overdrive"] = overdrive
    result["guardians_won"] = guardians_won
    result["abilities_used"] = abilities_used
    result["contracts_claimed"] = contracts_claimed
    result["contract_stage"] = contract_stage.duplicate()
    result["contract_start"] = contract_start.duplicate()
    result["camp"] = camp.duplicate()
    result["all_time_taps"] = all_time_taps
    result["overdrive_used"] = overdrive_used
    return result

func load_save() -> bool:
    if not super.load_save():
        return false
    var file: FileAccess = FileAccess.open(SAVE_FILE,FileAccess.READ)
    if file == null:
        return true
    var value: Variant = JSON.parse_string(file.get_as_text())
    if not (value is Dictionary):
        return true
    var data: Dictionary = value
    var loaded_stance: String = String(data.get("stance","Balanced"))
    stance = loaded_stance if STANCES.has(loaded_stance) else "Balanced"
    overdrive = clampf(float(data.get("overdrive",0.0)),0.0,100.0)
    guardians_won = maxi(0,int(data.get("guardians_won",0)))
    abilities_used = maxi(0,int(data.get("abilities_used",0)))
    contracts_claimed = maxi(0,int(data.get("contracts_claimed",0)))
    var stages: Dictionary = data.get("contract_stage",{})
    var starts: Dictionary = data.get("contract_start",{})
    for key in CONTRACTS:
        contract_stage[key] = maxi(0,int(stages.get(key,0)))
        # A v0.2 save begins with no unearned legacy progress on contracts.
        var fallback: int = contract_count(key) if not data.has("v03") else 0
        contract_start[key] = clampi(int(starts.get(key,fallback)),0,contract_count(key))
    var buildings: Dictionary = data.get("camp",{})
    for key in CAMP_UPGRADES:
        camp[key] = maxi(0,int(buildings.get(key,0)))
    all_time_taps = maxi(0,int(data.get("all_time_taps",0)))
    overdrive_used = maxi(0,int(data.get("overdrive_used",0)))
    # Overdrive's active timer is deliberately not persisted to prevent reload abuse.
    overdrive_left = 0.0
    return true
