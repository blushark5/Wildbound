extends SceneTree
## Captures the REAL unified navigation while preserving the full battle.
const SCENE = preload("res://scenes/incremental/wildbound_bond_v27.tscn")
const GAME = preload("res://scripts/incremental/bond_engine_v25.gd")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")
func _initialize() -> void:
    call_deferred("_capture")
func _frames() -> void:
    for i in range(10):
        await process_frame
    await RenderingServer.frame_post_draw
func _shot(view: SubViewport,name: String) -> bool:
    var filepath: String = ProjectSettings.globalize_path("res://Docs/QA/"+name+".png")
    DirAccess.make_dir_recursive_absolute(filepath.get_base_dir())
    return view.get_texture().get_image().save_png(filepath) == OK
func _capture() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var view := SubViewport.new()
    view.size = Vector2i(1280,720)
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var ui: Control = SCENE.instantiate()
    view.add_child(ui)
    await _frames()
    ui._strike()
    ui._refresh()
    await _frames()
    if not _shot(view,"wildbound_v27_top_tabs_team_drawer"):
        push_error("Team side drawer screenshot missing");quit(1);return
    ui._show_section("GROW")
    await _frames()
    if not _shot(view,"wildbound_v27_top_tabs_gold_drawer"):
        push_error("Gold side drawer screenshot missing");quit(1);return
    ui._show_section("WORLD")
    await _frames()
    if not _shot(view,"wildbound_v27_top_tabs_world_journey"):
        push_error("World+Journey side screenshot missing");quit(1);return
    ui._show_section("TOOLS")
    await _frames()
    if not _shot(view,"wildbound_v27_top_tabs_tactics"):
        push_error("Tactics side drawer screenshot missing");quit(1);return
    ui._show_section("SAVE")
    await _frames()
    if not _shot(view,"wildbound_v27_top_tabs_save_slots"):
        push_error("Save panel screenshot missing");quit(1);return
    ui._close_drawer()
    await _frames()
    if not _shot(view,"wildbound_v27_uncluttered_battle"):
        push_error("Full battle screenshot missing");quit(1);return
    SLOTS.erase_all(GAME.SAVE_FILE)
    print("PASS v0.27: six actual Godot 1280x720 battle/menu screenshots")
    quit(0)
