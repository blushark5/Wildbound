extends RefCounted
## v0.16 style lock: keep Spriglet/Brinlet/Cindlet EXACTLY as their
## approved v0.7 painted atlas. Nine later families use painted v0.16
## raster sprites rather than the rejected v0.14/v0.15 flat SVG drawings.
const ORIGINAL = preload("res://scripts/incremental/bestiary_art_v07.gd")
const PAINTED = preload("res://scripts/incremental/painted_creatures_v16.gd")
const STARTERS: Array[String] = ["spriglet","brinlet","cindlet"]
static var original_attacks: Dictionary = {}

static func creature(kind: String,evolved: bool = false,attacking: bool = false) -> Texture2D:
    if STARTERS.has(kind):
        var approved: Texture2D = ORIGINAL.get_creature(kind,evolved)
        if not attacking or approved == null:
            return approved
        var key: String = kind+("_evolved" if evolved else "_normal")
        if not original_attacks.has(key):
            var img: Image = approved.get_image()
            img.adjust_bcs(1.045,1.035,1.06)
            original_attacks[key] = ImageTexture.create_from_image(img)
        return original_attacks[key] as Texture2D
    return PAINTED.get_creature(kind,evolved,attacking)
