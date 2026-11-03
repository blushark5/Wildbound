extends "res://scripts/incremental/collection_ui_v12.gd"
## v0.13: visual overhaul around the proven v0.12 economy and 3v3 combat.
## No new Gold/Essence logic; all controls modify real existing state.

const COIN = preload("res://assets/incremental/v13/gold.svg")
const ESSENCE = preload("res://assets/incremental/v13/essence.svg")
const ECHO = preload("res://assets/incremental/v13/echo.svg")
const HATCH_EGG = preload("res://assets/incremental/v13/nest_egg.svg")
const ARENA = {
    "Earth":preload("res://assets/incremental/v13/arena_earth.svg"),
    "Water":preload("res://assets/incremental/v13/arena_water.svg"),
    "Fire":preload("res://assets/incremental/v13/arena_fire.svg"),
    "Air":preload("res://assets/incremental/v13/arena_air.svg")
}
const PALETTE: Dictionary = {
    "base":Color("#091b29"),"raised":Color("#173747"),
    "panel":Color("#102b3a"),"edge":Color("#436774"),
    "gold":Color("#f4cf85"),"sage":Color("#98e1b7"),
    "ink":Color("#e5f0eb"),"muted":Color("#9ab5c0")
}
const ELEMENT_LIST: Array[String] = ["Earth","Water","Fire","Air"]
var visual_ready: bool = false
var codex_layer: Control
var codex_header: Label
var codex_essence: Label
var codex_progress: ColorRect
var codex_hatch: Button
var codex_status: Label
var codex_cards: Dictionary = {}
var codex_slot_buttons: Array[Button] = []
var codex_egg: TextureRect
var prev_playing: bool = true
var arena_badge: Panel
var currency_icons: Array[TextureRect] = []
var portraits_halos: Array[Panel] = []
var pack_halos: Array[Panel] = []
var element_chips: Array[Label] = []
var type_key: Label
var art_scene_element: String = ""
var last_element: String = ""
var visual_clock: float = 0.0

func _ready() -> void:
    super._ready()
    _install_world_skin()
    _build_codex()
    visual_ready = true
    _switch_tab("GROW")
    _refresh()

func _process(delta: float) -> void:
    super._process(delta)
    if not visual_ready:
        return
    visual_clock += delta
    if is_instance_valid(codex_egg):
        var bob: float = sin(visual_clock*2.1)
        codex_egg.position.y = 90.0+bob*3.0
    if is_instance_valid(arena_badge):
        arena_badge.modulate.a = 0.77+sin(visual_clock*2.2)*0.12

func _glass(fill: Color,edge: Color, radius: int = 12, width: int = 1, shadow: int = 0) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = edge
    style.set_border_width_all(width)
    style.set_corner_radius_all(radius)
    style.content_margin_left = 9
    style.content_margin_right = 9
    style.content_margin_top = 6
    style.content_margin_bottom = 6
    if shadow > 0:
        style.shadow_size = shadow
        style.shadow_color = Color("#020b16",0.38)
        style.shadow_offset = Vector2(0,3)
    return style

func _skin_button(button: Button, edge: Color, strong: bool = false) -> void:
    var color: Color = Color("#255566") if strong else Color("#1b4050")
    button.add_theme_stylebox_override("normal",_glass(color,edge,9,1,2))
    button.add_theme_stylebox_override("hover",_glass(color.lightened(0.16),edge.lightened(0.23),9,2,3))
    button.add_theme_stylebox_override("pressed",_glass(color.darkened(0.16),edge,9,2))
    button.add_theme_stylebox_override("disabled",_glass(Color("#20323b"),Color("#34505c"),9))
    button.add_theme_color_override("font_color",PALETTE["ink"])
    button.add_theme_color_override("font_hover_color",Color.WHITE)
    button.add_theme_color_override("font_disabled_color",Color("#78909a"))
    button.add_theme_font_size_override("font_size",12)

