extends SceneTree
## Render actual Godot v0.20 squad battle, guide slot IDs and farming picker.
const SCENE = preload("res://scenes/incremental/wildbound_bond_v20.tscn")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")
const GAME = preload("res://scripts/incremental/bond_engine_v20.gd")
func _initialize() -> void:
    call_deferred("_capture")
func _frame() -> void:
    for i in range(8):
        await process_frame
    await RenderingServer.frame_post_draw
func _shot(v: SubViewport,name: String) -> bool:
    var img: Image = v.get_texture().get_image()
    var target: String = ProjectSettings.globalize_path("res://Docs/QA/"+name+".png")
    DirAccess.make_dir_recursive_absolute(target.get_base_dir())
    return img.save_png(target) == OK
func _capture() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var view := SubViewport.new()
    view.size = Vector2i(1280,720)
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var ui: Control = SCENE.instantiate()
    view.add_child(ui)
    ui.guide_dialog.hide()
    ui._strike()
    ui.playing = false
    ui._refresh()
    await _frame()
    if not _shot(view,"wildbound_v20_elemental_battle"):
        push_error("No v20 elemental battle image");quit(1);return
    ui._open_codex()
    ui._refresh_codex()
    await _frame()
    if not _shot(view,"wildbound_v20_guide_slots"):
        push_error("No v20 guide slot image");quit(1);return
    ui._close_codex()
    for i in range(3):
        var enemy: Dictionary = ui.game.rival_units[i]
        if float(enemy["hp"]) > 0.0:
            ui.game._damage_rival(i,float(enemy["hp"])+10.0,String(ui.game.squad_slots[0]))
    ui.playing = true
    ui._refresh()
    ui._open_farm_picker()
    await _frame()
    if not _shot(view,"wildbound_v20_farm_stage_picker"):
        push_error("No v20 farming picker image");quit(1);return
    ui.farm_dialog.hide()
    SLOTS.erase_all(GAME.SAVE_FILE)
    print("PASS v0.20: actual element-marked fight, slot-aware Field Guide, and selectable farming stage UI")
    quit(0)
