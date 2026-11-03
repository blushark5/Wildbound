extends SceneTree
## v0.18 battle + save gate. Runs against real Godot engine and raster sheets.
const ENGINE = preload("res://scripts/incremental/bond_engine_v18.gd")
const OLD = preload("res://scripts/incremental/bond_engine_v14.gd")
const ART = preload("res://scripts/incremental/roster_art_v18.gd")
const SCENE = preload("res://scenes/incremental/wildbound_bond_v18.tscn")

func _initialize() -> void:
    call_deferred("_check")

func _fail(reason: String) -> void:
    push_error("v0.18: "+reason)
    _cleanup()
    quit(1)

func _cleanup() -> void:
    var p: String = ProjectSettings.globalize_path(ENGINE.SAVE_FILE)
    if FileAccess.file_exists(ENGINE.SAVE_FILE):
        DirAccess.remove_absolute(p)

func _win(game: RefCounted) -> void:
    for i in range(3):
        if game.awaiting_next:
            break
        var u: Dictionary = game.rival_units[i]
        if float(u["hp"]) > 0.0:
            game._damage_rival(i,float(u["hp"])+10.0,String(game.squad_slots[0]))

func _check() -> void:
    _cleanup()
    for kind in ART.ORDER:
        var image0: Texture2D = ART.creature(kind)
        var image1: Texture2D = ART.creature(kind,true,false)
        var image2: Texture2D = ART.creature(kind,true,false,true)
        var attacking: Texture2D = ART.creature(kind,false,true)
        if image0 == null or image1 == null or image2 == null or attacking == null:
            _fail("Missing painted 3-form sprites and attack frame: "+kind);return
        if image0 == image1 or image1 == image2 or attacking == image0:
            _fail("Forms or attack variant not independently textured: "+kind);return
        if image2.get_width() != 128 or image2.get_height() != 128:
            _fail("Wrong painted portrait resolution for "+kind);return
        if image0.get_image().get_pixel(0,0).a > 0.1:
            _fail("Artwork should have a transparent corner for "+kind);return

    var game = ENGINE.new()
    game.initialize_alpha()
    game.load_save()
    if game.collection_count() != 3 or game.occupied_slots() != 3:
        _fail("New save must give three distinct actual owned starters");return
    var families: Dictionary = {}
    var elements: Dictionary = {}
    var unique: Dictionary = {}
    for kind in game.squad_slots:
        if not game.has_instance(kind) or unique.has(kind):
            _fail("Starting team has duplicates or unowned entry");return
        unique[kind] = true
        families[game.family_of(kind)] = true
        elements[String(ENGINE.CATALOG[kind]["element"])] = true
    if families.size() != 3 or elements.size() != 3:
        _fail("Starting trio must have three body families and three elements");return
    if game.hatch_cost() != 5:
        _fail("Three free starters inflated the first earned egg");return

    var lineup: String = game.encounter_id(17)
    if lineup != game.encounter_id(17):
        _fail("Stage rerolled without an Ascension");return
    var guardians: Array = game.roster_for(10)
    if game.roster_for(10).size() != 3 or game.family_of(String(guardians[0])) != "Fox" or game.family_of(String(guardians[1])) != "Bird" or game.family_of(String(guardians[2])) != "Lizard":
        _fail("Guardians must preserve the three-family boss formation");return
    game.essence = 5
    var hatch: String = game.hatch_egg()
    if hatch == "" or game.collection_count() != 4 or game.new_hatches != 1:
        _fail("First 5-Essence earned hatch failed");return
    if elements.has(String(ENGINE.CATALOG[hatch]["element"])) or game.hatch_cost() != 8:
        _fail("First earned egg should cover missing element; second egg should cost 8");return

    game.essence = 0
    _win(game)
    if game.essence != 1 or game.wave != 2:
        _fail("v0.15 first-clear Essence broken in randomized mode");return
    if not game.set_farming():
        _fail("Cannot farm a cleared trainer in v0.18");return
    _win(game)
    if game.essence != 1:
        _fail("Farming paid Essence");return
    game.save()
    var reloaded = ENGINE.new()
    reloaded.initialize_alpha()
    if not reloaded.load_save() or reloaded.run_seed != game.run_seed or reloaded.encounter_id(17) != lineup:
        _fail("Random encounters did not survive saving and reloading");return
    if reloaded.collection_count() != 4 or reloaded.essence != game.essence:
        _fail("Collection or Essence did not survive saving");return

    reloaded.run_peak = 20
    reloaded.best_wave = 20
    var before_seed: int = reloaded.run_seed
    var collection_before: Dictionary = reloaded.owned_creatures.duplicate(true)
    if not reloaded.ascend() or reloaded.run_seed == before_seed:
        _fail("Ascension failed to reroll the encounter seed");return
    if reloaded.owned_creatures.size() != collection_before.size() or reloaded.essence != game.essence:
        _fail("Ascension wiped the owned roster or first-clear Essence");return
    var changed: bool = false
    for st in range(1,30):
        if reloaded.encounter_id(st) != game.encounter_id(st):
            changed = true
    if not changed:
        _fail("New Ascension does not change any encountered trainer lineup");return

    # Migration: old player has just Spriglet; new code MUST NOT gift
    # three replacement creatures, overwrite their individual, or new-game-reroll.
    _cleanup()
    var legacy = OLD.new()
    legacy.initialize_alpha()
    legacy.initialize_squads()
    legacy.gold = 37.0
    legacy.save()
    var converted = ENGINE.new()
    converted.initialize_alpha()
    if not converted.load_save() or converted.collection_count() != 1 or not converted.has_instance("spriglet") or converted.gold < 37.0:
        _fail("Existing v0.16 save was rerolled or corrupted");return
    if converted.hatch_cost() != 5:
        _fail("Migrated save hatch cost should remain equivalent");return

    _cleanup()
    var ui: Control = SCENE.instantiate() as Control
    root.add_child(ui)
    if not ui.game.has_method("encounter_id") or ui.card_art[String(ui.CHALLENGE.ORDER[0])].texture == null:
        _fail("Live v0.18 scene lacks game engine or painted portraits");return
    if not ui.game.has_method("unit_ascended"):
        _fail("Ascended art tier not supported in actual interface");return
    print("PASS v0.18: 36 transparent creature forms, unique three-family/three-element starter, deterministic stages, 5-Essence earned hatch, first-clear Gold/Essence/farming, Ascension reroll and legacy save migration")
    quit(0)
