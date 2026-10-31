extends "res://scripts/incremental/engine.gd"
## Wildbound Alpha: permanent collection, rare variants, field builds, ascension
## research, active creature abilities, regions, milestones and automation.
## Extends v0.1 rather than replacing the existing save contract.

const REGIONS: Dictionary = {
    "meadow":{"name":"Verdant Meadow","unlock":1,"hp":1.0,"damage":1.0,"gold":1.0,"tint":"#23443e","element":"Grove"},
    "shore":{"name":"Moonlit Shore","unlock":30,"hp":1.6,"damage":1.3,"gold":1.7,"tint":"#18455d","element":"Tide"},
    "embers":{"name":"Ember Hollow","unlock":65,"hp":2.5,"damage":1.6,"gold":2.8,"tint":"#653e39","element":"Ember"},
    "sky":{"name":"Skyglass Peaks","unlock":120,"hp":4.0,"damage":2.0,"gold":5.0,"tint":"#45517c","element":"Grove"}
}
const REGION_ORDER: Array[String] = ["meadow","shore","embers","sky"]
const EXTRA_MODULES: Array[String] = ["crit","bounty","recovery","pierce"]
const MODULE_NAMES: Dictionary = {
    "power":"Might Matrix","guard":"Bulwark","tempo":"Haste Clock",
    "crit":"Critical Lens","bounty":"Golden Roots",
    "recovery":"Renewal Moss","pierce":"Bossbreaker"
}
const EXTRA_RESEARCH: Array[String] = ["bounty","speed","scavenge","incubator","automation","instinct"]
const RESEARCH_NAMES: Dictionary = {
    "might":"Pack Might","heart":"Living Ward","bounty":"Golden Fortune",
    "speed":"Perpetual Motion","scavenge":"Nest Foraging",
    "incubator":"Rare Heritage","automation":"Autonomous Workshop",
    "instinct":"Wild Instinct"
}
const MILESTONES: Dictionary = {
    "wave10":{"title":"First Guardian","desc":"Reach wave 10","type":"wave","goal":10,"echoes":1,"shards":3},
    "wave30":{"title":"Beyond the Meadow","desc":"Reach wave 30","type":"wave","goal":30,"echoes":2,"shards":4},
    "wave60":{"title":"The Deep Wilds","desc":"Reach wave 60","type":"wave","goal":60,"echoes":4,"shards":6},
    "wave100":{"title":"Century of Strength","desc":"Reach wave 100","type":"wave","goal":100,"echoes":8,"shards":8},
    "kills50":{"title":"Seasoned Pack","desc":"Win 50 battles","type":"kills","goal":50,"echoes":1,"shards":4},
    "kills250":{"title":"Relentless","desc":"Win 250 battles","type":"kills","goal":250,"echoes":3,"shards":6},
    "eggs3":{"title":"Nest Keeper","desc":"Hatch 3 eggs","type":"eggs","goal":3,"echoes":2,"shards":2},
    "eggs12":{"title":"Master Breeder","desc":"Hatch 12 eggs","type":"eggs","goal":12,"echoes":5,"shards":5},
    "ascend1":{"title":"Circle Renewed","desc":"Ascend once","type":"ascend","goal":1,"echoes":1,"shards":2},
    "ascend5":{"title":"Eternal Wilds","desc":"Ascend 5 times","type":"ascend","goal":5,"echoes":6,"shards":10},
    "evolve1":{"title":"True Potential","desc":"Evolve 1 creature","type":"evolve","goal":1,"echoes":2,"shards":3},
    "relic1":{"title":"The First Relic","desc":"Find 1 Relic","type":"relic","goal":1,"echoes":1,"shards":2},
    "relic5":{"title":"Relic Hunter","desc":"Find 5 Relics","type":"relic","goal":5,"echoes":3,"shards":5},
    "evolve3":{"title":"Perfect Pack","desc":"Evolve all 3 creatures","type":"evolve","goal":3,"echoes":5,"shards":8}
}
const MILESTONE_ORDER: Array[String] = [
    "wave10","relic1","kills50","evolve1","ascend1","eggs3","wave30",
    "kills250","wave60","eggs12","relic5","ascend5","evolve3","wave100"
]
const ABILITY_NAMES: Dictionary = {"spriglet":"Verdant Bloom","brinlet":"Tidal Surge","cindlet":"Ember Frenzy"}
const RELICS: Dictionary = {
    "oak":{"name":"Elderwood Charm","description":"+20% Grove damage per rank"},
    "pearl":{"name":"Tideglass Pearl","description":"+20% Tide damage per rank"},
    "ember":{"name":"Cinderheart Talisman","description":"+20% Ember damage per rank"},
    "sigil":{"name":"Guardian Sigil","description":"+25% boss damage per rank"},
    "coin":{"name":"Coinroot Amulet","description":"+12% Gold earned per rank"},
    "hearth":{"name":"Hearthstone","description":"+18% ward capacity per rank"}
}
const RELIC_ORDER: Array[String] = ["oak","pearl","ember","sigil","coin","hearth"]

