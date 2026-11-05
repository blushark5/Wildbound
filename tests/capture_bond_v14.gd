extends SceneTree
const SCENE = preload("res://scenes/incremental/wildbound_bond_v14.tscn")

func _initialize() -> void:
    call_deferred("_capture")

func _shot(v: SubViewport,name: String) -> bool:
    var image: Image = v.get_texture().get_image()
    if image == null or image.is_empty():
        return false
    var file: String = ProjectSettings.globalize_path("res://Docs/QA/"+name+".png")
    DirAccess.make_dir_recursive_absolute(file.get_base_dir())
    return image.save_png(file) == OK

func _frame() -> void:
    for i in range(7):
        await process_frame
    await RenderingServer.frame_post_draw

func _capture() -> void:
    var viewport := SubViewport.new()
    viewport.size = Vector2i(1280,720)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var ui: Control = SCENE.instantiate() as Control
    viewport.add_child(ui)
    ui.playing = false
    ui.guide_dialog.hide()
    ui.game.onboarding_seen = true
    ui.call("_refresh")
    await _frame()
    if not _shot(viewport,"wildbound_v14_starter_bond_hud"):
        push_error("Could not capture Bond-ranked starter");quit(1);return

    # A visual QA roster can display rare/midgame creatures without
    # modifying what the REAL player starts with.
    ui.game.owned_creatures["zephlet"] = ui.game._new_record("zephlet",91)
    ui.game.owned_creatures["ashcub"] = ui.game._new_record("ashcub",92)
    ui.game.assign_creature(1,"zephlet")
    ui.game.assign_creature(2,"ashcub")
    ui.game.wave = 9
    ui.game._spawn_enemy()
    ui.game._fit_enemy_to_region()
    ui.game.initialize_squads()
    ui.call("_refresh")
    await _frame()
    if not _shot(viewport,"wildbound_v14_distinct_party_idle"):
        push_error("Could not capture new illustrated idle sprites");quit(1);return
    ui.game.ally_units[1]["action"] = 0.26
    ui.game.ally_units[2]["action"] = 0.26
    ui.call("_refresh")
    await _frame()
    if not _shot(viewport,"wildbound_v14_elemental_strikes"):
        push_error("Could not capture new attack poses and elemental spark");quit(1);return
    ui.game.awaiting_next = true
    ui.game.last_clash = "TRAINER DEFEATED"
    ui.call("_refresh")
    await _frame()
    if not _shot(viewport,"wildbound_v14_enter_next_stage"):
        push_error("Could not capture corrected stage-action button");quit(1);return
    ui.game.awaiting_next = false
    ui._open_codex()
    ui.call("_refresh")
    await _frame()
    if not _shot(viewport,"wildbound_v14_bond_field_guide"):
        push_error("Could not capture Bond cap and expanded creature artwork");quit(1);return
    var path: String = ui.game.SAVE_FILE
    if FileAccess.file_exists(path):
        DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
    print("PASS: v0.14 five real Godot screenshots of sprites, Bond progression and contextual stage controls")
    quit(0)
