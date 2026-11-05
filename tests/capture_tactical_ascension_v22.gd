extends SceneTree
## Actual v0.22 mobile-touch UI review.
const SCENE = preload("res://scenes/incremental/wildbound_bond_v22.tscn")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")
const GAME = preload("res://scripts/incremental/bond_engine_v22.gd")
func _initialize() -> void:
    call_deferred("_capture")
func _frame() -> void:
    for _i in range(8):
        await process_frame
    await RenderingServer.frame_post_draw
func _shot(v: SubViewport,name: String) -> bool:
    var path: String = ProjectSettings.globalize_path("res://Docs/QA/"+name+".png")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    return v.get_texture().get_image().save_png(path) == OK
func _capture() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var view := SubViewport.new()
    view.size = Vector2i(1280,720)
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var ui: Control = SCENE.instantiate()
    view.add_child(ui)
    ui.guide_dialog.hide()
    ui._strike()
    ui.playing = false
    ui.game.gold = 2.0e8
    ui._switch_tab("GROW")
    ui._refresh()
    await _frame()
    if not _shot(view,"wildbound_v22_batch_and_matchups"):
        push_error("Could not render v0.22 matchups or bulk Gold");quit(1);return
    ui._show_matchups()
    await _frame()
    if not _shot(view,"wildbound_v22_matchup_details"):
        push_error("Could not render v0.22 counter information");quit(1);return
    ui.matchup_dialog.hide()
    ui.game.run_peak = 20
    ui.game.best_wave = 20
    ui._request_ascension()
    await _frame()
    if not _shot(view,"wildbound_v22_ascension_preview"):
        push_error("Could not render Ascension preview");quit(1);return
    ui.ascend_dialog.hide()
    ui._ascend()
    await _frame()
    if not _shot(view,"wildbound_v22_ascension_results"):
        push_error("Could not render post-Ascension permanent reward summary");quit(1);return
    SLOTS.erase_all(GAME.SAVE_FILE)
    print("PASS v0.22: real battle HUD, bulk Gold controls, elemental matches and Ascension preview/results screenshots")
    quit(0)
