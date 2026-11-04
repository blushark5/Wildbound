extends "res://scripts/incremental/bond_ui_v25.gd"
## Wildbound v0.26 • THE WILDS, not a dashboard.
## A full-width tactical battle is the default. Secondary systems are kept
## in a genuine shop drawer and an intentional tactics menu. No combat math,
## collection data or save-file changes.
const WILDS_SIGIL = preload("res://assets/incremental/v26/duel_sigil.svg")
const ALLY_POS: Array[float] = [112.0,274.0,436.0]
const FOE_POS: Array[float] = [760.0,922.0,1084.0]
const PACK_POS: Array[float] = [24.0,440.0,856.0]
const GOLD_TONE: Color = Color("#e5c58b")
const MINT_TONE: Color = Color("#9ed7bb")
const INK_TONE: Color = Color("#0c1f2b")
var design26_ready: bool = false
var drawer_open: bool = false
var shop_button: Button
var tactics_button: Button
var drawer_close: Button
var drawer_backdrop: Panel
var arena_emblem: TextureRect
var small_heading: Label
var tactics_dialog: AcceptDialog
var tactics_hint: Label
var tactics_actions: Dictionary = {}
var zone_frames: Array[Panel] = []

func _ready() -> void:
    super._ready()
    _build_cinematic_arena()
    _build_big_team_cards()
    _build_shop_drawer()
    _build_tactics_menu()
    design26_ready = true
    _close_drawer()
    _refresh()

