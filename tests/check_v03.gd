extends SceneTree
const ENGINE = preload("res://scripts/incremental/v03_engine.gd")
func _initialize() -> void:
    call_deferred("_run")
func _die(problem: String) -> void:
    push_error("WILDBOUND V0.3: " + problem)
    quit(1)
func _run() -> void:
    var g = ENGINE.new()
    g.initialize_alpha()
    if g.stance != "Balanced" or g.contract_target("battles") < 1 or g.camp_cost("pack") < 1:
        _die("Initial v0.3 state invalid")
        return
    var normal: float = g.species_damage("spriglet")
    if not g.set_stance("Feral") or g.species_damage("spriglet") <= normal:
        _die("Feral pack tactic fails to increase damage")
        return
    var feral_damage: float = g.enemy_damage()
    if not g.set_stance("Bulwark") or g.enemy_damage() >= feral_damage:
        _die("Bulwark stance fails to reduce incoming damage")
        return
    if not g.set_stance("Forager") or g.wave_reward() <= 8.0:
        _die("Forager tactic should grant more Gold")
        return
    if g.set_stance("NoSuchStance"):
        _die("Invalid tactic accepted")
        return
    g.set_stance("Balanced")
    var before_tap: float = g.overdrive
    g.tap()
    if g.overdrive <= before_tap or g.all_time_taps != 1:
        _die("Manual attack failed to build resonance")
        return
    g.overdrive = 100.0
    if not g.activate_overdrive() or g.overdrive_used != 1 or g.activate_overdrive():
        _die("Overdrive charge/cooldown gates not enforced")
        return
    if g.species_damage("spriglet") <= normal:
        _die("Active resonance must empower pack damage")
        return
    g.tick(0.2)
    if g.overdrive_left <= 0.0:
        _die("Overdrive should last 12 seconds")
        return
    g.overdrive_left = 0.0
    g.nests = 50
    if not g.buy_camp_upgrade("pack") or g.camp["pack"] != 1:
        _die("Camp construction unavailable")
        return
    if g.species_damage("spriglet") <= normal:
        _die("Camp Pack Lodgings not affecting attack")
        return
    if not g.buy_camp_upgrade("nest") or not g.buy_camp_upgrade("altar"):
        _die("Permanent sanctuary upgrades unavailable")
        return
    for i in range(12):
        g.attack(g.enemy_hp+100)
    if not g.contract_ready("battles"):
        _die("Repeatable battle contract did not track kills")
        return
    var first_target: int = g.contract_target("battles")
    if not g.claim_contract("battles") or g.claim_contract("battles"):
        _die("Contract can be claimed twice")
        return
    if g.contract_target("battles") <= first_target or g.contracts_claimed != 1:
        _die("Next contract tier did not scale")
        return
    g.wave = 10
    g._spawn_enemy()
    g._fit_enemy_to_region()
    g.attack(g.enemy_hp+100)
    if not g.contract_ready("guardians") or not g.claim_contract("guardians"):
        _die("Guardian contract not tracking guardian victories")
        return
    g.ability_clock["spriglet"] = 0.0
    for i in range(4):
        if not g.use_ability("spriglet"):
            _die("Creature ability could not fire")
            return
        g.ability_clock["spriglet"] = 0.0
    if not g.contract_ready("abilities") or not g.claim_contract("abilities"):
        _die("Ability contracts not tracking ability uses")
        return
    g.wave = 14
    g._spawn_enemy()
    g._fit_enemy_to_region()
    var plain_hp: float = g.enemy_max_hp
    g.wave = 14 # armored wave 14
    g._fit_enemy_to_region()
    if g.enemy_mutator() != "Armored" or g.enemy_max_hp < plain_hp*0.99:
        _die("Elite mutator scaling failed")
        return
    g.wave = 20
    g.run_peak = 20
    g.best_wave = 50
    g._spawn_enemy()
    g._fit_enemy_to_region()
    var echoes: int = g.available_echoes()
    if echoes < 1 or not g.ascend() or g.wave != 1:
        _die("Ascension from v0.3 failed")
        return
    if g.camp["pack"] != 1 or g.camp["altar"] != 1 or g.contracts_claimed != 3:
        _die("Ascension should preserve camp and contracts")
        return
    var persisted_stance: String = g.stance
    var baseline: Dictionary = g.to_dict()
    if int(baseline.get("v03",0)) != 3:
        _die("v0.3 save version marker absent")
        return
    if not g.save():
        _die("Cannot save v0.3 alpha")
        return
    var loaded = ENGINE.new()
    loaded.initialize_alpha()
    if not loaded.load_save() or loaded.contracts_claimed != 3 or loaded.camp["pack"] != 1 or loaded.stance != persisted_stance:
        _die("v0.3 save/load lost durable state")
        return
    # Simulate upgrading a v0.2 save in-place. No new data is required.
    var old: Dictionary = baseline.duplicate(true)
    for key in ["v03","stance","overdrive","guardians_won","abilities_used","contracts_claimed","contract_stage","contract_start","camp","all_time_taps","overdrive_used"]:
        old.erase(key)
    old["saved_at"] = Time.get_unix_time_from_system()
    var file: FileAccess = FileAccess.open(ENGINE.SAVE_FILE,FileAccess.WRITE)
    file.store_string(JSON.stringify(old))
    file.close()
    var migrated = ENGINE.new()
    migrated.initialize_alpha()
    if not migrated.load_save() or migrated.camp["pack"] != 0 or migrated.contracts_claimed != 0 or migrated.stance != "Balanced":
        _die("v0.2 save migration failed")
        return
    # Base tests share a user:// path. Clean fixtures prior to visual render.
    DirAccess.remove_absolute(ProjectSettings.globalize_path(ENGINE.SAVE_FILE))
    var packed: PackedScene = load("res://scenes/incremental/wildbound_alpha.tscn") as PackedScene
    if packed == null:
        _die("Game scene not found")
        return
    var screen: Control = packed.instantiate() as Control
    root.add_child(screen)
    if screen.get_node_or_null("stance_Feral") == null or screen.get_node_or_null("Resonance") == null:
        _die("Tactic and resonance controls not on screen")
        return
    screen.get_node("stance_Feral").emit_signal("pressed")
    if screen.game.stance != "Feral":
        _die("Visual formation button does not change gameplay")
        return
    screen.call("_switch_tab","GOALS")
    var contracts: int = 0
    for row in screen.right_rows:
        if row.get("mode","") == "contract":
            contracts += 1
    if contracts != 3:
        _die("Repeatable contracts missing from GOALS tab")
        return
    screen.call("_switch_tab","NEST")
    var camps: int = 0
    for row in screen.right_rows:
        if row.get("mode","") == "camp":
            camps += 1
    if camps != 3:
        _die("Permanent sanctuary upgrades missing from NEST tab")
        return
    print("PASS v0.3: tactics, overdrive, elites, contracts, camp, permanent Ascension, v0.2 migration, live UI buttons")
    quit(0)
