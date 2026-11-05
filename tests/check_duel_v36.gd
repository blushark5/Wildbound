extends SceneTree
## v0.36 art-first acceptance: actual 1280px raster arena and distinct
## transparent creatures must be bound to the live Godot battle scene.
const SCENE = preload("res://scenes/duel/wildbound_duel_v36.tscn")
const ART = preload("res://scripts/duel/painted_art_v36.gd")
const ENGINE = preload("res://scripts/duel/duel_engine_v30.gd")
func _initialize() -> void:
    call_deferred("_run")
func _fail(why: String) -> void:
    push_error("v0.36 acceptance: "+why)
    quit(1)
func _run() -> void:
    var save_path: String = ENGINE.SAVE_FILE
    var had: bool = FileAccess.file_exists(save_path)
    var previous: String = FileAccess.get_file_as_string(save_path) if had else ""
    if not ART.ready():
        _fail("Illustrated atlas was not decoded and installed");return
    if ART.environment().get_width() != 1280:
        _fail("1280px painted environment missing");return
    for creature in ENGINE.ORDER:
        var tex: Texture2D = ART.creature(creature)
        if tex == null or tex.get_width() < 240 or tex.get_height() < 150:
            _fail("Missing full-body transparent painting for "+creature);return
        var image: Image = tex.get_image()
        if image.get_pixel(0,0).a > 0.25:
            _fail("Sprite background isn't transparent: "+creature);return
    var ui: Control = SCENE.instantiate()
    root.add_child(ui)
    await process_frame
    if not ui.composition36_ready or not ui.premium35_ready:
        _fail("New Godot visual scene did not initialize");return
    if ui.hero_art.texture != ART.creature(ui.game.active):
        _fail("Hero still uses lower-quality legacy sprites");return
    if ui.landscape.texture != ART.environment():
        _fail("Stage still uses the legacy background");return
    if not (ui.get_node("Tagline") as Label).text.contains("v0.36"):
        _fail("Live version text not updated");return
    if ui.team_buttons35.size() != 3 or ui.game.SPECIES.size() != 3:
        _fail("Three-creature roster changed");return
    if ENGINE.SAVE_FILE != "user://wildbound_duel_v30.json":
        _fail("Existing browser save path was modified");return
    ui.game.new_game()
    ui._refresh()
    if not ui.game.start():
        _fail("Battle failed to start");return
    var before: float = ui.game.enemy_hp
    ui._manual_hit()
    if ui.game.enemy_hp >= before:
        _fail("Manual combat assistance regressed");return
    for i in range(500):
        if ui.game.awaiting_next:
            break
        ui.game.hit()
    if ui.game.wins != 1 or not ui.victory31.visible:
        _fail("Victory presentation regressed");return
    ui._primary_action()
    if ui.game.stage != 2:
        _fail("Advance progression regressed");return
    ui._open_menu("UPGRADES")
    if not ui.menu_active or ui.upgrade_buttons.size() != 3:
        _fail("Upgrades drawer not operational");return
    ui._close_menu()
    if ui.menu_active:
        _fail("Menu cannot close");return
    ui.game.stage = 5
    ui.game._spawn()
    ui._refresh()
    if not ui.game.is_boss() or ui.stage_title.text != "GUARDIAN TRIAL":
        _fail("Guardian encounter not reflected by real HUD");return
    ui.queue_free()
    if had:
        var file: FileAccess = FileAccess.open(save_path,FileAccess.WRITE)
        if file != null:
            file.store_string(previous)
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
    print("PASS v0.36: actual 1280px stage, three full-body raster sprites, 1v1 combat, stage advance, guardian, upgrades and saves")
    quit(0)