var relic_ranks: Dictionary = {"oak":0,"pearl":0,"ember":0,"sigil":0,"coin":0,"hearth":0}
var equipped_relics: Array[String] = []
var relic_drops: int = 0
var nests: int = 0
var eggs_hatched: int = 0
var gene: Dictionary = {"spriglet":0,"brinlet":0,"cindlet":0}
var rare: Dictionary = {"spriglet":false,"brinlet":false,"cindlet":false}
var rare_pity: int = 0
var milestones_claimed: Dictionary = {}
var region: String = "meadow"
var overclock: bool = false
var auto_buy: bool = false
var auto_skills: bool = false
var ability_clock: Dictionary = {"spriglet":0.0,"brinlet":0.0,"cindlet":0.0}
var frenzy_left: float = 0.0
var _automation_clock: float = 0.0
var _regen_clock: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var damage_flash: float = 0.0
var recent_hit: float = 0.0
var recent_critical: bool = false
var offline_gold: float = 0.0
var lifetime_gold: float = 0.0
var lifetime_echoes: int = 0
var last_boss_wave: int = 0
var current_streak: int = 0
var greatest_streak: int = 0
var battle_seconds: float = 0.0
var total_seconds: float = 0.0
var game_speed: float = 1.0

func initialize_alpha() -> void:
    _rng.randomize()
    for key in EXTRA_MODULES:
        if not modules.has(key):
            modules[key] = 0
    for key in EXTRA_RESEARCH:
        if not research.has(key):
            research[key] = 0
    _fit_enemy_to_region()
    ward = minf(ward,max_ward())

func _region_data() -> Dictionary:
    return REGIONS.get(region,REGIONS["meadow"])

func _fit_enemy_to_region() -> void:
    var hp_fraction: float = clampf(enemy_hp / maxf(enemy_max_hp,1.0),0.0,1.0)
    var factor: float = float(_region_data()["hp"]) * (2.0 if overclock else 1.0)
    # Avoid repeated multiplication when switching regions mid-battle.
    var vanilla: float = 18.0 * pow(1.185,float(wave-1)) * (4.0 if enemy_is_boss() else 1.0)
    enemy_max_hp = vanilla * factor
    enemy_hp = maxf(1.0,enemy_max_hp * hp_fraction)
    var regional: String = String(_region_data()["element"])
    var index: int = (wave - 1) % 3
    if region != "meadow" and wave % 4 != 0:
        for species in ORDER:
            if String(SPECIES[species]["element"]) == regional:
                enemy_species = species
                break
    else:
        enemy_species = ORDER[index]

func region_available(key: String) -> bool:
    return REGIONS.has(key) and best_wave >= int(REGIONS[key]["unlock"])

func select_region(key: String) -> bool:
    if not region_available(key):
        return false
    if key == region:
        return true
    region = key
    _fit_enemy_to_region()
    _report("Expedition launched: %s." % String(REGIONS[key]["name"]))
    return true

func toggle_overclock() -> void:
    overclock = not overclock
    _fit_enemy_to_region()
    _report("Overclock %s: tougher foes, greater rewards." % ("ON" if overclock else "OFF"))

