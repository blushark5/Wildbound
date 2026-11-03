extends "res://scripts/incremental/bond_ui_v18.gd"
## Wildbound v0.19: visible save slots + honest first-battle start
## + discoverable Ascension shortcut. Preserve legacy /bond/ save namespace.
const ENGINE_19 = preload("res://scripts/incremental/bond_engine_v19.gd")
const SAVE_SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")

var save_window: AcceptDialog
var save_intro: Label
var slot_buttons: Array[Button] = []
var new_run_button: Button
var delete_button: Button
var delete_all_button: Button
var action_confirmation: ConfirmationDialog
var pending_action: String = ""
var ascend_shortcut: Button
var ascension_info: AcceptDialog
var ui19_ready: bool = false
var modal_was_active: bool = false
var modal_resume: bool = false

func _ready() -> void:
    super._ready()
    # The v0.18 scene built the visual shell; switch the actual active game
    # to the save-aware version without changing the parent/legacy scenes.
    game = ENGINE_19.new()
    game.initialize_alpha()
    var had_save: bool = FileAccess.file_exists(game.SAVE_FILE)
    game.load_save()
    game.notice.connect(_on_notice)
    last_kills = game.kills
    last_guardian = game.last_boss_wave
    _build_save_window()
    _build_ascension_shortcut()
    playing = game.battle_started
    # The inherited onboarding controller already schedules the first
    # guide for brand-new saves. Resumed, unstarted games show it too.
    if not game.battle_started:
        game.onboarding_seen = true
        if had_save:
            call_deferred("_show_first_steps")
    ui19_ready = true
    _switch_tab("GROW")
    _refresh()

func _build_save_window() -> void:
    var save_header: Button = get_node("Save") as Button
    save_header.text = "SAVES"
    save_header.tooltip_text = "Save progress, switch between three local slots, start a fresh game or delete stored data."
    # The existing SAVE action runs first. This additional callback then
    # presents the save manager, so opening it never loses live progress.
    save_header.pressed.connect(_show_save_manager)
    save_window = AcceptDialog.new()
    save_window.title = "Wildbound • Saved Adventures"
    save_window.ok_button_text = "CLOSE"
    add_child(save_window)
    var holder: VBoxContainer = save_window.get_vbox()
    holder.add_theme_constant_override("separation",11)
    save_intro = Label.new()
    save_intro.custom_minimum_size = Vector2(490,64)
    save_intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    holder.add_child(save_intro)
    for i in range(1,4):
        var btn: Button = Button.new()
        btn.custom_minimum_size = Vector2(490,46)
        btn.pressed.connect(_load_slot.bind(i))
        _skin_button(btn,PALETTE["sage"],true)
        holder.add_child(btn)
        slot_buttons.append(btn)
    new_run_button = Button.new()
    new_run_button.text = "NEW GAME IN CURRENT SLOT"
    new_run_button.custom_minimum_size = Vector2(490,42)
    new_run_button.pressed.connect(_confirm_new_game)
    _skin_button(new_run_button,PALETTE["gold"],true)
    holder.add_child(new_run_button)
    delete_button = Button.new()
    delete_button.text = "DELETE CURRENT SLOT'S SAVE"
    delete_button.custom_minimum_size = Vector2(490,39)
    delete_button.pressed.connect(_confirm_delete_current)
    _skin_button(delete_button,Color("#dd9178"))
    holder.add_child(delete_button)
    delete_all_button = Button.new()
    delete_all_button.text = "DELETE ALL 3 LOCAL SAVES"
    delete_all_button.custom_minimum_size = Vector2(490,35)
    delete_all_button.pressed.connect(_confirm_delete_all)
    _skin_button(delete_all_button,Color("#b26c67"))
    holder.add_child(delete_all_button)
    action_confirmation = ConfirmationDialog.new()
    action_confirmation.title = "Confirm saved-data change"
    action_confirmation.confirmed.connect(_execute_confirmed_action)
    add_child(action_confirmation)