func _build_cinematic_arena() -> void:
    # The last few versions kept a cramped 826px battle alongside an
    # always-visible 414px spreadsheet. The battle now fills the canvas.
    var battle: Panel = get_node("BattlePanel") as Panel
    battle.position = Vector2(14,88)
    battle.size = Vector2(1252,334)
    battle.add_theme_stylebox_override("panel",
        _glass(Color("#09232f"),Color("#b5aa77"),20,2,9))
    scenic_art.position = Vector2(20,95)
    scenic_art.size = Vector2(1240,317)
    scenic_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    get_node("StageTopShade").position = Vector2(22,98)
    get_node("StageTopShade").size = Vector2(1236,101)
    get_node("StageTopShade").color = Color("#061823",0.83)
    get_node("StageBottomShade").position = Vector2(22,365)
    get_node("StageBottomShade").size = Vector2(1236,45)
    get_node("StageBottomShade").color = Color("#061823",0.84)
    # Two restrained, colored encounter zones make all six creature
    # portraits read as opponents rather than one packed row of icons.
    var ally_zone: Panel = _layer_panel("V26AllyZone",
        Rect2(50,194,522,164),Color("#0b3a3e",0.27),
        Color("#88c5ae",0.30),ally_widgets[0]["portrait"])
    var foe_zone: Panel = _layer_panel("V26EnemyZone",
        Rect2(706,194,521,164),Color("#3b222f",0.30),
        Color("#efb5a4",0.29),rival_widgets[0]["portrait"])
    zone_frames.assign([ally_zone,foe_zone])
    for zone in zone_frames:
        zone.add_theme_stylebox_override("panel",
            _glass(Color("#0d3039",0.22) if zone == ally_zone
                else Color("#422932",0.23),
                Color("#9bdfc7",0.37) if zone == ally_zone
                else Color("#f3b3a5",0.35),17,1,1))
    arena_emblem = _texture("V26AncientDuelSigil",
        Rect2(573,193,136,146),WILDS_SIGIL)
    arena_emblem.mouse_filter = Control.MOUSE_FILTER_IGNORE
    arena_emblem.modulate.a = 0.84
    arena_badge.hide()
    squad_status.hide()
    type_key.hide()

    screen_labels["Wave"].position = Vector2(48,108)
    screen_labels["Wave"].size = Vector2(372,30)
    screen_labels["Wave"].add_theme_font_size_override("font_size",25)
    screen_labels["EnemyName"].position = Vector2(868,110)
    screen_labels["EnemyName"].size = Vector2(353,27)
    screen_labels["EnemyName"].add_theme_font_size_override("font_size",17)
    screen_labels["EnemyHp"].position = Vector2(929,145)
    screen_labels["EnemyHp"].size = Vector2(292,21)
    screen_labels["EnemyHp"].add_theme_font_size_override("font_size",12)
    get_node("EnemyHpRail").position = Vector2(987,173)
    get_node("EnemyHpRail").size = Vector2(234,8)
    threat_bar.position = Vector2(989,175)
    screen_labels["EncounterHint"].position = Vector2(52,149)
    screen_labels["EncounterHint"].size = Vector2(609,22)
    screen_labels["EncounterHint"].add_theme_font_size_override("font_size",12)
    screen_labels["Toast"].position = Vector2(52,149)
    screen_labels["Toast"].size = Vector2(609,22)
    screen_labels["Toast"].add_theme_font_size_override("font_size",12)
    screen_labels["FieldStatus"].position = Vector2(54,371)
    screen_labels["FieldStatus"].size = Vector2(611,23)
    screen_labels["FieldStatus"].add_theme_font_size_override("font_size",12)
    screen_labels["DamageReadout"].position = Vector2(754,371)
    screen_labels["DamageReadout"].size = Vector2(471,23)
    screen_labels["DamageReadout"].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    get_node("WardRail").position = Vector2(51,398)
    get_node("WardRail").size = Vector2(1176,6)
    ward_bar.position = Vector2(51,398)
    for i in range(stage_steps.size()):
        var step: ColorRect = stage_steps[i]
        step.position = Vector2(50.0+float(i)*52.0,181)
        step.size = Vector2(46,3)

    ally_title.position = Vector2(73,199)
    ally_title.size = Vector2(390,22)
    ally_title.add_theme_font_size_override("font_size",13)
    rival_title.position = Vector2(835,199)
    rival_title.size = Vector2(365,22)
    rival_title.add_theme_font_size_override("font_size",13)
    for i in range(3):
        for group in [ally_widgets[i],rival_widgets[i]]:
            var foe: bool = group == rival_widgets[i]
            var picture: TextureRect = group["portrait"]
            var previous_x: float = picture.position.x
            var x: float = FOE_POS[i] if foe else ALLY_POS[i]
            var offset: float = x-previous_x
            picture.position.x = x
            picture.size.x = 112
            for field in ["name","bar","hp","target"]:
                var control: Control = group[field]
                control.position.x += offset
                if field == "name":
                    control.size.x = 130
                    control.add_theme_font_size_override("font_size",12)
                if field == "hp":
                    control.size.x = 135
            var halo: Panel = portraits_halos[i*2+(1 if foe else 0)]
            halo.position.x += offset
            halo.size.x = 124
        ally_element_icons[i].position = Vector2(ALLY_POS[i]+101,217)
        enemy_element_icons[i].position = Vector2(FOE_POS[i]+100,217)
    # The inherited target threads used old hard-coded 826px coordinates.
    # Keep the original auto-target system but omit the obsolete lines.
    for line in target_threads:
        line.visible = false

    farm_select_button.position = Vector2(470,107)
    farm_select_button.size = Vector2(164,31)
    farm_select_button.add_theme_font_size_override("font_size",11)
    matchup_button.position = Vector2(644,107)
    matchup_button.size = Vector2(151,31)
    matchup_button.add_theme_font_size_override("font_size",11)
    # Room for the actual mythic creatures rather than tiny crowded HUD text.
    get_node("PackPanel").position = Vector2(14,432)
    get_node("PackPanel").size = Vector2(1252,188)
    (get_node("PackPanel") as Panel).add_theme_stylebox_override("panel",
        _glass(Color("#0d2635"),Color("#6b9783"),17,1,6))
    get_node("ActionPanel").position = Vector2(14,629)
    get_node("ActionPanel").size = Vector2(1252,78)
    (get_node("ActionPanel") as Panel).add_theme_stylebox_override("panel",
        _glass(Color("#102937"),Color("#8aaf9b"),14,1,5))
    strike_button.position = Vector2(29,641)
    strike_button.size = Vector2(439,52)
    resonance_button.position = Vector2(481,641)
    resonance_button.size = Vector2(247,52)
    repeat_button.position = Vector2(742,641)
    repeat_button.size = Vector2(246,52)
    speed_button.position = Vector2(1001,641)
    speed_button.size = Vector2(250,52)
    _skin_button(strike_button,GOLD_TONE,true)
    _skin_button(resonance_button,Color("#bdabeb"))
    _skin_button(repeat_button,MINT_TONE)
    _skin_button(speed_button,Color("#c3d2be"))