func species_damage(kind: String) -> float:
    var base: float = super.species_damage(kind)
    if base <= 0.0:
        return 0.0
    var heredity: float = pow(1.065,float(int(gene.get(kind,0))))
    var shimmer: float = 1.22 if bool(rare.get(kind,false)) else 1.0
    var lineage_relic: Dictionary = {"spriglet":"oak","brinlet":"pearl","cindlet":"ember"}
    var relic_key: String = String(lineage_relic[kind])
    var relic_power: float = pow(1.20,float(int(relic_ranks[relic_key]))) if equipped_relics.has(relic_key) else 1.0
    var haste: float = pow(1.08,float(int(research.get("speed",0))))
    var frenzy: float = 1.85 if frenzy_left > 0.0 else 1.0
    return base * heredity * shimmer * haste * frenzy * relic_power

func attack_interval(kind: String) -> float:
    return maxf(0.15,super.attack_interval(kind)*pow(0.97,float(int(research.get("speed",0)))))

func effective_damage(kind: String) -> float:
    var raw: float = super.effective_damage(kind)
    if raw <= 0.0:
        return 0.0
    if enemy_is_boss():
        raw *= 1.0+0.20*float(int(modules.get("pierce",0)))
        if equipped_relics.has("sigil"):
            raw *= pow(1.25,float(int(relic_ranks["sigil"])))
    var chance: float = minf(0.70,0.05+float(int(modules.get("crit",0)))*0.035)
    recent_critical = _rng.randf() < chance
    if recent_critical:
        raw *= 2.5
    recent_hit = raw
    damage_flash = 0.16
    return raw

func max_ward() -> float:
    var relic_ward: float = pow(1.18,float(int(relic_ranks["hearth"]))) if equipped_relics.has("hearth") else 1.0
    return super.max_ward() * (1.0 + float(int(research.get("incubator",0))) * 0.04) * relic_ward

func enemy_damage() -> float:
    return super.enemy_damage() * float(_region_data()["damage"]) * (1.65 if overclock else 1.0)

func wave_reward() -> float:
    var relic_gold: float = pow(1.12,float(int(relic_ranks["coin"]))) if equipped_relics.has("coin") else 1.0
    return super.wave_reward() * float(_region_data()["gold"]) * relic_gold \
        * (2.4 if overclock else 1.0) \
        * pow(1.15,float(int(modules.get("bounty",0)))) \
        * pow(1.12,float(int(research.get("bounty",0))))

func module_cost(kind: String) -> float:
    if EXTRA_MODULES.has(kind):
        var prices: Dictionary = {"crit":140.0,"bounty":90.0,"recovery":110.0,"pierce":180.0}
        return ceil(float(prices[kind])*pow(1.56,float(int(modules.get(kind,0)))))
    return super.module_cost(kind)

func buy_module(kind: String) -> bool:
    var price: float = module_cost(kind)
    if not modules.has(kind) or gold < price:
        return false
    gold -= price
    modules[kind] = int(modules[kind])+1
    if kind == "guard":
        ward = minf(max_ward(),ward+30.0)
    return true

func _enemy_defeated() -> void:
    var defeated_wave: int = wave
    var was_boss: bool = enemy_is_boss()
    var paid: float = wave_reward()
    super._enemy_defeated()
    lifetime_gold += paid
    current_streak += 1
    greatest_streak = maxi(greatest_streak,current_streak)
    if was_boss:
        # First guardian guarantees a Relic; later drops are generous.
        if relic_drops == 0 or _rng.randf() < minf(0.80,0.35 + float(int(research.get("scavenge",0)))*0.035):
            var relic_key: String = RELIC_ORDER[_rng.randi_range(0,RELIC_ORDER.size()-1)]
            relic_ranks[relic_key] = int(relic_ranks[relic_key])+1
            relic_drops += 1
        last_boss_wave = maxi(last_boss_wave,defeated_wave)
        nests += 3 + int(research.get("scavenge",0))
        ward = minf(max_ward(),ward+max_ward()*0.12)
        _report("Guardian cleared! +%d Nest Shards. Wave %d defeated." % [3+int(research.get("scavenge",0)),defeated_wave])
    elif _rng.randf() < 0.055 + 0.018*float(int(research.get("scavenge",0))):
        nests += 1
    _fit_enemy_to_region()

