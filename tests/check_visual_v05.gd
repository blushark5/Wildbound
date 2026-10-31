extends SceneTree
## Visual regression: tests actual illustrated resources and functional UI nodes.
## A successful screenshot is still subject to human art-quality review.
const SCENE := preload("res://scenes/incremental/wildbound_alpha.tscn")

func _initialize() -> void:
    call_deferred("_verify")

func _failure(message: String) -> void:
    push_error("WILDBOUND VISUAL V0.5: " + message)
    quit(1)

func _verify() -> void:
    var screen: Control = SCENE.instantiate() as Control
    root.add_child(screen)
    if screen.get_node_or_null("Header/OriginalWildboundBackdrop") == null:
        _failure("Original scenic header artwork was not installed")
        return
    for kind in ["spriglet","brinlet","cindlet"]:
        var card: Panel = screen.get_node_or_null("PackCard_"+kind) as Panel
        if card == null or card.get_node_or_null("OriginalWildboundBackdrop") == null:
            _failure("Missing modular painted creature card " + kind)
            return
        if card.get_node_or_null("ReadableContentVeil") == null:
            _failure("Art card lacks text-contrast overlay " + kind)
            return
        var portraits: Dictionary = screen.portraits
        if (portraits[kind] as TextureRect).texture == null:
            _failure("Original creature asset not displayed " + kind)
            return
    var ally: TextureRect = screen.get_node_or_null("AllyLead") as TextureRect
    # AllyLead is a Label; illustration is exposed as a typed scene property.
    if screen.ally_portrait == null or screen.ally_portrait.texture == null:
        _failure("Actual original back-facing ally artwork missing")
        return
    if screen.enemy_portrait == null or screen.enemy_portrait.texture == null:
        _failure("Battle enemy illustration missing")
        return
    if not screen.ally_portrait.texture.resource_path.ends_with("spriglet_back.png"):
        _failure("Starter must display the distinct rear-view sprite")
        return
    if not screen.arena_art.texture.resource_path.ends_with("battle_meadow.png"):
        _failure("Meadow illustration not loaded")
        return
    screen.game.best_wave = 120
    if not screen.game.select_region("shore"):
        _failure("Could not test alternate illustrated region")
        return
    screen.call("_refresh")
    if not screen.arena_art.texture.resource_path.ends_with("battle_shore.png"):
        _failure("Changing regions did not change battle illustration")
        return
    screen.game.evolved["spriglet"] = true
    screen.call("_refresh")
    if not screen.ally_portrait.texture.resource_path.ends_with("spriglet_evo_back.png"):
        _failure("Evolution should change the player's battlefield art")
        return
    screen.call("_switch_tab","PACK")
    if screen.right_rows.size() < 6:
        _failure("Original interactive progression tab was lost in visual rebuild")
        return
    for row in screen.right_rows:
        if not row.has("card") or row["card"] == null:
            _failure("Modular, independently interactive upgrade card missing")
            return
    if screen.get_node_or_null("Tap") == null:
        _failure("Original click-to-attack button has been obscured or removed")
        return
    var hp_before: float = screen.game.enemy_hp
    screen.get_node("Tap").emit_signal("pressed")
    if screen.game.enemy_hp >= hp_before and screen.game.wave <= 1:
        _failure("Styled STRIKE button has broken live combat")
        return
    # Test never writes into a real player's browser save; test runner user:// only.
    DirAccess.remove_absolute(ProjectSettings.globalize_path(screen.ENGINE.SAVE_FILE))
    print("PASS visual v0.5: illustrated header/cards, rear-view ally, evolved art, region scenes, functional upgrades and combat")
    quit(0)
