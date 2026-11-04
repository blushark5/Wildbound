extends SceneTree
## v0.25 visual-layout regression: real Godot scene, mobile touch areas,
## compact/expanded quest, larger typography, meaningful slot controls,
## preserved v0.24 Ascension rescue, and per-slot preference persistence.
const SCENE = preload("res://scenes/incremental/wildbound_bond_v25.tscn")
const GAME = preload("res://scripts/incremental/bond_engine_v25.gd")
const OLD = preload("res://scripts/incremental/bond_engine_v24.gd")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _fail(why: String) -> void:
    push_error("Wildbound v0.25: "+why)
    SLOTS.erase_all(GAME.SAVE_FILE)
    quit(1)

func _near(a: float,b: float) -> bool:
    return absf(a-b) < 0.1

func _check_layout(ui: Control,compact: bool) -> bool:
    var panel: Panel = ui.get_node("SidebarPanel")
    var scroll: ScrollContainer = ui.get_node("SidebarScroll")
    var journey: Panel = ui.get_node("JourneyPanel")
    var tabs_y: float = 225.0 if compact else 308.0
    var scroll_y: float = 303.0 if compact else 386.0
    var shop_y: float = 213.0 if compact else 296.0
    if not _near(shop.position.y,shop_y) or not _near(scroll.position.y,scroll_y):
        _fail("Sidebar did not reposition correctly when Journey toggled");return false
    if not _near(journey.size.y,115.0 if compact else 198.0):
        _fail("Journey height incorrect");return false
    if shop.position.y < journey.position.y+journey.size.y:
        _fail("Shop overlaps the Journey panel");return false
    for tab in ui.tab_buttons.values():
        if not _near(tab.position.y,tabs_y) or tab.size.y < 39:
            _fail("Shop tabs too small or wrongly positioned");return false
    if scroll.position.y < tabs_y+40 or scroll.position.y+scroll.size.y > 707.0:
        _fail("Sidebar scroll overlaps tabs or leaves the viewport");return false
    var toggle: Button = ui.quest_fold_button
    if toggle.get_rect().intersects(ui.screen_labels["JourneyStage"].get_rect()):
        _fail("Journey collapse control covers chapter progress");return false
    return true

