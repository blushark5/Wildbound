extends RefCounted
## The original three retain the full illustrated bestiary art. The new
## species have their own source SVG poses, packed as Godot textures.
const ORIGINAL = preload("res://scripts/incremental/bestiary_art_v07.gd")
const EXTRA: Array[String] = ["pebblit","mossling","driplet","tidefin","ashcub","emberlyn","zephlet","gustling","skyray"]
static var textures: Dictionary = {}

static func get_creature(kind: String,evolved: bool = false) -> Texture2D:
    if ["spriglet","brinlet","cindlet"].has(kind):
        return ORIGINAL.get_creature(kind,evolved)
    if not EXTRA.has(kind):
        return null
    if not textures.has(kind):
        var path: String = "res://assets/incremental/v12/"+kind+".svg"
        var texture: Texture2D = load(path) as Texture2D
        textures[kind] = texture
    return textures[kind] as Texture2D
