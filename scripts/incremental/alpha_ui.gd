extends Control
## WILDBOUND — Creature Ascension Alpha
## One-screen arena with deep tabbed builds/collection/research/map/milestones.
const ENGINE = preload("res://scripts/incremental/v04_engine.gd")
const AUDIO = preload("res://scripts/audio.gd")
const BG := Color("#0c1724")
const CARD := Color("#172b3c")
const CARD_ALT := Color("#1b3744")
const BORDER := Color("#3c6472")
const INK := Color("#f5e9cc")
const GOLD := Color("#f6c978")
const JADE := Color("#91e1b8")
const DULL := Color("#a9bccb")
const LILAC := Color("#c8abe8")
const CORAL := Color("#edaa91")
const TABS: Array[String] = ["FORGE","NEST","PACK","RELICS","LEGACY","MAP","GOALS"]

var game
var running: bool = true
var batch: int = 1
var tab: String = "FORGE"
var clock: float = 0.0
var autosave_clock: float = 0.0
var visual_time: float = 0.0
var labels: Dictionary = {}
var buttons: Dictionary = {}
var portraits: Dictionary = {}
var ally_skills: Dictionary = {}
var enemy_portrait: TextureRect
var enemy_fill: ColorRect
var ward_fill: ColorRect
var arena_panel: Panel
var tab_column: VBoxContainer
var tab_scroll: ScrollContainer
var right_rows: Array[Dictionary] = []
var tab_buttons: Dictionary = {}
var damage_text: Label
var arena_art: TextureRect
var focus_buttons: Dictionary = {}
var resonance_fill: ColorRect
var resonance_button: Button
var _last_art_path: String = ""
var _last_visual_wave: int = -1
var fury_label: Label
var combo_label: Label
var mastery_cards: Dictionary = {}
var options_dialog: AcceptDialog
var motion_reduced: bool = false
var audio: Node
var help_dialog: AcceptDialog
var ascend_dialog: ConfirmationDialog

func _ready() -> void:
    game = ENGINE.new()
    game.initialize_alpha()
    game.load_save()
    motion_reduced = game.ui_compact
    game.notice.connect(_on_notice)
    audio = AUDIO.new()
    add_child(audio)
    audio.set("muted",true) # Audio opt-in, compatible with browser gesture rules.
    _layout()
    _build_help_dialog()
    _build_ascend_dialog()
    _build_options_dialog()
    _switch_tab("FORGE")
    _refresh()

func _process(delta: float) -> void:
    visual_time += delta
    if running:
        game.tick(delta)
    clock += delta
    autosave_clock += delta
    if clock > 0.16:
        clock = 0.0
        _refresh()
    if autosave_clock > 20.0:
        autosave_clock = 0.0
        game.save()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST and game != null:
        game.save()

func _unhandled_key_input(event: InputEvent) -> void:
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_SPACE:
            _tap()
            get_viewport().set_input_as_handled()
        elif event.keycode == KEY_ESCAPE:
            _toggle_running()
            get_viewport().set_input_as_handled()

func _style(fill: Color = CARD, edge: Color = BORDER, radius: int = 9) -> StyleBoxFlat:
    var style := StyleBoxFlat.new()
    style.bg_color = fill
    style.border_color = edge
    style.set_border_width_all(2)
    style.set_corner_radius_all(radius)
    style.content_margin_left = 10
    style.content_margin_right = 10
    style.content_margin_top = 9
    style.content_margin_bottom = 9
    return style

func _panel(parent: Node, name: String, area: Rect2, tint: Color = CARD) -> Panel:
    var p := Panel.new()
    p.name = name
    p.position = area.position
    p.size = area.size
    p.add_theme_stylebox_override("panel",_style(tint))
    parent.add_child(p)
    return p

func _label(parent: Node, name: String, content: String, area: Rect2, size: int = 16, color: Color = INK) -> Label:
    var label := Label.new()
    label.name = name
    label.position = area.position
    label.size = area.size
    label.text = content
    label.add_theme_font_size_override("font_size",size)
    label.add_theme_color_override("font_color",color)
    label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(label)
    labels[name] = label
    return label

func _button(parent: Node, name: String, content: String, area: Rect2, action: Callable, color: Color = Color("#2b6971")) -> Button:
    var button := Button.new()
    button.name = name
    button.text = content
    button.position = area.position
    button.size = area.size
    button.add_theme_font_size_override("font_size",14)
    button.add_theme_color_override("font_color",INK)
    button.add_theme_stylebox_override("normal",_style(color,Color("#638f91"),6))
    button.add_theme_stylebox_override("hover",_style(color.lightened(0.13),JADE,6))
    button.add_theme_stylebox_override("pressed",_style(color.darkened(0.09),JADE,6))
    button.add_theme_stylebox_override("disabled",_style(Color("#253945"),Color("#41515a"),6))
    button.add_theme_color_override("font_disabled_color",Color("#798f97"))
    button.focus_mode = Control.FOCUS_NONE
    button.pressed.connect(action)
    button.tooltip_text = content
    parent.add_child(button)
    buttons[name] = button
    return button

func _image(parent: Node, kind: String, area: Rect2) -> TextureRect:
    var pic := TextureRect.new()
    pic.position = area.position
    pic.size = area.size
    pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    pic.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    pic.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(pic)
    _apply_art(pic,kind)
    return pic

