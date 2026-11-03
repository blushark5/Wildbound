extends "res://scripts/incremental/squad_engine_v11.gd"
## v0.12: owned individuals, slow earned hatching, distinct 4-element roster.
## The parent v0.11 battle system still runs every attack and target decision.

const CATALOG: Dictionary = {
    "spriglet":{"name":"Spriglet","evolved":"Thornhart","element":"Earth","base":3.8,"interval":0.85,"hp":1.06,"ability":"ROOTGUARD"},
    "pebblit":{"name":"Pebblit","evolved":"Granithorn","element":"Earth","base":5.2,"interval":1.20,"hp":1.35,"ability":"ROOTGUARD"},
    "mossling":{"name":"Mossling","evolved":"Fernwold","element":"Earth","base":2.8,"interval":0.67,"hp":0.98,"ability":"ROOTGUARD"},
    "brinlet":{"name":"Brinlet","evolved":"Tidemare","element":"Water","base":3.2,"interval":0.70,"hp":0.96,"ability":"SURGE"},
    "driplet":{"name":"Driplet","evolved":"Cascadia","element":"Water","base":3.9,"interval":0.82,"hp":1.02,"ability":"SURGE"},
    "tidefin":{"name":"Tidefin","evolved":"Deepcrest","element":"Water","base":4.9,"interval":1.13,"hp":1.16,"ability":"SURGE"},
    "cindlet":{"name":"Cindlet","evolved":"Blazetail","element":"Fire","base":5.7,"interval":1.10,"hp":0.90,"ability":"BLAZE"},
    "ashcub":{"name":"Ashcub","evolved":"Cindermane","element":"Fire","base":4.5,"interval":0.93,"hp":1.03,"ability":"BLAZE"},
    "emberlyn":{"name":"Emberlyn","evolved":"Solvulp","element":"Fire","base":3.6,"interval":0.68,"hp":0.86,"ability":"BLAZE"},
    "zephlet":{"name":"Zephlet","evolved":"Tempestral","element":"Air","base":3.6,"interval":0.62,"hp":0.79,"ability":"GALE"},
    "gustling":{"name":"Gustling","evolved":"Siroccan","element":"Air","base":4.7,"interval":0.95,"hp":1.06,"ability":"GALE"},
    "skyray":{"name":"Skyray","evolved":"Cloudmantle","element":"Air","base":5.2,"interval":1.14,"hp":1.14,"ability":"GALE"}
}
const COLLECTION_ORDER: Array[String] = [
    "spriglet","pebblit","mossling",
    "brinlet","driplet","tidefin",
    "cindlet","ashcub","emberlyn",
    "zephlet","gustling","skyray"
]
const ELEMENTS: Array[String] = ["Earth","Water","Fire","Air"]
const ELEMENT_BEATS: Dictionary = {"Earth":"Water","Water":"Fire","Fire":"Air","Air":"Earth"}
const COLLECTION_TRAIL: Array = [
    {"name":"The First Bond","hint":"Win five trainer battles. Earn Essence to discover a second unique creature.","kind":"kills","target":5,"gold":70.0,"shards":0,"echoes":0},
    {"name":"Your First Hatch","hint":"Open COLLECT and spend 5 Essence to hatch your first Fire creature.","kind":"collection","target":2,"gold":120.0,"shards":1,"echoes":0},
    {"name":"Defy the Wind","hint":"Defeat trainer stage 6. Fire creatures counter Air.","kind":"wave","target":7,"gold":180.0,"shards":1,"echoes":0},
    {"name":"A Real Team","hint":"Hatch your third unique creature. No species can fill two active slots.","kind":"collection","target":3,"gold":225.0,"shards":2,"echoes":0},
    {"name":"Three Against Three","hint":"Fill all three squad slots with different creatures.","kind":"squad","target":3,"gold":275.0,"shards":2,"echoes":0},
    {"name":"Defeat the Guardian","hint":"Win a Guardian trainer encounter at stage 10.","kind":"guardian","target":10,"gold":350.0,"shards":3,"echoes":0},
    {"name":"Raise Your Partner","hint":"Level Spriglet to 15 or evolve any creature at level 15 and 25 Bonds.","kind":"level","target":15,"gold":600.0,"shards":3,"echoes":0},
    {"name":"The Fourth Element","hint":"Hatch an Air creature to complete the four-element circle.","kind":"air","target":1,"gold":750.0,"shards":4,"echoes":1},
    {"name":"The Long Road","hint":"Reach stage 20 to earn your first Ascension.","kind":"wave","target":20,"gold":800.0,"shards":4,"echoes":2},
    {"name":"Renew the Wild","hint":"Ascend once. Creatures, traits, Genes and evolutions remain yours.","kind":"ascend","target":1,"gold":1000.0,"shards":5,"echoes":3}
]

