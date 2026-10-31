extends SceneTree
# Produces a real Godot-rendered 1280x720 image under xvfb-run, not a mockup.
func _initialize() -> void:
    call_deferred("_capture")
func _capture() -> void:
    var viewport := SubViewport.new()
    viewport.size = Vector2i(1280,720)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport.transparent_bg = false
    root.add_child(viewport)
    var packed: PackedScene = load("res://scenes/incremental/wildbound_alpha.tscn") as PackedScene
    if packed == null:
        push_error("Cannot load Alpha scene")
        quit(1)
        return
    viewport.add_child(packed.instantiate())
    for frame in range(12):
        await process_frame
    await RenderingServer.frame_post_draw
    var img: Image = viewport.get_texture().get_image()
    if img == null or img.is_empty():
        push_error("No actual renderer output")
        quit(1)
        return
    var destination: String = ProjectSettings.globalize_path("res://Docs/QA/wildbound_alpha.png")
    DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
    if img.save_png(destination) != OK:
        push_error("Cannot save rendered Alpha screenshot")
        quit(1)
        return
    print("Actual 1280x720 Alpha screenshot captured: " + destination)
    quit(0)
