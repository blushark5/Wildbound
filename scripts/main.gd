extends Node2D

# WILDBOUND: FIRST STEPS. Original GBA-era creature RPG prototype.
# Intentionally independent of the incremental / idle Wildbound v0.x prototype.

const SAVE_PATH: String = "user://wildbound_first_steps_v0_1.json"
const AUDIO_SCRIPT: Script = preload("res://scripts/audio.gd")
const SPECIES: Dictionary = {
    "spriglet": {"name": "Spriglet", "evolution": "Thornhart", "affinity": "Grove", "hp": 24, "attack": 9, "move": "Briar Dart", "move_power": 13},
    "brinlet": {"name": "Brinlet", "evolution": "Tidemare", "affinity": "Tide", "hp": 25, "attack": 8, "move": "Ripple Jet", "move_power": 13},
    "cindlet": {"name": "Cindlet", "evolution": "Blazetail", "affinity": "Ember", "hp": 22, "attack": 10, "move": "Flare Flick", "move_power": 13}
}
const AFFINITY_WINS: Dictionary = {"Grove": "Tide", "Tide": "Ember", "Ember": "Grove"}
const CREAM: Color = Color("#f7f1dc")
const NAVY: Color = Color("#19364c")
const PALE: Color = Color("#fff8e7")
const TEAL: Color = Color("#68b6a3")
const GOLD: Color = Color("#f4d38e")

var mode: String = "title"
var phase: String = "commands"
var world_map: Sprite2D
var player_sprite: Sprite2D
var keeper_sprite: Sprite2D
var follow_camera: Camera2D
var hud: Control
var blocked: Dictionary = {}
var tall: Dictionary = {}
var player_tile: Vector2i = Vector2i(12, 12)
var direction: String = "down"
var step_timer: float = 0.0
var party: Array = []
var active_index: int = 0
var orbs: int = 5
var battles_won: int = 0
var captures: int = 0
var keeper_met: bool = false
var wild: Dictionary = {}
var battle_message: String = ""
var return_message: String = ""
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var movement_tween: Tween
var is_moving: bool = false
var battle_pages: Array[String] = []
var battle_page_index: int = 0
var evolution_notice: Dictionary = {}
var audio_engine: Node

func _ready() -> void:
    rng.randomize()
    audio_engine = AUDIO_SCRIPT.new()
    add_child(audio_engine)
    _load_map()
    _create_world()
    _render_title()

func _music(theme: String) -> void:
    audio_engine.call("play_track", theme)

func _sfx(kind: String) -> void:
    audio_engine.call("play_fx", kind)

func _toggle_audio() -> void:
    audio_engine.call("toggle_mute")
    _render_pause()

func _dismiss_world_notice() -> void:
    if return_message.is_empty():
        return
    return_message = ""
    _render_world()

func _unhandled_input(event: InputEvent) -> void:
    if mode == "dialogue":
        if event is InputEventMouseButton and event.pressed:
            _render_world()
        elif event is InputEventScreenTouch and event.pressed:
            _render_world()
        return
    if mode != "world" or return_message.is_empty():
        return
    if event is InputEventMouseButton:
        var click: InputEventMouseButton = event
        if click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
            _dismiss_world_notice()
    elif event is InputEventScreenTouch:
        var touch: InputEventScreenTouch = event
        if touch.pressed:
            _dismiss_world_notice()

func _load_map() -> void:
    var file: FileAccess = FileAccess.open("res://world.json", FileAccess.READ)
    if file == null:
        push_error("Missing world.json")
        return
    var raw: Variant = JSON.parse_string(file.get_as_text())
    if not (raw is Dictionary):
        push_error("Bad world.json")
        return
    var meta: Dictionary = raw
    for coordinate in meta.get("blocked", []):
        blocked[Vector2i(int(coordinate[0]), int(coordinate[1]))] = true
    for coordinate in meta.get("tall_grass", []):
        tall[Vector2i(int(coordinate[0]), int(coordinate[1]))] = true

