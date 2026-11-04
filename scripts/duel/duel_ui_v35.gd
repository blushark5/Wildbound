extends "res://scripts/duel/duel_ui_v34.gd"
## Wildbound v0.35 -- battle-first painted composition.
## Intentionally preserves the engine, save path, signals and working menus.
## No new combat commands: every visible button calls an existing action.
const PREMIUM35 = preload("res://scripts/duel/premium_art_v35.gd")
const NAVY35: Color = Color("#101c2c")
const FRAME35: Color = Color("#d9b576")
const SILK35: Color = Color("#fff3d1")
var premium35_ready: bool = false
var team_buttons35: Dictionary = {}
var team_images35: Dictionary = {}
var team_levels35: Dictionary = {}
var level_button35: Button
var hero_icon35: TextureRect
var enemy_icon35: TextureRect

func _ready() -> void:
    super._ready()
    _recompose_battle35()
    _build_team35()
    _build_training_action35()
    premium35_ready = PREMIUM35.environment() != null
    (get_node("Tagline") as Label).text = "THE GUARDIAN TRIAL  •  v0.35"
    DisplayServer.window_set_title("Wildbound: Guardian Trial v0.35")
    _refresh()

func _place35(node: Control,at: Vector2,extent: Vector2) -> void:
    node.position = at
    node.size = extent
    if node is TextureRect:
        (node as TextureRect).pivot_offset = extent*0.5

func _hide35(name: String) -> void:
    var node: CanvasItem = get_node_or_null(name) as CanvasItem
    if node != null:
        node.hide()

func _frame35(node: Panel,alpha: float = 0.94) -> void:
    node.add_theme_stylebox_override("panel",_style(
        Color(NAVY35,alpha),FRAME35,12,2,5))

func _nameplate35(name: String,rect: Rect2,front: Control) -> void:
    var plate: Panel = _panel(self,name,rect,
        Color("#0c1d2d",0.91),FRAME35,13,2)
    # Place behind text, icon and health meters, not over them.
    move_child(plate,front.get_index())

func _element_icon35(kind: String) -> Texture2D:
    return FIRE_MARK if kind == "cindlet" else WATER_MARK if kind == "brinlet" else EARTH_MARK

