extends RefCounted
## Wildbound Duel v0.30: exactly three elemental families, one living creature
## against one rival at a time. The older 3v3 engine is not executed.
## Uses its own safe save namespace; a best-effort legacy import is read-only.
signal changed(message: String)

const SAVE_FILE: String = "user://wildbound_duel_v30.json"
const LEGACY_FILE: String = "user://wildbound_bond_v14_preview_v1.json"
const LEGACY_FALLBACK: String = "user://wildbound_incremental_reboot_v1.json"
const ORDER: Array[String] = ["cindlet","brinlet","spriglet"]
const SPECIES: Dictionary = {
    "cindlet":{"name":"Cindlet","evolved":"Blazetail","element":"Fire","base":5.6,"interval":1.10,"hp":90.0},
    "brinlet":{"name":"Brinlet","evolved":"Tidemare","element":"Water","base":4.4,"interval":0.93,"hp":105.0},
    "spriglet":{"name":"Spriglet","evolved":"Thornhart","element":"Earth","base":4.8,"interval":1.01,"hp":112.0}
}
const BEATS: Dictionary = {"Fire":"Earth","Earth":"Water","Water":"Fire"}
const UPGRADES: Array[String] = ["power","haste","guard"]
const UPGRADE_NAMES: Dictionary = {"power":"MIGHT","haste":"HASTE","guard":"VITALITY"}
const UPGRADE_HELP: Dictionary = {
    "power":"Each level grants +14% attack power.",
    "haste":"Each level makes attacks 5% faster.",
    "guard":"Each level grants +18% maximum HP."
}
var stage: int = 1
var best_stage: int = 0
var push_stage: int = 1
var gold: float = 0.0
var echo: int = 0
var ascensions: int = 0
var wins: int = 0
var deaths: int = 0
var active: String = "spriglet"
var levels: Dictionary = {"cindlet":1,"brinlet":1,"spriglet":1}
var bond_ranks: Dictionary = {"cindlet":1,"brinlet":1,"spriglet":1}
var bond_xp: Dictionary = {"cindlet":0,"brinlet":0,"spriglet":0}
var evolved: Dictionary = {"cindlet":false,"brinlet":false,"spriglet":false}
var upgrades: Dictionary = {"power":0,"haste":0,"guard":0}
var auto_advance: bool = false
var battle_started: bool = false
var fighting: bool = false
var awaiting_next: bool = false
var defeated: bool = false
var farming: bool = false
var opponent: String = "spriglet"
var enemy_hp: float = 1.0
var enemy_max_hp: float = 1.0
var hero_hp: float = 100.0
var hero_max_hp: float = 100.0
var hero_clock: float = 0.0
var enemy_clock: float = 0.0
var clear_pause: float = 0.0
var switch_cooldown: float = 0.0
var last_hit: float = 0.0
var impact_flash: float = 0.0
var last_notice: String = "Choose a creature, then begin your adventure."
var highest_run_stage: int = 1

func _init() -> void:
    _spawn()

func element(kind: String) -> String:
    return String(SPECIES.get(kind,{}).get("element",""))

func display_name(kind: String) -> String:
    if not SPECIES.has(kind):
        return "Unknown"
    return String(SPECIES[kind]["evolved"] if bool(evolved[kind]) else SPECIES[kind]["name"])

func level_cap(kind: String) -> int:
    return 8+5*int(bond_ranks.get(kind,1))

func level_cost(kind: String) -> float:
    if not SPECIES.has(kind) or int(levels[kind]) >= level_cap(kind):
        return INF
    return ceil(10.0*pow(1.19,float(int(levels[kind])-1)))

func upgrade_cost(kind: String) -> float:
    if not UPGRADES.has(kind):
        return INF
    var starting: float = {"power":35.0,"haste":60.0,"guard":50.0}[kind]
    return ceil(starting*pow(1.34,float(int(upgrades[kind]))))

func format_number(amount: float) -> String:
    var abs_amount: float = absf(amount)
    if abs_amount < 1000.0:
        return str(roundi(amount))
    var units: Array[String] = ["K","M","B","T","Qa","Qi"]
    var index: int = 0
    var scaled: float = amount
    while absf(scaled) >= 1000.0 and index < units.size():
        scaled /= 1000.0
        index += 1
    return ("%.2f" % scaled).trim_suffix(".00")+units[index-1]

func matchup(a: String,b: String) -> float:
    var attacker: String = element(a)
    var defender: String = element(b)
    if attacker == defender:
        return 1.0
    if BEATS.get(attacker,"") == defender:
        return 2.0
    return 0.5

