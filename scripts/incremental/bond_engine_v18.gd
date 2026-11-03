extends "res://scripts/incremental/bond_engine_v14.gd"
## v0.18: stable species families, balanced randomized opening trio, seeded
## stage encounters, and first-earned-egg pricing; no destructive migrations.
const FAMILIES: Dictionary = {
    "cindlet":"Fox","brinlet":"Fox","spriglet":"Fox","gustling":"Fox",
    "emberlyn":"Bird","tidefin":"Bird","mossling":"Bird","zephlet":"Bird",
    "ashcub":"Lizard","driplet":"Lizard","pebblit":"Lizard","skyray":"Lizard"
}
const LINES: Dictionary = {
    "cindlet":["Cindlet","Blazetail","Infernovex","Fierce"],
    "brinlet":["Brinlet","Riptail","Tidefang","Stoic"],
    "spriglet":["Spriglet","Briarvex","Thornreign","Noble"],
    "gustling":["Zephvex","Galewraith","Skyreign","Mysterious"],
    "emberlyn":["Emberwing","Pyretalon","Sunrend","Aggressive"],
    "tidefin":["Tidecrest","Reefhunter","Tideroc","Predatory"],
    "mossling":["Mosswing","Cragowl","Dreadcanopy","Ominous"],
    "zephlet":["Zephlet","Stormtalon","Tempestroc","Majestic"],
    "ashcub":["Scorlisk","Magmaw","Cataclysk","Brutal"],
    "driplet":["Rillisk","Fenmaw","Thalassaur","Eerie"],
    "pebblit":["Pebblit","Shaleback","Monolisk","Relentless"],
    "skyray":["Glidescale","Voltrake","Skyrend","Bizarre"]
}
const FAMILY_ORDER: Array[String] = ["Fox","Bird","Lizard"]
var run_seed: int = 0
var opening_seed: int = 0
var randomized_opening: bool = false

func _ensure_run_seed() -> void:
    if run_seed > 0:
        return
    if FileAccess.file_exists(SAVE_FILE):
        var file: FileAccess = FileAccess.open(SAVE_FILE,FileAccess.READ)
        if file != null:
            var data: Variant = JSON.parse_string(file.get_as_text())
            if data is Dictionary:
                run_seed = maxi(0,int(data.get("v18_run_seed",0)))
                opening_seed = maxi(0,int(data.get("v18_opening_seed",0)))
                randomized_opening = bool(data.get("v18_randomized_opening",false))
    if run_seed <= 0:
        var rng: RandomNumberGenerator = RandomNumberGenerator.new()
        rng.randomize()
        run_seed = rng.randi_range(1,2000000000)

func family_of(kind: String) -> String:
    return String(FAMILIES.get(kind,""))

func unit_ascended(kind: String) -> bool:
    return has_instance(kind) and unit_evolved(kind) and unit_bond_rank(kind) >= 3

func display_name(kind: String,form: int = 0) -> String:
    if not LINES.has(kind):
        return "Unknown"
    return String(LINES[kind][clampi(form,0,2)])

func combat_meta(kind: String) -> Dictionary:
    var info: Dictionary = super.combat_meta(kind).duplicate()
    if LINES.has(kind):
        info["name"] = display_name(kind)
        info["evolved"] = display_name(kind,1)
        info["ascended"] = display_name(kind,2)
        info["family"] = family_of(kind)
        info["tone"] = String(LINES[kind][3])
    return info

func combat_name(kind: String) -> String:
    if not LINES.has(kind):
        return "Unassigned"
    return display_name(kind,2 if unit_ascended(kind) else (1 if unit_evolved(kind) else 0))

func _ensure_starter() -> void:
    # Invoked by v0.12 before save migration. Existing collections MUST
    # never be supplemented, deleted, or rerolled. Only an empty save starts
    # with three strangers chosen from the approved 12-line roster.
    if not owned_creatures.is_empty():
        return
    _ensure_run_seed()
    if opening_seed <= 0:
        opening_seed = run_seed ^ 135791113
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = opening_seed
    var elements: Array[String] = ELEMENTS.duplicate()
    for i in range(elements.size()-1,0,-1):
        var j: int = rng.randi_range(0,i)
        var temp: String = elements[i]
        elements[i] = elements[j]
        elements[j] = temp
    squad_slots.resize(SQUAD_SIZE)
    for i in range(FAMILY_ORDER.size()):
        var family: String = FAMILY_ORDER[i]
        var element: String = elements[i]
        var picks: Array[String] = []
        for key in COLLECTION_ORDER:
            if family_of(key) == family and String(CATALOG[key]["element"]) == element:
                picks.append(key)
        if picks.is_empty():
            push_error("v0.18 requires one creature in every family/element pair.")
            return
        var kind: String = picks[rng.randi_range(0,picks.size()-1)]
        creature_serial += 1
        owned_creatures[kind] = _new_record(kind,creature_serial)
        squad_slots[i] = kind
        levels[kind] = 1
        bonds[kind] = 0
        evolved[kind] = false
    randomized_opening = true
    collecting_notice = "NEW ROSTER: %s, %s, %s. You begin with three unique elemental families." % [
        combat_name(squad_slots[0]),combat_name(squad_slots[1]),combat_name(squad_slots[2])]

func initialize_squads() -> void:
    _ensure_starter()
    super.initialize_squads()

