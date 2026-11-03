extends SceneTree
## v0.19 regression: three browser save slots, first-battle hold, Ascension help.
const GAME = preload("res://scripts/incremental/bond_engine_v19.gd")
const LEGACY = preload("res://scripts/incremental/bond_engine_v18.gd")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")
const SCENE = preload("res://scenes/incremental/wildbound_bond_v19.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _fail(reason: String) -> void:
    push_error("Wildbound v0.19: "+reason)
    SLOTS.erase_all(GAME.SAVE_FILE)
    quit(1)

func _verify() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var ui: Control = SCENE.instantiate() as Control
    root.add_child(ui)
    await process_frame
    if ui.game.battle_started or ui.playing or ui.game.kills != 0:
        _fail("A new game must not fight before pressing START BATTLE");return
    var time_before: float = ui.game.total_seconds
    for i in range(7):
        await process_frame
    if ui.game.total_seconds != time_before or ui.game.kills != 0 or ui.game.gold > 0.0:
        _fail("The first battle ran while the new guide was up");return
    if not ui.strike_button.text.contains("START FIRST BATTLE") or not ui.repeat_button.disabled:
        _fail("Start Battle not clearly exposed and Farm still enabled before start");return
    if not ui.guide_dialog.dialog_text.contains("START FIRST BATTLE"):
        _fail("Guide does not explain explicit first encounter action");return
    if not ui.ascend_shortcut.text.contains("STAGE 1 / 20"):
        _fail("Ascension progress shortcut missing from initial screen");return
    ui._open_ascension()
    if not ui.ascension_info.visible:
        _fail("Locked Ascension shortcut should explain the requirement");return
    ui.ascension_info.hide()
    ui.guide_dialog.hide()
    ui._strike()
    if not ui.game.battle_started or not ui.playing:
        _fail("Clicking START BATTLE did not begin a new adventure");return
    var snapshot: float = ui.game.total_seconds
    ui._process(0.20)
    if ui.game.total_seconds <= snapshot:
        _fail("Actual first battle remained paused after explicit START");return
    if not FileAccess.file_exists(GAME.SAVE_FILE):
        _fail("First battle was not saved");return
    ui.game.gold = 73.0
    ui.game.save()
    ui._show_save_manager()
    if not ui.save_window.visible or ui.slot_buttons.size() != 3:
        _fail("SAVES menu must expose three selectable slots");return
    ui._load_slot(2)
    if SLOTS.active_slot() != 2 or ui.game.battle_started or ui.game.collection_count() != 3:
        _fail("Empty Slot 2 did not create a separately paused randomized team");return
    if not FileAccess.file_exists(SLOTS.slot_path(1)):
        _fail("Opening Slot 2 failed to snapshot existing Slot 1 progress");return
    ui.guide_dialog.hide()
    ui._strike()
    ui.game.gold = 410.0
    ui.game.save()
    ui._load_slot(1)
    if SLOTS.active_slot() != 1 or not ui.game.battle_started or ui.game.gold < 73.0 or ui.game.gold >= 410.0:
        _fail("Returning to Slot 1 did not restore its separate saved progress");return
    ui._load_slot(2)
    if ui.game.gold < 410.0 or not ui.game.battle_started:
        _fail("Returning to Slot 2 did not restore its separate saved progress");return
    ui._confirm_delete_current()
    if not ui.action_confirmation.visible:
        _fail("Deleting a save must require explicit confirmation");return
    ui.action_confirmation.hide()
    ui._execute_confirmed_action()
    if FileAccess.file_exists(GAME.SAVE_FILE) or FileAccess.file_exists(SLOTS.slot_path(2)) or ui.game.battle_started:
        _fail("Confirmed current-slot deletion left data behind or resumed combat");return
    if not FileAccess.file_exists(SLOTS.slot_path(1)):
        _fail("Deleting Slot 2 accidentally destroyed Slot 1");return
    ui._show_save_manager()
    if FileAccess.file_exists(GAME.SAVE_FILE):
        _fail("Opening SAVES silently recreated a deleted slot");return
    ui._load_slot(1)
    if FileAccess.file_exists(SLOTS.slot_path(2)):
        _fail("Switching away from a deleted, unstarted slot silently recreated it");return
    if ui.game.gold < 73.0:
        _fail("Slot 1 did not survive Slot 2 deletion");return
    ui._confirm_new_game()
    if not ui.action_confirmation.visible:
        _fail("New Game must warn before replacing current saved data");return
    ui.action_confirmation.hide()
    ui._execute_confirmed_action()
    if FileAccess.file_exists(GAME.SAVE_FILE) or ui.game.battle_started or ui.game.collection_count() != 3:
        _fail("New Game did not clear current slot and create unstarted starter trio");return
    ui._confirm_delete_all()
    ui.action_confirmation.hide()
    ui._execute_confirmed_action()
    if SLOTS.active_slot() != 1 or FileAccess.file_exists(GAME.SAVE_FILE) or FileAccess.file_exists(SLOTS.slot_path(1)):
        _fail("Delete All did not clear canonical, snapshots, and slot-selection metadata");return

    # v0.18 save has no battle_started key. It must be treated as already
    # playing rather than replaying the new introduction or resetting data.
    var old_game = LEGACY.new()
    old_game.initialize_alpha()
    old_game.initialize_squads()
    old_game.gold = 116.0
    old_game.save()
    var migrated = GAME.new()
    migrated.initialize_alpha()
    if not migrated.load_save() or not migrated.battle_started or migrated.gold < 116.0:
        _fail("Legacy v0.18 progress was gated or lost on migration");return

    SLOTS.erase_all(GAME.SAVE_FILE)
    ui.queue_free()
    print("PASS v0.19: paused first guide, explicit battle start, visible Ascension unlock, 3 independent save slots, confirmed delete/new and old-save migration")
    quit(0)