func _apply_art(pic: TextureRect, kind: String, is_enemy: bool = false) -> void:
    if not ENGINE.SPECIES.has(kind):
        return
    var evolution: bool = game.enemy_is_boss() if is_enemy else bool(game.evolved[kind])
    var path: String = "res://assets/%s%s_front.png" % [kind,"_evo" if evolution else ""]
    if pic.texture == null or pic.texture.resource_path != path:
        pic.texture = load(path) as Texture2D
    if not is_enemy:
        pic.modulate = Color("#e7ddff") if bool(game.rare[kind]) else Color.WHITE

func _bar(parent: Node, name: String, area: Rect2, color: Color) -> ColorRect:
    var bg := ColorRect.new()
    bg.position = area.position
    bg.size = area.size
    bg.color = BG
    bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(bg)
    var fill := ColorRect.new()
    fill.name = name
    fill.position = area.position + Vector2(2,2)
    fill.size = area.size - Vector2(4,4)
    fill.color = color
    fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(fill)
    return fill

func _layout() -> void:
    var background := ColorRect.new()
    background.name = "Backdrop"
    background.color = BG
    background.position = Vector2.ZERO
    background.size = Vector2(1280,720)
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)

    _panel(self,"Header",Rect2(12,10,1256,65),CARD_ALT)
    _label(self,"Logo","WILDBOUND",Rect2(29,17,270,38),31,JADE)
    _label(self,"Sublogo","CREATURE ASCENSION  •  ALPHA 0.4",Rect2(31,51,280,15),11,DULL)
    _label(self,"Resources","",Rect2(367,18,628,44),19,GOLD)
    _button(self,"Options","OPTIONS",Rect2(1000,25,83,34),_show_options,Color("#3e5c77"))
    _button(self,"Guide","GUIDE",Rect2(1090,25,78,34),_show_help,Color("#3e5c77"))
    _button(self,"Sound","SOUND OFF",Rect2(1176,25,76,34),_toggle_audio,Color("#3e5c77"))

    _panel(self,"PackPane",Rect2(12,86,318,565))
    _label(self,"PackTitle","YOUR WILDBOUND PACK",Rect2(28,101,282,29),20,JADE)
    _label(self,"PackHint","Level creatures • evolve • unlock abilities",Rect2(28,132,282,20),12,DULL)

    for i in range(3):
        var kind: String = String(ENGINE.ORDER[i])
        var y: float = 157.0 + 137.0 * float(i)
        _panel(self,"PackCard_"+kind,Rect2(26,y,291,130),CARD_ALT)
        portraits[kind] = _image(self,kind,Rect2(30,y+6,98,87))
        _label(self,"name_"+kind,"",Rect2(126,y+10,179,23),17,INK)
        _label(self,"stats_"+kind,"",Rect2(126,y+38,180,40),12,DULL)
        _button(self,"buy_"+kind,"",Rect2(126,y+77,177,28),_buy_creature.bind(kind))
        ally_skills[kind] = _button(self,"skill_"+kind,"",Rect2(37,y+105,267,23),_ability.bind(kind),Color("#425b84"))
        ally_skills[kind].add_theme_font_size_override("font_size",12)
    _label(self,"PackFooter","TACTICAL FORMATION",Rect2(30,568,280,20),13,JADE)
    for i in range(ENGINE.STANCES.size()):
        var stance_name: String = ENGINE.STANCES[i]
        var stance_button: Button = _button(self,"stance_"+stance_name,stance_name.to_upper(),
            Rect2(29+72*i,592,68,30),_set_stance.bind(stance_name),Color("#3b6370"))
        stance_button.add_theme_font_size_override("font_size",10)
        focus_buttons[stance_name] = stance_button
    _label(self,"TacticsNote","",Rect2(29,626,285,18),10,DULL)

    arena_panel = _panel(self,"ArenaPane",Rect2(340,86,528,565),Color("#19383c"))
    _label(self,"RegionTitle","",Rect2(362,101,482,28),22,JADE)
    _label(self,"WaveTitle","",Rect2(362,134,480,24),17,GOLD)
    fury_label = _label(self,"FuryCountdown","",Rect2(705,153,133,18),12,CORAL)
    _panel(self,"EnemyArena",Rect2(364,169,480,281),Color("#244b4a"))
    arena_art = TextureRect.new()
    arena_art.name = "ArenaIllustration"
    arena_art.position = Vector2(367,172)
    arena_art.size = Vector2(474,274)
    arena_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    arena_art.stretch_mode = TextureRect.STRETCH_SCALE
    arena_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    arena_art.modulate = Color(0.63,0.72,0.75,0.62)
    arena_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(arena_art)
    var arena_gradient: ColorRect = ColorRect.new()
    arena_gradient.color = Color(0.03,0.08,0.13,0.24)
    arena_gradient.position = Vector2(367,172)
    arena_gradient.size = Vector2(474,274)
    arena_gradient.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(arena_gradient)
    _label(self,"EnemyName","",Rect2(385,183,410,28),19,INK)
    enemy_portrait = _image(self,"brinlet",Rect2(505,201,209,160))
    damage_text = _label(self,"DamageText","",Rect2(382,363,443,22),14,CORAL)
    combo_label = _label(self,"ComboCounter","",Rect2(661,365,169,22),14,LILAC)
    _label(self,"EnemyHp","",Rect2(382,391,443,22),14,INK)
    enemy_fill = _bar(self,"EnemyBar",Rect2(381,416,444,14),CORAL)
    _button(self,"Tap","STRIKE  •  CLICK / SPACE",Rect2(385,452,439,44),_tap,Color("#946342"))
    _label(self,"WardText","",Rect2(363,510,480,23),15,INK)
    ward_fill = _bar(self,"WardBar",Rect2(362,537,480,18),JADE)
    _label(self,"DpsText","",Rect2(363,570,475,23),15,GOLD)
    _label(self,"ArenaFooter","",Rect2(363,591,482,20),11,DULL)
    resonance_fill = _bar(self,"ResonanceBar",Rect2(364,617,262,12),LILAC)
    resonance_button = _button(self,"Resonance","RESONANCE • CHARGE",Rect2(634,609,199,32),_activate_resonance,Color("#684878"))
    resonance_button.add_theme_font_size_override("font_size",12)

    _panel(self,"UpgradePane",Rect2(879,86,389,565))
    _label(self,"UpgradesTitle","THE SANCTUARY",Rect2(896,101,354,28),20,JADE)
    for i in range(TABS.size()):
        var current_tab: String = TABS[i]
        var tx: float = 891.0 + float(i)*51.0
        var b: Button = _button(self,"tab_"+current_tab,current_tab,Rect2(tx,134,49,31),_switch_tab.bind(current_tab),Color("#395874"))
        b.add_theme_font_size_override("font_size",9)
        tab_buttons[current_tab] = b
    tab_scroll = ScrollContainer.new()
    tab_scroll.name = "UpgradeScroll"
    tab_scroll.position = Vector2(897,177)
    tab_scroll.size = Vector2(352,455)
    tab_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    add_child(tab_scroll)
    tab_column = VBoxContainer.new()
    tab_column.name = "UpgradeCards"
    tab_column.custom_minimum_size = Vector2(329,0)
    tab_column.add_theme_constant_override("separation",9)
    tab_scroll.add_child(tab_column)

    _panel(self,"Footer",Rect2(12,663,1256,46),CARD_ALT)
    _label(self,"Notice","",Rect2(26,676,491,28),13,INK)
    _button(self,"AutoBuy","AUTO BUY",Rect2(522,670,124,32),_toggle_auto_buy)
    _button(self,"AutoSkills","AUTO SKILLS",Rect2(653,670,129,32),_toggle_auto_skills)
    _button(self,"Repeat","REPEAT OFF",Rect2(789,670,125,32),_toggle_repeat)
    _button(self,"Batch","BUY x1",Rect2(921,670,94,32),_toggle_batch)
    _button(self,"Speed","1x SPEED",Rect2(1022,670,111,32),_toggle_speed)
    _button(self,"Save","SAVE",Rect2(1140,670,112,32),_save)