func _create_world() -> void:
    world_map = Sprite2D.new()
    world_map.texture = load("res://assets/world.png")
    world_map.centered = false
    add_child(world_map)
    # The original world image remains intact. This transparent original art
    # layer adds details without moving collision tiles or save positions.
    var overworld_polish: Sprite2D = Sprite2D.new()
    overworld_polish.texture = load("res://assets/world_polish.svg")
    overworld_polish.centered = false
    overworld_polish.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    add_child(overworld_polish)
    keeper_sprite = Sprite2D.new()
    keeper_sprite.texture = load("res://assets/keeper.png")
    keeper_sprite.centered = false
    keeper_sprite.position = Vector2(16 * 16 - 4, 12 * 16 - 16)
    add_child(keeper_sprite)
    player_sprite = Sprite2D.new()
    player_sprite.texture = load("res://assets/hero_down.png")
    player_sprite.centered = false
    add_child(player_sprite)
    _place_hero()
    follow_camera = Camera2D.new()
    follow_camera.limit_left = 0
    follow_camera.limit_top = 0
    follow_camera.limit_right = 52 * 16
    follow_camera.limit_bottom = 29 * 16
    follow_camera.position = Vector2(player_tile.x * 16 + 8, player_tile.y * 16 + 8)
    # The camera must use the same movement clock as the player.
    follow_camera.process_callback = Camera2D.CAMERA2D_PROCESS_IDLE
    add_child(follow_camera)
    follow_camera.make_current()
    var overlay: CanvasLayer = CanvasLayer.new()
    add_child(overlay)
    hud = Control.new()
    hud.size = Vector2(480, 320)
    hud.mouse_filter = Control.MOUSE_FILTER_IGNORE
    overlay.add_child(hud)

func _place_hero() -> void:
    player_sprite.position = Vector2(player_tile.x * 16 - 4, player_tile.y * 16 - 16)
    player_sprite.texture = load("res://assets/hero_%s.png" % direction)

func _process(delta: float) -> void:
    if mode != "world":
        return
    if is_moving:
        return
    step_timer -= delta
    if step_timer > 0.0:
        return
    var shift: Vector2i = Vector2i.ZERO
    if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
        shift = Vector2i.UP
        direction = "up"
    elif Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
        shift = Vector2i.DOWN
        direction = "down"
    elif Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
        shift = Vector2i.LEFT
        direction = "left"
    elif Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
        shift = Vector2i.RIGHT
        direction = "right"
    if shift != Vector2i.ZERO:
        step_timer = 0.14
        _step(shift)

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey):
        return
    var key_event: InputEventKey = event
    if not key_event.pressed or key_event.echo:
        return
    if mode == "world":
        if key_event.keycode == KEY_E or key_event.keycode == KEY_ENTER or key_event.keycode == KEY_SPACE:
            if not return_message.is_empty():
                _dismiss_world_notice()
            else:
                _talk()
        elif key_event.keycode == KEY_ESCAPE:
            _render_pause()
        elif key_event.keycode == KEY_TAB:
            _render_team()
    elif mode == "team":
        if key_event.keycode == KEY_ESCAPE:
            _render_world()
    elif mode == "dialogue":
        if key_event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE, KEY_E]:
            _render_world()
    elif mode == "pause":
        if key_event.keycode == KEY_ESCAPE:
            _resume_from_pause()
    elif mode == "battle":
        if key_event.keycode == KEY_ENTER or key_event.keycode == KEY_SPACE:
            if battle_page_index < battle_pages.size() - 1:
                _advance_battle_message()
        elif key_event.keycode == KEY_ESCAPE:
            if phase == "moves" or phase == "items" or phase == "switch":
                phase = "commands"
                _render_battle()

func _step(shift: Vector2i) -> void:
    var next_tile: Vector2i = player_tile + shift
    player_sprite.texture = load("res://assets/hero_%s.png" % direction)
    if next_tile.x < 1 or next_tile.y < 1 or next_tile.x >= 51 or next_tile.y >= 28:
        return
    if blocked.has(next_tile) or next_tile == Vector2i(16, 12):
        return
    if not return_message.is_empty():
        return_message = ""
        _render_world()
    player_tile = next_tile
    is_moving = true
    # Do not teleport the camera while the sprite is moving. Advance both in one tween.
    # Round both visual positions to logical pixels to preserve the crisp GBA look.
    if movement_tween != null and movement_tween.is_running():
        movement_tween.kill()
    var starting_hero: Vector2 = player_sprite.position
    var target_hero: Vector2 = Vector2(player_tile.x * 16 - 4, player_tile.y * 16 - 16)
    var starting_camera: Vector2 = follow_camera.position
    var target_camera: Vector2 = Vector2(player_tile.x * 16 + 8, player_tile.y * 16 + 8)
    movement_tween = create_tween()
    movement_tween.tween_method(
        Callable(self, "_update_movement").bind(starting_hero, target_hero, starting_camera, target_camera),
        0.0, 1.0, 0.145
    ).set_trans(Tween.TRANS_LINEAR)
    movement_tween.finished.connect(Callable(self, "_complete_step").bind(next_tile))

func _update_movement(progress: float, starting_hero: Vector2, target_hero: Vector2, starting_camera: Vector2, target_camera: Vector2) -> void:
    player_sprite.position = starting_hero.lerp(target_hero, progress).round()
    follow_camera.position = starting_camera.lerp(target_camera, progress).round()

