extends SceneTree
# Runtime screenshot attempt, separate from headless import/export checks.
# Run with xvfb-run and a real graphics renderer, not --headless.
func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var viewport := SubViewport.new()
    viewport.size = Vector2i(1152,336)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    viewport.transparent_bg = false
    root.add_child(viewport)
    var packed: PackedScene = load("res://scenes/environment/willowrest_modular_test.tscn") as PackedScene
    if packed == null:
        push_error("Cannot open visual QA scene")
        quit(1)
        return
    var scene: Node = packed.instantiate()
    viewport.add_child(scene)
    for i in range(7):
        await process_frame
    await RenderingServer.frame_post_draw
    var img: Image = viewport.get_texture().get_image()
    if img == null or img.is_empty():
        push_error("Rendered frame unavailable, screenshot NOT visually validated")
        quit(1)
        return
    var output: String = ProjectSettings.globalize_path("res://Docs/Art/qa/modular_scene_study.png")
    DirAccess.make_dir_recursive_absolute(output.get_base_dir())
    var error: Error = img.save_png(output)
    if error != OK:
        push_error("Could not save visual screenshot")
        quit(1)
        return
    print("Rendered screenshot captured for human QA: " + output)
    quit(0)
