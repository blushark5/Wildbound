extends RefCounted
## Wildbound visual-fidelity v0.34. These images are extracted from the
## original Wildbound illustrated concept art, rather than generated geometric
## SVG creature approximations. The combat/save engine is not changed.
const BASE_ATLAS: String = "res://assets/duel/v34/concept_creatures.webp.base64"
const BATTLE: String = "res://assets/duel/v34/verdant_ruins.webp.base64"
const EVOLVED = preload("res://scripts/incremental/roster_art_v18.gd")
const STARTERS: Array[String] = ["cindlet","brinlet","spriglet"]
static var cache_ready: bool = false
static var creature_textures: Dictionary = {}
static var background_texture: Texture2D = null
static var load_success: bool = false

static func background() -> Texture2D:
    _initialize()
    return background_texture

static func creature(kind: String,evolved: bool = false,attacking: bool = false) -> Texture2D:
    _initialize()
    if evolved:
        # Keep the established distinct evolved forms and their original
        # fox/water-fox/earth-species silhouettes rather than flattening progress.
        var evolved_sprite: Texture2D = EVOLVED.creature(kind,true,attacking)
        if evolved_sprite != null:
            return evolved_sprite
    return creature_textures.get(kind,null) as Texture2D

static func _read_webp_b64(path: String) -> Image:
    if not FileAccess.file_exists(path):
        push_error("Wildbound v0.34 missing painted asset: "+path)
        return null
    var text: String = FileAccess.get_file_as_string(path)
    var decoded: PackedByteArray = Marshalls.base64_to_raw(text.strip_edges())
    var image_data := Image.new()
    if decoded.is_empty() or image_data.load_webp_from_buffer(decoded) != OK:
        push_error("Wildbound v0.34 could not decode illustrated game asset: "+path)
        return null
    return image_data

static func _trim_transparent(image_data: Image) -> Image:
    var x0: int = image_data.get_width()
    var y0: int = image_data.get_height()
    var x1: int = -1
    var y1: int = -1
    for y in range(image_data.get_height()):
        for x in range(image_data.get_width()):
            if image_data.get_pixel(x,y).a >= 0.12:
                x0 = mini(x0,x)
                y0 = mini(y0,y)
                x1 = maxi(x1,x)
                y1 = maxi(y1,y)
    if x1 < x0 or y1 < y0:
        return image_data
    var margin: int = 6
    x0 = maxi(0,x0-margin)
    y0 = maxi(0,y0-margin)
    x1 = mini(image_data.get_width()-1,x1+margin)
    y1 = mini(image_data.get_height()-1,y1+margin)
    return image_data.get_region(Rect2i(x0,y0,x1-x0+1,y1-y0+1))

static func _initialize() -> void:
    if cache_ready:
        return
    cache_ready = true
    var atlas: Image = _read_webp_b64(BASE_ATLAS)
    var ruins: Image = _read_webp_b64(BATTLE)
    if atlas == null or ruins == null:
        return
    if atlas.get_width() != 960 or atlas.get_height() != 320:
        push_error("Wildbound v0.34 creatures require a 960x320 transparent atlas")
        return
    if ruins.get_width() != 864 or ruins.get_height() != 529:
        push_error("Wildbound v0.34 battlefield must be 864x529")
        return
    for i in range(STARTERS.size()):
        var species: String = STARTERS[i]
        var square: Image = atlas.get_region(Rect2i(i*320,0,320,320))
        var rendered: Image = _trim_transparent(square)
        creature_textures[species] = ImageTexture.create_from_image(rendered)
    background_texture = ImageTexture.create_from_image(ruins)
    load_success = creature_textures.size() == 3 and background_texture != null
