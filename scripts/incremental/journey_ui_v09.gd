extends Control
## Wildbound 0.9: a clean player-first shell around the existing combat engine.
## Three areas: battle, party and one contextual progression column.
const ENGINE = preload("res://scripts/incremental/journey_engine_v09.gd")
const CREATURES = preload("res://scripts/incremental/bestiary_art_v07.gd")
const SCENERY = preload("res://scripts/incremental/scenery_bank_v06.gd")
const TABS = ["GROW","NEST","LEGACY","WORLD"]
const BASE = Color("#101e2a")
const PANEL = Color("#162d3b")
const BORDER = Color("#385b65")
const TEXT = Color("#edf1df")
const MUTED = Color("#a7bac0")
const GOLD = Color("#f2c779")
const GREEN = Color("#9ad9aa")
const CORAL = Color("#f2ab7b")
const COLORS = {"spriglet":Color("#8cdda1"),"brinlet":Color("#8ed2ea"),"cindlet":Color("#f6b17c")}
const DESC = {
    "power":"All creatures hit harder.",
    "tempo":"Faster automatic attacks.",
    "guard":"Increase Ward and survive longer.",
    "crit":"More frequent critical strikes.",
    "bounty":"Earn more Gold per victory.",
    "recovery":"Regenerate Ward over time.",
    "pierce":"Stronger strikes against Guardians."
}

var game
var playing: bool = true
var tab: String = "GROW"
var batch: int = 1
var ui_clock: float = 0.0
var autosave_clock: float = 0.0
var animation_clock: float = 0.0
var last_kills: int = 0
var last_guardian: int = 0
var toast_time: float = 0.0
var notice_message: String = ""
var screen_labels: Dictionary = {}
var card_art: Dictionary = {}
var card_buy: Dictionary = {}
var card_skill: Dictionary = {}
var card_details: Dictionary = {}
var team_art: Array[TextureRect] = []
var enemy_art: TextureRect
var scenic_art: TextureRect
var threat_bar: ColorRect
var ward_bar: ColorRect
var resonance_bar: ColorRect
var trail_fill: ColorRect
var trail_button: Button
var strike_button: Button
var resonance_button: Button
var speed_button: Button
var repeat_button: Button
var tab_buttons: Dictionary = {}
var sidebar: VBoxContainer
var active_rows: Array[Dictionary] = []
var guide_dialog: AcceptDialog
var ascend_dialog: ConfirmationDialog
var stage_steps: Array[ColorRect] = []
var _scene_key: String = ""

func _ready() -> void:
    game = ENGINE.new()
    game.initialize_alpha()
    game.load_save()
    game.notice.connect(_on_notice)
    last_kills = game.kills
    last_guardian = game.last_boss_wave
    _build_layout()
    _switch_tab("GROW")
    _refresh()

func _process(delta: float) -> void:
    animation_clock += delta
    if playing:
        game.tick(delta)
    ui_clock += delta
    autosave_clock += delta
    toast_time = maxf(0.0,toast_time-delta)
    if game.kills > last_kills:
        if game.last_boss_wave > last_guardian:
            _toast("GUARDIAN CLEARED! Nest Shards + Relic reward.")
        elif game.kills <= 4 or game.kills % 5 == 0:
            _toast("VICTORY!  Gold earned. Your bonds grow.")
        last_kills = game.kills
        last_guardian = game.last_boss_wave
    if ui_clock >= 0.16:
        ui_clock = 0.0
        _refresh()
    if autosave_clock >= 20.0:
        autosave_clock = 0.0
        game.save()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST and game != null:
        game.save()

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    var key: InputEventKey = event as InputEventKey
    if not key.pressed or key.echo or key.ctrl_pressed or key.alt_pressed or key.meta_pressed:
        return
    if guide_dialog.visible or ascend_dialog.visible:
        return
    match key.keycode:
        KEY_SPACE:
            _strike()
        KEY_1:
            _use_skill("spriglet")
        KEY_2:
            _use_skill("brinlet")
        KEY_3:
            _use_skill("cindlet")
        KEY_R:
            _resonate()
        KEY_TAB:
            _switch_tab(TABS[(TABS.find(tab)+1)%TABS.size()])
        KEY_B:
            _toggle_batch()
        KEY_S:
            _save()
        _:
            return
    get_viewport().set_input_as_handled()

