extends "res://scripts/incremental/bond_ui_v19.gd"
## Wildbound v0.20 • battle element emblems, visible squad-slot selection
## and a non-trapping, remembered-lineup, stage-selectable farming loop.
const ENGINE_20 = preload("res://scripts/incremental/bond_engine_v20.gd")
const ELEMENT_BADGES: Dictionary = {
    "Earth":preload("res://assets/incremental/v20/icon_earth.svg"),
    "Water":preload("res://assets/incremental/v20/icon_water.svg"),
    "Fire":preload("res://assets/incremental/v20/icon_fire.svg"),
    "Air":preload("res://assets/incremental/v20/icon_air.svg")
}
const ELEMENT_COLORS_20: Dictionary = {
    "Earth":Color("#a0dea6"),"Water":Color("#8cceef"),
    "Fire":Color("#f8b280"),"Air":Color("#c6c5ff")
}
var ui20_ready: bool = false
var ally_element_icons: Array[TextureRect] = []
var enemy_element_icons: Array[TextureRect] = []
var card_element_icons: Array[TextureRect] = []
var guide_element_icons: Dictionary = {}
var small_icons: Dictionary = {}
var farm_select_button: Button
var farm_dialog: ConfirmationDialog
var farm_spinner: SpinBox
var farm_preview: Label
var farm_was_playing: bool = false

func _ready() -> void:
    super._ready()
    game = ENGINE_20.new()
    game.initialize_alpha()
    game.load_save()
    game.notice.connect(_on_notice)
    last_kills = game.kills
    last_guardian = game.last_boss_wave
    playing = game.battle_started
    _create_element_icons()
    _create_farm_controls()
    # Battle emblems are added after the original Field Guide overlay.
    # Keep the Field Guide above them so badges never bleed through its dim veil.
    codex_layer.z_index = 12
    ui20_ready = true
    _refresh()
    if not game.battle_started:
        game.onboarding_seen = true

func _icon_for(element: String) -> Texture2D:
    return ELEMENT_BADGES.get(element,ELEMENT_BADGES["Earth"]) as Texture2D

func _small_icon(element: String) -> Texture2D:
    if small_icons.has(element):
        return small_icons[element] as Texture2D
    var image: Image = _icon_for(element).get_image()
    image.resize(19,19,Image.INTERPOLATE_LANCZOS)
    small_icons[element] = ImageTexture.create_from_image(image)
    return small_icons[element] as Texture2D

func _element_icon(name: String,parent: Control,pos: Vector2,side: float) -> TextureRect:
    var icon := TextureRect.new()
    icon.name = name
    icon.position = pos
    icon.size = Vector2(side,side)
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(icon)
    return icon

func _create_element_icons() -> void:
    # Creature art stays fully visible. Icons sit at the upper-right edge of
    # each 3v3 battle portrait and on each team building card.
    for i in range(3):
        ally_element_icons.append(_element_icon("AllyElement%d" % i,self,
            Vector2(ALLY_X[i]+78,199),24.0))
        enemy_element_icons.append(_element_icon("RivalElement%d" % i,self,
            Vector2(RIVAL_X[i]+70,199),24.0))
        var x: float = 24.0+float(i)*269.0
        card_element_icons.append(_element_icon("PackElement%d" % i,self,
            Vector2(x+88,455),25.0))
    # The Field Guide was constructed in v0.13; add color-coded element
    # emblems to each creature without changing selection/action geometry.
    for col in range(4):
        for row in range(3):
            var key: String = String(ENGINE_20.COLLECTION_ORDER[col*3+row])
            var x: float = 96+float(col)*272
            var y: float = 221+float(row)*124
            guide_element_icons[key] = _element_icon("GuideElement_"+key,codex_layer,
                Vector2(x+235,y+9),20.0)

