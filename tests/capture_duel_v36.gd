extends SceneTree
## Capture real Godot frames, not a mockup. Isolate saved game per state.
const SCENE = preload("res://scenes/duel/wildbound_duel_v36.tscn")
const ENGINE = preload("res://scripts/duel/duel_engine_v30.gd")
func _initialize() -> void:
    call_deferred("_run")
func _settle() -> void:
    for i in range(10):
        await process_frame
    await RenderingServer.frame_post_draw
func _shot(view: SubViewport,tag: String) -> void:
    var file: String = ProjectSettings.globalize_path(
        "res://Docs/QA/wildbound_v36_"+tag+".png")
    DirAccess.make_dir_recursive_absolute(file.get_base_dir())
    if view.get_texture().get_image().save_png(file) != OK:
        push_error("v0.36 failed capturing "+tag)
        quit(1)
func _run() -> void:
    var path: String = ENGINE.SAVE_FILE
    var existed: bool = FileAccess.file_exists(path)
    var old: String = FileAccess.get_file_as_string(path) if existed else ""
    var viewport := SubViewport.new()
    viewport.size = Vector2i(1280,720)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var ui: Control = SCENE.instantiate()
    viewport.add_child(ui)
    for creature in ENGINE.ORDER:
        ui.game.new_game()
        ui.game.select_creature(creature)
        ui.game.gold = 400.0
        ui.game.start()
        ui.victory31_left = 0.0
        ui.victory31.hide()
        ui.ribbon_timer32 = 0.0
        ui.stage_ribbon32.hide()
        ui._refresh()
        await _settle()
        _shot(viewport,creature+"_battle")
    ui.game.new_game()
    ui.game.gold = 500.0
    ui.game.start()
    for i in range(300):
        if ui.game.awaiting_next:
            break
        ui.game.hit()
    ui._refresh()
    await _settle()
    _shot(viewport,"victory")
    ui.game.new_game()
    ui.victory31_left = 0.0
    ui.victory31.hide()
    ui.ribbon_timer32 = 0.0
    ui.stage_ribbon32.hide()
    ui.game.stage = 5
    ui.game._spawn()
    ui.game.start()
    ui._refresh()
    await _settle()
    _shot(viewport,"guardian")
    ui._open_menu("UPGRADES")
    await _settle()
    _shot(viewport,"upgrades_menu")
    if existed:
        var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
        if file != null:
            file.store_string(old)
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("PASS v0.36: six real rendered Godot QA screens")
    quit(0)
