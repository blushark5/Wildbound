extends SceneTree
const ENGINE = preload("res://scripts/incremental/engine.gd")
func _initialize() -> void:
    call_deferred("_test")
func fail(message: String) -> void:
    push_error("WILDBOUND INCREMENTAL TEST: "+message)
    quit(1)
func _test() -> void:
    var engine = ENGINE.new()
    if engine.wave != 1 or engine.gold != 0.0 or engine.total_dps() <= 0.0:
        fail("Invalid initial battle state")
        return
    for i in range(7):
        engine.attack(engine.enemy_hp+1.0)
    if engine.wave != 8 or engine.gold < 48.0:
        fail("Auto-wave kills or gold curve invalid")
        return
    if not engine.buy_levels("brinlet",1):
        fail("Second creature cannot be recruited after several kills")
        return
    if engine.total_dps() <= engine.species_damage("spriglet")/engine.attack_interval("spriglet"):
        fail("Recruited creature has no DPS")
        return
    engine.repeat_wave = true
    for i in range(65):
        engine.attack(engine.enemy_hp+1.0)
    if engine.wave != 8 or int(engine.bonds["spriglet"]) < 25:
        fail("Repeat farming or persistent bonding failed")
        return
    if not engine.buy_levels("spriglet",14):
        fail("First evolution upgrade pacing insufficient")
        return
    if not engine.evolved["spriglet"]:
        fail("First creature did not evolve at level 15 and 25 bonds")
        return
    engine.repeat_wave = false
    while engine.wave < 22:
        engine.attack(engine.enemy_hp+1.0)
    if engine.available_echoes() < 1:
        fail("Prestige did not unlock")
        return
    if not engine.ascend():
        fail("Ascension rejected")
        return
    if engine.wave != 1 or engine.gold != 0.0 or not engine.evolved["spriglet"] or engine.levels["brinlet"] != 1:
        fail("Ascension failed to reset the run while preserving creatures/evolutions")
        return
    if not engine.buy_research("might"):
        fail("Permanent Echo research unavailable")
        return
    if not engine.save():
        fail("Save game failed")
        return
    var loaded = ENGINE.new()
    if not loaded.load_save() or not loaded.evolved["spriglet"] or loaded.research["might"] != 1 or loaded.ascensions != 1:
        fail("Save/load lost permanent creature progression")
        return
    loaded.wave = 2
    loaded._spawn_enemy()
    if loaded.effective_damage("spriglet") <= loaded.species_damage("spriglet"):
        fail("Grove advantage against Tide enemy not applied")
        return
    # The visual-QA step should render an actual fresh-start session, not the
    # intentionally advanced/saved fixture from this progression regression test.
    DirAccess.remove_absolute(ProjectSettings.globalize_path(ENGINE.SAVE_FILE))
    var ui: PackedScene = load("res://scenes/incremental/wildbound_idle.tscn") as PackedScene
    if ui == null:
        fail("Reboot UI scene missing")
        return
    var instance: Control = ui.instantiate() as Control
    root.add_child(instance)
    if instance.get_node_or_null("buy_spriglet") == null or instance.get_node_or_null("ascend") == null:
        fail("Required live UI controls absent")
        return
    print("PASS: waves, recruitment, DPS, repetition, evolution, prestige, permanent research, save/load, live UI")
    quit(0)
