extends "res://scripts/incremental/v03_engine.gd"
## Wildbound v0.4: specialist bonds, dynamic combat, manual combo,
## Guardian pressure, milestone caches and portable player progression.
## Additive schema: existing /reboot/ saves stay in their current location.

const SPECIALIZATIONS: Dictionary = {
    "spriglet": {
        "briar":{"name":"Briarheart","desc":"+40% Spriglet damage, +12% critical damage"},
        "bloom":{"name":"Lifebloom","desc":"+30% Ward capacity, +25% Verdant Bloom healing"}
    },
    "brinlet": {
        "riptide":{"name":"Riptide","desc":"+32% Brinlet damage, +35% Tidal Surge burst"},
        "harbor":{"name":"Harborkeeper","desc":"+15% Gold and +15% Ward capacity"}
    },
    "cindlet": {
        "inferno":{"name":"Inferno","desc":"+50% Cindlet damage versus Guardians"},
        "swift":{"name":"Swiftflame","desc":"Cindlet attacks 30% faster; Ember Frenzy lasts longer"}
    }
}
const SPECIALIZATION_ORDER: Dictionary = {
    "spriglet":["briar","bloom"],
    "brinlet":["riptide","harbor"],
    "cindlet":["inferno","swift"]
}
const CACHE_CHOICES: Dictionary = {
    "gold":{"name":"Golden Cache","desc":"Receive Gold based on current wave"},
    "shards":{"name":"Nest Cache","desc":"Earn permanent Nest Shards"},
    "surge":{"name":"Battle Cache","desc":"+12% pack damage until next Ascension"}
}
const CACHE_ORDER: Array[String] = ["gold","shards","surge"]
var specialization: Dictionary = {"spriglet":"","brinlet":"","cindlet":""}
var caches_pending: int = 0
var caches_claimed: int = 0
var cache_surges: int = 0
var cache_wave_awarded: Dictionary = {}
var guardian_seconds: float = 0.0
var guardian_enraged: bool = false
var combo_hits: int = 0
var combo_window: float = 0.0
var highest_combo: int = 0
var raw_damage_done: float = 0.0
var last_kill_reward: float = 0.0
var last_reward_kind: String = ""
var onboarding_seen: bool = false
var ui_compact: bool = false

func spec_name(kind: String) -> String:
    var current: String = String(specialization.get(kind,""))
    if current == "":
        return "Untrained"
    return String(SPECIALIZATIONS[kind][current]["name"])

func can_specialize(kind: String) -> bool:
    return SPECIES.has(kind) and bool(evolved.get(kind,false)) and int(bonds.get(kind,0)) >= 25

func specialize(kind: String, choice: String) -> bool:
    if not can_specialize(kind) or not SPECIALIZATIONS[kind].has(choice):
        return false
    if String(specialization[kind]) == choice:
        return false
    # Switching after first choice costs earned shards; first choice is free.
    var cost: int = 12 if String(specialization[kind]) != "" else 0
    if nests < cost:
        _report("Need 12 Nest Shards to change this mastery.")
        return false
    nests -= cost
    specialization[kind] = choice
    ward = minf(ward,max_ward())
    _report("%s learned %s! The mastery lasts across Ascensions." % [
        species_name(kind),spec_name(kind)])
    return true

func species_damage(kind: String) -> float:
    var base: float = super.species_damage(kind)
    match String(specialization.get(kind,"")):
        "briar":
            if kind == "spriglet":
                base *= 1.40
        "riptide":
            if kind == "brinlet":
                base *= 1.32
        "inferno":
            if kind == "cindlet" and enemy_is_boss():
                base *= 1.50
    return base * pow(1.12,float(cache_surges))

func attack_interval(kind: String) -> float:
    var interval: float = super.attack_interval(kind)
    if kind == "cindlet" and String(specialization[kind]) == "swift":
        interval *= 0.77
    return maxf(0.12,interval)

func max_ward() -> float:
    var amount: float = super.max_ward()
    if String(specialization["spriglet"]) == "bloom":
        amount *= 1.30
    if String(specialization["brinlet"]) == "harbor":
        amount *= 1.15
    return amount

func wave_reward() -> float:
    var reward: float = super.wave_reward()
    if String(specialization["brinlet"]) == "harbor":
        reward *= 1.15
    return reward

func effective_damage(kind: String) -> float:
    var damage: float = super.effective_damage(kind)
    if kind == "spriglet" and String(specialization[kind]) == "briar" and recent_critical:
        damage *= 1.12
        recent_hit = damage
    return damage

func use_ability(kind: String) -> bool:
    # Parent implements all cooldowns, effects and contract tracking.
    if not SPECIES.has(kind) or int(levels[kind]) < 1 or float(ability_clock[kind]) > 0.0:
        return false
    var earlier_hp: float = enemy_hp
    var result: bool = super.use_ability(kind)
    if not result:
        return false
    if kind == "spriglet" and String(specialization[kind]) == "bloom":
        ward = minf(max_ward(),ward + max_ward()*0.42*0.25)
    elif kind == "brinlet" and String(specialization[kind]) == "riptide":
        var original_burst: float = maxf(0.0,earlier_hp-enemy_hp)
        # Use a deterministic extra attack even if the target has already died.
        attack(maxf(10.0,total_dps()*6.0)*0.35)
    elif kind == "cindlet" and String(specialization[kind]) == "swift":
        frenzy_left += 4.0
    return true