func _layer_panel(name: String,rect: Rect2,fill: Color,edge: Color,before: Control) -> Panel:
    var panel: Panel = _panel(name,rect,fill,edge)
    panel.add_theme_stylebox_override("panel",_glass(fill,edge,12,1,5))
    if is_instance_valid(before):
        move_child(panel,before.get_index())
    return panel

func _install_world_skin() -> void:
    get_node("Background").color = PALETTE["base"]
    var header: Panel = get_node("Header")
    header.add_theme_stylebox_override("panel",_glass(Color("#112c3c"),Color("#598777"),13,1,6))
    var battle_panel: Panel = get_node("BattlePanel")
    battle_panel.add_theme_stylebox_override("panel",_glass(Color("#112c3a"),Color("#679788"),15,2,6))
    var pack_panel: Panel = get_node("PackPanel")
    pack_panel.add_theme_stylebox_override("panel",_glass(Color("#112d3c"),Color("#456d6d"),13,1,5))
    var progress_panel: Panel = get_node("JourneyPanel")
    progress_panel.add_theme_stylebox_override("panel",_glass(Color("#193744"),Color("#b8a578"),13,2,5))
    var sidebar_panel: Panel = get_node("SidebarPanel")
    sidebar_panel.add_theme_stylebox_override("panel",_glass(Color("#112c3a"),Color("#4b697b"),13,1,5))
    var action_panel: Panel = get_node("ActionPanel")
    action_panel.add_theme_stylebox_override("panel",_glass(Color("#122d3e"),Color("#6a8a7c"),11,1,5))

    screen_labels["GameName"].text = "WILDBOUND"
    screen_labels["GameName"].add_theme_font_size_override("font_size",30)
    screen_labels["GameName"].add_theme_color_override("font_color",Color("#e1f3d1"))
    screen_labels["Tagline"].text = "THE LIVING WILDS  •  TRAINER ASCENT"
    screen_labels["Tagline"].add_theme_color_override("font_color",Color("#b3c7bc"))
    screen_labels["Tagline"].add_theme_font_size_override("font_size",10)

    _layer_panel("GoldChip",Rect2(378,20,230,53),Color("#273b3a"),Color("#806c46"),screen_labels["Gold"])
    _layer_panel("EssenceChip",Rect2(615,20,198,53),Color("#183c4b"),Color("#487f85"),screen_labels["Shards"])
    _layer_panel("EchoChip",Rect2(820,20,166,53),Color("#2b3046"),Color("#6a618a"),screen_labels["Echoes"])
    for name in ["Gold","Shards","Echoes"]:
        screen_labels[name].position.y = 32
        screen_labels[name].add_theme_font_size_override("font_size",16)
    screen_labels["Gold"].position.x = 420
    screen_labels["Gold"].size.x = 188
    screen_labels["Shards"].position.x = 654
    screen_labels["Shards"].size.x = 158
    screen_labels["Echoes"].position.x = 861
    screen_labels["Echoes"].size.x = 124
    var coin: TextureRect = _texture("CoinIcon",Rect2(385,31,29,29),COIN)
    var essence_icon: TextureRect = _texture("EssenceIcon",Rect2(623,31,29,29),ESSENCE)
    var echo_icon: TextureRect = _texture("EchoIcon",Rect2(829,31,29,29),ECHO)
    currency_icons.assign([coin,essence_icon,echo_icon])
    screen_labels["TrailRank"].position = Vector2(1001,37)
    screen_labels["TrailRank"].add_theme_font_size_override("font_size",12)
    _skin_button(get_node("Save"),PALETTE["gold"])
    screen_labels["PackHeader"].text = "YOUR TEAM"
    screen_labels["PackHeader"].add_theme_font_size_override("font_size",17)
    screen_labels["JourneyHeading"].text = "CHAPTER  •  THE JOURNEY"
    screen_labels["JourneyHeading"].add_theme_font_size_override("font_size",13)
    screen_labels["QuestName"].add_theme_font_size_override("font_size",20)
    screen_labels["QuestName"].add_theme_color_override("font_color",Color("#fbf0d1"))
    screen_labels["Wave"].add_theme_font_size_override("font_size",21)
    screen_labels["EnemyName"].add_theme_font_size_override("font_size",16)
    screen_labels["EncounterHint"].add_theme_font_size_override("font_size",10)
    screen_labels["EncounterHint"].size.x = 530.0
    screen_labels["DamageReadout"].add_theme_font_size_override("font_size",12)
    screen_labels["FieldStatus"].add_theme_font_size_override("font_size",11)
    screen_labels["PackDps"].add_theme_font_size_override("font_size",11)
    screen_labels["PackDps"].position.x = 352
    screen_labels["PackDps"].size.x = 308

    get_node("StageTopShade").color = Color("#071924",0.75)
    get_node("StageBottomShade").color = Color("#091a22",0.77)
    get_node("WardRail").color = Color("#173a42")
    get_node("EnemyHpRail").color = Color("#143240")
    get_node("TrailRail").color = Color("#304c50")
    get_node("WardFill").color = Color("#89deb7")
    get_node("EnemyHpFill").color = Color("#f39d85")
    get_node("TrailFill").color = PALETTE["gold"]
    for step in stage_steps:
        step.size.y = 4.0
        step.position.y = 173.0
    for button in [strike_button,resonance_button,repeat_button,speed_button,batch_button,trail_button,collect_button]:
        _skin_button(button,PALETTE["sage"])
    _skin_button(strike_button,PALETTE["gold"],true)
    _skin_button(collect_button,Color("#a4e2d4"),true)
    collect_button.text = "FIELD GUIDE"
    collect_button.size = Vector2(149,29)
    collect_button.position.x = 678
    collect_button.add_theme_font_size_override("font_size",12)
    _skin_button(trail_button,PALETTE["gold"],true)
    for k in tab_buttons:
        var btn: Button = tab_buttons[k]
        _skin_button(btn,PALETTE["sage"])
        btn.add_theme_font_size_override("font_size",10)
    for idx in range(3):
        var kind: String = String(CHALLENGE.ORDER[idx])
        var card: Panel = get_node("PackCard_"+kind)
        card.add_theme_stylebox_override("panel",_glass(Color("#183a49"),Color("#577f81"),11,1,3))
        var x: float = 24.0+float(idx)*269.0
        var bg: Panel = _layer_panel("PortraitWell_"+str(idx),
            Rect2(x+9,462,95,108),Color("#1d4551"),Color("#639b9f"),card_art[kind])
        pack_halos.append(bg)
        card_art[kind].position = Vector2(x+11,467)
        card_art[kind].size = Vector2(91,96)
        screen_labels["Name_"+kind].position.y = 458
        screen_labels["Name_"+kind].add_theme_font_size_override("font_size",14)
        card_details[kind].position.y = 485
        card_details[kind].add_theme_font_size_override("font_size",11)
        card_details[kind].size.y = 45
        _skin_button(card_buy[kind],PALETTE["gold"])
        _skin_button(card_skill[kind],PALETTE["sage"])
        _skin_button(focus_buttons[kind],PALETTE["sage"])
        var bond: ColorRect = _paint("BondTrack_"+str(idx),Rect2(x+110,570,132,3),Color("#2c555c"))
        var progress: ColorRect = _paint("BondFill_"+str(idx),Rect2(x+110,570,0,3),Color("#8ddbc2"))
        bond.z_index = 1
        progress.z_index = 1
        var chip: Label = _label("TypeChip_"+str(idx),"",Rect2(x+17,547,81,20),10,PALETTE["ink"])
        chip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        chip.add_theme_stylebox_override("normal",_glass(Color("#173846"),Color("#527b82"),6))
        element_chips.append(chip)

    for idx in range(3):
        var ally: Dictionary = ally_widgets[idx]
        var foe: Dictionary = rival_widgets[idx]
        for side in [ally,foe]:
            var art: TextureRect = side["portrait"]
            var pos: Vector2 = art.position
            var well: Panel = _layer_panel("ArenaWell_%d_%d"%[idx,1 if side == foe else 0],
                Rect2(pos.x-6,215,art.size.x+11,91),
                Color("#163447",0.41),Color("#679a9c",0.22),art)
            portraits_halos.append(well)
            art.position.y = 217
            art.size.y = 88
            side["name"].position.y = 195
            side["name"].add_theme_font_size_override("font_size",11)
            side["hp"].position.y = 324
            side["hp"].add_theme_font_size_override("font_size",10)
            side["target"].position.y = 340
            side["target"].add_theme_font_size_override("font_size",9)
            side["target"].size.y = 20
    arena_badge = _layer_panel("DuelSigil",Rect2(418,232,67,58),
        Color("#0a2833",0.75),Color("#9cd8c0",0.40),squad_status)
    squad_status.position = Vector2(423,234)
    squad_status.size = Vector2(57,53)
    squad_status.add_theme_font_size_override("font_size",10)
    squad_status.add_theme_color_override("font_color",PALETTE["gold"])
    type_key = _label("TypeCycleHint","EARTH  >  WATER  >  FIRE  >  AIR  >  EARTH",
        Rect2(192,386,466,13),10,Color("#c9e7db"))
    type_key.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    get_node("Notification").add_theme_color_override("font_color",Color("#819eab"))
    _polish_sidebar_rows()

