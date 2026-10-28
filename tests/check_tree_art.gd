extends SceneTree
# Test native sprite integrity, footprint size and zero overlap with *any*
# walkable player standing position. This protects us from hiding the hero
# behind decorative trees in future art iterations.
func _initialize() -> void:
    call_deferred("_validate_trees")

func _validate_trees() -> void:
    var tex: Texture2D = load("res://assets/trees_atlas.png") as Texture2D
    if tex == null or tex.get_width() != 256 or tex.get_height() != 80:
        push_error("Expected four 64x80 original forest sprites")
        quit(1)
        return
    var img: Image = tex.get_image()
    if img == null or img.is_empty():
        push_error("Tree source texture could not decode")
        quit(1)
        return
    img.convert(Image.FORMAT_RGBA8)
    for i in range(4):
        var visible: int = 0
        for y in range(80):
            for x in range(i * 64, (i + 1) * 64):
                if img.get_pixel(x, y).a > 0.45:
                    visible += 1
        if visible < 800:
            push_error("Missing pixels in original tree frame %d" % i)
            quit(1)
            return
    var file: FileAccess = FileAccess.open("res://world.json", FileAccess.READ)
    if file == null:
        push_error("Missing world map")
        quit(1)
        return
    var map_data: Dictionary = JSON.parse_string(file.get_as_text())
    var blocked: Dictionary = {}
    for p in map_data.get("blocked", []):
        blocked[Vector2i(int(p[0]), int(p[1]))] = true

    var tree_script: Script = load("res://scripts/tree_art.gd") as Script
    var node: Node2D = tree_script.new() as Node2D
    root.add_child(node)
    var positions: Array = tree_script.get_script_constant_map().get("TREE_SPOTS", [])
    var display_size: Vector2i = tree_script.get_script_constant_map().get("DISPLAY_CELL", Vector2i.ZERO)
    if positions.size() != 4 or node.get_child_count() != 4 or display_size != Vector2i(32, 40):
        push_error("Tree pilot should contain four 32x40 sprites")
        quit(1)
        return
    for i in range(positions.size()):
        var spot: Vector3i = positions[i]
        var actual: Sprite2D = node.get_child(i) as Sprite2D
        if actual == null or actual.texture == null or actual.texture.get_size() != Vector2(display_size):
            push_error("Tree %d is missing its 32x40 texture" % i)
            quit(1)
            return
        var foot_tile: Vector2i = Vector2i(int(spot.x / 16), int((spot.y - 1) / 16))
        if not blocked.has(foot_tile):
            push_error("Tree %d foot is not on an existing blocked forest tile" % i)
            quit(1)
            return
        var bounds: Rect2 = Rect2(actual.position, Vector2(display_size))
        for y in range(int(map_data["height"])):
            for x in range(int(map_data["width"])):
                if blocked.has(Vector2i(x, y)):
                    continue
                # The game draws the hero 24x32 at (tile.x*16-4, tile.y*16-16).
                var hero: Rect2 = Rect2(x * 16 - 4, y * 16 - 16, 24, 32)
                if bounds.intersects(hero):
                    push_error("Tree %d overlaps walkable hero cell (%d,%d)" % [i, x, y])
                    quit(1)
                    return
    print("Tree pilot PASS: original pixels visible; compact trees avoid every walkable hero tile")
    quit(0)
