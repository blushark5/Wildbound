extends SceneTree
const SCENE = preload("res://scenes/incremental/wildbound_visual_v13.tscn")
func _initialize() -> void:
    call_deferred("_capture")
func _shot(viewport: SubViewport,name: String) -> bool:
    var img: Image = viewport.get_texture().get_image()
    if img == null or img.is_empty():
        return false
    var path: String = ProjectSettings.globalize_path("res://Docs/QA/"+name+".png")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    return img.save_png(path) == OK
func _frame() -> void:
    for j in range(8):
        await process_frame
    await RenderingServer.frame_post_draw
func _capture() -> void:
    var viewport := SubViewport.new()
    viewport.size = Vector2i(1280,720)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var ui: Control = SCENE.instantiate() as Control
    viewport.add_child(ui)
    ui.playing = true
    ui.guide_dialog.hide()
    ui.game.onboarding_seen = true
    ui.call("_refresh")
    await _frame()
    if not _shot(viewport,"wildbound_v13_arena_start"):
        push_error("Unable to capture initial illustrated duel arena");quit(1);return
    ui._open_codex()
    ui.call("_refresh")
    await _frame()
    if not _shot(viewport,"wildbound_v13_full_field_guide"):
        push_error("Unable to capture full 12-creature Field Guide");quit(1);return
    ui.game.essence = 99
    ui._codex_hatch()
    ui._codex_hatch()
    ui._codex_hatch()
    ui.game.assign_creature(1,"cindlet")
    ui.game.assign_creature(2,"brinlet")
    ui._close_codex()
    ui.game.wave = 9
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.game.initialize_squads()
    ui.call("_refresh")
    await _frame()
    if not _shot(viewport,"wildbound_v13_mixed_duel"):
        push_error("Unable to capture illustrated mixed team battle");quit(1);return
    ui._open_codex()
    ui.call("_refresh")
    await _frame()
    if not _shot(viewport,"wildbound_v13_collected_individuals"):
        push_error("Unable to capture discovered species in Field Guide");quit(1);return
    var saved_path: String = ui.game.SAVE_FILE
    if FileAccess.file_exists(saved_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(saved_path))
    print("PASS: four actual Godot screenshots of v0.13 visual battle and Field Guide")
    quit(0)