func _refresh_landscape() -> void:
    if game == null or not game.has_method("collection_count"):
        super._refresh_landscape()
        return
    var roster: Array = game.roster_for(game.wave)
    var first: String = String(roster[0]) if not roster.is_empty() else "spriglet"
    var element: String = String(COLLECTION_ENGINE.CATALOG[first]["element"])
    if element == art_scene_element:
        return
    art_scene_element = element
    scenic_art.texture = ARENA[element]
    scenic_art.modulate = Color("#e6fcfc") if game.enemy_is_boss() else Color.WHITE

func _polish_sidebar_rows() -> void:
    for row in active_rows:
        var title: Label = row["title"]
        var button: Button = row["button"]
        var info: Label = row["info"]
        var card: PanelContainer = title.get_parent().get_parent().get_parent() as PanelContainer
        if card != null:
            card.add_theme_stylebox_override("panel",_glass(Color("#1b3b4b"),Color("#436a76"),10,1,2))
        title.add_theme_color_override("font_color",Color("#f1f4e7"))
        title.add_theme_font_size_override("font_size",13)
        info.add_theme_color_override("font_color",Color("#a8c2c7"))
        info.add_theme_font_size_override("font_size",10)
        _skin_button(button,PALETTE["sage"])

func _switch_tab(next: String) -> void:
    super._switch_tab(next)
    if not visual_ready:
        return
    if next == "NEST":
        _build_collection_teaser()
        _open_codex()
    _polish_sidebar_rows()