func _recompose_battle35() -> void:
    # No inherited training sidebar or full-width banner is allowed to
    # cover the painted environment. The wallpaper is a scene asset, not
    # a screenshot of a completed game interface.
    for name in ["MainHeader","TrainingPanel","TrainingTitle",
            "TrainingDescription","ElementGuide","ElementGuideTitle",
            "ElementGuide1","ElementGuide2","ProgressChip",
            "InfoStrip","FooterHelp","DuelWindow"]:
        _hide35(name)
    for kind in DUEL.ORDER:
        var row: Dictionary = roster_rows[kind]
        for item in ["shell","frame","image","name","info","choose","spend"]:
            (row[item] as CanvasItem).hide()
    trim31.hide()
    landscape.position = Vector2(0,0)
    landscape.size = Vector2(1280,720)
    landscape.stretch_mode = TextureRect.STRETCH_SCALE
    landscape.texture = PREMIUM35.environment()
    landscape.modulate = Color.WHITE
    # Keep original environmental animation understated and unobstructive.
    ambient32.modulate.a = 0.32

    # A floating title, just as in the concept, instead of an 80px navbar.
    var logo: Label = get_node("Logo") as Label
    _place35(logo,Vector2(27,12),Vector2(296,43))
    logo.add_theme_font_size_override("font_size",39)
    logo.add_theme_color_override("font_color",SILK35)
    logo.add_theme_constant_override("outline_size",6)
    logo.add_theme_color_override("font_outline_color",Color("#1a1520"))
    var tagline: Label = get_node("Tagline") as Label
    _place35(tagline,Vector2(33,54),Vector2(316,23))
    tagline.add_theme_color_override("font_color",Color("#fff0cc"))
    tagline.add_theme_constant_override("outline_size",3)

    _place35(battle_header,Vector2(452,12),Vector2(376,75))
    _frame35(battle_header,0.96)
    _place35(stage_title,Vector2(474,17),Vector2(334,36))
    stage_title.add_theme_font_size_override("font_size",27)
    _place35(stage_subtitle,Vector2(476,52),Vector2(328,24))
    stage_subtitle.add_theme_font_size_override("font_size",13)
    stage_subtitle.add_theme_color_override("font_color",Color("#d5e9df"))
    _place35(guardian_label32,Vector2(504,89),Vector2(272,23))
    guardian_label32.add_theme_font_size_override("font_size",13)
    for i in range(progress_pips32.size()):
        var pip: Panel = progress_pips32[i]
        _place35(pip,Vector2(578.0+float(i)*29.0,113),Vector2(18,9))
    # Prevent a floating stage announcement from masking the creatures.
    _reposition_stage_intro33()

    _place35(get_node("GoldChip") as Control,Vector2(898,20),Vector2(128,52))
    _frame35(get_node("GoldChip") as Panel)
    _place35(get_node("GoldCoin") as Control,Vector2(908,32),Vector2(28,27))
    _place35(gold_text,Vector2(942,32),Vector2(80,29))
    gold_text.add_theme_font_size_override("font_size",18)
    _place35(get_node("EchoChip") as Control,Vector2(1033,20),Vector2(100,52))
    _frame35(get_node("EchoChip") as Panel)
    _place35(get_node("EchoCrystal") as Control,Vector2(1040,34),Vector2(25,25))
    _place35(echo_text,Vector2(1072,32),Vector2(52,29))
    echo_text.add_theme_font_size_override("font_size",18)
    _place35(menu_button,Vector2(1144,20),Vector2(118,52))
    menu_button.text = "☰  MENU"
    _paint_button(menu_button,Color("#152638"),FRAME35)

    # Two named combatants and clearly separated HP regions.
    _nameplate35("HeroPremiumPlate35",
        Rect2(19,102,358,103),hero_name)
    _nameplate35("EnemyPremiumPlate35",
        Rect2(904,102,357,103),enemy_name)
    _place35(hero_name,Vector2(78,110),Vector2(278,34))
    _place35(hero_element,Vector2(81,143),Vector2(273,19))
    _place35(enemy_name,Vector2(960,110),Vector2(269,34))
    _place35(enemy_element,Vector2(964,143),Vector2(259,19))
    for label in [hero_name,enemy_name]:
        label.add_theme_font_size_override("font_size",24)
        label.add_theme_color_override("font_color",SILK35)
    for label in [hero_element,enemy_element]:
        label.add_theme_font_size_override("font_size",13)
    hero_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    hero_element.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    enemy_element.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    hero_icon35 = _art(self,"HeroElementV35",FIRE_MARK,
        Rect2(40,113,32,32))
    enemy_icon35 = _art(self,"EnemyElementV35",WATER_MARK,
        Rect2(921,113,32,32))
    # Keep the native live HP widgets; never substitute an ornamental meter.
    _place35(get_node("HeroHealthBg") as Control,Vector2(35,166),Vector2(327,25))
    _place35(get_node("EnemyHealthBg") as Control,Vector2(920,166),Vector2(326,25))
    for bar in [hero_hp_bar,enemy_hp_bar]:
        bar.color = Color("#58cf64")
    _place35(hero_hp_bar,Vector2(41,172),Vector2(315,13))
    _place35(enemy_hp_bar,Vector2(926,172),Vector2(314,13))
    _place35(hero_damage_tail33,Vector2(41,172),Vector2(315,13))
    _place35(enemy_damage_tail33,Vector2(926,172),Vector2(314,13))
    _place35(hero_hp_text,Vector2(48,167),Vector2(305,24))
    _place35(enemy_hp_text,Vector2(933,167),Vector2(299,24))
    hero_hp_text.add_theme_font_size_override("font_size",14)
    enemy_hp_text.add_theme_font_size_override("font_size",14)
    hero_hp_text.add_theme_constant_override("outline_size",3)
    enemy_hp_text.add_theme_constant_override("outline_size",3)
    _place35(auto_badge33,Vector2(1055,207),Vector2(190,29))
    _place35(auto_text33,Vector2(3,2),Vector2(184,24))

    # Huge art, a believable shared ground plane and generous central space.
    _place35(get_node("HeroAura") as Control,Vector2(129,565),Vector2(340,25))
    _place35(get_node("RivalAura") as Control,Vector2(803,567),Vector2(354,25))
    _place35(hero_art,Vector2(63,250),Vector2(462,333))
    _place35(enemy_art,Vector2(752,242),Vector2(454,344))
    hero_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    enemy_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    enemy_art.flip_h = true
    _place35(enemy_hit_button,Vector2(754,254),Vector2(435,316))
    enemy_hit_button.tooltip_text = "Tap to help attack. Auto-combat continues normally."

    # Combat information floats above a short bottom navigation shelf.
    _hide35("ActiveName")
    _hide35("RivalName")
    hero_name.show()
    enemy_name.show()
    _place35(power_text,Vector2(357,557),Vector2(552,26))
    power_text.add_theme_font_size_override("font_size",16)
    power_text.add_theme_constant_override("outline_size",4)
    _place35(notice_text,Vector2(341,596),Vector2(609,24))
    notice_text.add_theme_font_size_override("font_size",12)
    notice_text.add_theme_constant_override("outline_size",4)
    _panel(self,"PremiumCommandShelf35",Rect2(0,614,1280,106),
        Color("#0a1829",0.95),Color("#c39f64",0.95),0,2)
    # Move existing working actions on top of the shelf.
    _place35(next_button,Vector2(350,639),Vector2(361,67))
    _place35(farm_button,Vector2(724,639),Vector2(235,67))
    next_button.add_theme_font_size_override("font_size",21)
    farm_button.add_theme_font_size_override("font_size",17)
    _paint_button(next_button,Color("#8a411f"),Color("#ffd084"))
    _paint_button(farm_button,Color("#263d52"),FRAME35)
    _place35(victory31,Vector2(459,234),Vector2(364,143))
    _frame35(victory31,0.96)

