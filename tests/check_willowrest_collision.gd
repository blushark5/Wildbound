extends SceneTree
func _initialize() -> void:
    call_deferred("_validate")

func _validate() -> void:
    var map_script: Script = load("res://scripts/willowrest_map.gd") as Script
    var layout: Dictionary = map_script.new().call("build")
    var walls: Dictionary = layout["blocked"]
    var grass: Dictionary = layout["tall"]
    var spawn: Vector2i = Vector2i(24, 7)
    var keeper: Vector2i = Vector2i(23, 8)
    if walls.has(spawn) or walls.has(keeper):
        push_error("Player spawn or Keeper Vale is obstructed")
        quit(1)
        return
    # Trees, houses, fences and water must block the protagonist's foot tile.
    var solid_samples: Array[Vector2i] = [
        Vector2i(4, 8), Vector2i(20, 2), Vector2i(29, 2),
        Vector2i(35, 4), Vector2i(42, 3), Vector2i(29, 12),
        Vector2i(39, 11),
    ]
    for tile in solid_samples:
        if not walls.has(tile):
            push_error("Scenery is walk-through at " + str(tile))
            quit(1)
            return
    var open_samples: Array[Vector2i] = [
        spawn, Vector2i(24, 8), Vector2i(24, 9),
        Vector2i(25, 5), Vector2i(29, 6), Vector2i(35, 8),
    ]
    for tile in open_samples:
        if walls.has(tile):
            push_error("Walkable road blocked at " + str(tile))
            quit(1)
            return
    var visited: Dictionary = {spawn: true}
    var queue: Array[Vector2i] = [spawn]
    while not queue.is_empty():
        var here: Vector2i = queue.pop_front()
        for step in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
            var candidate: Vector2i = here + step
            if candidate.x <= 0 or candidate.x >= 47 or candidate.y <= 0 or candidate.y >= 13:
                continue
            if candidate == keeper or walls.has(candidate) or visited.has(candidate):
                continue
            visited[candidate] = true
            queue.append(candidate)
    var reachable_grass: int = 0
    for tile in grass.keys():
        if visited.has(tile):
            reachable_grass += 1
    if reachable_grass < 4 or not visited.has(Vector2i(25, 5)):
        push_error("Meadow or town path disconnected from spawn")
        quit(1)
        return
    var accessible_keeper: bool = false
    for delta in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
        if visited.has(keeper + delta):
            accessible_keeper = true
    if not accessible_keeper:
        push_error("Cannot approach Keeper Vale")
        quit(1)
        return
    var texture: Texture2D = load("res://assets/keeper_vale_v1.png") as Texture2D
    if texture == null or texture.get_size() != Vector2(24, 32):
        push_error("Unique Keeper Vale portrait failed to load at 24x32")
        quit(1)
        return
    var picture: Image = texture.get_image()
    picture.convert(Image.FORMAT_RGBA8)
    var visible: int = 0
    for y in range(32):
        for x in range(24):
            if picture.get_pixel(x, y).a > 0.5:
                visible += 1
    if visible < 150:
        push_error("Keeper Vale image has too few visible pixels")
        quit(1)
        return
    print("PASS: Keeper sprite %d pixels, %d reachable tiles, %d accessible encounters, correct scenery blocking" % [visible, visited.size(), reachable_grass])
    quit(0)
