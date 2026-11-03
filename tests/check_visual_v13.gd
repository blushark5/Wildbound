extends SceneTree
const SCENE = preload("res://scenes/incremental/wildbound_visual_v13.tscn")
const GAME = preload("res://scripts/incremental/collection_engine_v12.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _fail(message: String) -> void:
    push_error("Wildbound v0.13 visual QA: "+message)
    quit(1)

func _verify() -> void:
    var game = GAME.new()
    game.initialize_alpha()
    game.initialize_squads()
    if game.collection_count() != 1 or game.hatch_cost() != 5:
        _fail("Visual overhaul changed existing two-currency collection mechanics");return
    if game.CATALOG.size() != 12:
        _fail("All twelve unique creature species must remain available");return
    print("V13 phase: actual redesigned battle scene")
    var ui: Control = SCENE.instantiate() as Control
    root.add_child(ui)
    if not ui.visual_ready or ui.get_node_or_null("FieldGuideOverlay") == null:
        _fail("New Field Guide UI did not build");return
    if ui.get_node_or_null("GoldChip") == null or ui.get_node_or_null("EssenceChip") == null:
        _fail("Separate Gold and Essence visual counters are missing");return
    if ui.get_node_or_null("DuelSigil") == null or ui.get_node_or_null("PortraitWell_0") == null:
        _fail("Duel arena and squad portrait styling missing");return
    if ui.get_node_or_null("CoinIcon") == null or ui.get_node_or_null("EssenceIcon") == null:
        _fail("Currency artwork missing");return
    for icon in ui.currency_icons:
        if icon.texture == null:
            _fail("Visible currency icon failed to load");return
    if ui.scenic_art.texture == null:
        _fail("New biome-themed duel arena art not loaded");return
    if ui.codex_layer.visible:
        _fail("Field Guide should not obscure the game on startup");return
    if ui.get_node_or_null("BondFill_0") == null:
        _fail("Individual progression bars missing from squad cards");return
    if ui.game.occupied_slots() != 1 or ui.game.essence != 0:
        _fail("Visual pass must preserve one starter and slow Essence gain");return
    if ui.get_node_or_null("CollectionShortcut") == null:
        _fail("Field Guide must be accessible from the battle screen");return

    print("V13 phase: inspect full guide")
    ui._open_codex()
    if not ui.codex_layer.visible or ui.playing:
        _fail("Opening Field Guide did not pause live combat");return
    if ui.codex_cards.size() != 12:
        _fail("Field Guide must show 4 columns x 3 original species");return
    if ui.codex_hatch == null:
        _fail("Hatching action not present in Field Guide");return
    if not ui.codex_hatch.disabled:
        _fail("Hatch should be disabled without earned Essence");return
    for key in ui.game.COLLECTION_ORDER:
        if ui.codex_cards[key]["picture"].texture == null:
            _fail("Missing rendered compendium portrait for "+String(key));return
    if ui.codex_cards["cindlet"]["action"].disabled == false:
        _fail("Unowned species must not be assignable");return
    ui._choose_slot(1)
    ui.game.essence = 5
    ui._refresh_codex()
    if ui.codex_hatch.disabled:
        _fail("Hatch button should clearly enable at 5 earned Essence");return
    ui._codex_hatch()
    if not ui.game.has_instance("cindlet"):
        _fail("Field Guide hatch doesn't add real creature");return
    if ui.codex_cards["cindlet"]["action"].disabled:
        _fail("Newly earned creature must be selectable in Field Guide");return
    ui._codex_assign("cindlet")
    if String(ui.game.squad_slots[1]) != "cindlet" or ui.game.occupied_slots() != 2:
        _fail("Assign button doesn't modify active game squad");return
    if not ui.codex_cards["cindlet"]["action"].disabled:
        _fail("Selected Field Guide card should indicate active squad slot");return
    ui._close_codex()
    if ui.codex_layer.visible or not ui.playing:
        _fail("Closing Field Guide should resume the prior real-time battle");return
    if not ui.ally_widgets[1]["portrait"].visible:
        _fail("Hatched Fire creature not visible in battlefield");return
    if ui.game.squad_slots[0] == ui.game.squad_slots[1]:
        _fail("Unique creatures cannot duplicate into two slots");return

    print("V13 phase: world art, progress styling, upgrade controls")
    ui.game.wave = 6
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.game.initialize_squads()
    ui._refresh_landscape()
    if ui.art_scene_element != "Air" or ui.scenic_art.texture == null:
        _fail("Stage-six Air trainer should receive its own distinct arena artwork");return
    ui._switch_tab("GROW")
    if not ui.get_node("Tab_GROW").text == "UPGRADES":
        _fail("Gold spending and creature collection tabs became confusing");return
    if ui.screen_labels["Shards"].text.find("/") < 0:
        _fail("Header must show Essence progression to next hatch");return
    for key in ["spriglet","brinlet","cindlet"]:
        if ui.card_buy[key] == null or ui.focus_buttons[key] == null:
            _fail("Creature growth and squad-selection buttons must remain functional");return
    # The Field Guide correctly persists changes; isolate this smoke test
    # so the subsequent v0.12 fresh-start regression sees a clean save.
    var saved_path: String = ui.game.SAVE_FILE
    if FileAccess.file_exists(saved_path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(saved_path))
    print("PASS v0.13: illustrated arenas, glowing HUD, full 12-portrait Field Guide, hatch, assign, pause, economy, old battle")
    quit(0)
