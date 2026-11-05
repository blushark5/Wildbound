extends SceneTree
## Actual rendered v0.18 battle and Field Guide visual review.
const SCENE = preload("res://scenes/incremental/wildbound_bond_v18.tscn")

func _initialize() -> void:
    call_deferred("_capture")

func _frame() -> void:
    for i in range(8):
        await process_frame
    await RenderingServer.frame_post_draw

func _shot(v: SubViewport,name: String) -> bool:
    var pic: Image = v.get_texture().get_image()
    var path: String = ProjectSettings.globalize_path("res://Docs/QA/"+name+".png")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    return pic.save_png(path) == OK

func _capture() -> void:
    var viewport := SubViewport.new()
    viewport.size = Vector2i(1280,720)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var ui: Control = SCENE.instantiate() as Control
    viewport.add_child(ui)
    ui.playing = false
    ui.guide_dialog.hide()
    ui.game.onboarding_seen = true
    ui._refresh()
    await _frame()
    if not _shot(viewport,"wildbound_v18_random_starters"):
        push_error("Failed v0.18 new roster screenshot");quit(1);return
    ui.game.wave = 10
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.game.initialize_squads()
    ui._refresh()
    await _frame()
    if not _shot(viewport,"wildbound_v18_guardian"):
        push_error("Failed v0.18 stage 10 Guardian");quit(1);return
    for kind in ui.game.squad_slots:
        ui.game.owned_creatures[kind]["evolved"] = true
        ui.game.bond_ranks[kind] = 4
    ui.game.initialize_squads()
    ui._refresh()
    await _frame()
    if not _shot(viewport,"wildbound_v18_ascended_art"):
        push_error("Failed v0.18 mythic form screenshot");quit(1);return
    ui._open_codex()
    ui._refresh()
    await _frame()
    if not _shot(viewport,"wildbound_v18_field_guide"):
        push_error("Failed v0.18 Field Guide screenshot");quit(1);return
    var path: String = ui.game.SAVE_FILE
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("PASS v0.18: four real new-starter, boss, Ascended and Field Guide screenshots")
    quit(0)
