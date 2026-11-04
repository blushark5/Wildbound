extends SceneTree
## v0.26: genuinely uncluttered FULL-WIDTH battle, drawer navigation,
## optional tactics, nonoverlapping touch targets, saved-game compatibility,
## and v0.24 Ascension recovery. All functions are real scene actions.
const SCENE = preload("res://scenes/incremental/wildbound_bond_v26.tscn")
const GAME = preload("res://scripts/incremental/bond_engine_v25.gd")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _fail(message: String) -> void:
    push_error("Wildbound v0.26: "+message)
    SLOTS.erase_all(GAME.SAVE_FILE)
    quit(1)

func _verify() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var ui: Control = SCENE.instantiate()
    root.add_child(ui)
    await process_frame
    if not ui.design26_ready or ui.game == null or not ui.game.has_method("replay_status"):
        _fail("v0.26 did not load the current engine/UI");return
    if ui.drawer_open or ui.get_node("SidebarPanel").visible or ui.get_node("JourneyPanel").visible:
        _fail("Main screen still opens as cluttered battle + spreadsheet");return
    if ui.get_node("BattlePanel").size.x < 1200 or ui.scenic_art.size.x < 1200:
        _fail("Full-width cinematic battle view was not installed");return
    if ui.get_node("PackPanel").size.x < 1200 or ui.slot_markers.size() != 3:
        _fail("Three large team cards missing from new full-width layout");return
    # v0.14's animation rig uses separate ally_base/rival_base vectors.
    # Reflowing only the static portrait would appear correct for one
    # frame, then animate enemy art back onto the allied side.
    ui._animate_fighters()
    for i in range(3):
        var ally_art: TextureRect = ui.ally_widgets[i]["portrait"]
        var foe_art: TextureRect = ui.rival_widgets[i]["portrait"]
        if absf(ally_art.position.x-ui.ALLY_POS[i]) > 39:
            _fail("Animated ally sprite escaped its intended wide-arena slot");return
        if absf(foe_art.position.x-ui.FOE_POS[i]) > 39:
            _fail("Animated enemy sprite moved onto allied side or wrong panel");return
        if not ui.ally_base[i].is_equal_approx(Vector2(ui.ALLY_POS[i],229)):
            _fail("Sprite animation base was not updated with the battle reflow");return
        var photo: TextureRect = ui.card_art[String(ui.CHALLENGE.ORDER[i])]
        if photo.position.y < 486 or photo.position.y > 495:
            _fail("Animated team card portrait is clipping outside new frame");return
    if not is_instance_valid(ui.arena_emblem) or ui.arena_emblem.texture == null:
        _fail("New original battle sigil missing");return
    if ui.autoform_button.visible or ui.replay_button.visible or ui.type_size_button.visible:
        _fail("Advanced toggles still compete with the core battle HUD");return
    if ui.shop_button == null or ui.tactics_button == null or ui.tactics_actions.size() != 5:
        _fail("Shop and Tactics controls not installed");return
    if ui.strike_button.get_rect().intersects(ui.repeat_button.get_rect()):
        _fail("Battle primary action still overlaps farm/push button");return
    for control in [ui.batch_button,ui.collect_button,ui.shop_button,ui.tactics_button]:
        if control.size.y < 28:
            _fail("Important team/shop touch target too short");return
    var cmds: Array[Button] = [ui.batch_button,ui.collect_button,ui.shop_button,ui.tactics_button]
    for i in range(cmds.size()):
        for j in range(i+1,cmds.size()):
            if cmds[i].get_rect().intersects(cmds[j].get_rect()):
                _fail("Team command buttons visually overlap");return
    for i in range(3):
        var key: String = String(ui.CHALLENGE.ORDER[i])
        var card: Panel = ui.get_node("PackCard_"+key)
        if card.size.x < 385 or ui.card_art[key].size.x < 100:
            _fail("Creature card/portrait not visibly enlarged");return
        if card.position.x+card.size.x > 1270:
            _fail("Large team card extends outside the browser viewport");return
        if ui.card_skill[key].get_rect().intersects(ui.card_buy[key].get_rect()):
            _fail("Card controls overlap after rearrangement");return
    # Only focus on the battle; shop and quest must be intentional.
    ui._open_shop("GROW")
    if not ui.drawer_open or not ui.get_node("SidebarPanel").visible or not ui.get_node("SidebarScroll").visible:
        _fail("UPGRADES button did not open working shop drawer");return
    if not ui.drawer_backdrop.visible or not ui.drawer_close.visible:
        _fail("Right shop has no intentional panel or close action");return
    if ui.tab != "GROW" or ui.sidebar_title.text.find("GOLD") < 0:
        _fail("Opened drawer did not show Gold upgrades");return
    if ui.drawer_close.get_rect().intersects(ui.quest_fold_button.get_rect()):
        _fail("Drawer CLOSE overlaps Journey MORE/Less control");return
    ui._switch_tab("NEST")
    if ui.tab != "NEST" or ui.active_rows.is_empty():
        _fail("Nest tab is not functional inside drawer");return
    ui._switch_tab("LEGACY")
    if ui.tab != "LEGACY":
        _fail("ASCEND tab inaccessible from drawer");return
    ui._switch_tab("WORLD")
    if ui.tab != "WORLD":
        _fail("WORLD tab inaccessible from drawer");return
    ui._toggle_journey()
    if ui.game.ui_compact_journey or not ui.screen_labels["QuestHint"].visible:
        _fail("Journey More did not expose context/details");return
    ui._toggle_journey()
    if not ui.game.ui_compact_journey or ui.screen_labels["QuestHint"].visible:
        _fail("Journey Less did not collapse context");return
    ui._close_drawer()
    if ui.drawer_open or ui.get_node("SidebarPanel").visible or ui.get_node("SidebarScroll").visible:
        _fail("Shop drawer failed to restore uncluttered battle view");return

    ui._open_tactics()
    if not ui.tactics_dialog.visible or not ui.tactics_actions["auto"].disabled:
        _fail("Tactics menu must exist and Auto-Form must start locked");return
    if not ui.tactics_actions["replay"].disabled or not ui.tactics_actions["farm"].disabled:
        _fail("Tactics incorrectly unlocks Ascension or uncleared farming");return
    ui._tool_text()
    if not ui.game.ui_large_text or not ui.tactics_actions["text"].text.contains("LARGE"):
        _fail("Tactics text accessibility toggle did not work");return
    ui.tactics_dialog.hide()
    ui.guide_dialog.hide()
    ui._strike()
    if not ui.playing or not ui.game.battle_started:
        _fail("Main first-battle START action stopped working");return
    ui._open_tactics()
    if ui.tactics_actions["farm"].disabled:
        # Winning the first stage should unlock farm controls without
        # disrupting first-clear progression or Essence.
        ui.tactics_dialog.hide()
        for i in range(3):
            if ui.game.awaiting_next:
                break
            var unit: Dictionary = ui.game.rival_units[i]
            if float(unit["hp"]) > 0.0:
                ui.game._damage_rival(i,float(unit["hp"])+100.0,String(ui.game.squad_slots[0]))
        ui._open_tactics()
        if ui.tactics_actions["farm"].disabled:
            _fail("Tactics farming didn't unlock after an actual stage win");return
    ui.tactics_dialog.hide()
    # Saved data and Ascension restart must not be affected by this art pass.
    ui.game.best_wave = 21
    ui.game.run_peak = 21
    ui.game.wave = 21
    ui.game.awaiting_next = false
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.game._setup_trainer_fight()
    ui._ascend()
    if ui.game.ascensions != 1 or not ui.ascent_results.visible:
        _fail("Existing Ascension results/preview broken by the new UI");return
    ui.ascent_results.hide()
    ui._close_ascent_results()
    await process_frame
    if not ui.playing or ui.strike_button.disabled:
        _fail("Ascension post-dialog battle lockup returned");return
    ui._open_tactics()
    if ui.tactics_actions["auto"].disabled or ui.tactics_actions["replay"].disabled:
        _fail("Tactics failed to unlock automation after Ascension");return
    ui.tactics_dialog.hide()
    ui.game.save()
    ui._load_slot(2)
    if not ui.game.has_method("replay_status") or ui.game.ascensions != 0 or ui.drawer_open:
        _fail("Switching slots corrupted progression or kept obstructive drawer");return
    ui._load_slot(1)
    if ui.game.ascensions != 1 or ui.drawer_open or not ui.game.ui_large_text:
        _fail("Returning to existing slot did not recover progress, view or accessibility preference");return

    SLOTS.erase_all(GAME.SAVE_FILE)
    ui.queue_free()
    print("PASS v0.26: unmistakable full-width battle focus, 3 enlarged cards, functional shop drawer and all tabs, optional Tactics menu, no overlap, Farm unlocks, Ascension recovery, save slot integrity")
    quit(0)
