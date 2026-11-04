extends "res://scripts/incremental/bond_ui_v26.gd"
## Wildbound v0.27: one consistent RIGHT DRAWER with TOP TABS.
## All non-destructive navigation stays beside the active battlefield.
## Inherits v0.26 combat/Ascension recovery, no engine/economy changes.

const MENU_KEYS: Array[String] = ["TEAM","GROW","NEST","LEGACY","WORLD","TOOLS","SAVE"]
const MENU_LABELS: Array[String] = ["TEAM","GOLD","NEST","ASC","WORLD","TOOLS","SAVE"]
const MENU_ELEMENT_ORDER: Array[String] = ["Fire","Water","Earth","Air"]
var nav27_ready: bool = false
var menu_section: String = "TEAM"
var menu_buttons: Dictionary = {}
var menu_heading: Label
var team_page: Control
var tools_page: Control
var saves_page: Control
var menu_scroll: ScrollContainer
var creature_rows: Dictionary = {}
var team_target_buttons: Array[Button] = []
var hatch_side_button: Button
var team_count_label: Label
var team_essence_label: Label
var team_preset_load: Array[Button] = []
var tools_status: Label
var tools_buttons: Dictionary = {}
var tools_farm_stage: SpinBox
var tools_farm_preview: Label
var tools_readout: RichTextLabel
var saves_buttons: Array[Button] = []
var saves_caption: Label
var side_help_mode: String = ""

func _ready() -> void:
    super._ready()
    _create_unified_nav()
    _create_team_page()
    _create_tools_page()
    _create_saves_page()
    nav27_ready = true
    menu_section = "TEAM"
    _close_drawer()
    _refresh()

func _create_unified_nav() -> void:
    # The previous drawer sat underneath separate upgrade tabs and an
    # independent full-screen Field Guide. This top navigation replaces
    # those different patterns with one always-consistent destination.
    drawer_backdrop.position = Vector2(842,86)
    drawer_backdrop.size = Vector2(424,621)
    drawer_backdrop.add_theme_stylebox_override("panel",
        _glass(Color("#081e29",0.985),Color("#94c3ae"),16,2,11))
    for i in range(MENU_KEYS.size()):
        var key: String = MENU_KEYS[i]
        var button: Button = _button("SideTab_"+key,MENU_LABELS[i],
            Rect2(852+i*56.0,99,54,37),_show_section.bind(key),MINT_TONE)
        button.z_index = 6
        button.add_theme_font_size_override("font_size",9)
        var narrow_style := _glass(Color("#143342"),MINT_TONE,6,1)
        narrow_style.content_margin_left = 3.0
        narrow_style.content_margin_right = 3.0
        button.add_theme_stylebox_override("normal",narrow_style)
        button.tooltip_text = {
            "TEAM":"Field Guide: view, hatch, equip and save teams",
            "GROW":"Gold upgrades for your current run",
            "NEST":"Eggs, relics and Nest resources",
            "LEGACY":"Ascension, permanent Echo research and history",
            "WORLD":"The Journey, regions and tactics",
            "TOOLS":"Auto-Form, Replay, stage farming, matchups and accessibility",
            "SAVE":"Save slots, New Game and save management"
        }[key]
        menu_buttons[key] = button
    menu_heading = _label("V27SideSectionHeading","YOUR TEAM",
        Rect2(862,151,324,35),19,GOLD_TONE)
    menu_heading.z_index = 5
    drawer_close.position = Vector2(1205,149)
    drawer_close.size = Vector2(46,35)
    drawer_close.z_index = 7
    drawer_close.tooltip_text = "Close the menu; the battlefield remains visible."
    # The old four Gold/Nest/Ascend/World sub-tabs are now redundant.
    for tab_button in tab_buttons.values():
        (tab_button as Button).hide()
    quest_fold_button.hide()

func _side_root(name: String) -> Control:
    var root_page := Control.new()
    root_page.name = name
    root_page.position = Vector2(853,192)
    root_page.size = Vector2(398,508)
    root_page.z_index = 5
    root_page.visible = false
    add_child(root_page)
    return root_page