func _build_collection_teaser() -> void:
    for child in sidebar.get_children():
        sidebar.remove_child(child)
        child.queue_free()
    active_rows.clear()
    _sidebar_card("A NEW DISCOVERY",
        "Trainer victories grant Essence. Hatch a creature with a unique trait and place it in your squad.",
        "HATCH",_codex_hatch,"unique_hatch")
    _sidebar_card("THE FIELD GUIDE",
        "Browse all 12 original creatures across Earth, Water, Fire and Air. Assign unique individuals to one of three slots.",
        "OPEN",_open_codex,"tutorial")
    _sidebar_card("FOUR ELEMENTS",
        "EARTH > WATER > FIRE > AIR > EARTH. Strong counters hit for 2x. A bad matchup deals only 0.45x.",
        "GUIDE",_show_first_steps,"tutorial")

func _open_collection() -> void:
    if not visual_ready:
        super._open_collection()
        return
    for i in range(3):
        if String(game.squad_slots[i]) == "":
            chosen_slot = i
            break
    _open_codex()

func _focus(kind: String) -> void:
    var index: int = CHALLENGE.ORDER.find(kind)
    if index < 0:
        return
    chosen_slot = index
    _open_codex()

func _refresh() -> void:
    super._refresh()
    if not visual_ready or game == null or not game.has_method("collection_count"):
        return
    screen_labels["TrailRank"].text = "CHAPTER %02d / %02d" % [
        mini(game.trail_rank+1,game.COLLECTION_TRAIL.size()),game.COLLECTION_TRAIL.size()]
    screen_labels["PackDps"].text = "%d / 3 UNIQUE ACTIVE" % game.occupied_slots()
    collect_button.text = "FIELD GUIDE  %d/12" % game.collection_count()
    screen_labels["Shards"].text = "%d / %d" % [game.essence,game.hatch_cost()]
    screen_labels["Gold"].text = game.format_number(game.gold)
    screen_labels["Echoes"].text = str(game.echoes)
    for idx in range(3):
        var key: String = String(game.squad_slots[idx])
        var card_key: String = String(CHALLENGE.ORDER[idx])
        var chip: Label = element_chips[idx]
        var halo: Panel = pack_halos[idx]
        var bond_fill: ColorRect = get_node("BondFill_"+str(idx))
        if key != "" and game.has_instance(key):
            var element: String = String(COLLECTION_ENGINE.CATALOG[key]["element"])
            var tint: Color = ELEMENT_COLORS[element]
            chip.text = element.to_upper()
            chip.add_theme_color_override("font_color",tint)
            chip.visible = true
            halo.add_theme_stylebox_override("panel",_glass(tint.darkened(0.73),tint.darkened(0.24),10,1,3))
            var level: int = game.unit_level(key)
            bond_fill.size.x = 132.0*clampf(float(game.unit_bond(key))/25.0,0.0,1.0)
            bond_fill.color = tint
            screen_labels["Name_"+card_key].add_theme_color_override("font_color",tint)
            card_art[card_key].visible = true
            if level >= 15 and game.unit_bond(key) < 25:
                chip.text = "BONDING"
        else:
            chip.text = "UNASSIGNED"
            chip.visible = true
            halo.add_theme_stylebox_override("panel",_glass(Color("#1b323c"),Color("#36515b"),10,1))
            bond_fill.size.x = 0.0
        var unit: Dictionary = game.ally_units[idx]
        var image: TextureRect = ally_widgets[idx]["portrait"]
        if String(unit["kind"]) != "":
            image.position.y = 217+(2.4*sin(animation_clock*1.7+float(idx)))
            image.size.y = 90
            image.visible = true
        var enemy: Dictionary = game.rival_units[idx]
        var rival_image: TextureRect = rival_widgets[idx]["portrait"]
        rival_image.position.y = 217+(2.8*sin(animation_clock*1.3+float(idx)+2.0))
        rival_image.size.y = 90
        var pair: Array = [unit,enemy]
        for n in range(2):
            var member: Dictionary = pair[n]
            var well: Panel = portraits_halos[idx*2+n]
            var element: String = ""
            var kind: String = String(member["kind"])
            if kind != "":
                element = String(COLLECTION_ENGINE.CATALOG[kind]["element"])
            var glow: Color = ELEMENT_COLORS.get(element,Color("#54717b"))
            var alive: bool = float(member["hp"]) > 0.0
            well.add_theme_stylebox_override("panel",_glass(
                Color(glow,0.14 if alive else 0.05),
                Color(glow,0.40 if alive else 0.13),12,1))
    if codex_layer.visible:
        _refresh_codex()

