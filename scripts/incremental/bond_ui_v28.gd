extends "res://scripts/incremental/bond_ui_v27.gd"
## Wildbound v0.28 — PLAY FIRST.
## Three obvious main-screen actions; an intentional MENU entry point.
## All older gameplay, Ascensions, squad art and saved data stay intact.

var simple28_ready: bool = false
var menu28_button: Button
var resources28: Label
var prompt28: Label
var help28: Label
var home28: Control
var home28_open: bool = false
var back28_button: Button
var train28_buttons: Array[Button] = []
var skills28_button: Button
var skills28_page: Control
var skills28_ability_buttons: Array[Button] = []
var skills28_resonance: Button
var skills28_speed: Button
var skills28_open: bool = false

func _ready() -> void:
    super._ready()
    _create_play_first_screen()
    _create_menu_home()
    _relocate_training_and_abilities()
    simple28_ready = true
    _close_drawer()
    _refresh()

func _create_play_first_screen() -> void:
    var header: Panel = get_node("Header") as Panel
    header.add_theme_stylebox_override("panel",
        _glass(Color("#0b2533"),Color("#547c71"),17,1,4))
    screen_labels["GameName"].position = Vector2(31,21)
    screen_labels["GameName"].size = Vector2(230,37)
    screen_labels["GameName"].add_theme_font_size_override("font_size",31)
    screen_labels["Tagline"].position = Vector2(35,57)
    screen_labels["Tagline"].size = Vector2(340,19)
    screen_labels["Tagline"].text = "YOUR TEAM BATTLES AUTOMATICALLY"
    screen_labels["Tagline"].add_theme_font_size_override("font_size",11)
    resources28 = _label("V28Resources","",
        Rect2(426,28,655,35),17,Color("#e2dcc4"))
    resources28.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    resources28.clip_text = true
    menu28_button = _button("V28MainMenu","☰  MENU",
        Rect2(1102,22,151,48),_toggle_main_menu,GOLD_TONE)
    _skin_button(menu28_button,GOLD_TONE,true)
    menu28_button.add_theme_font_size_override("font_size",17)
    menu28_button.tooltip_text = (
        "Open the main menu to manage creatures, level up, buy upgrades, "
        +"use abilities, Ascend, see quests and manage saves.")
    for name in ["Gold","Shards","Echoes","TrailRank"]:
        screen_labels[name].hide()
    for name in ["GoldChip","EssenceChip","EchoChip"]:
        get_node(name).hide()
    for picture in currency_icons:
        picture.hide()
    get_node("Save").hide()
    ascend_shortcut.hide()

    # The arena remains large and readable. Remove secondary diagnostics,
    # symbols and shortcut buttons that competed with the actual fight.
    farm_select_button.hide()
    matchup_button.hide()
    matchup_label.hide()
    arena_emblem.modulate.a = 0.27
    screen_labels["Wave"].position = Vector2(55,110)
    screen_labels["Wave"].size = Vector2(500,38)
    screen_labels["Wave"].add_theme_font_size_override("font_size",27)
    screen_labels["EnemyName"].position = Vector2(871,112)
    screen_labels["EnemyName"].size = Vector2(345,25)
    screen_labels["EnemyName"].add_theme_font_size_override("font_size",16)
    screen_labels["EnemyHp"].hide()
    screen_labels["FieldStatus"].hide()
    screen_labels["DamageReadout"].hide()
    get_node("WardRail").hide()
    ward_bar.hide()
    get_node("EnemyHpRail").hide()
    threat_bar.hide()
    for step in stage_steps:
        step.hide()
    for i in range(3):
        var ally: Dictionary = ally_widgets[i]
        var foe: Dictionary = rival_widgets[i]
        ally["hp"].hide()
        foe["hp"].hide()
        ally["target"].hide()
        foe["target"].hide()
    prompt28 = _label("V28BattleInstruction","",
        Rect2(59,372,1161,30),17,Color("#f6e5be"))
    prompt28.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    prompt28.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    prompt28.add_theme_stylebox_override("normal",
        _glass(Color("#091d2a",0.87),Color("#668f80",0.4),8,1))
    screen_labels["EncounterHint"].hide()
    screen_labels["Toast"].hide()

    # Creature cards become visual summaries, not three competing sets of
    # purchase, ability and assignment buttons.
    screen_labels["PackHeader"].text = "YOUR CREATURES"
    screen_labels["PackHeader"].position = Vector2(36,439)
    screen_labels["PackHeader"].size = Vector2(290,26)
    screen_labels["PackHeader"].add_theme_font_size_override("font_size",18)
    help28 = _label("V28TeamHelp",
        "Train, change teams and use abilities from MENU",
        Rect2(555,440,686,24),12,Color("#a8c5b9"))
    help28.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    batch_button.hide()
    collect_button.hide()
    shop_button.hide()
    tactics_button.hide()
    small_heading.hide()
    for key in card_buy:
        var k: String = String(key)
        card_buy[k].hide()
        card_skill[k].hide()
        focus_buttons[k].hide()
        var pos: int = CHALLENGE.ORDER.find(k)
        if pos < 0:
            continue
        var x: float = PACK_POS[pos]
        var card: Panel = get_node("PackCard_"+k) as Panel
        card.position.y = 474
        card.size.y = 139
        card_art[k].position = Vector2(x+18,490)
        card_art[k].size = Vector2(125,108)
        screen_labels["Name_"+k].position = Vector2(x+157,492)
        screen_labels["Name_"+k].size = Vector2(220,26)
        screen_labels["Name_"+k].add_theme_font_size_override("font_size",16)
        card_details[k].position = Vector2(x+158,526)
        card_details[k].size = Vector2(225,58)
        card_details[k].add_theme_font_size_override("font_size",13)
        get_node("BondTrack_"+str(pos)).hide()
        get_node("BondFill_"+str(pos)).hide()
        card_element_icons[pos].position = Vector2(x+354,485)
    resonance_button.hide()
    speed_button.hide()
    strike_button.position = Vector2(34,644)
    strike_button.size = Vector2(1208,50)
    _skin_button(strike_button,GOLD_TONE,true)
    strike_button.add_theme_font_size_override("font_size",20)
    repeat_button.hide()
    repeat_button.position = Vector2(831,644)
    repeat_button.size = Vector2(408,50)
    _skin_button(repeat_button,MINT_TONE,true)
    repeat_button.add_theme_font_size_override("font_size",17)

