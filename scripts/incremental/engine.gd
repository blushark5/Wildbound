extends RefCounted
## Wildbound: creature-centric idle combat. Gameplay deliberately separate from UI.
signal notice(message: String)

const SPECIES := {
    "spriglet": {"name":"Spriglet", "evolved":"Thornhart", "element":"Grove", "base":3.8, "interval":0.85, "cost":0},
    "brinlet": {"name":"Brinlet", "evolved":"Tidemare", "element":"Tide", "base":3.2, "interval":0.70, "cost":48},
    "cindlet": {"name":"Cindlet", "evolved":"Blazetail", "element":"Ember", "base":5.7, "interval":1.10, "cost":155}
}
const ORDER := ["spriglet","brinlet","cindlet"]
const MODULES := ["power","guard","tempo"]
const RESEARCH := ["might","heart"]
const SAVE_FILE := "user://wildbound_incremental_reboot_v1.json"
var wave: int = 1
var best_wave: int = 1
var run_peak: int = 1
var gold: float = 0.0
var echoes: int = 0
var ascensions: int = 0
var defeats: int = 0
var kills: int = 0
var levels: Dictionary = {"spriglet":1,"brinlet":0,"cindlet":0}
var bonds: Dictionary = {"spriglet":0,"brinlet":0,"cindlet":0}
var evolved: Dictionary = {"spriglet":false,"brinlet":false,"cindlet":false}
var modules: Dictionary = {"power":0,"guard":0,"tempo":0}
var research: Dictionary = {"might":0,"heart":0}
var attack_clocks: Dictionary = {"spriglet":0.0,"brinlet":0.0,"cindlet":0.0}
var enemy_clock: float = 0.0
var enemy_hp: float = 0.0
var enemy_max_hp: float = 0.0
var ward: float = 100.0
var repeat_wave: bool = false
var enemy_species: String = "brinlet"
var tap_damage_last: float = 0.0
var last_notice: String = "A new bond is forged. Your creatures attack automatically."

func _init() -> void:
    _spawn_enemy()

func enemy_is_boss() -> bool:
    return wave % 10 == 0

func species_name(kind: String) -> String:
    if not SPECIES.has(kind):
        return "Unknown"
    return String(SPECIES[kind]["evolved"] if bool(evolved[kind]) else SPECIES[kind]["name"])

func species_damage(kind: String) -> float:
    if int(levels.get(kind,0)) < 1:
        return 0.0
    var lv: int = int(levels[kind])
    var base: float = float(SPECIES[kind]["base"])
    var evolved_multiplier: float = 2.8 if bool(evolved[kind]) else 1.0
    var gear: float = pow(1.13,float(int(modules["power"])))
    var legacy: float = pow(1.22,float(int(research["might"])))
    var family: float = 1.06 if int(levels["spriglet"]) > 0 and int(levels["brinlet"]) > 0 and int(levels["cindlet"]) > 0 else 1.0
    return base * pow(1.19,float(lv-1)) * evolved_multiplier * gear * legacy * family

func effective_damage(kind: String) -> float:
    # Original Wildbound elemental circle. A creature choice is a build choice.
    var attacking: String = String(SPECIES[kind]["element"])
    var defending: String = String(SPECIES[enemy_species]["element"])
    var wins: Dictionary = {"Grove":"Tide","Tide":"Ember","Ember":"Grove"}
    var multiplier: float = 1.0
    if String(wins.get(attacking,"")) == defending:
        multiplier = 1.50
    elif String(wins.get(defending,"")) == attacking:
        multiplier = 0.75
    return species_damage(kind)*multiplier

func attack_interval(kind: String) -> float:
    return maxf(0.18,float(SPECIES[kind]["interval"])*pow(0.94,float(int(modules["tempo"]))))

func total_dps() -> float:
    var result: float = 0.0
    for kind in ORDER:
        result += species_damage(kind) / attack_interval(kind)
    return result

func max_ward() -> float:
    return (100.0+22.0*float(int(modules["guard"])))*pow(1.18,float(int(research["heart"])))