func _build_codex() -> void:
    codex_layer = Control.new()
    codex_layer.name = "FieldGuideOverlay"
    codex_layer.position = Vector2.ZERO
    codex_layer.size = Vector2(1280,720)
    codex_layer.mouse_filter = Control.MOUSE_FILTER_STOP
    codex_layer.visible = false
    add_child(codex_layer)
    var veil := ColorRect.new()
    veil.name = "DimWorld"
    veil.position = Vector2.ZERO
    veil.size = Vector2(1280,720)
    veil.color = Color("#06131d",0.88)
    veil.mouse_filter = Control.MOUSE_FILTER_STOP
    codex_layer.add_child(veil)
    _inside_panel(codex_layer,"CodexBook",Rect2(71,43,1138,633),
        Color("#132f3e"),Color("#9fbf9b"),16,2)
    _inside_label(codex_layer,"CodexBrand","WILDBOUND   /   FIELD GUIDE",
        Rect2(99,62,600,24),14,PALETTE["sage"])
    codex_header = _inside_label(codex_layer,"CodexTitle","YOUR LIVING COLLECTION",
        Rect2(99,86,490,38),29,PALETTE["ink"])
    _inside_label(codex_layer,"CodexSubtitle",
        "Each creature is unique. Discover, raise, evolve, and assign your favorites.",
        Rect2(100,126,560,25),13,PALETTE["muted"])
    codex_egg = _inside_texture(codex_layer,"HatchingEgg",Rect2(666,90,70,76),HATCH_EGG)
    codex_essence = _inside_label(codex_layer,"CodexEssence",
        "ESSENCE  0 / 5",Rect2(746,101,233,28),19,PALETTE["gold"])
    _inside_panel(codex_layer,"HatchRail",Rect2(746,139,209,10),
        Color("#294852"),Color("#466a73"),5)
    codex_progress = _inside_rect(codex_layer,"HatchFill",Rect2(747,141,0,6),PALETTE["sage"])
    codex_hatch = _inside_button(codex_layer,"CodexHatch",
        "HATCH A UNIQUE CREATURE",Rect2(966,103,189,45),_codex_hatch,PALETTE["gold"])
    codex_hatch.add_theme_font_size_override("font_size",12)
    _inside_button(codex_layer,"CodexClose","X",Rect2(1157,59,34,34),_close_codex,PALETTE["muted"])
    codex_status = _inside_label(codex_layer,"CodexNotice","",Rect2(746,154,408,22),11,PALETTE["sage"])

    for col in range(4):
        var element: String = ELEMENT_LIST[col]
        var x: float = 96+float(col)*272
        var tint: Color = ELEMENT_COLORS[element]
        _inside_panel(codex_layer,"ElementHeader_"+element,
            Rect2(x,181,263,31),Color(tint.darkened(0.77),0.96),Color(tint,0.6),9)
        var headline: Label = _inside_label(codex_layer,"ElementLabel_"+element,
            element.to_upper()+"  /  03",Rect2(x+14,186,244,22),14,tint)
        headline.add_theme_font_size_override("font_size",12)
        for row in range(3):
            var key: String = String(COLLECTION_ENGINE.COLLECTION_ORDER[col*3+row])
            var rect: Rect2 = Rect2(x,221+float(row)*124,263,114)
            var card: Panel = _inside_panel(codex_layer,"FieldCard_"+key,rect,
                Color(tint.darkened(0.80),0.79),Color(tint,0.35),12)
            var pic: TextureRect = _inside_texture(codex_layer,"FieldArt_"+key,
                Rect2(rect.position.x+7,rect.position.y+10,83,83),
                COLLECTION_ART.get_creature(key,false))
            _inside_label(codex_layer,"FieldName_"+key,"",Rect2(x+98,rect.position.y+8,155,23),14,PALETTE["ink"])
            _inside_label(codex_layer,"FieldTrait_"+key,"",Rect2(x+98,rect.position.y+31,159,18),10,PALETTE["muted"])
            _inside_label(codex_layer,"FieldStatus_"+key,"",Rect2(x+98,rect.position.y+48,159,17),10,tint)
            var action: Button = _inside_button(codex_layer,"FieldAssign_"+key,
                "UNDISCOVERED",Rect2(x+99,rect.position.y+75,154,30),
                _codex_assign.bind(key),tint)
            action.add_theme_font_size_override("font_size",10)
            codex_cards[key] = {"panel":card,"picture":pic,
                "name":codex_layer.get_node("FieldName_"+key),
                "trait":codex_layer.get_node("FieldTrait_"+key),
                "status":codex_layer.get_node("FieldStatus_"+key),"action":action,
                "tint":tint}

    _inside_label(codex_layer,"SelectSlotPrompt","ASSIGN CREATURE TO",
        Rect2(102,600,210,24),13,PALETTE["muted"])
    for i in range(3):
        var select: Button = _inside_button(codex_layer,"ChooseSlot_"+str(i),
            "SLOT "+str(i+1),Rect2(270+float(i)*122,594,113,36),
            _choose_slot.bind(i),PALETTE["sage"])
        codex_slot_buttons.append(select)
    _inside_label(codex_layer,"CollectionFooter",
        "EARTH  >  WATER  >  FIRE  >  AIR  >  EARTH   •   2x strong  /  0.45x resisted",
        Rect2(650,599,519,33),12,PALETTE["muted"])

