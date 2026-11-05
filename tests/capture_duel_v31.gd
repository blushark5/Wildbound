extends SceneTree
const SCENE = preload("res://scenes/duel/wildbound_duel_v31.tscn")
const ENGINE = preload("res://scripts/duel/duel_engine_v30.gd")

func _initialize() -> void:
    call_deferred("_capture")

func _settle() -> void:
    for i in range(9):
        await process_frame
    await RenderingServer.frame_post_draw

func _shot(view: SubViewport,name: String) -> void:
    var path: String = ProjectSettings.globalize_path("res://Docs/QA/"+name+".png")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    if view.get_texture().get_image().save_png(path) != OK:
        push_error("v31 screenshot failed: "+name)
        quit(1)

func _capture() -> void:
    var path: String = ENGINE.SAVE_FILE
    var had: bool = FileAccess.file_exists(path)
    var previous: String = FileAccess.get_file_as_string(path) if had else ""
    var v := SubViewport.new()
    v.size = Vector2i(1280,720)
    v.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(v)
    var ui: Control = SCENE.instantiate()
    v.add_child(ui)
    ui.game.new_game()
    await _settle()
    _shot(v,"wildbound_v31_new_game")
    ui.game.start()
    ui.game.gold = 1500.0
    for i in range(8):
        ui.game.level_up("brinlet")
        ui.game.level_up("cindlet")
        ui.game.level_up("spriglet")
    ui.game.select_creature("brinlet")
    ui._refresh()
    ui.game.hit(true)
    await _settle()
    _shot(v,"wildbound_v31_combat")
    ui.game.enemy_hp = 1.0
    ui.game.hit(true)
    ui._refresh()
    await _settle()
    _shot(v,"wildbound_v31_victory")
    ui._primary_action()
    ui._open_menu("UPGRADES")
    await _settle()
    _shot(v,"wildbound_v31_upgrades")
    ui._close_menu()
    if had:
        var file: FileAccess = FileAccess.open(path,FileAccess.WRITE)
        if file != null:
            file.store_string(previous)
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("PASS v0.31: 4 real UI captures including effects and menu")
    quit(0)