func MINT_COLOR() -> Color:
    return DULL

func _new_card(title: String, description: String, button_text: String, fn: Callable, min_height: float = 102.0) -> Dictionary:
    var card := PanelContainer.new()
    card.custom_minimum_size = Vector2(326,min_height)
    card.add_theme_stylebox_override("panel",_style(CARD_ALT,Color("#426f7b"),7))
    tab_column.add_child(card)
    var content := VBoxContainer.new()
    content.add_theme_constant_override("separation",3)
    card.add_child(content)
    var name_label := Label.new()
    name_label.text = title
    name_label.add_theme_font_size_override("font_size",16)
    name_label.add_theme_color_override("font_color",JADE)
    content.add_child(name_label)
    var info := Label.new()
    info.text = description
    info.add_theme_font_size_override("font_size",12)
    info.add_theme_color_override("font_color",DULL)
    info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    content.add_child(info)
    var button := Button.new()
    button.text = button_text
    button.custom_minimum_size = Vector2(301,27)
    button.add_theme_font_size_override("font_size",13)
    button.add_theme_color_override("font_color",INK)
    button.add_theme_stylebox_override("normal",_style(Color("#295f66"),Color("#668f93"),5))
    button.add_theme_stylebox_override("hover",_style(Color("#398276"),JADE,5))
    button.add_theme_stylebox_override("disabled",_style(Color("#293941"),Color("#405662"),5))
    button.add_theme_color_override("font_disabled_color",Color("#7d969d"))
    button.focus_mode = Control.FOCUS_NONE
    button.pressed.connect(fn)
    content.add_child(button)
    return {"title":name_label,"info":info,"button":button}

