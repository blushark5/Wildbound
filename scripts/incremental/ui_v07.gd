extends "res://scripts/incremental/ui_v06.gd"
## Visual architecture rebuild v0.7.
## Enlarges the actual interactive battle stage by ~80% area.
## Reflows, rather than decorates, the left creature roster and right progression.
## All creature skills, click/auto combat, research, and autosaving still derive
## from the existing engine and working scene.

const BATTLE_ART = preload("res://scripts/incremental/bestiary_art_v07.gd")
const PLATE := Color("#102332")
const EDGE := Color("#d2ab68")
const LIGHT := Color("#edf5e5")
const PALE := Color("#bad7ce")
const FIRE := Color("#ffba78")
const AQUA := Color("#88d5e1")

func _layout() -> void:
    super._layout()
    _rebuild_hierarchy()
    _enhance_stage()

func _move(name: String, pos: Vector2, bounds: Vector2) -> void:
    var node: Control = get_node_or_null(name) as Control
    if node == null:
        return
    node.position = pos
    node.size = bounds
    if node is Panel:
        for child in node.get_children():
            if child is Control:
                var decor: Control = child as Control
                if decor.name == "OriginalWildboundBackdrop" or decor.name == "ReadableContentVeil":
                    decor.size = bounds

func _rebuild_hierarchy() -> void:
    _move("PackPane",Vector2(10,84),Vector2(247,558))
    _move("PackTitle",Vector2(24,97),Vector2(222,27))
    _move("PackHint",Vector2(24,127),Vector2(219,24))
    labels["PackTitle"].add_theme_font_size_override("font_size",18)
    labels["PackHint"].add_theme_font_size_override("font_size",10)
    for i in range(ENGINE.ORDER.size()):
        var species: String = String(ENGINE.ORDER[i])
        var y: float = 154.0 + float(i)*136.0
        _move("PackCard_"+species,Vector2(21,y),Vector2(224,130))
        _move("name_"+species,Vector2(104,y+11),Vector2(132,23))
        _move("stats_"+species,Vector2(104,y+39),Vector2(130,38))
        _move("buy_"+species,Vector2(104,y+78),Vector2(131,28))
        _move("skill_"+species,Vector2(28,y+107),Vector2(209,21))
        _move("IllustratedPortrait_"+species,Vector2(24,y+7),Vector2(75,88))
        if art_portraits.has(species):
            var crop: TextureRect = art_portraits[species]
            crop.size = Vector2(75,88)
        var icon: TextureRect = portraits[species]
        icon.position = Vector2(24,y+7)
        icon.size = Vector2(75,88)
        labels["name_"+species].add_theme_font_size_override("font_size",15)
        labels["stats_"+species].add_theme_font_size_override("font_size",11)
        buttons["buy_"+species].add_theme_font_size_override("font_size",12)
        ally_skills[species].add_theme_font_size_override("font_size",10)
    _move("PackFooter",Vector2(25,571),Vector2(215,18))
    _move("TacticsNote",Vector2(25,622),Vector2(218,20))
    labels["PackFooter"].add_theme_font_size_override("font_size",12)
    for i in range(ENGINE.STANCES.size()):
        var key: String = ENGINE.STANCES[i]
        var btn: Button = buttons["stance_"+key]
        btn.position = Vector2(24+float(i)*55.0,590)
        btn.size = Vector2(53,28)
        btn.add_theme_font_size_override("font_size",9)

    # The battle is now the primary focal point rather than a little window
    # embedded between two equal-size admin panels.
    _move("ArenaPane",Vector2(268,84),Vector2(744,558))
    _move("RegionTitle",Vector2(286,98),Vector2(562,32))
    _move("WaveTitle",Vector2(286,129),Vector2(620,30))
    labels["RegionTitle"].add_theme_font_size_override("font_size",27)
    labels["WaveTitle"].add_theme_font_size_override("font_size",17)
    _move("FuryCountdown",Vector2(861,139),Vector2(128,23))
    _move("EnemyArena",Vector2(284,164),Vector2(712,340))
    arena_art.position = Vector2(288,168)
    arena_art.size = Vector2(704,332)
    arena_art.modulate = Color(1,1,1,0.99)
    arena_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    if art_fx != null:
        art_fx.position = Vector2(288,168)
        art_fx.size = Vector2(704,332)
    # Move the original transparent readability overlay without baking the
    # letters/health values into an unchangeable screenshot.
    for child in get_children():
        if child is ColorRect:
            var tint: ColorRect = child as ColorRect
            if tint.position == Vector2(367,172) and tint.size == Vector2(474,274):
                tint.position = Vector2(288,168)
                tint.size = Vector2(704,332)
                tint.color = Color("#071a22",0.19)
    _move("EnemyName",Vector2(695,184),Vector2(286,27))
    _move("EnemyHp",Vector2(672,456),Vector2(305,22))
    _move("DamageText",Vector2(740,416),Vector2(236,28))
    _move("ComboCounter",Vector2(537,428),Vector2(150,25))
    enemy_portrait.position = Vector2(741,222)
    enemy_portrait.size = Vector2(210,223)
    ally_portrait.position = Vector2(319,291)
    ally_portrait.size = Vector2(152,185)
    _move("AllyLead",Vector2(308,224),Vector2(285,24))
    labels["AllyLead"].add_theme_font_size_override("font_size",14)
    for i in range(2):
        if not unit_sprites.has(i):
            continue
        var fig: TextureRect = unit_sprites[i]
        fig.position = Vector2(445+float(i)*112,332+float(i)*7)
        fig.size = Vector2(145-float(i)*16,137-float(i)*6)
    _move("StageFlag",Vector2(746,378),Vector2(230,23))
    _move("SquadStatus",Vector2(306,469),Vector2(230,20))
    _move("MobileHint",Vector2(890,633),Vector2(90,15))
    _move("Tap",Vector2(290,507),Vector2(704,43))
    # Reposition the two unnamed bar backgrounds, as well as their fills.
    for child in get_children():
        if child is ColorRect:
            var rect: ColorRect = child as ColorRect
            if rect.position == Vector2(381,416) and rect.size == Vector2(444,14):
                rect.position = Vector2(300,490)
                rect.size = Vector2(690,14)
            elif rect.position == Vector2(362,537) and rect.size == Vector2(480,18):
                rect.position = Vector2(288,586)
                rect.size = Vector2(704,18)
    _move("WardText",Vector2(288,562),Vector2(695,22))
    _move("WardBar",Vector2(290,587),Vector2(699,15))
    _move("DpsText",Vector2(288,607),Vector2(430,24))
    _move("ArenaFooter",Vector2(288,631),Vector2(270,16))
    _move("ResonanceBar",Vector2(578,628),Vector2(229,12))
    _move("Resonance",Vector2(816,611),Vector2(176,32))
    labels["EnemyName"].add_theme_font_size_override("font_size",18)
    labels["EnemyHp"].add_theme_font_size_override("font_size",13)
    labels["EnemyHp"].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    labels["DamageText"].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    labels["StageFlag"].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    labels["ArenaFooter"].add_theme_font_size_override("font_size",10)
    labels["ArenaFooter"].visible = false
    labels["MobileHint"].visible = false

    _move("UpgradePane",Vector2(1021,84),Vector2(247,558))
    _move("UpgradesTitle",Vector2(1035,99),Vector2(220,28))
    labels["UpgradesTitle"].add_theme_font_size_override("font_size",19)
    for i in range(TABS.size()):
        var key: String = TABS[i]
        var btn: Button = tab_buttons[key]
        var row_index: int = i/4
        var column_index: int = i%4
        btn.position = Vector2(1031+float(column_index)*57,136+float(row_index)*36)
        btn.size = Vector2(54,32)
        btn.add_theme_font_size_override("font_size",9)
    tab_scroll.position = Vector2(1032,214)
    tab_scroll.size = Vector2(225,417)
    tab_column.custom_minimum_size = Vector2(209,0)
    _move("Footer",Vector2(10,653),Vector2(1258,57))
    _move("Notice",Vector2(25,670),Vector2(440,26))
    var control_positions: Dictionary = {
        "AutoBuy":Vector2(470,664),"AutoSkills":Vector2(581,664),
        "Repeat":Vector2(706,664),"Batch":Vector2(820,664),
        "Speed":Vector2(912,664),"Save":Vector2(1045,664)
    }
    var control_widths: Dictionary = {
        "AutoBuy":105.0,"AutoSkills":119.0,"Repeat":108.0,
        "Batch":86.0,"Speed":125.0,"Save":207.0
    }
    for key in control_positions:
        var control: Button = buttons[key]
        control.position = control_positions[key]
        control.size = Vector2(float(control_widths[key]),36)
        control.add_theme_font_size_override("font_size",12)
    buttons["Save"].add_theme_color_override("font_color",Color("#fff0cc"))

