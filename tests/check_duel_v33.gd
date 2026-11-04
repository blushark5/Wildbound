extends SceneTree
## v0.33: prove that cosmetic clarity changes do not alter core combat.
const SCENE = preload("res://scenes/duel/wildbound_duel_v33.tscn")
const ENGINE = preload("res://scripts/duel/duel_engine_v30.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(why: String) -> void:
    push_error("v0.33: "+why)
    quit(1)

func _run() -> void:
    var path: String = ENGINE.SAVE_FILE
    var had: bool = FileAccess.file_exists(path)
    var prior: String = FileAccess.get_file_as_string(path) if had else ""
    var ui: Control = SCENE.instantiate()
    root.add_child(ui)
    await process_frame
    if not ui.ui_live or not ui.polish32_ready or not ui.clarity33_ready:
        _fail("Current UI hierarchy failed to load");return
    if ui.game.SPECIES.size() != 3 or ui.roster_rows.size() != 3:
        _fail("Scope must remain three species");return
    if ui.auto_badge33 == null or ui.hero_damage_tail33 == null \
            or ui.enemy_damage_tail33 == null:
        _fail("Readability controls missing");return
    ui.game.new_game()
    ui._refresh()
    if not ui.game.start():
        _fail("Battle no longer starts");return
    ui._refresh()
    if ui.auto_text33.text != "AUTO ATTACK ON":
        _fail("Automatic combat is not identified");return
    if not ui.next_button.text.contains("TAP TO ATTACK"):
        _fail("Manual assist control is unclear");return
    var hp: float = ui.game.enemy_hp
    ui._manual_hit()
    if ui.game.enemy_hp >= hp:
        _fail("Manual strike did not cause damage");return
    if ui.enemy_damage_tail33.size.x <= ui.enemy_hp_bar.size.x:
        _fail("Enemy damage trail does not show recent damage");return
    ui._process(0.10)
    if ui.enemy_damage_tail33.size.x < ui.enemy_hp_bar.size.x:
        _fail("Enemy damage trail must never underfill actual HP");return
    ui.game.stage = 5
    ui.game._spawn()
    ui.game.fighting = true
    ui.game.awaiting_next = false
    ui._refresh()
    if not ui.game.is_boss():
        _fail("Guardian stage broken");return
    if ui.stage_ribbon32.position.y+ui.stage_ribbon32.size.y > 260.0:
        _fail("Guardian introduction still obscures the active creature");return
    if ui.game.farming and ui.game.best_stage < 1:
        _fail("Farming stage rules changed");return
    ui._open_menu("UPGRADES")
    if not ui.menu_active or ui.upgrade_buttons.size() != 3:
        _fail("Upgrades menu must still function");return
    ui._close_menu()
    ui.queue_free()
    if had:
        var old: FileAccess = FileAccess.open(path,FileAccess.WRITE)
        if old != null:
            old.store_string(prior)
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("PASS v0.33: manual/auto clarity, unobstructed guardian intro, delayed health damage and unchanged 1v1")
    quit(0)
