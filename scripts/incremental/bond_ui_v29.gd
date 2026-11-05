extends "res://scripts/incremental/bond_ui_v28.gd"
## Wildbound v0.29 — true playable Clicker-style layout.
## The v0.25 game engine, collection, save data, and side-menu remain untouched.
## Only the presentation is rebuilt. No mockup screenshots are used as UI.

const VALLEY_29 = preload("res://assets/incremental/v29/valley_arena.svg")
const BOND_29 = preload("res://scripts/incremental/roster_art_v18.gd")
const GOLD_29: Color = Color("#f0c671")
const LIGHT_29: Color = Color("#e7f4ec")
const SEA_29: Color = Color("#82d4c8")

var clicker29_ready: bool = false
var clicker29_layer: Control
var currency29: Array[Label] = []
var stage29: Label
var stage_hint29: Label
var enemy29: TextureRect
var enemy29_name: Label
var enemy29_count: Label
var enemy29_hp: Label
var enemy29_fill: ColorRect
var unit29_rows: Array[Dictionary] = []
var unit29_order: Array[String] = []
var party29_rows: Array[Dictionary] = []
var party29_title: Label
var team29_power: Label
var action29: Button
var farm29: Button
var team29_button: Button
var legacy29_button: Button
var battlefield29_hint: Label
var clock29: float = 0.0

func _ready() -> void:
    super._ready()
    _build_clicker29()
    clicker29_ready = true
    _close_drawer()
    _refresh()

func _clicker_panel(name: String,rect: Rect2,fill: Color,edge: Color,rounding: int = 14) -> Panel:
    var card := Panel.new()
    card.name = name
    card.position = rect.position
    card.size = rect.size
    card.mouse_filter = Control.MOUSE_FILTER_IGNORE
    card.add_theme_stylebox_override("panel",_glass(fill,edge,rounding,1,4))
    clicker29_layer.add_child(card)
    return card

func _clicker_label(name: String,value: String,rect: Rect2,
        size: int = 15,tint: Color = LIGHT_29) -> Label:
    var line := Label.new()
    line.name = name
    line.text = value
    line.position = rect.position
    line.size = rect.size
    line.clip_text = true
    line.mouse_filter = Control.MOUSE_FILTER_IGNORE
    line.add_theme_font_size_override("font_size",size)
    line.add_theme_color_override("font_color",tint)
    clicker29_layer.add_child(line)
    return line

func _clicker_image(name: String,rect: Rect2,picture: Texture2D) -> TextureRect:
    var artwork := TextureRect.new()
    artwork.name = name
    artwork.position = rect.position
    artwork.size = rect.size
    artwork.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    artwork.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    artwork.mouse_filter = Control.MOUSE_FILTER_IGNORE
    artwork.texture = picture
    clicker29_layer.add_child(artwork)
    return artwork

func _clicker_button(name: String,caption: String,rect: Rect2,
        action: Callable,highlight: bool = false) -> Button:
    var button := Button.new()
    button.name = name
    button.text = caption
    button.position = rect.position
    button.size = rect.size
    clicker29_layer.add_child(button)
    button.pressed.connect(action)
    _skin_button(button,GOLD_29 if highlight else SEA_29,highlight)
    button.add_theme_font_size_override("font_size",16 if highlight else 13)
    button.add_theme_color_override("font_color",Color("#f7eed6"))
    button.add_theme_color_override("font_hover_color",Color.WHITE)
    button.add_theme_color_override("font_disabled_color",Color("#89a0a4"))
    if highlight:
        _paint_gold29(button)
    return button

func _paint_gold29(button: Button) -> void:
    button.add_theme_stylebox_override("normal",_glass(Color("#916320"),Color("#fadd8b"),13,2,6))
    button.add_theme_stylebox_override("hover",_glass(Color("#b07c31"),Color("#fff0ad"),13,2,7))
    button.add_theme_stylebox_override("pressed",_glass(Color("#775020"),Color("#e9b86e"),13,2,3))

