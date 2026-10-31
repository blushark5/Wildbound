extends "res://scripts/incremental/alpha_ui.gd"
## Alpha 0.6 — art-directed battle composition with a full 3-creature squad,
## environmental motion and accessible presentation.
## Inherits existing progression/controls: nothing is faked or screen-baked.

const COMBAT_FX = preload("res://scripts/incremental/combat_fx_v06.gd")
const ART_BANK = preload("res://scripts/incremental/portrait_bank_v06.gd")
const SPRITE_SHADER = preload("res://assets/shaders/creature_rim_v06.gdshader")
const SHADES: Dictionary = {
    "spriglet": Color("#90f2b3"),
    "brinlet": Color("#8ad6ff"),
    "cindlet": Color("#ffc17d")
}
var unit_sprites: Dictionary = {}
var art_portraits: Dictionary = {}
var unit_cached: Dictionary = {}
var unit_names: Dictionary = {}
var art_fx: Control
var resource_chips: Dictionary = {}
var mobile_hint: Label
var glow_strip: ColorRect

func _layout() -> void:
    super._layout()
    _style_shell()
    _create_resource_chips()
    _redesign_battle()
    _style_tabs()
    _style_footer()

func _style_shell() -> void:
    var wallpaper: ColorRect = get_node("Backdrop") as ColorRect
    wallpaper.color = Color("#0a1727")
    var corners: Dictionary = {
        "Header":Color("#dcbf81"),
        "PackPane":Color("#65bca0"),
        "ArenaPane":Color("#63afcb"),
        "UpgradePane":Color("#d3b57a"),
        "Footer":Color("#4f91b0")}
    for key in corners:
        var panel: Panel = get_node(key) as Panel
        var color: Color = corners[key]
        panel.add_theme_stylebox_override("panel",_style(Color("#142e40") if key != "ArenaPane" else Color("#123746"),color,10))
    var logo: Label = get_node("Logo") as Label
    logo.add_theme_font_size_override("font_size",34)
    logo.add_theme_color_override("font_color",Color("#e9f8df"))
    var p: Label = get_node("Sublogo") as Label
    p.text = "CREATURE ASCENSION  •  ART ALPHA 0.6"
    p.add_theme_color_override("font_color",Color("#a5cad3"))
    for creature in ENGINE.ORDER:
        var card: Panel = get_node("PackCard_"+creature) as Panel
        card.add_theme_stylebox_override("panel",_style(Color("#163a49"),SHADES[creature],8))
        var portrait: TextureRect = portraits[creature]
        portrait.size = Vector2(95,91)
        portrait.position = Vector2(31,164+137.0*float(ENGINE.ORDER.find(creature)))
        portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        portrait.material = _make_rim(SHADES[creature],0.78)
        # Real raster portrait crops from the original concept sheet;
        # fallback original creatures remain available after evolution.
        var concept_texture: Texture2D = ART_BANK.portrait(creature)
        if concept_texture != null:
            var art := TextureRect.new()
            art.name = "IllustratedPortrait_"+creature
            art.position = portrait.position
            art.size = Vector2(91,92)
            art.texture = concept_texture
            art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
            art.mouse_filter = Control.MOUSE_FILTER_IGNORE
            add_child(art)
            art_portraits[creature] = art
        var title: Label = labels["name_"+creature]
        title.add_theme_color_override("font_color",SHADES[creature])
        var ability: Button = ally_skills[creature]
        ability.add_theme_stylebox_override("normal",_style(Color("#21475b"),SHADES[creature],5))
        ability.add_theme_stylebox_override("hover",_style(Color("#2e6677"),SHADES[creature].lightened(0.23),5))
        ability.add_theme_font_size_override("font_size",12)

func _make_rim(color: Color, strength: float) -> ShaderMaterial:
    var material := ShaderMaterial.new()
    material.shader = SPRITE_SHADER
    material.set_shader_parameter("rim_color",color)
    material.set_shader_parameter("rim_strength",strength)
    material.set_shader_parameter("glint",0.08)
    return material

func _create_resource_chips() -> void:
    var base: Label = labels["Resources"]
    base.visible = false
    var layout: Array[Dictionary] = [
        {"key":"gold","title":"GOLD","glyph":"◆","tone":Color("#f5c778")},
        {"key":"echoes","title":"ECHOES","glyph":"✦","tone":Color("#beadff")},
        {"key":"nests","title":"NEST SHARDS","glyph":"◇","tone":Color("#8cd5ff")},
        {"key":"ascensions","title":"ASCENSIONS","glyph":"✺","tone":Color("#f5a971")}
    ]
    for i in range(layout.size()):
        var entry: Dictionary = layout[i]
        var px: float = 350.0 + float(i)*157.0
        var panel: Panel = _panel(self,"Resource_"+String(entry["key"]),Rect2(px,19,150,49),Color("#102a3b"))
        panel.add_theme_stylebox_override("panel",_style(Color("#0f2c40"),entry["tone"].darkened(0.4),6))
        _label(self,"resource_icon_"+String(entry["key"]),String(entry["glyph"]),Rect2(px+8,28,25,28),21,entry["tone"])
        _label(self,"resource_value_"+String(entry["key"]),"0",Rect2(px+36,26,108,28),21,Color("#f5eee0"))
        var hint: Label = _label(self,"resource_name_"+String(entry["key"]),String(entry["title"]),Rect2(px+38,51,108,12),9,entry["tone"])
        hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
        resource_chips[String(entry["key"])] = panel