var owned_creatures: Dictionary = {}
var essence: int = 0
var creature_serial: int = 0
var new_hatches: int = 0
var unlock_clock: Dictionary = {}
var last_hatch_kind: String = ""
var collecting_notice: String = "Earn Essence by winning trainer battles."

func _new_record(kind: String,seed: int = 0) -> Dictionary:
    var traits: Array[String] = ["Bold","Swift","Stout","Keen"]
    var variant: int = (seed % 4) if seed > 0 else _rng.randi_range(0,3)
    return {"id":maxi(1,seed),"level":1,"bond":0,"gene":0,"evolved":false,
        "trait":traits[variant],"power":1.12 if variant == 0 else 1.0,
        "speed":1.13 if variant == 1 else 1.0,
        "vigor":1.18 if variant == 2 else 1.0,
        "focus":1.11 if variant == 3 else 1.0}

func _ensure_starter() -> void:
    if not owned_creatures.has("spriglet"):
        creature_serial = maxi(creature_serial,1)
        owned_creatures["spriglet"] = _new_record("spriglet",1)
    if squad_slots.size() != SQUAD_SIZE:
        squad_slots.assign(["spriglet","",""])

func collection_count() -> int:
    return owned_creatures.size()

func has_instance(kind: String) -> bool:
    return owned_creatures.has(kind)

func unit_level(kind: String) -> int:
    return int(owned_creatures.get(kind,{}).get("level",0))

func unit_record(kind: String) -> Dictionary:
    return owned_creatures.get(kind,{})

func unit_gene(kind: String) -> int:
    return int(unit_record(kind).get("gene",0))

func unit_bond(kind: String) -> int:
    return int(unit_record(kind).get("bond",0))

func unit_evolved(kind: String) -> bool:
    return bool(unit_record(kind).get("evolved",false))

func unit_trait(kind: String) -> String:
    return String(unit_record(kind).get("trait","Wild"))

func combat_meta(kind: String) -> Dictionary:
    return CATALOG.get(kind,{})

func combat_owned(kind: String) -> bool:
    return has_instance(kind)

func combat_name(kind: String) -> String:
    if not CATALOG.has(kind):
        return "Unassigned"
    return String(CATALOG[kind]["evolved"] if unit_evolved(kind) else CATALOG[kind]["name"])

func combat_interval(kind: String) -> float:
    if not CATALOG.has(kind):
        return 1.0
    var speed: float = float(unit_record(kind).get("speed",1.0))
    return maxf(0.16,float(CATALOG[kind]["interval"])*pow(0.94,float(int(modules["tempo"])))/speed)

func combat_enemy_interval(kind: String) -> float:
    return float(CATALOG.get(kind,{}).get("interval",1.0))

func combat_damage(kind: String) -> float:
    if not has_instance(kind):
        return 0.0
    var item: Dictionary = unit_record(kind)
    var base: float = float(CATALOG[kind]["base"])
    var heredity: float = pow(1.065,float(int(item["gene"])))
    var evolved_gain: float = 2.8 if bool(item["evolved"]) else 1.0
    var rare_gain: float = 1.22 if bool(rare.get(kind,false)) else 1.0
    var build: float = pow(1.13,float(int(modules["power"])))
    var research_gain: float = pow(1.22,float(int(research["might"])))
    var trail_gain: float = pow(1.12,float(trail_rank))
    var frenzy: float = 1.85 if frenzy_left > 0.0 else 1.0
    var resonance: float = 2.0 if overdrive_left > 0.0 else 1.0
    return base*pow(1.19,float(int(item["level"])-1))*float(item["power"])*float(item["focus"])*heredity*evolved_gain*rare_gain*build*research_gain*trail_gain*frenzy*resonance

