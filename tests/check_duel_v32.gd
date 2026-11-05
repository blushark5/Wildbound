extends SceneTree
## v0.32 real-scene visual and combat acceptance.
const SCENE = preload("res://scenes/duel/wildbound_duel_v32.tscn")
const ENGINE = preload("res://scripts/duel/duel_engine_v30.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(why: String) -> void:
    push_error("v0.32: "+why)
    quit(1)

func _run() -> void:
    var path: String = ENGINE.SAVE_FILE
    var had: bool = FileAccess.file_exists(path)
    var before_file: String = FileAccess.get_file_as_string(path) if had else ""
    var ui: Control = SCENE.instantiate()
    root.add_child(ui)
    await process_frame
    if not ui.art31_ready or not ui.polish32_ready:
        _fail("V32 presentation did not initialize");return
    if ui.ambient32 == null or ui.fx31 == null:
        _fail("Living arena and impact trails did not initialize");return
    if ui.game.SPECIES.size() != 3 or ui.roster_rows.size() != 3:
        _fail("Game exceeds the fixed three-creature scope");return
    if not ui.enemy_art.flip_h:
        _fail("Enemy still faces away from player");return
    if ui.progress_pips32.size() != 5:
        _fail("Five-stage guardian progression markers missing");return
    ui.game.new_game()
    ui.game.gold = 5000.0
    ui._refresh()
    var initial_level: int = int(ui.game.levels["cindlet"])
    ui._train("cindlet")
    if int(ui.game.levels["cindlet"]) != initial_level+1:
        _fail("Training broke during visual polish");return
    if not ui.game.start():
        _fail("First duel cannot start");return
    ui._choose("brinlet")
    if ui.game.active != "brinlet":
        _fail("Switching to a selected element fails");return
    var hp: float = ui.game.enemy_hp
    ui._manual_hit()
    if ui.game.enemy_hp >= hp:
        _fail("Manual action no longer causes damage");return
    if ui.fx31.traveling.is_empty() or ui.fx31.particles.is_empty():
        _fail("Actual combat no longer creates elemental trails and sparks");return
    for i in range(500):
        if ui.game.awaiting_next:
            break
        ui.game.hit()
    if ui.game.wins != 1 or not ui.victory31.visible:
        _fail("Victory overlay or real 1v1 clear broken");return
    ui._primary_action()
    if ui.game.stage != 2 or ui.ribbon_timer32 <= 0.0:
        _fail("Next-stage reveal did not play");return
    ui.game.stage = 5
    ui.game._spawn()
    ui.game.fighting = true
    ui._refresh()
    if not ui.game.is_boss() or ui.stage_ribbon_name32.text != "GUARDIAN STAGE 5":
        _fail("Boss milestone presentation missing");return
    ui._open_menu("UPGRADES")
    if ui.upgrade_buttons.size() != 3 or not ui.menu_active:
        _fail("Original 3 Gold upgrades must remain accessible");return
    ui._close_menu()
    if ui.menu_active:
        _fail("Menu failed to close");return
    ui.queue_free()
    if had:
        var old: FileAccess = FileAccess.open(path,FileAccess.WRITE)
        if old != null:
            old.store_string(before_file)
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("PASS v0.32: living battle scene, creature facing, real elemental trails, guardian pips, levels, 1v1 and saves")
    quit(0)
