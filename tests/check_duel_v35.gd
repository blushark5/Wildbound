extends SceneTree
## v0.35 live-scene acceptance -- preserves the proven v0.30 battle engine.
const SCENE = preload("res://scenes/duel/wildbound_duel_v35.tscn")
const ENGINE = preload("res://scripts/duel/duel_engine_v30.gd")
const ART = preload("res://scripts/duel/premium_art_v35.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("v0.35: "+message)
    quit(1)

func _run() -> void:
    var save_path: String = ENGINE.SAVE_FILE
    var existed: bool = FileAccess.file_exists(save_path)
    var old: String = FileAccess.get_file_as_string(save_path) if existed else ""
    var ui: Control = SCENE.instantiate()
    root.add_child(ui)
    await process_frame
    if not ui.premium35_ready or ART.environment() == null:
        _fail("Premium art did not load");return
    if not (ui.get_node("Tagline") as Label).text.contains("v0.35"):
        _fail("Incorrect displayed version");return
    if ui.roster_rows.size() != 3 or ui.game.SPECIES.size() != 3:
        _fail("Exactly three families required");return
    if ui.landscape.position != Vector2.ZERO or ui.landscape.size != Vector2(1280,720):
        _fail("Battlefield must be full-bleed raster artwork");return
    if (ui.get_node("TrainingPanel") as Panel).visible:
        _fail("Legacy training sidebar must not obscure artwork");return
    if ui.team_buttons35.size() != 3 or ui.level_button35 == null:
        _fail("Missing real interactive team or training controls");return
    for kind in ENGINE.ORDER:
        if ART.creature(kind) == null:
            _fail("Missing full-body creature for "+kind);return
        if ART.creature(kind).get_width() < 180:
            _fail("Creature raster insufficient: "+kind);return
    if ENGINE.SAVE_FILE != "user://wildbound_duel_v30.json":
        _fail("Browser save namespace changed");return
    ui.game.new_game()
    ui._refresh()
    if not ui.game.start():
        _fail("Could not begin new duel");return
    var hp: float = ui.game.enemy_hp
    ui._manual_hit()
    if ui.game.enemy_hp >= hp:
        _fail("Manual attack no longer works");return
    for i in range(500):
        if ui.game.awaiting_next:
            break
        ui.game.hit()
    if ui.game.wins != 1 or not ui.victory31.visible:
        _fail("Victory must display after actual combat");return
    ui._primary_action()
    if ui.game.stage != 2:
        _fail("Next stage regressed");return
    ui._open_menu("UPGRADES")
    if not ui.menu_active or ui.upgrade_buttons.size() != 3:
        _fail("Gold upgrades menu regressed");return
    ui._close_menu()
    if ui.menu_active:
        _fail("Menu failed to close");return
    ui.game.stage = 5
    ui.game._spawn()
    ui._refresh()
    if not ui.game.is_boss() or ui.stage_title.text != "GUARDIAN TRIAL":
        _fail("Guardian HUD not responding to actual stage");return
    ui.queue_free()
    if existed:
        var file: FileAccess = FileAccess.open(save_path,FileAccess.WRITE)
        if file != null:
            file.store_string(old)
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
    print("PASS v0.35: three raster creatures, full painted arena, combat, level controls, guardian, progression, menus and saves")
    quit(0)
