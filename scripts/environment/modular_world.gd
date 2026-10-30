extends Node2D
# New isolated environment. No full-screen world sprite is drawn.
# 24px tiles; real layer cells, original illustrated trees as movable scenes.
const TILE: int = 24
const WIDTH: int = 48
const HEIGHT: int = 14
const PLAYER_SPAWN: Vector2i = Vector2i(24,7)
const KEEPER: Vector2i = Vector2i(23,8)
const TREE_CELLS: Array[Vector3i] = [
    Vector3i(3,3,0),Vector3i(8,3,1),Vector3i(13,3,2),
    Vector3i(18,2,0),Vector3i(30,3,1),Vector3i(35,3,2),
    Vector3i(42,3,3),Vector3i(4,12,1),Vector3i(15,12,0),
    Vector3i(20,12,3),Vector3i(29,12,0),Vector3i(36,12,1),
    Vector3i(46,12,2)
]
var blocked: Dictionary = {}
var encounters: Dictionary = {}
var ground: TileMapLayer
var roads: TileMapLayer
var water: TileMapLayer
var vegetation: TileMapLayer
var objects: Node2D

func _ready() -> void:
    build()

func _new_layer(label: String, tiles: TileSet, depth: int) -> TileMapLayer:
    var layer := TileMapLayer.new()
    layer.name = label
    layer.tile_set = tiles
    layer.z_index = depth
    layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(layer)
    return layer

func _tile_set() -> TileSet:
    var tex: Texture2D = load("res://assets/environment/terrain_study.png") as Texture2D
    if tex == null or tex.get_size() != Vector2(384,24):
        push_error("Terrain study PNG missing: run environment/bake_terrain.gd")
        return null
    var result := TileSet.new()
    result.tile_size = Vector2i(TILE,TILE)
    result.add_physics_layer()
    result.set_physics_layer_collision_layer(0,1)
    result.set_physics_layer_collision_mask(0,1)
    var atlas := TileSetAtlasSource.new()
    atlas.texture = tex
    atlas.texture_region_size = Vector2i(TILE,TILE)
    for n in range(16):
        atlas.create_tile(Vector2i(n,0))
    result.add_source(atlas,0)
    for n in [8,9,10,11,14,15]:
        var tile: TileData = atlas.get_tile_data(Vector2i(n,0),0)
        tile.add_collision_polygon(0)
        tile.set_collision_polygon_points(0,0,PackedVector2Array([
            Vector2(-12,-12),Vector2(12,-12),
            Vector2(12,12),Vector2(-12,12)
        ]))
    return result

func _stamp(layer: TileMapLayer, cell: Vector2i, art_id: int) -> void:
    layer.set_cell(cell,0,Vector2i(art_id,0))

func build() -> void:
    blocked.clear()
    encounters.clear()
    var tiles: TileSet = _tile_set()
    if tiles == null:
        return
    ground = _new_layer("Ground",tiles,-4)
    roads = _new_layer("Roads",tiles,-3)
    water = _new_layer("Water",tiles,-2)
    vegetation = _new_layer("Vegetation",tiles,-1)
    var ripple := ShaderMaterial.new()
    ripple.shader = load("res://scripts/environment/water_shimmer.gdshader") as Shader
    water.material = ripple
    objects = Node2D.new()
    objects.name = "WorldObjects"
    objects.y_sort_enabled = true
    add_child(objects)
    # Grass and a few art variations. All placement is editable as tile cells.
    for y in range(HEIGHT):
        for x in range(WIDTH):
            var cell := Vector2i(x,y)
            var value: int = posmod(x*31 + y*17 + x*y*3,19)
            _stamp(ground,cell,0 if value < 12 else (1 if value < 16 else 2))
            if x == 0 or y == 0 or x == WIDTH-1 or y == HEIGHT-1:
                blocked[cell] = true
    # A small plaza/route, NOT a copy of a whole baked village background.
    for y in range(6,9):
        for x in range(12,47):
            _stamp(roads,Vector2i(x,y),4 if (x+y)%7 else 5)
    for y in range(2,10):
        for x in range(22,26):
            _stamp(roads,Vector2i(x,y),4 if (x+y)%5 else 6)
    # Water occupies its own tilemap physics layer and grid-blocking cells.
    for y in range(9,13):
        for x in range(2,12):
            var lake_cell := Vector2i(x,y)
            _stamp(water,lake_cell,8+posmod(x*7+y*13,4))
            blocked[lake_cell] = true
    # Real encounter metadata attached to the visible meadow cells.
    for y in range(3,12):
        for x in range(39,46):
            var cell := Vector2i(x,y)
            if roads.get_cell_source_id(cell) != -1:
                continue
            _stamp(vegetation,cell,12 if (x+y)%4 else 13)
            encounters[cell] = true
    _add_tree_instances()
    blocked[KEEPER] = true
    blocked.erase(PLAYER_SPAWN)

func _add_tree_instances() -> void:
    var source: Texture2D = load("res://assets/trees_atlas.png") as Texture2D
    if source == null or source.get_size() != Vector2(256,80):
        push_error("Original illustrated tree atlas unavailable")
        return
    for entry in TREE_CELLS:
        var tile := Vector2i(entry.x,entry.y)
        if roads.get_cell_source_id(tile) != -1 or water.get_cell_source_id(tile) != -1:
            push_warning("Skipping tree on a road/water cell: " + str(tile))
            continue
        var body := StaticBody2D.new()
        body.name = "Tree_%d_%d" % [tile.x,tile.y]
        body.position = cell_center(tile)
        body.collision_layer = 1
        body.collision_mask = 0
        var frame := AtlasTexture.new()
        frame.atlas = source
        frame.region = Rect2i(entry.z*64,0,64,80)
        frame.filter_clip = true
        var graphic := Sprite2D.new()
        graphic.name = "TreeArtwork"
        graphic.texture = frame
        graphic.centered = false
        graphic.position = Vector2(-32,-72)
        graphic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        body.add_child(graphic)
        var collision := CollisionShape2D.new()
        collision.name = "TrunkCollision"
        var trunk := RectangleShape2D.new()
        trunk.size = Vector2(16,11)
        collision.shape = trunk
        collision.position = Vector2(0,-5)
        body.add_child(collision)
        objects.add_child(body)
        blocked[tile] = true

func cell_center(cell: Vector2i) -> Vector2:
    return Vector2(cell.x*TILE + 12,cell.y*TILE + 12)

func is_open(cell: Vector2i) -> bool:
    return cell.x > 0 and cell.y > 0 and cell.x < WIDTH-1 and cell.y < HEIGHT-1 and not blocked.has(cell)

func is_encounter(cell: Vector2i) -> bool:
    return encounters.has(cell) and is_open(cell)
