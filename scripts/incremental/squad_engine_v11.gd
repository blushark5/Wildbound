extends "res://scripts/incremental/challenge_engine_v10.gd"
## Wildbound v0.11: genuine six-unit, auto-targeting trainer encounters.
## Progression/loot/Ascension remain in the proven v0.10 engine.
## One owned species may fill several slots in this prototype. Species levels,
## genes, evolutions and relics affect every copy in a player's squad.

const SQUAD_SIZE: int = 3
const STAGE_ROSTERS: Array = [
    ["brinlet","brinlet","brinlet"],
    ["brinlet","spriglet","brinlet"],
    ["cindlet","cindlet","cindlet"],
    ["spriglet","brinlet","cindlet"],
    ["spriglet","spriglet","spriglet"],
    ["cindlet","brinlet","cindlet"],
    ["brinlet","brinlet","cindlet"],
    ["spriglet","brinlet","cindlet"],
    ["cindlet","spriglet","cindlet"],
    ["spriglet","brinlet","cindlet"]
]
const ELEMENT_MULTIPLIER_STRONG: float = 2.0
const ELEMENT_MULTIPLIER_WEAK: float = 0.45

var squad_slots: Array[String] = ["spriglet","spriglet","spriglet"]
var ally_units: Array[Dictionary] = []
var rival_units: Array[Dictionary] = []
var trainer_wins: int = 0
var combat_revision: int = 0
var last_clash: String = "Your three creatures will automatically seek favorable targets."

func initialize_squads() -> void:
    for i in range(SQUAD_SIZE):
        var kind: String = squad_slots[i]
        if not SPECIES.has(kind) or int(levels.get(kind,0)) < 1:
            squad_slots[i] = "spriglet"
    _setup_trainer_fight()

func roster_for(stage: int) -> Array:
    return STAGE_ROSTERS[(maxi(1,stage)-1)%STAGE_ROSTERS.size()].duplicate()

func multiplier(attacker_kind: String, defender_kind: String) -> float:
    var a: String = String(SPECIES[attacker_kind]["element"])
    var b: String = String(SPECIES[defender_kind]["element"])
    if String(COUNTERS[a]) == b:
        return ELEMENT_MULTIPLIER_STRONG
    if String(COUNTERS[b]) == a:
        return ELEMENT_MULTIPLIER_WEAK
    return 1.0

func _new_ally(kind: String, index: int) -> Dictionary:
    var cap: float = max_ward()/float(SQUAD_SIZE)
    return {"kind":kind,"hp":cap,"max_hp":cap,"clock":0.0,
        "target":-1,"slot":index,"flash":0.0}

func _new_rival(kind: String,index: int) -> Dictionary:
    # Calculate a deterministic base rather than reusing enemy_max_hp:
    # that compatibility field is the SUM of the current trio, and
    # reusing it would inflate HP every time a player changed a slot.
    var base: float = 18.0*pow(1.185,float(wave-1))
    base *= 4.0 if enemy_is_boss() else 1.0
    base *= float(_region_data()["hp"])*(2.0 if overclock else 1.0)
    base *= challenge_multiplier()
    if enemy_mutator() == "Armored":
        base *= 1.65
    var per_unit: float = maxf(5.0,base*(0.19 if enemy_is_boss() else 0.75))
    return {"kind":kind,"hp":per_unit,"max_hp":per_unit,"clock":0.0,
        "target":-1,"slot":index,"flash":0.0}

func _setup_trainer_fight() -> void:
    focused_companion = squad_slots[0]
    ally_units.clear()
    rival_units.clear()
    for i in range(SQUAD_SIZE):
        ally_units.append(_new_ally(squad_slots[i],i))
        rival_units.append(_new_rival(String(roster_for(wave)[i]),i))
    _sync_health()
    _refresh_ai_targets()
    combat_revision += 1

func _sync_health() -> void:
    ward = 0.0
    enemy_hp = 0.0
    enemy_max_hp = 0.0
    for unit in ally_units:
        ward += maxf(0.0,float(unit["hp"]))
    for unit in rival_units:
        enemy_hp += maxf(0.0,float(unit["hp"]))
        enemy_max_hp += float(unit["max_hp"])