func _side_label(parent: Control,name: String,value: String,rect: Rect2,
        size: int = 13,tint: Color = Color("#d4e7dd")) -> Label:
    var result := Label.new()
    result.name = name
    result.text = value
    result.position = rect.position
    result.size = rect.size
    result.clip_text = true
    result.add_theme_color_override("font_color",tint)
    result.add_theme_font_size_override("font_size",size)
    result.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(result)
    return result

func _side_button(parent: Control,name: String,value: String,rect: Rect2,
        fn: Callable,tint: Color = MINT_TONE) -> Button:
    var result := Button.new()
    result.name = name
    result.text = value
    result.position = rect.position
    result.size = rect.size
    _skin_button(result,tint)
    result.add_theme_font_size_override("font_size",11)
    parent.add_child(result)
    result.pressed.connect(fn)
    return result

func _create_team_page() -> void:
    team_page = _side_root("V27TeamDrawer")
    team_count_label = _side_label(team_page,"TeamCount","",Rect2(7,0,370,24),12)
    for i in range(3):
        var button: Button = _side_button(team_page,"TargetSlot_"+str(i),
            "EQUIP IN %d" % (i+1),Rect2(7+i*129,29,124,41),
            _team_pick_slot.bind(i),GOLD_TONE)
        team_target_buttons.append(button)
    team_essence_label = _side_label(team_page,"EssenceText","",
        Rect2(8,81,190,25),12,Color("#a1dee2"))
    hatch_side_button = _side_button(team_page,"HatchFromSide","HATCH CREATURE",
        Rect2(208,75,183,37),_team_hatch,GOLD_TONE)
    _side_label(team_page,"SpeciesSubtitle","COLLECTION • ORGANIZED BY ELEMENT",
        Rect2(10,120,380,21),11,Color("#9bbfae"))
    menu_scroll = ScrollContainer.new()
    menu_scroll.name = "TeamSpeciesScroll"
    menu_scroll.position = Vector2(7,143)
    menu_scroll.size = Vector2(385,268)
    menu_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
    team_page.add_child(menu_scroll)
    var species_list := VBoxContainer.new()
    species_list.name = "SpeciesList"
    species_list.custom_minimum_size = Vector2(367,0)
    species_list.add_theme_constant_override("separation",6)
    menu_scroll.add_child(species_list)
    for element in MENU_ELEMENT_ORDER:
        var tint: Color = ELEMENT_COLORS[element]
        var title := Label.new()
        title.text = element.to_upper()+"  •  THREE CREATURE FAMILIES"
        title.custom_minimum_size = Vector2(366,29)
        title.add_theme_font_size_override("font_size",13)
        title.add_theme_color_override("font_color",tint)
        species_list.add_child(title)
        for kind in ENGINE_25.COLLECTION_ORDER:
            if String(ENGINE_25.CATALOG[kind]["element"]) != element:
                continue
            var creature: String = String(kind)
            var container := PanelContainer.new()
            container.custom_minimum_size = Vector2(365,76)
            container.add_theme_stylebox_override("panel",
                _glass(Color("#12313f"),Color(tint,0.41),9,1,1))
            species_list.add_child(container)
            var line := HBoxContainer.new()
            line.add_theme_constant_override("separation",7)
            container.add_child(line)
            var art := TextureRect.new()
            art.custom_minimum_size = Vector2(67,62)
            art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
            art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
            art.mouse_filter = Control.MOUSE_FILTER_IGNORE
            line.add_child(art)
            var words := VBoxContainer.new()
            words.custom_minimum_size = Vector2(163,61)
            line.add_child(words)
            var caption := Label.new()
            caption.clip_text = true
            caption.add_theme_font_size_override("font_size",13)
            caption.add_theme_color_override("font_color",Color("#e8f0dd"))
            words.add_child(caption)
            var extra := Label.new()
            extra.clip_text = true
            extra.add_theme_font_size_override("font_size",11)
            extra.add_theme_color_override("font_color",Color("#a9c7c0"))
            words.add_child(extra)
            var equip := Button.new()
            equip.custom_minimum_size = Vector2(105,42)
            equip.pressed.connect(_team_equip.bind(creature))
            _skin_button(equip,tint,true)
            equip.add_theme_font_size_override("font_size",10)
            line.add_child(equip)
            creature_rows[creature] = {
                "art":art,"name":caption,"details":extra,"button":equip,"shown":""
            }
    _side_label(team_page,"PresetLabel","SAVE OR REUSE A TEAM",
        Rect2(9,420,374,22),11,GOLD_TONE)
    for i in range(1,4):
        var x: float = 7+(i-1)*131
        var use: Button = _side_button(team_page,"PresetUse_"+str(i),
            "USE %d"%i,Rect2(x,450,70,42),_team_use_preset.bind(i))
        team_preset_load.append(use)
        _side_button(team_page,"PresetSave_"+str(i),"SAVE",
            Rect2(x+73,450,54,42),_team_save_preset.bind(i),GOLD_TONE)