func _enhance_stage() -> void:
    # Painterly original sprites already installed in v06 are now sized for
    # the significantly larger battle. Keep backing engine content dynamic.
    var title: Label = labels["RegionTitle"]
    title.add_theme_color_override("font_color",Color("#f2f6e0"))
    title.add_theme_color_override("font_shadow_color",Color("#071b1f"))
    title.add_theme_constant_override("shadow_offset_x",2)
    title.add_theme_constant_override("shadow_offset_y",2)
    for label_name in ["EnemyName","EnemyHp","WaveTitle","AllyLead","DamageText"]:
        var label: Label = labels[label_name]
        label.add_theme_color_override("font_shadow_color",Color("#08141c"))
        label.add_theme_constant_override("shadow_offset_x",2)
        label.add_theme_constant_override("shadow_offset_y",2)
    var bg: Panel = get_node("EnemyArena") as Panel
    bg.add_theme_stylebox_override("panel",_style(Color("#10202a"),Color("#dcbd80"),7))
    # Replace the badly enlarged 24px prototype monsters with genuine,
    # independent transparent artwork from the approved bestiary.
    for kind in ENGINE.ORDER:
        var painted: Texture2D = BATTLE_ART.get_creature(String(kind))
        if painted == null:
            continue
        if art_portraits.has(kind):
            var card_art: TextureRect = art_portraits[kind]
            card_art.texture = painted
            card_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        portraits[kind].texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    enemy_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    ally_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    enemy_portrait.flip_h = true
    var strike: Button = buttons["Tap"]
    strike.add_theme_stylebox_override("normal",_style(Color("#90432b"),Color("#ffc67b"),9))
    strike.add_theme_stylebox_override("hover",_style(Color("#c45a35"),Color("#fff1ae"),9))
    strike.add_theme_font_size_override("font_size",19)
    strike.text = "⚔  STRIKE  •  CLICK / SPACE"
    var sidebar: Panel = get_node("UpgradePane") as Panel
    sidebar.add_theme_stylebox_override("panel",_style(Color("#122638"),Color("#bc9c67"),9))

