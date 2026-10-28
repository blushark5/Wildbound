extends SceneTree
# Regression test for Wildbound forest asset integration. A readable PNG,
# visible tree pixels, proper atlas dimensions, and existing collision anchors
# are required before the browser preview can be approved.
func _initialize() -> void:
    var tex: Texture2D = load("res://assets/trees_atlas.png") as Texture2D
    if tex == null or tex.get_width() != 256 or tex.get_height() != 80:
        push_error("Tree atlas missing or incorrect dimensions (expected 256x80)")
        quit(1)
        return
    var img: Image = tex.get_image()
    if img == null or img.is_empty():
        push_error("Tree atlas could not decode")
        quit(1)
        return
    img.convert(Image.FORMAT_RGBA8)
    for frame_idx in range(4):
        var visible: int = 0
        for y in range(80):
            for x in range(frame_idx * 64, (frame_idx + 1) * 64):
                if img.get_pixel(x, y).a > 0.45:
                    visible += 1
        print("Tree #%d visible pixels: %d" % [frame_idx, visible])
        if visible < 800:
            push_error("Tree frame %d is missing most of its sprite" % frame_idx)
            quit(1)
            return
    var file: FileAccess = FileAccess.open("res://world.json", FileAccess.READ)
    if file == null:
        quit(1)
        return
    var map_data: Dictionary = JSON.parse_string(file.get_as_text())
    var blocked: Dictionary = {}
    for p in map_data.get("blocked", []):
        blocked[Vector2i(int(p[0]), int(p[1]))] = true
    var script: Script = load("res://scripts/tree_art.gd") as Script
    var node: Node2D = script.new() as Node2D
    root.add_child(node)
    if node.get_child_count() != 4:
        push_error("Tree study did not instantiate four sprites")
        quit(1)
        return
    for loc in script.get("GROVE_SPOTS"):
        if not blocked.has(Vector2i(loc.x, loc.y)):
            push_error("Tree foot outside blocked forest: %s" % str(loc))
            quit(1)
            return
    print("Wildbound tree art validated: 4 visible variants on blocked tiles")
    quit(0)