func _switch_tab(next: String) -> void:
    tab = next
    for key in tab_buttons:
        tab_buttons[key].modulate = Color.WHITE if key == tab else Color("#a8c4ca")
    for child in tab_column.get_children():
        tab_column.remove_child(child)
        child.queue_free()
    right_rows.clear()
    tab_scroll.scroll_vertical = 0
    match tab:
        "FORGE":
            for kind in ENGINE.MODULES + ENGINE.EXTRA_MODULES:
                var card: Dictionary = _new_card(ENGINE.MODULE_NAMES[kind],"", "Buy",_purchase_module.bind(kind))
                card["key"] = kind
                card["mode"] = "module"
                right_rows.append(card)
        "NEST":
            for camp_key in ["nest","pack","altar"]:
                var camp_row: Dictionary = _new_card("CAMP • "+String(ENGINE.CAMP_UPGRADES[camp_key]),"",
                    "Build",_buy_camp.bind(camp_key),103)
                camp_row["mode"] = "camp"
                camp_row["key"] = camp_key
                right_rows.append(camp_row)
            var egg: Dictionary = _new_card("The Moonlit Nest","Earn Nest Shards in combat and from guardian kills. Eggs recruit new species or strengthen bloodlines.","Hatch Egg",_hatch,130)
            egg["mode"] = "hatch"
            right_rows.append(egg)
            for kind in ENGINE.ORDER:
                var row: Dictionary = _new_card(String(ENGINE.SPECIES[kind]["name"])+" Lineage","", "Inspect",_inspect_species.bind(kind))
                row["mode"] = "lineage"
                row["key"] = kind
                right_rows.append(row)
        "PACK":
            var guide: Dictionary = _new_card("BOND MASTERY","Each evolved creature with 25 bonds can choose a lasting specialization. The first choice is free; switching costs 12 earned Nest Shards.","FIELD GUIDE",_show_help,121)
            guide["mode"] = "mastery_guide"
            right_rows.append(guide)
            for creature in ENGINE.ORDER:
                for choice in ENGINE.SPECIALIZATION_ORDER[creature]:
                    var mastery_data: Dictionary = ENGINE.SPECIALIZATIONS[creature][choice]
                    var card: Dictionary = _new_card(String(ENGINE.SPECIES[creature]["name"])+" • "+String(mastery_data["name"]),
                        "","Choose",_set_mastery.bind(creature,choice),113)
                    card["mode"] = "mastery"
                    card["key"] = creature
                    card["choice"] = choice
                    right_rows.append(card)
        "RELICS":
            var vault: Dictionary = _new_card("RELIC VAULT","Guardian kills yield permanent relics. You may equip any two. Duplicates upgrade their bonuses.","VIEW FIELD GUIDE",_show_help,118)
            vault["mode"] = "vault"
            right_rows.append(vault)
            for relic in ENGINE.RELIC_ORDER:
                var item: Dictionary = _new_card(String(ENGINE.RELICS[relic]["name"]),"","Equip",_equip_relic.bind(relic))
                item["mode"] = "relic"
                item["key"] = relic
                right_rows.append(item)
        "LEGACY":
            var prestige: Dictionary = _new_card("ASCEND THE WILDS","", "Ascend",_request_ascend,124)
            prestige["mode"] = "ascend"
            right_rows.append(prestige)
            for kind in ["might","heart"] + ENGINE.EXTRA_RESEARCH:
                var card: Dictionary = _new_card(ENGINE.RESEARCH_NAMES[kind],"", "Research",_purchase_research.bind(kind))
                card["mode"] = "research"
                card["key"] = kind
                right_rows.append(card)
        "MAP":
            var difficulty: Dictionary = _new_card("Overclock Challenge","Elite enemies gain extra health/damage in return for 2.4x Gold. Switch any time.","Toggle",_toggle_overclock)
            difficulty["mode"] = "overclock"
            right_rows.append(difficulty)
            for key in ENGINE.REGION_ORDER:
                var region_card: Dictionary = _new_card(String(ENGINE.REGIONS[key]["name"]),"", "Travel",_change_region.bind(key))
                region_card["mode"] = "region"
                region_card["key"] = key
                right_rows.append(region_card)
        "GOALS":
            var cache_overview: Dictionary = _new_card("WILD CACHES","Every 25 cleared waves grants a choice of valuable rewards. Unclaimed caches survive Ascension.","Collect",_show_help,118)
            cache_overview["mode"] = "cache_guide"
            right_rows.append(cache_overview)
            for reward_key in ENGINE.CACHE_ORDER:
                var cache: Dictionary = _new_card(String(ENGINE.CACHE_CHOICES[reward_key]["name"]),"",
                    "Claim",_claim_cache.bind(reward_key),104)
                cache["mode"] = "cache"
                cache["key"] = reward_key
                right_rows.append(cache)
            for contract in ENGINE.CONTRACTS:
                var task: Dictionary = _new_card("CONTRACT • "+String(ENGINE.CONTRACT_TITLES[contract]),"",
                    "Collect",_claim_contract.bind(contract),108)
                task["mode"] = "contract"
                task["key"] = contract
                right_rows.append(task)
            var stats: Dictionary = _new_card("Adventure Record","", "Pause / Resume",_toggle_running)
            stats["mode"] = "record"
            right_rows.append(stats)
            for key in ENGINE.MILESTONE_ORDER:
                var goal: Dictionary = _new_card(String(ENGINE.MILESTONES[key]["title"]),"", "Claim",_claim.bind(key))
                goal["mode"] = "goal"
                goal["key"] = key
                right_rows.append(goal)
    _refresh_right()

