extends SceneTree
## Wildbound v0.27: real panel navigation, 7 top tabs, team roster,
## hatching and persistent squads, tools, farm, Save management, Ascent.
const SCENE = preload("res://scenes/incremental/wildbound_bond_v27.tscn")
const GAME = preload("res://scripts/incremental/bond_engine_v25.gd")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _fail(why: String) -> void:
    push_error("Wildbound v0.27: "+why)
    SLOTS.erase_all(GAME.SAVE_FILE)
    quit(1)

func _verify() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var ui: Control = SCENE.instantiate()
    root.add_child(ui)
    await process_frame
    if not ui.nav27_ready or ui.menu_buttons.size() != 7:
        _fail("Seven consistent top tabs were not created");return
    if not ui.game.has_method("replay_status") or ui.game.ascensions != 0:
        _fail("Current engine and clean first save not loaded");return
    if ui.codex_layer.visible or ui.tactics_dialog.visible or ui.save_window.visible:
        _fail("Legacy full-screen popups are still open at start");return
    if not ui.drawer_open or ui.menu_section != "TEAM":
        _fail("First-time help should use the side Team panel, not a giant guide");return
    if not ui.team_page.visible or ui.codex_layer.visible:
        _fail("Field Guide did not open as a side panel");return
    if ui.creature_rows.size() != 12 or ui.team_target_buttons.size() != 3:
        _fail("Compact side Field Guide missing 12 species or 3 slot selectors");return
    if ui.drawer_backdrop.position.x < 800 or ui.drawer_backdrop.size.x > 480:
        _fail("Side panel is not actually docked on the right");return
    for name in ui.menu_buttons:
        var button: Button = ui.menu_buttons[name]
        if button.size.y < 35 or not button.visible:
            _fail("Top-tab navigation not usable: "+String(name));return
        if button.position.x < 840 or button.position.x+button.size.x > 1260:
            _fail("Top tab outside right-side menu");return
    for a in ui.menu_buttons:
        for b in ui.menu_buttons:
            if String(a) >= String(b):
                continue
            if (ui.menu_buttons[a] as Button).get_rect().intersects(
                    (ui.menu_buttons[b] as Button).get_rect()):
                _fail("Top menu tabs overlap");return

    ui._team_pick_slot(2)
    if ui.chosen_slot != 2 or not ui.team_target_buttons[2].text.contains("SLOT 3"):
        _fail("Team slot choice does not update the sidebar");return
    var owned: Array[String] = ui.game.squad_slots.duplicate()
    ui._team_equip(owned[0])
    if ui.game.squad_slots[2] != owned[0]:
        _fail("Side Field Guide equip/swap is not connected to battle engine");return
    ui._team_save_preset(1)
    if ui.game.preset_team(1).size() != 3:
        _fail("Saving team presets from side panel failed");return
    ui._team_use_preset(1)
    if ui.game.squad_slots.size() != 3:
        _fail("Loading team presets from side panel failed");return

    # Main menu tabs change contents without closing the side panel.
    ui._show_section("GROW")
    if not ui.drawer_open or ui.menu_section != "GROW" or ui.team_page.visible:
        _fail("GOLD tab failed to replace team contents");return
    if ui.get_node("SidebarScroll").visible == false or ui.tab != "GROW":
        _fail("Real Gold upgrade list is not visible inside shared drawer");return
    if ui.screen_labels["QuestName"].visible:
        _fail("Quest continues to clutter Gold purchases");return
    ui._show_section("NEST")
    if ui.tab != "NEST" or not ui.get_node("SidebarScroll").visible:
        _fail("Nest hatch/relic screen not accessible as side tab");return
    ui._show_section("LEGACY")
    if ui.tab != "LEGACY" or not ui.get_node("SidebarScroll").visible:
        _fail("Ascension and permanent research not accessible");return
    ui._show_section("WORLD")
    if ui.tab != "WORLD" or not ui.screen_labels["QuestName"].visible or not ui.trail_button.visible:
        _fail("Journey and its working claim action must live under World tab");return
    if ui.get_node("SidebarScroll").position.y <= ui.get_node("JourneyPanel").position.y+ui.get_node("JourneyPanel").size.y:
        _fail("World region/shop rows overlap Journey panel");return

    # Tactics, matchups, farm stage selection and save management all remain
    # beside the battle, rather than opening large center popups.
    ui._open_tactics()
    if ui.menu_section != "TOOLS" or not ui.tools_page.visible or ui.tactics_dialog.visible:
        _fail("Tactics still opens a central popup instead of side panel");return
    if not ui.tools_buttons["auto"].disabled or not ui.tools_buttons["farm"].disabled:
        _fail("Fresh-run automation/farming wrongly unlocked");return
    ui._show_matchups()
    if ui.menu_section != "TOOLS" or not ui.tools_readout.text.contains("EARTH"):
        _fail("Matchup details should render inside Tactics side panel");return
    if ui.matchup_dialog.visible:
        _fail("Matchups still open as central popups");return
    ui._show_save_manager()
    if ui.menu_section != "SAVE" or not ui.saves_page.visible or ui.save_window.visible:
        _fail("Save Manager still uses giant central modal");return
    if ui.saves_buttons.size() != 3:
        _fail("Three existing save slots missing from side drawer");return
    ui._open_ascension()
    if ui.menu_section != "LEGACY" or ui.ascension_info.visible:
        _fail("Header Ascend shortcut failed to select side Ascend tab");return
    ui._close_drawer()
    if ui.drawer_open or ui.drawer_backdrop.visible or ui.team_page.visible:
        _fail("Close did not return to full-width battlefield");return

    # First-stage gate and v0.24 Ascension recovery must survive the menu
    # rewrite. Popup stays only for explicit Ascension confirmation.
    ui._strike()
    if not ui.game.battle_started or not ui.playing:
        _fail("First battle did not start after side menu onboarding");return
    ui._open_farm_picker()
    if ui.menu_section != "TOOLS" or ui.farm_dialog.visible:
        _fail("Farm picker should be integrated with Tools side panel");return
    for i in range(3):
        if ui.game.awaiting_next:
            break
        var unit: Dictionary = ui.game.rival_units[i]
        if float(unit["hp"]) > 0.0:
            ui.game._damage_rival(i,float(unit["hp"])+100.0,String(ui.game.squad_slots[0]))
    ui._show_section("TOOLS")
    if ui.tools_buttons["farm"].disabled:
        _fail("Farm stage selector not unlocked after a genuine win");return
    ui.tools_farm_stage.value = 1
    ui._tool_side_farm()
    if not ui.game.repeat_wave:
        _fail("Farming selected stage did not call original farm mechanics");return
    ui.game.best_wave = 21
    ui.game.run_peak = 21
    ui.game.wave = 21
    ui.game.repeat_wave = false
    ui.game.awaiting_next = false
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.game._setup_trainer_fight()
    ui._ascend()
    if ui.game.ascensions != 1 or not ui.ascent_results.visible:
        _fail("Ascension execution/results broken by navigation");return
    ui.ascent_results.hide()
    ui._close_ascent_results()
    await process_frame
    if not ui.playing or ui.strike_button.disabled:
        _fail("Old Ascension battle lockup returned");return
    ui._show_section("TOOLS")
    if ui.tools_buttons["auto"].disabled or ui.tools_buttons["replay"].disabled:
        _fail("Real Auto-Form and Replay did not unlock");return
    ui._tool_side_autoform()
    if ui.game.auto_form_enabled:
        _fail("Auto-Form toggle is not wired to saved game");return
    ui._tool_side_autoform()
    ui.game.save()
    ui._side_load_slot(2)
    if ui.game.ascensions != 0 or ui.drawer_open:
        _fail("Switching to empty save slot preserved wrong engine/drawer");return
    ui._side_load_slot(1)
    if ui.game.ascensions != 1 or ui.game.preset_team(1).size() != 3:
        _fail("Returning to saved slot lost Ascension/preset");return
    if ui.drawer_open or ui.save_window.visible:
        _fail("Save slot switch left a modal window trapping the game");return

    SLOTS.erase_all(GAME.SAVE_FILE)
    ui.queue_free()
    print("PASS v0.27: seven top tabs, unified right-side Team/Gold/Nest/Ascend/World/Tools/Saves, all real game actions, no obstructive popups, farm, Ascension, save slots")
    quit(0)
