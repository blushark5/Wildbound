extends SceneTree
## v0.16 art-only gate. Gameplay and saves MUST remain untouched.
const ORIGINAL = preload("res://scripts/incremental/bestiary_art_v07.gd")
const PAINTED = preload("res://scripts/incremental/painted_creatures_v16.gd")
const RIG = preload("res://scripts/incremental/sprite_frames_v14.gd")
const GAME = preload("res://scripts/incremental/bond_engine_v14.gd")

func _initialize() -> void:
    call_deferred("_check")

func _fail(reason: String) -> void:
    push_error("Wildbound painted v0.16 art regression: "+reason)
    quit(1)

func _check() -> void:
    for kind in ["spriglet","brinlet","cindlet"]:
        for evolved in [false,true]:
            if RIG.creature(kind,evolved,false) != ORIGINAL.get_creature(kind,evolved):
                _fail("Approved original starter illustration was replaced: "+kind);return
            if RIG.creature(kind,evolved,true) == null:
                _fail("Starter attack art missing: "+kind);return
    var families: Array[String] = [
        "pebblit","mossling","driplet","tidefin","ashcub",
        "emberlyn","zephlet","gustling","skyray"
    ]
    for kind in families:
        for evolved in [false,true]:
            var idle: Texture2D = RIG.creature(kind,evolved,false)
            var strike: Texture2D = RIG.creature(kind,evolved,true)
            if idle == null or strike == null or idle == strike:
                _fail("A true painted variant is missing for "+kind);return
            if idle.get_width() != 128 or idle.get_height() != 128:
                _fail("Painted portrait must be 128x128: "+kind);return
            if idle.get_image().get_pixel(0,0).a > 0.15:
                _fail("Painted portrait background should be transparent: "+kind);return
            if idle != PAINTED.get_creature(kind,evolved,false):
                _fail("Renderer did not use the new painted atlas for "+kind);return
        if RIG.creature(kind,false,false) == RIG.creature(kind,true,false):
            _fail("Evolved artwork must be a distinct painted illustration: "+kind);return
    var game = GAME.new()
    game.initialize_alpha()
    game.initialize_squads()
    if game.bond_level_cap("spriglet") != 8 or game.essence != 0 or game.hatch_cost() != 5:
        _fail("Art-only pass changed gameplay or starting economy");return
    print("PASS v0.16: exact approved starter restorations, nine painted + nine evolved raster creatures, transparent portraits, animated attack textures, unchanged gameplay")
    quit(0)