func _spawn_enemy() -> void:
    var index: int = (wave-1) % 3
    enemy_species = String(ORDER[index])
    var boss_multi: float = 4.0 if enemy_is_boss() else 1.0
    enemy_max_hp = 18.0 * pow(1.185,float(wave-1)) * boss_multi
    enemy_hp = enemy_max_hp
    enemy_clock = 0.0

func enemy_damage() -> float:
    return 3.0*pow(1.09,float(wave-1))*(2.0 if enemy_is_boss() else 1.0)

func wave_reward() -> float:
    return 8.0*pow(1.135,float(wave-1))*(3.0 if enemy_is_boss() else 1.0)

func _report(message: String) -> void:
    last_notice = message
    notice.emit(message)

func attack(damage: float) -> void:
    if damage <= 0.0:
        return
    enemy_hp -= damage
    if enemy_hp <= 0.0:
        _enemy_defeated()

func tap() -> void:
    tap_damage_last = maxf(2.0,total_dps()*0.53)
    attack(tap_damage_last)

func tick(delta: float) -> void:
    var duration: float = clampf(delta,0.0,0.25)
    for kind in ORDER:
        if int(levels[kind]) < 1:
            continue
        var clock: float = float(attack_clocks[kind])+duration
        var interval: float = attack_interval(kind)
        var strikes: int = 0
        while clock >= interval and strikes < 4:
            clock -= interval
            attack(effective_damage(kind))
            strikes += 1
        attack_clocks[kind] = clock
    enemy_clock += duration
    if enemy_clock >= 1.65:
        enemy_clock -= 1.65
        ward -= enemy_damage()
        if ward <= 0.0:
            _regroup()

func _enemy_defeated() -> void:
    gold += wave_reward()
    kills += 1
    for kind in ORDER:
        if int(levels[kind]) > 0:
            bonds[kind] = int(bonds[kind])+1
            _check_evolution(kind)
    if enemy_is_boss():
        _report("Boss defeated! Your team earned bonus Gold.")
        ward = minf(max_ward(),ward+max_ward()*0.18)
    if not repeat_wave:
        wave += 1
        best_wave = maxi(best_wave,wave)
        run_peak = maxi(run_peak,wave)
    _spawn_enemy()

func _regroup() -> void:
    defeats += 1
    var before: int = wave
    wave = maxi(1,wave-4)
    ward = max_ward()
    _spawn_enemy()
    _report("Your pack retreated from wave %d to %d. Upgrades are kept." % [before,wave])

func level_cost(kind: String, level: int = -1) -> float:
    var lv: int = int(levels[kind]) if level < 0 else level
    if lv < 1:
        return float(SPECIES[kind]["cost"])
    return ceil(9.0*pow(1.20,float(lv-1)))

func can_buy(kind: String, amount: int = 1) -> bool:
    if not SPECIES.has(kind):
        return false
    return gold >= purchase_cost(kind,amount)

func purchase_cost(kind: String, amount: int) -> float:
    if not SPECIES.has(kind):
        return INF
    var lv: int = int(levels[kind])
    var total: float = 0.0
    for i in range(clampi(amount,1,25)):
        total += level_cost(kind,lv+i)
    return total

func buy_levels(kind: String, amount: int = 1) -> bool:
    if not SPECIES.has(kind):
        return false
    var quantity: int = clampi(amount,1,25)
    var price: float = purchase_cost(kind,quantity)
    if gold < price:
        return false
    gold -= price
    var was_locked: bool = int(levels[kind]) == 0
    levels[kind] = int(levels[kind])+quantity
    _check_evolution(kind)
    if was_locked:
        _report("%s joined your team!" % species_name(kind))
    return true

func module_cost(kind: String) -> float:
    if not modules.has(kind):
        return INF
    var starting: float = 85.0 if kind == "power" else (70.0 if kind == "guard" else 120.0)
    return ceil(starting*pow(1.58,float(int(modules[kind]))))

func buy_module(kind: String) -> bool:
    if not modules.has(kind):
        return false
    var price: float = module_cost(kind)
    if gold < price:
        return false
    gold -= price
    modules[kind] = int(modules[kind])+1
    if kind == "guard":
        ward = minf(max_ward(),ward+28.0)
    return true