func party_max_hp() -> float:
    var sum: float = 0.0
    for unit in ally_units:
        sum += float(unit["max_hp"])
    return maxf(1.0,sum)

func _living(units: Array[Dictionary]) -> int:
    var count: int = 0
    for unit in units:
        if float(unit["hp"]) > 0.0:
            count += 1
    return count

func ally_alive() -> int:
    return _living(ally_units)

func rival_alive() -> int:
    return _living(rival_units)

func _pick_target(attacker: String, enemies: Array[Dictionary]) -> int:
    var best: int = -1
    var score: float = -INF
    for i in range(enemies.size()):
        var target: Dictionary = enemies[i]
        if float(target["hp"]) <= 0.0:
            continue
        # Matchups dominate. Within a matchup finish the weakest opponent,
        # so after a knockout attackers naturally retarget to the next best.
        var element_score: float = multiplier(attacker,String(target["kind"]))*1000.0
        var finish_score: float = (1.0-float(target["hp"])/maxf(1.0,float(target["max_hp"])))*70.0
        var proposed: float = element_score+finish_score-float(i)*0.01
        if proposed > score:
            score = proposed
            best = i
    return best

func _refresh_ai_targets() -> void:
    for i in range(ally_units.size()):
        var chosen: int = _pick_target(String(ally_units[i]["kind"]),rival_units) if float(ally_units[i]["hp"]) > 0.0 else -1
        ally_units[i]["target"] = chosen
    for i in range(rival_units.size()):
        var chosen: int = _pick_target(String(rival_units[i]["kind"]),ally_units) if float(rival_units[i]["hp"]) > 0.0 else -1
        rival_units[i]["target"] = chosen

func cycle_slot(index: int) -> bool:
    if index < 0 or index >= SQUAD_SIZE or awaiting_next == false and ally_alive() < SQUAD_SIZE:
        # Don't revive a fallen creature by swapping it mid-trainer-battle.
        return false
    var current: String = squad_slots[index]
    var next: String = current
    var offset: int = ORDER.find(current)
    for skip in range(1,ORDER.size()+1):
        var candidate: String = String(ORDER[(offset+skip)%ORDER.size()])
        if int(levels.get(candidate,0)) > 0:
            next = candidate
            break
    if next == current:
        _report("Recruit another species first! Any recruited species can fill multiple squad slots.")
        return false
    squad_slots[index] = next
    _setup_trainer_fight()
    _report("SQUAD SLOT %d: %s. Your team now changes targets automatically." % [index+1,species_name(next)])
    return true

func squad_dps() -> float:
    var combined: float = 0.0
    for unit in ally_units:
        if float(unit["hp"]) <= 0.0:
            continue
        var target: int = _pick_target(String(unit["kind"]),rival_units)
        if target < 0:
            continue
        combined += species_damage(String(unit["kind"]))*multiplier(
            String(unit["kind"]),String(rival_units[target]["kind"]))/attack_interval(String(unit["kind"]))
    return combined

func battle_dps() -> float:
    return squad_dps()

func total_dps() -> float:
    var sum: float = 0.0
    for unit in ally_units:
        if float(unit["hp"]) > 0.0:
            sum += species_damage(String(unit["kind"]))/attack_interval(String(unit["kind"]))
    return sum

func _ally_hit(index: int) -> void:
    if index < 0 or index >= ally_units.size() or awaiting_next:
        return
    var attacker: Dictionary = ally_units[index]
    if float(attacker["hp"]) <= 0.0:
        return
    var target: int = _pick_target(String(attacker["kind"]),rival_units)
    if target < 0:
        return
    var kind: String = String(attacker["kind"])
    var victim: String = String(rival_units[target]["kind"])
    var damage: float = species_damage(kind)*multiplier(kind,victim)
    if enemy_is_boss():
        damage *= 1.0+0.20*float(int(modules.get("pierce",0)))
        if equipped_relics.has("sigil"):
            damage *= pow(1.25,float(int(relic_ranks["sigil"])))
    recent_critical = _rng.randf() < minf(0.70,0.05+float(int(modules.get("crit",0)))*0.035)
    if recent_critical:
        damage *= 2.5
    recent_hit = damage
    damage_flash = 0.16
    attacker["target"] = target
    _damage_rival(target,damage,kind)