func hatch_cost() -> int:
    # Three complementary free starters must NOT inflate the first earned egg.
    return maxi(5,int(ceil(5.0*pow(1.58,float(maxi(0,new_hatches))))))

func hatch_egg() -> String:
    var price: int = hatch_cost()
    if essence < price:
        _report("Earn %d more first-clear Essence for the next unique egg." % (price-essence))
        return ""
    var candidates: Array[String] = []
    var missing: Array[String] = []
    var elements_owned: Dictionary = {}
    for key in owned_creatures:
        elements_owned[String(CATALOG[key]["element"])] = true
    for key in COLLECTION_ORDER:
        if not has_instance(key):
            candidates.append(key)
            if not elements_owned.has(String(CATALOG[key]["element"])):
                missing.append(key)
    if candidates.is_empty():
        _report("The twelve-line collection is complete.")
        return ""
    var pool: Array[String] = missing if not missing.is_empty() else candidates
    var kind: String = pool[_rng.randi_range(0,pool.size()-1)]
    essence -= price
    eggs_hatched += 1
    creature_serial += 1
    owned_creatures[kind] = _new_record(kind,creature_serial)
    new_hatches += 1
    last_hatch_kind = kind
    levels[kind] = 1
    bonds[kind] = 0
    evolved[kind] = false
    var rarity: bool = rare_pity >= 9 or _rng.randf() < 0.07
    rare[kind] = rarity
    owned_creatures[kind]["shimmer"] = rarity
    rare_pity = 0 if rarity else rare_pity+1
    collecting_notice = "%s joined! %s %s. Trait: %s. Collection: %d / 12." % [
        combat_name(kind),String(CATALOG[kind]["element"]),family_of(kind),unit_trait(kind),collection_count()]
    _report(collecting_notice)
    return kind

func roster_for(stage: int) -> Array:
    _ensure_run_seed()
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = (run_seed ^ (maxi(1,stage)*1103515245)) & 9223372036854775807
    var guardian: bool = stage % 10 == 0
    var first_element: String = ELEMENTS[rng.randi_range(0,ELEMENTS.size()-1)]
    var second_element: String = ELEMENTS[rng.randi_range(0,ELEMENTS.size()-1)]
    var roster: Array[String] = []
    for slot in range(SQUAD_SIZE):
        var possible: Array[String] = []
        for key in COLLECTION_ORDER:
            if roster.has(key):
                continue
            var family_match: bool = not guardian or family_of(key) == FAMILY_ORDER[slot]
            var early_match: bool = stage > 3 or (
                String(CATALOG[key]["element"]) == first_element or
                (slot > 0 and String(CATALOG[key]["element"]) == second_element))
            if family_match and early_match:
                possible.append(key)
        if possible.is_empty():
            for key in COLLECTION_ORDER:
                if not roster.has(key):
                    possible.append(key)
        roster.append(possible[rng.randi_range(0,possible.size()-1)])
    return roster

func encounter_id(stage: int) -> String:
    var enemies: Array = roster_for(stage)
    return "|".join(enemies)

func ascend() -> bool:
    var success: bool = super.ascend()
    if success:
        var rng: RandomNumberGenerator = RandomNumberGenerator.new()
        rng.randomize()
        var previous: int = run_seed
        run_seed = rng.randi_range(1,2000000000)
        if run_seed == previous:
            run_seed = (previous % 2000000000)+1
        # Keep every owned individual and deliberately preserve the player's
        # squad choices, Bond Ranks and evolution; only opponents reroll.
        _setup_trainer_fight()
        _report("ASCENSION %d: a new wild encounter cycle begins. Your collection and Bond Ranks survive." % ascensions)
    return success

func trail_info() -> Dictionary:
    var original: Dictionary = super.trail_info()
    var next: Dictionary = original.duplicate()
    if trail_rank == 1:
        next["name"] = "Your Fourth Companion"
        next["hint"] = "Earn five first-clear Essence and hatch a fourth unique creature. Your three starters are gifts, not paid eggs."
        next["target"] = 4
    elif trail_rank == 2:
        next["name"] = "Read the Elements"
        next["hint"] = "Clear trainer stage 6. The elemental circle is Earth > Water > Fire > Air > Earth."
    elif trail_rank == 3:
        next["name"] = "Widen Your Team"
        next["hint"] = "Collect five unique lines by pushing and hatching more eggs."
        next["kind"] = "collection"
        next["target"] = 5
    elif trail_rank == 7:
        next["name"] = "Full Element Circle"
        next["hint"] = "Own at least one creature of all four elements."
        next["kind"] = "four_elements"
        next["target"] = 4
    return next

func trail_progress() -> int:
    if not trail_complete() and String(trail_info().get("kind","")) == "four_elements":
        var found: Dictionary = {}
        for kind in owned_creatures:
            found[String(CATALOG[kind]["element"])] = true
        return found.size()
    return super.trail_progress()

func to_dict() -> Dictionary:
    var data: Dictionary = super.to_dict()
    data["v18_run_seed"] = run_seed
    data["v18_opening_seed"] = opening_seed
    data["v18_randomized_opening"] = randomized_opening
    return data

func load_save() -> bool:
    # Read seed BEFORE lower-level reload constructs trainer units. This
    # preserves the same opponents and battle attrition across save/reload.
    _ensure_run_seed()
    var success: bool = super.load_save()
    # Loading a legacy save legitimately has a collection but no v0.18 key;
    # do not randomize or award three starter creatures on migration.
    return success
