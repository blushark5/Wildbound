extends SceneTree
## Real interactive layout review for first-battle, save menu, and locked Ascension.
const SCENE = preload("res://scenes/incremental/wildbound_bond_v19.tscn")
const GAME = preload("res://scripts/incremental/bond_engine_v19.gd")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")

func _initialize() -> void:
    call_deferred("_capture")

func _shot(v: SubViewport,name: String) -> bool:
    var pic: Image = v.get_texture().get_image()
    var path: String = ProjectSettings.globalize_path("res://Docs/QA/"+name+".png")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    return pic.save_png(path) == OK

func _frame() -> void:
    for i in range(8):
        await process_frame
    await RenderingServer.frame_post_draw

func _capture() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var viewport := SubViewport.new()
    viewport.size = Vector2i(1280,720)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var ui: Control = SCENE.instantiate() as Control
    viewport.add_child(ui)
    ui.guide_dialog.hide()
    ui._refresh()
    await _frame()
    if not _shot(viewport,"wildbound_v19_waiting_to_start"):
        push_error("v19 missing waiting-to-start screenshot");quit(1);return
    ui._show_save_manager()
    await _frame()
    if not _shot(viewport,"wildbound_v19_save_manager"):
        push_error("v19 missing save-manager screenshot");quit(1);return
    ui.save_window.hide()
    ui._open_ascension()
    await _frame()
    if not _shot(viewport,"wildbound_v19_ascension_unlock"):
        push_error("v19 missing Ascension-unlock screenshot");quit(1);return
    SLOTS.erase_all(GAME.SAVE_FILE)
    print("PASS v0.19: real Godot first-start, save manager and Ascension help screenshots")
    quit(0)
