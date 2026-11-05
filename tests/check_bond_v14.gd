extends SceneTree
const ENGINE = preload("res://scripts/incremental/bond_engine_v14.gd")
const UI = preload("res://scenes/incremental/wildbound_bond_v14.tscn")
const ART = preload("res://scripts/incremental/sprite_frames_v14.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _fail(reason: String) -> void:
    push_error("Wildbound v0.14 progression and sprites: "+reason)
    quit(1)

func _verify() -> void:
    print("V14 CHECKPOINT: prestige-gated individual levels")
    var game = ENGINE.new()
    game.initialize_alpha()
    game.initialize_squads()
    if game.collection_count() != 1 or game.occupied_slots() != 1:
        _fail("One unique starting Spriglet and two empty slots must survive");return
    if game.unit_bond_rank("spriglet") != 1 or game.bond_level_cap("spriglet") != 8:
        _fail("Fresh Bond Rank 1 must cap creature training at level 8");return
    if game.next_bond_goal("spriglet") != 8:
        _fail("First permanent Bond promotion must require 8 battle victories");return
    if game.trail_info()["kind"] != "kills":
        _fail("Opening journey must still start with trainer battles");return
    var initial_damage: float = game.combat_damage("spriglet")
    game.gold = 10000.0
    if not game.level_creature("spriglet",25) or game.unit_level("spriglet") != 8:
        _fail("Batch leveling must stop EXACTLY at individual Bond level cap");return
    if game.combat_damage("spriglet") <= initial_damage:
        _fail("Creature levels must still improve real DPS");return
    var remaining: float = game.gold
    if game.level_creature("spriglet",1) or game.gold != remaining:
        _fail("Level cap cannot be circumvented with extra Gold");return
    var power_before: float = game.combat_damage("spriglet")
    if not game.buy_module("power") or game.combat_damage("spriglet") <= power_before:
        _fail("GENERAL Gold upgrades must keep growing DPS beyond creature caps");return
    if game.level_batch_available("spriglet",25) != 0:
        _fail("Gold batch button must recognize a capped partner");return
    if game.creature_level_price("spriglet",1) != INF:
        _fail("Capped creature should never expose a payable price");return

    # Eight complete trainer victories grant Bond XP but NOT a new rank.
    for win in range(8):
        if game.awaiting_next and not game.enter_next_stage():
            _fail("Manual stage control was lost");return
        for i in range(3):
            if game.awaiting_next:
                break
            game._damage_rival(i,float(game.rival_units[i]["hp"])+1.0,"spriglet")
    if game.kills != 8 or game.unit_bond("spriglet") != 8:
        _fail("Actual trainer victories must build persistent Bond XP");return
    if game.unit_bond_rank("spriglet") != 1 or game.bond_level_cap("spriglet") != 8:
        _fail("Winning battles must NEVER directly promote permanent Bond Rank");return
    if game.bond_progress("spriglet") < 0.99:
        _fail("Full Bond XP should display 100% progress toward Ascension");return
    game.run_peak = 20
    game.best_wave = 20
    if not game.ascend():
        _fail("Ascension after stage 20 must work");return
    if game.unit_bond_rank("spriglet") != 2 or game.bond_level_cap("spriglet") != 13:
        _fail("Ascension with 8 XP must increase Bond Rank and permanent cap");return
    if game.unit_level("spriglet") != 1 or game.modules["power"] != 0 or game.gold != 0.0:
        _fail("New run should reset creature levels, Gold and general modules");return
    if game.unit_bond("spriglet") != 8:
        _fail("Bond victories must survive Ascension as permanent history");return
    if game.next_bond_goal("spriglet") != 20:
        _fail("Second rank must need longer commitment: 20 lifetime wins");return
    game.gold = 10000.0
    if not game.level_creature("spriglet",25) or game.unit_level("spriglet") != 13:
        _fail("Second Bond Rank must allow exactly five additional levels");return
    if game.level_creature("spriglet",1):
        _fail("Cannot bypass second Bond cap before another Ascension");return
    var saved: Dictionary = game.to_dict()
    if saved.get("v14_bond_ranks",{}).get("spriglet",0) != 2:
        _fail("Individual Bond ranks must serialize separately from level XP");return

    print("V14 CHECKPOINT: original multi-pose sprite artwork")
    if ART.creature("spriglet",false,false) == null:
        _fail("Approved original starter sprite missing");return
    for key in ["pebblit","mossling","driplet","tidefin","ashcub","emberlyn","zephlet","gustling","skyray"]:
        for evolved in [false,true]:
            var idle: Texture2D = ART.creature(key,evolved,false)
            var strike: Texture2D = ART.creature(key,evolved,true)
            if idle == null or strike == null:
                _fail("Missing distinct idle/attack frames for "+key);return
            if idle == strike:
                _fail("New creature must have a real illustrated action pose for "+key);return
    if ART.creature("spriglet",true,false) == null:
        _fail("Original species' approved evolved image must remain available");return

    print("V14 CHECKPOINT: full actual battle and user interface")
    var ui: Control = UI.instantiate() as Control
    root.add_child(ui)
    if not ui.sprite_ready or not ui.visual_ready:
        _fail("New sprite and Bond presentation did not initialize");return
    if not ui.game.has_method("bond_level_cap") or ui.game.collection_count() != 1:
        _fail("New UI is not using the actual capped-collection engine");return
    if ui.strike_button.text.find("ASSIST") < 0:
        _fail("Main button must describe its real manual-attack action, not vague STRIKE");return
    if ui.card_details["spriglet"].text.find("/ 8") < 0:
        _fail("Creature card should disclose permanent Bond level cap");return
    if ui.get_node_or_null("CombatSpark_Ally_0") == null or ui.battle_sparks.size() != 6:
        _fail("Unique six-fighter elemental battle effects missing");return
    if ui.get_node_or_null("Tab_GROW") == null or ui.get_node_or_null("FieldGuideOverlay") == null:
        _fail("Gold upgrades and Essence collection remain separate UI systems");return
    ui.game.owned_creatures["zephlet"] = ui.game._new_record("zephlet",91)
    ui.game.assign_creature(1,"zephlet")
    ui.game.ally_units[1]["action"] = 0.22
    ui._animate_fighters()
    if not ui.battle_sparks[2].visible:
        _fail("A real Air creature attack must show its elemental effect");return
    if ui.ally_widgets[1]["portrait"].texture != ART.creature("zephlet",false,true):
        _fail("Live battle did not switch to the new illustrated attack frame");return
    ui.game.awaiting_next = true
    ui.game.last_clash = "TRAINER DEFEATED"
    ui._refresh()
    if ui.strike_button.text.find("NEXT STAGE") < 0:
        _fail("Stage advancement action must be labeled ENTER NEXT STAGE");return
    ui.game.last_clash = "SQUAD DEFEATED"
    ui._refresh()
    if ui.strike_button.text.find("RETRY") < 0:
        _fail("Squad wipes must be labeled RETRY instead of STRIKE");return
    ui.game.awaiting_next = false
    ui._open_codex()
    ui._refresh_codex()
    if not ui.codex_cards["zephlet"]["trait"].text.contains("/8"):
        _fail("Field Guide must show each creature's individual Bond ceiling");return
    if ui.codex_cards.size() != 12 or ui.game.hatch_cost() != 8:
        # A manual test-added species counts in collection, so hatch should
        # become more expensive exactly as it did in v0.12.
        _fail("Field Guide or Essence collection inflation changed");return
    if ui.game.squad_slots[0] == ui.game.squad_slots[1]:
        _fail("A creature cannot be duplicated in active combat");return
    var save_path: String = ui.game.SAVE_FILE
    if FileAccess.file_exists(save_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
    print("PASS v0.14: prestige Bond caps, retained Gold upgrades, honest action button, 36 sprite frames, effects, UI and saves")
    quit(0)
