extends SceneTree
const ENGINE = preload("res://scripts/incremental/squad_engine_v11.gd")
const SCENE = preload("res://scenes/incremental/wildbound_squads_v11.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _fail(reason: String) -> void:
    push_error("Wildbound v0.11 squad regression: "+reason)
    quit(1)

func _verify() -> void:
    var game = ENGINE.new()
    game.initialize_alpha()
    game.initialize_squads()
    if game.squad_slots != ["spriglet","spriglet","spriglet"]:
        _fail("Starter lineup must let players immediately try three Spriglets");return
    if game.ally_units.size() != 3 or game.rival_units.size() != 3:
        _fail("Not a real six-unit combat state");return
    if game.roster_for(1) != ["brinlet","brinlet","brinlet"]:
        _fail("First rival trainer must have three Tide opponents");return
    if game.roster_for(3) != ["cindlet","cindlet","cindlet"]:
        _fail("The early Ember counter-wall is missing");return
    if game.multiplier("spriglet","brinlet") != 2.0:
        _fail("Grove must demolish Tide");return
    if game.multiplier("spriglet","cindlet") >= 0.5:
        _fail("Grove must be badly resisted by Ember");return
    if game.multiplier("brinlet","cindlet") != 2.0 or game.multiplier("cindlet","spriglet") != 2.0:
        _fail("Elemental circle is broken");return
    var favored_dps: float = game.squad_dps()
    game.wave = 3
    game._spawn_enemy()
    game._fit_enemy_to_region()
    game.initialize_squads()
    if favored_dps < game.squad_dps()*4.0:
        _fail("A mono-element counter must be dramatically stronger than a poor matchup");return
    # Real tick simulation: 3 unfavorable Spriglets should lose to a
    # same-level team of 3 Cindlets without upgrades or player clicking.
    for t in range(550):
        if game.defeats > 0 or game.awaiting_next:
            break
        game.tick(0.2)
    if game.defeats < 1:
        _fail("Early elemental counter-wall is toothless: 3 Spriglets beat 3 Cindlets");return
    if game.wave != 3 or not game.awaiting_next:
        _fail("Defeat should allow REPLAY or FARM at the current wall");return

    game.wave = 4
    game._spawn_enemy()
    game._fit_enemy_to_region()
    game.levels["brinlet"] = 1
    game.levels["cindlet"] = 1
    game.squad_slots = ["spriglet","brinlet","cindlet"]
    game.awaiting_next = false
    game.initialize_squads()
    if game.roster_for(4) != ["spriglet","brinlet","cindlet"]:
        _fail("Mixed trainer roster missing");return
    var ally_targets: Array[int] = []
    var enemy_targets: Array[int] = []
    for unit in game.ally_units:
        ally_targets.append(int(unit["target"]))
    for unit in game.rival_units:
        enemy_targets.append(int(unit["target"]))
    if ally_targets != [1,2,0] or enemy_targets != [1,2,0]:
        _fail("Mixed squads should independently target Tide, Ember, Grove counters");return
    game.rival_units[1]["hp"] = 0.0
    game._refresh_ai_targets()
    if int(game.ally_units[0]["target"]) == 1:
        _fail("Spriglet failed to retarget after Brinlet was KO'd");return
    if int(game.ally_units[1]["target"]) != 2:
        _fail("Brinlet should keep targeting the live Cindlet");return

    game.wave = 1
    game._spawn_enemy()
    game._fit_enemy_to_region()
    game.squad_slots = ["spriglet","spriglet","spriglet"]
    game.awaiting_next = false
    game.initialize_squads()
    var hp_before: float = float(game.rival_units[0]["hp"])
    game._ally_hit(0)
    if float(game.rival_units[0]["hp"]) >= hp_before:
        _fail("Independent ally attack did not damage its selected opponent");return
    if float(game.rival_units[1]["hp"]) < float(game.rival_units[1]["max_hp"]):
        _fail("Attacks improperly damage all three enemies rather than one");return
    var gold_before: float = game.gold
    var kills_before: int = game.kills
    for i in range(3):
        if game.awaiting_next:
            break
        game._damage_rival(i,float(game.rival_units[i]["hp"])+1.0,"spriglet")
    if game.kills != kills_before+1 or game.gold <= gold_before:
        _fail("All 3 rival KOs must pay exactly ONE trainer reward");return
    if game.wave != 2 or not game.awaiting_next:
        _fail("Trainer victory must require the manual NEXT STAGE choice");return
    if not game.enter_next_stage() or game.awaiting_next:
        _fail("NEXT STAGE failed to start a new three-on-three match");return
    if game.roster_for(game.wave) != ["brinlet","spriglet","brinlet"]:
        _fail("Second trainer lineup does not appear after NEXT STAGE");return

    var cap_before: float = float(game.rival_units[0]["max_hp"])
    game.wave = 4
    game._spawn_enemy()
    game._fit_enemy_to_region()
    game.initialize_squads()
    game.squad_slots[1] = "brinlet"
    game.initialize_squads()
    var cap_after: float = float(game.rival_units[0]["max_hp"])
    game.squad_slots[1] = "cindlet"
    game.initialize_squads()
    var cap_again: float = float(game.rival_units[0]["max_hp"])
    if not is_equal_approx(cap_after,cap_again):
        _fail("Swapping units stacked enemy HP by accident");return
    if cap_before <= 0.0:
        _fail("Enemy HP should remain positive");return
    var saved: Dictionary = game.to_dict()
    if not saved.has("v11_squad_slots") or not saved.has("v11_ally_units") or not saved.has("v11_rival_units"):
        _fail("Individual team composition and HP are not persisted");return
    game.ascensions = 1
    if not game.auto_advance_unlocked():
        _fail("The v0.10 late-game auto-advance unlock was lost");return

    var ui: Control = SCENE.instantiate() as Control
    root.add_child(ui)
    if ui.ally_widgets.size() != 3 or ui.rival_widgets.size() != 3:
        _fail("The actual scene does not render three fighters on each side");return
    for index in range(3):
        if ui.ally_widgets[index]["portrait"].texture == null:
            _fail("Missing active ally portrait %d" % index);return
        if ui.rival_widgets[index]["portrait"].texture == null:
            _fail("Missing active enemy portrait %d" % index);return
    if ui.get_node_or_null("SquadAllyVital_0") == null or ui.get_node_or_null("SquadRivalAim_2") == null:
        _fail("Individual HP and attack intent are not shown in the UI");return
    ui.game.gold = 300.0
    ui.call("_switch_tab","GROW")
    ui.call("_recruit_species","brinlet")
    if int(ui.game.levels["brinlet"]) < 1:
        _fail("Can't recruit a second species inside the roster UI");return
    ui.get_node("Focus_brinlet").emit_signal("pressed")
    if ui.game.squad_slots[1] != "brinlet":
        _fail("SWAP action did not change the second combatant");return
    ui.game.wave = 4
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.game.squad_slots = ["spriglet","brinlet","spriglet"]
    ui.game.initialize_squads()
    ui.call("_refresh")
    if not ui.rival_widgets[0]["target"].text.contains("Brinlet") and ui.game.rival_units[0]["target"] >= 0:
        _fail("Enemy targeting HUD isn't updating after a squad change");return
    print("PASS v0.11: six real fighters, clone advantages, automatic counters, live retargeting, KO, Gold, walls, squads, save/UI")
    quit(0)