func _complete_step(next_tile: Vector2i) -> void:
    player_sprite.position = Vector2(player_tile.x * 16 - 4, player_tile.y * 16 - 16)
    follow_camera.position = Vector2(player_tile.x * 16 + 8, player_tile.y * 16 + 8)
    is_moving = false
    step_timer = 0.0
    if mode != "world":
        return
    if tall.has(next_tile) and rng.randf() < 0.18:
        _start_wild_battle()
    elif (next_tile.x == 26 or next_tile.x == 27) and next_tile.y >= 13 and next_tile.y <= 17:
        _render_world()

func _talk() -> void:
    if is_moving:
        return
    if player_tile.distance_to(Vector2i(16, 12)) <= 2.3:
        keeper_met = true
        _sfx("confirm")
        for index in range(party.size()):
            var creature: Dictionary = party[index]
            creature["hp"] = _max_hp(creature)
            party[index] = creature
        mode = "dialogue"
        _clear_ui()
        # Dialogue occupies the bottom of the world rather than covering it.
        _box(hud, Vector2(12, 199), Vector2(456, 115), PALE)
        _label(hud, "KEEPER VALE", 23, 204, 300, 26, 17, NAVY)
        _label(hud, "Fernpath Meadow lies beyond the eastern gate.\nWild creatures hide in tall grass.\nWeaken one before using a Capture Seal!\nYour team has been healed.", 23, 235, 315, 70, 12, NAVY)
        _button(hud, "Continue", 346, 277, 109, 31, Callable(self, "_render_world"))
        _save()
    else:
        return_message = "Explore east, or talk to Keeper Vale near the plaza."
        _render_world()

func _quest() -> String:
    if battles_won == 0 and captures == 0:
        return "QUEST 01  •  Walk east to Fernpath Meadow."
    if captures == 0:
        return "QUEST 02  •  Weaken and capture a wild creature."
    for creature in party:
        if bool(creature.get("evolved", false)):
            return "QUEST COMPLETE  •  Explore, capture, and build your team!"
    return "QUEST 03  •  Raise a creature to Level 8 to evolve."

func _new_creature(species: String, level: int) -> Dictionary:
    var c: Dictionary = {"species": species, "level": level, "xp": 0, "evolved": false, "hp": 1}
    c["hp"] = _max_hp(c)
    return c

func _max_hp(c: Dictionary) -> int:
    var data: Dictionary = SPECIES[String(c.get("species", "spriglet"))]
    var boost: int = 20 if bool(c.get("evolved", false)) else 0
    return int(data["hp"]) + int(c.get("level", 1)) * 4 + boost

func _attack_stat(c: Dictionary) -> int:
    var data: Dictionary = SPECIES[String(c.get("species", "spriglet"))]
    return int(data["attack"]) + int(c.get("level", 1)) * 2 + (14 if bool(c.get("evolved", false)) else 0)

func _name(c: Dictionary) -> String:
    var data: Dictionary = SPECIES[String(c["species"])]
    return String(data["evolution"]) if bool(c.get("evolved", false)) else String(data["name"])

func _type(c: Dictionary) -> String:
    return String(SPECIES[String(c["species"])]["affinity"])

func _effectiveness(attacking: String, defending: String) -> float:
    if attacking == "Neutral" or attacking == defending:
        return 1.0
    return 2.0 if String(AFFINITY_WINS.get(attacking, "")) == defending else 0.5

func _gain_xp(amount: int) -> String:
    if party.is_empty():
        return ""
    var c: Dictionary = party[active_index]
    c["xp"] = int(c["xp"]) + amount
    var message: String = "Gained %d XP." % amount
    while int(c["xp"]) >= (18 + int(c["level"]) * 11):
        c["xp"] = int(c["xp"]) - (18 + int(c["level"]) * 11)
        c["level"] = int(c["level"]) + 1
        c["hp"] = _max_hp(c)
        message += "  Level %d!" % int(c["level"])
        if int(c["level"]) >= 8 and not bool(c.get("evolved", false)):
            var previous_name: String = _name(c)
            var previous_attack: int = _attack_stat(c)
            var previous_hp: int = _max_hp(c)
            c["evolved"] = true
            c["hp"] = _max_hp(c)
            evolution_notice = {"species": String(c["species"]), "from": previous_name,
                "to": _name(c), "before_attack": previous_attack,
                "after_attack": _attack_stat(c), "before_hp": previous_hp,
                "after_hp": _max_hp(c)}
            message += "\n%s evolved into %s!" % [previous_name, _name(c)]
    party[active_index] = c
    return message

func _start_wild_battle() -> void:
    var kinds: Array = ["spriglet", "brinlet", "cindlet"]
    var spec: String = String(kinds[rng.randi_range(0, kinds.size() - 1)])
    wild = _new_creature(spec, rng.randi_range(2, 5))
    mode = "battle"
    phase = "commands"
    _music("battle")
    _set_battle_message("A wild %s appeared!" % _name(wild))
    _render_battle()