func _regroup() -> void:
    current_streak = 0
    super._regroup()
    _fit_enemy_to_region()

func tick(delta: float) -> void:
    # Real-time simulation, deliberately capped to avoid tab-throttle exploits.
    var duration: float = clampf(delta,0.0,0.25) * game_speed
    total_seconds += duration
    battle_seconds += duration
    if frenzy_left > 0.0:
        frenzy_left = maxf(0.0,frenzy_left-duration)
    damage_flash = maxf(0.0,damage_flash-duration)
    for kind in ORDER:
        ability_clock[kind] = maxf(0.0,float(ability_clock[kind])-duration)
    _regen_clock += duration
    if _regen_clock >= 0.25:
        var segments: int = mini(10,int(_regen_clock/0.25))
        _regen_clock -= float(segments)*0.25
        var healing: float = max_ward() * 0.0025 * (1.0 + float(int(modules.get("recovery",0)))*0.7)
        ward = minf(max_ward(),ward + healing*float(segments))
    super.tick(duration)
    _automation_clock += duration
    if _automation_clock >= 1.0:
        _automation_clock = 0.0
        if auto_skills and int(research.get("instinct",0)) > 0:
            if ward < max_ward()*0.70:
                use_ability("spriglet")
            if enemy_is_boss():
                use_ability("brinlet")
            use_ability("cindlet")
        if auto_buy and int(research.get("automation",0)) > 0:
            automate_purchase()

func automate_purchase() -> void:
    # Spend on the cheapest currently-owned creature or field improvement.
    # Never spends Echoes or shards, never Ascends automatically.
    var best_kind: String = ""
    var best_price: float = INF
    var best_module: bool = false
    for kind in ORDER:
        if int(levels[kind]) < 1:
            continue
        var cost: float = level_cost(kind)
        if cost <= gold and cost < best_price:
            best_price = cost
            best_kind = kind
            best_module = false
    for key in MODULES + EXTRA_MODULES:
        var cost: float = module_cost(key)
        if cost <= gold and cost < best_price:
            best_price = cost
            best_kind = key
            best_module = true
    if best_kind != "":
        if best_module:
            buy_module(best_kind)
        else:
            buy_levels(best_kind,1)

func ability_cooldown(kind: String) -> float:
    if kind == "spriglet":
        return 25.0
    if kind == "brinlet":
        return 19.0
    return 38.0

func use_ability(kind: String) -> bool:
    if not SPECIES.has(kind) or int(levels[kind]) < 1 or float(ability_clock[kind]) > 0.0:
        return false
    ability_clock[kind] = ability_cooldown(kind)
    if kind == "spriglet":
        var healed: float = max_ward()*0.42
        ward = minf(max_ward(),ward+healed)
        _report("%s: sanctuary restored!" % ABILITY_NAMES[kind])
    elif kind == "brinlet":
        var burst: float = maxf(10.0,total_dps()*6.0)
        attack(burst)
        _report("%s hits for %s!" % [ABILITY_NAMES[kind],format_number(burst)])
    else:
        frenzy_left = 12.0
        _report("%s! Pack damage increases for 12 seconds." % ABILITY_NAMES[kind])
    return true

func equip_relic(key: String) -> bool:
    if not RELICS.has(key) or int(relic_ranks.get(key,0)) < 1:
        return false
    if equipped_relics.has(key):
        equipped_relics.erase(key)
        _report("%s unequipped." % String(RELICS[key]["name"]))
        return true
    if equipped_relics.size() >= 2:
        _report("Relic slots are full. Unequip one first.")
        return false
    equipped_relics.append(key)
    ward = minf(max_ward(),ward)
    _report("%s equipped! Its permanent bonus is active." % String(RELICS[key]["name"]))
    return true

func hatch_cost() -> int:
    return 5

