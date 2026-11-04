extends SceneTree
## Dedicated simplified v0.30 acceptance: 3 species, correct triangle, only 1v1,
## gold economy, boss, stage clear, farming, interface and safe persistence.
const ENGINE = preload("res://scripts/duel/duel_engine_v30.gd")
const SCENE = preload("res://scenes/duel/wildbound_duel_v30.tscn")

func _initialize() -> void:
    call_deferred("_run")

func _fail(what: String) -> void:
    push_error("v0.30: "+what)
    quit(1)

func _run() -> void:
    # Never delete an actual player's save during tests. CI project storage
    # is a disposable runner; restore prior test state if it exists.
    var path: String = ENGINE.SAVE_FILE
    var previous: String = ""
    var had: bool = FileAccess.file_exists(path)
    if had:
        previous = FileAccess.get_file_as_string(path)
    var engine: RefCounted = ENGINE.new()
    if engine.ORDER.size() != 3 or engine.SPECIES.size() != 3:
        _fail("Exactly 3 species required");return
    if engine.BEATS != {"Fire":"Earth","Earth":"Water","Water":"Fire"}:
        _fail("Wrong Fire Earth Water triangle");return
    if engine.matchup("cindlet","spriglet") != 2.0 \
            or engine.matchup("spriglet","brinlet") != 2.0 \
            or engine.matchup("brinlet","cindlet") != 2.0:
        _fail("Element advantage no longer correctly doubles damage");return
    if engine.matchup("spriglet","cindlet") != 0.5:
        _fail("Element resistance should halve damage");return
    if engine.start() == false or not engine.fighting:
        _fail("First battle must begin explicitly");return
    var opponent: String = engine.opponent
    if not engine.select_creature("brinlet") or engine.active != "brinlet":
        _fail("Cannot switch active monster during a duel");return
    if not engine.opponent == opponent or engine.enemy_hp != engine.enemy_max_hp:
        _fail("Switching monster should not spawn a new opponent");return
    engine.gold = 5000.0
    var prior: int = int(engine.levels["cindlet"])
    if not engine.level_up("cindlet") or int(engine.levels["cindlet"]) != prior+1:
        _fail("All three individually earn their own levels");return
    if not engine.buy_upgrade("power") or int(engine.upgrades["power"]) != 1:
        _fail("Global Gold upgrades not functional");return
    engine.hit()
    if engine.enemy_hp >= engine.enemy_max_hp:
        _fail("Manual attack did not affect living 1v1 enemy");return
    engine.hit()
    for i in range(700):
        if engine.awaiting_next:
            break
        engine.hit()
    if not engine.awaiting_next or engine.best_stage != 1 or engine.wins != 1:
        _fail("Single opponent should clear exactly one stage");return
    var gold_after_win: float = engine.gold
    if not engine.toggle_farm() or not engine.farming or not engine.fighting:
        _fail("Farming should automatically start a cleared stage");return
    for i in range(700):
        if engine.awaiting_next:
            break
        engine.hit()
    if not engine.awaiting_next or engine.gold <= gold_after_win:
        _fail("Farming Gold reward broken");return
    engine.tick(1.0)
    for i in range(12):
        engine.tick(0.14)
    if not engine.fighting:
        _fail("Farm mode must resume enemy automatically");return
    if not engine.toggle_farm() or engine.farming or engine.stage != 2:
        _fail("Leaving farm must return to push stage");return
    if not engine.is_boss() == false:
        _fail("Stage 2 is not a boss");return
    engine.stage = 5
    engine._spawn()
    if not engine.is_boss() or engine.enemy_max_hp < 100.0:
        _fail("Stage-5 boss must have enhanced health");return
    engine.stage = 20
    engine.best_stage = 20
    engine.highest_run_stage = 21
    engine.ascensions = 0
    engine.bond_xp["cindlet"] = 15
    if not engine.can_ascend() or not engine.ascend():
        _fail("Ascension should unlock after stage 20");return
    if engine.ascensions != 1 or engine.echo != 1 \
            or int(engine.bond_ranks["cindlet"]) != 2 or engine.stage != 1:
        _fail("Ascension must restart the run and permanently raise earned Bond");return
    if not engine.start() or not engine.fighting:
        _fail("After Ascension, battles must start normally");return
    engine.gold = 273.0
    engine.save()
    var restored: RefCounted = ENGINE.new()
    if not restored.load() or restored.gold != 273.0 or restored.ascensions != 1:
        _fail("Persistence loses progress");return
    # The new Godot scene must show actual creature sprites and functional actions.
    var ui: Control = SCENE.instantiate()
    root.add_child(ui)
    await process_frame
    if not ui.ui_live or ui.roster_rows.size() != 3:
        _fail("The final UI must have exactly 3 creature training rows");return
    if ui.hero_art.texture == null or ui.enemy_art.texture == null:
        _fail("Large painted battle creatures did not render");return
    if ui.landscape.texture == null or ui.landscape.size.x < 800:
        _fail("Full scenic battle art is missing");return
    if ui.next_button.text.length() < 8 or ui.menu_active:
        _fail("Core battle action/menu entry broken");return
    ui._open_menu("UPGRADES")
    if not ui.menu_active or ui.upgrade_buttons.size() != 3:
        _fail("Menu must have only 3 working global upgrades");return
    ui._close_menu()
    if ui.menu_active:
        _fail("Menu cannot close");return
    ui.queue_free()
    if had:
        var old: FileAccess = FileAccess.open(path,FileAccess.WRITE)
        if old != null:
            old.store_string(previous)
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("PASS v0.30: exact 3 starters, Fire/Earth/Water, genuine 1v1, switch, levels, farming, boss, prestige, persistence, scenic artwork, UI")
    quit(0)
