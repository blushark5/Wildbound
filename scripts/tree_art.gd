extends Node2D
# Willowrest environment art study: real transparent pixel sprites extracted
# and cleaned from Wildbound's approved original environment concept.
# Atlas: four 64x80 cells, variations 0-2 broadleaf / 3 evergreen.
# Trunk bases sit on EXISTING blocked tiles. No collision or map changes.
const CELL_SIZE: Vector2i = Vector2i(64, 80)
const GROVE_SPOTS: Array[Vector3i] = [
    Vector3i(25, 5, 0),
    Vector3i(25, 10, 2),
    Vector3i(25, 22, 1),
    Vector3i(25, 26, 3),
]

func _ready() -> void:
    var atlas_image: Texture2D = load("res://assets/trees_atlas.png") as Texture2D
    if atlas_image == null:
        push_error("Wildbound tree atlas unavailable")
        return
    for spot in GROVE_SPOTS:
        var region: AtlasTexture = AtlasTexture.new()
        region.atlas = atlas_image
        region.region = Rect2i(spot.z * CELL_SIZE.x, 0, CELL_SIZE.x, CELL_SIZE.y)
        region.filter_clip = true
        var sprite: Sprite2D = Sprite2D.new()
        sprite.name = "Tree_%d_%d" % [spot.x, spot.y]
        sprite.texture = region
        sprite.centered = false
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        # Foot of the tree is anchored on the already impassable central grove.
        var foot: Vector2 = Vector2(spot.x * 16 + 8, (spot.y + 1) * 16)
        sprite.position = foot - Vector2(32, 80)
        add_child(sprite)