func _damage(attacker: Dictionary, target: Dictionary, power: int, move_type: String) -> int:
    var advantage: float = _effectiveness(move_type, _type(target))
    var value: float = float(_attack_stat(attacker) + power) * advantage * rng.randf_range(0.83, 1.06)
    var defense: float = 0.38 + float(int(target["level"])) * 0.015
    return maxi(1, int(value * defense))

func _use_move(index: int) -> void:
    if mode != "battle" or phase != "moves":
        return
    var yours: Dictionary = party[active_index]
    var skill_type: String = "Neutral" if index == 0 else _type(yours)
    var skill_name: String = "Nudge" if index == 0 else String(SPECIES[String(yours["species"])]["move"])
    var power: int = 8 if index == 0 else int(SPECIES[String(yours["species"])]["move_power"])
    var hit: int = _damage(yours, wild, power, skill_type)
    wild["hp"] = maxi(0, int(wild["hp"]) - hit)
    var effect: float = _effectiveness(skill_type, _type(wild))
    var note: String = " Super effective!" if effect > 1.0 else (" Not very effective." if effect < 1.0 else "")
    _set_battle_message("%s used %s! %d damage.%s" % [_name(yours), skill_name, hit, note])
    if int(wild["hp"]) == 0:
        battles_won += 1
        _set_battle_message(battle_message + "\n%s fainted. %s" % [_name(wild), _gain_xp(12 + int(wild["level"]) * 5)])
        if battles_won % 3 == 0:
            orbs += 1
            _set_battle_message(battle_message + "\nFound a Capture Seal!")
        phase = "result"
    else:
        _enemy_turn()
    _save()
    _render_battle()
    _sfx("victory" if int(wild["hp"]) == 0 else "hit")
    _flash_enemy()

func _enemy_turn() -> void:
    if int(wild.get("hp", 0)) <= 0 or party.is_empty():
        return
    var yours: Dictionary = party[active_index]
    var dmg: int = _damage(wild, yours, 7, "Neutral")
    yours["hp"] = maxi(0, int(yours["hp"]) - dmg)
    party[active_index] = yours
    _set_battle_message(battle_message + "\nWild %s struck for %d damage." % [_name(wild), dmg])
    if int(yours["hp"]) == 0:
        _set_battle_message(battle_message + "\n%s fainted!" % _name(yours))
        var replacement: int = _first_healthy()
        if replacement < 0:
            _set_battle_message(battle_message + "\nYour team needs rest!")
            phase = "defeat"
        else:
            active_index = replacement
            _set_battle_message(battle_message + "\nGo, %s!" % _name(party[active_index]))
            phase = "commands"
    else:
        phase = "commands"

func _first_healthy() -> int:
    for i in range(party.size()):
        if int(party[i]["hp"]) > 0:
            return i
    return -1

func _capture() -> void:
    if orbs < 1:
        _set_battle_message("You have no Capture Seals!")
        phase = "commands"
        _render_battle()
        return
    if party.size() >= 6:
        _set_battle_message("Your party is full (6 creatures). Storage is not yet available.")
        phase = "commands"
        _render_battle()
        return
    orbs -= 1
    _sfx("confirm")
    var fraction: float = float(wild["hp"]) / float(_max_hp(wild))
    var odds: float = clampf(0.29 + (1.0 - fraction) * 0.62, 0.29, 0.91)
    if rng.randf() < odds:
        captures += 1
        _sfx("capture")
        var caught: Dictionary = wild.duplicate(true)
        caught["hp"] = _max_hp(caught)
        party.append(caught)
        _set_battle_message("Click... click... captured!\n%s joined your team!" % _name(caught))
        phase = "result"
    else:
        _sfx("break")
        _set_battle_message("The seal opened! %s broke free!" % _name(wild))
        _enemy_turn()
    _save()
    _render_battle()

func _switch(index: int) -> void:
    if index < 0 or index >= party.size() or int(party[index]["hp"]) <= 0:
        return
    if active_index == index:
        return
    active_index = index
    _sfx("confirm")
    _set_battle_message("Go, %s!" % _name(party[index]))
    _enemy_turn()
    _save()
    _render_battle()

func _run_away() -> void:
    if rng.randf() < 0.86:
        return_message = "You escaped safely."
        _save()
        _render_world()
    else:
        _set_battle_message("Couldn't escape!")
        _enemy_turn()
        _render_battle()

