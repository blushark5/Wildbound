extends SceneTree
const ENGINE = preload("res://scripts/incremental/challenge_engine_v10.gd")
const SCENE = preload("res://scenes/incremental/wildbound_challenge_v10.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _die(why: String) -> void:
    push_error("Wildbound v0.10 QA: "+why)
    quit(1)

func _verify() -> void:
    var game = ENGINE.new()
    game.initialize_alpha()
    game.wave = 1
    game._spawn_enemy()
    game._fit_enemy_to_region()
    if game.awaiting_next or game.auto_advance_unlocked():
        _die("New run should require manual progression");return
    game.attack(game.enemy_hp+1.0)
    if not game.awaiting_next or game.wave != 2 or game.last_stage_cleared != 1:
        _die("Victory should stop until next stage is chosen");return
    var hp: float = game.enemy_hp
    game.tick(0.25)
    game.tap()
    if game.enemy_hp != hp:
        _die("Battle did not pause while awaiting next stage");return
    if not game.enter_next_stage() or game.awaiting_next:
        _die("Next Stage button did not resume combat");return
    game.attack(game.enemy_hp+1.0)
    if not game.awaiting_next or game.wave != 3:
        _die("Second stage bypassed manual choice");return
    game.set_farming()
    if game.awaiting_next or not game.repeat_wave or game.wave != 2:
        _die("Farm should replay previously cleared wave");return
    var gold_before: float = game.gold
    game.attack(game.enemy_hp+1.0)
    if game.wave != 2 or game.gold <= gold_before:
        _die("Farming did not repeat or earn Gold");return
    game.set_farming()
    game.attack(game.enemy_hp+1.0)
    if game.wave != 3 or not game.awaiting_next:
        _die("PUSH should leave farming and stop at next stage");return
    game.wave = 3
    game._spawn_enemy()
    game._fit_enemy_to_region()
    var early_hp: float = game.enemy_max_hp
    game.wave = 8
    game._spawn_enemy()
    game._fit_enemy_to_region()
    if game.challenge_multiplier(8) < 2.0 or game.enemy_max_hp <= early_hp*2.0:
        _die("Early wave difficulty should sharply increase");return
    game.awaiting_next = false
    game.levels["brinlet"] = 1
    game.enemy_species = "cindlet"
    var old_hit: float = game.effective_damage("brinlet")
    if not game.focus("brinlet") or game.effective_damage("brinlet") <= old_hit*2.0:
        _die("Selecting a counter didn't strengthen battle attacks");return
    if not game.element_relation("brinlet").contains("SUPER EFFECTIVE"):
        _die("Tide should counter Ember");return
    var prior: float = game.species_damage("spriglet")
    game.gold = 1000.0
    if not game.buy_levels("spriglet",1) or game.species_damage("spriglet") <= prior*1.18:
        _die("Leveling should noticeably increase creature damage");return
    game.nests = 10
    var eggs_before: int = game.eggs_hatched
    if game.hatch_egg() == "" or game.eggs_hatched != eggs_before+1:
        _die("Eggs should create real progress");return
    game.ascensions = 1
    if not game.auto_advance_unlocked() or not game.toggle_auto_advance():
        _die("Auto next-stage should unlock with Ascension");return
    game.awaiting_next = false
    game.repeat_wave = false
    game.wave = 1
    game._spawn_enemy()
    game._fit_enemy_to_region()
    game.attack(game.enemy_hp+1.0)
    if game.awaiting_next or game.wave != 2:
        _die("Unlockable automation didn't automatically enter next fight");return
    game.toggle_auto_advance()
    game.attack(game.enemy_hp+1.0)
    if not game.awaiting_next or not bool(game.to_dict()["v10_awaiting_next"]):
        _die("Auto OFF didn't restore and save manual stage gating");return

    var ui: Control = SCENE.instantiate() as Control
    root.add_child(ui)
    if ui.get_node_or_null("Focus_spriglet") == null or ui.focus_buttons.size() != 3:
        _die("Focused companion controls are missing");return
    if ui.team_art[0].texture == null or ui.enemy_art.texture == null:
        _die("Illustrated creature or fallback sprites missing");return
    for name in ["v07_bestiary_atlas.webp.base64","v07_evolved_bestiary.webp.base64"]:
        if not FileAccess.file_exists("res://assets/incremental/"+name):
            _die("Browser sprite payload missing: "+name);return
    ui.game.gold = 2000.0
    ui.game.buy_levels("brinlet",1)
    ui.get_node("Focus_brinlet").emit_signal("pressed")
    if ui.game.focused_companion != "brinlet":
        _die("FOCUS wasn't wired to real battle state");return
    ui.game.awaiting_next = true
    ui.game.last_stage_cleared = 1
    ui.game.wave = 2
    ui.call("_refresh")
    if not ui.strike_button.text.contains("NEXT STAGE"):
        _die("Next Stage CTA missing after victory");return
    ui.strike_button.emit_signal("pressed")
    if ui.game.awaiting_next:
        _die("Next Stage CTA doesn't work");return
    if not ui.speed_button.disabled:
        _die("AUTO should be locked before first Ascension");return
    ui.game.ascensions = 1
    ui.call("_refresh")
    if ui.speed_button.disabled:
        _die("AUTO did not unlock after Ascension");return
    print("PASS: guided stages, sharp walls, farming, leveling, elemental focus, eggs, manual/auto, real sprites")
    quit(0)
