extends SceneTree
const SCENE = preload("res://scenes/incremental/wildbound_collection_v12.tscn")
func _initialize() -> void:
    call_deferred("_capture")

func _take(v: SubViewport,filename: String) -> bool:
    var pic: Image = v.get_texture().get_image()
    if pic == null or pic.is_empty():
        return false
    var out: String = ProjectSettings.globalize_path("res://Docs/QA/"+filename+".png")
    DirAccess.make_dir_recursive_absolute(out.get_base_dir())
    return pic.save_png(out) == OK

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
    ui.call("_refresh")
    for i in range(7):
        await process_frame
    await RenderingServer.frame_post_draw
    if not _take(viewport,"wildbound_v12_one_unique_starter"):
        push_error("Failed to render one-unique-starter battle");quit(1);return
    ui.game.essence = 60
    ui.game.hatch_egg()
    ui.game.hatch_egg()
    ui.game.hatch_egg()
    ui.game.assign_creature(1,"cindlet")
    ui.game.assign_creature(2,"brinlet")
    ui.game.wave = 8
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.game.initialize_squads()
    ui.call("_refresh")
    for i in range(7):
        await process_frame
    await RenderingServer.frame_post_draw
    if not _take(viewport,"wildbound_v12_unique_mixed_squad"):
        push_error("Failed to render 3 distinct individual monsters");quit(1);return
    ui.call("_switch_tab","NEST")
    ui.call("_refresh")
    for i in range(7):
        await process_frame
    await RenderingServer.frame_post_draw
    if not _take(viewport,"wildbound_v12_collection"):
        push_error("Failed to render earned collection interface");quit(1);return
    print("PASS: three genuine Godot screenshots of v0.12 unique collection")
    quit(0)
