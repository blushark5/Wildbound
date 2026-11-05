extends RefCounted
## v0.16: true painted raster portraits for the nine expanded Wildbound species.
## Only approved painted artwork may be presented in the live renderer.
const ORDER: Array[String] = [
    "pebblit","mossling","driplet",
    "tidefin","ashcub","emberlyn",
    "zephlet","gustling","skyray"
]
const NORMAL: String = "res://assets/incremental/v16/new9_base.webp.base64"
const EVOLVED: String = "res://assets/incremental/v16/new9_evolved.webp.base64"
static var loaded: bool = false
static var frames: Dictionary = {}

static func get_creature(kind: String,evolved: bool = false,attacking: bool = false) -> Texture2D:
    if not ORDER.has(kind):
        return null
    if not loaded:
        loaded = true
        _load_sheet(NORMAL,false)
        _load_sheet(EVOLVED,true)
    var name: String = kind+("_evolved" if evolved else "_normal")+("_attack" if attacking else "_idle")
    return frames.get(name,null) as Texture2D

static func _load_sheet(path: String,evolved: bool) -> void:
    if not FileAccess.file_exists(path):
        push_error("Wildbound painted bestiary asset missing: "+path)
        return
    var encoded: String = FileAccess.get_file_as_string(path).strip_edges()
    var raw: PackedByteArray = Marshalls.base64_to_raw(encoded)
    var sheet: Image = Image.new()
    if raw.is_empty() or sheet.load_webp_from_buffer(raw) != OK:
        push_error("Wildbound could not decode painted creature atlas: "+path)
        return
    if sheet.get_width() != 384 or sheet.get_height() != 384:
        push_error("Wildbound painted creature sheet must be 384 by 384: "+path)
        return
    for i in range(ORDER.size()):
        var kind: String = ORDER[i]
        var portrait: Image = sheet.get_region(Rect2i((i % 3)*128,(i / 3)*128,128,128))
        var name: String = kind+("_evolved" if evolved else "_normal")
        frames[name+"_idle"] = ImageTexture.create_from_image(portrait)
        # A second actual raster texture gives live attack poses a light
        # boost while movement/lunges/sparks remain driven by combat state.
        # It never replaces the creature with a simplified redraw.
        var attack_image: Image = portrait.duplicate()
        attack_image.adjust_bcs(1.055,1.055,1.10)
        frames[name+"_attack"] = ImageTexture.create_from_image(attack_image)
