extends SceneTree
## v0.24 regression for reported post-Ascension soft lock, mobile
## control overlap, bounded scroll dialogs, and current-save recovery.
const GAME = preload("res://scripts/incremental/bond_engine_v24.gd")
const PRIOR = preload("res://scripts/incremental/bond_engine_v23.gd")
const SCENE = preload("res://scenes/incremental/wildbound_bond_v24.tscn")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")

func _initialize() -> void:
    call_deferred("_check")

func _fail(message: String) -> void:
    push_error("v0.24 regression: "+message)
    SLOTS.erase_all(GAME.SAVE_FILE)
    quit(1)

func _check() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var ui: Control = SCENE.instantiate()
    root.add_child(ui)
    await process_frame
    if not ui.game.has_method("replay_status") or not ui.game.has_method("save_squad_preset"):
        _fail("Main game does not have current v0.24 engine");return
    if ui.collect_button.get_rect().intersects(ui.autoform_button.get_rect()) or ui.collect_button.get_rect().intersects(ui.replay_button.get_rect()):
        _fail("Field Guide shortcut is overlapped by automation controls");return
    if ui.batch_button.get_rect().intersects(ui.collect_button.get_rect()) or ui.replay_button.get_rect().intersects(ui.autoform_button.get_rect()):
        _fail("Pack header buttons overlap");return
    if ui.team_note.visible or ui.screen_labels["Notification"].visible:
        _fail("Legacy selected-slot / clipped notification labels still clutter UI");return
    if ui.preview_body == null or ui.results_body == null or not ui.preview_body.scroll_active:
        _fail("Ascension preview and result text must be bounded and scrollable");return
    if ui.preview_body.autowrap_mode != TextServer.AUTOWRAP_WORD_SMART or ui.preview_body.size.x > 585.0:
        _fail("Mobile Ascension text does not wrap or exceeds viewport");return
    if ui.counters_body == null or ui.chronicle_body == null or not ui.counters_body.scroll_active:
        _fail("Tactical matchup/Chronicle dialog body not scrollable");return
    for kind in ["tempo","crit","recovery"]:
        var detail: String = String(ui.upgrade_breakdown(kind)["details"])
        if detail.length() < 75 or detail.find("%") < 0:
            _fail("Upgrade description has malformed percent formatting: "+kind);return
    ui.guide_dialog.hide()
    ui._strike()
    if not ui.game.battle_started or not ui.playing:
        _fail("Fresh save could not intentionally start first battle");return
    if ui.collect_button.disabled or not ui.collect_button.visible:
        _fail("Field Guide shortcut is not available after starting");return
    # Stage 20 completed, then real v0.24 Ascension UI flow.
    ui.game.best_wave = 21
    ui.game.run_peak = 21
    ui.game.wave = 21
    ui.game.awaiting_next = false
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.game._setup_trainer_fight()
    ui._request_ascension()
    if not ui.ascend_dialog.visible or ui.preview_body.text.find("ECHO") < 0:
        _fail("Readable Ascension preview failed");return
    ui.ascend_dialog.hide()
    ui._ascend()
    if ui.game.ascensions != 1 or ui.game.wave != 1 or not ui.game.battle_started or ui.game.awaiting_next:
        _fail("Ascension did not reset to an immediately playable Stage 1");return
    if not ui.ascent_results.visible or not ui.results_body.text.contains("ECHO") or not ui.pending_ascension_start:
        _fail("Ascension result dialog missing its start affordance");return
    if ui.playing:
        _fail("Combat should remain paused WHILE results are visible");return
    ui.ascent_results.hide()
    ui._close_ascent_results()
    await process_frame
    if not ui.playing or ui.strike_button.disabled:
        _fail("BUG REPRODUCED: closing results leaves battle disabled/paused");return
    if ui.extra_modal_paused or ui.modal_was_active:
        _fail("Old modal pause flags still force combat OFF after close");return
    var t0: float = ui.game.total_seconds
    ui._process(0.35)
    if ui.game.total_seconds <= t0:
        _fail("Battle time does not advance after closing Ascension results");return
    ui.game.save()

    # Simulate an existing v0.23 browser save where battle_started=true
    # but all pause flags were incorrectly captured as FALSE.
    ui.playing = false
    ui.modal_was_active = true
    ui.modal_resume = false
    ui.extra_modal_paused = true
    ui.extra_modal_playing = false
    ui._refresh()
    if ui.strike_button.disabled or not ui.strike_button.text.contains("RESUME"):
        _fail("Existing stuck save lacks an enabled RESUME BATTLE button");return
    ui._strike()
    if not ui.playing or ui.extra_modal_paused or ui.modal_was_active:
        _fail("RESUME BATTLE failed to clear poisoned modal pause states");return

    ui._show_matchups()
    if not ui.matchup_dialog.visible or not ui.counters_body.text.contains("STAGE"):
        _fail("Matchup guide not using wrapped scroll area");return
    ui.matchup_dialog.hide()
    ui._show_chronicle()
    if not ui.chronicle_dialog.visible or not ui.chronicle_body.text.contains("Ascensions"):
        _fail("Chronicle not using wrapped scroll area");return
    ui.chronicle_dialog.hide()
    ui._open_codex()
    if not ui.codex_layer.visible:
        _fail("Field Guide cannot be opened");return
    ui._close_codex()

    # Confirm newest game type persists after slot switch, deletion, New Game.
    ui._load_slot(2)
    if ui.game.battle_started or not ui.game.has_method("replay_status"):
        _fail("Switching slots reintroduced an older engine or old battle");return
    ui._load_slot(1)
    if not ui.game.has_method("replay_status") or ui.game.ascensions != 1:
        _fail("Returning to Slot 1 lost Ascension progression");return
    ui._confirm_new_game()
    ui.action_confirmation.hide()
    ui._execute_confirmed_action()
    if ui.game.battle_started or ui.game.ascensions != 0:
        _fail("New Game did not reset battle/Ascension in current slot only");return

    # v0.23 saved game migration: every previously Ascended user's
    # creatures, Echoes, and battle_started marker must remain intact.
    SLOTS.erase_all(GAME.SAVE_FILE)
    var old = PRIOR.new()
    old.initialize_alpha()
    old.load_save()
    old.battle_started = true
    old.best_wave = 21
    old.run_peak = 21
    old.ascend()
    old.save()
    var upgraded = GAME.new()
    upgraded.initialize_alpha()
    if not upgraded.load_save() or not upgraded.battle_started or upgraded.ascensions != 1:
        _fail("Old v0.23 Ascended save is not compatible");return
    SLOTS.erase_all(GAME.SAVE_FILE)
    ui.queue_free()
    print("PASS v0.24: real Ascension results close resumes fight, poisoned old pause state recovered by RESUME BATTLE, dialogs wrap/scroll, all pack controls separate, 3 save slots and prior saves safe")
    quit(0)