func damage(kind: String) -> float:
    if not SPECIES.has(kind):
        return 0.0
    return float(SPECIES[kind]["base"])*pow(1.18,float(int(levels[kind])-1))*pow(1.14,float(int(upgrades["power"])))*(2.65 if bool(evolved[kind]) else 1.0)*pow(1.20,float(ascensions))

func interval(kind: String) -> float:
    return maxf(0.22,float(SPECIES[kind]["interval"])*pow(0.95,float(int(upgrades["haste"]))))

func dps(kind: String) -> float:
    return damage(kind)/interval(kind)

func hero_hp_cap(kind: String) -> float:
    return (float(SPECIES[kind]["hp"])+float(int(levels[kind])-1)*5.0)*pow(1.18,float(int(upgrades["guard"])))*pow(1.08,float(ascensions))

func is_boss() -> bool:
    return stage % 5 == 0

func _spawn() -> void:
    # Three original elements only, including enemies at every stage.
    var enemy_rotation: Array[String] = ["brinlet","cindlet","spriglet"]
    opponent = enemy_rotation[(stage-1)%enemy_rotation.size()]
    var scalar: float = 4.0 if is_boss() else 1.0
    enemy_max_hp = (32.0*pow(1.235,float(stage-1))+float(stage)*3.0)*scalar
    enemy_hp = enemy_max_hp
    hero_max_hp = hero_hp_cap(active)
    hero_hp = hero_max_hp
    hero_clock = 0.0
    enemy_clock = 0.0
    switch_cooldown = 0.0
    impact_flash = 0.0

func select_creature(kind: String) -> bool:
    if not SPECIES.has(kind) or kind == active or switch_cooldown > 0.0:
        return false
    var fraction: float = hero_hp/maxf(1.0,hero_max_hp)
    active = kind
    hero_max_hp = hero_hp_cap(active)
    hero_hp = hero_max_hp*clampf(fraction,0.0,1.0)
    hero_clock = 0.0
    switch_cooldown = 1.8 if fighting else 0.0
    _announce("%s enters the duel! %s attacks %s." % [display_name(kind),element(kind),element(opponent)])
    save()
    return true

func start() -> bool:
    if fighting or (awaiting_next and not defeated):
        return false
    if not battle_started:
        battle_started = true
    if defeated:
        defeated = false
        awaiting_next = false
        _spawn()
    fighting = true
    _announce("DUEL STARTED • %s vs %s" % [display_name(active),display_name(opponent)])
    save()
    return true

func hit(tap: bool = false) -> void:
    if not fighting or awaiting_next:
        return
    var strike: float = damage(active)*matchup(active,opponent)*(0.65 if tap else 1.0)
    last_hit = strike
    impact_flash = 0.18
    enemy_hp = maxf(0.0,enemy_hp-strike)
    if enemy_hp <= 0.0:
        _victory()

func _enemy_hit() -> void:
    if not fighting:
        return
    var strike: float = (3.6*pow(1.105,float(stage-1))*(1.8 if is_boss() else 1.0))
    hero_hp = maxf(0.0,hero_hp-strike*matchup(opponent,active))
    if hero_hp <= 0.0:
        fighting = false
        awaiting_next = true
        defeated = true
        deaths += 1
        farming = false
        _announce("%s was defeated. Level up, switch elements, or retry." % display_name(active))
        save()

func _victory() -> void:
    if not fighting:
        return
    fighting = false
    awaiting_next = true
    defeated = false
    wins += 1
    var gained: float = ceil((13.0*pow(1.172,float(stage-1)))*(3.5 if is_boss() else 1.0))
    gold += gained
    var prior_best: int = best_stage
    if not farming:
        best_stage = maxi(best_stage,stage)
        push_stage = maxi(push_stage,stage+1)
        highest_run_stage = maxi(highest_run_stage,stage+1)
    bond_xp[active] = int(bond_xp[active])+1
    if int(levels[active]) >= 15 and int(bond_xp[active]) >= 15:
        evolved[active] = true
    clear_pause = 1.0
    _announce("%s WINS • +%s Gold%s" % [
        display_name(active),format_number(gained),
        " • NEW STAGE RECORD" if not farming and stage > prior_best else ""])
    save()

func next_stage() -> bool:
    if not awaiting_next or defeated:
        return false
    farming = false
    stage = maxi(stage+1,push_stage)
    push_stage = stage
    awaiting_next = false
    _spawn()
    fighting = true
    _announce("STAGE %d • %s" % [stage,display_name(opponent)])
    save()
    return true