func _create_farm_controls() -> void:
    farm_select_button = _button("FarmStageSelector","FARM STAGE ▾",
        Rect2(379,104,162,30),_open_farm_picker,Color("#91dbae"))
    farm_select_button.add_theme_font_size_override("font_size",12)
    _skin_button(farm_select_button,PALETTE["sage"],true)
    farm_select_button.tooltip_text = "Choose ANY stage you've cleared in THIS Ascension run. Restores its latest winning lineup. A failed farm auto-retreats."
    farm_dialog = ConfirmationDialog.new()
    farm_dialog.title = "Select a Beatable Farming Stage"
    farm_dialog.dialog_text = ""
    farm_dialog.confirmed.connect(_confirm_farm_stage)
    farm_dialog.confirmed.connect(_farm_popup_closed)
    farm_dialog.canceled.connect(_farm_popup_closed)
    add_child(farm_dialog)
    var layout := VBoxContainer.new()
    layout.name = "FarmStageControls"
    layout.position = Vector2(15,22)
    layout.size = Vector2(464,184)
    layout.custom_minimum_size = Vector2(464,184)
    layout.add_theme_constant_override("separation",10)
    farm_dialog.add_child(layout)
    var explanation := Label.new()
    explanation.text = "REPLAY CLEARED STAGES • GOLD + BOND XP • NO ESSENCE"
    explanation.add_theme_color_override("font_color",PALETTE["sage"])
    explanation.add_theme_font_size_override("font_size",12)
    layout.add_child(explanation)
    var nav := HBoxContainer.new()
    nav.custom_minimum_size = Vector2(450,43)
    nav.add_theme_constant_override("separation",6)
    layout.add_child(nav)
    for delta in [-5,-1]:
        var back: Button = Button.new()
        back.text = str(delta)
        back.custom_minimum_size = Vector2(63,39)
        back.pressed.connect(_nudge_farm_stage.bind(delta))
        _skin_button(back,PALETTE["sage"])
        nav.add_child(back)
    farm_spinner = SpinBox.new()
    farm_spinner.min_value = 1
    farm_spinner.max_value = 1
    farm_spinner.step = 1
    farm_spinner.rounded = true
    farm_spinner.custom_minimum_size = Vector2(156,39)
    farm_spinner.suffix = "stage"
    farm_spinner.value_changed.connect(_update_farm_preview)
    nav.add_child(farm_spinner)
    for delta in [1,5]:
        var forward: Button = Button.new()
        forward.text = "+"+str(delta)
        forward.custom_minimum_size = Vector2(63,39)
        forward.pressed.connect(_nudge_farm_stage.bind(delta))
        _skin_button(forward,PALETTE["sage"])
        nav.add_child(forward)
    farm_preview = Label.new()
    farm_preview.custom_minimum_size = Vector2(450,101)
    farm_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    farm_preview.add_theme_font_size_override("font_size",12)
    farm_preview.add_theme_color_override("font_color",PALETTE["ink"])
    layout.add_child(farm_preview)

func _nudge_farm_stage(delta: int) -> void:
    farm_spinner.value = clampi(int(farm_spinner.value)+delta,1,int(farm_spinner.max_value))

func _open_farm_picker() -> void:
    if game == null or not game.battle_started:
        _toast("START the first battle before choosing a farming stage.")
        return
    var available: int = game.last_cleared_run_stage()
    if available < 1:
        _toast("Win Stage 1 before farming. You can replay any cleared stage afterward.")
        return
    farm_spinner.max_value = available
    farm_spinner.value = clampi(game.wave if game.repeat_wave else (game.wave-1),1,available)
    _update_farm_preview(farm_spinner.value)
    farm_was_playing = playing
    playing = false
    farm_dialog.popup_centered(Vector2i(504,304))

func _update_farm_preview(_value: float) -> void:
    if game == null or not game.has_method("winning_team_for") or farm_preview == null:
        return
    var stage: int = int(farm_spinner.value)
    var foes: Array = game.roster_for(stage)
    var opponents: Array[String] = []
    for kind in foes:
        opponents.append("%s (%s)" % [
            game.display_name(String(kind)),String(ENGINE_20.CATALOG[kind]["element"])])
    var recorded: Array[String] = game.winning_team_for(stage)
    var formation: Array[String] = []
    for kind in recorded:
        formation.append(game.display_name(kind))
    var team: String = ", ".join(formation) if not formation.is_empty() else "No recorded clear yet. Current team will be used."
    farm_preview.text = (
        "STAGE %d / %d • %s\n" % [stage,game.last_cleared_run_stage(),"GUARDIAN" if stage % 10 == 0 else "TRAINER"]
        +"FOES: "+", ".join(opponents)+"\n"
        +"LAST WINNING SQUAD: "+team+"\n"
        +"RESUME PUSH returns directly to your previous wall.")

func _confirm_farm_stage() -> void:
    if game.farm_stage(int(farm_spinner.value)):
        game.save()
        _toast("STAGE %d FARM • Saved winning squad restored if available." % game.wave)
    _refresh()

func _farm_popup_closed() -> void:
    if game != null:
        playing = farm_was_playing and game.battle_started
    farm_was_playing = false

func _repeat() -> void:
    super._repeat()
    if game != null and game.has_method("last_cleared_run_stage"):
        game.save()

