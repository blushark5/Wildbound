extends SceneTree
const V06 = preload("res://scenes/incremental/wildbound_visual_v06.tscn")
func _initialize() -> void:
    call_deferred("_verify")
func _die(note: String) -> void:
    push_error("WILDBOUND VISUAL V0.6: " + note)
    quit(1)
func _verify() -> void:
    var screen: Control = V06.instantiate() as Control
    root.add_child(screen)
    if screen == null or screen.get_node_or_null("BattleFieldEffects") == null:
        _die("Battle FX and redesigned scene missing")
        return
    if screen.enemy_portrait == null or screen.ally_portrait == null:
        _die("Distinct ally/enemy original sprites are required")
        return
    if screen.unit_sprites.size() != 2:
        _die("Squad stage must support both additional companions")
        return
    if not screen.resource_chips.has("gold") or not screen.resource_chips.has("nests"):
        _die("Dynamic resource cards missing")
        return
    if screen.get_node_or_null("StageFlag") == null or screen.get_node_or_null("SquadStatus") == null:
        _die("Battle HUD has lost its labels")
        return
    if screen.game.SAVE_FILE != "user://wildbound_incremental_reboot_v1.json":
        _die("Existing progression save namespace unexpectedly altered")
        return
    if screen._active_creatures() != 1:
        _die("Expected only initial Spriglet at fresh save")
        return
    screen.game.gold = 1000.0
    if not screen.game.buy_levels("brinlet",1) or not screen.game.buy_levels("cindlet",1):
        _die("Cannot add both companions to battle")
        return
    screen.call("_refresh")
    if screen._active_creatures() != 3:
        _die("Battle UI must show all three owned species")
        return
    if not screen.unit_sprites[0].visible or not screen.unit_sprites[1].visible:
        _die("Additional allied character sprites remain hidden")
        return
    if screen.unit_sprites[0].texture == null or screen.unit_sprites[1].texture == null:
        _die("Allied battle artwork wasn't imported")
        return
    screen.game.select_region("meadow")
    screen.call("_refresh")
    if screen.arena_art.texture == null or screen.arena_art.texture.get_width() != 240:
        _die("Real illustrated meadow art failed WebP decode")
        return
    if screen.art_portraits.size() != 3:
        _die("Three new painted roster portraits were not decoded")
        return
    if screen.enemy_portrait.material == null:
        _die("Enhanced original creature sprite shader missing")
        return
    var before: float = screen.game.enemy_hp
    screen.get_node("Tap").emit_signal("pressed")
    if screen.game.enemy_hp >= before and screen.game.wave == 1:
        _die("Refined STRIKE button no longer triggers actual combat")
        return
    screen.game.best_wave = 65
    if not screen.game.select_region("shore"):
        _die("Region unlocking failed")
        return
    screen.call("_refresh")
    if not screen.arena_art.texture.resource_path.ends_with("battle_shore.png"):
        _die("Scenery isn't switched dynamically by region")
        return
    screen.call("_switch_tab","PACK")
    if screen.right_rows.size() < 6:
        _die("All prior mastery controls must survive redesigned UI")
        return
    print("PASS: working three-creature stage, original sprites, enhanced materials, HUD counters, real Strike, scenes, progression and tabs")
    quit(0)