func _inside_panel(parent: Node,name: String,rect: Rect2,fill: Color,
    edge: Color,radius: int = 10,stroke: int = 1) -> Panel:
    var panel := Panel.new()
    panel.name = name
    panel.position = rect.position
    panel.size = rect.size
    panel.add_theme_stylebox_override("panel",_glass(fill,edge,radius,stroke,3))
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(panel)
    return panel

func _inside_label(parent: Node,name: String,title: String,rect: Rect2,
    font_size: int,color: Color) -> Label:
    var label := Label.new()
    label.name = name
    label.position = rect.position
    label.size = rect.size
    label.text = title
    label.clip_text = true
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_color_override("font_color",color)
    label.add_theme_font_size_override("font_size",font_size)
    parent.add_child(label)
    return label

func _inside_texture(parent: Node,name: String,rect: Rect2,texture: Texture2D) -> TextureRect:
    var img := TextureRect.new()
    img.name = name
    img.position = rect.position
    img.size = rect.size
    img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    img.texture = texture
    img.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(img)
    return img

func _inside_rect(parent: Node,name: String,rect: Rect2,fill: Color) -> ColorRect:
    var panel := ColorRect.new()
    panel.name = name
    panel.position = rect.position
    panel.size = rect.size
    panel.color = fill
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(panel)
    return panel