func _build_team35() -> void:
    _panel(self,"QuickTeamFrame35",Rect2(12,621,325,87),
        Color("#101c2e",0.98),FRAME35,13,2)
    _text(self,"QuickTeamTitle35","YOUR TEAM",
        Rect2(29,623,290,18),12,Color("#f5d695"))
    for i in range(DUEL.ORDER.size()):
        var kind: String = DUEL.ORDER[i]
        var x: float = 33.0+float(i)*101.0
        var button: Button = _button(self,"QuickSwitch_"+kind,"",
            Rect2(x,643,90,60),_choose.bind(kind))
        button.tooltip_text = "Switch to "+String(DUEL.SPECIES[kind]["name"])
        _paint_button(button,Color("#1a2b37"),COLORS[game.element(kind)])
        var image: TextureRect = _art(self,"QuickPortrait_"+kind,
            PREMIUM35.creature(kind),Rect2(x+6,647,78,47))
        image.mouse_filter = Control.MOUSE_FILTER_IGNORE
        var lvl: Label = _text(self,"QuickLevel_"+kind,"",
            Rect2(x+3,687,84,14),10,Color("#fff3d6"),HORIZONTAL_ALIGNMENT_CENTER)
        lvl.add_theme_constant_override("outline_size",2)
        team_buttons35[kind] = button
        team_images35[kind] = image
        team_levels35[kind] = lvl

func _build_training_action35() -> void:
    level_button35 = _button(self,"QuickLevelActive35","",
        Rect2(971,639,292,67),_level_active35,true)
    _paint_button(level_button35,Color("#275a46"),Color("#a4dfa8"))
    level_button35.add_theme_font_size_override("font_size",17)
    level_button35.tooltip_text = "Level your active creature using Gold. Bond limits maximum level."

func _level_active35() -> void:
    if game.level_up(game.active):
        fx31.impact(Vector2(306,475),game.element(game.active),true)
        _mini_toast32("LEVEL UP!",Vector2(303,308),Color("#e0ffa3"))
        _refresh()

func _reposition_stage_intro33() -> void:
    if stage_ribbon32 == null:
        return
    _place35(stage_ribbon32,Vector2(498,203),Vector2(284,67))
    _place35(stage_ribbon_name32,Vector2(8,5),Vector2(266,31))
    _place35(stage_ribbon_detail32,Vector2(7,37),Vector2(268,23))
    stage_ribbon_name32.add_theme_font_size_override("font_size",22)
    stage_ribbon_detail32.add_theme_font_size_override("font_size",12)