func _style(fill: Color, edge: Color = BORDER, radius: int = 10) -> StyleBoxFlat:
    var s := StyleBoxFlat.new()
    s.bg_color = fill
    s.border_color = edge
    s.set_border_width_all(1)
    s.set_corner_radius_all(radius)
    s.content_margin_left = 8
    s.content_margin_right = 8
    s.content_margin_top = 6
    s.content_margin_bottom = 6
    return s

func _panel(name: String, rect: Rect2, fill: Color = PANEL, edge: Color = BORDER) -> Panel:
    var p := Panel.new()
    p.name = name
    p.position = rect.position
    p.size = rect.size
    p.add_theme_stylebox_override("panel",_style(fill,edge))
    p.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(p)
    return p

func _label(name: String, value: String, rect: Rect2, font_size: int = 15, color: Color = TEXT) -> Label:
    var l := Label.new()
    l.name = name
    l.text = value
    l.position = rect.position
    l.size = rect.size
    l.add_theme_color_override("font_color",color)
    l.add_theme_font_size_override("font_size",font_size)
    l.clip_text = true
    l.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(l)
    screen_labels[name] = l
    return l

func _button(name: String, title: String, rect: Rect2, action: Callable, accent: Color = GREEN) -> Button:
    var b := Button.new()
    b.name = name
    b.text = title
    b.position = rect.position
    b.size = rect.size
    b.add_theme_font_size_override("font_size",13)
    b.add_theme_color_override("font_color",TEXT)
    b.add_theme_color_override("font_disabled_color",MUTED.darkened(0.28))
    b.add_theme_stylebox_override("normal",_style(Color("#244658"),accent.darkened(0.30),7))
    b.add_theme_stylebox_override("hover",_style(Color("#36657b"),accent,7))
    b.add_theme_stylebox_override("pressed",_style(Color("#17303a"),accent.lightened(0.15),7))
    b.add_theme_stylebox_override("disabled",_style(Color("#26333c"),Color("#344651"),7))
    b.pressed.connect(action)
    add_child(b)
    return b

func _texture(name: String, rect: Rect2, picture: Texture2D = null) -> TextureRect:
    var t := TextureRect.new()
    t.name = name
    t.position = rect.position
    t.size = rect.size
    t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    t.mouse_filter = Control.MOUSE_FILTER_IGNORE
    t.texture = picture
    add_child(t)
    return t

func _paint(name: String, rect: Rect2, color: Color) -> ColorRect:
    var c := ColorRect.new()
    c.name = name
    c.position = rect.position
    c.size = rect.size
    c.color = color
    c.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(c)
    return c

