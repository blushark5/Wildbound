extends "res://scripts/incremental/bond_ui_v24.gd"
## Wildbound v0.25 — cohesive 1280x720 responsive-to-scale interface pass.
## The touch-first frame and all gameplay buttons retain their true actions.
const ENGINE_25 = preload("res://scripts/incremental/bond_engine_v25.gd")

var qol25_ready: bool = false
var quest_fold_button: Button
var type_size_button: Button
var sidebar_title: Label
var slot_markers: Array[Label] = []

func _ready() -> void:
    super._ready()
    game = ENGINE_25.new()
    game.initialize_alpha()
    game.load_save()
    game.notice.connect(_on_notice)
    last_kills = game.kills
    last_guardian = game.last_boss_wave
    playing = game.battle_started
    _build_layout_controls()
    qol25_ready = true
    _apply_journey_layout()
    _apply_type_sizes()
    _switch_tab("GROW")
    _refresh()

func _build_layout_controls() -> void:
    screen_labels["PackHeader"].text = "ACTIVE SQUAD"
    screen_labels["PackHeader"].add_theme_font_size_override("font_size",16)
    screen_labels["PackHeader"].size.x = 190
    # Keep the title distinct from HUD controls and resource chips.
    type_size_button = _button("TypeSize","TEXT A+",
        Rect2(277,30,89,34),_toggle_text_size,Color("#aacaca"))
    _skin_button(type_size_button,PALETTE["sage"])
    type_size_button.add_theme_font_size_override("font_size",11)
    type_size_button.tooltip_text = "Enlarge creature names, descriptions and shop text. Setting is saved per game slot."

    # The Journey normally consumed ~200px even when players were buying
    # upgrades. Compact mode frees 88px of valuable right-side space.
    quest_fold_button = _button("JourneyFold","DETAILS",
        Rect2(1189,104,65,29),_toggle_journey,PALETTE["gold"])
    _skin_button(quest_fold_button,PALETTE["gold"])
    quest_fold_button.add_theme_font_size_override("font_size",10)
    quest_fold_button.tooltip_text = "Expand or collapse the Journey. Your reward claim remains accessible in either view."

    sidebar_title = _label("SidebarContext","GOLD UPGRADES",
        Rect2(871,359,371,25),12,PALETTE["sage"])
    sidebar_title.add_theme_font_size_override("font_size",12)
    sidebar_title.clip_text = true

    # Large squad-slot numbers to emphasize which creature is in each
    # position. Element badges and portraits remain unobscured.
    for i in range(3):
        var x: float = 24.0+269.0*float(i)
        var slot: Label = _label("SquadSlotMarker_"+str(i),
            "0%d" % (i+1),Rect2(x+10,451,34,21),12,PALETTE["gold"])
        slot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        slot.add_theme_stylebox_override("normal",
            _glass(Color("#0c2533",0.94),Color("#cbb47b",0.75),6,1))
        slot_markers.append(slot)

    # Unified bottom action bar. Keep all physical touch regions at least
    # 50px high; short verbs are easier to scan than sentence-long labels.
    strike_button.text = "ASSIST ATTACK"
    strike_button.add_theme_font_size_override("font_size",15)
    resonance_button.add_theme_font_size_override("font_size",12)
    repeat_button.add_theme_font_size_override("font_size",12)
    speed_button.add_theme_font_size_override("font_size",12)
    _skin_button(strike_button,PALETTE["gold"],true)
    _skin_button(resonance_button,Color("#a5b9e9"))
    _skin_button(repeat_button,Color("#98d0af"))
    _skin_button(speed_button,Color("#cfc7a2"))
    for button in [batch_button,collect_button,replay_button,autoform_button]:
        button.add_theme_font_size_override("font_size",11)
    # The temporary toast and the static encounter explanation previously
    # overlapped the stage progress strip.
    var toast: Label = screen_labels["Toast"]
    toast.position = Vector2(40,141)
    toast.size = Vector2(510,24)
    toast.clip_text = true
    toast.add_theme_font_size_override("font_size",11)
    toast.add_theme_color_override("font_color",Color("#ffe4aa"))
    screen_labels["EncounterHint"].position.y = 141
    screen_labels["EncounterHint"].size.x = 510
    # Visually emphasize the current team rather than generic card labels.
    for i in range(3):
        var key: String = String(CHALLENGE.ORDER[i])
        screen_labels["Name_"+key].position.y = 456
        screen_labels["Name_"+key].position.x = 24.0+269.0*float(i)+111.0
        screen_labels["Name_"+key].size.x = 135.0

