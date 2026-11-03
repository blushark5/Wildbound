extends SceneTree
const SCENE = preload("res://scenes/incremental/wildbound_squads_v11.tscn")

func _initialize() -> void:
    call_deferred("_capture")

func _snapshot(viewport: SubViewport, name: String) -> bool:
    var pic: Image = viewport.get_texture().get_image()
    if pic == null or pic.is_empty():
        return false
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
    ui.game.wave = 1
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.game.initialize_squads()
    ui.call("_refresh")
    for i in range(9):
        await process_frame
    await RenderingServer.frame_post_draw
    if not _snapshot(viewport,"wildbound_v11_spriglet_vs_brinlet"):
        push_error("Couldn't capture the 3-Grove vs 3-Tide battle");quit(1);return
    ui.game.gold = 10000.0
    ui.game.buy_levels("brinlet",5)
    ui.game.buy_levels("cindlet",5)
    ui.game.squad_slots.assign(["spriglet","brinlet","cindlet"])
    ui.game.wave = 4
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.game.initialize_squads()
    ui.call("_refresh")
    for i in range(9):
        await process_frame
    await RenderingServer.frame_post_draw
    if not _snapshot(viewport,"wildbound_v11_mixed_targeting"):
        push_error("Couldn't capture mixed smart-target combat");quit(1);return
    ui.game.wave = 10
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.game.initialize_squads()
    ui.call("_refresh")
    for i in range(8):
        await process_frame
    await RenderingServer.frame_post_draw
    if not _snapshot(viewport,"wildbound_v11_guardian_squad"):
        push_error("Couldn't capture three-enemy Guardian trainer");quit(1);return
    print("Rendered v0.11 mono-type, mixed counters and Guardian trio screenshots")
    quit(0)