func _finish_battle() -> void:
    if phase == "defeat":
        for i in range(party.size()):
            var c: Dictionary = party[i]
            c["hp"] = _max_hp(c)
            party[i] = c
        player_tile = Vector2i(12, 12)
        _place_hero()
        follow_camera.position = Vector2(player_tile.x * 16 + 8, player_tile.y * 16 + 8)
        return_message = "Keeper Vale healed your team."
        active_index = 0
    else:
        return_message = "Victory! Keep exploring Fernpath Meadow."
    _save()
    if not evolution_notice.is_empty():
        _render_evolution()
    else:
        _render_world()

func _render_evolution() -> void:
    mode = "evolution"
    _sfx("evolve")
    _clear_ui()
    _full_screen_tint(Color("#132739"), 0.95)
    _box(hud, Vector2(25, 18), Vector2(430, 284), CREAM)
    _label(hud, "A NEW FORM!", 88, 29, 320, 39, 27, NAVY)
    var key: String = String(evolution_notice["species"])
    _sprite(hud, "res://assets/%s_front.png" % key, 46, 82, 130, 123)
    _sprite(hud, "res://assets/%s_evo_front.png" % key, 289, 76, 137, 133)
    _label(hud, "→", 220, 129, 40, 40, 27, NAVY)
    _label(hud, "%s evolved into %s!" % [String(evolution_notice["from"]), String(evolution_notice["to"])], 41, 207, 400, 31, 17, NAVY)
    _label(hud, "Attack: %d → %d      Max HP: %d → %d" % [int(evolution_notice["before_attack"]), int(evolution_notice["after_attack"]), int(evolution_notice["before_hp"]), int(evolution_notice["after_hp"])], 62, 240, 360, 23, 13, NAVY)
    _button(hud, "Continue", 161, 270, 158, 28, Callable(self, "_dismiss_evolution"))

func _dismiss_evolution() -> void:
    evolution_notice.clear()
    _render_world()

func _render_title() -> void:
    mode = "title"
    _music("title")
    _clear_ui()
    _full_screen_tint(Color("#132739"), 0.83)
    _box(hud, Vector2(49, 36), Vector2(382, 247), CREAM)
    _label(hud, "WILDBOUND", 77, 58, 330, 47, 37, NAVY)
    _label(hud, "F I R S T   S T E P S", 102, 104, 310, 28, 16, Color("#507977"))
    _label(hud, "An original creature-collecting adventure", 75, 139, 340, 28, 14, NAVY)
    _label(hud, "Exploring: ESC = Menu    TAB = Team", 98, 156, 290, 16, 10, NAVY)
    if FileAccess.file_exists(SAVE_PATH):
        _button(hud, "Continue", 145, 173, 190, 31, Callable(self, "_continue_game"))
        _button(hud, "New Journey", 145, 209, 190, 31, Callable(self, "_confirm_new_journey"))
    else:
        _button(hud, "New Journey", 145, 181, 190, 35, Callable(self, "_render_starters"))
    if not OS.has_feature("web"):
        _button(hud, "Exit Game", 145, 246, 190, 29, Callable(self, "_quit_game"))

func _render_starters() -> void:
    mode = "starter"
    _clear_ui()
    _full_screen_tint(Color("#122b40"), 0.94)
    _label(hud, "CHOOSE YOUR FIRST COMPANION", 26, 15, 440, 45, 23, CREAM)
    _label(hud, "Your adventure begins with one creature.", 74, 51, 340, 25, 14, GOLD)
    var species: Array = ["spriglet", "brinlet", "cindlet"]
    for i in range(3):
        var key: String = String(species[i])
        var x: int = 22 + i * 154
        _box(hud, Vector2(x, 87), Vector2(142, 188), CREAM)
        _sprite(hud, "res://assets/%s_front.png" % key, x + 33, 100, 76, 76)
        _label(hud, String(SPECIES[key]["name"]), x + 15, 180, 126, 23, 18, NAVY)
        _label(hud, String(SPECIES[key]["affinity"]), x + 15, 203, 120, 21, 14, Color("#557b79"))
        _button(hud, "Choose", x + 17, 237, 107, 30, Callable(self, "_choose_starter").bind(key))
    _label(hud, "Every creature is original to Wildbound.", 111, 291, 330, 25, 12, CREAM)

func _choose_starter(species: String) -> void:
    party = [_new_creature(species, 5)]
    active_index = 0
    orbs = 5
    battles_won = 0
    captures = 0
    keeper_met = false
    evolution_notice.clear()
    player_tile = Vector2i(12, 12)
    direction = "down"
    _place_hero()
    follow_camera.position = Vector2(player_tile.x * 16 + 8, player_tile.y * 16 + 8)
    return_message = "Your adventure begins! Head east toward the tall grass."
    _sfx("confirm")
    _save()
    _render_world()

