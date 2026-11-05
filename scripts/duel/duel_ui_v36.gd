extends "res://scripts/duel/duel_ui_v35.gd"
## Wildbound v0.36 -- reconstructed concept-driven battle composition.
## All economy, battle, saves, and button callbacks remain in the v0.30 engine.
const ILLUSTRATION36 = preload("res://scripts/duel/painted_art_v36.gd")
var composition36_ready: bool = false
var hero_portrait36: TextureRect
var foe_portrait36: TextureRect
var hero_gem36: Panel
var enemy_gem36: Panel
var river_clock36: float = 0.0
var background_bloom36: ColorRect

func _ready() -> void:
    super._ready()
    _rebuild_illustrated_stage36()
    composition36_ready = true
    (get_node("Tagline") as Label).text = "THE GUARDIAN TRIAL  •  v0.36"
    DisplayServer.window_set_title("Wildbound: Guardian Trial v0.36")
    _refresh()

func _rebuild_illustrated_stage36() -> void:
    # Preserve interactive controls but replace the full-screen battle art.
    landscape.texture = ILLUSTRATION36.environment()
    landscape.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    landscape.modulate = Color.WHITE
    landscape.position = Vector2.ZERO
    landscape.size = Vector2(1280,720)
    # De-emphasize inherited artificial particles. Painted scenery carries
    # sunlight, ruins, mist and water instead of extra flat overlays.
    ambient32.modulate.a = 0.12
    _hide35("HeroPremiumPlate35")
    _hide35("EnemyPremiumPlate35")
    _hide35("AutoCombatStatus")
    _hide35("GuardianCountdown")
    for dot in progress_pips32:
        (dot as Panel).hide()

    var hero_plate: Panel = _panel(self,"IllustratedHeroPlate36",
        Rect2(18,107,414,105),Color("#091424",0.94),
        Color("#dfb978"),13,3)
    var foe_plate: Panel = _panel(self,"IllustratedRivalPlate36",
        Rect2(848,107,414,105),Color("#091424",0.94),
        Color("#dfb978"),13,3)
    move_child(hero_plate,hero_name.get_index())
    move_child(foe_plate,enemy_name.get_index())
    var hero_frame: Panel = _panel(self,"HeroPortraitFrame36",
        Rect2(24,114,95,94),Color("#14263b"),
        Color("#ffe09a"),14,3)
    var foe_frame: Panel = _panel(self,"RivalPortraitFrame36",
        Rect2(1160,114,95,94),Color("#15273b"),
        Color("#ffe09a"),14,3)
    hero_portrait36 = _art(self,"HeroPortrait36",
        ILLUSTRATION36.portrait("cindlet"),Rect2(28,117,88,88))
    foe_portrait36 = _art(self,"RivalPortrait36",
        ILLUSTRATION36.portrait("brinlet"),Rect2(1164,117,88,88))
    hero_portrait36.flip_h = false
    foe_portrait36.flip_h = false
    hero_portrait36.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    foe_portrait36.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

    _place35(hero_name,Vector2(143,112),Vector2(268,37))
    _place35(enemy_name,Vector2(883,112),Vector2(267,37))
    _place35(hero_element,Vector2(147,149),Vector2(256,20))
    _place35(enemy_element,Vector2(885,149),Vector2(260,20))
    _place35(hero_icon35,Vector2(121,149),Vector2(24,24))
    _place35(enemy_icon35,Vector2(858,149),Vector2(24,24))
    hero_name.add_theme_font_size_override("font_size",24)
    enemy_name.add_theme_font_size_override("font_size",24)
    hero_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    enemy_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    hero_element.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    enemy_element.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    _place35(get_node("HeroHealthBg") as Control,Vector2(139,175),Vector2(278,26))
    _place35(get_node("EnemyHealthBg") as Control,Vector2(880,175),Vector2(271,26))
    _place35(hero_hp_bar,Vector2(145,182),Vector2(266,13))
    _place35(enemy_hp_bar,Vector2(886,182),Vector2(259,13))
    _place35(hero_damage_tail33,Vector2(145,182),Vector2(266,13))
    _place35(enemy_damage_tail33,Vector2(886,182),Vector2(259,13))
    _place35(hero_hp_text,Vector2(145,176),Vector2(265,24))
    _place35(enemy_hp_text,Vector2(887,176),Vector2(258,24))
    hero_hp_bar.color = Color("#58d33b")
    enemy_hp_bar.color = Color("#58d33b")
    for label in [hero_hp_text,enemy_hp_text]:
        label.add_theme_color_override("font_color",Color("#fff9df"))
        label.add_theme_constant_override("outline_size",4)
        label.add_theme_color_override("font_outline_color",Color("#071425"))
    (get_node("HeroHealthBg") as Panel).add_theme_stylebox_override(
        "panel",_style(Color("#071427"),Color("#e0ba7a"),6,2,2))
    (get_node("EnemyHealthBg") as Panel).add_theme_stylebox_override(
        "panel",_style(Color("#071427"),Color("#e0ba7a"),6,2,2))

    _place35(battle_header,Vector2(450,9),Vector2(380,80))
    battle_header.add_theme_stylebox_override(
        "panel",_style(Color("#101928",0.96),Color("#efc779"),17,3,7))
    _place35(stage_title,Vector2(468,15),Vector2(345,38))
    _place35(stage_subtitle,Vector2(477,53),Vector2(325,25))
    stage_title.add_theme_font_size_override("font_size",29)
    stage_title.add_theme_color_override("font_color",Color("#ffeacc"))
    stage_subtitle.add_theme_font_size_override("font_size",15)
    stage_subtitle.add_theme_color_override("font_color",Color("#d8e7d5"))

    _place35(get_node("HeroAura") as Control,Vector2(105,578),Vector2(344,26))
    _place35(get_node("RivalAura") as Control,Vector2(829,578),Vector2(350,25))
    _place35(hero_art,Vector2(10,270),Vector2(545,350))
    _place35(enemy_art,Vector2(738,267),Vector2(529,353))
    enemy_art.flip_h = false
    _place35(enemy_hit_button,Vector2(752,270),Vector2(477,324))
    _place35(victory31,Vector2(451,250),Vector2(378,147))
    _place35(power_text,Vector2(362,557),Vector2(551,30))
    _place35(notice_text,Vector2(375,587),Vector2(530,23))
    power_text.add_theme_font_size_override("font_size",16)
    power_text.add_theme_constant_override("outline_size",5)
    notice_text.add_theme_constant_override("outline_size",5)
    _place35(stage_ribbon32,Vector2(500,215),Vector2(280,73))
    # Enemy and ally paintings remain on top of the stage, under live HUD.
    hero_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    enemy_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    (get_node("QuickTeamTitle35") as Label).add_theme_font_size_override(
        "font_size",11)
    menu_button.text = "☰  MENU"
    (get_node("Logo") as Label).add_theme_font_size_override("font_size",39)

