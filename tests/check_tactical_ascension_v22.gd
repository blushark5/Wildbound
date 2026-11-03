extends SceneTree
## v0.22 actual Godot validation: unlocked-on-Ascension Auto-Form,
## historical upper bound, manual overrides, old-save migration, exact
## discounted? no: precisely priced bulk upgrades, and staged UI previews.
const GAME = preload("res://scripts/incremental/bond_engine_v22.gd")
const OLD = preload("res://scripts/incremental/bond_engine_v20.gd")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")
const SCENE = preload("res://scenes/incremental/wildbound_bond_v22.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _fail(why: String) -> void:
    push_error("Wildbound v0.22: "+why)
    SLOTS.erase_all(GAME.SAVE_FILE)
    quit(1)

func _win(g: RefCounted) -> void:
    for i in range(3):
        if g.awaiting_next:
            break
        var enemy: Dictionary = g.rival_units[i]
        if float(enemy["hp"]) > 0.0:
            g._damage_rival(i,float(enemy["hp"])+100.0,String(g.squad_slots[0]))

func _verify() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var fresh = GAME.new()
    fresh.initialize_alpha()
    fresh.load_save()
    if fresh.ascensions != 0 or fresh.lifetime_cleared_stage != 0 or fresh.is_autoform_eligible(1):
        _fail("First adventure should not Auto-Form or claim previous stage clears");return
    if fresh.toggle_auto_form():
        _fail("Auto-Form must be unavailable before the first Ascension");return
    fresh.battle_started = true
    _win(fresh)
    if fresh.lifetime_cleared_stage != 1 or fresh.lifetime_winning_teams.size() != 1:
        _fail("True first stage win did not populate permanent stage/squad history");return
    # Simulate other genuine clears before Ascension while preserving the
    # original economy/Essence code. Ascend still requires Stage 20.
    fresh.run_peak = 21
    fresh.best_wave = 21
    fresh.wave = 21
    fresh.awaiting_next = false
    fresh._spawn_enemy()
    fresh._fit_enemy_to_region()
    fresh._setup_trainer_fight()
    if not fresh.ascend():
        _fail("Stage-20 completed run could not Ascend");return
    if fresh.ascensions != 1 or fresh.lifetime_cleared_stage != 20 or fresh.wave != 1:
        _fail("Ascension lost highest COMPLETE stage or incorrect new run");return
    if not fresh.is_autoform_eligible(20) or fresh.is_autoform_eligible(21):
        _fail("Auto-Form must stop exactly after lifetime Stage 20");return
    if fresh.last_autoformed_stage != 1 or fresh.squad_slots.size() != 3:
        _fail("First stage of new Ascension did not prepare a squad");return
    if fresh.recommended_team_for(21).size() != 0 or fresh.recommended_team_for(20).size() != 3:
        _fail("Recommendation illegally formed an unbeaten stage");return
    var original: Array[String] = fresh.squad_slots.duplicate()
    var swapped: String = String(fresh.squad_slots[1])
    if not fresh.assign_creature(0,swapped):
        _fail("Player could not manually swap creatures");return
    var manual: Array[String] = fresh.squad_slots.duplicate()
    if manual == original or fresh.manual_override_stage != 1 or fresh._apply_autoform_stage(1):
        _fail("Manual team edit was overwritten by automatic optimization");return
    # A new stage clears the override. Opponents have a NEW encounter seed.
    fresh.wave = 2
    fresh.manual_override_stage = -1
    fresh.last_autoformed_stage = -1
    if not fresh._apply_autoform_stage(2) or fresh.squad_slots.size() != 3:
        _fail("Auto-Form failed on next previously completed stage");return
    var foes: Array = fresh.roster_for(2)
    var expected: int = 0
    for kind in fresh.squad_slots:
        var match: Dictionary = fresh.matchup_analysis(kind,2)
        if int(match["strong"]) >= 1:
            expected += 1
        for enemy in foes:
            if fresh.multiplier(kind,String(enemy)) > 2.01:
                _fail("Invalid element combat multiplier");return

    fresh.save()
    var reloaded = GAME.new()
    reloaded.initialize_alpha()
    if not reloaded.load_save() or reloaded.lifetime_cleared_stage != 20:
        _fail("Lifetime stage record did not survive save/load");return
    if reloaded.lifetime_winning_teams.size() != 1 or reloaded.ascensions != 1:
        _fail("Historical lineup lost across Ascension/save");return
    if not reloaded.toggle_auto_form() or reloaded.is_autoform_eligible(2):
        _fail("Auto-Form OFF switch did not block formation");return
    reloaded.save()
    var off_reload = GAME.new()
    off_reload.initialize_alpha()
    if not off_reload.load_save() or off_reload.auto_form_enabled:
        _fail("Auto-Form preference not saved");return

    # Batch affordability is EXACT, never 10x a single-rank cost.
    var economical = GAME.new()
    economical.initialize_alpha()
    economical.load_save()
    economical.gold = 90.0
    var exact: Dictionary = economical.module_batch_quote("power",10)
    if bool(exact["full"]) or economical.buy_module_batch("power",10) != 0:
        _fail("x10 bought partial ranks with insufficient Gold");return
    economical.gold = 1.0e9
    var quote: Dictionary = economical.module_batch_quote("bounty",10)
    if not bool(quote["full"]) or int(quote["count"]) != 10:
        _fail("x10 quote should be fully affordable");return
    var previous_gold: float = economical.gold
    if economical.buy_module_batch("bounty",10) != 10 or int(economical.modules["bounty"]) != 10:
        _fail("x10 Gold upgrades not purchased");return
    if absf((previous_gold-economical.gold)-float(quote["cost"])) > 0.01:
        _fail("Gold batch quoted cost did not match charged price");return
    var budget: float = economical.gold
    var max_quote: Dictionary = economical.module_batch_quote("crit",0)
    if not bool(max_quote["full"]) or int(max_quote["count"]) < 1:
        _fail("MAX failed to price affordable Critical ranks");return
    var bought: int = economical.buy_module_batch("crit",0)
    if bought != int(max_quote["count"]) or economical.gold < -0.001 or economical.gold > budget:
        _fail("MAX spent wrong Gold or did not buy all affordable ranks");return
    if int(economical.modules["power"]) != 0:
        _fail("Bulk purchase changed another upgrade type");return

    # v0.20 legacy migration: previously recorded winners must become
    # durable lifetime history without modifying the original save.
    SLOTS.erase_all(GAME.SAVE_FILE)
    var previous = OLD.new()
    previous.initialize_alpha()
    previous.load_save()
    _win(previous)
    previous.save()
    var migrated = GAME.new()
    migrated.initialize_alpha()
    if not migrated.load_save() or migrated.lifetime_cleared_stage != 1:
        _fail("Older v0.20 save lacks safe lifetime high-water migration");return
    if migrated.lifetime_winning_teams.size() != 1:
        _fail("Older v0.20 stage winner not imported into lifetime history");return

    SLOTS.erase_all(GAME.SAVE_FILE)
    var ui: Control = SCENE.instantiate() as Control
    root.add_child(ui)
    await process_frame
    if ui.autoform_button == null or ui.matchup_button == null or ui.matchup_label == null:
        _fail("Auto-Form and elemental comparison controls not visible");return
    if not ui.autoform_button.disabled or ui.matchup_label.text.length() < 12:
        _fail("First-run Auto-Form should be locked; matchup summary should be live");return
    if ui.bulk_mode_buttons.size() != 4:
        _fail("x1/x10/x25/MAX buttons absent from Gold shop");return
    ui._choose_bulk(10)
    if ui.bulk_amount != 10:
        _fail("Bulk x10 selector did not change mode");return
    ui._show_matchups()
    if not ui.matchup_dialog.visible or not ui.matchup_dialog.dialog_text.contains("2x damage"):
        _fail("Matchup explanation missing from in-game mobile dialog");return
    ui.matchup_dialog.hide()
    ui.game.run_peak = 20
    ui.game.best_wave = 20
    ui._request_ascension()
    if not ui.ascend_dialog.visible or not ui.ascend_dialog.dialog_text.contains("BONDED RANKS"):
        _fail("Ascension preview missing exact Echoes or prepared Bond Ranks");return
    ui.ascend_dialog.hide()
    ui._ascend()
    if ui.game.ascensions != 1 or not ui.ascent_results.visible:
        _fail("Ascension results summary did not appear after confirmation");return
    if not ui.ascent_results.dialog_text.contains("ECHOES") or ui.autoform_button.disabled:
        _fail("Ascension results missing rewards or Auto-Form did not unlock");return
    ui.ascent_results.hide()
    ui._close_ascent_results()
    if not ui.game.auto_form_enabled:
        _fail("Auto-Form should default on after the first Ascension");return
    SLOTS.erase_all(GAME.SAVE_FILE)
    print("PASS v0.22: post-Ascension matchup-aware Auto-Form to exact lifetime stage only, manual priority, historic winners, deterministic counters, exact x1/x10/x25/MAX Gold, save migrations, Ascension preview and results")
    quit(0)