func _new_card(title: String, description: String, button_text: String, fn: Callable, min_height: float = 102.0) -> Dictionary:
    var row: Dictionary = super._new_card(title,description,button_text,fn,maxf(min_height,115.0))
    var container: PanelContainer = row["card"]
    container.custom_minimum_size = Vector2(208,maxf(min_height,115.0))
    var heading: Label = row["title"]
    heading.add_theme_font_size_override("font_size",13)
    var info: Label = row["info"]
    info.add_theme_font_size_override("font_size",11)
    var action: Button = row["button"]
    action.custom_minimum_size = Vector2(185,30)
    action.add_theme_font_size_override("font_size",11)
    return row

func _refresh() -> void:
    super._refresh()
    if game == null or art_fx == null:
        return
    # Restore higher-resolution original creatures after the parent redraws
    # the low-res placeholder sprites. Evolved forms retain old fallbacks
    # until their own independent artwork is ready.
    var leader: String = "spriglet"
    var highest: float = -1.0
    for candidate in ENGINE.ORDER:
        if int(game.levels[candidate]) > 0:
            var strength: float = game.species_damage(candidate) / game.attack_interval(candidate)
            if strength > highest:
                highest = strength
                leader = String(candidate)
        if not bool(game.evolved[candidate]):
            var card_texture: Texture2D = BATTLE_ART.get_creature(String(candidate))
            if card_texture != null and art_portraits.has(candidate):
                var card: TextureRect = art_portraits[candidate]
                card.texture = card_texture
    if not bool(game.evolved[leader]):
        var ally_texture: Texture2D = BATTLE_ART.get_creature(leader)
        if ally_texture != null:
            ally_portrait.texture = ally_texture
    for i in range(2):
        var sidekeys: Array[String] = []
        for member in ENGINE.ORDER:
            if String(member) != leader and int(game.levels[member]) > 0:
                sidekeys.append(String(member))
        if i < sidekeys.size() and not bool(game.evolved[sidekeys[i]]):
            var side_art: Texture2D = BATTLE_ART.get_creature(sidekeys[i])
            if side_art != null:
                var sprite: TextureRect = unit_sprites[i]
                sprite.texture = side_art
                sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    if not game.enemy_is_boss():
        var foe_art: Texture2D = BATTLE_ART.get_creature(game.enemy_species)
        if foe_art != null:
            enemy_portrait.texture = foe_art
    # Base class sets old 480x270 screen positions each frame; enforce the
    # 704x332 battlefield and 3-aligned formation instead.
    enemy_portrait.position = Vector2(
        741.0 + (sin(visual_time*38.0)*3.0 if game.damage_flash > 0.0 and not motion_reduced else 0.0),
        222.0 + (0.0 if motion_reduced else sin(visual_time*2.2)*2.0))
    ally_portrait.position = Vector2(319.0,
        291.0 + (0.0 if motion_reduced else sin(visual_time*2.3)*2.0))
    for i in range(2):
        if unit_sprites.has(i):
            var fig: TextureRect = unit_sprites[i]
            fig.position = Vector2(445+float(i)*112,
                332+float(i)*7+(0.0 if motion_reduced else sin(visual_time*1.9+float(i))*2.0))
    # Full-width bars corresponding to the new readable HUD.
    var hp_ratio: float = clampf(game.enemy_hp/maxf(game.enemy_max_hp,1.0),0.0,1.0)
    enemy_fill.position = Vector2(301,490)
    enemy_fill.size = Vector2(687.0*hp_ratio,11)
    var ward_ratio: float = clampf(game.ward/maxf(game.max_ward(),1.0),0.0,1.0)
    ward_fill.position = Vector2(290,587)
    ward_fill.size = Vector2(699.0*ward_ratio,14)
    resonance_fill.position = Vector2(579,629)
    resonance_fill.size = Vector2(225.0*clampf(game.overdrive/100.0,0.0,1.0),9)
    glow_strip.visible = false
    labels["SquadStatus"].visible = false
    labels["MobileHint"].visible = false
    labels["ArenaFooter"].visible = false
    labels["StageFlag"].position = Vector2(746,378)
    labels["PackFooter"].visible = true
    # Old caption can overlap the enemy health UI in v0.6.
    labels["DamageText"].text = (
        ("CRITICAL  " if game.recent_critical else "HIT  ")+game.format_number(game.recent_hit)
        if game.damage_flash > 0.0 else "")
