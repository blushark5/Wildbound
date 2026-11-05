extends SceneTree
const SCENE = preload("res://scenes/incremental/wildbound_bond_v29.tscn")
const GAME = preload("res://scripts/incremental/bond_engine_v25.gd")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")

func _initialize() -> void:
    call_deferred("_capture")

func _settle() -> void:
    for i in range(7):
        await process_frame
    await RenderingServer.frame_post_draw

func _shot(view: SubViewport,name: String) -> bool:
    var path: String = ProjectSettings.globalize_path("res://Docs/QA/"+name+".png")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    return view.get_texture().get_image().save_png(path) == OK

func _capture() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var viewport := SubViewport.new()
    viewport.size = Vector2i(1280,720)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var ui: Control = SCENE.instantiate()
    viewport.add_child(ui)
    await _settle()
    if not _shot(viewport,"wildbound_v29_start"):
        push_error("Could not capture clicker-style start");quit(1);return
    ui._strike()
    await _settle()
    if not _shot(viewport,"wildbound_v29_battle"):
        push_error("Could not capture battle");quit(1);return
    ui._toggle_main_menu()
    await _settle()
    if not _shot(viewport,"wildbound_v29_menu"):
        push_error("Could not capture menu");quit(1);return
    ui._show_section("TEAM")
    await _settle()
    if not _shot(viewport,"wildbound_v29_team"):
        push_error("Could not capture team");quit(1);return
    ui._close_drawer()
    for i in range(3):
        if ui.game.awaiting_next:
            break
        var foe: Dictionary = ui.game.rival_units[i]
        if float(foe.get("hp",0.0)) > 0:
            ui.game._damage_rival(i,float(foe["hp"])+100.0,String(ui.game.squad_slots[0]))
    ui._refresh()
    await _settle()
    if not _shot(viewport,"wildbound_v29_next_and_farm"):
        push_error("Could not capture victory");quit(1);return
    SLOTS.erase_all(GAME.SAVE_FILE)
    print("PASS v0.29: five actual 1280x720 browser-game screenshots")
    quit(0)