func _refresh() -> void:
    super._refresh()
    if not premium35_ready or game == null:
        return
    landscape.texture = PREMIUM35.environment()
    stage_title.text = "GUARDIAN TRIAL" if game.is_boss() else "VERDANT GROVE"
    stage_subtitle.text = "STAGE %d   •   %s" % [
        game.stage,"GUARDIAN ENCOUNTER" if game.is_boss() else "THE ANCIENT RUINS"]
    var hero_pose: String = "hurt" if stagger31 > 0.12 else "attack" if lunge31 > 0.1 else "idle"
    var rival_pose: String = "hurt" if enemy_hit31 > 0.10 else "idle"
    hero_art.texture = PREMIUM35.creature(game.active,bool(game.evolved[game.active]),hero_pose)
    enemy_art.texture = PREMIUM35.creature(game.opponent,game.is_boss(),rival_pose)
    hero_icon35.texture = _element_icon35(game.active)
    enemy_icon35.texture = _element_icon35(game.opponent)
    var hero_ratio: float = clampf(game.hero_hp/maxf(1.0,game.hero_max_hp),0.0,1.0)
    var rival_ratio: float = clampf(game.enemy_hp/maxf(1.0,game.enemy_max_hp),0.0,1.0)
    hero_hp_bar.size.x = 315.0*hero_ratio
    enemy_hp_bar.size.x = 314.0*rival_ratio
    hero_hp_text.text = "%s / %s" % [
        game.format_number(game.hero_hp),game.format_number(game.hero_max_hp)]
    enemy_hp_text.text = "%s / %s" % [
        game.format_number(game.enemy_hp),game.format_number(game.enemy_max_hp)]
    hero_name.text = game.display_name(game.active)
    enemy_name.text = game.display_name(game.opponent)
    hero_element.text = "%s   •   LV. %d" % [
        game.element(game.active).to_upper(),int(game.levels[game.active])]
    enemy_element.text = "%s   •   %s" % [
        game.element(game.opponent).to_upper(),"GUARDIAN" if game.is_boss() else "RIVAL"]
    for kind in DUEL.ORDER:
        var button: Button = team_buttons35.get(kind) as Button
        if button == null:
            continue
        var selected: bool = kind == game.active
        _paint_button(button,Color("#544224") if selected else Color("#172735"),
            FRAME35 if selected else COLORS[game.element(kind)])
        button.disabled = selected or game.switch_cooldown > 0.0
        (team_images35[kind] as TextureRect).texture = (
            PREMIUM35.creature(kind,bool(game.evolved[kind])))
        (team_levels35[kind] as Label).text = "LV %d" % int(game.levels[kind])
    var cost: float = game.level_cost(game.active)
    level_button35.disabled = cost == INF or game.gold < cost
    level_button35.text = (
        "BOND LEVEL CAP" if cost == INF
        else "LEVEL UP  •  %s G" % game.format_number(cost))
    next_button.text = (
        "START BATTLE" if not game.battle_started
        else "RETRY BATTLE" if game.defeated
        else "NEXT STAGE" if game.awaiting_next and not game.farming
        else "TAP TO ATTACK" if game.fighting
        else "AUTO FARMING")
    farm_button.text = "RETURN TO PUSH" if game.farming else "FARM GOLD"
    (get_node("QuickTeamTitle35") as Label).text = "YOUR TEAM  •  %s" % game.display_name(game.active).to_upper()

func _on_strike31(amount: float,enemy_target: bool,
        element_name: String,manual: bool) -> void:
    if not art31_ready:
        return
    var spot: Vector2 = (Vector2(995,413) if enemy_target else Vector2(304,431))
    spot += Vector2(randf_range(-27.0,27.0),randf_range(-19.0,19.0))
    fx31.impact(spot,element_name,amount >= 25.0 or manual)
    _float_damage31(amount,spot,enemy_target,element_name,amount >= 25.0 or manual)
    if enemy_target:
        enemy_hit31 = 0.22
        lunge31 = 0.20
    else:
        stagger31 = 0.23

func _on_strike32(amount: float,enemy_target: bool,
        element_name: String,manual: bool) -> void:
    if not polish32_ready or fx31 == null:
        return
    fx31.launch(Vector2(467,426) if enemy_target else Vector2(825,423),
        Vector2(924,426) if enemy_target else Vector2(352,426),
        element_name,manual)
    if enemy_target and game.matchup(game.active,game.opponent) > 1.0 and manual:
        _mini_toast32("SUPER EFFECTIVE!",Vector2(931,279),Color("#c5ffaf"))

func _process(delta: float) -> void:
    super._process(delta)
    if not premium35_ready:
        return
    # Rebase legacy animation on the new stage coordinates each frame.
    var player_lunge: float = (sin((1.0-lunge31/0.2)*PI)*37.0
        if lunge31 > 0.0 else 0.0)
    hero_art.position = Vector2(63.0+player_lunge,250.0+sin(scene_clock31*1.75)*3.0)
    hero_art.rotation = -sin(scene_clock31*76.0)*stagger31*0.14
    enemy_art.position = Vector2(
        752.0+sin(scene_clock31*91.0)*enemy_hit31*25.0,
        242.0+sin(scene_clock31*1.53+0.5)*3.4)
    if stagger31 > 0.11:
        hero_art.modulate = Color("#ffe1d4")
    else:
        hero_art.modulate = Color.WHITE
