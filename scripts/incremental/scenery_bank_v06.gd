extends RefCounted
## Scenery-only original pixel-art study cropped independently from the
## approved visual illustration (no words, controls, or characters baked in).
const PATH := "res://assets/incremental/meadow_scene_v06.webp.base64"
static var loaded: bool = false
static var meadow: Texture2D

static func forest() -> Texture2D:
    if not loaded:
        loaded = true
        if FileAccess.file_exists(PATH):
            var raw: PackedByteArray = Marshalls.base64_to_raw(FileAccess.get_file_as_string(PATH).strip_edges())
            var img := Image.new()
            if img.load_webp_from_buffer(raw) == OK and img.get_width() == 240 and img.get_height() == 138:
                meadow = ImageTexture.create_from_image(img)
            else:
                push_warning("High-detail meadow scenery decode failed; using original region fallback")
    return meadow
