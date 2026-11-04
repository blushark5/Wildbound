extends Control
## Wildbound v0.30 — purpose-built 1v1 creature clicker, not a reskin of the 3v3 interface.
## Only original painted Cindlet / Brinlet / Spriglet art is used.
const DUEL = preload("res://scripts/duel/duel_engine_v30.gd")
const SPRITES = preload("res://scripts/incremental/sprite_frames_v14.gd")
const LANDSCAPE = preload("res://assets/duel/duel_valley_v30.svg")
const COIN = preload("res://assets/incremental/v13/gold.svg")
const ECHO = preload("res://assets/incremental/v13/echo.svg")
const FIRE_MARK = preload("res://assets/incremental/v20/icon_fire.svg")
const WATER_MARK = preload("res://assets/incremental/v20/icon_water.svg")
const EARTH_MARK = preload("res://assets/incremental/v20/icon_earth.svg")
const COLORS: Dictionary = {
    "Fire":Color("#ffac72"),"Water":Color("#79d6f2"),"Earth":Color("#a9df96")
}
const GOLD: Color = Color("#f4ca70")
const PEARL: Color = Color("#f7f4df")
const SEA: Color = Color("#8ed2c4")
const DARK: Color = Color("#0b2c3d")

var game
var ui_live: bool = false
var refresh_timer: float = 0.0
var bob_clock: float = 0.0

var roster_rows: Dictionary = {}
var gold_text: Label
var echo_text: Label
var progress_text: Label
var stage_title: Label
var stage_subtitle: Label
var enemy_art: TextureRect
var hero_art: TextureRect
var enemy_name: Label
var enemy_element: Label
var hero_name: Label
var hero_element: Label
var enemy_hp_bar: ColorRect
var hero_hp_bar: ColorRect
var enemy_hp_text: Label
var hero_hp_text: Label
var power_text: Label
var notice_text: Label
var next_button: Button
var farm_button: Button
var menu_button: Button
var enemy_hit_button: Button
var numbers: Label
var menu_root: Control
var menu_content: Control
var menu_heading: Label
var menu_active: bool = false
var menu_page: String = "HOME"
var upgrade_buttons: Dictionary = {}
var ascent_button: Button
var ascent_body: Label
var save_body: Label
var confirm_new: ConfirmationDialog
var landscape: TextureRect
var rival_frame: Panel
var battle_header: Panel

func _ready() -> void:
    game = DUEL.new()
    game.load()
    game.changed.connect(_on_game_notice)
    _build_screen()
    _build_menu()
    _build_confirmation()
    ui_live = true
    _refresh()
    set_process(true)

func _style(fill: Color,edge: Color,radius: int = 14,border: int = 1,depth: int = 3) -> StyleBoxFlat:
    var result := StyleBoxFlat.new()
    result.bg_color = fill
    result.border_color = edge
    result.set_border_width_all(border)
    result.set_corner_radius_all(radius)
    result.content_margin_left = 9.0
    result.content_margin_right = 9.0
    result.content_margin_top = 6.0
    result.content_margin_bottom = 6.0
    result.shadow_color = Color("#020d16",0.50)
    result.shadow_size = depth
    result.shadow_offset = Vector2(0,2)
    return result

func _panel(parent: Control,name: String,rect: Rect2,
        fill: Color,edge: Color,radius: int = 14,border: int = 1) -> Panel:
    var panel := Panel.new()
    panel.name = name
    panel.position = rect.position
    panel.size = rect.size
    panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
    panel.add_theme_stylebox_override("panel",_style(fill,edge,radius,border))
    parent.add_child(panel)
    return panel

