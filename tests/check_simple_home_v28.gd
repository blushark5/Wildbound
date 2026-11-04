extends SceneTree
## Real v0.28 "Play First" UI/regression in Godot.
const SCENE = preload("res://scenes/incremental/wildbound_bond_v28.tscn")
const GAME = preload("res://scripts/incremental/bond_engine_v25.gd")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")

func _initialize() -> void:
    call_deferred("_test")

func _fail(why: String) -> void:
    push_error("v0.28: "+why)
    SLOTS.erase_all(GAME.SAVE_FILE)
    quit(1)

func _check_main(ui: Control) -> bool:
    if not ui.simple28_ready or not ui.menu28_button.visible or not ui.strike_button.visible:
        _fail("Main screen missing MENU or primary battle action");return false
    if ui.drawer_open or ui.home28.visible:
        _fail("Menus should not obscure the opening battle");return false
    for b in [ui.batch_button,ui.collect_button,ui.shop_button,ui.tactics_button,
        ui.resonance_button,ui.speed_button,ui.autoform_button,ui.replay_button,
        ui.farm_select_button,ui.matchup_button,ui.ascend_shortcut]:
        if b.visible:
            _fail("Advanced main-screen button still cluttering view: "+b.name);return false
    for key in ui.card_buy:
        if ui.card_buy[key].visible or ui.card_skill[key].visible or ui.focus_buttons[key].visible:
            _fail("Team cards still have many confusing buttons");return false
    if ui.prompt28.text.length() < 20 or not ui.resources28.text.contains("GOLD"):
        _fail("Plain instruction and concise resource summary missing");return false
    return true

func _test() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var ui: Control = SCENE.instantiate()
    root.add_child(ui)
    await process_frame
    if not _check_main(ui):
        return
    if ui.guide_dialog.visible or ui.game.battle_started:
        _fail("First run must await explicit START BATTLE without a giant guide");return
    if not ui.strike_button.text.contains("START") or ui.repeat_button.visible:
        _fail("Start screen should only offer START BATTLE and MENU");return
    ui._toggle_main_menu()
    if not ui.home28.visible or not ui.drawer_open:
        _fail("MENU did not open a simple category list");return
    if ui.home28.get_node("Home_TEAM") == null or ui.home28.get_node("Home_SAVE") == null:
        _fail("Menu does not contain the main navigation routes");return
    for button in ui.menu_buttons.values():
        if button.visible:
            _fail("Tiny top tabs should be hidden on menu home");return
    ui._show_section("TEAM")
    if ui.home28.visible or not ui.team_page.visible or ui.train28_buttons.size() != 3:
        _fail("CREATURES screen does not expose the three training actions");return
    var creature: String = String(ui.game.squad_slots[0])
    var level: int = ui.game.unit_level(creature)
    ui.game.gold = 500000.0
    ui._refresh()
    if ui.train28_buttons[0].disabled:
        _fail("Owned starter with Gold should be trainable");return
    ui._train_slot(0)
    if ui.game.unit_level(creature) != level+1:
        _fail("TRAIN S1 does not increase an individual's level");return
    ui._open_menu_home()
    if not ui.home28.visible:
        _fail("Cannot return from section to main category list");return
    ui._show_section("TOOLS")
    if not ui.tools_page.visible or ui.skills28_button == null:
        _fail("Optional combat abilities inaccessible");return
    ui._open_skills_panel()
    if not ui.skills28_page.visible or ui.skills28_ability_buttons.size() != 3:
        _fail("Per-creature abilities missing from MENU");return
    var speed: float = ui.game.game_speed
    ui._toggle_play_speed()
    if ui.game.game_speed == speed:
        _fail("Speed control no longer modifies gameplay");return
    ui._close_skills_panel()
    ui._close_drawer()
    if not _check_main(ui):
        return
    ui._strike()
    if not ui.game.battle_started or not ui.playing:
        _fail("START button did not start auto-combat");return
    ui._refresh()
    if not ui.strike_button.text.contains("HELP ATTACK"):
        _fail("Active battle doesn't communicate optional attack");return
    for i in range(3):
        if ui.game.awaiting_next:
            break
        var enemy: Dictionary = ui.game.rival_units[i]
        if float(enemy["hp"]) > 0:
            ui.game._damage_rival(i,float(enemy["hp"])+100.0,String(ui.game.squad_slots[0]))
    ui._refresh()
    if not ui.game.awaiting_next or not ui.repeat_button.visible or not ui.strike_button.text.contains("NEXT"):
        _fail("Victory should reveal NEXT STAGE and FARM GOLD");return
    var essence: int = ui.game.essence
    ui._repeat()
    ui._refresh()
    if not ui.game.repeat_wave or not ui.repeat_button.text.contains("RETURN"):
        _fail("FARM GOLD should toggle into RETURN TO NEW STAGES");return
    if ui.game.essence != essence:
        _fail("Farming illegally granted Essence");return
    ui._repeat()
    if ui.game.repeat_wave:
        _fail("Returning from farming did not work");return
    ui.game.best_wave = 21
    ui.game.run_peak = 21
    ui.game.wave = 21
    ui.game.awaiting_next = false
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.game._setup_trainer_fight()
    ui._ascend()
    if ui.game.ascensions != 1 or not ui.ascent_results.visible:
        _fail("Ascension result modal not reached");return
    ui.ascent_results.hide()
    ui._close_ascent_results()
    await process_frame
    if not ui.playing or ui.strike_button.disabled:
        _fail("Post-Ascension soft lock returned");return
    ui.game.save()
    ui._show_section("SAVE")
    ui._side_load_slot(2)
    if ui.game.ascensions != 0 or ui.drawer_open:
        _fail("Save-slot switching leaked a prior game's menu or progress");return
    ui._side_load_slot(1)
    if ui.game.ascensions != 1 or not _check_main(ui):
        _fail("Restored save is wrong or main screen still cluttered");return
    SLOTS.erase_all(GAME.SAVE_FILE)
    ui.queue_free()
    print("PASS v0.28: clean battle, one menu, training/abilities available, victory/farming, save slots, Ascension recovery")
    quit(0)
