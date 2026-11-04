extends SceneTree
## Export six actual Godot-rendered frames for visual QA.
const SCENE = preload("res://scenes/duel/wildbound_duel_v35.tscn")
const ENGINE = preload("res://scripts/duel/duel_engine_v30.gd")

func _initialize() -> void:
    call_deferred("_run")

func _settle() -> void:
    for i in range(9):
        await process_frame
    await RenderingServer.frame_post_draw

func _shot(view: SubViewport,tag: String) -> void:
    var path: String = ProjectSettings.globalize_path(
        "res://Docs/QA/wildbound_v35_"+tag+".png")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    if view.get_texture().get_image().save_png(path) != OK:
        push_error("Could not capture v0.35 "+tag)
        quit(1)

func _run() -> void:
    var save_path: String = ENGINE.SAVE_FILE
    var existed: bool = FileAccess.file_exists(save_path)
    var old: String = FileAccess.get_file_as_string(save_path) if existed else ""
    var view := SubViewport.new()
    view.size = Vector2i(1280,720)
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var ui: Control = SCENE.instantiate()
    view.add_child(ui)
    for kind in ENGINE.ORDER:
        ui.game.new_game()
        ui.game.select_creature(kind)
        ui.game.gold = 400.0
        ui.game.start()
        ui._refresh()
        await _settle()
        _shot(view,kind+"_battle")
    ui.game.new_game()
    ui.game.gold = 500.0
    ui.game.start()
    for i in range(300):
        if ui.game.awaiting_next:
            break
        ui.game.hit()
    ui._refresh()
    await _settle()
    _shot(view,"victory")
    ui.game.new_game()
    ui.game.stage = 5
    ui.game._spawn()
    ui.game.start()
    ui._refresh()
    await _settle()
    _shot(view,"guardian")
    ui._open_menu("UPGRADES")
    await _settle()
    _shot(view,"upgrades_menu")
    if existed:
        var file: FileAccess = FileAccess.open(save_path,FileAccess.WRITE)
        if file != null:
            file.store_string(old)
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
    print("PASS v0.35: Cindlet / Brinlet / Spriglet / victory / guardian / menu captures")
    quit(0)