func _create_menu_home() -> void:
    home28 = _side_root("V28MainMenuHome")
    back28_button = _button("V28ReturnToMenu","‹ MENU",
        Rect2(860,153,89,33),_open_menu_home,MINT_TONE)
    back28_button.z_index = 7
    _skin_button(back28_button,MINT_TONE)
    back28_button.add_theme_font_size_override("font_size",12)
    var sections: Array = [
        ["TEAM","CREATURES & TRAINING","Equip, level up, hatch and save squads"],
        ["GROW","GOLD UPGRADES","Improve the strength of your whole team"],
        ["NEST","NEST & RELICS","Discover rewards, eggs and equipment"],
        ["LEGACY","ASCENSION","Permanent upgrades and the next run"],
        ["WORLD","QUESTS & WORLD","Objectives, progress and destinations"],
        ["TOOLS","ABILITIES & OPTIONS","Skills, speed, farming and Auto-Form"],
        ["SAVE","SAVES & NEW GAME","Switch slots or manage saved progress"]
    ]
    for i in range(sections.size()):
        var section: String = String(sections[i][0])
        var y: float = 5+float(i)*70
        var button: Button = _side_button(home28,"Home_"+section,
            String(sections[i][1]),Rect2(8,y,381,44),
            _show_section.bind(section),GOLD_TONE if i == 0 else MINT_TONE)
        button.add_theme_font_size_override("font_size",15)
        button.tooltip_text = String(sections[i][2])
        _side_label(home28,"HomeDesc_"+section,String(sections[i][2]),
            Rect2(15,y+43,375,22),11,Color("#a9c9bd"))
    home28.hide()
    back28_button.hide()