func _refresh() -> void:
    super._refresh()
    if not ui20_ready or game == null or not game.has_method("winning_team_for"):
        return
    var max_stage: int = game.last_cleared_run_stage()
    farm_select_button.disabled = max_stage < 1 or not game.battle_started
    farm_select_button.text = "CHOOSE FARM STAGE ▾" if max_stage > 0 else "FARM LOCKED"
    if game.repeat_wave:
        repeat_button.text = "RESUME PUSH\nSTAGE %d ▶" % (game.push_return_stage if game.push_return_stage > 0 else game.run_peak)
        repeat_button.tooltip_text = "Return to your highest push point immediately, without replaying every cleared stage."
        screen_labels["EncounterHint"].text = "FARM STAGE %d • GOLD + BOND XP • NO ESSENCE • AUTO-RETREAT ON LOSS" % game.wave
    elif max_stage >= 1 and game.battle_started:
        repeat_button.text = "FARM\nSTAGE %d ↻" % max_stage
        repeat_button.tooltip_text = "Farm the highest stage cleared in this Ascension. Or choose any cleared stage above to farm safely."
    for i in range(3):
        var my: String = String(game.squad_slots[i])
        var enemy: String = String(game.rival_units[i].get("kind",""))
        var my_element: String = String(ENGINE_20.CATALOG[my]["element"]) if my != "" else ""
        var enemy_element: String = String(ENGINE_20.CATALOG[enemy]["element"]) if enemy != "" else ""
        ally_element_icons[i].visible = my_element != ""
        enemy_element_icons[i].visible = enemy_element != ""
        card_element_icons[i].visible = my_element != ""
        if my_element != "":
            var element_tex: Texture2D = _icon_for(my_element)
            ally_element_icons[i].texture = element_tex
            card_element_icons[i].texture = element_tex
            var current: String = game.display_name(my,2 if game.unit_ascended(my) else (1 if game.unit_evolved(my) else 0))
            screen_labels["Name_"+String(CHALLENGE.ORDER[i])].text = "SLOT %d • %s" % [i+1,current]
            screen_labels["Name_"+String(CHALLENGE.ORDER[i])].add_theme_color_override(
                "font_color",ELEMENT_COLORS_20[my_element])
            ally_element_icons[i].tooltip_text = "%s • %s" % [current,my_element]
            card_element_icons[i].tooltip_text = "%s • %s" % [current,my_element]
            ally_widgets[i]["name"].tooltip_text = "SLOT %d • %s • %s" % [i+1,current,my_element]
        if enemy_element != "":
            enemy_element_icons[i].texture = _icon_for(enemy_element)
            enemy_element_icons[i].tooltip_text = "%s • %s" % [
                game.display_name(enemy),enemy_element]
            rival_widgets[i]["name"].add_theme_color_override(
                "font_color",ELEMENT_COLORS_20[enemy_element])
        else:
            enemy_element_icons[i].texture = null

func _refresh_codex() -> void:
    super._refresh_codex()
    if not ui20_ready or not is_instance_valid(codex_layer) or game == null or not game.has_method("family_of"):
        return
    var selected: int = clampi(chosen_slot,0,2)
    for i in range(3):
        var key: String = String(game.squad_slots[i])
        var name: String = game.display_name(key,2 if game.unit_ascended(key) else (1 if game.unit_evolved(key) else 0)) if key != "" and game.has_instance(key) else "EMPTY"
        var element: String = String(ENGINE_20.CATALOG[key]["element"]) if key != "" else ""
        var slot_btn: Button = codex_slot_buttons[i]
        slot_btn.text = "S%d • %s" % [i+1,name.substr(0,11)]
        slot_btn.icon = _small_icon(element) if element != "" else null
        slot_btn.add_theme_font_size_override("font_size",10)
        slot_btn.tooltip_text = "SQUAD SLOT %d: %s • %s. Click to choose this slot, then choose a creature card." % [
            i+1,name,element if element != "" else "EMPTY"]
    var selected_kind: String = String(game.squad_slots[selected])
    var selected_name: String = game.display_name(selected_kind) if selected_kind != "" else "EMPTY"
    var prompt: Label = codex_layer.get_node("SelectSlotPrompt") as Label
    prompt.text = "EQUIP SLOT %d • %s" % [selected+1,selected_name]
    prompt.add_theme_font_size_override("font_size",11)
    for key in guide_element_icons:
        var badge: TextureRect = guide_element_icons[key]
        var element: String = String(ENGINE_20.CATALOG[key]["element"])
        badge.texture = _icon_for(element)
        badge.tooltip_text = "%s • %s" % [game.display_name(String(key)),element]
