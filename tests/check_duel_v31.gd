extends SceneTree
## Visual/regression acceptance for v0.31 on the real Godot scene.
const SCENE = preload("res://scenes/duel/wildbound_duel_v31.tscn")
const ENGINE = preload("res://scripts/duel/duel_engine_v30.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("v0.31: "+message)
    quit(1)

func _run() -> void:
    var save_path: String = ENGINE.SAVE_FILE
    var had_save: bool = FileAccess.file_exists(save_path)
    var prior: String = FileAccess.get_file_as_string(save_path) if had_save else ""
    var ui: Control = SCENE.instantiate()
    root.add_child(ui)
    await process_frame
    if not ui.ui_live or not ui.art31_ready or ui.fx31 == null:
        _fail("Production art overlay or effects did not initialize");return
    if ui.roster_rows.size() != 3 or ui.game.SPECIES.size() != 3:
        _fail("Art pass reintroduced more than 3 creatures");return
    if ui.hero_art.texture == null or ui.enemy_art.texture == null \
            or ui.trim31.texture == null:
        _fail("Real painted sprites or border art failed to load");return
    if ui.hero_art.size.x < 200.0 or ui.enemy_art.size.x < 310.0:
        _fail("Duel staging still uses undersized original sprites");return
    if ui.game.strike_landed.get_connections().size() < 1:
        _fail("Hit effects not connected to actual damage event");return
    if ui.game.duel_finished.get_connections().size() < 1:
        _fail("Victory effect not connected to actual encounter result");return
    ui.game.new_game()
    ui._refresh()
    if not ui.game.start():
        _fail("Start duel no longer works");return
    var before_hp: float = ui.game.enemy_hp
    ui._manual_hit()
    if ui.game.enemy_hp >= before_hp or ui.fx31.particles.size() < 5:
        _fail("Actual manual strike did not spawn elemental hit effects");return
    if ui.damage_labels31.is_empty():
        _fail("Real damage did not create floating damage number");return
    # Win exactly once. Single opponent, no phantom 3v3 logic.
    for i in range(300):
        if ui.game.awaiting_next:
            break
        ui.game.hit()
    if ui.game.wins != 1 or not ui.victory31.visible or ui.victory31_left <= 0:
        _fail("Victory banner did not appear on a real stage clear");return
    if ui.fx31.particles.size() < 20:
        _fail("Victory requires a celebration burst");return
    ui._primary_action()
    if ui.game.stage != 2 or ui.victory31.visible:
        _fail("Victory card prevents NEXT STAGE or does not clear");return
    if ui.roster_rows.size() != 3 or ui.game.element("cindlet") != "Fire":
        _fail("Combat changes affected 3-element scope");return
    ui._open_menu("UPGRADES")
    if not ui.menu_active or ui.upgrade_buttons.size() != 3:
        _fail("Polished menu hides functional upgrades");return
    ui._close_menu()
    if ui.menu_active:
        _fail("Menu cannot close");return
    ui.queue_free()
    if had_save:
        var file: FileAccess = FileAccess.open(save_path,FileAccess.WRITE)
        if file != null:
            file.store_string(prior)
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
    print("PASS v0.31: premium UI, three creatures, real elemental impacts, floating damage, victory and menu controls")
    quit(0)