func _build_clicker29() -> void:
    clicker29_layer = Control.new()
    clicker29_layer.name = "V29ClickerExperience"
    clicker29_layer.position = Vector2.ZERO
    clicker29_layer.size = Vector2(1280,720)
    clicker29_layer.z_index = 2
    clicker29_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(clicker29_layer)

    # Opaque cover isolates the new interface from the inherited UI's
    # numerous root-owned labels, bars and controls without destroying them.
    var backdrop := ColorRect.new()
    backdrop.name = "V29OpaqueBackdrop"
    backdrop.color = Color("#061c29")
    backdrop.position = Vector2.ZERO
    backdrop.size = Vector2(1280,720)
    backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
    clicker29_layer.add_child(backdrop)
    var world: TextureRect = _clicker_image("V29Valley",Rect2(402,98,870,521),VALLEY_29)
    world.stretch_mode = TextureRect.STRETCH_SCALE
    world.modulate = Color("#ffffff",0.91)

    # Compact top resources. Original MENU remains interactive, above drawer.
    _clicker_panel("V29TopBar",Rect2(12,10,1256,79),
        Color("#0a303f",0.97),Color("#80b8a7",0.72),13)
    _clicker_label("V29GameTitle","WILDBOUND",Rect2(32,18,365,41),35,
        Color("#fbf2d9"))
    _clicker_label("V29GameSubtitle","ELEMENTAL CREATURES  •  BOND  •  ASCEND",
        Rect2(36,61,394,17),10,SEA_29)
    var resources: Array = [
        ["GOLD",510.0,198.0,COIN],["ESSENCE",719.0,166.0,ESSENCE],
        ["ECHO",896.0,101.0,ECHO]
    ]
    for i in range(resources.size()):
        var data: Array = resources[i]
        var x: float = float(data[1])
        var width: float = float(data[2])
        _clicker_panel("V29ResourceBg_"+str(i),Rect2(x,24,width,49),
            Color("#193b49",0.97),Color("#9cb9a9",0.60),11)
        _clicker_image("V29ResourceIcon_"+str(i),
            Rect2(x+8,34,29,29),data[3] as Texture2D)
        currency29.append(_clicker_label("V29ResourceText_"+str(i),"",
            Rect2(x+42,33,width-46,31),16,LIGHT_29))
    _clicker_panel("V29AscendBadge",Rect2(1007,24,130,49),
        Color("#153e4b",0.97),Color("#dbbb79",0.83),11)
    var ascent: Label = _clicker_label("V29AscendBadgeTitle","ASCEND",
        Rect2(1021,27,100,20),11,GOLD_29)
    ascent.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    var ascent_progress: Label = _clicker_label("V29AscendProgress","",
        Rect2(1015,48,113,19),12,LIGHT_29)
    ascent_progress.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    # This is the actual inherited menu opener, not a fake graphic.
    menu28_button.position = Vector2(1149,24)
    menu28_button.size = Vector2(113,49)
    menu28_button.z_index = 9
    menu28_button.add_theme_font_size_override("font_size",16)
    menu28_button.text = "☰ MENU"

    # The left panel is a real spending interface, like an idle RPG roster.
    _clicker_panel("V29TrainingBg",Rect2(16,105,379,587),
        Color("#0e2c3b",0.98),Color("#86cbbb",0.86),20)
    _clicker_label("V29TrainingTitle","CREATURE TRAINING",
        Rect2(37,121,342,33),23,Color("#fff5db"))
    _clicker_label("V29TrainingHelp","Level creatures with Gold to deal more damage.",
        Rect2(37,153,343,23),12,Color("#b9d9cd"))
    for i in range(5):
        var top: float = 187.0+float(i)*96.0
        _clicker_panel("V29TrainingRowBg_"+str(i),
            Rect2(28,top,355,89),Color("#163c4c",0.96),
            Color("#6e9a99",0.86),12)
        var face: TextureRect = _clicker_image("V29TrainingPortrait_"+str(i),
            Rect2(38,top+10,75,69),null)
        var n: Label = _clicker_label("V29TrainingName_"+str(i),"",
            Rect2(123,top+7,137,23),16,LIGHT_29)
        var rank: Label = _clicker_label("V29TrainingLevel_"+str(i),"",
            Rect2(123,top+35,138,18),12,Color("#e1cf9f"))
        var dps: Label = _clicker_label("V29TrainingDps_"+str(i),"",
            Rect2(123,top+57,144,19),12,Color("#b1dec9"))
        var btn: Button = _clicker_button("V29Train_"+str(i),"",
            Rect2(269,top+17,105,58),_buy_roster29.bind(i),true)
        btn.add_theme_font_size_override("font_size",13)
        unit29_rows.append({"portrait":face,"name":n,"rank":rank,
            "dps":dps,"button":btn})
    _clicker_label("V29RosterFootnote","All creatures and Gold upgrades are in MENU.",
        Rect2(30,667,348,18),11,Color("#93baa9"))

    # Real battle engine still runs 3-versus-3. This is a deliberately
    # focused view of the first living rival, not a new one-enemy game mode.
    _clicker_panel("V29BattleBorder",Rect2(405,105,857,503),
        Color("#123343",0.10),Color("#9bc0ac",0.78),18)
    _clicker_panel("V29StagePill",Rect2(699,119,248,56),
        Color("#102d3a",0.91),GOLD_29,14)
    stage29 = _clicker_label("V29StageLabel","STAGE 1",
        Rect2(712,122,222,28),23,Color("#fff5d9"))
    stage29.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    stage_hint29 = _clicker_label("V29StageHint","AUTO BATTLE",
        Rect2(713,150,221,19),11,Color("#abdbca"))
    stage_hint29.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    enemy29 = _clicker_image("V29HeroEnemy",Rect2(687,178,335,270),null)
    enemy29.pivot_offset = enemy29.size*0.5
    enemy29_name = _clicker_label("V29EnemyName","",
        Rect2(658,432,329,29),21,Color("#fff2dc"))
    enemy29_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    enemy29_count = _clicker_label("V29EnemyCount","",
        Rect2(1000,440,112,23),11,Color("#ffd7b0"))
    enemy29_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _clicker_panel("V29EnemyHpRail",Rect2(614,472,499,34),
        Color("#172c38",0.94),Color("#dca17d",0.85),12)
    enemy29_fill = ColorRect.new()
    enemy29_fill.name = "V29EnemyHpFill"
    enemy29_fill.position = Vector2(618,476)
    enemy29_fill.size = Vector2(491,25)
    enemy29_fill.color = Color("#d65d49")
    enemy29_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
    clicker29_layer.add_child(enemy29_fill)
    enemy29_hp = _clicker_label("V29EnemyHp","",
        Rect2(630,475,469,27),15,Color("#fff6df"))
    enemy29_hp.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    # A genuinely compact strip; creature training is now on the left.
    _clicker_panel("V29PartyBar",Rect2(421,527,695,88),
        Color("#0b2b3b",0.94),Color("#8dc5b5",0.91),13)
    party29_title = _clicker_label("V29PartyTitle","YOUR TEAM  (3/3)",
        Rect2(437,530,320,21),14,SEA_29)
    team29_power = _clicker_label("V29TeamDps","",
        Rect2(811,530,289,22),14,GOLD_29)
    team29_power.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    for i in range(3):
        var x: float = 434.0+float(i)*225.0
        _clicker_panel("V29PartySlot_"+str(i),Rect2(x,553,216,53),
            Color("#163c4b",0.99),Color("#639ca7",0.77),10)
        var portrait: TextureRect = _clicker_image("V29PartyArt_"+str(i),
            Rect2(x+3,555,55,48),null)
        var text: Label = _clicker_label("V29PartyName_"+str(i),"",
            Rect2(x+60,554,150,23),13,LIGHT_29)
        var line: Label = _clicker_label("V29PartyHealth_"+str(i),"",
            Rect2(x+60,579,150,20),11,SEA_29)
        party29_rows.append({"portrait":portrait,"name":text,"hp":line})

    # Short plain-language actions, no duplicated legacy battle controls.
    action29 = _clicker_button("V29PrimaryBattle","▶ START BATTLE",
        Rect2(442,630,527,60),_strike,true)
    action29.add_theme_font_size_override("font_size",24)
    farm29 = _clicker_button("V29Farm","FARM GOLD",
        Rect2(983,630,252,60),_repeat)
    farm29.add_theme_font_size_override("font_size",17)
    farm29.tooltip_text = "Repeat a cleared stage for Gold and Bond XP. No Essence from farming."
    battlefield29_hint = _clicker_label("V29PassiveTip",
        "Your team attacks automatically. Manual attacks are optional.",
        Rect2(450,611,767,18),11,Color("#bdd6ce"))
    battlefield29_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    # Only two shortcuts: optional navigation is still behind MENU.
    team29_button = _clicker_button("V29TeamShortcut","TEAM",
        Rect2(1135,258,115,64),_show_section.bind("TEAM"))
    legacy29_button = _clicker_button("V29AscendShortcut","ASCEND",
        Rect2(1135,330,115,64),_show_section.bind("LEGACY"))
    _clicker_label("V29AutoCombatNotice","AUTO ATTACK ON",
        Rect2(1127,222,126,24),11,SEA_29).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    # The new layer covers all legacy art but not the existing menu / dialogs.
    get_node("Background").mouse_filter = Control.MOUSE_FILTER_IGNORE

