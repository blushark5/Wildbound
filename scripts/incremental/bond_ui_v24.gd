extends "res://scripts/incremental/bond_ui_v23.gd"
## v0.24: repair post-Ascension pause deadlock, add a reliable battle
## resume affordance, and clean up crowded mobile/desktop HUD controls.
const ENGINE_24 = preload("res://scripts/incremental/bond_engine_v24.gd")
var qol24_ready: bool = false
var pending_ascension_start: bool = false
var preview_body: RichTextLabel
var results_body: RichTextLabel
var counters_body: RichTextLabel
var chronicle_body: RichTextLabel

func _ready() -> void:
    super._ready()
    game = ENGINE_24.new()
    game.initialize_alpha()
    game.load_save()
    game.notice.connect(_on_notice)
    last_kills = game.kills
    last_guardian = game.last_boss_wave
    playing = game.battle_started
    _clean_interface()
    _install_readable_modals()
    qol24_ready = true
    _switch_tab("GROW")
    _refresh()

func _clean_interface() -> void:
    # The legacy "Squad slot selected..." help line was floating across
    # the top edge of the sidebar and covering the tab buttons.
    if is_instance_valid(team_note):
        team_note.hide()
    # This legacy second ticker was cut off against the bottom screen edge.
    # Concise temporary messages remain in the upper battle HUD.
    screen_labels["Notification"].hide()
    var toast: Label = screen_labels["Toast"]
    toast.position = Vector2(42,152)
    toast.size = Vector2(485,17)
    toast.clip_text = true
    toast.add_theme_font_size_override("font_size",10)
    # Before v0.24 AUTO-FORM covered FIELD GUIDE on the pack header.
    # All five actions now have separate, non-overlapping touch targets.
    collect_button.position = Vector2(345,416)
    collect_button.size = Vector2(154,32)
    collect_button.add_theme_font_size_override("font_size",11)
    collect_button.text = "FIELD GUIDE"
    batch_button.size.y = 31
    batch_button.position.y = 417
    replay_button.position = Vector2(505,416)
    replay_button.size = Vector2(162,32)
    autoform_button.position = Vector2(672,416)
    autoform_button.size = Vector2(162,32)
    # First battle, next stage and rescue from a paused Ascension all use
    # the SAME large primary action, never a hidden shortcut.
    strike_button.add_theme_font_size_override("font_size",16)
    strike_button.tooltip_text = (
        "START: begin your first encounter. NEXT: advance after a victory. "
        +"RETRY: replay after defeat. RESUME: restart a paused Ascension run. "
        +"During live combat, this button performs a manual assist attack.")
    # Make the nearby three combat actions legible on a phone.
    resonance_button.add_theme_font_size_override("font_size",12)
    repeat_button.add_theme_font_size_override("font_size",12)
    speed_button.add_theme_font_size_override("font_size",12)
    # Clarify that this results button STARTS the newly reset run.
    ascent_results.ok_button_text = "START NEW ASCENSION RUN ▶"
    ascent_results.title = "Ascension Complete • Begin Your Next Run"
    # The tiny body text in the Sidebar tends to disappear after scaling.
    for tab_button in tab_buttons.values():
        (tab_button as Button).add_theme_font_size_override("font_size",11)

func _modal_body(window: Window,name: String,size: Vector2) -> RichTextLabel:
    var body := RichTextLabel.new()
    body.name = name
    body.position = Vector2(18,27)
    body.size = size
    body.custom_minimum_size = size
    body.fit_content = false
    body.bbcode_enabled = false
    body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    body.scroll_active = true
    body.scroll_following = false
    body.add_theme_font_size_override("normal_font_size",15)
    body.add_theme_color_override("default_color",Color("#e2f0e8"))
    window.add_child(body)
    return body

func _install_readable_modals() -> void:
    # Previous Ascension / Chronicle / matchup dialogs used their native
    # no-wrap text fields, which can run outside the screen on mobile.
    preview_body = _modal_body(ascend_dialog,"PreviewWrapped",Vector2(570,286))
    results_body = _modal_body(ascent_results,"ResultsWrapped",Vector2(570,286))
    counters_body = _modal_body(matchup_dialog,"MatchupsWrapped",Vector2(556,286))
    chronicle_body = _modal_body(chronicle_dialog,"ChronicleWrapped",Vector2(556,284))

func _request_ascension() -> void:
    super._request_ascension()
    if qol24_ready and ascend_dialog.visible:
        preview_body.text = ascend_dialog.dialog_text
        ascend_dialog.dialog_text = ""
        ascend_dialog.popup_centered(Vector2i(610,404))