func multiplier(attacker_kind: String,defender_kind: String) -> float:
    var attacking: String = String(CATALOG.get(attacker_kind,{}).get("element",""))
    var defending: String = String(CATALOG.get(defender_kind,{}).get("element",""))
    if attacking == "" or defending == "":
        return 1.0
    if ELEMENT_BEATS[attacking] == defending:
        return 2.0
    if ELEMENT_BEATS[defending] == attacking:
        return 0.45
    return 1.0

func roster_for(stage: int) -> Array:
    # The first five rivals teach combat and supply the five Essence needed
    # for the first hatch. Stage six introduces the Air counter-wall.
    if stage <= 2:
        return ["brinlet","driplet","tidefin"]
    if stage == 3:
        return ["brinlet","mossling","driplet"]
    if stage == 4:
        return ["tidefin","brinlet","pebblit"]
    if stage == 5:
        return ["driplet","tidefin","brinlet"]
    var waves: Array = [
        ["zephlet","gustling","skyray"],
        ["pebblit","mossling","brinlet"],
        ["cindlet","zephlet","driplet"],
        ["gustling","tidefin","ashcub"],
        ["mossling","emberlyn","skyray"],
        ["brinlet","cindlet","gustling"],
        ["pebblit","ashcub","tidefin"],
        ["mossling","driplet","skyray"],
        ["cindlet","gustling","pebblit"],
        ["zephlet","brinlet","emberlyn"]
    ]
    return waves[(stage-6)%waves.size()].duplicate()

func _new_ally(kind: String,index: int) -> Dictionary:
    if not has_instance(kind):
        return {"kind":"","hp":0.0,"max_hp":1.0,"clock":0.0,"target":-1,"slot":index,"flash":0.0}
    var count: int = maxi(1,occupied_slots())
    var cap: float = max_ward()/float(count)*float(CATALOG[kind]["hp"])*float(unit_record(kind)["vigor"])
    return {"kind":kind,"hp":cap,"max_hp":cap,"clock":0.0,"target":-1,"slot":index,"flash":0.0}

func occupied_slots() -> int:
    var count: int = 0
    for kind in squad_slots:
        if has_instance(kind):
            count += 1
    return count

func initialize_squads() -> void:
    _ensure_starter()
    var assigned: Dictionary = {}
    for i in range(SQUAD_SIZE):
        var kind: String = String(squad_slots[i])
        if not has_instance(kind) or assigned.has(kind):
            squad_slots[i] = ""
        else:
            assigned[kind] = true
    if occupied_slots() == 0:
        squad_slots[0] = "spriglet"
    _setup_trainer_fight()

func assign_creature(slot: int,kind: String) -> bool:
    if slot < 0 or slot >= SQUAD_SIZE or not has_instance(kind):
        return false
    var old_slot: int = squad_slots.find(kind)
    if old_slot == slot:
        return false
    var displaced: String = squad_slots[slot]
    squad_slots[slot] = kind
    if old_slot >= 0:
        squad_slots[old_slot] = displaced
    initialize_squads()
    _report("%s now occupies squad slot %d. Each species can appear only once." % [combat_name(kind),slot+1])
    return true

func cycle_slot(_index: int) -> bool:
    # Squad changes must explicitly pick a unique owned individual.
    return false

func creature_level_price(kind: String,amount: int = 1) -> float:
    if not has_instance(kind):
        return INF
    var total: float = 0.0
    for i in range(clampi(amount,1,25)):
        total += ceil(9.0*pow(1.20,float(unit_level(kind)+i-1)))
    return total

func level_creature(kind: String,amount: int = 1) -> bool:
    var cost: float = creature_level_price(kind,amount)
    if gold < cost or not has_instance(kind):
        return false
    gold -= cost
    owned_creatures[kind]["level"] = unit_level(kind)+clampi(amount,1,25)
    if levels.has(kind):
        levels[kind] = unit_level(kind)
    _check_personal_evolution(kind)
    _report("%s grew to level %d. Every individual has independent growth." % [combat_name(kind),unit_level(kind)])
    return true

func _check_personal_evolution(kind: String) -> void:
    var item: Dictionary = unit_record(kind)
    if bool(item["evolved"]) or int(item["level"]) < 15 or int(item["bond"]) < 25:
        return
    item["evolved"] = true
    if evolved.has(kind):
        evolved[kind] = true
    _report("%s evolved into %s! Its individual traits survive Ascension." % [
        String(CATALOG[kind]["name"]),combat_name(kind)])

