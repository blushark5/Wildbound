extends "res://scripts/incremental/bond_ui_v22.gd"
## Wildbound v0.23: repeat-route convenience, three squad loadouts,
## Ascension Chronicle and real Echo research gains for all 12 creatures.
const ENGINE_23 = preload("res://scripts/incremental/bond_engine_v23.gd")
const PRESET_COUNT: int = 3

var qol23_ready: bool = false
var replay_button: Button
var preset_load_buttons: Array[Button] = []
var preset_store_buttons: Array[Button] = []
var chronicle_dialog: AcceptDialog
var extra_modal_paused: bool = false
var extra_modal_playing: bool = false

func _ready() -> void:
    super._ready()
    game = ENGINE_23.new()
    game.initialize_alpha()
    game.load_save()
    game.notice.connect(_on_notice)
    last_kills = game.kills
    last_guardian = game.last_boss_wave
    playing = game.battle_started
    _build_replay_control()
    _build_preset_controls()
    _build_chronicle()
    qol23_ready = true
    _switch_tab("GROW")
    _refresh()

func _build_replay_control() -> void:
    # Replaces a redundant team-caption strip; does not cover the three
    # creature cards, farm picker or existing Auto-Form control.
    screen_labels["PackDps"].hide()
    replay_button = _button("ReplayRoute","REPLAY • LOCKED",
        Rect2(506,416,161,31),_toggle_replay_route,Color("#a9d7ff"))
    _skin_button(replay_button,PALETTE["sage"],true)
    replay_button.add_theme_font_size_override("font_size",11)

func _toggle_replay_route() -> void:
    if game.toggle_replay_route():
        game.save()
        _toast(game.replay_status())
    else:
        _toast("REPLAY ROUTE unlocks after your first Ascension.")
    _refresh()

func _build_preset_controls() -> void:
    var footer: Label = codex_layer.get_node_or_null("CollectionFooter") as Label
    if footer != null:
        footer.position.y = 642
        footer.add_theme_font_size_override("font_size",10)
    _inside_label(codex_layer,"PresetHeader","TEAM PRESETS",
        Rect2(650,602,111,25),12,PALETTE["sage"])
    for i in range(1,PRESET_COUNT+1):
        var x: float = 759.0+float(i-1)*135.0
        var use: Button = _inside_button(codex_layer,"PresetUse%d" % i,
            "USE %d" % i,Rect2(x,597,72,37),_use_preset.bind(i),PALETTE["sage"])
        use.add_theme_font_size_override("font_size",10)
        preset_load_buttons.append(use)
        var save: Button = _inside_button(codex_layer,"PresetSave%d" % i,
            "SAVE",Rect2(x+75,597,54,37),_store_preset.bind(i),PALETTE["gold"])
        save.add_theme_font_size_override("font_size",10)
        preset_store_buttons.append(save)

func _store_preset(index: int) -> void:
    if game.save_squad_preset(index):
        game.save()
        _toast("TEAM %d SAVED • Available after Ascension and on this save slot." % index)
    else:
        _toast("To save a preset, first equip three distinct owned creatures.")
    _refresh_codex()

func _use_preset(index: int) -> void:
    if game.load_squad_preset(index):
        game.save()
        _toast("TEAM %d LOADED • Manual choices are respected on this stage." % index)
        _refresh()
    else:
        _toast("Preset %d is empty or unavailable." % index)
    _refresh_codex()

func _build_chronicle() -> void:
    chronicle_dialog = AcceptDialog.new()
    chronicle_dialog.title = "Wildbound • Ascension Chronicle"
    chronicle_dialog.ok_button_text = "RETURN"
    add_child(chronicle_dialog)

func _show_chronicle() -> void:
    if game == null or not game.has_method("replay_status"):
        return
    var lines: Array[String] = [
        "LIFETIME RECORD: Stage %d • %d Ascensions" %
            [game.lifetime_cleared_stage,game.ascensions],
        "Auto-Form: %s • Replay Route: %s" % [
            "ON" if game.auto_form_enabled else "OFF",
            "ON" if game.replay_route_enabled else "OFF"],
        "",
        "LATEST COMPLETED RUNS:"
    ]
    if game.ascension_chronicle.is_empty():
        lines.append("No Ascensions yet. Clear Stage 20 to earn your first Echoes.")
    else:
        for entry in game.ascension_chronicle.slice(0,6):
            var seconds: int = int(float(entry["duration"]))
            lines.append("#%d • Stage %d • +%d Echoes • %d creatures • %dm %ds" % [
                int(entry["number"]),int(entry["best_stage"]),int(entry["echoes"]),
                int(entry["creatures"]),seconds/60,seconds%60])
    lines.append("")
    lines.append("Presets are permanent for this save slot. Auto-Form stops at")
    lines.append("your lifetime record; Replay Route pauses before new stages.")
    chronicle_dialog.dialog_text = "\n".join(lines)
    chronicle_dialog.popup_centered(Vector2i(640,385))

func _switch_tab(next: String) -> void:
    super._switch_tab(next)
    if not qol23_ready or sidebar == null:
        return
    if next == "LEGACY":
        var previous: String = (
            "Last: Stage %d, +%d Echoes • Stored runs: %d" % [
                int(game.ascension_chronicle[0]["best_stage"]),
                int(game.ascension_chronicle[0]["echoes"]),
                game.ascension_chronicle.size()]
            if not game.ascension_chronicle.is_empty() else
            "Your first Ascension unlocks run-by-run records.")
        _sidebar_card("ASCENSION CHRONICLE",previous,
            "VIEW",_show_chronicle,"chronicle")
        var card: Control = sidebar.get_child(sidebar.get_child_count()-1)
        sidebar.move_child(card,1)
    _refresh_sidebar()

