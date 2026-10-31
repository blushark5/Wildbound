extends SceneTree
func _initialize() -> void:
    call_deferred("_capture")
func _capture() -> void:
    var viewport := SubViewport.new()
    viewport.size = Vector2i(1280,720)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var scene: PackedScene = load("res://scenes/incremental/wildbound_visual_v07.tscn") as PackedScene
    if scene == null:
        push_error("No v0.7 stage scene"); quit(1); return
    var screen: Control = scene.instantiate() as Control
    viewport.add_child(screen)
    # Representative mid-run battle for visually judging all three creatures.
    # This staged state lives only in the disposable CI scene process.
    screen.game.gold = 100000.0
    screen.game.buy_levels("brinlet",4)
    screen.game.buy_levels("cindlet",4)
    screen.game.wave = 42
    screen.game.best_wave = 42
    screen.game._spawn_enemy()
    screen.game._fit_enemy_to_region()
    screen.call("_refresh")
    for i in range(12):
        await process_frame
    await RenderingServer.frame_post_draw
    var img: Image = viewport.get_texture().get_image()
    if img == null or img.is_empty():
        push_error("Renderer produced no screenshot"); quit(1); return
    var dest: String = ProjectSettings.globalize_path("res://Docs/QA/wildbound_visual_v07.png")
    DirAccess.make_dir_recursive_absolute(dest.get_base_dir())
    if img.save_png(dest) != OK:
        push_error("Screenshot couldn't be saved"); quit(1); return
    print("Rendered original starter roster "+dest)
    # Inspect all three evolved species facing an actual Guardian separately.
    for creature in ["spriglet","brinlet","cindlet"]:
        screen.game.evolved[creature] = true
        screen.game.levels[creature] = 40
    screen.game.wave = 50
    screen.game.best_wave = 50
    screen.game._spawn_enemy()
    screen.game._fit_enemy_to_region()
    screen.call("_refresh")
    for i in range(6):
        await process_frame
    await RenderingServer.frame_post_draw
    var evolved: Image = viewport.get_texture().get_image()
    var evolved_path: String = ProjectSettings.globalize_path("res://Docs/QA/wildbound_visual_v07_evolved.png")
    if evolved == null or evolved.is_empty() or evolved.save_png(evolved_path) != OK:
        push_error("Evolved Guardian screenshot failure"); quit(1); return
    print("Rendered original evolved forms "+evolved_path)
    quit(0)
