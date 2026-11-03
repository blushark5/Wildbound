extends SceneTree
const V08 = preload("res://scenes/incremental/wildbound_visual_v08.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _die(note: String) -> void:
    push_error("WILDBOUND V0.8: "+note)
    quit(1)

func _verify() -> void:
    var scene: Control = V08.instantiate() as Control
    root.add_child(scene)
    if scene.get_node_or_null("BattleFieldEffectsV08") == null:
        _die("Stage-sized decorative effects missing"); return
    if scene.journey_ticks.size() != 10:
        _die("Ten-wave Guardian progress HUD missing"); return
    if scene.get_node_or_null("TacticalReadout") == null or scene.get_node_or_null("ThreatReadout") == null:
        _die("Dedicated tactical readouts missing"); return
    for tab_name in scene.TABS:
        if scene.tab_buttons[tab_name].size.x < 70.0:
            _die("Sanctuary tab is still too narrow"); return
    if scene.game.levels["spriglet"] < 1 or scene.ally_portrait.texture == null:
        _die("Starting creature failed to load"); return
    var initial_tab: String = scene.tab
    if not scene._handle_shortcut(KEY_Q) or scene.tab == initial_tab:
        _die("Live keyboard tab navigation broken"); return
    var previous_batch: int = scene.batch
    scene._handle_shortcut(KEY_B)
    if scene.batch == previous_batch:
        _die("Batch purchase shortcut not wired"); return
    var before_repeat: bool = scene.game.repeat_wave
    scene._handle_shortcut(KEY_F)
    if scene.game.repeat_wave == before_repeat:
        _die("Wave-farming shortcut not wired"); return
    var before_run: bool = scene.running
    scene._handle_shortcut(KEY_P)
    if scene.running == before_run:
        _die("Pause shortcut not wired"); return
    scene._handle_shortcut(KEY_P)
    scene.game.gold = 2000.0
    scene.game.buy_levels("brinlet",1)
    scene.game.buy_levels("cindlet",1)
    scene.call("_refresh")
    if scene._active_creatures() != 3:
        _die("Existing three-creature battle formation regressed"); return
    var prior_enemy_hp: float = scene.game.enemy_hp
    scene.get_node("Tap").emit_signal("pressed")
    if scene.game.enemy_hp >= prior_enemy_hp and scene.game.wave == 1:
        _die("Strike no longer inflicts real damage"); return
    scene.game.wave = 10
    scene.game._spawn_enemy()
    scene.game._fit_enemy_to_region()
    scene.call("_refresh")
    if not scene.fury_label.text.contains("FURY") or not scene.threat_readout.text.contains("GUARDIAN"):
        _die("Guardian warning HUD missing"); return
    if scene.journey_ticks[9].color != scene.TRACK_GUARDIAN:
        _die("Guardian progress track not visibly complete"); return
    if scene.enemy_portrait.texture == null or scene.enemy_portrait.texture.get_width() != 128:
        _die("Evolved Guardian illustration regressed"); return
    if scene.tab_scroll.size.y < 375.0:
        _die("Sanctuary needs a usable scroll area"); return
    print("PASS v0.8: actual combat, 3 allies, ten-wave meter, Guardian warnings, controls, original artwork")
    quit(0)