func _training_order29() -> Array[String]:
    var order: Array[String] = []
    for kind in game.squad_slots:
        var name: String = String(kind)
        if name != "" and game.has_instance(name) and not order.has(name):
            order.append(name)
    for candidate in ENGINE_25.COLLECTION_ORDER:
        var name: String = String(candidate)
        if game.has_instance(name) and not order.has(name):
            order.append(name)
    return order

func _buy_roster29(index: int) -> void:
    if game == null or index < 0 or index >= unit29_order.size():
        return
    var kind: String = unit29_order[index]
    if kind == "":
        _show_section("TEAM")
        return
    if game.level_creature(kind,1):
        game.save()
        _toast("%s • LEVEL %d" % [game.display_name(kind),game.unit_level(kind)])
    _refresh()

func _refresh_clicker29() -> void:
    currency29[0].text = game.format_number(game.gold)
    currency29[1].text = "%d / %d" % [game.essence,game.hatch_cost()]
    currency29[2].text = str(game.echoes)
    (clicker29_layer.get_node("V29AscendProgress") as Label).text = (
        "STAGE %d / 20" % mini(game.wave,20))
    var loss: bool = game.awaiting_next and String(game.last_clash).begins_with("SQUAD DEFEATED")
    stage29.text = "STAGE %d" % game.wave
    stage_hint29.text = (
        "FARMING FOR GOLD" if game.repeat_wave else
        "RETRY TO PUSH" if loss else
        "STAGE CLEARED" if game.awaiting_next else
        "AUTO BATTLE • CREATURES ATTACK")
    if not game.battle_started:
        action29.text = "▶  START BATTLE"
    elif game.awaiting_next:
        action29.text = "↻  RETRY STAGE" if loss else "⚔  NEXT STAGE"
    elif not playing:
        action29.text = "▶  RESUME BATTLE"
    else:
        action29.text = "⚔  HELP ATTACK"
    action29.disabled = _any_blocking_dialog()
    var farm_allowed: bool = game.battle_started and game.last_cleared_run_stage() >= 1
    farm29.visible = farm_allowed
    farm29.text = "RETURN TO PUSH" if game.repeat_wave else "↻  FARM GOLD"
    battlefield29_hint.text = (
        "Farming earns Gold and Bond XP, never Essence." if game.repeat_wave else
        "Your team attacks automatically. Manual attacks are optional.")
    unit29_order = _training_order29()
    for i in range(unit29_rows.size()):
        var row: Dictionary = unit29_rows[i]
        var portrait: TextureRect = row["portrait"]
        var name_label: Label = row["name"]
        var rank_label: Label = row["rank"]
        var dps_label: Label = row["dps"]
        var train: Button = row["button"]
        if i >= unit29_order.size():
            portrait.texture = null
            name_label.text = "UNDISCOVERED"
            rank_label.text = "Earn Essence in battle"
            dps_label.text = "Hatch from MENU"
            train.text = "COLLECT"
            train.disabled = false
            continue
        var kind: String = unit29_order[i]
        var evolved: bool = game.unit_evolved(kind)
        portrait.texture = _creature_texture(kind,evolved,false)
        name_label.text = game.display_name(kind,2 if game.unit_ascended(kind) else 1 if evolved else 0)
        rank_label.text = "LV %d / %d • BOND %d" % [
            game.unit_level(kind),game.bond_level_cap(kind),game.unit_bond_rank(kind)]
        var dps: float = game.combat_damage(kind)/maxf(0.1,game.combat_interval(kind))
        dps_label.text = "DPS  %s" % game.format_number(dps)
        var cost: float = game.creature_level_price(kind,1)
        if cost == INF:
            train.text = "BOND CAP"
            train.disabled = true
        else:
            train.text = "LEVEL UP\n%s G" % game.format_number(cost)
            train.disabled = game.gold < cost
        train.tooltip_text = "Spend Gold on %s. Bond Rank controls its maximum level." % game.display_name(kind)

    var active_count: int = 0
    var total_power: float = 0.0
    for i in range(3):
        var row: Dictionary = party29_rows[i]
        var kind: String = String(game.squad_slots[i])
        var pic: TextureRect = row["portrait"]
        var lab: Label = row["name"]
        var hp_lab: Label = row["hp"]
        if kind == "" or not game.has_instance(kind):
            pic.texture = null
            lab.text = "EMPTY SLOT %d" % (i+1)
            hp_lab.text = "Assign via TEAM"
            continue
        active_count += 1
        pic.texture = _creature_texture(kind,game.unit_evolved(kind),false)
        lab.text = "%s • LV %d" % [game.display_name(kind),game.unit_level(kind)]
        var current_hp: float = 0.0
        var max_hp: float = 0.0
        if i < game.ally_units.size():
            current_hp = float(game.ally_units[i].get("hp",0.0))
            max_hp = float(game.ally_units[i].get("max_hp",0.0))
        hp_lab.text = "%d / %d HP" % [roundi(current_hp),roundi(max_hp)]
        total_power += game.combat_damage(kind)/maxf(0.1,game.combat_interval(kind))
    party29_title.text = "YOUR TEAM  (%d/3)" % active_count
    team29_power.text = "TEAM DPS  %s" % game.format_number(total_power)

    var target: Dictionary = {}
    var targets_alive: int = 0
    for rival in game.rival_units:
        if String(rival.get("kind","")) == "":
            continue
        if float(rival.get("hp",0.0)) > 0.0:
            targets_alive += 1
            if target.is_empty():
                target = rival
    if target.is_empty() and not game.rival_units.is_empty():
        target = game.rival_units[0]
    if not target.is_empty():
        var enemy_kind: String = String(target.get("kind",""))
        enemy29.texture = _creature_texture(enemy_kind,game.enemy_is_boss(),true)
        enemy29.modulate = Color("#a9c4cb",0.63) if game.awaiting_next else Color.WHITE
        enemy29_name.text = game.display_name(enemy_kind)
        enemy29_count.text = "%d / 3 REMAIN" % targets_alive
        var hp: float = float(target.get("hp",0.0))
        var top_hp: float = maxf(1.0,float(target.get("max_hp",1.0)))
        enemy29_fill.size.x = 491.0*clampf(hp/top_hp,0.0,1.0)
        enemy29_hp.text = "%s / %s HP" % [
            game.format_number(maxf(0.0,hp)),game.format_number(top_hp)]
    else:
        enemy29.texture = null
        enemy29_name.text = "READY FOR BATTLE"
        enemy29_count.text = ""
        enemy29_fill.size.x = 0.0
        enemy29_hp.text = "START A STAGE"

func _refresh() -> void:
    super._refresh()
    if not clicker29_ready or game == null:
        return
    _refresh_clicker29()
    # Legacy controls are kept functional for inherited methods but never
    # permitted above the new battle-first presentation.
    strike_button.hide()
    repeat_button.hide()
    if is_instance_valid(resources28):
        resources28.hide()

func _process(delta: float) -> void:
    super._process(delta)
    if not clicker29_ready:
        return
    clock29 += delta
    # Tiny idle motion on the actual combat portrait.
    enemy29.scale = Vector2.ONE*(1.0+0.009*sin(clock29*1.8))

func _replace_active_game() -> void:
    super._replace_active_game()
    if clicker29_ready:
        _refresh()