func toggle_farm() -> bool:
    if best_stage < 1:
        return false
    if farming:
        farming = false
        stage = push_stage
        awaiting_next = false
        defeated = false
        _spawn()
        fighting = true
        _announce("PUSHING STAGE %d" % stage)
    else:
        farming = true
        stage = mini(best_stage,maxi(1,push_stage-1))
        awaiting_next = false
        defeated = false
        _spawn()
        fighting = true
        battle_started = true
        _announce("FARMING STAGE %d • Gold + Bond XP" % stage)
    save()
    return true

func level_up(kind: String) -> bool:
    var price: float = level_cost(kind)
    if not SPECIES.has(kind) or price == INF or gold < price:
        return false
    gold -= price
    levels[kind] = int(levels[kind])+1
    if kind == active:
        var fraction: float = hero_hp/maxf(1.0,hero_max_hp)
        hero_max_hp = hero_hp_cap(active)
        hero_hp = hero_max_hp*fraction
    _announce("%s TRAINED TO LEVEL %d" % [display_name(kind),int(levels[kind])])
    save()
    return true

func buy_upgrade(kind: String) -> bool:
    if not UPGRADES.has(kind):
        return false
    var price: float = upgrade_cost(kind)
    if gold < price:
        return false
    gold -= price
    upgrades[kind] = int(upgrades[kind])+1
    var fraction: float = hero_hp/maxf(1.0,hero_max_hp)
    hero_max_hp = hero_hp_cap(active)
    hero_hp = hero_max_hp*fraction
    _announce("%s UPGRADED" % UPGRADE_NAMES[kind])
    save()
    return true

func can_ascend() -> bool:
    return best_stage >= 20 and highest_run_stage >= 20

func ascend() -> bool:
    if not can_ascend():
        return false
    ascensions += 1
    echo += 1
    for kind in ORDER:
        if int(bond_xp[kind]) >= 5+int(bond_ranks[kind])*3:
            bond_ranks[kind] = int(bond_ranks[kind])+1
            bond_xp[kind] = 0
        levels[kind] = 1
    for upgrade in UPGRADES:
        upgrades[upgrade] = 0
    gold = 0.0
    stage = 1
    push_stage = 1
    highest_run_stage = 1
    best_stage = 0
    farming = false
    fighting = false
    awaiting_next = false
    defeated = false
    battle_started = false
    _spawn()
    _announce("ASCENDED • +1 ECHO • BOND RANKS PERMANENT")
    save()
    return true

func tick(delta: float) -> void:
    var dt: float = clampf(delta,0.0,0.15)
    impact_flash = maxf(0.0,impact_flash-dt)
    switch_cooldown = maxf(0.0,switch_cooldown-dt)
    if farming and awaiting_next and not defeated:
        clear_pause -= dt
        if clear_pause <= 0.0:
            awaiting_next = false
            _spawn()
            fighting = true
    if not fighting or awaiting_next:
        return
    hero_clock += dt
    enemy_clock += dt
    if hero_clock >= interval(active):
        hero_clock -= interval(active)
        hit()
    if fighting and enemy_clock >= 2.1:
        enemy_clock -= 2.1
        _enemy_hit()

func _announce(message: String) -> void:
    last_notice = message
    changed.emit(message)

func to_dict() -> Dictionary:
    return {"version":30,"stage":stage,"best_stage":best_stage,
        "push_stage":push_stage,"highest_run_stage":highest_run_stage,
        "gold":gold,"echo":echo,"ascensions":ascensions,"wins":wins,
        "deaths":deaths,"active":active,"levels":levels.duplicate(),
        "bond_ranks":bond_ranks.duplicate(),"bond_xp":bond_xp.duplicate(),
        "evolved":evolved.duplicate(),"upgrades":upgrades.duplicate(),
        "battle_started":battle_started,"farming":farming,
        "fighting":fighting,"awaiting_next":awaiting_next,"defeated":defeated,
        "enemy_hp":enemy_hp,"hero_hp":hero_hp,"saved_at":Time.get_unix_time_from_system()}

func save() -> bool:
    var file: FileAccess = FileAccess.open(SAVE_FILE,FileAccess.WRITE)
    if file == null:
        return false
    file.store_string(JSON.stringify(to_dict()))
    return true

