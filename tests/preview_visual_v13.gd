extends SceneTree
const SCENE = preload("res://scenes/incremental/wildbound_visual_v13.tscn")

func _initialize() -> void:
    call_deferred("_preview")

func _emit_preview(viewport: SubViewport, name: String) -> void:
    var shot: Image = viewport.get_texture().get_image()
    if shot == null or shot.is_empty():
        push_error("Visual image unavailable: "+name)
        quit(1)
        return
    shot.resize(640,360,Image.INTERPOLATE_LANCZOS)
    var jpg: PackedByteArray = shot.save_jpg_to_buffer(0.75)
    var encoded: String = Marshalls.raw_to_base64(jpg)
    print("VISUAL_PREVIEW_BEGIN:"+name)
    for offset in range(0,encoded.length(),2000):
        print("VISUAL_PREVIEW_PART:"+encoded.substr(offset,2000))
    print("VISUAL_PREVIEW_END:"+name)

func _preview() -> void:
    var viewport := SubViewport.new()
    viewport.size = Vector2i(1280,720)
    viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(viewport)
    var ui: Control = SCENE.instantiate() as Control
    viewport.add_child(ui)
    ui.playing = true
    ui.guide_dialog.hide()
    for i in range(7):
        await process_frame
    await RenderingServer.frame_post_draw
    _emit_preview(viewport,"battle")
    ui._open_codex()
    ui.call("_refresh")
    for i in range(7):
        await process_frame
    await RenderingServer.frame_post_draw
    _emit_preview(viewport,"field_guide")
    print("PASS: compressed authentic visual review thumbnails")
    quit(0)
