extends "res://scripts/duel/duel_ui_v33.gd"
## Wildbound v0.34: ACTUAL high-fidelity art replacement, not extra HUD polish.
## Uses the approved-concept-derived raster sprites and painted backdrop.
## Three creatures, 1v1 battle, persistent local save namespace unchanged.
const ART34 = preload("res://scripts/duel/concept_art_v34.gd")
var fidelity34_ready: bool = false

func _ready() -> void:
    super._ready()
    var painted_scene: Texture2D = ART34.background()
    if painted_scene != null:
        landscape.texture = painted_scene
        landscape.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
        landscape.stretch_mode = TextureRect.STRETCH_SCALE
        landscape.modulate = Color.WHITE
    # Larger stage creatures show the illustrated anatomy at useful sizes.
    hero_art.size = Vector2(260,237)
    hero_art.pivot_offset = hero_art.size/2.0
    enemy_art.size = Vector2(351,305)
    enemy_art.pivot_offset = enemy_art.size/2.0
    hero_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    enemy_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    for kind in DUEL.ORDER:
        var row: Dictionary = roster_rows[kind]
        var portrait: TextureRect = row["image"] as TextureRect
        portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    # Tone down redundant arena darkening. The new scenery supplies its own depth.
    rival_frame.add_theme_stylebox_override("panel",_style(
        Color("#09252b",0.02),Color("#d4dfb7",0.18),18,1,1))
    (get_node("Tagline") as Label).text = "CREATURES  •  ELEMENTS  •  ASCENSION     v0.34"
    DisplayServer.window_set_title("Wildbound: Creature Ascension v0.34")
    fidelity34_ready = ART34.load_success
    _refresh()

func _refresh() -> void:
    super._refresh()
    if not fidelity34_ready:
        return
    var main_pose: Texture2D = ART34.creature(
        game.active,bool(game.evolved[game.active]),
        game.fighting and game.hero_clock < 0.16)
    var rival_pose: Texture2D = ART34.creature(
        game.opponent,game.is_boss(),game.impact_flash > 0.0)
    if main_pose != null:
        hero_art.texture = main_pose
    if rival_pose != null:
        enemy_art.texture = rival_pose
    for kind in DUEL.ORDER:
        var row: Dictionary = roster_rows[kind]
        var sprite: Texture2D = ART34.creature(kind,bool(game.evolved[kind]))
        if sprite != null:
            (row["image"] as TextureRect).texture = sprite

func _process(delta: float) -> void:
    super._process(delta)
    if not fidelity34_ready:
        return
    # Previous layers compute lunge and stagger; offset their existing poses
    # after that computation, so we don't accumulate per-frame drift.
    hero_art.position += Vector2(-10.0,-17.0)
    enemy_art.position += Vector2(-8.0,-12.0)
