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
    viewport.add_child(scene.instantiate())
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
    print("Rendered v0.6 actual playable scene "+dest)
    quit(0)
