extends SceneTree
## True Godot scene screenshots for a narrow guide and meaningful modules.
const SCENE = preload("res://scenes/incremental/wildbound_bond_v21.tscn")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")
const GAME = preload("res://scripts/incremental/bond_engine_v20.gd")

func _initialize() -> void:
    call_deferred("_capture")

func _frame() -> void:
    for i in range(8):
        await process_frame
    await RenderingServer.frame_post_draw

func _shot(v: SubViewport,name: String) -> bool:
    var target: String = ProjectSettings.globalize_path("res://Docs/QA/"+name+".png")
    DirAccess.make_dir_recursive_absolute(target.get_base_dir())
    return v.get_texture().get_image().save_png(target) == OK

func _capture() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var v := SubViewport.new()
    v.size = Vector2i(1280,720)
    v.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(v)
    var ui: Control = SCENE.instantiate()
    v.add_child(ui)
    ui._show_first_steps()
    await _frame()
    if not _shot(v,"wildbound_v21_wrapped_guide"):
        push_error("Could not capture bounded intro guide");quit(1);return
    ui.guide_dialog.hide()
    ui.game.gold = 1.0e9
    ui.game.modules["power"] = 3
    ui.game.modules["tempo"] = 2
    ui.game.modules["crit"] = 5
    ui.game.modules["bounty"] = 4
    ui.game.modules["recovery"] = 2
    ui._switch_tab("GROW")
    ui._refresh()
    await _frame()
    if not _shot(v,"wildbound_v21_upgrade_breakdowns"):
        push_error("Could not capture math-rich Gold upgrades");quit(1);return
    SLOTS.erase_all(GAME.SAVE_FILE)
    print("PASS v0.21: real word-wrapped guide and cumulative Gold upgrade screenshots")
    quit(0)