func _rival_hit(index: int) -> void:
    if index < 0 or index >= rival_units.size() or awaiting_next:
        return
    var attacker: Dictionary = rival_units[index]
    if float(attacker["hp"]) <= 0.0:
        return
    var target: int = _pick_target(String(attacker["kind"]),ally_units)
    if target < 0:
        return
    var attack_type: String = String(attacker["kind"])
    var defense_type: String = String(ally_units[target]["kind"])
    var guardian_scale: float = 0.47 if enemy_is_boss() else 1.90
    var amount: float = enemy_damage()*guardian_scale*multiplier(attack_type,defense_type)
    attacker["target"] = target
    ally_units[target]["hp"] = maxf(0.0,float(ally_units[target]["hp"])-amount)
    ally_units[target]["flash"] = 0.18
    if float(ally_units[target]["hp"]) <= 0.0:
        last_clash = "%s was knocked out! The remaining squad keeps fighting." % species_name(defense_type)
    _sync_health()
    _refresh_ai_targets()
    if ally_alive() == 0:
        _regroup()

func _damage_rival(index: int,damage: float,source: String) -> void:
    if damage <= 0.0 or index < 0 or index >= rival_units.size():
        return
    var hit: Dictionary = rival_units[index]
    var before: float = float(hit["hp"])
    hit["hp"] = maxf(0.0,before-damage)
    hit["flash"] = 0.16
    raw_damage_done += minf(before,damage)
    if float(hit["hp"]) <= 0.0 and before > 0.0:
        last_clash = "%s defeated %s! Targets are being reassigned." % [
            species_name(source),String(SPECIES[String(hit["kind"])]["name"])]
    _sync_health()
    _refresh_ai_targets()
    if rival_alive() == 0:
        _enemy_defeated()

func attack(damage: float) -> void:
    if awaiting_next or rival_alive() == 0:
        return
    # Manual tap and burst abilities follow the best available target, but
    # individual auto-attackers target independently.
    var source: String = focused_companion
    if not squad_slots.has(source):
        source = squad_slots[0]
    var target: int = _pick_target(source,rival_units)
    if target >= 0:
        _damage_rival(target,damage,source)

func use_ability(kind: String) -> bool:
    if awaiting_next:
        return false
    var present: bool = false
    for unit in ally_units:
        if String(unit["kind"]) == kind and float(unit["hp"]) > 0.0:
            present = true
            break
    if not present:
        _report("Place a living %s in the squad to use this ability." % String(SPECIES[kind]["name"]))
        return false
    var old_hp: float = ward
    var success: bool = super.use_ability(kind)
    if success and kind == "spriglet":
        var healing: float = maxf(0.0,ward-old_hp)
        _heal_allies(healing)
    return success

func _heal_allies(amount: float) -> void:
    # Heal the most injured surviving teammate first. KO cannot be bypassed
    # by using a heal skill, but the living squad becomes harder to wipe.
    var remaining: float = amount
    for pass_index in range(SQUAD_SIZE):
        var worst: int = -1
        var fraction: float = 1.01
        for i in range(ally_units.size()):
            var unit: Dictionary = ally_units[i]
            if float(unit["hp"]) > 0.0 and float(unit["hp"]) < float(unit["max_hp"]):
                var ratio: float = float(unit["hp"])/float(unit["max_hp"])
                if ratio < fraction:
                    fraction = ratio
                    worst = i
        if worst < 0 or remaining <= 0.0:
            break
        var unit: Dictionary = ally_units[worst]
        var gained: float = minf(remaining,float(unit["max_hp"])-float(unit["hp"]))
        unit["hp"] = float(unit["hp"])+gained
        remaining -= gained
    _sync_health()

