extends SceneTree
# Reproducible original-pixel extraction, not a final authored terrain pack.
const ORIGINAL = "res://assets/willowrest_world.png"
const OUTPUT = "res://assets/environment/terrain_study.png"
const CELL = 24
# Grass x4, path x4, water x4, vegetation x2, shore study x2.
const ORIGINS = [
    Vector2i(760,112),Vector2i(852,106),Vector2i(970,116),Vector2i(792,118),
    Vector2i(580,145),Vector2i(608,144),Vector2i(566,180),Vector2i(690,190),
    Vector2i(54,223),Vector2i(86,246),Vector2i(125,275),Vector2i(52,185),
    Vector2i(836,136),Vector2i(754,136),Vector2i(175,155),Vector2i(335,260)
]
func _initialize() -> void:
    call_deferred("_bake")
func _bake() -> void:
    var img: Image = Image.load_from_file(ProjectSettings.globalize_path(ORIGINAL))
    if img == null or img.get_size() != Vector2i(1152,336):
        push_error("Missing/incorrect original Willowrest illustration")
        quit(1)
        return
    img.convert(Image.FORMAT_RGBA8)
    var atlas: Image = Image.create(CELL * ORIGINS.size(),CELL,false,Image.FORMAT_RGBA8)
    for i in range(ORIGINS.size()):
        atlas.blit_rect(img,Rect2i(ORIGINS[i],Vector2i(CELL,CELL)),Vector2i(i*CELL,0))
    var target: String = ProjectSettings.globalize_path(OUTPUT)
    DirAccess.make_dir_recursive_absolute(target.get_base_dir())
    var err: Error = atlas.save_png(target)
    if err != OK:
        push_error("PNG export failed: " + str(err))
        quit(1)
        return
    print("ART STUDY: 16 unchanged original illustrated 24px cells at " + target)
    quit(0)
