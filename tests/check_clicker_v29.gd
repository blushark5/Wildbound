extends SceneTree
## v0.29: check the LIVE Godot screen and all its connected actions.
const SCENE = preload("res://scenes/incremental/wildbound_bond_v29.tscn")
const GAME = preload("res://scripts/incremental/bond_engine_v25.gd")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("v0.29: "+message)
    SLOTS.erase_all(GAME.SAVE_FILE)
    quit(1)

func _run() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var ui: Control = SCENE.instantiate()
    root.add_child(ui)
    await process_frame
    if not ui.clicker29_ready or not ui.clicker29_layer.visible:
        _fail("Real clicker interface not built");return
    if ui.strike_button.visible or not ui.action29.visible:
        _fail("Original clutter still visible or primary battle missing");return
    if not ui.menu28_button.visible or ui.drawer_open:
        _fail("Menu should be visible and closed on launch");return
    if ui.unit29_rows.size() != 5 or ui.party29_rows.size() != 3:
        _fail("Left vertical training roster or small party strip missing");return
    if ui.enemy29.texture == null:
        _fail("Live enemy sprite missing from the large arena");return
    if ui.clicker29_layer.get_node("V29Valley").texture == null:
        _fail("New scenic original background not imported");return
    if not ui.action29.text.contains("START") or ui.farm29.visible:
        _fail("Opening battle actions incorrect");return
    var key: String = String(ui.game.squad_slots[0])
    var level: int = ui.game.unit_level(key)
    ui.game.gold = 500000.0
    ui._refresh()
    if ui.unit29_rows[0]["button"].disabled:
        _fail("Creature Level Up incorrectly disabled");return
    var gold: float = ui.game.gold
    ui._buy_roster29(0)
    if ui.game.unit_level(key) != level+1 or ui.game.gold >= gold:
        _fail("Displayed Level Up was not a real purchase");return
    ui._toggle_main_menu()
    if not ui.drawer_open or not ui.home28.visible:
        _fail("Menu overlay no longer opens");return
    ui._show_section("GROW")
    if not ui.drawer_open or ui.home28.visible:
        _fail("General Gold upgrades lost inside menu");return
    ui._close_drawer()
    ui._strike()
    if not ui.game.battle_started or not ui.playing:
        _fail("New START BATTLE is not connected to game");return
    for i in range(3):
        if ui.game.awaiting_next:
            break
        var foe: Dictionary = ui.game.rival_units[i]
        if float(foe.get("hp",0.0)) > 0.0:
            ui.game._damage_rival(i,float(foe["hp"])+100.0,key)
    ui._refresh()
    if not ui.game.awaiting_next or not ui.farm29.visible or not ui.action29.text.contains("NEXT"):
        _fail("Stage-clear Next/Farm interface broken");return
    var essence: int = ui.game.essence
    ui._repeat()
    ui._refresh()
    if not ui.game.repeat_wave or ui.game.essence != essence:
        _fail("Farming mechanic or no-Essence rule broken");return
    ui._repeat()
    if ui.game.repeat_wave:
        _fail("Cannot resume pushing stages");return
    ui.game.best_wave = 21
    ui.game.run_peak = 21
    ui.game.wave = 21
    ui.game.awaiting_next = false
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.game._setup_trainer_fight()
    ui._ascend()
    if ui.game.ascensions != 1:
        _fail("Ascension inaccessible");return
    ui.ascent_results.hide()
    ui._close_ascent_results()
    await process_frame
    if not ui.playing or ui.action29.disabled:
        _fail("Post-Ascension battle is stuck");return
    SLOTS.erase_all(GAME.SAVE_FILE)
    ui.queue_free()
    print("PASS v0.29: large arena, original art, roster, real leveling, menu, first battle, farming, Ascension and recovery")
    quit(0)