func _inside_button(parent: Node,name: String,title: String,rect: Rect2,
    callback: Callable,edge: Color) -> Button:
    var button := Button.new()
    button.name = name
    button.text = title
    button.position = rect.position
    button.size = rect.size
    parent.add_child(button)
    _skin_button(button,edge,true)
    button.pressed.connect(callback)
    return button

func _open_codex() -> void:
    if not visual_ready:
        return
    if codex_layer.visible:
        _refresh_codex()
        return
    prev_playing = playing
    playing = false
    codex_layer.show()
    _refresh_codex()

func _close_codex() -> void:
    codex_layer.hide()
    playing = prev_playing
    _refresh()

func _choose_slot(index: int) -> void:
    chosen_slot = index
    _refresh_codex()

func _codex_assign(kind: String) -> void:
    if not game.has_instance(kind):
        return
    if game.assign_creature(chosen_slot,kind):
        _toast("%s JOINED SQUAD SLOT %d" % [
            String(COLLECTION_ENGINE.CATALOG[kind]["name"]),chosen_slot+1])
        codex_status.text = "%s joins the active team. Your squad has been reformed." % [
            String(COLLECTION_ENGINE.CATALOG[kind]["name"])]
        game.save()
    _refresh_codex()
    _refresh()

func _codex_hatch() -> void:
    if game.essence < game.hatch_cost():
        return
    var kind: String = game.hatch_egg()
    if kind == "":
        return
    _toast("NEW DISCOVERY!  "+String(COLLECTION_ENGINE.CATALOG[kind]["name"]))
    codex_status.text = "DISCOVERED  •  %s  •  %s TRAIT" % [
        String(COLLECTION_ENGINE.CATALOG[kind]["name"]),game.unit_trait(kind).to_upper()]
    for i in range(3):
        if String(game.squad_slots[i]) == "":
            chosen_slot = i
            break
    if not codex_layer.visible:
        _open_codex()
    _refresh_codex()
    game.save()
    _refresh()

