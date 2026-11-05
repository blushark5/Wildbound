extends SceneTree
const SCENE = preload("res://scenes/duel/wildbound_duel_v30.tscn")
const ENGINE = preload("res://scripts/duel/duel_engine_v30.gd")

func _initialize() -> void:
    call_deferred("_run")

func _settle() -> void:
    for i in range(9):
        await process_frame
    await RenderingServer.frame_post_draw

func _shot(view: SubViewport,label: String) -> void:
    var path: String = ProjectSettings.globalize_path("res://Docs/QA/"+label+".png")
    DirAccess.make_dir_recursive_absolute(path.get_base_dir())
    if view.get_texture().get_image().save_png(path) != OK:
        push_error("Cannot render "+label)
        quit(1)

func _run() -> void:
    var v := SubViewport.new()
    v.size = Vector2i(1280,720)
    v.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(v)
    var ui: Control = SCENE.instantiate()
    v.add_child(ui)
    await _settle()
    _shot(v,"wildbound_v30_title_and_three_creatures")
    ui._primary_action()
    await _settle()
    _shot(v,"wildbound_v30_live_one_on_one")
    ui._open_menu("UPGRADES")
    await _settle()
    _shot(v,"wildbound_v30_gold_upgrades")
    ui._fill_menu("ASCEND")
    await _settle()
    _shot(v,"wildbound_v30_ascend")
    ui._close_menu()
    ui.game.enemy_hp = 1.0
    ui.game.hit()
    ui._refresh()
    await _settle()
    _shot(v,"wildbound_v30_next_stage")
    print("PASS v0.30: captured five actual 1280x720 visuals")
    quit(0)
