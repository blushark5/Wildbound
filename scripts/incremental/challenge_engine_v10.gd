extends "res://scripts/incremental/journey_engine_v09.gd"
## v0.10: Player-controlled stage advancement, real counterplay and earlier walls.
## Inherits the complete economy and saves; no duplicate combat simulation.

const FOCUS_MAIN: float = 1.85
const FOCUS_SUPPORT: float = 0.60
const COUNTERS: Dictionary = {"Grove":"Tide","Tide":"Ember","Ember":"Grove"}

var focused_companion: String = "spriglet"
var awaiting_next: bool = false
var auto_advance_enabled: bool = false
var last_stage_cleared: int = 0

func challenge_multiplier(level: int = -1) -> float:
    var stage: int = wave if level < 1 else level
    var early: int = mini(maxi(stage-3,0),7)
    var late: int = maxi(stage-10,0)
    return pow(1.16,float(early))*pow(1.12,float(late))

func _fit_enemy_to_region() -> void:
    # Parent always rebuilds HP from base stats, so difficulty never compounds
    # when a region is changed or the enemy is reinitialized mid-fight.
    super._fit_enemy_to_region()
    var ratio: float = clampf(enemy_hp/maxf(enemy_max_hp,1.0),0.0,1.0)
    enemy_max_hp *= challenge_multiplier()
    enemy_hp = maxf(1.0,enemy_max_hp*ratio)

func enemy_damage() -> float:
    return super.enemy_damage()*(1.0+0.065*float(maxi(0,wave-3)))

func wave_reward() -> float:
    # Extra revenue supports farming after a wall without flattening difficulty.
    return super.wave_reward()*pow(1.055,float(maxi(0,wave-3)))

func effective_damage(kind: String) -> float:
    var amount: float = super.effective_damage(kind)
    return amount*(FOCUS_MAIN if kind == focused_companion else FOCUS_SUPPORT)

func battle_dps() -> float:
    var amount: float = 0.0
    for kind in ORDER:
        if int(levels[kind]) > 0:
            amount += effective_damage(kind)/attack_interval(kind)
    return amount

func element_relation(kind: String) -> String:
    var attacker: String = String(SPECIES[kind]["element"])
    var target: String = String(SPECIES[enemy_species]["element"])
    if String(COUNTERS.get(attacker,"")) == target:
        return "SUPER EFFECTIVE • 1.5x"
    if String(COUNTERS.get(target,"")) == attacker:
        return "RESISTED • 0.75x"
    return "NEUTRAL • 1.0x"

func focus(kind: String) -> bool:
    if not SPECIES.has(kind) or int(levels[kind]) < 1:
        return false
    focused_companion = kind
    _report("FOCUS: %s. %s. Focused ally deals 1.85x, supports 0.60x." % [
        species_name(kind),element_relation(kind)])
    return true

func auto_advance_unlocked() -> bool:
    return ascensions >= 1

func toggle_auto_advance() -> bool:
    if not auto_advance_unlocked():
        _report("AUTO ADVANCE unlocks with your first Ascension. Choose every stage until then.")
        return false
    auto_advance_enabled = not auto_advance_enabled
    if auto_advance_enabled and awaiting_next:
        awaiting_next = false
    _report("AUTO ADVANCE %s. You can switch back to manual at any time." % ("ON" if auto_advance_enabled else "OFF"))
    return true

func enter_next_stage() -> bool:
    if not awaiting_next:
        return false
    awaiting_next = false
    _report("ENTERING STAGE %d • %s. Focus the best elemental counter." % [
        wave,species_name(enemy_species)])
    return true

func set_farming() -> bool:
    if awaiting_next:
        # The cleared stage is a safe, reusable farming spot. It may be
        # replayed for Gold and bonds instead of entering a harder stage.
        wave = maxi(1,wave-1)
        repeat_wave = true
        awaiting_next = false
        _spawn_enemy()
        _fit_enemy_to_region()
        _report("FARMING STAGE %d. Collect Gold and bonds, then select PUSH." % wave)
        return true
    repeat_wave = not repeat_wave
    _report("FARMING STAGE %d." % wave if repeat_wave else "PUSH MODE: The next clear will unlock a harder stage.")
    return true

func _enemy_defeated() -> void:
    var stage: int = wave
    var farming: bool = repeat_wave
    super._enemy_defeated()
    if not farming and not auto_advance_enabled:
        last_stage_cleared = stage
        awaiting_next = true
        _report("STAGE %d CLEARED! Tap NEXT STAGE to push, or FARM for Gold and bonds." % stage)

func attack(damage: float) -> void:
    if awaiting_next:
        return
    super.attack(damage)

func tap() -> void:
    if awaiting_next:
        return
    super.tap()

func use_ability(kind: String) -> bool:
    if awaiting_next:
        return false
    return super.use_ability(kind)

func tick(delta: float) -> void:
    # Prevent all auto-attacks and enemy retaliation while waiting for
    # the explicit next-stage decision; the pause persists through saves.
    if awaiting_next:
        return
    super.tick(delta)

func _regroup() -> void:
    var defeated_at: int = wave
    super._regroup()
    awaiting_next = false
    _report("WALL AT STAGE %d: You retreated. Level creatures, choose a counter, improve Ward, or FARM." % defeated_at)

func ascend() -> bool:
    var result: bool = super.ascend()
    if result:
        awaiting_next = false
        repeat_wave = false
        # First Ascension unlocks optional automation; it starts OFF.
        auto_advance_enabled = false
    return result

func to_dict() -> Dictionary:
    var data: Dictionary = super.to_dict()
    data["v10_focus"] = focused_companion
    data["v10_awaiting_next"] = awaiting_next
    data["v10_auto_advance"] = auto_advance_enabled
    data["v10_last_stage"] = last_stage_cleared
    return data

func load_save() -> bool:
    var ok: bool = super.load_save()
    if not ok:
        return false
    var file: FileAccess = FileAccess.open(SAVE_FILE,FileAccess.READ)
    if file == null:
        return true
    var raw: Variant = JSON.parse_string(file.get_as_text())
    if raw is Dictionary:
        var data: Dictionary = raw
        var preferred: String = String(data.get("v10_focus","spriglet"))
        focused_companion = preferred if SPECIES.has(preferred) and int(levels[preferred]) > 0 else "spriglet"
        awaiting_next = bool(data.get("v10_awaiting_next",false))
        auto_advance_enabled = bool(data.get("v10_auto_advance",false)) and auto_advance_unlocked()
        last_stage_cleared = maxi(0,int(data.get("v10_last_stage",0)))
        if auto_advance_enabled:
            awaiting_next = false
    _fit_enemy_to_region()
    return true
