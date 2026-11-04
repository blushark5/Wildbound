extends SceneTree
## Live game acceptance: v0.34 must use the ACTUAL approved-concept art.
const SCENE = preload("res://scenes/duel/wildbound_duel_v34.tscn")
const ART = preload("res://scripts/duel/concept_art_v34.gd")
const ENGINE = preload("res://scripts/duel/duel_engine_v30.gd")

func _initialize() -> void:
    call_deferred("_run")

func _fail(message: String) -> void:
    push_error("v0.34: "+message)
    quit(1)

func _run() -> void:
    var save_path: String = ENGINE.SAVE_FILE
    var had: bool = FileAccess.file_exists(save_path)
    var saved: String = FileAccess.get_file_as_string(save_path) if had else ""
    var ui: Control = SCENE.instantiate()
    root.add_child(ui)
    await process_frame
    if not ui.fidelity34_ready or not ART.load_success:
        _fail("Concept raster atlases failed to decode into real textures");return
    if not (ui.get_node("Tagline") as Label).text.contains("v0.34"):
        _fail("Displayed game version must match v0.34");return
    if ui.roster_rows.size() != 3 or ui.game.SPECIES.size() != 3:
        _fail("Visual update must preserve exactly 3 playable species");return
    if ART.background() == null or ART.background().get_width() != 864:
        _fail("Painted battle environment not installed at real 864px resolution");return
    if ui.landscape.texture != ART.background():
        _fail("The Godot scene still uses the old procedural SVG arena");return
    for kind in ENGINE.ORDER:
        var painted: Texture2D = ART.creature(kind)
        if painted == null or painted.get_width() < 155 or painted.get_height() < 110:
            _fail("Insufficient painted creature fidelity: "+kind);return
        var photo: TextureRect = ui.roster_rows[kind]["image"]
        if photo.texture != painted:
            _fail("Creature training is still displaying old tiny sprites: "+kind);return
    ui.game.new_game()
    ui._refresh()
    if ui.hero_art.texture != ART.creature(ui.game.active):
        _fail("Battle hero failed to load its concept creature art");return
    if not ui.game.start():
        _fail("New save cannot begin a duel");return
    var hp: float = ui.game.enemy_hp
    ui._manual_hit()
    if ui.game.enemy_hp >= hp:
        _fail("Battle damage changed during art-only upgrade");return
    for i in range(300):
        if ui.game.awaiting_next:
            break
        ui.game.hit()
    if ui.game.wins != 1 or not ui.victory31.visible:
        _fail("Victory feedback regressed");return
    ui._primary_action()
    if ui.game.stage != 2:
        _fail("Stage advancement regressed");return
    ui._open_menu("UPGRADES")
    if not ui.menu_active or ui.upgrade_buttons.size() != 3:
        _fail("Art update broke upgrade menu");return
    ui._close_menu()
    if ui.menu_active:
        _fail("Upgrade menu failed to close");return
    # Preserve the prior browser save exactly despite tests creating a new run.
    ui.queue_free()
    if had:
        var save: FileAccess = FileAccess.open(save_path,FileAccess.WRITE)
        if save != null:
            save.store_string(saved)
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
    print("PASS v0.34: genuine 864px painted battlefield, three high-detail creature textures, 1v1 duel, menu and saves")
    quit(0)
