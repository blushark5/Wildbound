extends SceneTree
## Real Godot regression for v0.20 element markers, saved lineups,
## retreat ladder, stage picker, direct-to-wall push and Ascension clearing.
const GAME = preload("res://scripts/incremental/bond_engine_v20.gd")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")
const SCENE = preload("res://scenes/incremental/wildbound_bond_v20.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _fail(why: String) -> void:
    push_error("Wildbound v0.20: "+why)
    SLOTS.erase_all(GAME.SAVE_FILE)
    quit(1)

func _win(game: RefCounted) -> void:
    for i in range(3):
        if game.awaiting_next:
            break
        var foe: Dictionary = game.rival_units[i]
        if float(foe.get("hp",0.0)) > 0.0:
            game._damage_rival(i,float(foe["hp"])+100.0,String(game.squad_slots[0]))

func _verify() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var game = GAME.new()
    game.initialize_alpha()
    game.load_save()
    var squad: Array[String] = game.squad_slots.duplicate()
    if game.collection_count() != 3 or game.last_cleared_run_stage() != 0:
        _fail("Fresh run unexpectedly allows farming or changed the trio");return
    if game.farm_stage(1):
        _fail("Cannot farm stage 1 before it is cleared");return
    game.battle_started = true
    _win(game)
    if game.last_cleared_run_stage() != 1 or game.winning_team_for(1) != squad or game.essence != 1:
        _fail("First clear did not remember lineup or preserve first-clear Essence");return
    if not game.enter_next_stage():
        _fail("Next stage must be enterable after victory");return
    # Advance the scripted state only for QA. Stages 13–15 represent the
    # observed Stage 15 player wall, not an artificial nerf.
    game.wave = 13
    game.run_peak = 13
    game.best_wave = 13
    game.awaiting_next = false
    game.repeat_wave = false
    game._spawn_enemy()
    game._fit_enemy_to_region()
    game._setup_trainer_fight()
    _win(game)
    if game.wave != 14 or game.winning_team_for(13) != squad:
        _fail("Stage 13 winning roster was not captured");return
    game.enter_next_stage()
    _win(game)
    if game.wave != 15 or game.winning_team_for(14) != squad or game.last_cleared_run_stage() != 14:
        _fail("Stage 14 winning lineup or progress was not recorded");return
    game.enter_next_stage()
    # Simulate a manual squad change that would make the old farm target
    # impossible. v0.20 must restore the lineup that actually won stage 14.
    game.squad_slots.reverse()
    game._setup_trainer_fight()
    if game.squad_slots == squad:
        _fail("Fixture team was not changed");return
    if not game.farm_stage(14):
        _fail("Previously cleared stage 14 cannot be selected");return
    if game.squad_slots != squad or game.push_return_stage != 15 or not game.repeat_wave:
        _fail("Farming failed to restore historical winner and remember stage 15 wall");return
    if game.farm_stage(15) or game.farm_stage(0):
        _fail("Farm picker must reject uncleared / out-of-range stages");return
    game.save()
    var loaded = GAME.new()
    loaded.initialize_alpha()
    if not loaded.load_save():
        _fail("Could not reload the saved farm run");return
    if loaded.wave != 14 or loaded.push_return_stage != 15 or loaded.winning_team_for(14) != squad:
        _fail("Farm stage, previous winner, or direct push destination did not survive reload");return

    # Force a loss on a selected farming stage: the engine MUST retreat
    # automatically to the next lower stage and restore THAT recorded team.
    loaded.squad_slots.reverse()
    loaded._setup_trainer_fight()
    loaded._regroup()
    if not loaded.repeat_wave or loaded.wave != 13 or loaded.awaiting_next:
        _fail("Losing farming Stage 14 did not automatically retreat to Stage 13");return
    if loaded.squad_slots != squad or loaded.push_return_stage != 15:
        _fail("Auto-retreat did not restore Stage 13 winner or original push wall");return
    var before_essence: int = loaded.essence
    var before_gold: float = loaded.gold
    _win(loaded)
    if loaded.essence != before_essence or loaded.gold <= before_gold or not loaded.repeat_wave or loaded.wave != 13:
        _fail("Safe farming changed Essence or failed to keep repeat mode");return
    if not loaded.set_farming() or loaded.wave != 15 or loaded.repeat_wave or loaded.awaiting_next:
        _fail("RESUME PUSH must skip cleared stages and return directly to wall 15");return

    # Lowest floor: never trap the player in infinite auto-wipes.
    if not loaded.farm_stage(1):
        _fail("Should be able to select previously cleared Stage 1");return
    loaded._regroup()
    if loaded.repeat_wave or not loaded.awaiting_next or not loaded.last_clash.contains("FARM FLOOR"):
        _fail("Farm floor must stop the loop with actionable Retry guidance");return
    loaded.run_peak = 20
    loaded.best_wave = 20
    if not loaded.ascend() or not loaded.stage_winning_teams.is_empty() or loaded.last_cleared_run_stage() != 0:
        _fail("Ascension must clear run-specific winning history and farm list");return
    if loaded.farm_stage(14):
        _fail("Cannot skip stages by farming an old Ascension's lineup");return

    # The actual scene must show element markers and slot ownership, not
    # rely on player memory of sprite colors or hidden tooltips.
    SLOTS.erase_all(GAME.SAVE_FILE)
    var ui: Control = SCENE.instantiate() as Control
    root.add_child(ui)
    await process_frame
    if ui.ally_element_icons.size() != 3 or ui.enemy_element_icons.size() != 3 or ui.card_element_icons.size() != 3:
        _fail("Six battle emblems and three squad-card emblems not installed");return
    for i in range(3):
        var kind: String = String(ui.game.squad_slots[i])
        var element: String = String(GAME.CATALOG[kind]["element"])
        if ui.ally_element_icons[i].texture == null or ui.enemy_element_icons[i].texture == null or ui.card_element_icons[i].texture == null:
            _fail("Battle/squad element icons missing for active slot "+str(i+1));return
        if ui.ally_element_icons[i].texture != ui.ELEMENT_BADGES[element]:
            _fail("Ally element icon doesn't match creature");return
    if ui.guide_element_icons.size() != 12:
        _fail("Element badges missing from Field Guide entries");return
    ui.guide_dialog.hide()
    ui._open_codex()
    ui._refresh_codex()
    for i in range(3):
        var button: Button = ui.codex_slot_buttons[i]
        if button.icon == null or not button.text.contains("S%d" % (i+1)) or not button.text.contains(ui.game.display_name(String(ui.game.squad_slots[i])).substr(0,11)):
            _fail("Field Guide does not show individual slot creatures AND icons");return
    ui._close_codex()
    ui._strike()
    _win(ui.game)
    ui._refresh()
    if ui.farm_select_button.disabled or not ui.farm_select_button.text.contains("FARM"):
        _fail("Stage picker should unlock after clearing stage 1");return
    ui._open_farm_picker()
    if not ui.farm_dialog.visible or int(ui.farm_spinner.max_value) != 1 or not ui.farm_preview.text.contains("LAST WINNING SQUAD"):
        _fail("Farming stage dialog must show cleared range and winning team");return
    ui._confirm_farm_stage()
    ui.farm_dialog.hide()
    if not ui.game.repeat_wave or ui.game.wave != 1:
        _fail("Picker Farm action did not activate real farming");return
    ui.game.set_farming()
    if ui.game.wave != 2 or ui.game.repeat_wave:
        _fail("UI farm resume did not skip back to current push stage");return
    ui.queue_free()
    SLOTS.erase_all(GAME.SAVE_FILE)
    print("PASS v0.20: 4 element emblems, 3 visible field-guide slots, stage picker, per-stage winning lineups, automatic farm retreat, no Essence repeats, direct push resume, cross-save history and Ascension reset")
    quit(0)
