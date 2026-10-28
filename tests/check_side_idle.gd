extends SceneTree
# Verify that standalone idle artwork is readable and nontransparent.
# Godot's ordinary headless startup does not prove an image has visible pixels.
func _initialize() -> void:
    var tex: Texture2D = load("res://assets/hero_idle_sides.png") as Texture2D
    if tex == null:
        push_error("Side idle PNG failed to load")
        quit(1)
        return
    if tex.get_width() != 48 or tex.get_height() != 32:
        push_error("Side idle PNG must be 48x32 pixels")
        quit(1)
        return
    var img: Image = tex.get_image()
    if img == null or img.is_empty():
        push_error("Side idle PNG decoded to no pixels")
        quit(1)
        return
    img.convert(Image.FORMAT_RGBA8)
    var opaque_left: int = 0
    var opaque_right: int = 0
    for y in range(32):
        for x in range(48):
            if img.get_pixel(x, y).a > 0.35:
                if x < 24:
                    opaque_left += 1
                else:
                    opaque_right += 1
    print("Side idle visible pixels: left=%d, right=%d" % [opaque_left, opaque_right])
    if opaque_left < 250 or opaque_right < 250:
        push_error("Side idle sprite missing visible artwork")
        quit(1)
        return
    quit(0)
