extends SceneTree
func _initialize() -> void:
    call_deferred("_validate")
func _fail(message: String) -> void:
    push_error("MODULAR ENVIRONMENT: " + message)
    quit(1)
func _validate() -> void:
    var packed: PackedScene = load("res://scenes/environment/willowrest_modular_test.tscn") as PackedScene
    if packed == null:
        _fail("Scene cannot be imported")
        return
    var scene: Node2D = packed.instantiate() as Node2D
    root.add_child(scene)
    var world: Node2D = scene.get_node("World")
    var ground: TileMapLayer = world.get_node("Ground") as TileMapLayer
    var road: TileMapLayer = world.get_node("Roads") as TileMapLayer
    var lake: TileMapLayer = world.get_node("Water") as TileMapLayer
    var grass: TileMapLayer = world.get_node("Vegetation") as TileMapLayer
    var trees: Node2D = world.get_node("WorldObjects")
    if ground == null or road == null or lake == null or grass == null:
        _fail("Independent tile layers missing")
        return
    if ground.get_used_cells().size() != 672 or road.get_used_cells().size() < 100 or lake.get_used_cells().size() != 40:
        _fail("Terrain tile coverage incorrect")
        return
    if trees.get_child_count() < 8 or trees.get_child(0).get_node_or_null("TrunkCollision") == null:
        _fail("Independent illustrated trees with trunk collisions missing")
        return
    var hero: Node2D = scene.get_node("Player")
    if hero.get_node("ApprovedHero").texture == null:
        _fail("Approved hero art missing")
        return
    var source: TileSetAtlasSource = lake.tile_set.get_source(0) as TileSetAtlasSource
    if source.get_tile_data(Vector2i(8,0),0).get_collision_polygons_count(0) != 1:
        _fail("Water TileSet polygon missing")
        return
    if not bool(world.call("is_open",Vector2i(24,7))) or bool(world.call("is_open",Vector2i(5,10))) or bool(world.call("is_open",Vector2i(3,3))):
        _fail("Spawn, lake or tree occupancy incorrect")
        return
    if not bool(world.call("is_encounter",Vector2i(40,4))):
        _fail("Eastern encounter cells missing")
        return
    if not bool(hero.call("move_one",Vector2i.RIGHT)):
        _fail("Movement to clear path rejected")
        return
    var visited: Dictionary = {Vector2i(24,7):true}
    var queue: Array[Vector2i] = [Vector2i(24,7)]
    var reached: bool = false
    while not queue.is_empty():
        var cell: Vector2i = queue.pop_front()
        if bool(world.call("is_encounter",cell)):
            reached = true
        for step in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
            var next: Vector2i = cell+step
            if visited.has(next) or not bool(world.call("is_open",next)):
                continue
            visited[next] = true
            queue.append(next)
    if not reached:
        _fail("Meadow disconnected from player")
        return
    print("PASS: 4 tile layers, %d separate trees, water physics, %d traversable cells, original hero" % [trees.get_child_count(),visited.size()])
    quit(0)
