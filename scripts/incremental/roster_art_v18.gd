extends RefCounted
## v0.18: approved 12×3 elemental roster (Fire, Water, Earth, Air by columns;
## Fox, Bird, Lizard by rows), extracted from the signed-off concept layout.
const ORDER: Array[String] = [
    "cindlet","brinlet","spriglet","gustling",
    "emberlyn","tidefin","mossling","zephlet",
    "ashcub","driplet","pebblit","skyray"
]
const FILES: Array[String] = [
    "res://assets/incremental/v18/base.webp.base64",
    "res://assets/incremental/v18/evolved.webp.base64",
    "res://assets/incremental/v18/ascended.webp.base64"
]
static var loaded: bool = false
static var atlas: Dictionary = {}

static func creature(kind: String,evolved: bool = false,attacking: bool = false,ascended: bool = false) -> Texture2D:
    if not ORDER.has(kind):
        return null
    if not loaded:
        loaded = true
        for tier in range(FILES.size()):
            _load_atlas(FILES[tier],tier)
    var form: int = 2 if ascended else (1 if evolved else 0)
    return atlas.get(kind+"_"+str(form)+("_attack" if attacking else "_idle"),null) as Texture2D

static func _load_atlas(path: String,tier: int) -> void:
    if not FileAccess.file_exists(path):
        push_error("Missing v0.18 roster atlas: "+path)
        return
    var raw: PackedByteArray = Marshalls.base64_to_raw(FileAccess.get_file_as_string(path).strip_edges())
    var picture: Image = Image.new()
    if raw.is_empty() or picture.load_webp_from_buffer(raw) != OK:
        push_error("Invalid v0.18 roster atlas: "+path)
        return
    if picture.get_width() != 512 or picture.get_height() != 384:
        push_error("v0.18 atlas dimensions must be 512×384: "+path)
        return
    for i in range(ORDER.size()):
        var kind: String = ORDER[i]
        var region: Image = picture.get_region(Rect2i((i % 4)*128,(i / 4)*128,128,128))
        atlas[kind+"_"+str(tier)+"_idle"] = ImageTexture.create_from_image(region)
        var strike: Image = region.duplicate()
        strike.adjust_bcs(1.055,1.04,1.055)
        atlas[kind+"_"+str(tier)+"_attack"] = ImageTexture.create_from_image(strike)
