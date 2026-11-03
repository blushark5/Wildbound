extends SceneTree
const SCENE = preload("res://scenes/incremental/wildbound_challenge_v10.tscn")

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var viewport := SubViewport.new()
    viewport.size = Vector2i(1280,720)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var ui: Control = SCENE.instantiate() as Control
    viewport.add_child(ui)
    ui.playing = false
    ui.guide_dialog.hide()
    ui.game.wave = 4
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.call("_refresh")
    for i in range(7):
        await process_frame
    await RenderingServer.frame_post_draw
    if not _save(viewport,"wildbound_v10_active"):
        push_error("Missing active screenshot");quit(1);return
    ui.game.gold = 10000.0
    ui.game.buy_levels("brinlet",5)
    ui.game.buy_levels("cindlet",5)
    ui.game.focus("cindlet")
    ui.game.wave = 10
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.game.awaiting_next = false
    ui.call("_refresh")
    for i in range(7):
        await process_frame
    await RenderingServer.frame_post_draw
    if not _save(viewport,"wildbound_v10_guardian"):
        push_error("Missing guardian screenshot");quit(1);return
    ui.game.attack(ui.game.enemy_hp+1.0)
    ui.call("_refresh")
    for i in range(7):
        await process_frame
    await RenderingServer.frame_post_draw
    if not _save(viewport,"wildbound_v10_next_stage"):
        push_error("Missing manual-next screenshot");quit(1);return
    print("Rendered active, Guardian and manual next-stage screenshots")
    quit(0)

func _save(viewport: SubViewport,name: String) -> bool:
    var picture: Image = viewport.get_texture().get_image()
    if picture == null or picture.is_empty():
        return false
    var path: String = ProjectSettings.globalize_path("res://Docs/QA/"+name+".png")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    return picture.save_png(path) == OK