func _refresh() -> void:
    if game == null:
        return
    labels["Resources"].text = "Gold %s     Echoes %d     Nest Shards %d     Ascensions %d" % [
        game.format_number(game.gold),game.echoes,game.nests,game.ascensions]
    labels["RegionTitle"].text = String(ENGINE.REGIONS[game.region]["name"]).to_upper()
    var status: String = game.enemy_mutator()
    labels["WaveTitle"].text = "WAVE %d  •  %s  •  Best %d" % [
        game.wave,status.to_upper() if status != "" else "WILD",game.best_wave]
    var bg_path: String = "res://assets/battle_meadow.png"
    if game.region == "shore":
        bg_path = "res://assets/battle_shore.png"
    elif game.region == "embers":
        bg_path = "res://assets/battle_woodland.png"
    elif game.region == "sky":
        bg_path = "res://assets/battle_shore.png"
    if bg_path != _last_art_path:
        arena_art.texture = load(bg_path) as Texture2D
        _last_art_path = bg_path
    labels["EnemyName"].text = "%s • %s" % [
        String(ENGINE.SPECIES[game.enemy_species]["evolved" if game.enemy_is_boss() else "name"]),
        String(ENGINE.SPECIES[game.enemy_species]["element"])]
    _apply_art(enemy_portrait,game.enemy_species,true)
    fury_label.text = ("FURY • %ds" % maxi(0,18-ceili(game.guardian_seconds))) if game.enemy_is_boss() and not game.guardian_enraged else ("FURY ACTIVE!" if game.enemy_is_boss() else "")
    var visual_bounce: float = 0.0 if motion_reduced else sin(visual_time*2.3)*3.0
    enemy_portrait.position.y = 199.0 + visual_bounce
    enemy_portrait.modulate = Color("#ffddbb") if game.damage_flash > 0.0 and not motion_reduced else Color.WHITE
    combo_label.text = ("COMBO x%d" % game.combo_hits) if game.combo_hits >= 2 else ""
    damage_text.text = "%s  %s" % ["CRITICAL" if game.recent_critical else "HIT",
        game.format_number(game.recent_hit)] if game.damage_flash > 0.0 else (
        "Guardian battle • higher rewards" if game.enemy_is_boss() else "Element cycle: Grove > Tide > Ember > Grove")
    labels["EnemyHp"].text = "Enemy  %s / %s HP" % [
        game.format_number(maxf(game.enemy_hp,0.0)),game.format_number(game.enemy_max_hp)]
    enemy_fill.size.x = 440.0*clampf(game.enemy_hp/maxf(game.enemy_max_hp,1.0),0.0,1.0)
    labels["WardText"].text = "PACK SANCTUARY WARD  %s / %s" % [
        game.format_number(game.ward),game.format_number(game.max_ward())]
    ward_fill.size.x = 476.0*clampf(game.ward/maxf(game.max_ward(),1.0),0.0,1.0)
    labels["DpsText"].text = "Pack DPS %s   •   Tap %s" % [
        game.format_number(game.total_dps()),game.format_number(maxf(2.0,game.total_dps()*0.53))]
    labels["ArenaFooter"].text = "%s • %s • Streak %d • Caches %d" % [
        "OVERCLOCK" if game.overclock else "EXPEDITION",
        "FARMING" if game.repeat_wave else "ADVANCING",game.current_streak,game.caches_pending]
    resonance_fill.size.x = 258.0 * clampf(game.overdrive / 100.0,0.0,1.0)
    resonance_button.disabled = game.overdrive < 99.99 or game.overdrive_left > 0.0
    resonance_button.text = ("RESONANCE • %.0fs" % game.overdrive_left) if game.overdrive_left > 0.0 else (
        "UNLEASH • READY" if game.overdrive >= 99.99 else ("RESONANCE  %d%%" % int(game.overdrive)))
    for stance_key in focus_buttons:
        focus_buttons[stance_key].modulate = Color.WHITE if game.stance == stance_key else Color("#91a4b3")
    labels["TacticsNote"].text = game.stance_description()
    for creature in ENGINE.ORDER:
        var label: Label = labels["name_"+creature]
        label.tooltip_text = "Mastery: "+game.spec_name(creature)
    var claimable: bool = game.caches_pending > 0
    for contract_key in ENGINE.CONTRACTS:
        if game.contract_ready(contract_key):
            claimable = true
            break
    if not claimable:
        for goal_key in ENGINE.MILESTONE_ORDER:
            if not game.milestones_claimed.has(goal_key) and game.milestone_progress(goal_key) >= int(ENGINE.MILESTONES[goal_key]["goal"]):
                claimable = true
                break
    tab_buttons["GOALS"].modulate = GOLD if claimable else (Color.WHITE if tab == "GOALS" else Color("#a8c4ca"))
    tab_buttons["NEST"].modulate = JADE if game.nests >= game.hatch_cost() and tab != "NEST" else (Color.WHITE if tab == "NEST" else Color("#a8c4ca"))
    var mastery_ready: bool = false
    for creature in ENGINE.ORDER:
        if game.can_specialize(creature) and game.specialization[creature] == "":
            mastery_ready = true
    tab_buttons["PACK"].modulate = GOLD if mastery_ready and tab != "PACK" else (Color.WHITE if tab == "PACK" else Color("#a8c4ca"))
    for kind in ENGINE.ORDER:
        var level: int = int(game.levels[kind])
        var owned: bool = level > 0
        var rare_text: String = " ✦" if bool(game.rare[kind]) else ""
        labels["name_"+kind].text = (game.species_name(kind)+rare_text) if owned else (String(ENGINE.SPECIES[kind]["name"])+" • Locked")
        labels["stats_"+kind].text = "Lv %d • %s\nBond %d • Genes %d" % [
            level,String(ENGINE.SPECIES[kind]["element"]),
            int(game.bonds[kind]),int(game.gene[kind])] if owned else "Recruit with Gold\nor hatch a Nest Egg"
        _apply_art(portraits[kind],kind)
        portraits[kind].modulate = Color("#bbbec8") if not owned else (Color("#dbbeff") if bool(game.rare[kind]) else Color.WHITE)
        var price: float = game.purchase_cost(kind,batch if owned else 1)
        buttons["buy_"+kind].text = ("%s   %s G" % [
            "Level +"+str(batch) if owned else "Recruit",
            game.format_number(price)])
        buttons["buy_"+kind].disabled = game.gold < price
        var available: float = float(game.ability_clock[kind])
        ally_skills[kind].text = "%s  %s" % [
            String(ENGINE.ABILITY_NAMES[kind]),
            ("%ds" % ceili(available)) if available > 0.0 else "READY"]
        ally_skills[kind].disabled = not owned or available > 0.0
    labels["PackFooter"].text = "PACK TACTIC • "+game.stance.to_upper()
    labels["Notice"].text = game.last_notice
    buttons["AutoBuy"].text = "AUTO BUY %s" % ("ON" if game.auto_buy else "OFF")
    buttons["AutoBuy"].disabled = int(game.research["automation"]) < 1
    buttons["AutoSkills"].text = "SKILLS %s" % ("AUTO" if game.auto_skills else "MANUAL")
    buttons["AutoSkills"].disabled = int(game.research["instinct"]) < 1
    buttons["Repeat"].text = "REPEAT %s" % ("ON" if game.repeat_wave else "OFF")
    buttons["Batch"].text = "BUY x%d" % batch
    buttons["Speed"].text = "%sx SPEED" % str(int(game.game_speed))
    buttons["Save"].text = "SAVE %s" % ("PAUSED" if not running else "NOW")
    buttons["Sound"].text = "SOUND OFF" if bool(audio.get("muted")) else "SOUND ON"
    _refresh_right()

