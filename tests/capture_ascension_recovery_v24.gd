extends SceneTree
## Real v0.24 viewport screenshots: battle resumes after first Ascension;
## readable, non-overlapping header controls and a recoverable paused state.
const SCENE = preload("res://scenes/incremental/wildbound_bond_v24.tscn")
const GAME = preload("res://scripts/incremental/bond_engine_v24.gd")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")
func _initialize() -> void:
    call_deferred("_capture")
func _frames() -> void:
    for i in range(8):
        await process_frame
    await RenderingServer.frame_post_draw
func _shot(v: SubViewport,name: String) -> bool:
    var path: String = ProjectSettings.globalize_path("res://Docs/QA/"+name+".png")
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
    ui.guide_dialog.hide()
    ui._strike()
    ui.game.best_wave = 21
    ui.game.run_peak = 21
    ui._ascend()
    ui.ascent_results.hide()
    ui._close_ascent_results()
    await _frames()
    if not ui.playing or not _shot(viewport,"wildbound_v24_ascension_battle_recovered"):
        push_error("v24 battle did not resume after results");quit(1);return
    ui.playing = false
    ui._refresh()
    await _frames()
    if not ui.strike_button.text.contains("RESUME") or not _shot(viewport,"wildbound_v24_resume_battle_button"):
        push_error("v24 stuck-save RESUME action not visible");quit(1);return
    ui._strike()
    ui._open_codex()
    await _frames()
    if not _shot(viewport,"wildbound_v24_clean_field_guide"):
        push_error("v24 cleaned Field Guide capture failed");quit(1);return
    SLOTS.erase_all(GAME.SAVE_FILE)
    print("PASS v0.24: actual usable Ascension, obvious RESUME and uncluttered Field Guide snapshots")
    quit(0)