func _check_evolution(kind: String) -> void:
    if bool(evolved[kind]) or int(levels[kind]) < 15 or int(bonds[kind]) < 25:
        return
    evolved[kind] = true
    _report("%s evolved into %s! The evolution survives Ascension." % [String(SPECIES[kind]["name"]),species_name(kind)])

func available_echoes() -> int:
    if run_peak < 20:
        return 0
    return maxi(1,int(pow(float(run_peak)/10.0,1.7)))

func ascend() -> bool:
    var earned: int = available_echoes()
    if earned < 1:
        return false
    echoes += earned
    ascensions += 1
    for kind in ORDER:
        levels[kind] = 1 if int(levels[kind]) > 0 else 0
        attack_clocks[kind] = 0.0
    for kind in MODULES:
        modules[kind] = 0
    gold = 0.0
    wave = 1
    run_peak = 1
    ward = max_ward()
    repeat_wave = false
    _spawn_enemy()
    _report("Ascension %d: +%d Echoes. Bonds and evolutions persist." % [ascensions,earned])
    return true

func research_cost(kind: String) -> int:
    if not research.has(kind):
        return 999999
    return int(research[kind])+1

func buy_research(kind: String) -> bool:
    if not research.has(kind):
        return false
    var price: int = research_cost(kind)
    if echoes < price:
        return false
    echoes -= price
    research[kind] = int(research[kind])+1
    if kind == "heart":
        ward = minf(max_ward(),ward+20.0)
    return true

func to_dict() -> Dictionary:
    return {
        "version":1,"wave":wave,"best_wave":best_wave,"run_peak":run_peak,
        "gold":gold,"echoes":echoes,"ascensions":ascensions,"defeats":defeats,"kills":kills,
        "levels":levels.duplicate(),"bonds":bonds.duplicate(),"evolved":evolved.duplicate(),
        "modules":modules.duplicate(),"research":research.duplicate(),"ward":ward,
        "repeat_wave":repeat_wave, "saved_at":Time.get_unix_time_from_system()
    }

func save() -> bool:
    var file: FileAccess = FileAccess.open(SAVE_FILE,FileAccess.WRITE)
    if file == null:
        _report("Could not save progress.")
        return false
    file.store_string(JSON.stringify(to_dict()))
    return true

func load_save() -> bool:
    if not FileAccess.file_exists(SAVE_FILE):
        return false
    var file: FileAccess = FileAccess.open(SAVE_FILE,FileAccess.READ)
    if file == null:
        return false
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary):
        return false
    var data: Dictionary = parsed
    if int(data.get("version",0)) != 1:
        return false
    wave = maxi(1,int(data.get("wave",1)))
    best_wave = maxi(wave,int(data.get("best_wave",1)))
    run_peak = maxi(wave,int(data.get("run_peak",wave)))
    gold = maxf(0.0,float(data.get("gold",0.0)))
    echoes = maxi(0,int(data.get("echoes",0)))
    ascensions = maxi(0,int(data.get("ascensions",0)))
    defeats = maxi(0,int(data.get("defeats",0)))
    kills = maxi(0,int(data.get("kills",0)))
    for key in ORDER:
        if data.get("levels",{}) is Dictionary:
            levels[key] = maxi(0,int(data["levels"].get(key,levels[key])))
        if data.get("bonds",{}) is Dictionary:
            bonds[key] = maxi(0,int(data["bonds"].get(key,0)))
        if data.get("evolved",{}) is Dictionary:
            evolved[key] = bool(data["evolved"].get(key,false))
    levels["spriglet"] = maxi(1,int(levels["spriglet"]))
    for key in MODULES:
        if data.get("modules",{}) is Dictionary:
            modules[key] = maxi(0,int(data["modules"].get(key,0)))
    for key in RESEARCH:
        if data.get("research",{}) is Dictionary:
            research[key] = maxi(0,int(data["research"].get(key,0)))
    repeat_wave = bool(data.get("repeat_wave",false))
    ward = clampf(float(data.get("ward",max_ward())),1.0,max_ward())
    _spawn_enemy()
    _report("Welcome back! Your pack is ready.")
    return true