func _refresh_right() -> void:
    if game == null:
        return
    for row in right_rows:
        var info: Label = row["info"]
        var action: Button = row["button"]
        var mode: String = String(row["mode"])
        var key: String = String(row.get("key",""))
        match mode:
            "mastery_guide":
                info.text = "Choose one lasting trait per evolved creature. Your first mastery is free and remains after Ascension."
                action.text = "READ FIELD GUIDE"
                action.disabled = false
            "mastery":
                var choice: String = String(row["choice"])
                var traits: Dictionary = ENGINE.SPECIALIZATIONS[key]
                var chosen: String = String(game.specialization[key])
                var unlocked: bool = game.can_specialize(key)
                var change_cost: int = 12 if chosen != "" else 0
                info.text = String(traits[choice]["desc"]) + ("\nNeeds Level 15 evolution + 25 bonds." if not unlocked else "")
                action.text = "SELECTED" if chosen == choice else ("CHANGE • 12 SHARDS" if chosen != "" else "CHOOSE MASTERY")
                action.disabled = not unlocked or chosen == choice or game.nests < change_cost
            "cache_guide":
                info.text = "%d unopened caches • %d already claimed. Clear a new wave 25/50/75/... to receive another." % [
                    game.caches_pending,game.caches_claimed]
                action.text = "LEARN ABOUT CACHES"
                action.disabled = false
            "cache":
                var options: Dictionary = ENGINE.CACHE_CHOICES[key]
                info.text = String(options["desc"])
                action.text = "TAKE "+String(options["name"]).to_upper() if game.caches_pending > 0 else "NO CACHES AVAILABLE"
                action.disabled = game.caches_pending < 1
            "contract":
                var progress: int = game.contract_progress(key)
                var target: int = game.contract_target(key)
                var reward: Dictionary = game.contract_rewards(key)
                info.text = "%s • %d / %d\nReward: %s Gold + %d shards%s" % [
                    String(ENGINE.CONTRACT_DESCRIPTIONS[key]),mini(progress,target),target,
                    game.format_number(float(reward["gold"])),int(reward["shards"]),
                    (" + %d Echo" % int(reward["echoes"])) if int(reward["echoes"]) > 0 else ""]
                action.text = "CLAIM REWARD" if game.contract_ready(key) else "IN PROGRESS"
                action.tooltip_text = "Repeatable objective • complete to receive earned Gold and Nest Shards."
                action.disabled = not game.contract_ready(key)
            "camp":
                var rank: int = int(game.camp[key])
                var cost: int = game.camp_cost(key)
                info.text = "Rank %d • %s" % [rank,String(ENGINE.CAMP_DESCRIPTIONS[key])]
                action.text = "BUILD • %d SHARDS" % cost
                action.tooltip_text = "Permanent camp improvement. Retained after Ascension."
                action.disabled = game.nests < cost
            "vault":
                info.text = "Relic drops: %d • Equipped: %d / 2
They persist through Ascension and grow with duplicates." % [game.relic_drops,game.equipped_relics.size()]
                action.text = "READ GEAR RULES"
                action.disabled = false
            "relic":
                var rank: int = int(game.relic_ranks[key])
                var owned: bool = rank > 0
                var equipped: bool = game.equipped_relics.has(key)
                info.text = "Rank %d • %s" % [rank,String(ENGINE.RELICS[key]["description"])]
                action.text = "UNEQUIP" if equipped else ("EQUIP RELIC" if owned else "UNDISCOVERED")
                action.disabled = not owned or (not equipped and game.equipped_relics.size() >= 2)
            "ascend":
                var earned: int = game.available_echoes()
                info.text = "Unlock at wave 20. Reset Gold, levels and field modules.
