extends RefCounted
## Original concept portrait study. These images are separate raster crops,
## decoded from a compact WebP atlas; they are NOT the full UI screenshot.
## Old independent front/back game sprites remain fallback and battle art.
const ATLAS_PATH := "res://assets/incremental/portraits_v06.webp.base64"
const KIND_INDEX := {"spriglet":0,"brinlet":1,"cindlet":2}
static var portraits: Dictionary = {}
static var tried: bool = false

static func portrait(kind: String) -> Texture2D:
    if not tried:
        _prepare()
    return portraits.get(kind,null) as Texture2D

static func _prepare() -> void:
    tried = true
    if not FileAccess.file_exists(ATLAS_PATH):
        push_warning("Concept portrait atlas not in Web export; using original sprite fallback")
        return
    var base64_text: String = FileAccess.get_file_as_string(ATLAS_PATH).strip_edges()
    var raw_data: PackedByteArray = Marshalls.base64_to_raw(base64_text)
    if raw_data.is_empty():
        push_warning("Could not decode original portrait art")
        return
    var full := Image.new()
    if full.load_webp_from_buffer(raw_data) != OK:
        push_warning("Could not open WebP original portrait study")
        return
    if full.get_width() != 144 or full.get_height() != 64:
        push_warning("Original portrait sheet has unexpected dimensions")
        return
    for kind in KIND_INDEX:
        var index: int = int(KIND_INDEX[kind])
        var frame: Image = full.get_region(Rect2i(index*48,0,48,64))
        portraits[kind] = ImageTexture.create_from_image(frame)
