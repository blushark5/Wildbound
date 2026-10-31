extends SceneTree
# Run under Xvfb, not --headless. Screenshot is for visual QA, not proof of gameplay.
func _initialize() -> void:
    call_deferred("_capture")
func _capture() -> void:
    var viewport := SubViewport.new()
    viewport.size = Vector2i(960,540)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var packed: PackedScene = load("res://scenes/incremental/wildbound_idle.tscn") as PackedScene
    if packed == null:
        push_error("Reboot scene missing")
        quit(1)
        return
    viewport.add_child(packed.instantiate())
    for i in range(10):
        await process_frame
    await RenderingServer.frame_post_draw
    var image: Image = viewport.get_texture().get_image()
    if image == null or image.is_empty():
        push_error("No rendered screenshot")
        quit(1)
        return
    var target := ProjectSettings.globalize_path("res://Docs/QA/wildbound_incremental.png")
    DirAccess.make_dir_recursive_absolute(target.get_base_dir())
    if image.save_png(target) != OK:
        push_error("Screenshot write failed")
        quit(1)
        return
    print("Rendered UI screenshot: "+target)
    quit(0)