func _refresh_sidebar() -> void:
    super._refresh_sidebar()
    if not qol23_ready or game == null or not game.has_method("research_details"):
        return
    for row in active_rows:
        var mode: String = String(row["mode"])
        if mode == "research":
            var key: String = String(row["key"])
            var details: Dictionary = game.research_details(key)
            var info: Label = row["info"]
            var button: Button = row["button"]
            info.text = "R%d • %s\n%s" % [
                int(details["rank"]),String(details["summary"]),String(details["effect"])]
            button.tooltip_text = "%s\n%s\n%s\nNext: %d permanent Echoes" % [
                String(ENGINE.RESEARCH_NAMES[key]),String(details["summary"]),
                String(details["effect"]),int(details["next_cost"])]
        elif mode == "chronicle":
            var text: Label = row["info"]
            var show: Button = row["button"]
            show.disabled = false
            show.text = "VIEW RUNS"
            text.text = (
                "Last Stage %d • +%d Echoes • %d records" % [
                    int(game.ascension_chronicle[0]["best_stage"]),
                    int(game.ascension_chronicle[0]["echoes"]),
                    game.ascension_chronicle.size()]
                if not game.ascension_chronicle.is_empty() else
                "Your first Ascension begins the Chronicle.")

func _research(kind: String) -> void:
    var before: int = int(game.research.get(kind,0))
    super._research(kind)
    if int(game.research.get(kind,0)) > before:
        game.save()
        var next_effect: Dictionary = game.research_details(kind)
        _toast("PERMANENT: "+String(next_effect["effect"]))
    _refresh()

func _ascend() -> void:
    var before: int = game.ascensions if game != null else 0
    super._ascend()
    if game != null and game.ascensions > before:
        ascent_results.dialog_text += (
            "\n\nREPLAY ROUTE: %s • Up to Stage %d.\n" % [
                "ACTIVE" if game.replay_route_enabled else "OFF",
                game.lifetime_cleared_stage]
            +"SAVED PRESETS: %d • See ASCEND > CHRONICLE for run history." %
                game.squad_presets.size())
        game.save()
        _refresh()

func _show_first_steps() -> void:
    super._show_first_steps()
    if is_instance_valid(wrapped_guide):
        wrapped_guide.text += (
            "\n\n[b]7. AFTER ASCENSION[/b]\n"
            +"Switch on REPLAY ROUTE to auto-advance through previously cleared stages. "
            +"It pauses at your first new stage or a defeat. Auto-Form remains optional. "
            +"In FIELD GUIDE, save and load three different teams for quick elemental swaps.")

func _refresh_codex() -> void:
    super._refresh_codex()
    if not qol23_ready or game == null or not game.has_method("preset_team"):
        return
    for index in range(1,PRESET_COUNT+1):
        var stored: Array[String] = game.preset_team(index)
        var use: Button = preset_load_buttons[index-1]
        var save: Button = preset_store_buttons[index-1]
        use.text = ("USE %d" if stored.size() == 3 else "EMPTY %d") % index
        use.disabled = stored.size() < 3
        use.tooltip_text = (
            "Load team %d: %s. Your manual selection overrides Auto-Form on this stage." %
                [index,game.preset_summary(index)])
        save.tooltip_text = (
            "Save your current 3 distinct creatures into preset %d. This replaces that preset only." %
                index)

func _refresh() -> void:
    super._refresh()
    if not qol23_ready or game == null or not game.has_method("replay_status"):
        return
    replay_button.disabled = game.ascensions < 1
    if game.ascensions < 1:
        replay_button.text = "REPLAY • LOCKED"
    elif not game.replay_route_enabled:
        replay_button.text = "REPLAY • OFF"
    elif game.is_replay_eligible() and not game.replay_frontier_reached:
        replay_button.text = "REPLAY ▶ %d/%d" % [
            mini(game.wave,game.lifetime_cleared_stage),game.lifetime_cleared_stage]
    else:
        replay_button.text = "REPLAY • PAUSED"
    replay_button.tooltip_text = (
        "Replay Route: "+game.replay_status()+".\n"
        +"After Ascension, toggle ON to auto-advance only through your lifetime cleared stages. "
        +"Auto-Form is separately optional. A loss or new stage pauses auto-progression.")

func _process(delta: float) -> void:
    if qol23_ready:
        var modal: bool = (
            (is_instance_valid(chronicle_dialog) and chronicle_dialog.visible) or
            (is_instance_valid(matchup_dialog) and matchup_dialog.visible) or
            (is_instance_valid(ascent_results) and ascent_results.visible))
        if modal and not extra_modal_paused:
            extra_modal_playing = playing
            extra_modal_paused = true
        if modal:
            playing = false
        elif extra_modal_paused:
            extra_modal_paused = false
            playing = extra_modal_playing and game.battle_started
    super._process(delta)

func _replace_active_game() -> void:
    # v0.19's base slot-switcher creates ENGINE_19. That silently
    # downgraded users after switching save slots in v0.20–0.22. Always
    # create the newest engine for every New Game/Delete/Load action.
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
    game = ENGINE_23.new()
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