func _relocate_training_and_abilities() -> void:
    # All three team card LEVEL buttons are intentionally absent from the
    # battle. Give the *same real* training action a clear place in TEAM.
    for i in range(3):
        var idx: int = i
        var button: Button = _side_button(team_page,"TrainSlot_"+str(i),
            "TRAIN SLOT %d" % (i+1),Rect2(7+i*129,75,124,38),
            _train_slot.bind(idx),GOLD_TONE)
        button.add_theme_font_size_override("font_size",11)
        train28_buttons.append(button)
    team_essence_label.position.y = 122
    hatch_side_button.position.y = 114
    (team_page.get_node("SpeciesSubtitle") as Label).position.y = 161
    menu_scroll.position.y = 188
    menu_scroll.size.y = 222

    # TOOLS remains compact. Advanced abilities, burst damage and speed
    # live behind one understandable "BATTLE ABILITIES" entry.
    skills28_button = _side_button(tools_page,"OpenCombatOptions",
        "BATTLE ABILITIES & SPEED",Rect2(9,376,375,42),
        _open_skills_panel,GOLD_TONE)
    tools_readout.position.y = 426
    tools_readout.size.y = 72
    skills28_page = Control.new()
    skills28_page.name = "V28CombatTools"
    skills28_page.position = Vector2.ZERO
    skills28_page.size = Vector2(398,507)
    tools_page.add_child(skills28_page)
    var veil := ColorRect.new()
    veil.position = Vector2.ZERO
    veil.size = Vector2(398,503)
    veil.color = Color("#0c2736",0.99)
    veil.mouse_filter = Control.MOUSE_FILTER_STOP
    skills28_page.add_child(veil)
    _side_button(skills28_page,"CombatBack","‹ BACK TO OPTIONS",
        Rect2(8,6,382,41),_close_skills_panel,MINT_TONE)
    _side_label(skills28_page,"CombatTitle","YOUR CREATURE ABILITIES",
        Rect2(12,61,370,30),17,GOLD_TONE)
    _side_label(skills28_page,"CombatHelp",
        "Abilities are optional. Your team always attacks automatically.",
        Rect2(12,92,375,32),11,Color("#b4c8bf"))
    for i in range(3):
        var button: Button = _side_button(skills28_page,"Ability_"+str(i),
            "USE SLOT %d ABILITY" % (i+1),Rect2(10,137+i*56,378,47),
            _activate_slot_ability.bind(i),MINT_TONE)
        skills28_ability_buttons.append(button)
    skills28_resonance = _side_button(skills28_page,"UseResonance",
        "USE RESONANCE WHEN READY",Rect2(10,320,378,47),
        _activate_resonance,GOLD_TONE)
    skills28_speed = _side_button(skills28_page,"BattleSpeed",
        "BATTLE SPEED",Rect2(10,379,378,46),_toggle_play_speed,MINT_TONE)
    _side_label(skills28_page,"SkillFoot",
        "Grow stronger with Gold upgrades and Bond Ranks in the menu.",
        Rect2(11,444,375,32),11,Color("#b2c7bc"))
    skills28_page.hide()

func _train_slot(index: int) -> void:
    if game == null or index < 0 or index >= 3:
        return
    var kind: String = String(game.squad_slots[index])
    if kind == "" or not game.has_instance(kind):
        return
    if game.level_creature(kind,1):
        game.save()
        _toast("%s trained to Level %d" % [game.display_name(kind),game.unit_level(kind)])
    else:
        _toast("Training requires Gold and an available Bond Rank level.")
    _refresh_side_team()
    _refresh()

func _refresh_side_team() -> void:
    super._refresh_side_team()
    if not simple28_ready or game == null:
        return
    for i in range(3):
        var kind: String = String(game.squad_slots[i])
        var btn: Button = train28_buttons[i]
        if kind == "" or not game.has_instance(kind):
            btn.text = "EMPTY SLOT"
            btn.disabled = true
            continue
        var cost: float = game.creature_level_price(kind,1)
        var cap: bool = cost == INF
        btn.text = ("S%d • MAX BOND" % (i+1) if cap
            else "TRAIN S%d • %s G" % [i+1,game.format_number(cost)])
        btn.disabled = cap or game.gold < cost
        btn.tooltip_text = (
            "%s: Level %d / %d. A training purchase increases only this creature. "
            +"Reach higher Bond Ranks by Ascending to grow beyond the cap.") % [
                game.display_name(kind),game.unit_level(kind),game.bond_level_cap(kind)]

func _open_skills_panel() -> void:
    skills28_open = true
    skills28_page.show()
    _update_skills_panel()