func _team_pick_slot(index: int) -> void:
    chosen_slot = index
    _refresh_side_team()

func _team_equip(kind: String) -> void:
    if game == null or not game.has_instance(kind):
        return
    if game.assign_creature(chosen_slot,kind):
        game.save()
        _toast("%s EQUIPPED IN SLOT %d" % [game.display_name(kind),chosen_slot+1])
    _refresh_side_team()
    _refresh()

func _team_hatch() -> void:
    if game == null or game.essence < game.hatch_cost():
        return
    # Use the exact same original hatch and first-clear Essence economy.
    _codex_hatch()
    _refresh_side_team()
    _refresh()

func _team_use_preset(index: int) -> void:
    _use_preset(index)
    _refresh_side_team()
    _refresh()

func _team_save_preset(index: int) -> void:
    _store_preset(index)
    _refresh_side_team()

func _refresh_side_team() -> void:
    if not nav27_ready or game == null or not is_instance_valid(team_page):
        return
    team_count_label.text = "OWNED %d / 12    •    CHOOSE A SLOT TO REPLACE" % game.collection_count()
    team_essence_label.text = "ESSENCE %d / %d" % [game.essence,game.hatch_cost()]
    hatch_side_button.text = "HATCH • %d ESSENCE" % game.hatch_cost()
    hatch_side_button.disabled = (
        game.essence < game.hatch_cost() or game.collection_count() >= 12)
    for i in range(3):
        var button: Button = team_target_buttons[i]
        button.text = ("◆  SLOT %d" if chosen_slot == i else "SLOT %d") % (i+1)
        _skin_button(button,GOLD_TONE if chosen_slot == i else MINT_TONE,chosen_slot==i)
    for kind in creature_rows:
        var row: Dictionary = creature_rows[kind]
        var owned: bool = game.has_instance(String(kind))
        var slot: int = game.squad_slots.find(String(kind))
        var picture: TextureRect = row["art"]
        var caption: Label = row["name"]
        var detail: Label = row["details"]
        var button: Button = row["button"]
        var form: String = ""
        if owned:
            form = game.display_name(String(kind),
                2 if game.unit_ascended(String(kind))
                else 1 if game.unit_evolved(String(kind)) else 0)
            caption.text = form
            detail.text = "LV %d • %s" % [game.unit_level(String(kind)),
                "IN SLOT %d" % (slot+1) if slot >= 0 else
                String(ENGINE_25.CATALOG[kind]["element"]).to_upper()]
            button.disabled = slot == chosen_slot
            button.text = "IN SLOT" if slot == chosen_slot else (
                "SWAP" if slot >= 0 else "EQUIP")
            var marker: String = str(game.unit_evolved(String(kind)))+str(game.unit_ascended(String(kind)))
            if String(row["shown"]) != marker:
                picture.texture = _creature_texture(String(kind),
                    game.unit_evolved(String(kind)),false)
                picture.modulate = Color.WHITE
                row["shown"] = marker
        else:
            caption.text = "UNKNOWN "+String(ENGINE_25.CATALOG[kind]["element"]).to_upper()
            detail.text = "NOT YET DISCOVERED"
            button.text = "LOCKED"
            button.disabled = true
            if String(row["shown"]) != "unknown":
                picture.texture = _creature_texture(String(kind),false,false)
                picture.modulate = Color("#8c9da0",0.38)
                row["shown"] = "unknown"
    for i in range(1,4):
        var button: Button = team_preset_load[i-1]
        button.disabled = game.preset_team(i).size() != 3
        button.tooltip_text = "Load team %d: %s" % [i,game.preset_summary(i)]