func _render_world() -> void:
    mode = "world"
    _music("world")
    _clear_ui()
    # No persistent HUD over the player. ESC = menu, TAB = team.
    # Notices stay at the bottom until movement, confirmation, click, or tap.
    if not return_message.is_empty():
        _box(hud, Vector2(12, 256), Vector2(456, 58), CREAM)
        _label(hud, return_message, 25, 263, 429, 31, 13, NAVY)
        _label(hud, "Move, click or tap to continue", 253, 296, 198, 14, 10, Color("#54786c"))

func _save_and_note() -> void:
    _save()
    return_message = "Adventure saved."
    _render_world()

func _render_team() -> void:
    mode = "team"
    _clear_ui()
    _full_screen_tint(Color("#142d42"), 0.92)
    _label(hud, "YOUR CREATURES", 20, 12, 345, 40, 25, CREAM)
    _label(hud, "Capture Seals: %d    Caught: %d" % [orbs, captures], 25, 48, 360, 24, 13, GOLD)
    for i in range(party.size()):
        var c: Dictionary = party[i]
        var xx: int = 18 + (i % 2) * 226
        var yy: int = 82 + int(i / 2) * 64
        var bg: Color = Color("#d9edce") if i == active_index else CREAM
        _box(hud, Vector2(xx, yy), Vector2(216, 59), bg)
        _sprite(hud, "res://assets/%s%s_front.png" % [String(c["species"]), "_evo" if bool(c.get("evolved", false)) else ""], xx + 3, yy + 2, 52, 51)
        _label(hud, "%s  Lv.%d" % [_name(c), int(c["level"])], xx + 58, yy + 4, 148, 19, 13, NAVY)
        _label(hud, _type(c), xx + 58, yy + 23, 90, 16, 10, Color("#557b79"))
        _label(hud, "HP %d/%d" % [int(c["hp"]), _max_hp(c)], xx + 58, yy + 39, 81, 16, 10, NAVY)
        _button(hud, "SET LEAD" if i != active_index else "LEAD", xx + 138, yy + 31, 71, 25, Callable(self, "_choose_leader").bind(i))
    _button(hud, "Back to World", 150, 278, 180, 33, Callable(self, "_render_world"))

func _choose_leader(index: int) -> void:
    if index >= 0 and index < party.size() and int(party[index]["hp"]) > 0:
        active_index = index
        _save()
        _render_team()

func _flash_enemy() -> void:
    # Lightweight sprite-area hit flash. Does not alter the battle calculation.
    if mode != "battle":
        return
    var flash: ColorRect = ColorRect.new()
    flash.position = Vector2(325, 84)
    flash.size = Vector2(94, 95)
    flash.color = Color(1.0, 1.0, 1.0, 0.52)
    flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    hud.add_child(flash)
    var fade: Tween = create_tween()
    fade.tween_property(flash, "modulate:a", 0.0, 0.23)
    fade.tween_callback(Callable(flash, "queue_free"))

func _render_battle() -> void:
    mode = "battle"
    _clear_ui()
    _sprite(hud, "res://assets/battle_meadow.png", 0, 0, 480, 320)
    if party.is_empty():
        return
    var yours: Dictionary = party[active_index]
    var enemy_icon: String = "res://assets/%s_front.png" % String(wild["species"])
    var your_icon: String = "res://assets/%s%s_back.png" % [String(yours["species"]), "_evo" if bool(yours.get("evolved", false)) else ""]
    if int(wild.get("hp", 0)) > 0:
        _sprite(hud, enemy_icon, 322, 79, 103, 103)
    _sprite(hud, your_icon, 53, 135, 117, 117)
    _box(hud, Vector2(10, 12), Vector2(228, 57), CREAM)
    _label(hud, "Wild %s   Lv.%d" % [_name(wild), int(wild["level"])], 19, 19, 210, 24, 15, NAVY)
    _hp_bar(23, 46, 198, int(wild["hp"]), _max_hp(wild))
    _box(hud, Vector2(260, 170), Vector2(212, 66), CREAM)
    _label(hud, "%s    Lv.%d" % [_name(yours), int(yours["level"])], 270, 175, 195, 21, 14, NAVY)
    _hp_bar(274, 198, 180, int(yours["hp"]), _max_hp(yours))
    _label(hud, "HP %d/%d" % [int(yours["hp"]), _max_hp(yours)], 334, 216, 118, 18, 11, NAVY)
    _box(hud, Vector2(0, 237), Vector2(480, 83), NAVY)
    var displayed_message: String = battle_message
    if not battle_pages.is_empty():
        displayed_message = battle_pages[clampi(battle_page_index, 0, battle_pages.size() - 1)]
    var narration: Label = _label(hud, displayed_message, 13, 242, 454, 36, 12, CREAM)
    narration.max_lines_visible = 2
    if battle_page_index < battle_pages.size() - 1:
        _button(hud, "Next ▶", 358, 282, 108, 30, Callable(self, "_advance_battle_message"))
        return
    if phase == "commands":
        _button(hud, "FIGHT", 12, 280, 109, 33, Callable(self, "_set_phase").bind("moves"))
        _button(hud, "SEAL (%d)" % orbs, 128, 280, 109, 33, Callable(self, "_capture"))
        _button(hud, "TEAM", 244, 280, 109, 33, Callable(self, "_set_phase").bind("switch"))
        _button(hud, "RUN", 360, 280, 109, 33, Callable(self, "_run_away"))
    elif phase == "moves":
        var data: Dictionary = SPECIES[String(yours["species"])]
        _button(hud, "Nudge (Neutral)", 10, 280, 217, 33, Callable(self, "_use_move").bind(0))
        _button(hud, "%s (%s)" % [String(data["move"]), _type(yours)], 234, 280, 237, 33, Callable(self, "_use_move").bind(1))
    elif phase == "switch":
        for i in range(mini(party.size(), 6)):
            var c: Dictionary = party[i]
            _button(hud, "%s" % _name(c).substr(0, 8), 5 + i * 79, 280, 74, 33, Callable(self, "_switch").bind(i))
    elif phase == "result":
        _button(hud, "Continue Adventure", 134, 281, 214, 32, Callable(self, "_finish_battle"))
    elif phase == "defeat":
        _button(hud, "Rest at Willowrest", 134, 281, 214, 32, Callable(self, "_finish_battle"))

