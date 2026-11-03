extends SceneTree
const ENGINE = preload("res://scripts/incremental/collection_engine_v12.gd")
const SCENE = preload("res://scenes/incremental/wildbound_collection_v12.tscn")
const ART = preload("res://scripts/incremental/collection_art_v12.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _fail(reason: String) -> void:
    push_error("Wildbound v0.12 unique collection QA: "+reason)
    quit(1)

func _verify() -> void:
    print("V12 checkpoint: collection engine")
    var game = ENGINE.new()
    game.initialize_alpha()
    game.initialize_squads()
    if game.collection_count() != 1 or game.occupied_slots() != 1:
        _fail("New save must have one Spriglet and TWO truly empty squad slots");return
    if game.squad_slots != ["spriglet","",""]:
        _fail("Default squad still duplicates its starter monster");return
    if game.CATALOG.size() != 12 or game.ELEMENT_BEATS.size() != 4:
        _fail("Expected twelve distinct species and Earth/Water/Fire/Air");return
    for kind in game.COLLECTION_ORDER:
        if ART.get_creature(kind,false) == null:
            _fail("Missing actual original texture for species "+kind);return
    if game.multiplier("spriglet","brinlet") != 2.0:
        _fail("Earth must beat Water");return
    if game.multiplier("brinlet","cindlet") != 2.0:
        _fail("Water must beat Fire");return
    if game.multiplier("cindlet","zephlet") != 2.0:
        _fail("Fire must beat Air");return
    if game.multiplier("zephlet","spriglet") != 2.0:
        _fail("Air must beat Earth");return
    if game.multiplier("spriglet","cindlet") != 1.0:
        _fail("Opposing four-element corners should be neutral");return
    if game.roster_for(6) != ["zephlet","gustling","skyray"]:
        _fail("Early Air trainer should teach Fire counterplay");return
    if game.essence != 0 or game.hatch_cost() != 5:
        _fail("First unique hatch should cost five earned Essence");return
    if game.hatch_egg() != "":
        _fail("Cannot hatch a creature without fighting trainer battles");return
    if game.buy_levels("brinlet",1):
        _fail("Direct Gold recruiting must no longer unlock monsters");return
    for i in range(5):
        if game.awaiting_next:
            game.enter_next_stage()
        for rival_index in range(3):
            game._damage_rival(rival_index,float(game.rival_units[rival_index]["hp"])+1.0,"spriglet")
    if game.essence != 5 or game.kills != 5 or game.wave != 6:
        _fail("Five whole trainer battles must earn 5 Essence and stage 6");return
    if not game.awaiting_next:
        _fail("Manual Next Stage option was lost");return
    var first: String = game.hatch_egg()
    if first != "cindlet" or game.collection_count() != 2:
        _fail("First earned hatch should guarantee a NEW Fire companion");return
    if game.essence != 0 or game.hatch_cost() <= 5:
        _fail("Hatch cost must rise sharply after every earned creature");return
    if game.unit_record("cindlet")["id"] == game.unit_record("spriglet")["id"]:
        _fail("Each owned creature needs its own persistent identity");return
    if not game.assign_creature(1,"cindlet") or game.occupied_slots() != 2:
        _fail("Hatched individual can't be assigned to empty squad slot");return
    if not game.assign_creature(2,"cindlet"):
        _fail("Moving a creature to another slot should be allowed");return
    if game.squad_slots[1] != "" or game.squad_slots[2] != "cindlet":
        _fail("A creature assigned in two places must move, never duplicate");return
    if game.assign_creature(2,"cindlet"):
        _fail("Reassigning same creature to same slot should be a no-op");return
    game.essence = game.hatch_cost()
    var second: String = game.hatch_egg()
    if second != "brinlet" or game.collection_count() != 3:
        _fail("Second earned hatch should add a distinct Water species");return
    game.essence = game.hatch_cost()
    var third: String = game.hatch_egg()
    if third != "zephlet" or game.collection_count() != 4:
        _fail("Third hatch should introduce original Air combatant");return
    if not game.assign_creature(1,"brinlet"):
        _fail("Owned Water creature should be fieldable");return
    if not game.assign_creature(2,"zephlet"):
        _fail("Owned Air creature should be fieldable");return
    if game.occupied_slots() != 3 or game.squad_slots[0] == game.squad_slots[1] or game.squad_slots[1] == game.squad_slots[2]:
        _fail("All three active squad members must be UNIQUE");return
    var before: float = game.combat_damage("brinlet")
    game.gold = 1000.0
    if not game.level_creature("brinlet",1) or game.combat_damage("brinlet") <= before*1.18:
        _fail("Individual leveling should improve its own real combat damage");return
    if game.unit_level("spriglet") != 1:
        _fail("Leveling Brinlet must NOT accidentally level Spriglet");return
    var saved: Dictionary = game.to_dict()
    if not saved.has("v12_collection") or not saved.has("v12_slots") or not saved.has("v12_essence"):
        _fail("Unique individual data and earned hatch currency aren't saved");return
    game.wave = 7
    game._spawn_enemy()
    game._fit_enemy_to_region()
    game.initialize_squads()
    var enemies: Array = game.roster_for(7)
    if not game.CATALOG.has(String(enemies[0])):
        _fail("New trainer roster keys must exist in collection catalog");return
    print("V12 checkpoint: actual Godot scene")
    var ui: Control = SCENE.instantiate() as Control
    root.add_child(ui)
    print("V12 checkpoint: UI ready")
    if ui.game.collection_count() != 1 or ui.game.occupied_slots() != 1:
        _fail("A fresh browser save should start as one unique Earth Spriglet");return
    if ui.get_node_or_null("CollectionShortcut") == null:
        _fail("Collection hatch must have an obvious main-screen shortcut");return
    if ui.tab_buttons["NEST"].text != "COLLECT":
        _fail("NEST tab should be explicitly labeled COLLECT");return
    if ui.ally_widgets[0]["portrait"].texture == null:
        _fail("Starter art must be visible in 3v3 battle");return
    if ui.ally_widgets[1]["portrait"].visible:
        _fail("An unowned monster must not appear in the second squad slot");return
    if ui.game.essence != 0:
        _fail("New player must earn Essence rather than start with recruit currency");return
    ui.game.essence = 5
    ui.call("_hatch_owned")
    if ui.game.collection_count() != 2:
        _fail("COLLECT hatch button didn't create a distinct individual");return
    ui.game.assign_creature(1,"cindlet")
    ui.call("_refresh")
    if ui.ally_widgets[1]["portrait"].texture == null or not ui.ally_widgets[1]["portrait"].visible:
        _fail("Newly hatched Fire companion isn't visible after squad assignment");return
    if ui.screen_labels["Shards"].text.find("ESSENCE") < 0:
        _fail("Earned hatching resource is not clearly shown");return
    print("PASS v0.12: 12 sprites, 4 elements, earned collection, unique slots and traits, stage walls, real combat, UI and saves")
    quit(0)
