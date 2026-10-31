extends Control
## Wildbound idle prototype. No overworld; creatures, waves and research are the game.
const ENGINE = preload("res://scripts/incremental/engine.gd")
const DARK := Color("#101b2b")
const PANEL := Color("#1b3044")
const PANEL_ALT := Color("#203d4e")
const PAPER := Color("#f8eacb")
const MINT := Color("#80e2bb")
const GOLD := Color("#f4c96b")
const MUTED := Color("#a9bed0")
var game
var labels: Dictionary = {}
var buttons: Dictionary = {}
var portraits: Dictionary = {}
var enemy_portrait: TextureRect
var enemy_bar: ColorRect
var ward_bar: ColorRect
var running: bool = true
var buy_batch: int = 1
var ui_clock: float = 0.0
var save_clock: float = 0.0

func _ready() -> void:
    game = ENGINE.new()
    game.load_save()
    game.notice.connect(_on_notice)
    _build_interface()
    _refresh()

func _process(delta: float) -> void:
    if running:
        game.tick(delta)
    ui_clock += delta
    save_clock += delta
    if ui_clock >= 0.13:
        ui_clock = 0.0
        _refresh()
    if save_clock >= 20.0:
        save_clock = 0.0
        game.save()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST and game != null:
        game.save()

func _make_panel(where: Rect2, fill: Color = PANEL) -> Panel:
    var panel := Panel.new()
    panel.position = where.position
    panel.size = where.size
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = Color("#42677c")
    style.set_border_width_all(2)
    style.set_corner_radius_all(10)
    panel.add_theme_stylebox_override("panel",style)
    add_child(panel)
    return panel

func _make_label(id: String, words: String, at: Rect2, font_size: int = 17, ink: Color = PAPER) -> Label:
    var label := Label.new()
    label.name = id
    label.text = words
    label.position = at.position
    label.size = at.size
    label.add_theme_font_size_override("font_size",font_size)
    label.add_theme_color_override("font_color",ink)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(label)
    labels[id] = label
    return label

func _make_button(id: String, title: String, at: Rect2, action: Callable, color: Color = Color("#285d62")) -> Button:
    var button := Button.new()
    button.name = id
    button.text = title
    button.position = at.position
    button.size = at.size
    button.add_theme_font_size_override("font_size",14)
    button.add_theme_color_override("font_color",PAPER)
    var style := StyleBoxFlat.new()
    style.bg_color = color
    style.border_color = Color("#66989b")
    style.set_border_width_all(1)
    style.set_corner_radius_all(6)
    button.add_theme_stylebox_override("normal",style)
    var highlight := style.duplicate() as StyleBoxFlat
    highlight.bg_color = Color("#34867e")
    button.add_theme_stylebox_override("hover",highlight)
    button.add_theme_stylebox_override("pressed",highlight)
    button.pressed.connect(action)
    add_child(button)
    buttons[id] = button
    return button

func _make_portrait(kind: String, at: Rect2) -> TextureRect:
    var picture := TextureRect.new()
    picture.position = at.position
    picture.size = at.size
    picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    picture.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(picture)
    _load_portrait(picture,kind)
    return picture

func _load_portrait(picture: TextureRect, kind: String) -> void:
    var extra: String = "_evo" if bool(game.evolved[kind]) else ""
    var path: String = "res://assets/%s%s_front.png" % [kind,extra]
    picture.texture = load(path) as Texture2D

func _make_bar(at: Rect2, tint: Color) -> ColorRect:
    # Pixel-exact colors prevent minimum-height ProgressBar theming from
    # obscuring the main tap button at small logical game resolutions.
    var background := ColorRect.new()
    background.position = at.position
    background.size = at.size
    background.color = Color("#091623")
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)
    var fill := ColorRect.new()
    fill.position = at.position
    fill.size = at.size
    fill.color = tint
    fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(fill)
    return fill