func load() -> bool:
    if not FileAccess.file_exists(SAVE_FILE):
        return _migrate_legacy()
    var file: FileAccess = FileAccess.open(SAVE_FILE,FileAccess.READ)
    if file == null:
        return false
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary):
        return false
    var data: Dictionary = parsed
    if int(data.get("version",0)) != 30:
        return false
    gold = clampf(float(data.get("gold",0.0)),0.0,1.0e30)
    echo = maxi(0,int(data.get("echo",0)))
    ascensions = maxi(0,int(data.get("ascensions",0)))
    wins = maxi(0,int(data.get("wins",0)))
    deaths = maxi(0,int(data.get("deaths",0)))
    best_stage = maxi(0,int(data.get("best_stage",0)))
    push_stage = maxi(1,int(data.get("push_stage",1)))
    highest_run_stage = maxi(1,int(data.get("highest_run_stage",push_stage)))
    stage = maxi(1,int(data.get("stage",1)))
    active = String(data.get("active","spriglet"))
    if not SPECIES.has(active):
        active = "spriglet"
    for key in ORDER:
        var ls: Dictionary = data.get("levels",{})
        var br: Dictionary = data.get("bond_ranks",{})
        var bx: Dictionary = data.get("bond_xp",{})
        var ev: Dictionary = data.get("evolved",{})
        levels[key] = maxi(1,int(ls.get(key,1)))
        bond_ranks[key] = maxi(1,int(br.get(key,1)))
        bond_xp[key] = maxi(0,int(bx.get(key,0)))
        levels[key] = mini(int(levels[key]),level_cap(key))
        evolved[key] = bool(ev.get(key,false))
    for key in UPGRADES:
        var us: Dictionary = data.get("upgrades",{})
        upgrades[key] = maxi(0,int(us.get(key,0)))
    battle_started = bool(data.get("battle_started",false))
    farming = bool(data.get("farming",false)) and best_stage > 0
    fighting = bool(data.get("fighting",false))
    awaiting_next = bool(data.get("awaiting_next",false))
    defeated = bool(data.get("defeated",false))
    _spawn()
    hero_hp = clampf(float(data.get("hero_hp",hero_max_hp)),0.0,hero_max_hp)
    enemy_hp = clampf(float(data.get("enemy_hp",enemy_max_hp)),0.0,enemy_max_hp)
    if not battle_started:
        fighting = false
        awaiting_next = false
    if defeated:
        fighting = false
        awaiting_next = true
    return true

func _migrate_legacy() -> bool:
    var old_path: String = LEGACY_FILE if FileAccess.file_exists(LEGACY_FILE) else LEGACY_FALLBACK
    if not FileAccess.file_exists(old_path):
        return false
    var file: FileAccess = FileAccess.open(old_path,FileAccess.READ)
    if file == null:
        return false
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if not (parsed is Dictionary):
        return false
    var data: Dictionary = parsed
    ascensions = maxi(0,int(data.get("ascensions",0)))
    gold = clampf(float(data.get("gold",0.0)),0.0,1.0e30)
    echo = maxi(0,int(data.get("echoes",0)))
    wins = maxi(0,int(data.get("kills",0)))
    best_stage = maxi(0,int(data.get("best_wave",1))-1)
    push_stage = maxi(1,int(data.get("wave",1)))
    stage = push_stage
    highest_run_stage = push_stage
    var collection: Dictionary = data.get("v12_collection",{})
    var rank: Dictionary = data.get("v14_bond_ranks",{})
    for kind in ORDER:
        if collection.has(kind):
            var item: Dictionary = collection[kind]
            levels[kind] = maxi(1,int(item.get("level",1)))
            bond_xp[kind] = maxi(0,int(item.get("bond",0)))
            evolved[kind] = bool(item.get("evolved",false))
        if rank.has(kind):
            bond_ranks[kind] = maxi(1,int(rank[kind]))
        levels[kind] = mini(int(levels[kind]),level_cap(kind))
    battle_started = false
    fighting = false
    awaiting_next = false
    defeated = false
    farming = false
    _spawn()
    _announce("Your earlier progress was imported into the new 1v1 adventure.")
    save()
    return true

func new_game() -> void:
    stage = 1
    best_stage = 0
    push_stage = 1
    highest_run_stage = 1
    gold = 0.0
    echo = 0
    ascensions = 0
    wins = 0
    deaths = 0
    active = "spriglet"
    for key in ORDER:
        levels[key] = 1
        bond_ranks[key] = 1
        bond_xp[key] = 0
        evolved[key] = false
    for upgrade in UPGRADES:
        upgrades[upgrade] = 0
    auto_advance = false
    battle_started = false
    fighting = false
    awaiting_next = false
    defeated = false
    farming = false
    _spawn()
    save()