# Keep narration to two short lines, with an explicit Next action for additional text.
func _set_battle_message(message: String) -> void:
    battle_message = message
    battle_pages.clear()
    battle_page_index = 0
    var lines: Array[String] = []
    for raw_line in message.split("\n"):
        var line: String = ""
        for word in raw_line.split(" ", false):
            if not line.is_empty() and line.length() + word.length() + 1 > 52:
                lines.append(line)
                line = ""
            line += (" " if not line.is_empty() else "") + word
        if not line.is_empty():
            lines.append(line)
    if lines.is_empty():
        lines.append(message)
    for start in range(0, lines.size(), 2):
        var page: String = lines[start]
        if start + 1 < lines.size():
            page += "\n" + lines[start + 1]
        battle_pages.append(page)

func _advance_battle_message() -> void:
    battle_page_index = mini(battle_page_index + 1, battle_pages.size() - 1)
    _render_battle()

func _set_phase(next_phase: String) -> void:
    phase = next_phase
    _render_battle()

func _render_pause() -> void:
    mode = "pause"
    _clear_ui()
    _full_screen_tint(Color("#142d42"), 0.91)
    _box(hud, Vector2(81, 28), Vector2(318, 270), CREAM)
    _label(hud, "PAUSED", 177, 34, 180, 39, 27, NAVY)
    _label(hud, _quest(), 100, 72, 292, 18, 10, NAVY)
    _button(hud, "Resume Adventure", 138, 94, 204, 33, Callable(self, "_resume_from_pause"))
    _button(hud, "Your Team", 138, 133, 204, 32, Callable(self, "_render_team"))
    _button(hud, "Save", 138, 172, 204, 31, Callable(self, "_save_and_pause_note"))
    _button(hud, "Save & Title", 138, 211, 204, 31, Callable(self, "_return_to_title"))
    var audio_label: String = "Sound OFF" if bool(audio_engine.get("muted")) else "Sound ON"
    if OS.has_feature("web"):
        _button(hud, audio_label, 138, 252, 204, 31, Callable(self, "_toggle_audio"))
    else:
        _button(hud, audio_label, 138, 252, 99, 31, Callable(self, "_toggle_audio"))
        _button(hud, "Save & Exit", 241, 252, 101, 31, Callable(self, "_quit_game"))

func _resume_from_pause() -> void:
    _render_world()

func _save_and_pause_note() -> void:
    _save()
    _render_pause()
    _label(hud, "Adventure saved!", 150, 72, 220, 18, 12, Color("#36725f"))

func _return_to_title() -> void:
    _save()
    _render_title()

func _quit_game() -> void:
    _save()
    if OS.has_feature("web"):
        _render_title()
    else:
        get_tree().quit()

func _confirm_new_journey() -> void:
    mode = "confirm_new"
    _clear_ui()
    _full_screen_tint(Color("#132739"), 0.95)
    _box(hud, Vector2(48, 65), Vector2(384, 191), CREAM)
    _label(hud, "START A NEW JOURNEY?", 80, 77, 341, 33, 22, NAVY)
    _label(hud, "This will replace your current saved adventure.\nYour existing team and progress will be lost.", 74, 133, 340, 58, 13, NAVY)
    _button(hud, "Cancel", 78, 207, 148, 32, Callable(self, "_render_title"))
    _button(hud, "Start Over", 254, 207, 148, 32, Callable(self, "_render_starters"))

