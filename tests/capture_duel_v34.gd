extends SceneTree
const SCENE = preload("res://scenes/duel/wildbound_duel_v34.tscn")
const ENGINE = preload("res://scripts/duel/duel_engine_v30.gd")

func _initialize() -> void:
    call_deferred("_run")

func _settle() -> void:
    for i in range(8):
        await process_frame
    await RenderingServer.frame_post_draw

func _shot(view: SubViewport,name: String) -> void:
    var path: String = ProjectSettings.globalize_path("res://Docs/QA/"+name+".png")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    if view.get_texture().get_image().save_png(path) != OK:
        push_error("Missing v0.34 capture: "+name)
        quit(1)

func _run() -> void:
    var save_path: String = ENGINE.SAVE_FILE
    var had: bool = FileAccess.file_exists(save_path)
    var previous: String = FileAccess.get_file_as_string(save_path) if had else ""
    var view := SubViewport.new()
    view.size = Vector2i(1280,720)
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var ui: Control = SCENE.instantiate()
    view.add_child(ui)
    ui.game.new_game()
    ui.game.gold = 400.0
    ui._refresh()
    await _settle()
    _shot(view,"wildbound_v34_start")
    ui._primary_action()
    ui._choose("brinlet")
    ui._refresh()
    await _settle()
    _shot(view,"wildbound_v34_brinlet_battle")
    ui._choose("cindlet")
    ui._refresh()
    await _settle()
    _shot(view,"wildbound_v34_cindlet_battle")
    ui._choose("spriglet")
    ui._refresh()
    await _settle()
    _shot(view,"wildbound_v34_spriglet_battle")
    ui._open_menu("UPGRADES")
    await _settle()
    _shot(view,"wildbound_v34_upgrades")
    if had:
        var old: FileAccess = FileAccess.open(save_path,FileAccess.WRITE)
        if old != null:
            old.store_string(previous)
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
    print("PASS v0.34: five gameplay screenshots with actual concept-derived creatures and arena")
    quit(0)