func _text(parent: Control,name: String,caption: String,rect: Rect2,
        size: int = 16,tint: Color = PEARL,align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
    var label := Label.new()
    label.name = name
    label.text = caption
    label.position = rect.position
    label.size = rect.size
    label.clip_text = true
    label.horizontal_alignment = align
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    label.add_theme_font_size_override("font_size",size)
    label.add_theme_color_override("font_color",tint)
    parent.add_child(label)
    return label

func _art(parent: Control,name: String,texture: Texture2D,rect: Rect2) -> TextureRect:
    var art := TextureRect.new()
    art.name = name
    art.position = rect.position
    art.size = rect.size
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    art.texture = texture
    parent.add_child(art)
    return art

func _button(parent: Control,name: String,caption: String,rect: Rect2,
        callback: Callable,accent: bool = false) -> Button:
    var item := Button.new()
    item.name = name
    item.text = caption
    item.position = rect.position
    item.size = rect.size
    item.focus_mode = Control.FOCUS_NONE
    var color: Color = Color("#926226") if accent else Color("#204b59")
    var trim: Color = GOLD if accent else SEA
    item.add_theme_stylebox_override("normal",_style(color,trim,11,2 if accent else 1,4))
    item.add_theme_stylebox_override("hover",_style(color.lightened(0.19),trim.lightened(0.2),11,2,5))
    item.add_theme_stylebox_override("pressed",_style(color.darkened(0.22),trim,11,2,1))
    item.add_theme_stylebox_override("disabled",_style(Color("#243c43"),Color("#4f6770"),11,1,0))
    item.add_theme_color_override("font_color",PEARL)
    item.add_theme_color_override("font_hover_color",Color.WHITE)
    item.add_theme_color_override("font_disabled_color",Color("#859ba3"))
    item.add_theme_font_size_override("font_size",17 if accent else 14)
    item.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    parent.add_child(item)
    item.pressed.connect(callback)
    return item

func _build_screen() -> void:
    var canvas := ColorRect.new()
    canvas.name = "Backdrop"
    canvas.color = Color("#081d2e")
    canvas.position = Vector2.ZERO
    canvas.size = Vector2(1280,720)
    canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(canvas)

    # Stage illustration fills the battlefield. Hand-authored original SVG,
    # unlike the previous small and flat icon-strip combat.
    landscape = _art(self,"ValleyBackdrop",LANDSCAPE,Rect2(401,92,864,529))
    landscape.stretch_mode = TextureRect.STRETCH_SCALE

    _panel(self,"MainHeader",Rect2(12,11,1255,80),
        Color("#082d3b",0.98),Color("#80b6aa",0.8),15)
    _text(self,"Logo","WILDBOUND",Rect2(34,18,351,39),34,PEARL)
    _text(self,"Tagline","CREATURES  •  ELEMENTS  •  ASCENSION",
        Rect2(38,60,354,19),10,SEA)
    _panel(self,"GoldChip",Rect2(520,24,222,52),
        Color("#203f45"),Color("#d6b573",0.77),12)
    _art(self,"GoldCoin",COIN,Rect2(531,35,30,29))
    gold_text = _text(self,"GoldBalance","",Rect2(567,33,166,33),21,GOLD)
    _panel(self,"EchoChip",Rect2(750,24,130,52),
        Color("#20354d"),Color("#a59bd3",0.78),12)
    _art(self,"EchoCrystal",ECHO,Rect2(762,35,30,29))
    echo_text = _text(self,"EchoBalance","",Rect2(799,34,75,32),20,PEARL)
    _panel(self,"ProgressChip",Rect2(887,24,229,52),
        Color("#163744"),Color("#89bcae",0.70),12)
    progress_text = _text(self,"ProgressLabel","",
        Rect2(899,32,208,34),16,PEARL,HORIZONTAL_ALIGNMENT_CENTER)
    menu_button = _button(self,"MainMenu","☰  MENU",Rect2(1126,24,130,52),
        _toggle_menu,true)
    menu_button.add_theme_font_size_override("font_size",16)

    # The entire left column is the creature roster. Exactly 3 species.
    _panel(self,"TrainingPanel",Rect2(18,107,376,587),
        Color("#0b2d3d",0.98),Color("#8dcdba",0.79),21)
    _text(self,"TrainingTitle","CREATURE TRAINING",
        Rect2(42,127,324,36),24,PEARL)
    _text(self,"TrainingDescription","Deploy one creature. Level any with Gold.",
        Rect2(42,165,326,23),12,Color("#acd2c2"))
    for i in range(DUEL.ORDER.size()):
        var kind: String = DUEL.ORDER[i]
        var y: float = 199.0+float(i)*123.0
        var shell := _panel(self,"RosterCard_"+kind,Rect2(33,y,345,115),
            Color("#143b4c"),Color("#698f99",0.75),15)
        var edge: Panel = _panel(self,"RosterArtBg_"+kind,Rect2(43,y+12,95,90),
            Color("#1b5261"),COLORS[DUEL.SPECIES[kind]["element"]],12)
        var photo: TextureRect = _art(self,"RosterArt_"+kind,
            SPRITES.creature(kind,false),Rect2(45,y+11,91,90))
        var elemental: Texture2D = (FIRE_MARK if kind == "cindlet"
            else WATER_MARK if kind == "brinlet" else EARTH_MARK)
        _art(self,"ElementIcon_"+kind,elemental,Rect2(347,y+13,23,23))
        var name: Label = _text(self,"RosterName_"+kind,"",
            Rect2(146,y+11,224,29),18,PEARL)
        var info: Label = _text(self,"RosterInfo_"+kind,"",
            Rect2(146,y+39,214,25),13,SEA)
        var choose: Button = _button(self,"Deploy_"+kind,"DEPLOY",
            Rect2(145,y+76,97,29),_choose.bind(kind))
        choose.add_theme_font_size_override("font_size",12)
        var spend: Button = _button(self,"Level_"+kind,"LEVEL UP",
            Rect2(251,y+69,116,38),_train.bind(kind),true)
        spend.add_theme_font_size_override("font_size",13)
        roster_rows[kind] = {"shell":shell,"frame":edge,"image":photo,"name":name,
            "info":info,"choose":choose,"spend":spend}
    _panel(self,"ElementGuide",Rect2(35,578,341,101),
        Color("#0b2637",0.97),Color("#688c85",0.68),12)
    _text(self,"ElementGuideTitle","ELEMENT ADVANTAGE",
        Rect2(50,588,314,25),15,GOLD)
    _text(self,"ElementGuide1","FIRE  >  EARTH  >  WATER  >  FIRE",
        Rect2(49,619,308,24),16,PEARL,HORIZONTAL_ALIGNMENT_CENTER)
    _text(self,"ElementGuide2","Strong attacks deal 2× damage.",
        Rect2(49,647,308,20),12,SEA,HORIZONTAL_ALIGNMENT_CENTER)

    # Single enemy occupies the right-center of the screen. The one active
    # ally has a smaller but still expressive character presentation.
    rival_frame = _panel(self,"DuelWindow",Rect2(412,109,835,503),
        Color("#083044",0.045),Color("#a1c8b8",0.83),19)
    battle_header = _panel(self,"StageTitlePlate",Rect2(699,119,232,60),
        Color("#0a303d",0.94),GOLD,14,2)
    stage_title = _text(self,"StageTitle","",
        Rect2(709,125,210,27),23,PEARL,HORIZONTAL_ALIGNMENT_CENTER)
    stage_subtitle = _text(self,"StageDetail","",
        Rect2(709,151,210,21),11,SEA,HORIZONTAL_ALIGNMENT_CENTER)
    _panel(self,"HeroAura",Rect2(474,302,162,147),
        Color("#0c3041",0.17),Color("#79bdc1",0.26),78)
    hero_art = _art(self,"YourCreature",SPRITES.creature("spriglet",false),
        Rect2(480,305,147,148))
    hero_art.pivot_offset = hero_art.size*0.5
    _panel(self,"RivalAura",Rect2(724,196,345,266),
        Color("#184b4a",0.16),Color("#b5d3c2",0.24),120)
    enemy_art = _art(self,"EnemyCreature",SPRITES.creature("cindlet",false),
        Rect2(755,192,285,269))
    enemy_art.pivot_offset = enemy_art.size*0.5

    enemy_hit_button = Button.new()
    enemy_hit_button.name = "TapEnemyAssist"
    enemy_hit_button.flat = true
    enemy_hit_button.text = ""
    enemy_hit_button.position = Vector2(740,205)
    enemy_hit_button.size = Vector2(321,252)
    enemy_hit_button.focus_mode = Control.FOCUS_NONE
    enemy_hit_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
    enemy_hit_button.tooltip_text = "Click enemy to help your creature attack."
    add_child(enemy_hit_button)
    enemy_hit_button.pressed.connect(_manual_hit)

    hero_name = _text(self,"ActiveName","",
        Rect2(469,449,173,25),17,PEARL,HORIZONTAL_ALIGNMENT_CENTER)
    hero_element = _text(self,"ActiveElement","",
        Rect2(468,475,175,18),12,SEA,HORIZONTAL_ALIGNMENT_CENTER)
    enemy_name = _text(self,"RivalName","",
        Rect2(763,445,269,29),22,PEARL,HORIZONTAL_ALIGNMENT_CENTER)
    enemy_element = _text(self,"RivalElement","",
        Rect2(763,474,267,19),12,GOLD,HORIZONTAL_ALIGNMENT_CENTER)
    _panel(self,"EnemyHealthBg",Rect2(705,512,405,30),
        Color("#133646",0.96),Color("#e4aa8e",0.81),11)
    enemy_hp_bar = ColorRect.new()
    enemy_hp_bar.name = "RivalHealthFill"
    enemy_hp_bar.position = Vector2(709,516)
    enemy_hp_bar.size = Vector2(397,22)
    enemy_hp_bar.color = Color("#dc6655")
    enemy_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(enemy_hp_bar)
    enemy_hp_text = _text(self,"RivalHealthText","",
        Rect2(711,513,392,27),14,PEARL,HORIZONTAL_ALIGNMENT_CENTER)
    _panel(self,"HeroHealthBg",Rect2(477,513,185,29),
        Color("#143b43",0.96),Color("#7cbaa1",0.84),11)
    hero_hp_bar = ColorRect.new()
    hero_hp_bar.name = "HeroHealthFill"
    hero_hp_bar.position = Vector2(481,517)
    hero_hp_bar.size = Vector2(177,21)
    hero_hp_bar.color = Color("#79cea5")
    hero_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(hero_hp_bar)
    hero_hp_text = _text(self,"HeroHealthText","",
        Rect2(484,514,172,25),12,PEARL,HORIZONTAL_ALIGNMENT_CENTER)
    _panel(self,"InfoStrip",Rect2(438,551,668,50),
        Color("#0b2f3b",0.95),Color("#81bdad",0.83),11)
    power_text = _text(self,"CombatInfo","",
        Rect2(454,556,632,24),14,PEARL,HORIZONTAL_ALIGNMENT_CENTER)
    notice_text = _text(self,"BattleNotice","",
        Rect2(454,578,632,18),11,SEA,HORIZONTAL_ALIGNMENT_CENTER)
    numbers = _text(self,"DamagePop","",
        Rect2(770,218,225,44),25,Color("#fff3ad"),HORIZONTAL_ALIGNMENT_CENTER)
    numbers.visible = false

    next_button = _button(self,"MainBattleAction","▶  START BATTLE",
        Rect2(432,632,515,59),_primary_action,true)
    next_button.add_theme_font_size_override("font_size",24)
    next_button.add_theme_stylebox_override("normal",
        _style(Color("#9d402b"),Color("#ffe1a3"),13,3,7))
    next_button.add_theme_stylebox_override("hover",
        _style(Color("#c05232"),Color("#fff0ba"),13,3,8))
    next_button.add_theme_stylebox_override("pressed",
        _style(Color("#7d3329"),Color("#f4bb6a"),13,3,3))
    farm_button = _button(self,"FarmGold","FARM GOLD",
        Rect2(960,632,273,59),_farm)
    farm_button.add_theme_font_size_override("font_size",18)
    farm_button.add_theme_stylebox_override("normal",_style(Color("#795a23"),GOLD,12,2,5))
    farm_button.add_theme_stylebox_override("hover",_style(Color("#a17930"),GOLD,12,2,6))
    farm_button.tooltip_text = "Replay a cleared stage for Gold and Bond XP."
    _text(self,"FooterHelp","Click the enemy to help attack • creatures fight automatically",
        Rect2(445,610,740,20),11,SEA,HORIZONTAL_ALIGNMENT_CENTER)

func _build_menu() -> void:
    menu_root = Control.new()
    menu_root.name = "MenuDrawer"
    menu_root.position = Vector2.ZERO
    menu_root.size = Vector2(1280,720)
    menu_root.z_index = 12
    menu_root.visible = false
    add_child(menu_root)
    var shade := ColorRect.new()
    shade.name = "MenuDimmer"
    shade.position = Vector2(0,89)
    shade.size = Vector2(1280,631)
    shade.color = Color("#04131e",0.55)
    shade.mouse_filter = Control.MOUSE_FILTER_STOP
    menu_root.add_child(shade)
    var hide_shade := Button.new()
    hide_shade.name = "DismissArea"
    hide_shade.flat = true
    hide_shade.position = Vector2(0,90)
    hide_shade.size = Vector2(830,630)
    menu_root.add_child(hide_shade)
    hide_shade.pressed.connect(_close_menu)
    _panel(menu_root,"DrawerBackground",Rect2(835,102,430,601),
        Color("#102b3b",0.99),Color("#b4b98b",0.9),18,2)
    menu_heading = _text(menu_root,"DrawerHeading","MENU",
        Rect2(863,130,260,37),25,PEARL)
    _button(menu_root,"MenuBack","‹ BACK",Rect2(1019,130,118,40),_menu_back)
    _button(menu_root,"MenuClose","✕",Rect2(1151,130,84,40),_close_menu)
    menu_content = Control.new()
    menu_content.name = "DrawerContent"
    menu_content.position = Vector2(847,190)
    menu_content.size = Vector2(401,492)
    menu_root.add_child(menu_content)
    _fill_menu("HOME")

func _fill_menu(page: String) -> void:
    menu_page = page
    for child in menu_content.get_children():
        menu_content.remove_child(child)
        child.queue_free()
    upgrade_buttons.clear()
    menu_heading.text = {"HOME":"GAME MENU","UPGRADES":"GOLD UPGRADES",
        "ASCEND":"ASCENSION","SAVE":"SAVE & SETTINGS"}.get(page,"MENU")
    if page == "HOME":
        _text(menu_content,"MenuIntro","The important things, all in one place.",
            Rect2(16,4,362,32),14,SEA)
        _button(menu_content,"GoUpgrades","GOLD UPGRADES",
            Rect2(18,65,355,74),_fill_menu.bind("UPGRADES"),true)
        _text(menu_content,"UpgradesDesc","Improve all three creatures with Gold.",
            Rect2(24,141,340,25),13,SEA)
        _button(menu_content,"GoAscend","ASCENSION",
            Rect2(18,189,355,74),_fill_menu.bind("ASCEND"))
        _text(menu_content,"AscendDesc","Reset the run for permanent Bond ranks.",
            Rect2(24,264,340,25),13,SEA)
        _button(menu_content,"GoSave","SAVE & NEW GAME",
            Rect2(18,315,355,74),_fill_menu.bind("SAVE"))
        _text(menu_content,"SaveDesc","Your progress saves automatically.",
            Rect2(24,390,340,25),13,SEA)
    elif page == "UPGRADES":
        _text(menu_content,"GoldHelp","Gold upgrades strengthen every creature.",
            Rect2(16,6,370,35),14,SEA)
        for i in range(DUEL.UPGRADES.size()):
            var key: String = String(DUEL.UPGRADES[i])
            var y: float = 58+float(i)*129
            _panel(menu_content,"UpgradeRow_"+key,
                Rect2(15,y,370,117),Color("#1a3c48"),Color("#77a7a3",0.78),13)
            _text(menu_content,"UpgradeName_"+key,String(DUEL.UPGRADE_NAMES[key]),
                Rect2(31,y+10,220,25),19,GOLD)
            _text(menu_content,"UpgradeHelp_"+key,String(DUEL.UPGRADE_HELP[key]),
                Rect2(31,y+39,338,24),12,SEA)
            upgrade_buttons[key] = _button(menu_content,"Buy_"+key,"",
                Rect2(190,y+72,176,36),_upgrade.bind(key),true)
            _text(menu_content,"UpgradeRank_"+key,
                "",Rect2(30,y+75,155,28),14,PEARL)
        _text(menu_content,"UpgradeFooter","These reset on Ascension. Bond ranks do not.",
            Rect2(25,455,364,26),12,SEA,HORIZONTAL_ALIGNMENT_CENTER)
    elif page == "ASCEND":
        _text(menu_content,"AscendTitle","ASCENSION • STAGE 20",
            Rect2(18,30,355,35),21,GOLD,HORIZONTAL_ALIGNMENT_CENTER)
        ascent_body = _text(menu_content,"AscendBody","",
            Rect2(28,95,345,176),15,PEARL,HORIZONTAL_ALIGNMENT_CENTER)
        ascent_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        ascent_body.clip_text = false
        ascent_button = _button(menu_content,"AscendNow","ASCEND",
            Rect2(22,299,350,67),_ascend,true)
        _text(menu_content,"AscendHint",
            "Your three creatures and evolutions stay yours.",
            Rect2(18,398,370,45),13,SEA,HORIZONTAL_ALIGNMENT_CENTER)
    elif page == "SAVE":
        save_body = _text(menu_content,"SaveDetails","",
            Rect2(24,28,347,115),15,PEARL)
        save_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        _button(menu_content,"SaveNow","SAVE PROGRESS",
            Rect2(19,180,356,63),_manual_save,true)
        _button(menu_content,"ResetAll","NEW GAME (RESET)",
            Rect2(19,293,356,63),_ask_reset)
        _text(menu_content,"SaveWarn",
            "A new game resets this three-creature run.\nThe previous v0.29 save is untouched.",
            Rect2(20,366,358,71),13,SEA,HORIZONTAL_ALIGNMENT_CENTER)

func _build_confirmation() -> void:
    confirm_new = ConfirmationDialog.new()
    confirm_new.title = "Start a new Wildbound adventure?"
    confirm_new.dialog_text = "This resets the simplified 1v1 save. Your previous version remains separate."
    confirm_new.ok_button_text = "START NEW GAME"
    add_child(confirm_new)
    confirm_new.confirmed.connect(_new_game)

func _toggle_menu() -> void:
    if menu_active:
        _close_menu()
    else:
        _open_menu("HOME")

func _open_menu(page: String = "HOME") -> void:
    menu_active = true
    menu_root.show()
    _fill_menu(page)
    _refresh_menu()

func _close_menu() -> void:
    menu_active = false
    menu_root.hide()

func _menu_back() -> void:
    if menu_page != "HOME":
        _fill_menu("HOME")
    else:
        _close_menu()

func _choose(kind: String) -> void:
    if game.select_creature(kind):
        _refresh()

func _train(kind: String) -> void:
    if game.level_up(kind):
        _refresh()

func _manual_hit() -> void:
    if game.fighting:
        game.hit(true)
        _refresh()

func _primary_action() -> void:
    if not game.battle_started or game.defeated:
        game.start()
    elif game.awaiting_next and not game.farming:
        game.next_stage()
    elif game.fighting:
        game.hit(true)
    _refresh()

func _farm() -> void:
    game.toggle_farm()
    _refresh()

func _upgrade(kind: String) -> void:
    game.buy_upgrade(kind)
    _refresh_menu()
    _refresh()

func _ascend() -> void:
    if game.ascend():
        _close_menu()
        _refresh()

func _manual_save() -> void:
    game.save()
    game.last_notice = "GAME SAVED • YOUR PROGRESS IS LOCAL TO THIS BROWSER"
    _refresh()

func _ask_reset() -> void:
    confirm_new.popup_centered()

func _new_game() -> void:
    game.new_game()
    _close_menu()
    _refresh()

func _on_game_notice(_message: String) -> void:
    if ui_live:
        _refresh()

func _refresh() -> void:
    if not ui_live:
        return
    gold_text.text = game.format_number(game.gold)
    echo_text.text = str(game.echo)
    progress_text.text = "STAGE %d  •  BEST %d" % [game.stage,game.best_stage]
    stage_title.text = "STAGE  %d" % game.stage
    stage_subtitle.text = (
        "GUARDIAN BATTLE" if game.is_boss() else
        "GOLD FARMING" if game.farming else "1 VS 1 • ELEMENTAL DUEL")

    for kind in DUEL.ORDER:
        var row: Dictionary = roster_rows[kind]
        var edge: Color = COLORS[game.element(kind)]
        var selected: bool = kind == game.active
        var card: Panel = row["shell"]
        card.add_theme_stylebox_override("panel",
            _style(Color("#205563") if selected else Color("#123747"),
                GOLD if selected else Color(edge,0.70),15,2 if selected else 1,4))
        var name: Label = row["name"]
        name.text = game.display_name(kind)
        name.add_theme_color_override("font_color",edge if selected else PEARL)
        var info: Label = row["info"]
        info.text = "LV %d/%d  •  DPS %s" % [int(game.levels[kind]),
            game.level_cap(kind),game.format_number(game.dps(kind))]
        var photo: TextureRect = row["image"]
        photo.texture = SPRITES.creature(kind,bool(game.evolved[kind]))
        var choose: Button = row["choose"]
        choose.text = "ACTIVE" if selected else "SWITCH"
        choose.disabled = selected or game.switch_cooldown > 0.0
        var spend: Button = row["spend"]
        var cost: float = game.level_cost(kind)
        spend.text = "BOND CAP" if cost == INF else ("LV UP • %s G" % game.format_number(cost))
        spend.disabled = cost == INF or game.gold < cost

    hero_art.texture = SPRITES.creature(game.active,bool(game.evolved[game.active]),game.fighting and game.hero_clock < 0.16)
    enemy_art.texture = SPRITES.creature(game.opponent,game.is_boss(),game.impact_flash > 0.0)
    enemy_art.modulate = (Color("#f9dec8") if game.impact_flash > 0.0
        else Color("#9caab0",0.74) if game.awaiting_next and not game.defeated
        else Color.WHITE)
    hero_name.text = game.display_name(game.active)
    enemy_name.text = game.display_name(game.opponent)
    hero_element.text = "%s • LV %d" % [game.element(game.active).to_upper(),int(game.levels[game.active])]
    enemy_element.text = "%s • %s" % [
        game.element(game.opponent).to_upper(),"GUARDIAN" if game.is_boss() else "RIVAL"]
    hero_element.add_theme_color_override("font_color",COLORS[game.element(game.active)])
    enemy_element.add_theme_color_override("font_color",COLORS[game.element(game.opponent)])
    enemy_hp_bar.size.x = 397.0*clampf(game.enemy_hp/maxf(1.0,game.enemy_max_hp),0.0,1.0)
    hero_hp_bar.size.x = 177.0*clampf(game.hero_hp/maxf(1.0,game.hero_max_hp),0.0,1.0)
    enemy_hp_text.text = "%s / %s HP" % [game.format_number(game.enemy_hp),game.format_number(game.enemy_max_hp)]
    hero_hp_text.text = "%s / %s" % [game.format_number(game.hero_hp),game.format_number(game.hero_max_hp)]
    var bonus: float = game.matchup(game.active,game.opponent)
    power_text.text = "YOUR DPS  %s     •     ELEMENTAL DAMAGE  %s×" % [
        game.format_number(game.dps(game.active)),str(bonus)]
    notice_text.text = game.last_notice
    if not game.battle_started:
        next_button.text = "▶  START BATTLE"
    elif game.defeated:
        next_button.text = "↻  RETRY BATTLE"
    elif game.awaiting_next and not game.farming:
        next_button.text = "⚔  NEXT STAGE"
    elif game.farming:
        next_button.text = "⚔  ASSIST ATTACK" if game.fighting else "AUTO FARMING..."
    else:
        next_button.text = "⚔  HELP ATTACK"
    next_button.disabled = game.farming and not game.fighting
    farm_button.visible = game.best_stage >= 1
    farm_button.text = "RETURN TO PUSH" if game.farming else "↻  FARM GOLD"
    if menu_active:
        _refresh_menu()

func _refresh_menu() -> void:
    if not menu_active:
        return
    if menu_page == "UPGRADES":
        for kind in upgrade_buttons:
            var item: Button = upgrade_buttons[kind]
            var cost: float = game.upgrade_cost(kind)
            item.text = "BUY • %s G" % game.format_number(cost)
            item.disabled = game.gold < cost
            var name: Label = menu_content.get_node("UpgradeRank_"+kind)
            name.text = "RANK %d" % int(game.upgrades[kind])
    elif menu_page == "ASCEND" and is_instance_valid(ascent_body):
        ascent_body.text = ("Ready to Ascend!\nGain +1 Echo, raise eligible Bond ranks,\nand restart stronger."
            if game.can_ascend() else
            "Reach and clear Stage 20 to Ascend.\n\nCurrent best stage: %d\nAscensions completed: %d" % [
                game.best_stage,game.ascensions])
        ascent_button.disabled = not game.can_ascend()
    elif menu_page == "SAVE" and is_instance_valid(save_body):
        save_body.text = ("Stage %d  •  Best %d\nGold %s  •  Ascensions %d\n\nYour progress saves automatically."
            % [game.stage,game.best_stage,game.format_number(game.gold),game.ascensions])

func _process(delta: float) -> void:
    if not ui_live:
        return
    game.tick(delta)
    bob_clock += delta
    hero_art.position.y = 305.0+sin(bob_clock*2.0)*3.0
    enemy_art.position.y = 192.0+sin(bob_clock*1.6+0.7)*4.0
    refresh_timer += delta
    if refresh_timer >= 0.08:
        refresh_timer = 0.0
        _refresh()
    if game.impact_flash > 0.0 and game.fighting:
        numbers.text = "-"+game.format_number(game.last_hit)
        numbers.visible = true
        numbers.modulate.a = game.impact_flash/0.18
        numbers.position.y = 214.0-game.impact_flash*70.0
    else:
        numbers.visible = false

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE:
            _toggle_menu()
        elif event.keycode == KEY_SPACE and not menu_active:
            _primary_action()
