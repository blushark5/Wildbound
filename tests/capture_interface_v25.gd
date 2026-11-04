extends SceneTree
## Real 1280x720 rendered screen audit. The browser scales this canvas
## to phone landscape, so all panels must remain fully inside it.
const SCENE = preload("res://scenes/incremental/wildbound_bond_v25.tscn")
const GAME = preload("res://scripts/incremental/bond_engine_v25.gd")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")

func _initialize() -> void:
    call_deferred("_capture")

func _frames() -> void:
    for _i in range(9):
        await process_frame
    await RenderingServer.frame_post_draw

func _screenshot(v: SubViewport,label: String) -> bool:
    var path: String = ProjectSettings.globalize_path("res://Docs/QA/"+label+".png")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    return v.get_texture().get_image().save_png(path) == OK

func _capture() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var viewport := SubViewport.new()
    viewport.size = Vector2i(1280,720)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var ui: Control = SCENE.instantiate()
    viewport.add_child(ui)
    await _frames()
    ui.guide_dialog.hide()
    ui._strike()
    ui.playing = false
    ui._refresh()
    await _frames()
    if not _screenshot(viewport,"wildbound_v25_compact_shop"):
        push_error("Missing compact-first view");quit(1);return
    ui._toggle_journey()
    ui._refresh()
    await _frames()
    if not _screenshot(viewport,"wildbound_v25_expanded_journey"):
        push_error("Missing expanded Journey view");quit(1);return
    ui._toggle_journey()
    ui._toggle_text_size()
    ui.game.gold = 1200000.0
    ui._refresh()
    await _frames()
    if not _screenshot(viewport,"wildbound_v25_large_text_upgrades"):
        push_error("Missing large type and upgrade view");quit(1);return
    ui._open_codex()
    ui._refresh_codex()
    await _frames()
    if not _screenshot(viewport,"wildbound_v25_refined_field_guide"):
        push_error("Missing clearer Field Guide view");quit(1);return
    ui._close_codex()
    ui._switch_tab("LEGACY")
    ui._refresh()
    await _frames()
    if not _screenshot(viewport,"wildbound_v25_ascension_shop"):
        push_error("Missing Ascension browse view");quit(1);return
    SLOTS.erase_all(GAME.SAVE_FILE)
    print("PASS v0.25: 5 real Godot screenshots of compact battle/shop, expanded quest, large text, updated Field Guide and Ascension shop")
    quit(0)