Keep companions, evolution, genes, bonds, regions and research."
                action.text = "ASCEND  •  +%d ECHOES" % earned
                action.disabled = earned < 1
            "module":
                var rank: int = int(game.modules[key])
                var cost: float = game.module_cost(key)
                var effects: Dictionary = {
                    "power":"+13% attack damage per rank",
                    "guard":"+22 Ward capacity per rank",
                    "tempo":"+6% attack speed per rank",
                    "crit":"+3.5% critical chance per rank",
                    "bounty":"+15% Gold per rank",
                    "recovery":"Sanctuary health regeneration",
                    "pierce":"+20% damage vs Guardians"}
                info.text = "Rank %d • %s" % [rank,String(effects.get(key,""))]
                action.text = "Upgrade • %s Gold" % game.format_number(cost)
                action.disabled = game.gold < cost
            "hatch":
                info.text = "Shards %d / %d • Hatched %d\nRare pity: %d / 10 • Duplicate eggs strengthen genes." % [
                    game.nests,game.hatch_cost(),game.eggs_hatched,game.rare_pity]
                action.text = "HATCH EGG  •  %d SHARDS" % game.hatch_cost()
                action.disabled = game.nests < game.hatch_cost()
            "lineage":
                info.text = "Genes %d • %s • %s" % [
                    int(game.gene[key]),"SHIMMER FOUND" if bool(game.rare[key]) else "Standard",
                    "Evolved" if bool(game.evolved[key]) else "Not yet evolved"]
                action.text = "VIEW LINEAGE"
                action.disabled = false
            "research":
                var rank: int = int(game.research[key])
                var cost: int = game.research_cost(key)
                var desc: Dictionary = {
                    "might":"+22% pack damage/rank",
                    "heart":"+18% Sanctuary Ward/rank",
                    "bounty":"+12% Gold income/rank",
                    "speed":"+8% attack power, +3% speed/rank",
                    "scavenge":"Extra Nest Shards and Echo bonuses",
                    "incubator":"+rare egg chance, +4% Ward/rank",
                    "automation":"Unlock automatic Gold spending",
                    "instinct":"Unlock automatic creature abilities"}
                info.text = "Rank %d • %s" % [rank,String(desc.get(key,"Permanent bonus"))]
                action.text = "RESEARCH  •  %d ECHOES" % cost
                action.disabled = game.echoes < cost
            "overclock":
                info.text = "2x enemy health • 1.65x enemy damage\n2.4x Gold rewards while active."
                action.text = "OVERCLOCK  %s" % ("ENABLED" if game.overclock else "DISABLED")
                action.disabled = false
            "region":
                var data: Dictionary = ENGINE.REGIONS[key]
                var available: bool = game.region_available(key)
                info.text = "%s • %.1fx foe HP • %.1fx Gold\nUnlock at best wave %d" % [
                    String(data["element"]),float(data["hp"]),float(data["gold"]),int(data["unlock"])]
                action.text = "EXPLORING" if game.region == key else ("TRAVEL" if available else "LOCKED")
                action.disabled = not available or game.region == key
            "record":
                info.text = "Wins %d • Guardians %d • Contracts %d\nEggs %d • Ascensions %d • Resonances %d" % [
                    game.kills,game.guardians_won,game.contracts_claimed,game.eggs_hatched,
                    game.ascensions,game.overdrive_used]
                action.text = "RESUME" if not running else "PAUSE COMBAT"
                action.disabled = false
            "goal":
                var data: Dictionary = ENGINE.MILESTONES[key]
                var progress: int = game.milestone_progress(key)
                var target: int = int(data["goal"])
                var claimed: bool = game.milestones_claimed.has(key)
                info.text = "%s • %d / %d" % [String(data["desc"]),mini(progress,target),target]
                action.text = "CLAIMED" if claimed else (
                    "CLAIM +%d Echoes / +%d Shards" % [int(data["echoes"]),int(data["shards"])])
                action.disabled = claimed or progress < target

func _build_help_dialog() -> void:
    help_dialog = AcceptDialog.new()
    help_dialog.title = "WILDBOUND • Field Guide"
    help_dialog.dialog_text = (
        "WELCOME TO THE WILDS\n"
        + "Your creatures battle automatically. Click STRIKE or press Space to help.\n\n"
        + "1. PACK: Spend Gold to recruit and level Spriglet, Brinlet and Cindlet.\n"
        + "2. ABILITIES: Click each creature's ability when ready. Bloom heals,\n"
        + "   Surge bursts enemies, and Frenzy empowers your whole pack.\n"
        + "3. FORGE: Build your run with damage, defense, speed, criticals,\n"
        + "   Gold, healing and guardian-breaking upgrades.\n"
        + "4. NEST: Guardians drop Nest Shards. Hatch eggs for recruits,\n"
        + "   permanent genes and rare Shimmer creatures.\n"
        + "5. EVOLVE: Level 15 plus 25 bond victories unlocks a new form.\n"
        + "   RELICS: Guardian drops grant gear. Equip 2 permanent relics.\n"
        + "6. LEGACY: Ascend from wave 20 onward for permanent Echoes.\n"
        + "   Creature ownership, evolution, genes, bonds and research persist.\n"
        + "7. AUTOMATE: Legacy research unlocks auto-buy and auto-skills.\n"
        + "8. MAP: Discover harder regions or enable Overclock for more Gold.\n"
        + "9. GOALS: Claim milestones and repeatable contracts.\n"
        + "10. FORMATIONS: Balanced, Feral, Bulwark or Forager tactics.\n"
        + "11. RESONANCE: Fill the purple bar from victories and taps,\n"
        + "   then unleash a 12-second 2x damage burst.\n"
        + "12. CAMP: Spend Nest Shards on permanent sanctuary buildings.\n"
        + "13. PACK: After evolution, choose a specialization for each line.\n"
        + "14. CACHES: Every 25 new cleared waves grants a reward choice.\n"
        + "15. COMBO: Click rhythmically to multiply your manual strikes.\n\n"
        + "Grove beats Tide, Tide beats Ember, Ember beats Grove.\n"
        + "Progress autosaves every 20 seconds in this browser. Offline Gold\n"
        + "is capped at 4 hours, with no simulated waves or premium rewards.\n"
        + "Everything is earn-only; there are no paid eggs or purchases."
    )
    help_dialog.ok_button_text = "BACK TO THE WILDS"
    add_child(help_dialog)

func _show_help() -> void:
    help_dialog.popup_centered(Vector2i(720,560))

func _build_ascend_dialog() -> void:
    ascend_dialog = ConfirmationDialog.new()
    ascend_dialog.title = "Begin an Ascension?"
    ascend_dialog.confirmed.connect(_confirm_ascend)
    add_child(ascend_dialog)

func _request_ascend() -> void:
    if game.available_echoes() < 1:
        return
    ascend_dialog.dialog_text = (
        "Earn %d Echoes and restart your expedition at wave 1.\n\n"
        + "Gold, creature levels and temporary modules reset.\n"
        + "Creature ownership, evolutions, genes, bonds and research persist.\n\n"
        + "Are you ready to Ascend?") % game.available_echoes()
    ascend_dialog.popup_centered(Vector2i(520,280))