func _build_big_team_cards() -> void:
    screen_labels["PackHeader"].position = Vector2(33,439)
    screen_labels["PackHeader"].size = Vector2(275,24)
    screen_labels["PackHeader"].add_theme_font_size_override("font_size",17)
    batch_button.position = Vector2(328,437)
    batch_button.size = Vector2(109,29)
    collect_button.position = Vector2(449,436)
    collect_button.size = Vector2(179,32)
    collect_button.text = "FIELD GUIDE"
    collect_button.add_theme_font_size_override("font_size",12)
    shop_button = _button("V26ShopButton","UPGRADES",
        Rect2(641,436,167,32),_toggle_shop,Color("#c1dba7"))
    _skin_button(shop_button,GOLD_TONE,true)
    shop_button.add_theme_font_size_override("font_size",12)
    shop_button.tooltip_text = "Open the upgrade drawer. Shop, Hatch, Ascend, World and quest details live here."
    tactics_button = _button("V26TacticsButton","TACTICS • MORE",
        Rect2(821,436,167,32),_open_tactics,Color("#a0c9e9"))
    _skin_button(tactics_button,MINT_TONE)
    tactics_button.add_theme_font_size_override("font_size",12)
    tactics_button.tooltip_text = "Find optional automation, Replay Route, stage selection and display settings."
    small_heading = _label("V26ModeStatus","",
        Rect2(1004,440,248,22),11,Color("#b0c9b9"))
    small_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    for idx in range(3):
        var x: float = PACK_POS[idx]
        var key: String = String(CHALLENGE.ORDER[idx])
        var card: Panel = get_node("PackCard_"+key) as Panel
        card.position = Vector2(x,474)
        card.size = Vector2(400,137)
        card.add_theme_stylebox_override("panel",
            _glass(Color("#183a47"),Color("#88b9ad"),15,1,5))
        pack_halos[idx].position = Vector2(x+12,486)
        pack_halos[idx].size = Vector2(117,109)
        card_art[key].position = Vector2(x+17,492)
        card_art[key].size = Vector2(107,93)
        slot_markers[idx].position = Vector2(x+17,478)
        slot_markers[idx].size = Vector2(36,20)
        screen_labels["Name_"+key].position = Vector2(x+146,483)
        screen_labels["Name_"+key].size = Vector2(213,25)
        screen_labels["Name_"+key].add_theme_font_size_override("font_size",15)
        card_details[key].position = Vector2(x+146,512)
        card_details[key].size = Vector2(230,40)
        card_details[key].add_theme_font_size_override("font_size",12)
        card_buy[key].position = Vector2(x+146,557)
        card_buy[key].size = Vector2(232,30)
        card_skill[key].position = Vector2(x+146,592)
        card_skill[key].size = Vector2(130,25)
        focus_buttons[key].position = Vector2(x+284,592)
        focus_buttons[key].size = Vector2(94,25)
        focus_buttons[key].add_theme_font_size_override("font_size",11)
        get_node("BondTrack_"+str(idx)).position = Vector2(x+146,552)
        get_node("BondFill_"+str(idx)).position = Vector2(x+146,552)
        element_chips[idx].hide()
        card_element_icons[idx].position = Vector2(x+360,480)
        card_element_icons[idx].size = Vector2(24,24)
        card_art[key].mouse_filter = Control.MOUSE_FILTER_IGNORE
    # Earlier revisions piled these toggles beside the creature cards.
    # Their exact actions remain available in the dedicated Tactics menu.
    autoform_button.hide()
    replay_button.hide()
    type_size_button.hide()

func _build_shop_drawer() -> void:
    drawer_backdrop = Panel.new()
    drawer_backdrop.name = "V26ShopCurtain"
    drawer_backdrop.position = Vector2(842,86)
    drawer_backdrop.size = Vector2(424,621)
    drawer_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
    drawer_backdrop.add_theme_stylebox_override("panel",
        _glass(Color("#071b27",0.98),Color("#dfc78e"),18,2,11))
    drawer_backdrop.z_index = 3
    add_child(drawer_backdrop)
    # The original shop is a set of root-owned controls (not true children
    # of SidebarPanel); collect them as a logical drawer.
    for control in _drawer_controls():
        control.z_index = 4
    drawer_close = _button("V26CloseShop","✕",
        Rect2(1197,100,55,32),_close_drawer,GOLD_TONE)
    drawer_close.z_index = 5
    _skin_button(drawer_close,GOLD_TONE,true)
    drawer_close.tooltip_text = "Return to the wide, uncluttered battle view."
    quest_fold_button.position = Vector2(1115,101)
    quest_fold_button.size = Vector2(75,30)
    quest_fold_button.z_index = 5
    screen_labels["JourneyStage"].position = Vector2(1033,108)
    screen_labels["JourneyStage"].size.x = 76
    # A visible drawer cannot shadow the rest of gameplay permanently.
    # First launch always returns to the clean battlefield.
    drawer_open = false
    _set_drawer_visibility(false)

