extends SceneTree
const SCENE = preload("res://scenes/incremental/wildbound_bond_v28.tscn")
const GAME = preload("res://scripts/incremental/bond_engine_v25.gd")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")
func _initialize() -> void:
    call_deferred("_run")
func _frames() -> void:
    for i in range(8):
        await process_frame
    await RenderingServer.frame_post_draw
func _shot(v: SubViewport,name: String) -> bool:
    var path: String = ProjectSettings.globalize_path("res://Docs/QA/"+name+".png")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    return v.get_texture().get_image().save_png(path) == OK
func _run() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var v := SubViewport.new()
    v.size = Vector2i(1280,720)
    v.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(v)
    var ui: Control = SCENE.instantiate()
    v.add_child(ui)
    await _frames()
    if not _shot(v,"wildbound_v28_first_battle"):
        push_error("First battle screenshot missing");quit(1);return
    ui._strike()
    await _frames()
    if not _shot(v,"wildbound_v28_clean_active_battle"):
        push_error("Active battle screenshot missing");quit(1);return
    ui._toggle_main_menu()
    await _frames()
    if not _shot(v,"wildbound_v28_main_menu"):
        push_error("Menu home screenshot missing");quit(1);return
    ui._show_section("TEAM")
    await _frames()
    if not _shot(v,"wildbound_v28_team_and_training"):
        push_error("Team training screenshot missing");quit(1);return
    ui._show_section("TOOLS")
    ui._open_skills_panel()
    await _frames()
    if not _shot(v,"wildbound_v28_optional_abilities"):
        push_error("Optional abilities screenshot missing");quit(1);return
    ui._close_drawer()
    for i in range(3):
        if ui.game.awaiting_next:
            break
        var enemy: Dictionary = ui.game.rival_units[i]
        if float(enemy["hp"]) > 0.0:
            ui.game._damage_rival(i,float(enemy["hp"])+100.0,String(ui.game.squad_slots[0]))
    ui._refresh()
    await _frames()
    if not ui.repeat_button.visible or not _shot(v,"wildbound_v28_next_or_farm"):
        push_error("NEXT/FARM screen screenshot missing");quit(1);return
    SLOTS.erase_all(GAME.SAVE_FILE)
    print("PASS v0.28: rendered start, active battle, menu home, team training, optional abilities, and farm")
    quit(0)