func _toggle_journey() -> void:
    if game == null or not game.has_method("to_dict"):
        return
    game.ui_compact_journey = not game.ui_compact_journey
    _apply_journey_layout()
    game.save()
    _refresh()

func _toggle_text_size() -> void:
    if game == null or not game.has_method("to_dict"):
        return
    game.ui_large_text = not game.ui_large_text
    _apply_type_sizes()
    game.save()
    _refresh()

func _apply_journey_layout() -> void:
    if game == null or not game.has_method("to_dict") or not is_instance_valid(quest_fold_button):
        return
    var compact: bool = game.ui_compact_journey
    var quest: Panel = get_node("JourneyPanel") as Panel
    var shop: Panel = get_node("SidebarPanel") as Panel
    var scroll: ScrollContainer = get_node("SidebarScroll") as ScrollContainer
    quest.size.y = 115.0 if compact else 198.0
    shop.position.y = 213.0 if compact else 296.0
    shop.size.y = 494.0 if compact else 411.0
    var tabs_y: float = 225.0 if compact else 308.0
    var heading_y: float = 273.0 if compact else 356.0
    var cards_y: float = 303.0 if compact else 386.0
    for name in tab_buttons:
        var button: Button = tab_buttons[name]
        button.position.y = tabs_y
        button.size.y = 40.0
    sidebar_title.position.y = heading_y
    scroll.position.y = cards_y
    scroll.size.y = 695.0-cards_y
    screen_labels["JourneyStage"].position.x = 1092
    screen_labels["JourneyStage"].size.x = 90
    quest_fold_button.position = Vector2(1188,100)
    quest_fold_button.text = "MORE ▾" if compact else "LESS ▴"
    quest_fold_button.tooltip_text = (
        "Show quest description and reward details." if compact else
        "Collapse quest details to see more Gold and Echo upgrades.")
    screen_labels["QuestName"].position.y = 133
    screen_labels["QuestName"].size = Vector2(371,24)
    screen_labels["QuestName"].add_theme_font_size_override("font_size",18)
    if compact:
        screen_labels["QuestHint"].hide()
        screen_labels["QuestReward"].hide()
        get_node("TrailRail").hide()
        trail_fill.hide()
        screen_labels["QuestProgress"].position = Vector2(872,165)
        screen_labels["QuestProgress"].size = Vector2(241,23)
        trail_button.position = Vector2(1135,159)
        trail_button.size = Vector2(112,36)
    else:
        screen_labels["QuestHint"].show()
        screen_labels["QuestReward"].show()
        get_node("TrailRail").show()
        trail_fill.show()
        screen_labels["QuestHint"].position = Vector2(870,161)
        screen_labels["QuestReward"].position.y = 264
        screen_labels["QuestProgress"].position = Vector2(872,211)
        trail_button.position = Vector2(1136,224)
        trail_button.size = Vector2(111,40)
    _update_sidebar_heading()

func _update_sidebar_heading() -> void:
    if not is_instance_valid(sidebar_title) or game == null:
        return
    match tab:
        "GROW":
            sidebar_title.text = "GOLD UPGRADES   •   PURCHASE %s" % (
                "MAX" if bulk_amount == 0 else "x%d" % bulk_amount)
        "NEST":
            sidebar_title.text = "THE NEST   •   %d / 12 COLLECTED" % game.collection_count()
        "LEGACY":
            sidebar_title.text = "PERMANENT POWER   •   %d ECHOES" % game.echoes
        "WORLD":
            sidebar_title.text = "WORLD & TACTICS   •   STAGE %d" % game.wave
        _:
            sidebar_title.text = "WILDBOUND"

