extends SceneTree
const SCENE = preload("res://scenes/duel/wildbound_duel_v33.tscn")
const ENGINE = preload("res://scripts/duel/duel_engine_v30.gd")

func _initialize() -> void:
    call_deferred("_run")

func _settle() -> void:
    for i in range(8):
        await process_frame
    await RenderingServer.frame_post_draw

func _photo(view: SubViewport,name: String) -> void:
    var path: String = ProjectSettings.globalize_path("res://Docs/QA/"+name+".png")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    if view.get_texture().get_image().save_png(path) != OK:
        push_error("Failed visual capture: "+name)
        quit(1)

func _run() -> void:
    var path: String = ENGINE.SAVE_FILE
    var had: bool = FileAccess.file_exists(path)
    var content: String = FileAccess.get_file_as_string(path) if had else ""
    var view := SubViewport.new()
    view.size = Vector2i(1280,720)
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var ui: Control = SCENE.instantiate()
    view.add_child(ui)
    ui.game.new_game()
    ui.game.gold = 1150.0
    ui._refresh()
    await _settle()
    _photo(view,"wildbound_v33_fresh_start")
    ui._primary_action()
    ui._choose("brinlet")
    ui.game.hit(true)
    await _settle()
    _photo(view,"wildbound_v33_active_duel")
    ui.game.enemy_hp = 1.0
    ui.game.hit()
    ui._refresh()
    await _settle()
    _photo(view,"wildbound_v33_victory")
    ui._primary_action()
    ui.game.stage = 5
    ui.game._spawn()
    ui.game.fighting = true
    ui.game.awaiting_next = false
    ui._refresh()
    await _settle()
    _photo(view,"wildbound_v33_boss_stage")
    ui._open_menu("UPGRADES")
    await _settle()
    _photo(view,"wildbound_v33_upgrade_drawer")
    if had:
        var old: FileAccess = FileAccess.open(path,FileAccess.WRITE)
        if old != null:
            old.store_string(content)
    else:
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("PASS v0.33: rendered 5 gameplay, boss, victory and upgrade screens")
    quit(0)