func _redesign_battle() -> void:
    var background: TextureRect = arena_art
    background.modulate = Color(1,1,1,0.96)
    var readability: ColorRect = get_node_or_null("ReadableContentVeil") as ColorRect
    if readability != null:
        readability.color = Color("#061521",0.09)
    # The stage takes up most of the center column. The original painted
    # environment and actual monster textures are separate layers.
    var arena: Panel = get_node("EnemyArena") as Panel
    arena.add_theme_stylebox_override("panel",_style(Color("#153e40"),Color("#88cbcb"),8))
    enemy_portrait.position = Vector2(621,218)
    enemy_portrait.size = Vector2(187,150)
    enemy_portrait.material = _make_rim(Color("#ffd29d"),0.88)
    ally_portrait.position = Vector2(394,260)
    ally_portrait.size = Vector2(95,98)
    ally_portrait.material = _make_rim(Color("#97e8ab"),0.78)
    ally_lead_label.position = Vector2(390,214)
    ally_lead_label.size = Vector2(207,23)
    ally_lead_label.add_theme_font_size_override("font_size",13)
    var enemy_title: Label = get_node("EnemyName") as Label
    enemy_title.position = Vector2(574,186)
    enemy_title.size = Vector2(248,26)
    enemy_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    enemy_title.add_theme_font_size_override("font_size",16)
    enemy_title.add_theme_color_override("font_color",Color("#ffdfb3"))
    var subtitles: Label = get_node("DamageText") as Label
    subtitles.add_theme_color_override("font_color",Color("#ffe4c2"))
    var health: Label = get_node("EnemyHp") as Label
    health.add_theme_color_override("font_color",Color("#f5edd8"))
    var button: Button = get_node("Tap") as Button
    button.add_theme_font_size_override("font_size",18)
    button.add_theme_stylebox_override("normal",_style(Color("#74462d"),Color("#f1bf79"),8))
    button.add_theme_stylebox_override("hover",_style(Color("#a36535"),Color("#ffe2a2"),8))
    button.add_theme_stylebox_override("pressed",_style(Color("#633d28"),Color("#d8b575"),8))
    var ward_title: Label = get_node("WardText") as Label
    ward_title.add_theme_color_override("font_color",Color("#d3f6e2"))
    var stage: Control = COMBAT_FX.new()
    stage.name = "BattleFieldEffects"
    stage.position = Vector2(367,172)
    stage.size = Vector2(474,274)
    add_child(stage)
    move_child(stage,ally_portrait.get_index())
    art_fx = stage
    # All three allies enter battle. Keep the existing dynamic lead portrait,
    # but also show the other two unlocked creatures without creating any
    # new combat actors or changing attack math.
    for i in range(2):
        var pic := TextureRect.new()
        pic.name = "SquadArt%d" % i
        pic.position = Vector2(453.0+float(i)*56.0,284.0+float(i)*9.0)
        pic.size = Vector2(81,78)
        pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
        pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(pic)
        move_child(pic,enemy_portrait.get_index())
        unit_sprites[i] = pic
        unit_cached[i] = ""
    var caption: Label = _label(self,"SquadStatus","THE PACK ADVANCES",Rect2(390,382,218,22),12,Color("#d9f6db"))
    caption.add_theme_color_override("font_shadow_color",Color("#061c20"))
    caption.add_theme_constant_override("shadow_offset_x",1)
    caption.add_theme_constant_override("shadow_offset_y",1)
    var callout := _label(self,"StageFlag","",Rect2(641,374,172,22),12,Color("#ffd79d"))
    callout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    glow_strip = _bar(self,"VisualResonanceAccent",Rect2(365,601,480,3),Color("#ba83f2"))
    mobile_hint = _label(self,"MobileHint","LANDSCAPE VIEW RECOMMENDED",Rect2(707,624,140,13),9,Color("#9abac3"))
    mobile_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _style_tabs() -> void:
    for name in tab_buttons:
        var tab_btn: Button = tab_buttons[name]
        tab_btn.add_theme_stylebox_override("normal",_style(Color("#203d50"),Color("#476a7c"),4))
        tab_btn.add_theme_stylebox_override("hover",_style(Color("#336883"),Color("#8fdcfa"),4))
        tab_btn.add_theme_font_size_override("font_size",9)
    var header: Label = get_node("UpgradesTitle") as Label
    header.add_theme_color_override("font_color",Color("#ffe5b1"))