func _close_skills_panel() -> void:
    skills28_open = false
    skills28_page.hide()

func _update_skills_panel() -> void:
    if not simple28_ready or game == null:
        return
    for i in range(3):
        var kind: String = String(game.squad_slots[i])
        var btn: Button = skills28_ability_buttons[i]
        var cd: float = float(game.unlock_clock.get(kind,0.0))
        btn.text = (
            "SLOT %d • %s  %s" % [
                i+1,game.display_name(kind),
                "READY" if cd <= 0.0 else "%ds COOLDOWN" % ceili(cd)]
            if kind != "" else "EMPTY SLOT %d" % (i+1))
        btn.disabled = (kind == "" or cd > 0.0 or game.awaiting_next
            or not game.battle_started)
    skills28_resonance.text = (
        "RESONANCE • READY" if game.overdrive >= 99.99
        else "RESONANCE • %d%% CHARGED" % int(game.overdrive))
    skills28_resonance.disabled = game.overdrive < 99.99 or game.overdrive_left > 0.0
    skills28_speed.text = "BATTLE SPEED • %dx" % int(game.game_speed)

func _activate_slot_ability(index: int) -> void:
    var key: String = String(CHALLENGE.ORDER[index])
    _use_skill(key)
    _update_skills_panel()

func _activate_resonance() -> void:
    _resonate()
    _update_skills_panel()

func _toggle_play_speed() -> void:
    # v0.10 repurposed the inherited _speed() action to toggle optional
    # Auto-Advance, but v0.26 still labeled it SPEED. This control now
    # explicitly changes real engine simulation speed (1× / 2×), not
    # Auto-Advance. Those distinct options remain in TOOLS.
    if game == null:
        return
    game.game_speed = 2.0 if game.game_speed < 2.0 else 1.0
    game.save()
    _toast("BATTLE SPEED • %dx" % int(game.game_speed))
    _refresh()
    _update_skills_panel()

func _toggle_main_menu() -> void:
    if drawer_open:
        _close_drawer()
    else:
        _open_menu_home()

func _open_menu_home() -> void:
    if not simple28_ready:
        return
    # Do not go through this class' _show_section override here:
    # that intentionally leaves the home page when an actual section
    # button is selected. Only the menu button should open home.
    home28_open = false
    super._show_section("TEAM")
    home28_open = true
    _set_drawer_visibility(true)
    menu28_button.text = "✕  CLOSE"

func _show_section(section: String) -> void:
    if simple28_ready:
        home28_open = false
        skills28_open = false
        skills28_page.hide()
    super._show_section(section)
    if simple28_ready:
        _set_drawer_visibility(true)

func _set_drawer_visibility(show: bool) -> void:
    super._set_drawer_visibility(show)
    if not simple28_ready:
        return
    var landing: bool = show and home28_open
    home28.visible = landing
    back28_button.visible = show and not landing
    if landing:
        for button in menu_buttons.values():
            (button as Button).hide()
        team_page.hide()
        tools_page.hide()
        saves_page.hide()
        (get_node("SidebarPanel") as Panel).hide()
        (get_node("SidebarScroll") as ScrollContainer).hide()
        sidebar_title.hide()
        get_node("JourneyPanel").hide()
        for name in ["JourneyHeading","JourneyStage","QuestName","QuestProgress"]:
            screen_labels[name].hide()
        trail_button.hide()
        menu_heading.text = "MAIN MENU"
    elif not show:
        skills28_open = false
        skills28_page.hide()

func _close_drawer() -> void:
    home28_open = false
    super._close_drawer()
    if simple28_ready:
        home28.hide()
        back28_button.hide()
        menu28_button.text = "☰  MENU"

func _show_first_steps() -> void:
    # A large introductory guide or forced Team side panel is the opposite
    # of the requested calm first screen. Show a short instruction *on the
    # battlefield* and leave both menus closed until explicitly requested.
    if not simple28_ready:
        if is_instance_valid(guide_dialog):
            guide_dialog.hide()
        return
    guide_dialog.hide()
    _close_drawer()
    if game != null and not game.battle_started:
        prompt28.text = "Your creatures fight automatically. Tap START BATTLE."