func _rescale_ally_max() -> void:
    var count: int = maxi(1,occupied_slots())
    for unit in ally_units:
        var kind: String = String(unit["kind"])
        if not has_instance(kind):
            continue
        var ratio: float = float(unit["hp"])/maxf(1.0,float(unit["max_hp"]))
        var cap: float = max_ward()/float(count)*float(CATALOG[kind]["hp"])*float(unit_record(kind)["vigor"])
        unit["max_hp"] = cap
        unit["hp"] = cap*ratio
    _sync_health()

func hatch_cost() -> int:
    return maxi(5,int(ceil(5.0*pow(1.58,float(maxi(0,collection_count()-1))))))

func hatch_egg() -> String:
    var price: int = hatch_cost()
    if essence < price:
        _report("Earn %d more Essence from trainer victories to hatch a unique creature." % [price-essence])
        return ""
    if collection_count() >= CATALOG.size():
        _report("The twelve-species collection is complete. Train and evolve your unique creatures!")
        return ""
    essence -= price
    eggs_hatched += 1
    var kind: String = ""
    # First three earned hatches teach the counters, without selling species
    # outright for Gold. After that, every summon guarantees a NEW species.
    var priority: Array[String] = ["cindlet","brinlet","zephlet"]
    if new_hatches < priority.size() and not has_instance(priority[new_hatches]):
        kind = priority[new_hatches]
    else:
        var candidates: Array[String] = []
        for key in COLLECTION_ORDER:
            if not has_instance(key):
                candidates.append(key)
        kind = candidates[_rng.randi_range(0,candidates.size()-1)]
    creature_serial += 1
    owned_creatures[kind] = _new_record(kind,creature_serial)
    new_hatches += 1
    last_hatch_kind = kind
    if levels.has(kind):
        levels[kind] = 1
    var rarity: bool = rare_pity >= 9 or _rng.randf() < 0.07
    rare[kind] = rarity
    rare_pity = 0 if rarity else rare_pity+1
    collecting_notice = "%s joined! Trait: %s. You own %d / 12 unique species." % [
        combat_name(kind),unit_trait(kind),collection_count()]
    _report(collecting_notice)
    return kind

func _enemy_defeated() -> void:
    var present: Array[String] = []
    for kind in squad_slots:
        if has_instance(kind):
            present.append(kind)
    super._enemy_defeated()
    essence += 1+(3 if (wave-1)%10 == 0 and not repeat_wave else 0)
    for kind in present:
        var item: Dictionary = unit_record(kind)
        item["bond"] = int(item["bond"])+1
        if bonds.has(kind):
            bonds[kind] = int(item["bond"])
        _check_personal_evolution(kind)
    collecting_notice = "+1 Essence! %d / %d for your next unique hatch." % [essence,hatch_cost()]
    if not awaiting_next and not repeat_wave:
        collecting_notice = "Trainer defeated. "+collecting_notice
    _report(collecting_notice)

func trail_complete() -> bool:
    return trail_rank >= COLLECTION_TRAIL.size()

func trail_info() -> Dictionary:
    if trail_complete():
        return {"name":"Your Living Collection","hint":"Hatch the remaining unique species, evolve your favorite individuals, and climb the endless trainer ladder.","kind":"end","target":1,"gold":0.0,"shards":0,"echoes":0}
    return COLLECTION_TRAIL[trail_rank]

func trail_progress() -> int:
    if trail_complete():
        return 1
    var kind: String = String(trail_info()["kind"])
    match kind:
        "kills":
            return kills
        "collection":
            return collection_count()
        "wave":
            return best_wave
        "squad":
            return occupied_slots()
        "guardian":
            return last_boss_wave
        "level":
            return maxi(unit_level("spriglet"),15 if owned_creatures.values().any(func(item: Dictionary) -> bool: return bool(item["evolved"])) else 0)
        "air":
            for key in owned_creatures:
                if String(CATALOG[key]["element"]) == "Air":
                    return 1
            return 0
        "ascend":
            return ascensions
    return 0

