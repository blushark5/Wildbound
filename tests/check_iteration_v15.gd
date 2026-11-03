extends SceneTree
const ENGINE = preload("res://scripts/incremental/bond_engine_v14.gd")
const UI = preload("res://scenes/incremental/wildbound_bond_v14.tscn")
const ART = preload("res://scripts/incremental/sprite_frames_v14.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _fail(why: String) -> void:
    push_error("Wildbound v0.15: "+why)
    quit(1)

func _win(game: Node) -> void:
    for i in range(3):
        if game.awaiting_next:
            break
        var foe: Dictionary = game.rival_units[i]
        if float(foe["hp"]) > 0.0:
            game._damage_rival(i,float(foe["hp"])+100.0,"spriglet")

func _verify() -> void:
    var game = ENGINE.new()
    game.initialize_alpha()
    game.initialize_squads()
    if game.essence != 0 or game.wave != 1 or game.set_farming():
        _fail("Fresh start cannot farm before clearing stage 1");return
    _win(game)
    if game.essence != 1 or game.wave != 2 or not game.awaiting_next:
        _fail("First stage must award precisely 1 Essence and await next stage");return
    var before_gold: float = game.gold
    var before_bond: int = game.unit_bond("spriglet")
    if not game.set_farming() or game.wave != 1 or not game.repeat_wave:
        _fail("Farm action must go back to previously cleared stage");return
    _win(game)
    if game.essence != 1 or game.gold <= before_gold or game.unit_bond("spriglet") <= before_bond:
        _fail("Farm must give Gold and Bond XP but zero Essence");return
    if not game.set_farming() or game.repeat_wave:
        _fail("Resume Push action should end Farm mode");return
    _win(game)
    if game.wave != 2 or game.essence != 1:
        _fail("Pushing an already-cleared stage must not duplicate Essence");return
    if not game.enter_next_stage():
        _fail("After replay, must be able to enter the next stage");return
    _win(game)
    if game.essence != 2 or game.wave != 3:
        _fail("New lifetime stage 2 clear must award 1 Essence");return
    if not game.enter_next_stage():
        _fail("Must enter unbeaten stage before wall test");return
    game._regroup()
    if not game.awaiting_next or game.wave != 3:
        _fail("Defeat must preserve wall at stage 3");return
    if not game.set_farming() or game.wave != 2 or not game.repeat_wave:
        _fail("Farm after a wipe must replay last beaten stage 2");return
    _win(game)
    if game.essence != 2:
        _fail("Farming after hitting a wall must grant zero Essence");return
    if not game.set_farming() or game.repeat_wave:
        _fail("Cannot return to PUSH mode from a wall");return
    game.run_peak = 20
    game.best_wave = 20
    if not game.ascend():
        _fail("Ascension must still be available after stage 20");return
    if game.wave != 1 or game.best_wave != 20 or game.essence != 2:
        _fail("Ascension must retain lifetime cleared stages and Essence");return
    _win(game)
    if game.essence != 2:
        _fail("Ascension replay must NOT re-award previously cleared stage Essence");return
    game.wave = 20
    game.best_wave = 20
    game.repeat_wave = false
    game.awaiting_next = false
    game._spawn_enemy()
    game._fit_enemy_to_region()
    game.initialize_squads()
    _win(game)
    if game.essence != 6 or game.best_wave != 21:
        _fail("First-ever stage 20 Guardian must award exactly 4 Essence");return
    for kind in ["spriglet","brinlet","cindlet","pebblit","mossling","driplet","tidefin","ashcub","emberlyn","zephlet","gustling","skyray"]:
        for evolved in [false,true]:
            var idle: Texture2D = ART.creature(kind,evolved,false)
            var attack: Texture2D = ART.creature(kind,evolved,true)
            if idle == null or attack == null or idle == attack:
                _fail("Original unique idle/attack art missing for "+kind);return
    var ui: Control = UI.instantiate() as Control
    root.add_child(ui)
    ui._refresh()
    if not ui.repeat_button.text.contains("FARM") or not ui.screen_labels["Shards"].tooltip_text.contains("No balance cap"):
        _fail("New Farm action and Essence explanation not shown");return
    ui.game.wave = 4
    ui.game.awaiting_next = true
    ui._refresh()
    ui.repeat_button.emit_signal("pressed")
    if not ui.game.repeat_wave or ui.game.wave != 3 or not ui.repeat_button.text.contains("RESUME"):
        _fail("Farm click does not replay previous stage and display RESUME PUSH");return
    ui.repeat_button.emit_signal("pressed")
    if ui.game.repeat_wave or not ui.repeat_button.text.contains("FARM"):
        _fail("Resume click does not return to Push");return
    print("PASS v0.15: first-clear-only Essence, Gold/Bond farming, Ascension high-water, Guardian +4, mode actions and 12 unique sprite families")
    quit(0)