func _style_footer() -> void:
    var controls: Array[String] = ["AutoBuy","AutoSkills","Repeat","Batch","Speed","Save"]
    for name in controls:
        var button: Button = buttons[name]
        var accent: Color = Color("#f1bb70") if name == "Save" else Color("#64bfca")
        button.add_theme_stylebox_override("normal",_style(Color("#1d4356"),accent.darkened(0.24),5))
        button.add_theme_stylebox_override("hover",_style(Color("#2d667d"),accent,5))
        button.add_theme_font_size_override("font_size",12)

func _refresh() -> void:
    super._refresh()
    if game == null or art_fx == null:
        return
    labels["resource_value_gold"].text = game.format_number(game.gold)
    labels["resource_value_echoes"].text = str(game.echoes)
    labels["resource_value_nests"].text = str(game.nests)
    labels["resource_value_ascensions"].text = str(game.ascensions)
    # Base class also refreshes all original buttons, prices, enemy HP and
    # save state. We don't duplicate the gameplay rules.
    enemy_portrait.position = Vector2(
        621.0 + (sin(visual_time*43.0)*3.0 if game.damage_flash > 0.0 and not motion_reduced else 0.0),
        218.0 + (0.0 if motion_reduced else sin(visual_time*2.6)*3.0))
    ally_portrait.position = Vector2(394,260+(0.0 if motion_reduced else sin(visual_time*2.2+1.0)*2.0))
    art_fx.refresh_from_game(game,motion_reduced)
    _refresh_squad()
    for kind in art_portraits:
        var portrait: TextureRect = art_portraits[kind]
        portrait.visible = not bool(game.evolved[kind])
        portrait.modulate = Color("#a7afb1") if int(game.levels[kind]) == 0 else Color.WHITE
    var rank: String = game.enemy_mutator()
    labels["StageFlag"].text = ("◆ "+rank.to_upper()) if rank != "" else ("◆ "+String(ENGINE.REGIONS[game.region]["name"]).to_upper())
    labels["SquadStatus"].text = "YOUR PACK • %d ACTIVE" % _active_creatures()
    glow_strip.size.x = 476.0 * clampf(game.overdrive/100.0,0.0,1.0)
    # Color status uses labels, not baked-in screenshot text.
    if game.enemy_is_boss():
        labels["WaveTitle"].add_theme_color_override("font_color",Color("#ffd18e"))
    else:
        labels["WaveTitle"].add_theme_color_override("font_color",Color("#dcefc7"))

func _active_creatures() -> int:
    var count: int = 0
    for kind in ENGINE.ORDER:
        if int(game.levels[kind]) > 0:
            count += 1
    return count

func _refresh_squad() -> void:
    var leader: String = "spriglet"
    var maximum: float = -1.0
    for kind in ENGINE.ORDER:
        if int(game.levels[kind]) < 1:
            continue
        var dps: float = game.species_damage(kind)/game.attack_interval(kind)
        if dps > maximum:
            maximum = dps
            leader = kind
    var sidekicks: Array[String] = []
    for kind in ENGINE.ORDER:
        if kind != leader and int(game.levels[kind]) > 0:
            sidekicks.append(kind)
    for i in range(2):
        var portrait: TextureRect = unit_sprites[i]
        if i >= sidekicks.size():
            portrait.visible = false
            continue
        portrait.visible = true
        var kind: String = sidekicks[i]
        var chosen_path: String = "res://assets/%s%s_back.png" % [
            kind,"_evo" if bool(game.evolved[kind]) else ""]
        if unit_cached[i] != chosen_path:
            portrait.texture = load(chosen_path) as Texture2D
            portrait.material = _make_rim(SHADES[kind],0.7)
            unit_cached[i] = chosen_path
        portrait.modulate = Color("#e1ceff") if bool(game.rare[kind]) else Color.WHITE
        portrait.position.y = 284.0+float(i)*9.0 + (0.0 if motion_reduced else sin(visual_time*2.0+float(i)*1.7)*2.0)

func _switch_tab(next: String) -> void:
    super._switch_tab(next)
    if tab_buttons.has(next):
        for name in tab_buttons:
            var btn: Button = tab_buttons[name]
            if String(name) == next:
                btn.add_theme_stylebox_override("normal",_style(Color("#4b5e61"),Color("#ffda99"),4))
            else:
                btn.add_theme_stylebox_override("normal",_style(Color("#203d50"),Color("#476a7c"),4))