func tick(delta: float) -> void:
    if awaiting_next or ally_units.size() != SQUAD_SIZE or rival_units.size() != SQUAD_SIZE:
        return
    # Real-time six-unit combat. Unlike the old engine, there's no second
    # invisible single-enemy simulator that could cause phantom rewards.
    var dt: float = clampf(delta,0.0,0.25)*game_speed
    total_seconds += dt
    battle_seconds += dt
    overdrive_left = maxf(0.0,overdrive_left-dt)
    frenzy_left = maxf(0.0,frenzy_left-dt)
    damage_flash = maxf(0.0,damage_flash-dt)
    if combo_window > 0.0:
        combo_window = maxf(0.0,combo_window-dt)
        if combo_window <= 0.0:
            combo_hits = 0
    if enemy_is_boss():
        guardian_seconds += dt
        guardian_enraged = guardian_seconds >= 18.0
    else:
        guardian_seconds = 0.0
        guardian_enraged = false
    for kind in ORDER:
        ability_clock[kind] = maxf(0.0,float(ability_clock[kind])-dt)
    for u in ally_units:
        u["flash"] = maxf(0.0,float(u["flash"])-dt)
    for u in rival_units:
        u["flash"] = maxf(0.0,float(u["flash"])-dt)
    _regen_clock += dt
    if _regen_clock >= 0.25:
        var segments: int = mini(10,int(_regen_clock/0.25))
        _regen_clock -= float(segments)*0.25
        var healing: float = party_max_hp()*0.0025*(1.0+float(int(modules.get("recovery",0)))*0.7)*float(segments)
        if stance == "Bulwark":
            healing *= 2.0
        _heal_allies(healing)

    for i in range(ally_units.size()):
        var unit: Dictionary = ally_units[i]
        if float(unit["hp"]) <= 0.0:
            continue
        unit["clock"] = float(unit["clock"])+dt
        var interval: float = attack_interval(String(unit["kind"]))
        if float(unit["clock"]) >= interval:
            unit["clock"] = float(unit["clock"])-interval
            _ally_hit(i)
            if awaiting_next:
                return

    for i in range(rival_units.size()):
        var unit: Dictionary = rival_units[i]
        if float(unit["hp"]) <= 0.0:
            continue
        unit["clock"] = float(unit["clock"])+dt
        var interval: float = maxf(0.65,float(SPECIES[String(unit["kind"])]["interval"])*1.9)
        if float(unit["clock"]) >= interval:
            unit["clock"] = float(unit["clock"])-interval
            _rival_hit(i)
            if awaiting_next:
                return
    _automation_clock += dt
    if _automation_clock >= 1.0:
        _automation_clock = 0.0
        if auto_skills and int(research.get("instinct",0)) > 0:
            if ward < party_max_hp()*0.7:
                use_ability("spriglet")
            if enemy_is_boss():
                use_ability("brinlet")
            use_ability("cindlet")
        if auto_buy and int(research.get("automation",0)) > 0:
            automate_purchase()

func _enemy_defeated() -> void:
    # One trainer battle pays exactly ONE stage reward, despite three KOs.
    var active: Dictionary = {}
    for kind in squad_slots:
        active[kind] = true
    var before_bonds: Dictionary = bonds.duplicate()
    var before_evolved: Dictionary = evolved.duplicate()
    trainer_wins += 1
    super._enemy_defeated()
    # Bonds go to participants only. Non-fielded owned species don't level
    # their bond or evolve for free while sitting in the collection.
    for kind in ORDER:
        if not active.has(kind):
            bonds[kind] = int(before_bonds[kind])
            evolved[kind] = bool(before_evolved[kind])
    _setup_trainer_fight()
    last_clash = "TRAINER DEFEATED! Choose NEXT STAGE or FARM to strengthen the squad."

func _regroup() -> void:
    # Preserve the wall. A loss allows a retry or farming the prior stage,
    # rather than silently throwing the player four encounters backward.
    var failed_stage: int = wave
    defeats += 1
    current_streak = 0
    wave = failed_stage
    last_stage_cleared = maxi(0,failed_stage-1)
    awaiting_next = true
    repeat_wave = false
    _spawn_enemy()
    _fit_enemy_to_region()
    _setup_trainer_fight()
    _report("SQUAD WIPED AT STAGE %d. RETRY or FARM the previous stage to prepare." % failed_stage)
    last_clash = "SQUAD DEFEATED • Change your three-slot lineup and counter the rival team."