func _build_layout() -> void:
    _paint("Background",Rect2(0,0,1280,720),BASE)
    _panel("Header",Rect2(14,11,1252,69),Color("#152b39"),Color("#5c796f"))
    _label("GameName","WILDBOUND",Rect2(30,20,239,36),29,Color("#d6f1ce"))
    _label("Tagline","A living pack. An endless journey.",Rect2(31,55,327,18),11,MUTED)
    _label("Gold","",Rect2(400,25,210,31),21,GOLD)
    _label("Shards","",Rect2(633,28,164,30),18,Color("#9fd7e4"))
    _label("Echoes","",Rect2(825,28,157,30),18,Color("#d6b4f4"))
    _label("TrailRank","",Rect2(996,29,150,26),15,GREEN)
    _button("Save","SAVE",Rect2(1160,26,90,36),_save,GOLD)

    _panel("BattlePanel",Rect2(14,90,826,319),Color("#172e37"),Color("#729589"))
    scenic_art = _texture("BattleLandscape",Rect2(21,96,812,305))
    scenic_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
    _paint("StageTopShade",Rect2(23,99,808,92),Color("#0c232a",0.70))
    _paint("StageBottomShade",Rect2(23,363,808,36),Color("#10222a",0.66))
    _label("Wave","WAVE 1",Rect2(38,104,331,29),22,TEXT)
    _label("EncounterHint","PACK ATTACKS AUTOMATICALLY",Rect2(39,137,442,20),12,GREEN)
    _label("EnemyName","",Rect2(554,106,258,29),21,Color("#f9e2c5")).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _label("EnemyHp","",Rect2(565,141,248,23),13,Color("#fff0de")).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _paint("EnemyHpRail",Rect2(582,169,230,10),Color("#253c44"))
    threat_bar = _paint("EnemyHpFill",Rect2(584,171,226,6),CORAL)
    for i in range(10):
        stage_steps.append(_paint("Step_%d"%i,Rect2(40+float(i)*47,166,44,6),Color("#44616a")))
    team_art.append(_texture("AllyLead",Rect2(65,183,202,179)))
    team_art.append(_texture("AllySecond",Rect2(244,232,122,125)))
    team_art.append(_texture("AllyThird",Rect2(350,241,104,116)))
    enemy_art = _texture("EnemySprite",Rect2(610,190,183,174))
    enemy_art.flip_h = true
    _label("FieldStatus","",Rect2(41,367,410,24),13,TEXT)
    _label("DamageReadout","",Rect2(462,367,342,24),13,GOLD).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _paint("WardRail",Rect2(38,396,784,5),Color("#38515c"))
    ward_bar = _paint("WardFill",Rect2(38,396,784,5),GREEN)

    _panel("PackPanel",Rect2(14,417,826,203),Color("#142b38"),Color("#405f62"))
    _label("PackHeader","YOUR PACK",Rect2(30,419,252,24),17,GREEN)
    _label("PackDps","",Rect2(345,420,475,21),13,MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    for i in range(ENGINE.ORDER.size()):
        var kind: String = String(ENGINE.ORDER[i])
        var x: float = 24+float(i)*269
        _panel("PackCard_"+kind,Rect2(x,449,256,163),Color("#1e3947"),COLORS[kind].darkened(0.40))
        card_art[kind] = _texture("CardArt_"+kind,Rect2(x+7,464,100,110))
        _label("Name_"+kind,"",Rect2(x+107,455,143,25),16,COLORS[kind])
        card_details[kind] = _label("Stats_"+kind,"",Rect2(x+107,481,143,47),12,TEXT)
        card_buy[kind] = _button("Buy_"+kind,"",Rect2(x+107,532,139,34),_buy_creature.bind(kind),COLORS[kind])
        card_skill[kind] = _button("Skill_"+kind,"",Rect2(x+10,576,235,29),_use_skill.bind(kind),COLORS[kind])

    _panel("ActionPanel",Rect2(14,630,826,77),Color("#172e3a"),Color("#6b8a87"))
    strike_button = _button("Strike","STRIKE  •  CLICK / SPACE",Rect2(28,642,309,51),_strike,CORAL)
    strike_button.add_theme_font_size_override("font_size",19)
    resonance_button = _button("Resonance","RESONANCE",Rect2(347,642,205,51),_resonate,Color("#c5a0ef"))
    repeat_button = _button("Repeat","ADVANCE",Rect2(561,642,124,51),_repeat,GREEN)
    speed_button = _button("Speed","SPEED 1x",Rect2(694,642,133,51),_speed,GOLD)

    _panel("JourneyPanel",Rect2(852,90,414,198),Color("#1c3541"),Color("#d7b77e"))
    _label("JourneyHeading","THE JOURNEY",Rect2(867,103,235,23),15,GOLD)
    _label("JourneyStage","",Rect2(1126,103,123,22),12,MUTED).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _label("QuestName","",Rect2(869,130,379,27),22,TEXT)
    _label("QuestHint","",Rect2(870,161,378,46),12,MUTED).autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _label("QuestProgress","",Rect2(872,211,258,23),13,GREEN)
    _paint("TrailRail",Rect2(872,240,255,10),Color("#324c50"))
    trail_fill = _paint("TrailFill",Rect2(874,242,0,6),GREEN)
    trail_button = _button("ClaimTrail","KEEP GOING",Rect2(1136,224,111,40),_claim_trail,GOLD)
    _label("QuestReward","",Rect2(872,264,255,19),11,GOLD)

    _panel("SidebarPanel",Rect2(852,296,414,411),Color("#142b39"),Color("#4e7376"))
    for i in range(TABS.size()):
        var name: String = String(TABS[i])
        var btn: Button = _button("Tab_"+name,name,Rect2(865+float(i)*98,308,94,37),_switch_tab.bind(name),GREEN)
        btn.add_theme_font_size_override("font_size",12)
        tab_buttons[name] = btn
    var scroll := ScrollContainer.new()
    scroll.name = "SidebarScroll"
    scroll.position = Vector2(864,354)
    scroll.size = Vector2(386,340)
    scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    add_child(scroll)
    sidebar = VBoxContainer.new()
    sidebar.name = "SidebarCards"
    sidebar.custom_minimum_size = Vector2(366,0)
    sidebar.add_theme_constant_override("separation",8)
    scroll.add_child(sidebar)
    _label("Toast","",Rect2(37,197,509,33),18,Color("#fff2b5"))
    _label("Notification","",Rect2(35,695,776,14),10,MUTED)
    guide_dialog = AcceptDialog.new()
    guide_dialog.title = "Welcome to Wildbound"
    guide_dialog.dialog_text = "Your pack attacks automatically. Strike to help, recruit creatures, and follow THE JOURNEY. Complete objectives to claim Gold, permanent damage, Nest Shards and Echoes. The right-hand tabs reveal deeper systems as you advance."
    add_child(guide_dialog)
    ascend_dialog = ConfirmationDialog.new()
    ascend_dialog.title = "Ascend the Wilds?"
    ascend_dialog.dialog_text = "Ascension resets your Gold, creature levels, and purchased modules. Owned creatures, bonds, evolutions, genes and permanent bonuses survive."
    ascend_dialog.confirmed.connect(_ascend)
    add_child(ascend_dialog)

func _sidebar_card(title: String, details: String, action: String, fn: Callable, mode: String, key: String = "") -> void:
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(366,89)
    card.add_theme_stylebox_override("panel",_style(Color("#1d3a49"),Color("#436a73"),8))
    sidebar.add_child(card)
    var horizontal := HBoxContainer.new()
    horizontal.add_theme_constant_override("separation",8)
    card.add_child(horizontal)
    var words := VBoxContainer.new()
    words.custom_minimum_size = Vector2(225,72)
    horizontal.add_child(words)
    var title_label := Label.new()
    title_label.text = title
    title_label.add_theme_font_size_override("font_size",14)
    title_label.add_theme_color_override("font_color",TEXT)
    title_label.clip_text = true
    words.add_child(title_label)
    var description := Label.new()
    description.text = details
    description.custom_minimum_size = Vector2(225,45)
    description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    description.add_theme_font_size_override("font_size",11)
    description.add_theme_color_override("font_color",MUTED)
    words.add_child(description)
    var button := Button.new()
    button.text = action
    button.custom_minimum_size = Vector2(112,44)
    button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
    button.add_theme_font_size_override("font_size",12)
    button.add_theme_stylebox_override("normal",_style(Color("#2f5963"),Color("#84bca5"),7))
    button.add_theme_stylebox_override("hover",_style(Color("#46767a"),Color("#b5e6c7"),7))
    button.add_theme_stylebox_override("disabled",_style(Color("#293940"),Color("#3c5056"),7))
    button.pressed.connect(fn)
    horizontal.add_child(button)
    active_rows.append({"mode":mode,"key":key,"title":title_label,"info":description,"button":button})

func _switch_tab(next: String) -> void:
    tab = next
    if sidebar == null:
        return
    for child in sidebar.get_children():
        sidebar.remove_child(child)
        child.queue_free()
    active_rows.clear()
    match tab:
        "GROW":
            for kind in ["power","tempo","guard","crit","bounty","recovery","pierce"]:
                _sidebar_card(String(ENGINE.MODULE_NAMES[kind]),String(DESC[kind]),"UPGRADE",_upgrade.bind(kind),"module",kind)
        "NEST":
            _sidebar_card("The Moonlit Nest","Hatch an egg. Duplicates raise a creature's Gene Rank; rare shimmer pity is guaranteed after 10 misses.","HATCH",_hatch,"egg")
            if game.caches_pending > 0:
                for cache in ENGINE.CACHE_ORDER:
                    _sidebar_card(String(ENGINE.CACHE_CHOICES[cache]["name"]),String(ENGINE.CACHE_CHOICES[cache]["desc"]),"CLAIM",_claim_cache.bind(cache),"cache",cache)
            for relic in ENGINE.RELIC_ORDER:
                if int(game.relic_ranks[relic]) > 0:
                    _sidebar_card(String(ENGINE.RELICS[relic]["name"]),String(ENGINE.RELICS[relic]["description"]),"EQUIP",_equip.bind(relic),"relic",relic)
            if game.relic_drops == 0:
                _sidebar_card("Relic Vault","Your first defeated Guardian guarantees a Relic. Equip up to two.","LOCKED",_noop,"information")
        "LEGACY":
            _sidebar_card("Ascend the Wilds","Reset this run for permanent Echoes. Creatures, genes, bonds and evolution survive.","ASCEND",_request_ascension,"ascend")
            for research in ["might","heart","bounty","speed","scavenge","incubator","automation","instinct"]:
                _sidebar_card(String(ENGINE.RESEARCH_NAMES[research]),"Permanent Echo research. Upgrades persist through every Ascension.","RESEARCH",_research.bind(research),"research",research)
            for milestone in ENGINE.MILESTONE_ORDER:
                if not game.milestones_claimed.has(milestone) and game.milestone_progress(milestone) >= int(ENGINE.MILESTONES[milestone]["goal"]):
                    _sidebar_card(String(ENGINE.MILESTONES[milestone]["title"]),"One-time achievement reward: Echoes and Nest Shards.","CLAIM",_milestone.bind(milestone),"milestone",milestone)
        "WORLD":
            for region in ENGINE.REGION_ORDER:
                _sidebar_card(String(ENGINE.REGIONS[region]["name"]),"Discover this region to unlock stronger foes and Gold bonuses.","TRAVEL",_travel.bind(region),"region",region)
            for stance in ENGINE.STANCES:
                _sidebar_card("Tactic: "+String(stance),String(ENGINE.CAMP_DESCRIPTIONS.get("pack","")) if stance == "Balanced" else "Change pack damage, defense and rewards to match your strategy.","SELECT",_stance.bind(stance),"stance",stance)
            for creature in ENGINE.ORDER:
                if game.can_specialize(creature):
                    for choice in ENGINE.SPECIALIZATION_ORDER[creature]:
                        _sidebar_card(String(ENGINE.SPECIALIZATIONS[creature][choice]["name"]),String(ENGINE.SPECIALIZATIONS[creature][choice]["desc"]),"MASTER",_mastery.bind(creature,choice),"mastery",creature+":"+choice)
    _refresh_sidebar()

func _refresh_sidebar() -> void:
    if game == null:
        return
    for key in TABS:
        var button: Button = tab_buttons[key]
        button.add_theme_stylebox_override("normal",_style(
            Color("#42655b") if tab == key else Color("#254352"),
            GOLD if tab == key else Color("#3d6370"),6))
    for row in active_rows:
        var mode: String = String(row["mode"])
        var key: String = String(row["key"])
        var button: Button = row["button"]
        var info: Label = row["info"]
        match mode:
            "module":
                var price: float = game.module_cost(key)
                button.text = game.format_number(price)+" G"
                button.disabled = game.gold < price
                info.text = "%s  •  Rank %d" % [DESC[key],int(game.modules[key])]
            "egg":
                button.text = "HATCH • 5"
                button.disabled = game.nests < game.hatch_cost()
                info.text = "%d Nest Shards  •  %d eggs hatched  •  Shimmer pity %d/10" % [game.nests,game.eggs_hatched,game.rare_pity]
            "cache":
                button.disabled = game.caches_pending <= 0
            "relic":
                var equipped: bool = game.equipped_relics.has(key)
                button.text = "REMOVE" if equipped else "EQUIP"
                button.disabled = not equipped and game.equipped_relics.size() >= 2
                info.text = "Rank %d  •  %s" % [int(game.relic_ranks[key]),String(ENGINE.RELICS[key]["description"])]
            "ascend":
                var echoes: int = game.available_echoes()
                button.disabled = echoes < 1
                button.text = "+%d ECHO" % echoes
                info.text = "Earn %d Echoes now. Best wave %d. Permanent growth starts here." % [echoes,game.best_wave]
            "research":
                var amount: int = game.research_cost(key)
                button.disabled = game.echoes < amount
                button.text = "%d ECHO" % amount
                info.text = "Permanent • Rank %d  •  Next cost %d Echoes" % [int(game.research[key]),amount]
            "milestone":
                button.disabled = game.milestones_claimed.has(key)
            "region":
                var entry: Dictionary = ENGINE.REGIONS[key]
                button.disabled = not game.region_available(key) or game.region == key
                button.text = "ACTIVE" if game.region == key else ("WAVE "+str(entry["unlock"]) if button.disabled else "TRAVEL")
                info.text = "Unlock at wave %d • %.1fx Gold, %.1fx health" % [int(entry["unlock"]),float(entry["gold"]),float(entry["hp"])]
            "stance":
                button.disabled = game.stance == key
                button.text = "ACTIVE" if game.stance == key else "SELECT"
                info.text = "Current: "+game.stance_description() if game.stance == key else "Changes pack attack, defense or Gold earnings."
            "mastery":
                var parts: PackedStringArray = key.split(":")
                var creature: String = String(parts[0])
                var choice: String = String(parts[1])
                button.disabled = String(game.specialization[creature]) == choice or (game.specialization[creature] != "" and game.nests < 12)
                button.text = "ACTIVE" if String(game.specialization[creature]) == choice else "CHOOSE"
            "information":
                button.disabled = true

func _refresh() -> void:
    if game == null or screen_labels.is_empty():
        return
    screen_labels["Gold"].text = "GOLD  "+game.format_number(game.gold)
    screen_labels["Shards"].text = "SHARDS  "+str(game.nests)
    screen_labels["Echoes"].text = "ECHOES  "+str(game.echoes)
    screen_labels["TrailRank"].text = "TRAIL  %d / %d" % [game.trail_rank,game.TRAIL.size()]
    screen_labels["Wave"].text = "WAVE %d  /  %s" % [game.wave,String(ENGINE.REGIONS[game.region]["name"])]
    var guardian: bool = game.enemy_is_boss()
    var name: String = String(ENGINE.SPECIES[game.enemy_species]["evolved" if guardian else "name"])
    screen_labels["EnemyName"].text = ("GUARDIAN  " if guardian else "WILD  ")+name
    screen_labels["EnemyHp"].text = "%s / %s HP" % [game.format_number(maxf(game.enemy_hp,0.0)),game.format_number(game.enemy_max_hp)]
    screen_labels["EncounterHint"].text = (
        "GUARDIAN FURY IN %ds • SHARDS + RELICS" % maxi(0,18-ceili(game.guardian_seconds))
        if guardian else "AUTO-BATTLE • GUARDIAN IN %d WAVES" % (10-(game.wave-1)%10))
    screen_labels["EncounterHint"].add_theme_color_override("font_color",GOLD if guardian else GREEN)
    for i in range(stage_steps.size()):
        stage_steps[i].color = GOLD if guardian else (GREEN if i <= (game.wave-1)%10 else Color("#3c5961"))
    var fraction: float = clampf(game.enemy_hp/maxf(game.enemy_max_hp,1.0),0.0,1.0)
    threat_bar.size.x = 226.0*fraction
    threat_bar.color = GOLD if guardian else CORAL
    ward_bar.size.x = 784.0*clampf(game.ward/maxf(game.max_ward(),1.0),0.0,1.0)
    screen_labels["FieldStatus"].text = "WARD  %s / %s" % [game.format_number(game.ward),game.format_number(game.max_ward())]
    screen_labels["DamageReadout"].text = ("CRIT! " if game.recent_critical else "HIT  ")+game.format_number(game.recent_hit) if game.damage_flash > 0.0 else (
        "COMBO x%d" % game.combo_hits if game.combo_hits >= 2 else "PACK DPS  "+game.format_number(game.total_dps()))
    screen_labels["PackDps"].text = "BONDS GROW WITH VICTORIES  •  %s" % ("FARMING" if game.repeat_wave else "ADVANCING")
    screen_labels["Notification"].text = game.last_notice
    screen_labels["Toast"].text = notice_message if toast_time > 0.0 else ""
    var stage: Dictionary = game.trail_info()
    screen_labels["JourneyStage"].text = "COMPLETE" if game.trail_complete() else "STEP %d / %d" % [game.trail_rank+1,game.TRAIL.size()]
    screen_labels["QuestName"].text = String(stage["name"])
    screen_labels["QuestHint"].text = String(stage["hint"])
    var current: int = mini(game.trail_progress(),int(stage["target"]))
    var target: int = int(stage["target"])
    screen_labels["QuestProgress"].text = "Opening journey finished" if game.trail_complete() else "PROGRESS  %d / %d" % [current,target]
    trail_fill.size.x = 251.0*clampf(float(current)/maxf(float(target),1.0),0.0,1.0)
    trail_button.disabled = not game.trail_ready()
    trail_button.text = "CLAIM!" if game.trail_ready() else ("DONE" if game.trail_complete() else "IN PROGRESS")
    screen_labels["QuestReward"].text = "Permanent +12% damage  •  %s G  •  %d Shards  •  %d Echoes" % [
        game.format_number(float(stage["gold"])),int(stage["shards"]),int(stage["echoes"])] if not game.trail_complete() else "Keep growing your pack and reaching new regions."
    for i in range(ENGINE.ORDER.size()):
        var kind: String = String(ENGINE.ORDER[i])
        var owned: bool = int(game.levels[kind]) > 0
        var evolved: bool = bool(game.evolved[kind])
        card_art[kind].texture = CREATURES.get_creature(kind,evolved)
        card_art[kind].modulate = Color.WHITE if owned else Color("#60717a")
        screen_labels["Name_"+kind].text = game.species_name(kind) if owned else String(ENGINE.SPECIES[kind]["name"])+" • LOCKED"
        card_details[kind].text = ("Lv %d  •  %s\nBond %d / 25  •  Gene %d" % [
            int(game.levels[kind]),String(ENGINE.SPECIES[kind]["element"]),int(game.bonds[kind]),int(game.gene[kind])]
            if owned else "Recruit with Gold\nEvolves at Lv 15 + 25 bonds")
        var price: float = game.purchase_cost(kind,batch if owned else 1)
        card_buy[kind].text = ("LEVEL +%d" % batch if owned else "RECRUIT")+" • "+game.format_number(price)+" G"
        card_buy[kind].disabled = game.gold < price
        var cooldown: float = float(game.ability_clock[kind])
        card_skill[kind].text = String(ENGINE.ABILITY_NAMES[kind]) + (" • %ds" % ceili(cooldown) if cooldown > 0 else " • READY")
        card_skill[kind].disabled = not owned or cooldown > 0
    var strong: String = "spriglet"
    var top: float = -1.0
    var side: Array[String] = []
    for kind in ENGINE.ORDER:
        if int(game.levels[kind]) > 0:
            var power: float = game.species_damage(kind)/game.attack_interval(kind)
            if power > top:
                top = power
                strong = String(kind)
    for kind in ENGINE.ORDER:
        if kind != strong and int(game.levels[kind]) > 0:
            side.append(String(kind))
    team_art[0].texture = CREATURES.get_creature(strong,bool(game.evolved[strong]))
    team_art[0].position.y = 183+(0.0 if game.ui_compact else sin(animation_clock*1.6)*2.0)
    for i in range(2):
        team_art[i+1].visible = i < side.size()
        if i < side.size():
            team_art[i+1].texture = CREATURES.get_creature(side[i],bool(game.evolved[side[i]]))
    enemy_art.texture = CREATURES.get_creature(game.enemy_species,guardian)
    enemy_art.position.x = 610 + (sin(animation_clock*34)*3.0 if game.damage_flash > 0.0 and not game.ui_compact else 0.0)
    _refresh_landscape()
    strike_button.disabled = not playing
    resonance_button.disabled = game.overdrive < 99.99 or game.overdrive_left > 0.0
    resonance_button.text = "RESONANCE READY" if game.overdrive >= 99.99 else "RESONANCE %d%%" % int(game.overdrive)
    repeat_button.text = "FARMING" if game.repeat_wave else "ADVANCE"
    speed_button.text = "SPEED %dx" % int(game.game_speed)
    _refresh_sidebar()

func _refresh_landscape() -> void:
    if game.region == _scene_key:
        return
    _scene_key = game.region
    match game.region:
        "meadow":
            var painted: Texture2D = SCENERY.forest()
            scenic_art.texture = painted if painted != null else load("res://assets/battle_meadow.png") as Texture2D
        "shore","sky":
            scenic_art.texture = load("res://assets/battle_shore.png") as Texture2D
        "embers":
            scenic_art.texture = load("res://assets/battle_woodland.png") as Texture2D

func _toast(message: String) -> void:
    notice_message = message
    toast_time = 2.3

func _on_notice(message: String) -> void:
    if message.contains("evolved") or message.contains("TRAIL COMPLETE") or message.contains("ASCENSION"):
        _toast(message)
    if is_node_ready() and screen_labels.has("Notification"):
        screen_labels["Notification"].text = message

func _strike() -> void:
    if playing:
        game.tap()
        _refresh()

func _buy_creature(kind: String) -> void:
    var quantity: int = batch if int(game.levels[kind]) > 0 else 1
    if game.buy_levels(kind,quantity):
        _toast("%s grows stronger!" % game.species_name(kind))
    _refresh()

func _use_skill(kind: String) -> void:
    if game.use_ability(kind):
        _toast(String(ENGINE.ABILITY_NAMES[kind])+" activated!")
    _refresh()

func _claim_trail() -> void:
    if game.claim_trail():
        game.save()
        _refresh()

func _upgrade(kind: String) -> void:
    if game.buy_module(kind):
        _toast(String(ENGINE.MODULE_NAMES[kind])+" upgraded!")
    _refresh()

func _hatch() -> void:
    if game.hatch_egg() != "":
        _switch_tab("NEST")
        game.save()
    _refresh()

func _claim_cache(choice: String) -> void:
    if game.claim_cache(choice):
        _switch_tab("NEST")
    _refresh()

func _equip(key: String) -> void:
    game.equip_relic(key)
    _refresh()

func _research(key: String) -> void:
    if game.buy_research(key):
        _toast("Permanent research acquired!")
    _refresh()

func _milestone(key: String) -> void:
    if game.claim_milestone(key):
        _switch_tab("LEGACY")
        game.save()
    _refresh()

func _travel(key: String) -> void:
    if game.select_region(key):
        _toast("New region: "+String(ENGINE.REGIONS[key]["name"]))
    _refresh()

func _stance(key: String) -> void:
    game.set_stance(key)
    _refresh()

func _mastery(kind: String,choice: String) -> void:
    game.specialize(kind,choice)
    _refresh()

func _request_ascension() -> void:
    if game.available_echoes() >= 1:
        ascend_dialog.popup_centered()

func _ascend() -> void:
    if game.ascend():
        game.save()
        _toast("ASCENSION! Your permanent power remains.")
        _refresh()

func _resonate() -> void:
    if game.activate_overdrive():
        _toast("WILD RESONANCE • DOUBLE PACK DAMAGE!")
    _refresh()

func _repeat() -> void:
    game.repeat_wave = not game.repeat_wave
    _refresh()

func _speed() -> void:
    game.game_speed = 2.0 if game.game_speed < 2.0 else 1.0
    _refresh()

func _toggle_batch() -> void:
    batch = 10 if batch == 1 else (25 if batch == 10 else 1)
    _refresh()

func _save() -> void:
    if game.save():
        _toast("Saved in this browser.")
    _refresh()

func _noop() -> void:
    pass
