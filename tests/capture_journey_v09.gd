extends SceneTree
const JOURNEY = preload("res://scenes/incremental/wildbound_journey_v09.tscn")

func _initialize() -> void:
    call_deferred("_capture")

func _save(viewport: SubViewport, name: String) -> bool:
    var image: Image = viewport.get_texture().get_image()
    if image == null or image.is_empty():
        return false
    var dest: String = ProjectSettings.globalize_path("res://Docs/QA/"+name+".png")
    DirAccess.make_dir_recursive_absolute(dest.get_base_dir())
    return image.save_png(dest) == OK

func _capture() -> void:
    var viewport := SubViewport.new()
    viewport.size = Vector2i(1280,720)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var ui: Control = JOURNEY.instantiate() as Control
    viewport.add_child(ui)
    ui.playing = false
    ui.game.trail_rank = 0
    ui.game.wave = 3
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.call("_refresh")
    for i in range(10):
        await process_frame
    await RenderingServer.frame_post_draw
    if not _save(viewport,"wildbound_journey_v09_opening"):
        push_error("Failed real opening screen capture"); quit(1); return
    ui.game.gold = 100000.0
    ui.game.buy_levels("brinlet",5)
    ui.game.buy_levels("cindlet",5)
    ui.game.trail_rank = 4
    ui.game.wave = 10
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.call("_refresh")
    for i in range(7):
        await process_frame
    await RenderingServer.frame_post_draw
    if not _save(viewport,"wildbound_journey_v09_guardian"):
        push_error("Failed real guardian screen capture"); quit(1); return
    print("Rendered both actual v0.9 Godot battle+quest screenshots")
    quit(0)