func _refresh() -> void:
    super._refresh()
    if not composition36_ready or game == null:
        return
    landscape.texture = ILLUSTRATION36.environment()
    stage_title.text = "GUARDIAN TRIAL"
    stage_subtitle.text = ("STAGE %d  •  GUARDIAN" % game.stage
        if game.is_boss() else "VERDANT GROVE  •  STAGE %d" % game.stage)
    var hero_pose: String = (
        "hurt" if stagger31 > .12 else
        "attack" if lunge31 > .10 else "idle")
    var foe_pose: String = "hurt" if enemy_hit31 > .1 else "idle"
    hero_art.texture = ILLUSTRATION36.creature(
        game.active,bool(game.evolved[game.active]),hero_pose)
    hero_art.flip_h = game.active == "brinlet"
    enemy_art.texture = ILLUSTRATION36.creature(
        game.opponent,game.is_boss(),foe_pose)
    enemy_art.flip_h = game.opponent != "brinlet"
    var rival_extent: Vector2 = (Vector2(545,375) if game.is_boss()
        else Vector2(529,353))
    enemy_art.size = rival_extent
    enemy_art.pivot_offset = rival_extent*0.5
    hero_portrait36.texture = ILLUSTRATION36.portrait(
        game.active,bool(game.evolved[game.active]))
    foe_portrait36.texture = ILLUSTRATION36.portrait(game.opponent,game.is_boss())
    hero_portrait36.flip_h = game.active == "brinlet"
    foe_portrait36.flip_h = game.opponent != "brinlet"
    for kind in DUEL.ORDER:
        (team_images35[kind] as TextureRect).texture = ILLUSTRATION36.portrait(
            kind,bool(game.evolved[kind]))
    hero_hp_bar.size.x = 266.0*clampf(
        game.hero_hp/maxf(1.0,game.hero_max_hp),0,1)
    enemy_hp_bar.size.x = 259.0*clampf(
        game.enemy_hp/maxf(1.0,game.enemy_max_hp),0,1)
    hero_damage_tail33.size.x = clampf(
        hero_damage_tail33.size.x,hero_hp_bar.size.x,266.0)
    enemy_damage_tail33.size.x = clampf(
        enemy_damage_tail33.size.x,enemy_hp_bar.size.x,259.0)
    if game.is_boss():
        enemy_art.modulate = Color("#e8f8ff") if game.impact_flash <= 0 else Color.WHITE
    (get_node("QuickTeamTitle35") as Label).text = "YOUR TEAM"

func _process(delta: float) -> void:
    super._process(delta)
    if not composition36_ready:
        return
    river_clock36 += delta
    var lunge: float = (
        sin((1.0-lunge31/.2)*PI)*42.0 if lunge31>0 else 0.0)
    hero_art.position = Vector2(
        10.0+lunge,270.0+sin(river_clock36*1.9)*3.6)
    enemy_art.position = Vector2(
        738.0+sin(river_clock36*96.0)*enemy_hit31*21.0,
        267.0+sin(river_clock36*1.55+.3)*3.3)