func _drawer_controls() -> Array[Control]:
    var result: Array[Control] = [
        get_node("JourneyPanel"),get_node("SidebarPanel"),
        get_node("SidebarScroll"),get_node("TrailRail"),
        trail_fill,trail_button,sidebar_title,quest_fold_button]
    for name in ["JourneyHeading","JourneyStage","QuestName","QuestHint",
        "QuestProgress","QuestReward"]:
        result.append(screen_labels[name])
    for button in tab_buttons.values():
        result.append(button as Control)
    return result

func _set_drawer_visibility(show: bool) -> void:
    if not is_instance_valid(drawer_backdrop):
        return
    drawer_backdrop.visible = show
    if is_instance_valid(drawer_close):
        drawer_close.visible = show
    for element in _drawer_controls():
        element.visible = show
    if show:
        # Honor the player's saved compact/expanded Journey choice.
        _apply_journey_layout()
        quest_fold_button.position = Vector2(1115,101)
        quest_fold_button.size = Vector2(75,30)
        screen_labels["JourneyStage"].position = Vector2(1033,108)
        screen_labels["JourneyStage"].size.x = 76
        # The v25 arrangement gives the Journey its own visibility rules.
        screen_labels["QuestHint"].visible = not game.ui_compact_journey
        screen_labels["QuestReward"].visible = not game.ui_compact_journey
        get_node("TrailRail").visible = not game.ui_compact_journey
        trail_fill.visible = not game.ui_compact_journey

func _toggle_shop() -> void:
    if drawer_open:
        _close_drawer()
    else:
        _open_shop("GROW")

func _open_shop(target: String = "GROW") -> void:
    if game == null:
        return
    drawer_open = true
    _switch_tab(target)
    _set_drawer_visibility(true)
    shop_button.text = "CLOSE UPGRADES"
    shop_button.tooltip_text = "Close the shop and return to the full-width arena."
    _refresh()

func _close_drawer() -> void:
    drawer_open = false
    _set_drawer_visibility(false)
    if is_instance_valid(shop_button):
        shop_button.text = "UPGRADES"
        shop_button.tooltip_text = "Open Gold upgrades, Nest, Ascend, World and quest details."
    if design26_ready:
        _refresh()

func _switch_tab(next: String) -> void:
    super._switch_tab(next)
    if design26_ready:
        _set_drawer_visibility(drawer_open)

func _toggle_journey() -> void:
    super._toggle_journey()
    if design26_ready:
        _set_drawer_visibility(drawer_open)

func _build_tactics_menu() -> void:
    tactics_dialog = AcceptDialog.new()
    tactics_dialog.title = "Wildbound • Tactics & Comfort"
    tactics_dialog.ok_button_text = "BACK TO BATTLE"
    add_child(tactics_dialog)
    var wrap := VBoxContainer.new()
    wrap.name = "TacticsMenuActions"
    wrap.position = Vector2(17,31)
    wrap.size = Vector2(502,354)
    wrap.custom_minimum_size = Vector2(502,354)
    wrap.add_theme_constant_override("separation",9)
    tactics_dialog.add_child(wrap)
    tactics_hint = Label.new()
    tactics_hint.custom_minimum_size = Vector2(500,64)
    tactics_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    tactics_hint.add_theme_font_size_override("font_size",14)
    wrap.add_child(tactics_hint)
    var actions: Array = [
        ["auto","AUTO-FORM",Callable(self,"_tool_autoform")],
        ["replay","REPLAY ROUTE",Callable(self,"_tool_replay")],
        ["farm","CHOOSE FARMING STAGE",Callable(self,"_tool_farm")],
        ["match","ELEMENT COUNTERS",Callable(self,"_tool_match")],
        ["text","LARGER TEXT",Callable(self,"_tool_text")]]
    for entry in actions:
        var key: String = String(entry[0])
        var button := Button.new()
        button.text = String(entry[1])
        button.custom_minimum_size = Vector2(500,42)
        button.pressed.connect(entry[2])
        _skin_button(button,MINT_TONE,true)
        button.add_theme_font_size_override("font_size",13)
        wrap.add_child(button)
        tactics_actions[key] = button

func _open_tactics() -> void:
    _update_tactics_menu()
    tactics_dialog.popup_centered(Vector2i(540,475))