func claim_trail() -> bool:
    if trail_complete() or trail_progress() < int(trail_info()["target"]):
        return false
    var goal: Dictionary = trail_info()
    trail_rank += 1
    gold += float(goal["gold"])
    lifetime_gold += float(goal["gold"])
    nests += int(goal["shards"])
    echoes += int(goal["echoes"])
    lifetime_echoes += int(goal["echoes"])
    _report("JOURNEY: %s complete! Permanent +12%% damage; +%s Gold." % [String(goal["name"]),format_number(float(goal["gold"]))])
    return true

func use_ability(kind: String) -> bool:
    if awaiting_next or not has_instance(kind):
        return false
    var alive: bool = false
    for unit in ally_units:
        if String(unit["kind"]) == kind and float(unit["hp"]) > 0.0:
            alive = true
    if not alive:
        return false
    var cooldown: float = float(unlock_clock.get(kind,0.0))
    if cooldown > 0.0:
        return false
    unlock_clock[kind] = 21.0
    var element: String = String(CATALOG[kind]["element"])
    match element:
        "Earth":
            _heal_allies(party_max_hp()*0.27)
        "Water":
            attack(maxf(10.0,combat_damage(kind)*4.0))
        "Fire":
            frenzy_left = maxf(frenzy_left,8.0)
        "Air":
            overdrive_left = maxf(overdrive_left,5.0)
    _report("%s uses %s!" % [combat_name(kind),String(CATALOG[kind]["ability"])])
    return true

func tick(delta: float) -> void:
    for key in unlock_clock:
        unlock_clock[key] = maxf(0.0,float(unlock_clock[key])-clampf(delta,0.0,0.25)*game_speed)
    super.tick(delta)

func ascend() -> bool:
    var did: bool = super.ascend()
    if did:
        for key in owned_creatures:
            owned_creatures[key]["level"] = 1
            if levels.has(key):
                levels[key] = 1
        unlock_clock.clear()
        initialize_squads()
    return did

func to_dict() -> Dictionary:
    var data: Dictionary = super.to_dict()
    data["v12_collection"] = owned_creatures.duplicate(true)
    data["v12_slots"] = squad_slots.duplicate()
    data["v12_essence"] = essence
    data["v12_hatches"] = new_hatches
    data["v12_serial"] = creature_serial
    data["v12_unlock_clock"] = unlock_clock.duplicate()
    data["v12_last_hatch"] = last_hatch_kind
    return data

func load_save() -> bool:
    _ensure_starter()
    var loaded: bool = super.load_save()
    var file: FileAccess = FileAccess.open(SAVE_FILE,FileAccess.READ)
    if file != null:
        var parsed: Variant = JSON.parse_string(file.get_as_text())
        if parsed is Dictionary:
            var data: Dictionary = parsed
            var saved_collection: Dictionary = data.get("v12_collection",{})
            if not saved_collection.is_empty():
                owned_creatures.clear()
                for key in saved_collection:
                    if CATALOG.has(key) and saved_collection[key] is Dictionary:
                        var item: Dictionary = saved_collection[key]
                        owned_creatures[key] = _new_record(String(key),maxi(1,int(item.get("id",1))))
                        for field in ["level","bond","gene","evolved","trait","power","speed","vigor","focus"]:
                            if item.has(field):
                                owned_creatures[key][field] = item[field]
                        owned_creatures[key]["level"] = maxi(1,int(owned_creatures[key]["level"]))
                        if levels.has(key):
                            levels[key] = int(owned_creatures[key]["level"])
                            bonds[key] = int(owned_creatures[key]["bond"])
                            evolved[key] = bool(owned_creatures[key]["evolved"])
            essence = maxi(0,int(data.get("v12_essence",0)))
            new_hatches = maxi(0,int(data.get("v12_hatches",0)))
            creature_serial = maxi(1,int(data.get("v12_serial",1)))
            last_hatch_kind = String(data.get("v12_last_hatch",""))
            var saved_slots: Array = data.get("v12_slots",[])
            if saved_slots.size() == SQUAD_SIZE:
                for i in range(SQUAD_SIZE):
                    squad_slots[i] = String(saved_slots[i])
            var clocks: Dictionary = data.get("v12_unlock_clock",{})
            for key in clocks:
                if CATALOG.has(key):
                    unlock_clock[key] = clampf(float(clocks[key]),0.0,30.0)
    _ensure_starter()
    initialize_squads()
    return loaded
