extends RefCounted
## Standalone original transparent creature art, with every evolutionary form
## separately cut from the approved Wildbound bestiary (no screenshot UI).
const STARTER := "res://assets/incremental/v07_bestiary_atlas.webp.base64"
const EVOLVED := "res://assets/incremental/v07_evolved_bestiary.webp.base64"
const POS: Dictionary = {"spriglet":0,"brinlet":1,"cindlet":2}
static var loaded: bool = false
static var sprites: Dictionary = {}
static var evolution_art: Dictionary = {}

static func get_creature(kind: String, evolved: bool = false) -> Texture2D:
    if not loaded:
        loaded = true
        _load_sheet(STARTER,96,sprites)
        _load_sheet(EVOLVED,128,evolution_art)
    if evolved:
        return evolution_art.get(kind,sprites.get(kind,null)) as Texture2D
    return sprites.get(kind,null) as Texture2D

static func _load_sheet(path: String, cell: int, into: Dictionary) -> void:
    if not FileAccess.file_exists(path):
        push_warning("Creature illustration atlas missing: "+path)
        return
    var raw: PackedByteArray = Marshalls.base64_to_raw(FileAccess.get_file_as_string(path).strip_edges())
    var picture := Image.new()
    if raw.is_empty() or picture.load_webp_from_buffer(raw) != OK:
        push_warning("Unable to decode creature illustration atlas "+path)
        return
    if picture.get_width() != cell*3 or picture.get_height() != cell:
        push_warning("Creature illustration atlas dimensions invalid: "+path)
        return
    for species in POS:
        var idx: int = int(POS[species])
        var crop: Image = picture.get_region(Rect2i(idx*cell,0,cell,cell))
        into[species] = ImageTexture.create_from_image(crop)
