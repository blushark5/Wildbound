extends RefCounted
## Wildbound v0.36 -- independent painted environment and creature raster
## layers, decoded from a production atlas. The HUD remains native Godot.
const ATLAS_PATH := "res://assets/duel/v36/concept_atlas.webp.base64"
const OLD = preload("res://scripts/duel/premium_art_v35.gd")
const WIDTH := 1024
const HEIGHT := 883
const ENV_HEIGHT := 576
const CELL_WIDTH := 341
const CELL_HEIGHT := 307
const ORDER: Array[String] = ["cindlet","brinlet","spriglet"]
static var initialized := false
static var valid := false
static var base: Dictionary = {}
static var attacks: Dictionary = {}
static var hurts: Dictionary = {}
static var back: Texture2D

static func ready() -> bool:
    _init_atlas()
    return valid

static func environment() -> Texture2D:
    _init_atlas()
    return back if valid else OLD.environment()

static func creature(kind: String,evolved: bool = false,pose: String = "idle") -> Texture2D:
    _init_atlas()
    if not valid:
        return OLD.creature(kind,evolved,pose)
    # Preserve recognizable anatomy across ranks. Feedback variants are
    # derived from the actual transparent painted creature, not placeholders.
    var dictionary: Dictionary = (attacks if pose == "attack" else hurts if pose == "hurt" else base)
    return dictionary.get(kind,base.get(kind,null)) as Texture2D

static func _init_atlas() -> void:
    if initialized:
        return
    initialized = true
    if not FileAccess.file_exists(ATLAS_PATH):
        push_warning("Wildbound v0.36 missing illustrated atlas: "+ATLAS_PATH)
        return
    var packed: PackedByteArray = Marshalls.base64_to_raw(
        FileAccess.get_file_as_string(ATLAS_PATH).strip_edges())
    var picture := Image.new()
    if packed.is_empty() or picture.load_webp_from_buffer(packed) != OK:
        push_error("Wildbound v0.36 painted atlas failed to decode")
        return
    if picture.get_width() != WIDTH or picture.get_height() != HEIGHT:
        push_error("Wildbound v0.36 atlas must be 1024x883")
        return
    back = ImageTexture.create_from_image(picture.get_region(
        Rect2i(0,0,WIDTH,ENV_HEIGHT)))
    for i in range(ORDER.size()):
        var image: Image = picture.get_region(Rect2i(
            i*CELL_WIDTH,ENV_HEIGHT,CELL_WIDTH,CELL_HEIGHT))
        image = _trim(image)
        base[ORDER[i]] = ImageTexture.create_from_image(image)
        var striking := image.duplicate()
        striking.adjust_bcs(1.065,1.04,1.055)
        attacks[ORDER[i]] = ImageTexture.create_from_image(striking)
        var damaged := image.duplicate()
        damaged.adjust_bcs(.96,1.08,.84)
        hurts[ORDER[i]] = ImageTexture.create_from_image(damaged)
    valid = base.size() == 3 and back != null

static func _trim(input: Image) -> Image:
    var start_x := input.get_width()
    var start_y := input.get_height()
    var end_x := -1
    var end_y := -1
    for y in range(input.get_height()):
        for x in range(input.get_width()):
            if input.get_pixel(x,y).a > 0.15:
                start_x = mini(start_x,x)
                start_y = mini(start_y,y)
                end_x = maxi(end_x,x)
                end_y = maxi(end_y,y)
    if end_x < start_x or end_y < start_y:
        return input
    start_x = maxi(start_x-3,0)
    start_y = maxi(start_y-3,0)
    return input.get_region(Rect2i(start_x,start_y,
        mini(end_x-start_x+4,input.get_width()-start_x),
        mini(end_y-start_y+4,input.get_height()-start_y)))