func _build_interface() -> void:
    var background := ColorRect.new()
    background.color = DARK
    background.size = Vector2(960,540)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)
    _make_panel(Rect2(12,10,936,64),PANEL_ALT)
    _make_label("title","WILDBOUND",Rect2(26,16,220,38),29,MINT)
    _make_label("tagline","Creature Ascension • incremental prototype",Rect2(27,50,320,18),12,MUTED)
    _make_label("top_stats","",Rect2(340,17,590,42),17,GOLD)

    _make_panel(Rect2(12,84,288,391))
    _make_label("roster_title","YOUR BONDED PACK",Rect2(25,96,268,30),20,MINT)
    for i in range(3):
        var kind: String = String(ENGINE.ORDER[i])
        var top: float = 135.0+i*109.0
        _make_panel(Rect2(23,top,264,102),PANEL_ALT)
        portraits[kind] = _make_portrait(kind,Rect2(31,top+10.0,76,76))
        _make_label(kind+"_name","",Rect2(107,top+8,165,22),16,PAPER)
        _make_label(kind+"_info","",Rect2(107,top+33,172,29),12,MUTED)
        _make_button("buy_"+kind,"",Rect2(109,top+69,168,26),_buy_species.bind(kind))

    _make_panel(Rect2(309,84,346,391))
    _make_label("arena_title","THE WILDS",Rect2(325,96,260,29),20,MINT)
    _make_label("arena_sub","",Rect2(325,127,313,22),15,GOLD)
    _make_panel(Rect2(356,155,251,196),PANEL_ALT)
    _make_button("hit","TAP TO STRIKE",Rect2(374,307,214,36),_hit,Color("#7c5337"))
    enemy_portrait = _make_portrait("brinlet",Rect2(402,166,160,131))
    _make_label("enemy_hp","",Rect2(369,277,224,24),15,PAPER)
    enemy_bar = _make_bar(Rect2(365,297,234,9),Color("#e89a73"))
    _make_label("ward_title","Sanctuary Ward",Rect2(329,360,170,24),14,MUTED)
    _make_label("ward_value","",Rect2(511,360,130,22),13,PAPER)
    ward_bar = _make_bar(Rect2(330,388,306,15),MINT)
    _make_label("battle_dps","",Rect2(329,414,311,21),15,GOLD)
    _make_label("hint","Grove > Tide > Ember > Grove. Tap to assist.",Rect2(327,443,316,25),11,MUTED)

    _make_panel(Rect2(666,84,282,391))
    _make_label("module_title","FIELD UPGRADES",Rect2(682,96,246,28),20,MINT)
    for i in range(3):
        var kind: String = String(ENGINE.MODULES[i])
        var y: float = 130.0+i*67.0
        _make_label("module_"+kind,"",Rect2(681,y,244,21),14,PAPER)
        _make_button("module_buy_"+kind,"",Rect2(682,y+24,245,30),_buy_module.bind(kind))
    _make_label("ascend_label","",Rect2(682,340,243,24),12,GOLD)
    _make_button("ascend","ASCEND",Rect2(683,363,243,34),_ascend,Color("#7b536d"))
    _make_label("research_label","PERMANENT RESEARCH",Rect2(681,405,250,18),13,MINT)
    _make_button("research_might","",Rect2(681,428,118,34),_buy_research.bind("might"))
    _make_button("research_heart","",Rect2(806,428,120,34),_buy_research.bind("heart"))

    _make_panel(Rect2(12,483,936,47),PANEL_ALT)
    _make_label("notice","",Rect2(22,496,460,27),13,PAPER)
    _make_button("pause","AUTO ON",Rect2(488,493,104,31),_toggle_pause)
    _make_button("repeat","REPEAT OFF",Rect2(600,493,116,31),_toggle_repeat)
    _make_button("batch","BUY x1",Rect2(726,493,93,31),_toggle_batch)
    _make_button("save","SAVE",Rect2(826,493,110,31),_manual_save)

func _fmt(value: float) -> String:
    var abs_value: float = absf(value)
    if abs_value < 1000.0:
        return "%.0f" % value
    var names := ["K","M","B","T","Qa","Qi","Sx","Sp","Oc","No"]
    var temp: float = value
    var index: int = -1
    while absf(temp) >= 1000.0 and index < names.size()-1:
        temp /= 1000.0
        index += 1
    return "%.2f%s" % [temp,names[index]]