func _refresh() -> void:
    super._refresh()
    if not simple28_ready or game == null:
        return
    resources28.text = "GOLD %s     •     ESSENCE %d/%d     •     ECHO %d" % [
        game.format_number(game.gold),game.essence,game.hatch_cost(),game.echoes]
    # One plain-language sentence instead of scattered combat jargon.
    var defeated: bool = (game.awaiting_next
        and String(game.last_clash).begins_with("SQUAD DEFEATED"))
    if not game.battle_started:
        strike_button.text = "▶  START BATTLE"
        prompt28.text = "Your three creatures fight automatically. Tap START BATTLE."
    elif game.awaiting_next:
        strike_button.text = "↻  RETRY STAGE" if defeated else "▶  NEXT STAGE"
        prompt28.text = (
            "Defeated. Retry, or farm Gold to grow stronger." if defeated else
            "Stage cleared! Tap NEXT STAGE, or farm Gold.")
    elif not playing and not _any_blocking_dialog():
        strike_button.text = "▶  RESUME BATTLE"
        prompt28.text = "Combat is paused. Tap RESUME BATTLE."
    else:
        strike_button.text = "⚔  HELP ATTACK"
        prompt28.text = (
            "Farming Stage %d for Gold • no Essence here." % game.wave
            if game.repeat_wave else
            "Your creatures fight on their own. HELP ATTACK is optional.")
    strike_button.disabled = false if not _any_blocking_dialog() else strike_button.disabled
    var can_farm: bool = game.battle_started and game.last_cleared_run_stage() >= 1
    repeat_button.visible = can_farm
    if can_farm:
        repeat_button.text = "▶  RETURN TO NEW STAGES" if game.repeat_wave else "↻  FARM GOLD"
        repeat_button.tooltip_text = (
            "Return to the furthest stage reached during this Ascension." if game.repeat_wave
            else "Replay a cleared stage to earn Gold and Bond XP. No Essence from farming.")
        strike_button.position.x = 34
        strike_button.size.x = 782
    else:
        strike_button.position.x = 34
        strike_button.size.x = 1208
    # Hide the inherited utility menu and repetitive card-level controls.
    for btn in [batch_button,collect_button,shop_button,tactics_button,
            farm_select_button,matchup_button,resonance_button,speed_button,
            autoform_button,replay_button,type_size_button,ascend_shortcut]:
        btn.hide()
    get_node("Save").hide()
    small_heading.hide()
    for name in ["Gold","Shards","Echoes","TrailRank","EnemyHp",
            "FieldStatus","DamageReadout","PackDps","EncounterHint","Toast"]:
        screen_labels[name].hide()
    for name in ["GoldChip","EssenceChip","EchoChip","WardRail","EnemyHpRail"]:
        get_node(name).hide()
    for icon in currency_icons:
        icon.hide()
    ward_bar.hide()
    threat_bar.hide()
    for marker in stage_steps:
        marker.hide()
    for btn in card_buy.values():
        (btn as Button).hide()
    for btn in card_skill.values():
        (btn as Button).hide()
    for btn in focus_buttons.values():
        (btn as Button).hide()
    for i in range(3):
        var kind: String = String(game.squad_slots[i])
        var key: String = String(CHALLENGE.ORDER[i])
        if kind != "" and game.has_instance(kind):
            card_details[key].text = ("%s ELEMENT\nLEVEL %d   •   BOND %d" % [
                String(ENGINE_25.CATALOG[kind]["element"]).to_upper(),
                game.unit_level(kind),game.unit_bond_rank(kind)])
            screen_labels["Name_"+key].text = game.display_name(kind,
                2 if game.unit_ascended(kind)
                else 1 if game.unit_evolved(kind) else 0)
        else:
            card_details[key].text = "CHOOSE A CREATURE IN MENU"
    if drawer_open:
        menu28_button.text = "✕  CLOSE"
        if menu_section == "TEAM" and not home28_open:
            _refresh_side_team()
        if menu_section == "TOOLS":
            skills28_button.visible = not skills28_open
            skills28_page.visible = skills28_open
            if skills28_open:
                _update_skills_panel()
    else:
        menu28_button.text = "☰  MENU"
    # Home visibility changes only on navigation, not every combat tick.

func _replace_active_game() -> void:
    super._replace_active_game()
    if simple28_ready:
        home28_open = false
        _close_drawer()
        _refresh()