func _create_tools_page() -> void:
    tools_page = _side_root("V27ToolsDrawer")
    tools_status = _side_label(tools_page,"ToolsStatus","",
        Rect2(10,3,375,47),13,MINT_TONE)
    for i in range(2):
        var id: String = "auto" if i == 0 else "replay"
        var title: String = "AUTO-FORM" if i == 0 else "REPLAY ROUTE"
        tools_buttons[id] = _side_button(tools_page,"Tool_"+id,
            title,Rect2(9,57+i*48,376,41),
            _tool_side_autoform if i == 0 else _tool_side_replay)
    tools_buttons["text"] = _side_button(tools_page,"Tool_Text","TEXT SIZE",
        Rect2(9,157,376,40),_tool_side_text)
    _side_label(tools_page,"FarmTitle","SELECT CLEARED FARMING STAGE",
        Rect2(9,207,372,25),12,GOLD_TONE)
    tools_farm_stage = SpinBox.new()
    tools_farm_stage.position = Vector2(9,238)
    tools_farm_stage.size = Vector2(140,39)
    tools_farm_stage.min_value = 1
    tools_farm_stage.max_value = 1
    tools_farm_stage.step = 1
    tools_farm_stage.rounded = true
    tools_farm_stage.suffix = "stage"
    tools_page.add_child(tools_farm_stage)
    tools_farm_stage.value_changed.connect(_tool_stage_changed)
    tools_buttons["farm"] = _side_button(tools_page,"Tool_Farm","FARM SELECTED STAGE",
        Rect2(158,238,227,39),_tool_side_farm)
    tools_farm_preview = _side_label(tools_page,"FarmPreview","",
        Rect2(10,283,377,38),11,Color("#adccc9"))
    tools_buttons["match"] = _side_button(tools_page,"Tool_Match",
        "ELEMENT MATCHUPS",Rect2(9,328,183,38),_tool_side_match)
    tools_buttons["history"] = _side_button(tools_page,"Tool_History",
        "ASCENSION HISTORY",Rect2(201,328,184,38),_tool_side_history)
    tools_readout = RichTextLabel.new()
    tools_readout.name = "ToolsDetails"
    tools_readout.position = Vector2(11,379)
    tools_readout.size = Vector2(373,111)
    tools_readout.bbcode_enabled = false
    tools_readout.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    tools_readout.scroll_active = true
    tools_readout.add_theme_font_size_override("normal_font_size",12)
    tools_page.add_child(tools_readout)

func _refresh_side_tools() -> void:
    if not nav27_ready or game == null or not is_instance_valid(tools_page):
        return
    tools_status.text = "STAGE %d    •    RECORD %d    •    ASCENSIONS %d" % [
        game.wave,game.lifetime_cleared_stage,game.ascensions]
    tools_buttons["auto"].disabled = game.ascensions < 1
    tools_buttons["auto"].text = (
        "AUTO-FORM  •  %s" % ("ON" if game.auto_form_enabled else "OFF")
        if game.ascensions > 0 else "AUTO-FORM  •  ASCEND TO UNLOCK")
    tools_buttons["replay"].disabled = game.ascensions < 1
    tools_buttons["replay"].text = (
        "REPLAY ROUTE  •  %s" % ("ON" if game.replay_route_enabled else "OFF")
        if game.ascensions > 0 else "REPLAY ROUTE  •  ASCEND TO UNLOCK")
    tools_buttons["text"].text = "LARGE TEXT  •  %s" % (
        "ON" if game.ui_large_text else "OFF")
    tools_farm_stage.max_value = maxi(1,game.last_cleared_run_stage())
    tools_buttons["farm"].disabled = (
        not game.battle_started or game.last_cleared_run_stage() < 1)
    _tool_stage_changed(tools_farm_stage.value)
    if side_help_mode == "":
        tools_readout.text = (
            "Tips: Counter your rival's elements and farm stages you can beat. "
            +"Auto-Form chooses teams; Replay Route advances through familiar stages. "
            +"Both are optional and unlock after Ascension.")