func enter_next_stage() -> bool:
    var result: bool = super.enter_next_stage()
    if result:
        _setup_trainer_fight()
    return result

func set_farming() -> bool:
    var before_stage: int = wave
    var result: bool = super.set_farming()
    if result and (before_stage != wave or not awaiting_next):
        _setup_trainer_fight()
    return result

func select_region(key: String) -> bool:
    var was: String = region
    var ok: bool = super.select_region(key)
    if ok and was != region:
        _setup_trainer_fight()
    return ok

func buy_levels(kind: String, amount: int = 1) -> bool:
    var result: bool = super.buy_levels(kind,amount)
    if result and ally_units.size() == SQUAD_SIZE:
        # Level changes squad damage immediately; maximum HP follows Ward.
        _rescale_ally_max()
    return result

func buy_module(kind: String) -> bool:
    var result: bool = super.buy_module(kind)
    if result and ally_units.size() == SQUAD_SIZE:
        _rescale_ally_max()
    return result

func _rescale_ally_max() -> void:
    var cap: float = max_ward()/float(SQUAD_SIZE)
    for unit in ally_units:
        var ratio: float = float(unit["hp"])/maxf(1.0,float(unit["max_hp"]))
        unit["max_hp"] = cap
        unit["hp"] = cap*ratio
    _sync_health()

func ascend() -> bool:
    var ok: bool = super.ascend()
    if ok:
        _setup_trainer_fight()
    return ok

func to_dict() -> Dictionary:
    var data: Dictionary = super.to_dict()
    data["v11_squad_slots"] = squad_slots.duplicate()
    data["v11_ally_units"] = ally_units.duplicate(true)
    data["v11_rival_units"] = rival_units.duplicate(true)
    data["v11_trainer_wins"] = trainer_wins
    return data

func load_save() -> bool:
    var success: bool = super.load_save()
    if not success:
        initialize_squads()
        return false
    var file: FileAccess = FileAccess.open(SAVE_FILE,FileAccess.READ)
    if file == null:
        initialize_squads()
        return true
    var raw: Variant = JSON.parse_string(file.get_as_text())
    if raw is Dictionary:
        var data: Dictionary = raw
        var saved_slots: Array = data.get("v11_squad_slots",[])
        if saved_slots.size() == SQUAD_SIZE:
            for i in range(SQUAD_SIZE):
                var kind: String = String(saved_slots[i])
                if SPECIES.has(kind) and int(levels[kind]) > 0:
                    squad_slots[i] = kind
        trainer_wins = maxi(0,int(data.get("v11_trainer_wins",0)))
        initialize_squads()
        var saved_allies: Array = data.get("v11_ally_units",[])
        var saved_rivals: Array = data.get("v11_rival_units",[])
        if saved_allies.size() == SQUAD_SIZE and saved_rivals.size() == SQUAD_SIZE and not awaiting_next:
            for i in range(SQUAD_SIZE):
                if saved_allies[i] is Dictionary and saved_rivals[i] is Dictionary:
                    # Preserve attrition and individual clock progress, but
                    # validate team species against loaded squad composition.
                    if String(saved_allies[i].get("kind","")) == squad_slots[i] and String(saved_rivals[i].get("kind","")) == String(rival_units[i]["kind"]):
                        ally_units[i]["hp"] = clampf(float(saved_allies[i].get("hp",ally_units[i]["hp"])),0.0,float(ally_units[i]["max_hp"]))
                        rival_units[i]["hp"] = clampf(float(saved_rivals[i].get("hp",rival_units[i]["hp"])),0.0,float(rival_units[i]["max_hp"]))
                        ally_units[i]["clock"] = clampf(float(saved_allies[i].get("clock",0.0)),0.0,2.0)
                        rival_units[i]["clock"] = clampf(float(saved_rivals[i].get("clock",0.0)),0.0,3.0)
    else:
        initialize_squads()
    _sync_health()
    _refresh_ai_targets()
    return true
