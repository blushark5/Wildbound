extends Node2D
# Small-scale Willowrest tree art study using four original concept-derived PNGs.
# Deliberately place them on the inaccessible outer boundary, not the
# one-tile-wide interior divider: otherwise the canopy covers walkable ground.
# No proximity fades, visibility tricks, collision or save changes.
const SOURCE_CELL: Vector2i = Vector2i(64, 80)
const DISPLAY_CELL: Vector2i = Vector2i(32, 40)
# Sprite foot positions in map pixels; first two are in the northern forest.
# The other two sit partly offscreen on the left/right boundary like the
# pre-existing border artwork. All avoid every accessible player tile.
const TREE_SPOTS: Array[Vector3i] = [
    Vector3i(36 * 16 + 8, 32, 0),
    Vector3i(39 * 16 + 8, 32, 2),
    Vector3i(8, 15 * 16, 1),
    Vector3i(51 * 16 + 8, 18 * 16, 3),
]

func _ready() -> void:
    var atlas: Texture2D = load("res://assets/trees_atlas.png") as Texture2D
    if atlas == null:
        push_error("Wildbound tree atlas unavailable")
        return
    var source: Image = atlas.get_image()
    if source == null or source.is_empty():
        push_error("Wildbound tree atlas could not be read")
        return
    source.convert(Image.FORMAT_RGBA8)
    var frames: Array[Texture2D] = []
    for i in range(4):
        var img: Image = source.get_region(Rect2i(i * SOURCE_CELL.x, 0, SOURCE_CELL.x, SOURCE_CELL.y))
        # Integer-sized half-resolution pixels, no smoothing or new art noise.
        img.resize(DISPLAY_CELL.x, DISPLAY_CELL.y, Image.INTERPOLATE_NEAREST)
        frames.append(ImageTexture.create_from_image(img))
    for spot in TREE_SPOTS:
        var sprite: Sprite2D = Sprite2D.new()
        sprite.name = "Tree_at_%d_%d" % [spot.x, spot.y]
        sprite.texture = frames[spot.z]
        sprite.centered = false
        sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        sprite.position = Vector2(spot.x - DISPLAY_CELL.x / 2, spot.y - DISPLAY_CELL.y)
        add_child(sprite)