func _tool_stage_changed(_value: float) -> void:
    if game == null or not is_instance_valid(tools_farm_preview):
        return
    var available: int = game.last_cleared_run_stage()
    tools_farm_preview.text = (
        "Farming awards Gold and Bond XP, never first-clear Essence.\n"
        +"Saved winning squad is restored when available."
        if available >= 1 else "Win Stage 1 before selecting a farming stage.")

func _tool_side_autoform() -> void:
    _toggle_autoform()
    _refresh_side_tools()

func _tool_side_replay() -> void:
    _toggle_replay_route()
    _refresh_side_tools()

func _tool_side_text() -> void:
    _toggle_text_size()
    _refresh_side_tools()

func _tool_side_farm() -> void:
    if game.farm_stage(int(tools_farm_stage.value)):
        game.save()
        _toast("FARMING STAGE %d • GOLD + BOND XP" % game.wave)
        _refresh()
    _refresh_side_tools()

func _tool_side_match() -> void:
    side_help_mode = "MATCH"
    var lines: Array[String] = ["EARTH > WATER > FIRE > AIR > EARTH",""]
    var foes: Array = game.roster_for(game.wave)
    for kind in game.squad_slots:
        if kind == "" or not game.has_instance(String(kind)):
            continue
        var matchup: Array[String] = []
        for enemy in foes:
            var factor: float = game.multiplier(String(kind),String(enemy))
            matchup.append("%s %s" % [
                game.display_name(String(enemy)),
                "2×" if factor > 1.0 else "0.45×" if factor < 1.0 else "1×"])
        lines.append(game.display_name(String(kind))+": "+", ".join(matchup))
    tools_readout.text = "\n".join(lines)

func _tool_side_history() -> void:
    side_help_mode = "HISTORY"
    var lines: Array[String] = [
        "LIFETIME STAGE %d • %d ASCENSIONS" %
        [game.lifetime_cleared_stage,game.ascensions]]
    if game.ascension_chronicle.is_empty():
        lines.append("Reach Stage 20 and Ascend to record your first run.")
    else:
        for entry in game.ascension_chronicle.slice(0,6):
            lines.append("#%d • Stage %d • +%d Echoes" % [
                int(entry["number"]),int(entry["best_stage"]),int(entry["echoes"])])
    tools_readout.text = "\n".join(lines)

func _create_saves_page() -> void:
    saves_page = _side_root("V27SaveDrawer")
    saves_caption = _side_label(saves_page,"SaveSummary","",
        Rect2(10,0,379,65),14,MINT_TONE)
    for i in range(1,4):
        var button: Button = _side_button(saves_page,"Slot_"+str(i),"",
            Rect2(9,72+(i-1)*57,378,49),_side_load_slot.bind(i))
        saves_buttons.append(button)
    _side_button(saves_page,"SaveNow","SAVE CURRENT SLOT NOW",
        Rect2(9,256,378,46),_side_save_now,GOLD_TONE)
    _side_button(saves_page,"NewGame","NEW GAME IN CURRENT SLOT",
        Rect2(9,318,378,47),_side_new_game,GOLD_TONE)
    _side_button(saves_page,"DeleteSlot","DELETE CURRENT SLOT",
        Rect2(9,381,378,46),_side_delete_slot,Color("#e49d86"))
    _side_button(saves_page,"DeleteAll","DELETE ALL 3 SAVES",
        Rect2(9,443,378,44),_side_delete_all,Color("#cd7d7d"))

