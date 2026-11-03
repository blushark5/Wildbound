extends SceneTree
const JOURNEY = preload("res://scenes/incremental/wildbound_journey_v09.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _fail(why: String) -> void:
    push_error("Wildbound v0.9 journey QA: "+why)
    quit(1)

func _verify() -> void:
    var ui: Control = JOURNEY.instantiate() as Control
    root.add_child(ui)
    if ui.get_node_or_null("BattlePanel") == null or ui.get_node_or_null("JourneyPanel") == null:
        _fail("Core battle and clearly signposted journey are missing"); return
    if ui.get_node_or_null("PackPanel") == null or ui.get_node_or_null("SidebarPanel") == null:
        _fail("Clean independent pack/progression hierarchy missing"); return
    if ui.get_node_or_null("PackCard_spriglet") == null or ui.get_node_or_null("SidebarCards") == null:
        _fail("Creature cards or contextual sidebar missing"); return
    if ui.get_node_or_null("PackCard_cindlet") == null:
        _fail("All three distinct creatures must remain accessible"); return
    if ui.stage_steps.size() != 10 or ui.game.TRAIL.size() < 8:
        _fail("Guardian beat and full opening journey are missing"); return
    if ui.game.TRAIL[4]["kind"] != "guardian":
        _fail("First Guardian isn't a real authored progression milestone"); return
    var power_before: float = ui.game.species_damage("spriglet")
    ui.game.trail_rank = 0
    ui.game.kills = 3
    ui.game.gold = 0.0
    if not ui.game.trail_ready():
        _fail("First objective not recognized when actual kills reached"); return
    ui.get_node("ClaimTrail").emit_signal("pressed")
    if ui.game.trail_rank != 1 or ui.game.gold < 45.0:
        _fail("Claim action doesn't award real earned Gold"); return
    if ui.game.species_damage("spriglet") <= power_before:
        _fail("Permanent trail damage progression isn't real"); return
    if ui.game.trail_ready():
        _fail("Quest can be double-claimed"); return
    if int(ui.game.to_dict().get("v09_trail_rank",-1)) != 1:
        _fail("Permanent journey state isn't serialized"); return
    ui.game.gold = 1000.0
    ui.get_node("Buy_brinlet").emit_signal("pressed")
    ui.get_node("Buy_cindlet").emit_signal("pressed")
    if int(ui.game.levels["brinlet"]) < 1 or int(ui.game.levels["cindlet"]) < 1:
        _fail("Real companion recruiting broken"); return
    ui.call("_refresh")
    if not ui.team_art[1].visible or not ui.team_art[2].visible:
        _fail("All three companions must appear in the battlefield"); return
    if ui.enemy_art.texture == null or ui.team_art[0].texture == null:
        _fail("Original creature artwork missing"); return
    if ui.game.levels["spriglet"] < 1:
        _fail("Starting creature missing"); return
    var previous_enemy: float = ui.game.enemy_hp
    ui.get_node("Strike").emit_signal("pressed")
    if ui.game.enemy_hp >= previous_enemy and ui.game.wave == 1:
        _fail("Live STRIKE input not wired to actual combat"); return
    ui.game.wave = 10
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.call("_refresh")
    if not ui.screen_labels["EnemyName"].text.contains("GUARDIAN"):
        _fail("Guardian battle lacks a visible reveal"); return
    if ui.enemy_art.texture == null or ui.enemy_art.texture.get_width() != 128:
        _fail("Evolved illustrated Guardian image missing"); return
    if ui.stage_steps[9].color != ui.GOLD:
        _fail("Guardian journey strip isn't reacting to boss wave"); return
    ui.call("_switch_tab","NEST")
    if ui.active_rows.size() < 2:
        _fail("Nest content missing"); return
    ui.call("_switch_tab","LEGACY")
    if ui.active_rows.size() < 8:
        _fail("Permanent prestige and research options lost"); return
    ui.call("_switch_tab","WORLD")
    if ui.active_rows.size() < 8:
        _fail("Region and tactical controls lost"); return
    print("PASS v0.9: 10 real quest beats, gold/reward/persistent bonuses, all party art, combat and legacy tabs")
    quit(0)