func _apply_type_sizes() -> void:
    if game == null or not game.has_method("to_dict") or not is_instance_valid(type_size_button):
        return
    var big: bool = game.ui_large_text
    type_size_button.text = "TEXT A−" if big else "TEXT A+"
    type_size_button.tooltip_text = (
        "Use regular-sized text." if big else
        "Make Field Guide, battle names and upgrade effects easier to read on your phone.")
    screen_labels["QuestHint"].add_theme_font_size_override("font_size",13 if big else 12)
    screen_labels["QuestProgress"].add_theme_font_size_override("font_size",14 if big else 13)
    screen_labels["EnemyHp"].add_theme_font_size_override("font_size",14 if big else 12)
    screen_labels["DamageReadout"].add_theme_font_size_override("font_size",13 if big else 12)
    screen_labels["EncounterHint"].add_theme_font_size_override("font_size",12 if big else 10)
    screen_labels["FieldStatus"].add_theme_font_size_override("font_size",12 if big else 11)
    screen_labels["QuestName"].add_theme_font_size_override("font_size",19 if big else 18)
    for idx in range(3):
        var k: String = String(CHALLENGE.ORDER[idx])
        screen_labels["Name_"+k].add_theme_font_size_override("font_size",14 if big else 13)
        card_details[k].add_theme_font_size_override("font_size",12 if big else 11)
        ally_widgets[idx]["name"].add_theme_font_size_override("font_size",12 if big else 11)
        rival_widgets[idx]["name"].add_theme_font_size_override("font_size",12 if big else 11)
        card_buy[k].add_theme_font_size_override("font_size",12 if big else 11)
        card_skill[k].add_theme_font_size_override("font_size",11 if big else 10)
    if is_instance_valid(codex_layer):
        codex_layer.get_node("CodexSubtitle").add_theme_font_size_override("font_size",14 if big else 13)
        for kind in codex_cards:
            var item: Dictionary = codex_cards[kind]
            (item["name"] as Label).add_theme_font_size_override("font_size",15 if big else 14)
            (item["trait"] as Label).add_theme_font_size_override("font_size",11 if big else 10)
            (item["status"] as Label).add_theme_font_size_override("font_size",11 if big else 10)
            (item["action"] as Button).add_theme_font_size_override("font_size",11 if big else 10)
    _style_shop_rows()

func _style_shop_rows() -> void:
    if game == null or sidebar == null:
        return
    var big: bool = game.ui_large_text if game.has_method("to_dict") else false
    for row in active_rows:
        var heading: Label = row["title"]
        var info: Label = row["info"]
        var action: Button = row["button"]
        heading.add_theme_font_size_override("font_size",14 if big else 13)
        info.add_theme_font_size_override("font_size",12 if big else 11)
        action.add_theme_font_size_override("font_size",12 if big else 11)
        info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
        var outer: Node = heading.get_parent().get_parent().get_parent()
        if outer is PanelContainer:
            (outer as PanelContainer).add_theme_stylebox_override("panel",
                _glass(Color("#17394a"),Color("#507b80"),11,1,1))

func _switch_tab(next: String) -> void:
    super._switch_tab(next)
    if not qol25_ready:
        return
    _apply_journey_layout()
    _style_shop_rows()
    _update_sidebar_heading()

func _choose_bulk(quantity: int) -> void:
    super._choose_bulk(quantity)
    if qol25_ready:
        _update_sidebar_heading()

func _refresh_sidebar() -> void:
    super._refresh_sidebar()
    if not qol25_ready or game == null:
        return
    _update_sidebar_heading()

