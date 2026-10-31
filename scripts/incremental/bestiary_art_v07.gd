extends RefCounted
## Three original independently masked transparent bestiary sprites.
## Approved Wildbound concept illustration -> segmentation -> RGBA WebP.
## Future evolutions will use authored forms; older battle art remains fallback.
const PATH := "res://assets/incremental/v07_bestiary_atlas.webp.base64"
const SPECIES_POS: Dictionary = {"spriglet":0,"brinlet":1,"cindlet":2}
static var loaded: bool = false
static var textures: Dictionary = {}

static func get_creature(kind: String) -> Texture2D:
    if not loaded:
        _load()
    return textures.get(kind,null) as Texture2D

static func _load() -> void:
    loaded = true
    if not FileAccess.file_exists(PATH):
        push_warning("v0.7 original sprite atlas not found; falling back to old battle artwork")
        return
    var text: String = FileAccess.get_file_as_string(PATH).strip_edges()
    var binary: PackedByteArray = Marshalls.base64_to_raw(text)
    if binary.is_empty():
        push_warning("Unable to decode creature atlas base64")
        return
    var image := Image.new()
    if image.load_webp_from_buffer(binary) != OK:
        push_warning("Unable to load creature WebP")
        return
    if image.get_width() != 288 or image.get_height() != 96:
        push_warning("Unexpected sprite atlas size; skipping replacement")
        return
    for kind in SPECIES_POS:
        var i: int = int(SPECIES_POS[kind])
        var crop: Image = image.get_region(Rect2i(i*96,0,96,96))
        textures[kind] = ImageTexture.create_from_image(crop)
