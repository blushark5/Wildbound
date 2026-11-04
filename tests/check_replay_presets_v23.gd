extends SceneTree
## v0.23 real Godot gameplay, save migration and UI regression.
const GAME = preload("res://scripts/incremental/bond_engine_v23.gd")
const PRIOR = preload("res://scripts/incremental/bond_engine_v22.gd")
const SCENE = preload("res://scenes/incremental/wildbound_bond_v23.tscn")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")

func _initialize() -> void:
    call_deferred("_verify")

func _fail(why: String) -> void:
    push_error("v0.23: "+why)
    SLOTS.erase_all(GAME.SAVE_FILE)
    quit(1)

func _win(g: RefCounted) -> void:
    for i in range(3):
        if g.awaiting_next:
            break
        var u: Dictionary = g.rival_units[i]
        if float(u["hp"]) > 0.0:
            g._damage_rival(i,float(u["hp"])+100.0,String(g.squad_slots[0]))

func _verify() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var g = GAME.new()
    g.initialize_alpha()
    g.load_save()
    if g.replay_route_enabled or g.toggle_replay_route():
        _fail("Replay must be locked before the first Ascension");return
    if not g.ascension_chronicle.is_empty() or g.squad_presets.size() != 0:
        _fail("Fresh run invented history or squad presets");return
    if g.research_details("speed")["summary"].find("+8% damage") < 0:
        _fail("Permanent Speed Echo research lacks its actual mechanic");return

    g.battle_started = true
    _win(g)
    if g.lifetime_cleared_stage != 1 or g.lifetime_winning_teams.size() != 1:
        _fail("Lifetime first clear and stage history broken");return
    if not g.save_squad_preset(1):
        _fail("Cannot store first valid 3-family squad");return
    var remembered: Array[String] = g.preset_team(1)
    if remembered.size() != 3:
        _fail("Saved preset missing one or more species");return
    if not g.assign_creature(0,remembered[1]) or g.squad_slots == remembered:
        _fail("Could not deliberately change the squad to test loadout swapping");return
    if not g.load_squad_preset(1) or g.squad_slots != remembered or g.manual_override_stage != 2:
        _fail("Loading a team preset did not recover exact slots/manual authority");return
    if g.load_squad_preset(2) or g.save_squad_preset(4):
        _fail("Missing/invalid presets must not be applied");return

    # The existing Ascension threshold is unchanged. Set a simulated
    # post-clear state, without changing combat Gold or difficulty.
    g.best_wave = 21
    g.run_peak = 21
    g.wave = 21
    g.awaiting_next = false
    g._spawn_enemy()
    g._fit_enemy_to_region()
    g._setup_trainer_fight()
    g.total_seconds = 780.0
    if not g.ascend() or g.lifetime_cleared_stage != 20 or g.ascensions != 1:
        _fail("Completed Stage 20 failed to unlock Ascension and lifetime limit");return
    if g.ascension_chronicle.size() != 1:
        _fail("First Ascension did not produce Chronicle history");return
    var entry: Dictionary = g.ascension_chronicle[0]
    if int(entry["number"]) != 1 or int(entry["best_stage"]) != 20 or float(entry["duration"]) != 780.0:
        _fail("Chronicle reward, stage or run duration was recorded incorrectly");return
    if g.preset_team(1) != remembered:
        _fail("Ascension destroyed permanently saved squad preset");return

    if not g.toggle_replay_route() or not g.replay_route_enabled or not g.auto_advance_enabled:
        _fail("Replay failed to enable through previously cleared stages");return
    var prior_essence: int = g.essence
    _win(g)
    if g.wave != 2 or g.awaiting_next or not g.auto_advance_enabled:
        _fail("Replay did not advance automatically to an already cleared stage");return
    if g.essence != prior_essence:
        _fail("Replay of a lifetime-cleared stage awarded Essence again");return
    if g.last_autoformed_stage != 2:
        _fail("Auto-Form did not prepare the NEXT familiar stage during Replay");return

    # Reach the HISTORICAL boundary. The next new enemy must never auto-play
    # even if Stage 20 is beaten quickly by a newly powerful Ascended team.
    g.wave = 20
    g.awaiting_next = false
    g.repeat_wave = false
    g._spawn_enemy()
    g._fit_enemy_to_region()
    g._setup_trainer_fight()
    _win(g)
    if g.wave != 21 or not g.awaiting_next or g.auto_advance_enabled:
        _fail("Replay entered uncleared Stage 21 instead of stopping at frontier");return
    if not g.replay_frontier_reached or g.is_replay_eligible(21):
        _fail("Replay frontier flag/eligibility incorrectly grants new stage autonomy");return
    if not g.enter_next_stage() or g.auto_advance_enabled:
        _fail("Manually entering Stage 21 should remain manual");return

    # Losing during a replay must not trap players in a wipe loop.
    g.wave = 5
    g.awaiting_next = false
    g.replay_frontier_reached = false
    g.auto_advance_enabled = true
    g._setup_trainer_fight()
    g._regroup()
    if g.replay_route_enabled or g.auto_advance_enabled or not g.awaiting_next:
        _fail("A tactical defeat should stop replay until manually re-enabled");return

    # Permanent Echo speed research previously did not affect the 12-line
    # collection combat engine. Ensure both intended factors now apply.
    var species: String = String(g.squad_slots[0])
    var old_attack: float = g.combat_damage(species)
    var old_interval: float = g.combat_interval(species)
    g.research["speed"] = int(g.research["speed"])+1
    if absf(g.combat_damage(species)/old_attack-1.08) > 0.0001:
        _fail("Speed research not increasing real 3v3 creature damage by 8%");return
    if absf(g.combat_interval(species)/old_interval-0.97) > 0.0001:
        _fail("Speed research not reducing real 3v3 attack interval by 3%");return
    var speed_effect: Dictionary = g.research_details("speed")
    if not String(speed_effect["effect"]).contains("Damage") or not String(speed_effect["effect"]).contains("interval"):
        _fail("Ascension Echo research preview not explaining real impact");return

    g.save()
    var reloaded = GAME.new()
    reloaded.initialize_alpha()
    if not reloaded.load_save() or reloaded.ascension_chronicle.size() != 1:
        _fail("Chronicle did not survive local browser save");return
    if reloaded.preset_team(1) != remembered or reloaded.replay_route_enabled:
        _fail("Preset or replay-off state not persisted");return

    # Existing v0.22 saved collection/Ascensions should migrate safely
    # without fabricating older Chronicle entries or auto-starting replay.
    SLOTS.erase_all(GAME.SAVE_FILE)
    var old = PRIOR.new()
    old.initialize_alpha()
    old.load_save()
    old.best_wave = 21
    old.run_peak = 21
    old.ascend()
    old.save()
    var migrated = GAME.new()
    migrated.initialize_alpha()
    if not migrated.load_save() or migrated.ascensions != 1 or migrated.replay_route_enabled or not migrated.ascension_chronicle.is_empty():
        _fail("v0.22 save migration rerolled progress or invented runs");return

    # Exercise REAL v0.23 game scene and its v0.19 save-slot hot swapping.
    SLOTS.erase_all(GAME.SAVE_FILE)
    var ui: Control = SCENE.instantiate()
    root.add_child(ui)
    await process_frame
    if not ui.game.has_method("save_squad_preset") or not ui.game.has_method("toggle_replay_route"):
        _fail("Live game is still using an earlier engine");return
    if ui.preset_load_buttons.size() != 3 or ui.preset_store_buttons.size() != 3:
        _fail("Field Guide missing 3 usable SAVE/LOAD team presets");return
    if ui.replay_button == null or ui.chronicle_dialog == null or not ui.replay_button.disabled:
        _fail("Replay or Chronicle UI missing/initial lock wrong");return
    ui.guide_dialog.hide()
    ui._open_codex()
    ui._refresh_codex()
    if ui.preset_load_buttons[0].disabled == false:
        _fail("Empty preset loads should be disabled");return
    ui._store_preset(1)
    if ui.preset_load_buttons[0].disabled or not FileAccess.file_exists(GAME.SAVE_FILE):
        _fail("Storing preset must enable loading and save data immediately");return
    ui._close_codex()
    ui._switch_tab("LEGACY")
    var research_stat: bool = false
    for row in ui.active_rows:
        if String(row["mode"]) == "research" and String(row["key"]) == "speed":
            research_stat = String(row["info"].text).contains("Damage")
    if not research_stat:
        _fail("Live Echo shop lacks current/next permanent upgrade effect");return
    ui._show_chronicle()
    if not ui.chronicle_dialog.visible:
        _fail("Chronicle details did not open");return
    ui.chronicle_dialog.hide()
    ui._load_slot(2)
    if not ui.game.has_method("save_squad_preset") or not ui.game.has_method("replay_status"):
        _fail("Switching saves downgraded active engine to old v0.19");return
    if ui.game.battle_started or ui.game.squad_presets.size() != 0:
        _fail("New save slot inherited another slot's game/presets");return
    ui._load_slot(1)
    if not ui.game.has_method("replay_status") or ui.game.preset_team(1).size() != 3:
        _fail("Switching back failed to restore newest engine and squad preset");return
    ui.queue_free()
    SLOTS.erase_all(GAME.SAVE_FILE)
    print("PASS v0.23: Ascension-only Replay, frontier stop, defeat stop, permanent 3-team presets, Speed Echo research combat effect, Chronicle, mobile controls, old-save migration, 3-slot engine consistency")
    quit(0)