func _refresh() -> void:
    super._refresh()
    if not qol25_ready or game == null or not game.has_method("replay_status"):
        return
    # Only one message occupies the narrow strip above stage progress.
    # Brief toasts temporarily replace the static encounter description.
    var toast: Label = screen_labels["Toast"]
    var event_active: bool = toast_time > 0.0 and toast.text != ""
    screen_labels["EncounterHint"].visible = not event_active
    toast.visible = event_active
    screen_labels["PackHeader"].text = "ACTIVE SQUAD • %d/3" % game.occupied_slots()
    for idx in range(3):
        var kind: String = String(game.squad_slots[idx])
        var key: String = String(CHALLENGE.ORDER[idx])
        if kind != "" and game.has_instance(kind):
            var name: String = game.display_name(kind,
                2 if game.unit_ascended(kind) else (1 if game.unit_evolved(kind) else 0))
            screen_labels["Name_"+key].text = "S%d · %s" % [idx+1,name]
            screen_labels["Name_"+key].tooltip_text = (
                "Squad Slot %d: %s. Choose FIELD GUIDE to change it." % [idx+1,name])
        else:
            screen_labels["Name_"+key].text = "S%d · EMPTY" % (idx+1)
    if not _any_blocking_dialog():
        # The explicit START / RESUME / NEXT path from v0.24 always wins.
        # Never make a critical action invisible through this UI pass.
        strike_button.visible = true
    quest_fold_button.disabled = false

func _refresh_codex() -> void:
    super._refresh_codex()
    if not qol25_ready or game == null or not is_instance_valid(codex_layer):
        return
    var focused: int = clampi(chosen_slot,0,2)
    var chosen_kind: String = String(game.squad_slots[focused])
    var display: String = game.display_name(chosen_kind) if chosen_kind != "" else "EMPTY"
    var prompt: Label = codex_layer.get_node("SelectSlotPrompt") as Label
    prompt.text = "REPLACE SLOT %d" % (focused+1)
    prompt.tooltip_text = "Currently %s • tap an owned creature to assign it to Squad Slot %d." % [
        display,focused+1]
    prompt.size.x = 174
    for idx in range(3):
        var button: Button = codex_slot_buttons[idx]
        var selected: bool = idx == focused
        _skin_button(button,PALETTE["gold"] if selected else Color("#75b7c5"),selected)
        button.add_theme_font_size_override("font_size",11 if game.ui_large_text else 10)
        button.size.y = 40.0
        button.position.y = 591.0
    # Each column is its own element. Show REAL ownership counts, not the
    # static /03 placeholder from the earliest Field Guide design.
    var elements: Array[String] = ["Earth","Water","Fire","Air"]
    for element in elements:
        var owned: int = 0
        for key in codex_cards:
            var kind: String = String(key)
            if String(ENGINE_25.CATALOG[kind]["element"]) == element and game.has_instance(kind):
                owned += 1
        var header: Label = codex_layer.get_node("ElementLabel_"+element) as Label
        header.text = "%s  %d / 3" % [element.to_upper(),owned]
    for key in codex_cards:
        var kind: String = String(key)
        var row: Dictionary = codex_cards[key]
        var action: Button = row["action"]
        if not game.has_instance(kind):
            action.text = "NOT YET HATCHED"
            continue
        var current_slot: int = game.squad_slots.find(kind)
        if current_slot == focused:
            action.text = "IN SLOT %d ✓" % (focused+1)
            action.disabled = true
        elif current_slot >= 0:
            action.text = "SWAP INTO SLOT %d" % (focused+1)
            action.disabled = false
        else:
            action.text = "EQUIP IN SLOT %d" % (focused+1)
            action.disabled = false
        action.tooltip_text = (
            "Assign %s to Squad Slot %d. %s" % [
                game.display_name(kind),focused+1,
                "This swaps the existing creature from another slot." if current_slot >= 0 else
                "Your other squad slots stay unchanged."])

func _replace_active_game() -> void:
    super._replace_active_game()
    # Preserve v0.24's fixed Ascension restart and all newer save-slot
    # semantics while restoring the v0.25 preferences after a slot switch.
    game = ENGINE_25.new()
    game.initialize_alpha()
    game.load_save()
    game.notice.connect(_on_notice)
    last_kills = game.kills
    last_guardian = game.last_boss_wave
    playing = game.battle_started
    if qol25_ready:
        _apply_journey_layout()
        _apply_type_sizes()
        _switch_tab("GROW")
        _refresh()