func _verify() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var ui: Control = SCENE.instantiate()
    root.add_child(ui)
    await process_frame
    if ui.game == null or not ui.game.has_method("replay_status") or not ui.qol25_ready:
        _fail("Main v0.25 scene did not load the new UI and gameplay engine");return
    if not ui.game.ui_compact_journey or ui.game.ui_large_text:
        _fail("Fresh game preferences should default to compact Journey and normal text");return
    if not _check_layout(ui,true):
        return
    if ui.get_node("JourneyPanel").size.y > 120.0 or ui.sidebar_title.text.find("GOLD UPGRADES") < 0:
        _fail("Compact quest and contextual shop title missing");return
    if ui.type_size_button.get_rect().intersects(ui.get_node("GoldChip").get_rect()):
        _fail("Text-size toggle overlaps Gold resources");return
    var controls: Array[Button] = [
        ui.batch_button,ui.collect_button,ui.replay_button,ui.autoform_button]
    for a in range(controls.size()):
        if controls[a].size.y < 30.0:
            _fail("Squad command touch target too short");return
        for b in range(a+1,controls.size()):
            if controls[a].get_rect().intersects(controls[b].get_rect()):
                _fail("Squad command touch targets overlap");return
    if ui.slot_markers.size() != 3:
        _fail("No clear slot 01/02/03 indicators on squad cards");return

    # Quest can expand/collapse without hiding the claim button, and the
    # upgrade viewport grows when the quest is compacted.
    var compact_height: float = ui.get_node("SidebarScroll").size.y
    ui._toggle_journey()
    if ui.game.ui_compact_journey or not _check_layout(ui,false):
        return
    if ui.get_node("SidebarScroll").size.y >= compact_height:
        _fail("Expanded quest did not trade shop space for details");return
    if not ui.screen_labels["QuestReward"].visible or not ui.screen_labels["QuestHint"].visible:
        _fail("Expanded quest reward and description not visible");return
    ui._toggle_journey()
    if not ui.game.ui_compact_journey or not _check_layout(ui,true):
        return
    if not ui.trail_button.visible or ui.trail_button.size.y < 35.0:
        _fail("Quest claim button inaccessible while collapsed");return

    # Contextual title tracks all four right-side tabs and Gold x10.
    ui._choose_bulk(10)
    if not ui.sidebar_title.text.contains("x10"):
        _fail("Shop heading doesn't show current purchase batch");return
    ui._switch_tab("LEGACY")
    if not ui.sidebar_title.text.contains("PERMANENT POWER") or not _check_layout(ui,true):
        return
    ui._switch_tab("WORLD")
    if not ui.sidebar_title.text.contains("WORLD & TACTICS") or not _check_layout(ui,true):
        return
    ui._switch_tab("GROW")
    ui._toggle_text_size()
    if not ui.game.ui_large_text or not ui.type_size_button.text.contains("A−"):
        _fail("Large type control did not change state");return
    var first: Label = ui.active_rows[1]["info"]
    if first.get_theme_font_size("font_size") != 12:
        _fail("Upgrade text size did not actually enlarge");return
    if ui.card_details[String(ui.CHALLENGE.ORDER[0])].get_theme_font_size("font_size") != 12:
        _fail("Creature detail text did not enlarge");return

    # Preview readability on the real Field Guide, element columns and
    # unambiguous equipped-slot actions.
    ui.guide_dialog.hide()
    ui._open_codex()
    ui._refresh_codex()
    if ui.codex_layer.get_node("SelectSlotPrompt").text != "REPLACE SLOT 1":
        _fail("Field Guide doesn't tell the player which squad slot is being replaced");return
    var named: Dictionary = {}
    for kind in ui.game.squad_slots:
        named[kind] = true
    for i in range(3):
        var id: String = String(ui.game.squad_slots[i])
        var action: Button = ui.codex_cards[id]["action"]
        if i == 0 and (not action.disabled or not action.text.contains("IN SLOT 1")):
            _fail("Selected owned slot still has confusing MOVE HERE copy");return
        if i > 0 and (action.disabled or not action.text.contains("SWAP INTO SLOT 1")):
            _fail("Other equipped creature lacks clear swap-to-slot action");return
    for element in ["Earth","Water","Fire","Air"]:
        var n: int = 0
        for k in ui.game.squad_slots:
            if String(GAME.CATALOG[k]["element"]) == element:
                n += 1
        var headline: Label = ui.codex_layer.get_node("ElementLabel_"+element)
        if not headline.text.contains("%d / 3" % n):
            _fail("Field Guide element heading doesn't count owned species");return
    ui._choose_slot(2)
    var equipped: String = String(ui.game.squad_slots[2])
    if not (ui.codex_cards[equipped]["action"] as Button).text.contains("IN SLOT 3"):
        _fail("Switching slot doesn't update actions");return
    ui._close_codex()

    # Old saves load with compact mode but can remember the user's revised
    # choice independently across each of the three local browser slots.
    ui._toggle_journey()
    ui.game.save()
    var restored = GAME.new()
    restored.initialize_alpha()
    if not restored.load_save() or restored.ui_compact_journey or not restored.ui_large_text:
        _fail("UI preferences did not persist to the active save slot");return
    ui._load_slot(2)
    if not ui.game.ui_compact_journey or ui.game.ui_large_text or not _check_layout(ui,true):
        _fail("Fresh Slot 2 should use clean independent default preferences");return
    ui._load_slot(1)
    if ui.game.ui_compact_journey or not ui.game.ui_large_text or not _check_layout(ui,false):
        _fail("Returning to Slot 1 lost UI settings");return

    # Normal combat recovery must still work after the interface reflow.
    ui.guide_dialog.hide()
    ui._strike()
    if not ui.playing or not ui.game.battle_started:
        _fail("First battle could not begin");return
    ui.game.best_wave = 21
    ui.game.run_peak = 21
    ui.game.wave = 21
    ui.game.awaiting_next = false
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.game._setup_trainer_fight()
    ui._ascend()
    if ui.game.ascensions != 1 or not ui.ascent_results.visible:
        _fail("Existing Ascension flow broke under UI refactor");return
    ui.ascent_results.hide()
    ui._close_ascent_results()
    await process_frame
    if not ui.playing or ui.strike_button.disabled:
        _fail("Old Ascension soft lock reappeared");return

    # Migrate a real older v0.24 save without touching creatures or Echoes.
    SLOTS.erase_all(GAME.SAVE_FILE)
    var old = OLD.new()
    old.initialize_alpha()
    old.load_save()
    old.battle_started = true
    old.gold = 47.0
    old.save()
    var migrated = GAME.new()
    migrated.initialize_alpha()
    if not migrated.load_save() or migrated.gold < 47.0:
        _fail("v0.24 save data was lost during UI-only migration");return
    if not migrated.ui_compact_journey or migrated.ui_large_text:
        _fail("Old save migration picked incorrect interface defaults");return

    SLOTS.erase_all(GAME.SAVE_FILE)
    ui.queue_free()
    print("PASS v0.25: collapsible quest and larger shop, touch targets, 3 squad numbers, large text mode, four contextual tabs, Field Guide owned counts and slot actions, independent preferences, Ascension recovery and v0.24 migration")
    quit(0)