func tap() -> void:
    # Manual engagement rewards timing, but loses its combo after 1.4 seconds.
    combo_hits = mini(40,combo_hits+1) if combo_window > 0.0 else 1
    combo_window = 1.4
    highest_combo = maxi(highest_combo,combo_hits)
    var raw: float = maxf(2.0,total_dps()*0.53)
    var combo_multiplier: float = 1.0 + 0.04*float(mini(25,combo_hits-1))
    tap_damage_last = raw * combo_multiplier
    all_time_taps += 1
    overdrive = minf(100.0,overdrive+0.7)
    attack(tap_damage_last)
    recent_hit = tap_damage_last
    recent_critical = false
    damage_flash = 0.18

func attack(damage: float) -> void:
    if damage > 0.0:
        raw_damage_done += minf(maxf(enemy_hp,0.0),damage)
    super.attack(damage)

func tick(delta: float) -> void:
    var duration: float = clampf(delta,0.0,0.25)*game_speed
    if combo_window > 0.0:
        combo_window = maxf(0.0,combo_window-duration)
        if combo_window <= 0.0:
            combo_hits = 0
    # Guardians become more dangerous in protracted encounters,
    # but this only activates after a generous 18 seconds.
    if enemy_is_boss():
        guardian_seconds += duration
        guardian_enraged = guardian_seconds >= 18.0
    else:
        guardian_seconds = 0.0
        guardian_enraged = false
    super.tick(delta)

func enemy_damage() -> float:
    var normal: float = super.enemy_damage()
    return normal*1.5 if guardian_enraged and enemy_is_boss() else normal

func _enemy_defeated() -> void:
    var defeated_wave: int = wave
    var was_repeat: bool = repeat_wave
    last_kill_reward = wave_reward()
    super._enemy_defeated()
    guardian_seconds = 0.0
    guardian_enraged = false
    if not was_repeat and defeated_wave >= 25 and defeated_wave % 25 == 0:
        var cache_key: String = str(ascensions)+":"+str(defeated_wave)
        if not cache_wave_awarded.has(cache_key):
            cache_wave_awarded[cache_key] = true
            caches_pending += 1
            _report("WILD CACHE discovered! Choose a reward in Goals.")

func claim_cache(choice: String) -> bool:
    if caches_pending < 1 or not CACHE_CHOICES.has(choice):
        return false
    caches_pending -= 1
    caches_claimed += 1
    last_reward_kind = choice
    match choice:
        "gold":
            var grant: float = maxf(80.0,wave_reward()*18.0)
            gold += grant
            lifetime_gold += grant
            _report("Wild Cache: +%s Gold!" % format_number(grant))
        "shards":
            var grant: int = 8+int(best_wave/50)
            nests += grant
            _report("Wild Cache: +%d Nest Shards!" % grant)
        "surge":
            cache_surges = mini(25,cache_surges+1)
            _report("Wild Cache: pack damage grows by 12% this run!")
    return true

func ascend() -> bool:
    var success: bool = super.ascend()
    if success:
        cache_surges = 0
        cache_wave_awarded.clear()
        # Unclaimed caches persist to prevent losing earned reward choices.
        combo_hits = 0
        combo_window = 0.0
        guardian_seconds = 0.0
        guardian_enraged = false
    return success

func _regroup() -> void:
    super._regroup()
    guardian_seconds = 0.0
    guardian_enraged = false

func _spawn_enemy() -> void:
    super._spawn_enemy()
    guardian_seconds = 0.0
    guardian_enraged = false

func to_dict() -> Dictionary:
    var data: Dictionary = super.to_dict()
    data["v04"] = 4
    data["specialization"] = specialization.duplicate(true)
    data["caches_pending"] = caches_pending
    data["caches_claimed"] = caches_claimed
    data["cache_surges"] = cache_surges
    data["cache_wave_awarded"] = cache_wave_awarded.duplicate(true)
    data["highest_combo"] = highest_combo
    data["raw_damage_done"] = raw_damage_done
    data["onboarding_seen"] = onboarding_seen
    data["ui_compact"] = ui_compact
    return data

func load_save() -> bool:
    if not super.load_save():
        return false
    var file: FileAccess = FileAccess.open(SAVE_FILE,FileAccess.READ)
    if file == null:
        return true
    var v: Variant = JSON.parse_string(file.get_as_text())
    if not (v is Dictionary):
        return true
    var data: Dictionary = v
    var specs: Dictionary = data.get("specialization",{})
    for kind in ORDER:
        var choice: String = String(specs.get(kind,""))
        specialization[kind] = choice if SPECIALIZATIONS[kind].has(choice) and can_specialize(kind) else ""
    caches_pending = clampi(int(data.get("caches_pending",0)),0,200)
    caches_claimed = maxi(0,int(data.get("caches_claimed",0)))
    cache_surges = clampi(int(data.get("cache_surges",0)),0,25)
    var awarded: Dictionary = data.get("cache_wave_awarded",{})
    cache_wave_awarded.clear()
    for key in awarded:
        if bool(awarded[key]):
            cache_wave_awarded[String(key)] = true
    highest_combo = maxi(0,int(data.get("highest_combo",0)))
    raw_damage_done = maxf(0.0,float(data.get("raw_damage_done",0.0)))
    onboarding_seen = bool(data.get("onboarding_seen",false))
    ui_compact = bool(data.get("ui_compact",false))
    guardian_seconds = 0.0
    guardian_enraged = false
    combo_hits = 0
    combo_window = 0.0
    return true
