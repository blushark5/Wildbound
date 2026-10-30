extends SceneTree
# Technical extraction ONLY. All tile pixels are from original Wildbound art.
# Searches for clean, low-seam samples to avoid crops containing buildings,
# trunks, flowers, water reeds or cross-terrain fragments.
const ORIGINAL = "res://assets/willowrest_world.png"
const OUTPUT = "res://assets/environment/terrain_study.png"
const CELL = 24

func _initialize() -> void:
    call_deferred("_bake")

func _is_class(c: Color, kind: int) -> bool:
    if kind == 0: # grassy ground
        return c.g > c.r * 1.13 and c.g > c.b * 1.04 and c.g > 0.28
    if kind == 1: # warm earthen pathway
        return c.r > 0.53 and c.g > 0.34 and c.r > c.g * 1.06 and c.g > c.b * 1.16
    # saturated water blue, rather than brown, green or roof pixels
    return c.b > c.r * 1.45 and c.g > c.r * 1.18 and c.b > c.g * 0.94 and c.b > 0.30

func _evaluate(img: Image, at: Vector2i, kind: int) -> float:
    var matches: int = 0
    for y in range(CELL):
        for x in range(CELL):
            if _is_class(img.get_pixel(at.x+x,at.y+y),kind):
                matches += 1
    var purity: float = float(matches) / float(CELL*CELL)
    if purity < 0.88:
        return -100.0
    var seams: float = 0.0
    for i in range(CELL):
        var left: Color = img.get_pixel(at.x,at.y+i)
        var right: Color = img.get_pixel(at.x+CELL-1,at.y+i)
        var top: Color = img.get_pixel(at.x+i,at.y)
        var bottom: Color = img.get_pixel(at.x+i,at.y+CELL-1)
        seams += absf(left.r-right.r)+absf(left.g-right.g)+absf(left.b-right.b)
        seams += absf(top.r-bottom.r)+absf(top.g-bottom.g)+absf(top.b-bottom.b)
    return purity * 100.0 - seams / float(CELL*6) * 55.0

func _select(img: Image, area: Rect2i, kind: int, count: int) -> Array[Vector2i]:
    var ranked: Array[Dictionary] = []
    for y in range(area.position.y,area.end.y-CELL,8):
        for x in range(area.position.x,area.end.x-CELL,8):
            var at := Vector2i(x,y)
            var score: float = _evaluate(img,at,kind)
            if score > 75.0:
                ranked.append({"at":at,"score":score})
    ranked.sort_custom(func(a: Dictionary,b: Dictionary) -> bool:
        return float(a["score"]) > float(b["score"])
    )
    var picked: Array[Vector2i] = []
    for entry in ranked:
        var at: Vector2i = entry["at"]
        var too_close: bool = false
        for chosen in picked:
            if at.distance_to(chosen) < 48.0:
                too_close = true
                break
        if too_close:
            continue
        picked.append(at)
        if picked.size() == count:
            break
    return picked

func _bake() -> void:
    var img: Image = Image.load_from_file(ProjectSettings.globalize_path(ORIGINAL))
    if img == null or img.get_size() != Vector2i(1152,336):
        push_error("Missing original illustrated Wildbound source")
        quit(1)
        return
    img.convert(Image.FORMAT_RGBA8)
    var chosen: Array[Vector2i] = []
    chosen.append_array(_select(img,Rect2i(190,38,944,275),0,4))
    chosen.append_array(_select(img,Rect2i(430,90,665,150),1,4))
    chosen.append_array(_select(img,Rect2i(5,170,190,155),2,4))
    if chosen.size() != 12:
        push_error("Could not locate 4 clean grass, path and water tiles; found " + str(chosen.size()))
        quit(1)
        return
    # Decoration/shore edge studies must still be replaced by polished art.
    chosen.append_array([Vector2i(836,136),Vector2i(754,136),Vector2i(175,155),Vector2i(335,260)])
    var atlas: Image = Image.create(CELL*chosen.size(),CELL,false,Image.FORMAT_RGBA8)
    for i in range(chosen.size()):
        atlas.blit_rect(img,Rect2i(chosen[i],Vector2i(CELL,CELL)),Vector2i(i*CELL,0))
    var target: String = ProjectSettings.globalize_path(OUTPUT)
    DirAccess.make_dir_recursive_absolute(target.get_base_dir())
    if atlas.save_png(target) != OK:
        push_error("Could not write the approved-pixel sample atlas")
        quit(1)
        return
    print("Terrain study atlas selected original crop origins: " + str(chosen))
    quit(0)