func _build_ascension_shortcut() -> void:
    # The existing header displays the chapter elsewhere, so re-purpose
    # its slot as a persistent readable Ascension progress/action.
    screen_labels["TrailRank"].visible = false
    ascend_shortcut = _button("AscendShortcut","ASCEND • STAGE 20",
        Rect2(990,23,156,44),_open_ascension,GOLD)
    ascend_shortcut.add_theme_font_size_override("font_size",11)
    _skin_button(ascend_shortcut,PALETTE["gold"],true)
    ascension_info = AcceptDialog.new()
    ascension_info.title = "Ascension • Unlock Progress"
    ascension_info.ok_button_text = "GOT IT"
    add_child(ascension_info)
    tab_buttons["LEGACY"].text = "ASCEND"
    tab_buttons["LEGACY"].tooltip_text = "Ascension lives here and in the top-right shortcut. Reach stage 20 in a single run to earn Echoes."

func _show_save_manager() -> void:
    if not ui19_ready:
        return
    game.save()
    _update_save_window()
    save_window.popup_centered(Vector2i(545,455))

func _update_save_window() -> void:
    var active: int = SAVE_SLOTS.active_slot()
    save_intro.text = ("Your current adventure uses Slot %d. Choose another slot to load it, "
        +"or create a new independent adventure in an empty slot. Saves remain in this browser.") % active
    for i in range(1,4):
        var button: Button = slot_buttons[i-1]
        var status: String = SAVE_SLOTS.slot_summary(game.SAVE_FILE,i)
        button.text = ("▶  SLOT %d  •  %s  •  CURRENT" if i == active else "SLOT %d  •  %s") % [i,status]
        button.disabled = i == active
    new_run_button.text = "NEW GAME IN SLOT %d (REPLACES THAT SLOT)" % active
    delete_button.text = "DELETE SLOT %d'S SAVED DATA" % active

func _load_slot(index: int) -> void:
    if index == SAVE_SLOTS.active_slot():
        return
    # The current slot is preserved before the canonical save file swaps.
    if not game.save() or not SAVE_SLOTS.switch_to(game.SAVE_FILE,index):
        _toast("Could not switch save slots. Current game has been preserved.")
        return
    save_window.hide()
    _replace_active_game()

func _confirm_new_game() -> void:
    pending_action = "new"
    save_window.hide()
    action_confirmation.title = "Replace This Slot With a New Adventure?"
    action_confirmation.dialog_text = (
        "This starts a newly randomized Fox, Bird and Lizard team in Slot %d. "
        +"All progress in THIS slot will be erased. Other save slots are untouched. Continue?"
        % SAVE_SLOTS.active_slot())
    action_confirmation.popup_centered(Vector2i(505,225))

func _confirm_delete_current() -> void:
    pending_action = "delete"
    save_window.hide()
    action_confirmation.title = "Delete This Slot's Saved Data?"
    action_confirmation.dialog_text = (
        "Permanently delete all progress from Slot %d? Other slots are kept. "
        +"You will return to a fresh, UNSTARTED adventure." % SAVE_SLOTS.active_slot())
    action_confirmation.popup_centered(Vector2i(505,210))

func _confirm_delete_all() -> void:
    pending_action = "delete_all"
    save_window.hide()
    action_confirmation.title = "Permanently Delete All Save Data?"
    action_confirmation.dialog_text = (
        "This permanently erases ALL THREE Wildbound /bond/ save slots "
        +"from this browser. It cannot be undone. Continue?")
    action_confirmation.popup_centered(Vector2i(505,215))

func _execute_confirmed_action() -> void:
    var ok: bool = false
    match pending_action:
        "new","delete":
            ok = SAVE_SLOTS.erase_slot(game.SAVE_FILE,SAVE_SLOTS.active_slot())
        "delete_all":
            ok = SAVE_SLOTS.erase_all(game.SAVE_FILE)
    var action: String = pending_action
    pending_action = ""
    if not ok:
        _toast("Could not modify the save data; nothing else was reset.")
        return
    _replace_active_game()
    _toast("New adventure ready." if action == "new" else "Save data deleted. Start when ready.")

func _replace_active_game() -> void:
    playing = false
    if is_instance_valid(codex_layer):
        codex_layer.hide()
    prev_playing = false
    ui_clock = 0.0
    autosave_clock = 0.0
    modal_was_active = false
    game = ENGINE_19.new()
    game.initialize_alpha()
    game.load_save()
    game.notice.connect(_on_notice)
    last_kills = game.kills
    last_guardian = game.last_boss_wave
    playing = game.battle_started
    if not game.battle_started:
        game.onboarding_seen = true
        call_deferred("_show_first_steps")
    _switch_tab("GROW")
    _refresh()

