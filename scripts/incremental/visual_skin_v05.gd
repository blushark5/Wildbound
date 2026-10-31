extends RefCounted
## Wildbound Creature Ascension: original-asset visual presentation pass.
## Presentation only. Does NOT create static screenshot-based buttons,
## replace creature gameplay data, or touch persistent browser saves.
const GROVE := Color("#79d7a4")
const TIDE := Color("#69c3ef")
const EMBER := Color("#f4a674")
const BRONZE := Color("#edbc6c")
const LIT := Color("#edf5e8")
const BORDER := Color("#42788a")

static func _border(fill: Color, edge: Color, corner: int = 10) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = edge
    style.set_border_width_all(2)
    style.set_corner_radius_all(corner)
    style.shadow_color = Color("#040b15",0.7)
    style.shadow_size = 3
    style.shadow_offset = Vector2(1,2)
    style.content_margin_left = 9.0
    style.content_margin_right = 9.0
    style.content_margin_top = 8.0
    style.content_margin_bottom = 8.0
    return style

static func _add_original_backdrop(panel: Panel, texture_path: String, opacity: float) -> void:
    # The existing Wildbound art is a decorative layer, never the input surface.
    var image: Texture2D = load(texture_path) as Texture2D
    if image == null:
        return
    panel.clip_contents = true
    var backdrop := TextureRect.new()
    backdrop.name = "OriginalWildboundBackdrop"
    backdrop.texture = image
    backdrop.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    backdrop.position = Vector2.ZERO
    backdrop.size = panel.size
    backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    backdrop.modulate = Color(0.78,0.94,0.88,opacity)
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_child(backdrop)
    var veil := ColorRect.new()
    veil.name = "ReadableContentVeil"
    veil.position = Vector2.ZERO
    veil.size = panel.size
    veil.color = Color(0.04,0.12,0.20,0.44)
    veil.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_child(veil)

static func apply(root: Control) -> void:
    var root_panel: Panel = root.get_node_or_null("Header") as Panel
    if root_panel != null:
        root_panel.add_theme_stylebox_override("panel",_border(Color("#102b3b"),BRONZE))
        _add_original_backdrop(root_panel,"res://assets/battle_woodland.png",0.18)
    var left: Panel = root.get_node_or_null("PackPane") as Panel
    if left != null:
        left.add_theme_stylebox_override("panel",_border(Color("#102836"),GROVE))
    var middle: Panel = root.get_node_or_null("ArenaPane") as Panel
    if middle != null:
        middle.add_theme_stylebox_override("panel",_border(Color("#102d35"),TIDE))
    var right: Panel = root.get_node_or_null("UpgradePane") as Panel
    if right != null:
        right.add_theme_stylebox_override("panel",_border(Color("#102837"),TIDE))
    var footer: Panel = root.get_node_or_null("Footer") as Panel
    if footer != null:
        footer.add_theme_stylebox_override("panel",_border(Color("#102b3b"),BORDER,6))

    var colors: Dictionary = {"spriglet":GROVE,"brinlet":TIDE,"cindlet":EMBER}
    var art: Dictionary = {
        "spriglet":"res://assets/battle_meadow.png",
        "brinlet":"res://assets/battle_shore.png",
        "cindlet":"res://assets/battle_woodland.png"}
    for kind in colors:
        var card: Panel = root.get_node_or_null("PackCard_"+kind) as Panel
        if card != null:
            card.add_theme_stylebox_override("panel",_border(Color("#143342"),colors[kind],7))
            _add_original_backdrop(card,String(art[kind]),0.29)
        var name_label: Label = root.get_node_or_null("name_"+kind) as Label
        if name_label != null:
            name_label.add_theme_color_override("font_color",colors[kind])
            name_label.add_theme_constant_override("outline_size",1)

    var arena: Panel = root.get_node_or_null("EnemyArena") as Panel
    if arena != null:
        arena.add_theme_stylebox_override("panel",_border(Color("#17414b"),Color("#6eb8c3"),8))
    for name in ["Tap","Save","Resonance"]:
        var btn: Button = root.get_node_or_null(name) as Button
        if btn != null:
            var tone: Color = BRONZE if name in ["Tap","Save"] else TIDE
            btn.add_theme_stylebox_override("normal",_border(Color("#754a31") if name == "Tap" else Color("#1b5260"),tone,7))
            btn.add_theme_stylebox_override("hover",_border(Color("#9c6938") if name == "Tap" else Color("#28758b"),Color("#fff0ba"),7))
            btn.add_theme_stylebox_override("pressed",_border(Color("#593421") if name == "Tap" else Color("#154553"),tone,7))
            btn.add_theme_font_size_override("font_size",17 if name == "Tap" else 13)

    for name in ["Logo","PackTitle","RegionTitle","UpgradesTitle","WaveTitle"]:
        var heading: Label = root.get_node_or_null(name) as Label
        if heading != null:
            heading.add_theme_color_override("font_shadow_color",Color("#071421",0.85))
            heading.add_theme_constant_override("shadow_offset_x",2)
            heading.add_theme_constant_override("shadow_offset_y",2)
    var title: Label = root.get_node_or_null("Logo") as Label
    if title != null:
        title.add_theme_color_override("font_color",Color("#d4ffe5"))
        title.add_theme_font_size_override("font_size",34)

static func accent_progress(fill: ColorRect, color: Color) -> void:
    if fill != null:
        fill.color = color

static func apply_right_card(card: PanelContainer, title: Label, action: Button, kind: String) -> void:
    var tone: Color = BORDER
    if kind in ["hatch","lineage","camp","mastery","mastery_guide"]:
        tone = GROVE
    elif kind in ["ascend","research","relic","vault","cache","cache_guide"]:
        tone = BRONZE
    elif kind in ["contract","goal","region"]:
        tone = TIDE
    card.add_theme_stylebox_override("panel",_border(Color("#193746"),tone.darkened(0.25),7))
    title.add_theme_color_override("font_color",tone.lightened(0.12))
    var normal_style: StyleBoxFlat = _border(Color("#244b60"),tone.darkened(0.08),5)
    action.add_theme_stylebox_override("normal",normal_style)
    action.add_theme_stylebox_override("hover",_border(Color("#347489"),tone.lightened(0.2),5))
    action.add_theme_stylebox_override("pressed",_border(Color("#163a51"),tone,5))
