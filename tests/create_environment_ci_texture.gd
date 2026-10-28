extends SceneTree
# CI-only: instantiate the full-scene path without committing placeholder art.
func _initialize() -> void:
    if FileAccess.file_exists("res://assets/willowrest_world.png"):
        var actual: Image = Image.load_from_file("res://assets/willowrest_world.png")
        if actual == null or actual.get_width() != 1152 or actual.get_height() != 336:
            push_error("Uploaded Willowrest artwork must be 1152x336 pixels")
            quit(1)
            return
        print("Full scene artwork found; using real pixels for integration test")
        quit(0)
        return
    var img: Image = Image.create(1152, 336, false, Image.FORMAT_RGBA8)
    img.fill(Color("#59956f"))
    var err: Error = img.save_png("res://assets/willowrest_world.png")
    if err != OK:
        push_error("Could not generate temporary integrated map texture")
        quit(1)
        return
    quit(0)