func hatch_egg() -> String:
    if nests < hatch_cost():
        return ""
    nests -= hatch_cost()
    eggs_hatched += 1
    var kind: String = ORDER[_rng.randi_range(0,ORDER.size()-1)]
    var was_owned: bool = int(levels[kind]) > 0
    if was_owned:
        gene[kind] = int(gene[kind])+1
    else:
        levels[kind] = 1
    var rare_chance: float = 0.08 + 0.025 * float(int(research.get("incubator",0)))
    var rare_hatch: bool = rare_pity >= 9 or _rng.randf() < minf(0.50,rare_chance)
    if rare_hatch:
        rare[kind] = true
        rare_pity = 0
    else:
        rare_pity += 1
    var text: String = "%s hatched%s! %s" % [
        String(SPECIES[kind]["name"]), " (Shimmer)" if rare_hatch else "",
        "+1 gene resonance" if was_owned else "A new teammate joined"]
    _report(text)
    return kind

func research_cost(kind: String) -> int:
    if EXTRA_RESEARCH.has(kind):
        var rank: int = int(research.get(kind,0))
        var minimum: int = 3 if kind == "automation" or kind == "instinct" else 1
        return minimum + rank * (3 if kind == "automation" or kind == "instinct" else 2)
    return super.research_cost(kind)

func buy_research(kind: String) -> bool:
    if not research.has(kind):
        return false
    var price: int = research_cost(kind)
    if echoes < price:
        return false
    echoes -= price
    research[kind] = int(research[kind])+1
    if kind == "heart":
        ward = minf(max_ward(),ward+max_ward()*0.18)
    _report("%s research upgraded to rank %d." % [RESEARCH_NAMES.get(kind,kind),int(research[kind])])
    return true

func available_echoes() -> int:
    var original: int = super.available_echoes()
    if original <= 0:
        return 0
    return maxi(1,int(ceil(float(original)*(1.0 + 0.10*float(int(research.get("scavenge",0)))))))

func ascend() -> bool:
    var earned: int = available_echoes()
    if earned < 1:
        return false
    lifetime_echoes += earned
    var result: bool = super.ascend()
    for kind in EXTRA_MODULES:
        modules[kind] = 0
    frenzy_left = 0.0
    current_streak = 0
    for kind in ORDER:
        ability_clock[kind] = 0.0
    _fit_enemy_to_region()
    if result:
        _report("ASCENSION %d • +%d Echoes! Your creatures and genes endure." % [ascensions,earned])
    return result

func milestone_progress(key: String) -> int:
    if not MILESTONES.has(key):
        return 0
    match String(MILESTONES[key]["type"]):
        "wave":
            return best_wave
        "kills":
            return kills
        "eggs":
            return eggs_hatched
        "relic":
            return relic_drops
        "ascend":
            return ascensions
        "evolve":
            var n: int = 0
            for kind in ORDER:
                if bool(evolved[kind]):
                    n += 1
            return n
    return 0

func claim_milestone(key: String) -> bool:
    if not MILESTONES.has(key) or milestones_claimed.has(key):
        return false
    if milestone_progress(key) < int(MILESTONES[key]["goal"]):
        return false
    milestones_claimed[key] = true
    var reward: Dictionary = MILESTONES[key]
    echoes += int(reward["echoes"])
    nests += int(reward["shards"])
    lifetime_echoes += int(reward["echoes"])
    _report("Milestone: %s! +%d Echoes, +%d shards." % [String(reward["title"]),int(reward["echoes"]),int(reward["shards"])])
    return true

func format_number(value: float) -> String:
    if is_nan(value):
        return "0"
    if is_inf(value):
        return "MAX"
    if absf(value) < 1000.0:
        return "%.0f" % value
    var units: Array[String] = ["K","M","B","T","Qa","Qi","Sx","Sp","Oc","No","Dc"]
    var n: float = value
    var i: int = -1
    while absf(n) >= 1000.0 and i < units.size()-1:
        n /= 1000.0
        i += 1
    if absf(n) >= 1000.0:
        return "%.2e" % value
    return "%.2f%s" % [n,units[i]]