func _open_ascension() -> void:
    if not ui19_ready:
        return
    if game.available_echoes() > 0:
        _request_ascension()
        return
    ascension_info.dialog_text = (
        "ASCENSION UNLOCKS AT STAGE 20.\n\n"
        +"Current run: reached stage %d of 20.\n"
        +"Climb through stages to earn your first Echoes, then Ascend here "
        +"or in the ASCEND tab.\n\n"
        +"At Ascension: Gold, creature levels, and temporary upgrades reset. "
        +"Your collection, Bond XP/Ranks, evolved creatures and research survive. "
        +"Your enemy stages reroll.") % mini(game.run_peak,20)
    ascension_info.popup_centered(Vector2i(540,290))

func _process(delta: float) -> void:
    if not ui19_ready or game == null or not game.has_method("unit_ascended"):
        super._process(delta)
        return
    var modal_open: bool = (
        guide_dialog.visible or ascend_dialog.visible or
        save_window.visible or action_confirmation.visible or
        ascension_info.visible)
    if modal_open and not modal_was_active:
        modal_resume = playing
        modal_was_active = true
    if modal_open:
        playing = false
    elif modal_was_active:
        modal_was_active = false
        playing = modal_resume and game.battle_started
    if not game.battle_started:
        playing = false
    super._process(delta)
    if not game.battle_started:
        # Deleting an entire save should actually leave no saved game until
        # the user starts it or deliberately presses SAVE.
        autosave_clock = 0.0

func _show_first_steps() -> void:
    super._show_first_steps()
    if not is_instance_valid(guide_dialog):
        return
    if game != null and game.has_method("unit_ascended") and not game.battle_started:
        guide_dialog.dialog_text += ("\n\nFIRST BATTLE: Close this guide, then press "
            +"START FIRST BATTLE in the main battle controls. Combat, Gold, "
            +"Bond XP and stage progression remain paused until you press START.")
    else:
        guide_dialog.dialog_text += "\n\nOpening this guide pauses live combat until you close it."

func _strike() -> void:
    if game != null and game.has_method("unit_ascended") and not game.battle_started:
        if guide_dialog.visible:
            return
        game.battle_started = true
        playing = true
        modal_was_active = false
        modal_resume = true
        game.onboarding_seen = true
        game.save()
        _toast("STAGE 1 STARTED • Your creatures now engage the enemy!")
        _refresh()
        return
    super._strike()

func _refresh() -> void:
    super._refresh()
    if not ui19_ready or game == null or not game.has_method("unit_ascended"):
        return
    if not game.battle_started:
        strike_button.text = "START FIRST BATTLE  ▶"
        strike_button.disabled = false
        strike_button.tooltip_text = "Close the introduction guide, then click to begin Stage 1. No battles or rewards are simulated before you choose START."
        repeat_button.disabled = true
        speed_button.disabled = true
        screen_labels["Wave"].text = "STAGE 1 • READY TO BEGIN"
        screen_labels["EncounterHint"].text = "PAUSED • CLOSE THE GUIDE, THEN CHOOSE START BATTLE"
    var available: int = game.available_echoes()
    ascend_shortcut.text = (
        "ASCEND +%d ECHO ▶" % available if available > 0
        else "ASCEND LOCKED\nSTAGE %d / 20" % mini(game.run_peak,20))
    ascend_shortcut.tooltip_text = (
        "Ascend now for %d permanent Echoes. Confirm before resetting temporary progress." % available
        if available > 0 else
        "Ascension becomes available once you reach Stage 20 in this run. Current progress: %d / 20. Click to learn more." % mini(game.run_peak,20))
    tab_buttons["LEGACY"].text = "ASCEND"
    for row in active_rows:
        if String(row["mode"]) == "ascend":
            if available < 1:
                row["info"].text = "LOCKED • Reach Stage 20 this run (%d/20). Progress remains permanently after Ascension." % mini(game.run_peak,20)
                row["button"].text = "STAGE 20"
                row["button"].tooltip_text = "Ascension is locked until your current run reaches Stage 20. Use the header shortcut for details."
            else:
                row["info"].text = "READY • +%d Echoes. Retains collected creatures, Bonds, evolution and research." % available
                row["button"].text = "ASCEND +%d" % available
