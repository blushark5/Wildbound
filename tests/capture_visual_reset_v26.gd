extends SceneTree
## Actual Godot 1280×720 screenshot set; one wide arena, one drawer,
## one tactics modal and one improved Field Guide. No design mockups.
const SCENE = preload("res://scenes/incremental/wildbound_bond_v26.tscn")
const GAME = preload("res://scripts/incremental/bond_engine_v25.gd")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")

func _initialize() -> void:
    call_deferred("_capture")
func _frames() -> void:
    for i in range(9):
        await process_frame
    await RenderingServer.frame_post_draw
func _shot(v: SubViewport,name: String) -> bool:
    var target: String = ProjectSettings.globalize_path("res://Docs/QA/"+name+".png")
    DirAccess.make_dir_recursive_absolute(target.get_base_dir())
    return v.get_texture().get_image().save_png(target) == OK
func _capture() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var view := SubViewport.new()
    view.size = Vector2i(1280,720)
    view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(view)
    var ui: Control = SCENE.instantiate()
    view.add_child(ui)
    await _frames()
    ui.guide_dialog.hide()
    ui._strike()
    ui.playing = false
    ui._refresh()
    await _frames()
    if not _shot(view,"wildbound_v26_full_width_battle"):
        push_error("Missing cinematic battle screenshot");quit(1);return
    ui._open_shop("GROW")
    await _frames()
    if not _shot(view,"wildbound_v26_upgrades_drawer"):
        push_error("Missing drawer screenshot");quit(1);return
    ui._close_drawer()
    ui._open_tactics()
    await _frames()
    if not _shot(view,"wildbound_v26_tactics_menu"):
        push_error("Missing advanced options screenshot");quit(1);return
    ui.tactics_dialog.hide()
    ui._open_codex()
    ui._refresh_codex()
    await _frames()
    if not _shot(view,"wildbound_v26_field_guide"):
        push_error("Missing Field Guide screenshot");quit(1);return
    ui._close_codex()
    SLOTS.erase_all(GAME.SAVE_FILE)
    print("PASS v0.26: rendered real 1280x720 full battle, upgrades, intentional advanced tactics, Field Guide")
    quit(0)
