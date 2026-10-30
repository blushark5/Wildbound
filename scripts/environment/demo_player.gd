extends Node2D
# Movement-only test scene; full original game remains in main.tscn.
const ART = preload("res://scripts/character_art.gd")
var tile: Vector2i = Vector2i(24,7)
var facing: String = "down"
var pose: int = 0
var is_moving: bool = false
var world: Node2D
var visual: Sprite2D
var art: RefCounted

func _ready() -> void:
    world = get_parent().get_node("World")
    art = ART.new()
    visual = Sprite2D.new()
    visual.name = "ApprovedHero"
    visual.centered = false
    visual.position = Vector2(-12,-30)
    visual.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(visual)
    visual.texture = art.call("sprite",facing)
    position = world.call("cell_center",tile)

func _process(_delta: float) -> void:
    if is_moving:
        return
    var step := Vector2i.ZERO
    if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
        step = Vector2i.UP
    elif Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
        step = Vector2i.DOWN
    elif Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
        step = Vector2i.LEFT
    elif Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
        step = Vector2i.RIGHT
    if step != Vector2i.ZERO:
        move_one(step)

func move_one(step: Vector2i) -> bool:
    facing = "up" if step == Vector2i.UP else ("down" if step == Vector2i.DOWN else ("left" if step == Vector2i.LEFT else "right"))
    visual.texture = art.call("sprite",facing)
    if is_moving or not bool(world.call("is_open",tile+step)):
        return false
    tile += step
    pose = 1 if pose == 2 else 2
    visual.texture = art.call("sprite",facing,pose)
    is_moving = true
    var move_tween := create_tween()
    move_tween.tween_property(self,"position",world.call("cell_center",tile),0.17)
    move_tween.finished.connect(_on_step_finished)
    return true

func _on_step_finished() -> void:
    visual.texture = art.call("sprite",facing,0)
    is_moving = false