func _refresh() -> void:
    if game == null:
        return
    labels["top_stats"].text = "Gold  %s     Echoes  %d     Best Wave  %d" % [_fmt(game.gold),game.echoes,game.best_wave]
    for kind in ENGINE.ORDER:
        var level: int = int(game.levels[kind])
        labels[kind+"_name"].text = game.species_name(kind) if level > 0 else str(ENGINE.SPECIES[kind]["name"])+"  • Locked"
        labels[kind+"_info"].text = ("Lv %d | %s\nBond %d / 25" % [level,str(ENGINE.SPECIES[kind]["element"]),int(game.bonds[kind])]) if level > 0 else "Recruit your next creature"
        var cost: float = game.purchase_cost(kind,buy_batch if level > 0 else 1)
        buttons["buy_"+kind].text = ("%s  %s Gold" % [("Level +" + str(buy_batch)) if level > 0 else "Recruit",_fmt(cost)])
        buttons["buy_"+kind].disabled = game.gold < cost
        _load_portrait(portraits[kind],kind)
        portraits[kind].modulate = Color.WHITE if level > 0 else Color(0.35,0.4,0.5,0.7)
    labels["arena_sub"].text = "Wave %d  •  %s  •  %s" % [game.wave,"BOSS" if game.enemy_is_boss() else "WILD",str(ENGINE.SPECIES[game.enemy_species]["element"])]
    var enemy_path: String = "res://assets/%s_front.png" % game.enemy_species
    if game.enemy_is_boss():
        enemy_path = "res://assets/%s_evo_front.png" % game.enemy_species
    enemy_portrait.texture = load(enemy_path) as Texture2D
    labels["enemy_hp"].text = "Enemy HP  %s / %s" % [_fmt(maxf(0.0,game.enemy_hp)),_fmt(game.enemy_max_hp)]
    enemy_bar.size.x = 234.0*clampf(game.enemy_hp/maxf(1.0,game.enemy_max_hp),0.0,1.0)
    labels["ward_value"].text = "%s / %s" % [_fmt(game.ward),_fmt(game.max_ward())]
    ward_bar.size.x = 306.0*clampf(game.ward/maxf(1.0,game.max_ward()),0.0,1.0)
    labels["battle_dps"].text = "Pack DPS: %s    |    Manual hit: %s" % [_fmt(game.total_dps()),_fmt(maxf(2.0,game.total_dps()*0.53))]
    for kind in ENGINE.MODULES:
        var rank: int = int(game.modules[kind])
        var desc: String = "Attack Power" if kind == "power" else ("Ward Strength" if kind == "guard" else "Attack Speed")
        labels["module_"+kind].text = "%s  •  Rank %d" % [desc,rank]
        var cost: float = game.module_cost(kind)
        buttons["module_buy_"+kind].text = "Upgrade — %s Gold" % _fmt(cost)
        buttons["module_buy_"+kind].disabled = game.gold < cost
    var earn: int = game.available_echoes()
    labels["ascend_label"].text = "Ascend at wave 20+  •  Reward: %d Echoes" % earn
    buttons["ascend"].disabled = earn == 0
    buttons["research_might"].text = "Might +22%% (%d)" % game.research_cost("might")
    buttons["research_heart"].text = "Ward +18%% (%d)" % game.research_cost("heart")
    buttons["research_might"].disabled = game.echoes < game.research_cost("might")
    buttons["research_heart"].disabled = game.echoes < game.research_cost("heart")
    labels["notice"].text = game.last_notice
    buttons["pause"].text = "AUTO ON" if running else "PAUSED"
    buttons["repeat"].text = "REPEAT ON" if game.repeat_wave else "REPEAT OFF"
    buttons["batch"].text = "BUY x%d" % buy_batch

func _buy_species(kind: String) -> void:
    var count: int = buy_batch if int(game.levels[kind]) > 0 else 1
    game.buy_levels(kind,count)
    _refresh()

func _buy_module(kind: String) -> void:
    game.buy_module(kind)
    _refresh()

func _buy_research(kind: String) -> void:
    game.buy_research(kind)
    _refresh()

func _hit() -> void:
    game.tap()
    _refresh()

func _ascend() -> void:
    if game.ascend():
        game.save()
    _refresh()

func _toggle_pause() -> void:
    running = not running
    _refresh()

func _toggle_repeat() -> void:
    game.repeat_wave = not game.repeat_wave
    _refresh()

func _toggle_batch() -> void:
    buy_batch = 10 if buy_batch == 1 else (25 if buy_batch == 10 else 1)
    _refresh()

func _manual_save() -> void:
    if game.save():
        game.last_notice = "Your progress was saved."
    _refresh()

func _on_notice(_message: String) -> void:
    _refresh()
