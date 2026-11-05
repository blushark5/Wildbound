extends RefCounted
## Wildbound v0.35 painted creature presentation, derived from original
## v0.34 transparent illustrated raster assets; not an SVG enlargement.
## Memory-only raster variants are kept separate from the UI and engine.
const SOURCE = preload("res://scripts/duel/concept_art_v34.gd")
static var prepared: bool = false
static var idle: Dictionary = {}
static var strike: Dictionary = {}
static var hurt: Dictionary = {}

static func creature(kind: String, evolved: bool = false, pose: String = "idle") -> Texture2D:
    _prepare()
    if evolved:
        var established: Texture2D = SOURCE.creature(kind,true,pose == "attack")
        if established != null:
            return established
    var bucket: Dictionary = strike if pose == "attack" else hurt if pose == "hurt" else idle
    return bucket.get(kind,null) as Texture2D

static func environment() -> Texture2D:
    return SOURCE.background()

static func _prepare() -> void:
    if prepared:
        return
    prepared = true
    for kind in ["cindlet","brinlet","spriglet"]:
        var source: Texture2D = SOURCE.creature(kind,false)
        if kind == "spriglet":
            # The v0.34 Spriglet atlas contains only a close-up head. Repaint
            # the existing complete illustrated fox anatomy to earth tones
            # to provide a properly grounded, full-body earth combatant.
            source = SOURCE.creature("cindlet",false)
        if source == null:
            continue
        var body: Image = source.get_image()
        body.convert(Image.FORMAT_RGBA8)
        if kind == "spriglet":
            _earth_palette(body)
        idle[kind] = ImageTexture.create_from_image(body)
        var attacking: Image = body.duplicate()
        attacking.adjust_bcs(1.07,1.04,1.06)
        strike[kind] = ImageTexture.create_from_image(attacking)
        var damaged: Image = body.duplicate()
        damaged.adjust_bcs(0.90,1.07,0.88)
        hurt[kind] = ImageTexture.create_from_image(damaged)

static func _earth_palette(img: Image) -> void:
    # Retain ALL the hand-illustrated highlights and fur detail in the
    # original transparent pixels, exchanging fiery reds for foliage greens.
    for y in range(img.get_height()):
        for x in range(img.get_width()):
            var c: Color = img.get_pixel(x,y)
            if c.a < 0.025:
                continue
            var h: float = c.h
            var s: float = c.s
            var v: float = c.v
            if s > 0.18 and (h < 0.17 or h > 0.91):
                var new_h: float = 0.292 if v < 0.70 else 0.235
                img.set_pixel(x,y,Color.from_hsv(new_h,clampf(s*0.88,0.18,0.88),v*0.93,c.a))
            elif s > 0.19 and h < 0.24:
                img.set_pixel(x,y,Color.from_hsv(0.205,clampf(s*0.80,0.15,0.90),v,c.a))