func _show_matchups() -> void:
    super._show_matchups()
    if qol24_ready and matchup_dialog.visible:
        counters_body.text = matchup_dialog.dialog_text
        matchup_dialog.dialog_text = ""
        matchup_dialog.popup_centered(Vector2i(604,405))

func _show_chronicle() -> void:
    super._show_chronicle()
    if qol24_ready and chronicle_dialog.visible:
        chronicle_body.text = chronicle_dialog.dialog_text
        chronicle_dialog.dialog_text = ""
        chronicle_dialog.popup_centered(Vector2i(604,405))

func _ascend() -> void:
    if game == null:
        return
    var previous: int = game.ascensions
    super._ascend()
    if game.ascensions <= previous:
        return
    # v0.22 captured 'playing' while a confirmation dialog had already
    # paused it; on close that FALSE value got restored indefinitely.
    pending_ascension_start = true
    results_body.text = ascent_results.dialog_text
    ascent_results.dialog_text = ""
    ascent_results.popup_centered(Vector2i(615,410))
    ascent_report_playing = true
    modal_resume = true
    extra_modal_playing = true
    # Do not run combat underneath the result dialog.
    playing = false
    game.save()
    _refresh()

func _close_ascent_results() -> void:
    # Force the requested new Ascension run to start, irrespective of
    # stale modal_resume / extra_modal_playing snapshots from v0.19-v0.23.
    if game == null:
        return
    if pending_ascension_start or game.battle_started:
        ascent_report_playing = true
        extra_modal_playing = true
        modal_resume = true
    super._close_ascent_results()
    pending_ascension_start = false
    extra_modal_paused = false
    modal_was_active = false
    playing = game.battle_started
    _refresh()
    # Window close events can arrive before visibility flags turn false.
    # Defer a final resume until after the result dialog has actually closed.
    call_deferred("_resume_after_ascension_dialog")

func _resume_after_ascension_dialog() -> void:
    if game == null or not game.battle_started:
        return
    if is_instance_valid(ascent_results) and ascent_results.visible:
        return
    if _any_blocking_dialog():
        return
    extra_modal_paused = false
    modal_was_active = false
    ascent_report_playing = true
    playing = true
    _refresh()
    game.save()

func _any_blocking_dialog() -> bool:
    return (guide_dialog.visible or ascend_dialog.visible or
        save_window.visible or action_confirmation.visible or
        ascension_info.visible or ascent_results.visible or
        chronicle_dialog.visible or matchup_dialog.visible or
        farm_dialog.visible or codex_layer.visible)

func _strike() -> void:
    if qol24_ready and game != null and game.battle_started and not playing:
        if _any_blocking_dialog():
            return
        # A post-Ascension paused game should never require a browser reset,
        # Incognito session or deletion to start fighting again.
        extra_modal_paused = false
        modal_was_active = false
        modal_resume = true
        playing = true
        pending_ascension_start = false
        game.save()
        _toast("BATTLE RESUMED • Stage %d" % game.wave)
        _refresh()
        return
    super._strike()

func _refresh() -> void:
    super._refresh()
    if not qol24_ready or game == null or not game.has_method("replay_status"):
        return
    # Guard the primary action against v0.19's 'not playing' disable path.
    # If the game is awaiting a new stage, entering it uses the same button.
    if game.battle_started and not playing and not _any_blocking_dialog():
        strike_button.text = (
            "CONTINUE • NEXT STAGE ▶" if game.awaiting_next else
            "RESUME BATTLE ▶")
        strike_button.disabled = false
        strike_button.tooltip_text = "Tap to resume combat after Ascension or another pause without affecting your save."
    # Neither a hidden legacy Field Guide button nor sidebar text should
    # overlap the other controls.
    collect_button.visible = not codex_layer.visible
    if collect_button.visible:
        collect_button.text = "FIELD GUIDE %d/12" % game.collection_count()

func _replace_active_game() -> void:
    # New Game / Delete / slot switch must ALL keep the patched v0.24
    # battle controller. Earlier v0.19–v0.23 versions substituted old engines.
    playing = false
    if is_instance_valid(codex_layer):
        codex_layer.hide()
    if is_instance_valid(chronicle_dialog):
        chronicle_dialog.hide()
    prev_playing = false
    ui_clock = 0.0
    autosave_clock = 0.0
    modal_was_active = false
    extra_modal_paused = false
    pending_ascension_start = false
    game = ENGINE_24.new()
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