func to_dict() -> Dictionary:
    var result: Dictionary = super.to_dict()
    result["alpha_save_version"] = 2
    result["relic_ranks"] = relic_ranks.duplicate(true)
    result["equipped_relics"] = equipped_relics.duplicate()
    result["relic_drops"] = relic_drops
    result["nests"] = nests
    result["eggs_hatched"] = eggs_hatched
    result["gene"] = gene.duplicate(true)
    result["rare"] = rare.duplicate(true)
    result["rare_pity"] = rare_pity
    result["milestones_claimed"] = milestones_claimed.duplicate()
    result["region"] = region
    result["overclock"] = overclock
    result["auto_buy"] = auto_buy
    result["auto_skills"] = auto_skills
    result["lifetime_gold"] = lifetime_gold
    result["lifetime_echoes"] = lifetime_echoes
    result["greatest_streak"] = greatest_streak
    result["last_boss_wave"] = last_boss_wave
    result["total_seconds"] = total_seconds
    result["game_speed"] = game_speed
    return result

func load_save() -> bool:
    var original: bool = super.load_save()
    if not original:
        return false
    var file: FileAccess = FileAccess.open(SAVE_FILE,FileAccess.READ)
    if file == null:
        return true
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary):
        return true
    var data: Dictionary = parsed
    # Parent v0.1 loader restores only its original three modules and two
    # research tracks. Restore expanded alpha keys explicitly before reading
    # automation toggles, or their unlocks would silently disappear on reload.
    var persisted_modules: Dictionary = data.get("modules",{})
    var persisted_research: Dictionary = data.get("research",{})
    for extra in EXTRA_MODULES:
        modules[extra] = maxi(0,int(persisted_modules.get(extra,0)))
    for extra in EXTRA_RESEARCH:
        research[extra] = maxi(0,int(persisted_research.get(extra,0)))
    var saved_relics: Dictionary = data.get("relic_ranks",{})
    for relic in RELIC_ORDER:
        relic_ranks[relic] = maxi(0,int(saved_relics.get(relic,0)))
    var loadout: Array = data.get("equipped_relics",[])
    equipped_relics.clear()
    for entry in loadout:
        var relic_key: String = String(entry)
        if RELICS.has(relic_key) and int(relic_ranks[relic_key]) > 0 and not equipped_relics.has(relic_key) and equipped_relics.size() < 2:
            equipped_relics.append(relic_key)
    relic_drops = maxi(0,int(data.get("relic_drops",0)))
    nests = maxi(0,int(data.get("nests",0)))
    eggs_hatched = maxi(0,int(data.get("eggs_hatched",0)))
    rare_pity = clampi(int(data.get("rare_pity",0)),0,9)
    for kind in ORDER:
        var gd: Dictionary = data.get("gene",{})
        var rd: Dictionary = data.get("rare",{})
        gene[kind] = maxi(0,int(gd.get(kind,0)))
        rare[kind] = bool(rd.get(kind,false))
    var claimed: Variant = data.get("milestones_claimed",{})
    if claimed is Dictionary:
        for key in MILESTONE_ORDER:
            if claimed.has(key) and bool(claimed[key]):
                milestones_claimed[key] = true
    var saved_region: String = String(data.get("region","meadow"))
    region = saved_region if region_available(saved_region) else "meadow"
    overclock = bool(data.get("overclock",false))
    auto_buy = bool(data.get("auto_buy",false)) and int(research.get("automation",0)) > 0
    auto_skills = bool(data.get("auto_skills",false)) and int(research.get("instinct",0)) > 0
    lifetime_gold = maxf(0.0,float(data.get("lifetime_gold",0.0)))
    lifetime_echoes = maxi(0,int(data.get("lifetime_echoes",0)))
    greatest_streak = maxi(0,int(data.get("greatest_streak",0)))
    last_boss_wave = maxi(0,int(data.get("last_boss_wave",0)))
    total_seconds = maxf(0.0,float(data.get("total_seconds",0.0)))
    game_speed = clampf(float(data.get("game_speed",1.0)),1.0,2.0)
    _fit_enemy_to_region()
    # Offline gold is capped. No phantom kills/waves, no offline premium currency.
    var time_away: float = clampf(float(Time.get_unix_time_from_system()) - float(data.get("saved_at",0.0)),0.0,14400.0)
    if time_away >= 30.0:
        offline_gold = minf(1.0e18,wave_reward()*(time_away/5.0)*0.20)
        gold += offline_gold
        lifetime_gold += offline_gold
        _report("Welcome back! Your pack gathered %s Gold offline." % format_number(offline_gold))
    return true
