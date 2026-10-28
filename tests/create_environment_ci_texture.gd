extends SceneTree
# CI-only: instantiate the full-scene path without committing placeholder art.
func _initialize() -> void:
    var img: Image = Image.create(1152, 336, false, Image.FORMAT_RGBA8)
    img.fill(Color("#59956f"))
    var err: Error = img.save_png("res://assets/willowrest_world.png")
    if err != OK:
        push_error("Could not generate temporary integrated map texture")
        quit(1)
        return
    quit(0)