func _update_tactics_menu() -> void:
    if game == null or not game.has_method("replay_status"):
        return
    tactics_hint.text = ("Optional automation is separate from your core battles.\n"
        +"STAGE %d • BEST CLEARED %d • ASCENSIONS %d") % [
            game.wave,game.lifetime_cleared_stage,game.ascensions]
    tactics_actions["auto"].text = ("AUTO-FORM   %s" % (
        "LOCKED UNTIL ASCENSION" if game.ascensions == 0
        else "ON" if game.auto_form_enabled else "OFF"))
    tactics_actions["auto"].disabled = game.ascensions == 0
    tactics_actions["replay"].text = ("REPLAY ROUTE   %s" % (
        "LOCKED UNTIL ASCENSION" if game.ascensions == 0
        else "ON" if game.replay_route_enabled else "OFF"))
    tactics_actions["replay"].disabled = game.ascensions == 0
    tactics_actions["farm"].disabled = not game.battle_started or game.last_cleared_run_stage() < 1
    tactics_actions["text"].text = (
        "TEXT SIZE   LARGE ✓" if game.ui_large_text else "TEXT SIZE   NORMAL")

func _tool_autoform() -> void:
    _toggle_autoform()
    _update_tactics_menu()

func _tool_replay() -> void:
    _toggle_replay_route()
    _update_tactics_menu()

func _tool_farm() -> void:
    tactics_dialog.hide()
    _open_farm_picker()

func _tool_match() -> void:
    tactics_dialog.hide()
    _show_matchups()

func _tool_text() -> void:
    _toggle_text_size()
    _update_tactics_menu()

func _refresh() -> void:
    super._refresh()
    if not design26_ready or game == null or not game.has_method("replay_status"):
        return
    small_heading.text = (
        "AUTO-FORM ON" if game.ascensions > 0 and game.auto_form_enabled
        else "AUTO-FORM OFF" if game.ascensions > 0
        else "ELEMENTAL 3 vs 3")
    screen_labels["PackHeader"].text = "YOUR TEAM  •  %d/3" % game.occupied_slots()
    # The large arena's status line is more useful than cramped duplicate
    # target text. Keep damage/element feedback, but not outdated guide copy.
    ally_title.text = "YOUR COMPANIONS    %d / 3" % game.ally_alive()
    rival_title.text = "ENEMY TEAM    %d / 3" % game.rival_alive()
    for target in target_threads:
        target.visible = false
    squad_status.hide()
    arena_badge.hide()
    for chip in element_chips:
        chip.hide()
    # Reset health bars to the expanded full-width presentation.
    ward_bar.size.x = 1176.0*clampf(
        game.ward/maxf(1.0,game.party_max_hp()),0.0,1.0)
    threat_bar.size.x = 230.0*clampf(
        game.enemy_hp/maxf(1.0,game.enemy_max_hp),0.0,1.0)
    for index in range(3):
        var key: String = String(CHALLENGE.ORDER[index])
        var creature: String = String(game.squad_slots[index])
        if creature == "":
            continue
        var color: Color = ELEMENT_COLORS_20.get(
            String(ENGINE_25.CATALOG[creature]["element"]),MINT_TONE)
        var card: Panel = get_node("PackCard_"+key) as Panel
        card.add_theme_stylebox_override("panel",
            _glass(Color("#102d3c"),Color(color,0.85),14,2,3))
        card_skill[key].add_theme_font_size_override("font_size",11)
        focus_buttons[key].add_theme_font_size_override("font_size",11)
        screen_labels["Name_"+key].add_theme_font_size_override("font_size",14)
    # The shop and Tactics remain available via clearly named buttons,
    # but are not allowed to reintroduce the old always-on dashboard.
    if not drawer_open:
        for element in _drawer_controls():
            element.visible = false
    autoform_button.hide()
    replay_button.hide()
    type_size_button.hide()
    # First-time onboarding and Ascension recovery from v0.24 are retained.
    if game.battle_started and not playing and not _any_blocking_dialog():
        strike_button.disabled = false

func _any_blocking_dialog() -> bool:
    var blocked: bool = super._any_blocking_dialog()
    return blocked or (is_instance_valid(tactics_dialog) and tactics_dialog.visible)

func _replace_active_game() -> void:
    # The v0.25 direct-switch fix already recreates the modern engine and
    # protects against deferred guides from other slots.
    super._replace_active_game()
    if design26_ready:
        _close_drawer()
        _refresh()
