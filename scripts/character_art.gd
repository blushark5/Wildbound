extends RefCounted
# Wildbound protagonist: independently illustrated 3-frame walk cycles.
# Art source: original Wildbound animation concept, not Nintendo assets.
# 72x128 sheet: 3 columns x 4 facings, each cell 24x32 logical pixels.
# Columns: left-foot step, standing, right-foot step.
# Rows: down, up, left, right.
const CELL_SIZE: Vector2i = Vector2i(24, 32)
const FACING_ROWS: Dictionary = {"down":0, "up":1, "left":2, "right":3}
var spritesheet: Texture2D
var cached_frames: Dictionary = {}

func sprite(facing: String, pose: int = 0) -> Texture2D:
    if not FACING_ROWS.has(facing):
        facing = "down"
    var column: int = 1
    if pose == 1:
        column = 0
    elif pose == 2:
        column = 2
    var key: String = "%s:%d" % [facing, column]
    if cached_frames.has(key):
        return cached_frames[key]
    if spritesheet == null:
        spritesheet = load("res://assets/hero_walk_sheet.png") as Texture2D
        if spritesheet == null:
            push_error("Missing hero_walk_sheet.png")
            return null
    var atlas: AtlasTexture = AtlasTexture.new()
    atlas.atlas = spritesheet
    atlas.region = Rect2i(column * CELL_SIZE.x, int(FACING_ROWS[facing]) * CELL_SIZE.y, CELL_SIZE.x, CELL_SIZE.y)
    atlas.filter_clip = true
    cached_frames[key] = atlas
    return atlas