func _confirm_ascend() -> void:
    game.save()
    if game.ascend():
        audio.call("play_fx","victory")
        game.save()
        _switch_tab("LEGACY")
    _refresh()

func _toggle_audio() -> void:
    var was_muted: bool = bool(audio.get("muted"))
    audio.call("toggle_mute")
    if was_muted:
        audio.call("play_track","battle")
        audio.call("play_fx","confirm")
    _refresh()

func _equip_relic(key: String) -> void:
    if game.equip_relic(key):
        audio.call("play_fx","confirm")
        game.save()
    _refresh()

func _set_stance(next: String) -> void:
    if game.set_stance(next):
        game.save()
    _refresh()

func _activate_resonance() -> void:
    if game.activate_overdrive():
        audio.call("play_fx","victory")
    _refresh()

func _claim_contract(key: String) -> void:
    if game.claim_contract(key):
        audio.call("play_fx","victory")
        game.save()
    _refresh()

func _buy_camp(key: String) -> void:
    if game.buy_camp_upgrade(key):
        audio.call("play_fx","confirm")
        game.save()
    _refresh()

func _set_mastery(kind: String, choice: String) -> void:
    if game.specialize(kind,choice):
        audio.call("play_fx","evolve")
        game.save()
    _refresh()

func _claim_cache(choice: String) -> void:
    if game.claim_cache(choice):
        audio.call("play_fx","capture")
        game.save()
    _refresh()

func _build_options_dialog() -> void:
    options_dialog = AcceptDialog.new()
    options_dialog.title = "Wildbound • Accessibility & Controls"
    options_dialog.dialog_text = "Enable reduced animation to stop creature bobbing and hit flashes.\nYour progression is autosaved every 20 seconds.\nSpace: strike • Escape: pause • Click buttons to upgrade."
    var toggle := CheckButton.new()
    toggle.name = "ReduceMotion"
    toggle.text = "Reduce animations and hit flashes"
    toggle.set_pressed_no_signal(motion_reduced)
    toggle.position = Vector2(18,145)
    toggle.toggled.connect(_toggle_reduced_motion)
    options_dialog.add_child(toggle)
    add_child(options_dialog)

func _show_options() -> void:
    options_dialog.popup_centered(Vector2i(580,270))

func _toggle_reduced_motion(value: bool) -> void:
    motion_reduced = value
    game.ui_compact = value
    game.save()
    _refresh()

func _buy_creature(kind: String) -> void:
    var owned: bool = int(game.levels[kind]) > 0
    if game.buy_levels(kind,batch if owned else 1):
        audio.call("play_fx","confirm")
        game.last_notice = "%s strengthened! Total pack DPS %s." % [
            game.species_name(kind),game.format_number(game.total_dps())]
    _refresh()

func _ability(kind: String) -> void:
    if game.use_ability(kind):
        audio.call("play_fx","confirm")
        _refresh()

func _purchase_module(kind: String) -> void:
    if game.buy_module(kind):
        audio.call("play_fx","confirm")
        game.last_notice = "%s upgraded to rank %d." % [ENGINE.MODULE_NAMES[kind],int(game.modules[kind])]
    _refresh()

func _purchase_research(kind: String) -> void:
    if game.buy_research(kind):
        game.save()
    _refresh()

func _hatch() -> void:
    if game.hatch_egg() != "":
        audio.call("play_fx","capture")
        game.save()
    _refresh()

func _inspect_species(kind: String) -> void:
    game.last_notice = "%s • Genes %d • %s • %d Bond victories." % [
        game.species_name(kind),int(game.gene[kind]),
        "Shimmer rarity" if game.rare[kind] else "Common heritage",
        int(game.bonds[kind])]
    _refresh()

func _change_region(key: String) -> void:
    if game.select_region(key):
        game.save()
    _refresh()

func _toggle_overclock() -> void:
    game.toggle_overclock()
    _refresh()

func _claim(key: String) -> void:
    if game.claim_milestone(key):
        game.save()
    _refresh()

func _tap() -> void:
    if running:
        game.tap()
    _refresh()

func _toggle_auto_buy() -> void:
    if int(game.research["automation"]) < 1:
        return
    game.auto_buy = not game.auto_buy
    game.last_notice = "Automatic workshop %s." % ("enabled" if game.auto_buy else "disabled")
    _refresh()

func _toggle_auto_skills() -> void:
    if int(game.research["instinct"]) < 1:
        return
    game.auto_skills = not game.auto_skills
    game.last_notice = "Automatic skills %s." % ("enabled" if game.auto_skills else "disabled")
    _refresh()

func _toggle_repeat() -> void:
    game.repeat_wave = not game.repeat_wave
    _refresh()

func _toggle_batch() -> void:
    batch = 10 if batch == 1 else (25 if batch == 10 else 1)
    _refresh()

func _toggle_speed() -> void:
    game.game_speed = 2.0 if game.game_speed < 2.0 else 1.0
    _refresh()

func _toggle_running() -> void:
    running = not running
    game.last_notice = "Expedition resumed." if running else "Expedition paused."
    _refresh()

func _save() -> void:
    if game.save():
        game.last_notice = "Adventure safely saved in this browser."
    _refresh()

func _on_notice(message: String) -> void:
    if audio != null and not bool(audio.get("muted")):
        if message.contains("evolved"):
            audio.call("play_fx","evolve")
        elif message.contains("Guardian cleared"):
            audio.call("play_fx","victory")
        elif message.contains("retreated"):
            audio.call("play_fx","break")
    if is_node_ready() and labels.has("Notice"):
        _refresh()