func _continue_game() -> void:
    var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
    if f == null:
        _render_starters()
        return
    var parsed: Variant = JSON.parse_string(f.get_as_text())
    if not (parsed is Dictionary):
        _render_starters()
        return
    var data: Dictionary = parsed
    party = data.get("party", [])
    if party.is_empty():
        _render_starters()
        return
    var location: Array = data.get("position", [12, 12])
    player_tile = Vector2i(int(location[0]), int(location[1]))
    active_index = clampi(int(data.get("active", 0)), 0, party.size() - 1)
    orbs = int(data.get("seals", 5))
    battles_won = int(data.get("victories", 0))
    captures = int(data.get("captures", 0))
    keeper_met = bool(data.get("keeper", false))
    _place_hero()
    follow_camera.position = Vector2(player_tile.x * 16 + 8, player_tile.y * 16 + 8)
    _render_world()

func _save() -> void:
    if party.is_empty():
        return
    var data: Dictionary = {"party": party, "position": [player_tile.x, player_tile.y], "active": active_index,
        "seals": orbs, "victories": battles_won, "captures": captures, "keeper": keeper_met}
    var f: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if f != null:
        f.store_string(JSON.stringify(data))

# UI drawing helpers. Fixed logical 480x320, scaled by project window settings.
func _clear_ui() -> void:
    for child in hud.get_children():
        hud.remove_child(child)
        child.queue_free()

func _full_screen_tint(col: Color, opacity: float) -> void:
    var rect: ColorRect = ColorRect.new()
    rect.position = Vector2.ZERO
    rect.size = Vector2(480, 320)
    rect.color = Color(col.r, col.g, col.b, opacity)
    hud.add_child(rect)

func _box(parent: Control, at: Vector2, dimensions: Vector2, col: Color) -> void:
    var rect: Panel = Panel.new()
    rect.position = at
    rect.size = dimensions
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = col
    style.border_color = Color("#536a65") if col == CREAM else Color("#a7c4ae")
    style.set_border_width_all(2)
    style.set_corner_radius_all(3)
    rect.add_theme_stylebox_override("panel", style)
    rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(rect)

func _label(parent: Control, content: String, px: float, py: float, width: float, height: float, size: int, col: Color) -> Label:
    var text_label: Label = Label.new()
    text_label.text = content
    text_label.position = Vector2(px, py)
    text_label.size = Vector2(width, height)
    text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    text_label.custom_minimum_size = Vector2(width, 0)
    text_label.clip_text = true
    text_label.add_theme_constant_override("line_spacing", 0)
    text_label.add_theme_font_size_override("font_size", size)
    text_label.add_theme_color_override("font_color", col)
    text_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(text_label)
    return text_label

func _button(parent: Control, content: String, px: float, py: float, width: float, height: float, callback: Callable) -> Button:
    var b: Button = Button.new()
    b.text = content
    b.position = Vector2(px, py)
    b.size = Vector2(width, height)
    b.add_theme_font_size_override("font_size", 13)
    b.add_theme_color_override("font_color", CREAM)
    var style: StyleBoxFlat = StyleBoxFlat.new()
    style.bg_color = NAVY
    style.border_color = TEAL
    style.set_border_width_all(2)
    style.set_corner_radius_all(3)
    b.add_theme_stylebox_override("normal", style)
    var hover: StyleBoxFlat = style.duplicate() as StyleBoxFlat
    hover.bg_color = Color("#326178")
    b.add_theme_stylebox_override("hover", hover)
    b.add_theme_stylebox_override("pressed", hover)
    b.pressed.connect(callback)
    parent.add_child(b)
    return b

func _sprite(parent: Control, resource: String, px: float, py: float, width: float, height: float) -> void:
    var tex: TextureRect = TextureRect.new()
    tex.texture = load(resource)
    tex.position = Vector2(px, py)
    tex.size = Vector2(width, height)
    tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    tex.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(tex)

func _hp_bar(x: float, y: float, width: float, current: int, maximum: int) -> void:
    var ratio: float = clampf(float(current) / maxf(1.0, float(maximum)), 0.0, 1.0)
    var base: ColorRect = ColorRect.new()
    base.position = Vector2(x, y)
    base.size = Vector2(width, 9)
    base.color = Color("#354958")
    hud.add_child(base)
    var fill: ColorRect = ColorRect.new()
    fill.position = Vector2(x + 2, y + 2)
    fill.size = Vector2(maxf(0.0, (width - 4) * ratio), 5)
    fill.color = Color("#68c77b") if ratio > 0.5 else (Color("#ebca68") if ratio > 0.25 else Color("#e37f70"))
    hud.add_child(fill)