func _refresh_codex() -> void:
    if not is_instance_valid(codex_layer):
        return
    codex_header.text = "YOUR LIVING COLLECTION  %02d / 12" % game.collection_count()
    var cost: int = game.hatch_cost()
    codex_essence.text = "ESSENCE  %d / %d" % [game.essence,cost]
    codex_progress.size.x = 206.0*clampf(float(game.essence)/maxf(1.0,float(cost)),0.0,1.0)
    codex_hatch.text = "HATCH  •  %d ESSENCE" % cost
    codex_hatch.disabled = game.essence < cost or game.collection_count() >= 12
    if codex_status.text == "":
        codex_status.text = "Win trainer battles to earn Essence. Every egg reveals a NEW species."
    for i in range(codex_slot_buttons.size()):
        var button: Button = codex_slot_buttons[i]
        var selected: bool = chosen_slot == i
        var tint: Color = PALETTE["gold"] if selected else Color("#4d8490")
        _skin_button(button,tint,selected)
        button.text = "SLOT %d  %s" % [i+1,"◆" if selected else "·"]
    for key in codex_cards:
        var entry: Dictionary = codex_cards[key]
        var owned: bool = game.has_instance(String(key))
        var tint: Color = entry["tint"]
        var action: Button = entry["action"]
        var card: Panel = entry["panel"]
        var artwork: TextureRect = entry["picture"]
        var name: Label = entry["name"]
        var trait_label: Label = entry["trait"]
        var status: Label = entry["status"]
        if owned:
            var item: Dictionary = game.unit_record(String(key))
            var slot: int = game.squad_slots.find(String(key))
            card.add_theme_stylebox_override("panel",_glass(
                Color(tint.darkened(0.75),0.91),Color(tint,0.55),12,1))
            artwork.texture = COLLECTION_ART.get_creature(String(key),bool(item["evolved"]))
            artwork.modulate = Color.WHITE
            name.text = String(COLLECTION_ENGINE.CATALOG[key]["evolved"] if bool(item["evolved"]) else COLLECTION_ENGINE.CATALOG[key]["name"])
            trait_label.text = "%s TRAIT  •  LV %d" % [String(item["trait"]).to_upper(),int(item["level"])]
            status.text = "IN SQUAD • SLOT %d" % (slot+1) if slot >= 0 else "READY TO JOIN"
            action.disabled = slot == chosen_slot
            action.text = "SELECTED" if slot == chosen_slot else ("MOVE HERE" if slot >= 0 else "ASSIGN TO SLOT %d" % (chosen_slot+1))
        else:
            card.add_theme_stylebox_override("panel",_glass(
                Color("#142d38"),Color("#33525b"),12,1))
            artwork.texture = COLLECTION_ART.get_creature(String(key),false)
            artwork.modulate = Color("#365360",0.47)
            name.text = "???  •  UNDISCOVERED"
            trait_label.text = String(COLLECTION_ENGINE.CATALOG[key]["element"]).to_upper()+"  •  UNKNOWN TRAITS"
            status.text = "WAITING IN THE WILDS"
            action.disabled = true
            action.text = "NOT YET HATCHED"