func _refresh_side_saves() -> void:
    if not nav27_ready or not is_instance_valid(saves_page) or game == null:
        return
    var active: int = SAVE_SLOTS.active_slot()
    saves_caption.text = (
        "CURRENT SLOT %d • STAGE %d • ASCENSIONS %d\n" %
        [active,game.wave,game.ascensions]
        +"Progress is stored locally in this browser.")
    for i in range(1,4):
        var button: Button = saves_buttons[i-1]
        var label: String = SAVE_SLOTS.slot_summary(game.SAVE_FILE,i)
        if i == active and game.battle_started:
            label = "STAGE %d • %d CREATURES" % [game.wave,game.collection_count()]
        button.text = ("◆ " if i == active else "")+"SLOT %d  •  "%i+label
        button.disabled = i == active

func _side_load_slot(index: int) -> void:
    _load_slot(index)
    _refresh_side_saves()

func _side_save_now() -> void:
    _save_current_slot()
    _refresh_side_saves()

func _side_new_game() -> void:
    _confirm_new_game()

func _side_delete_slot() -> void:
    _confirm_delete_current()

func _side_delete_all() -> void:
    _confirm_delete_all()

func _show_section(section: String) -> void:
    if not nav27_ready:
        return
    if not MENU_KEYS.has(section):
        return
    menu_section = section
    drawer_open = true
    if ["GROW","NEST","LEGACY","WORLD"].has(section):
        super._switch_tab(section)
    _set_drawer_visibility(true)
    if section == "TEAM":
        _refresh_side_team()
    elif section == "TOOLS":
        _refresh_side_tools()
    elif section == "SAVE":
        _refresh_side_saves()
    shop_button.text = "CLOSE MENU"
    _refresh()

func _set_drawer_visibility(show: bool) -> void:
    if not nav27_ready:
        super._set_drawer_visibility(show)
        return
    drawer_backdrop.visible = show
    drawer_close.visible = show
    menu_heading.visible = show
    for k in menu_buttons:
        var button: Button = menu_buttons[k]
        button.visible = show
        var selected: bool = menu_section == k
        var edge: Color = GOLD_TONE if selected else MINT_TONE
        var normal := _glass(Color("#3b554c") if selected else Color("#153746"),
            edge,6,1)
        normal.content_margin_left = 3.0
        normal.content_margin_right = 3.0
        button.add_theme_stylebox_override("normal",normal)
        var hover := _glass(Color("#42636d"),edge.lightened(0.16),6,1)
        hover.content_margin_left = 3.0
        hover.content_margin_right = 3.0
        button.add_theme_stylebox_override("hover",hover)
        button.add_theme_font_size_override("font_size",9)
        button.size = Vector2(54,37)
    team_page.visible = show and menu_section == "TEAM"
    tools_page.visible = show and menu_section == "TOOLS"
    saves_page.visible = show and menu_section == "SAVE"
    var shop: bool = show and ["GROW","NEST","LEGACY","WORLD"].has(menu_section)
    var world: bool = show and menu_section == "WORLD"
    var scroll: ScrollContainer = get_node("SidebarScroll") as ScrollContainer
    (get_node("SidebarPanel") as Panel).visible = shop
    scroll.visible = shop
    sidebar_title.visible = shop
    # Quest/Journey is part of the World tab instead of being permanently
    # attached to Gold, Nest, and Ascension purchases.
    var journey: Panel = get_node("JourneyPanel") as Panel
    journey.visible = world
    for name in ["JourneyHeading","JourneyStage","QuestName","QuestProgress"]:
        screen_labels[name].visible = world
    for name in ["QuestHint","QuestReward"]:
        screen_labels[name].visible = false
    get_node("TrailRail").visible = false
    trail_fill.visible = false
    trail_button.visible = world
    quest_fold_button.visible = false
    for button in tab_buttons.values():
        (button as Button).visible = false
    if shop:
        journey.position = Vector2(852,207)
        journey.size = Vector2(414,116)
        screen_labels["JourneyHeading"].position = Vector2(867,214)
        screen_labels["JourneyHeading"].size.x = 355
        screen_labels["JourneyStage"].position = Vector2(1131,216)
        screen_labels["JourneyStage"].size.x = 101
        screen_labels["QuestName"].position = Vector2(869,244)
        screen_labels["QuestName"].size.x = 354
        screen_labels["QuestProgress"].position = Vector2(872,283)
        screen_labels["QuestProgress"].size.x = 255
        trail_button.position = Vector2(1137,278)
        trail_button.size = Vector2(110,37)
        var top: float = 331 if world else 205
        (get_node("SidebarPanel") as Panel).position = Vector2(852,top)
        (get_node("SidebarPanel") as Panel).size = Vector2(414,707-top)
        sidebar_title.position = Vector2(866,top+8)
        sidebar_title.size.x = 345
        scroll.position = Vector2(864,top+44)
        scroll.size = Vector2(386,694-(top+44))
        for button in tab_buttons.values():
            (button as Button).hide()
    menu_heading.text = {
        "TEAM":"FIELD GUIDE","GROW":"GOLD UPGRADES",
        "NEST":"THE NEST","LEGACY":"ASCENSION & LEGACY",
        "WORLD":"WORLD & JOURNEY","TOOLS":"TACTICS & SETTINGS",
        "SAVE":"SAVE MANAGEMENT"
    }.get(menu_section,"WILDBOUND")

