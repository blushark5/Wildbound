extends SceneTree
func _initialize() -> void:
    call_deferred("_check")

func _check() -> void:
    var script: Script = load("res://scripts/willowrest_map.gd") as Script
    if script == null:
        push_error("Missing new Willowrest map script")
        quit(1)
        return
    var result: Dictionary = script.new().call("build")
    var blocked: Dictionary = result.get("blocked", {})
    var grass: Dictionary = result.get("tall", {})
    var spawn: Vector2i = Vector2i(24, 7)
    var keeper: Vector2i = Vector2i(22, 7)
    if blocked.has(spawn) or blocked.has(keeper):
        push_error("Town spawn or Keeper is obstructed")
        quit(1)
        return
    if blocked.size() < 80 or grass.size() < 5:
        push_error("Expected meaningful obstacles and wild-encounter ground")
        quit(1)
        return
    var frontier: Array[Vector2i] = [spawn]
    var visited: Dictionary = {spawn:true}
    var bounds: Vector2i = Vector2i(48, 14)
    var moves: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
    while not frontier.is_empty():
        var cell: Vector2i = frontier.pop_front()
        for delta in moves:
            var n: Vector2i = cell + delta
            if n.x < 1 or n.x >= bounds.x - 1 or n.y < 1 or n.y >= bounds.y - 1 or blocked.has(n) or n == keeper or visited.has(n):
                continue
            visited[n] = true
            frontier.append(n)
    if not visited.has(spawn + Vector2i(1, 0)):
        push_error("Spawn is trapped behind scenery")
        quit(1)
        return
    var reachable_meadow: bool = false
    for cell in grass.keys():
        if visited.has(cell):
            reachable_meadow = true
            break
    if not reachable_meadow:
        push_error("Wild encounter ground is not reachable from town")
        quit(1)
        return
    print("Willowrest new region passed: %d walkable tiles, %d grass cells, spawn and encounter routes connected" % [visited.size(), grass.size()])
    quit(0)
