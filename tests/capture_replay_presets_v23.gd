extends SceneTree
## Real Godot screenshots of compact Replay button, team presets,
## accurate Echo research panel and a populated Ascension Chronicle.
const SCENE = preload("res://scenes/incremental/wildbound_bond_v23.tscn")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")
const GAME = preload("res://scripts/incremental/bond_engine_v23.gd")

func _initialize() -> void:
    call_deferred("_capture")

func _frame() -> void:
    for i in range(9):
        await process_frame
    await RenderingServer.frame_post_draw

func _shot(v: SubViewport,name: String) -> bool:
    var image: Image = v.get_texture().get_image()
    var path: String = ProjectSettings.globalize_path("res://Docs/QA/"+name+".png")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    return image.save_png(path) == OK

func _capture() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var view := SubViewport.new()
    view.size = Vector2i(1280,720)
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var ui: Control = SCENE.instantiate() as Control
    view.add_child(ui)
    ui.guide_dialog.hide()
    ui._strike()
    ui.playing = false
    ui.game.best_wave = 21
    ui.game.run_peak = 21
    ui._ascend()
    ui.ascent_results.hide()
    ui._close_ascent_results()
    ui._toggle_replay_route()
    ui._refresh()
    await _frame()
    if not _shot(view,"wildbound_v23_replay_route"):
        push_error("Failed v0.23 replay route screenshot");quit(1);return
    ui._open_codex()
    ui._store_preset(1)
    ui._refresh_codex()
    await _frame()
    if not _shot(view,"wildbound_v23_team_presets"):
        push_error("Failed v0.23 team presets screenshot");quit(1);return
    ui._close_codex()
    ui._switch_tab("LEGACY")
    ui._refresh()
    await _frame()
    if not _shot(view,"wildbound_v23_permanent_research"):
        push_error("Failed v0.23 permanent research screenshot");quit(1);return
    ui._show_chronicle()
    await _frame()
    if not _shot(view,"wildbound_v23_ascension_chronicle"):
        push_error("Failed v0.23 Ascension Chronicle screenshot");quit(1);return
    SLOTS.erase_all(GAME.SAVE_FILE)
    print("PASS v0.23: real Replay, 3 team presets, permanent Echo effects, Ascension Chronicle screenshots")
    quit(0)