func _close_drawer() -> void:
    if not nav27_ready:
        super._close_drawer()
        return
    drawer_open = false
    _set_drawer_visibility(false)
    shop_button.text = "UPGRADES"
    _refresh()

func _open_shop(target: String = "GROW") -> void:
    if not nav27_ready:
        super._open_shop(target)
        return
    _show_section(target)

func _toggle_shop() -> void:
    if not nav27_ready:
        super._toggle_shop()
        return
    if drawer_open:
        _close_drawer()
    else:
        _show_section("GROW")

func _switch_tab(next: String) -> void:
    super._switch_tab(next)
    if nav27_ready and drawer_open:
        _set_drawer_visibility(true)

func _open_codex() -> void:
    if not nav27_ready:
        super._open_codex()
        return
    codex_layer.hide()
    _show_section("TEAM")

func _close_codex() -> void:
    if not nav27_ready:
        super._close_codex()
        return
    codex_layer.hide()
    _close_drawer()

func _open_tactics() -> void:
    if not nav27_ready:
        super._open_tactics()
        return
    tactics_dialog.hide()
    _show_section("TOOLS")

func _open_farm_picker() -> void:
    if not nav27_ready:
        super._open_farm_picker()
        return
    _show_section("TOOLS")
    if game.last_cleared_run_stage() < 1:
        _toast("Complete Stage 1 to unlock the farming selector.")

func _show_matchups() -> void:
    if not nav27_ready:
        super._show_matchups()
        return
    _show_section("TOOLS")
    _tool_side_match()

func _show_chronicle() -> void:
    if not nav27_ready:
        super._show_chronicle()
        return
    _show_section("TOOLS")
    _tool_side_history()

func _open_ascension() -> void:
    if not nav27_ready:
        super._open_ascension()
        return
    _show_section("LEGACY")

func _show_save_manager() -> void:
    if not nav27_ready:
        super._show_save_manager()
        return
    save_window.hide()
    _show_section("SAVE")

func _show_first_steps() -> void:
    # Introduce brand-new players with the same side navigation rather
    # than a full-width modal that obscures the first battle.
    if not nav27_ready:
        call_deferred("_show_slot_guide_if_needed")
        return
    guide_dialog.hide()
    _show_section("TEAM")
    _toast("Choose TEAM, GOLD, NEST or TOOLS at the top. START FIRST BATTLE when ready.")

func _refresh() -> void:
    super._refresh()
    if not nav27_ready or game == null:
        return
    if drawer_open:
        if menu_section == "TEAM":
            _refresh_side_team()
        elif menu_section == "TOOLS":
            _refresh_side_tools()
        elif menu_section == "SAVE":
            _refresh_side_saves()
        for button in tab_buttons.values():
            (button as Button).hide()
    codex_layer.hide()
    tactics_dialog.hide()
    save_window.hide()
    for button in menu_buttons.values():
        (button as Button).add_theme_font_size_override("font_size",10)
    if not drawer_open:
        menu_heading.hide()

func _replace_active_game() -> void:
    super._replace_active_game()
    if nav27_ready:
        menu_section = "TEAM"
        _close_drawer()
        _refresh()
