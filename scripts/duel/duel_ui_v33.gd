extends "res://scripts/duel/duel_ui_v32.gd"
## Wildbound v0.33: readable battles, clear controls, and health-loss feedback.
## Presentation-only changes. All gameplay, currency, progression and saves
## continue to use the exact same v0.30 duel engine.
var clarity33_ready: bool = false
var auto_badge33: Panel
var auto_text33: Label
var enemy_damage_tail33: ColorRect
var hero_damage_tail33: ColorRect
var last_tail_stage33: int = -1
var last_enemy_health33: float = -1.0
var last_hero_health33: float = -1.0

func _ready() -> void:
    super._ready()
    _reposition_stage_intro33()
    _create_automatic_combat_badge33()
    _create_health_loss_trails33()
    (get_node("Tagline") as Label).text = "CREATURES  •  ELEMENTS  •  ASCENSION     v0.33"
    DisplayServer.window_set_title("Wildbound: Creature Ascension v0.33")
    clarity33_ready = true
    _refresh()

func _reposition_stage_intro33() -> void:
    # Keep the intro in empty sky, never over the creature or HP meters.
    stage_ribbon32.position = Vector2(445,196)
    stage_ribbon32.size = Vector2(242,59)
    stage_ribbon32_title_override33()
    ribbon_timer32 = minf(ribbon_timer32,0.95)

func stage_ribbon32_title_override33() -> void:
    stage_ribbon_name32.position = Vector2(6,5)
    stage_ribbon_name32.size = Vector2(230,27)
    stage_ribbon_name32.add_theme_font_size_override("font_size",20)
    stage_ribbon_detail32.position = Vector2(6,32)
    stage_ribbon_detail32.size = Vector2(230,19)
    stage_ribbon_detail32.add_theme_font_size_override("font_size",11)

func _stage_enter32() -> void:
    super._stage_enter32()
    # Base v0.32 handles entry state; here we only reduce overlay obstruction.
    if stage_ribbon32 != null:
        _reposition_stage_intro33()
        ribbon_timer32 = 0.95

func _create_automatic_combat_badge33() -> void:
    auto_badge33 = _panel(self,"AutoCombatStatus",
        Rect2(1072,190,157,31),
        Color("#102d39",0.94),Color("#9bddc4",0.76),9,1)
    auto_badge33.z_index = 2
    auto_badge33.mouse_filter = Control.MOUSE_FILTER_IGNORE
    auto_text33 = _text(auto_badge33,"AutoCombatStatusText",
        "AUTO ATTACKING",Rect2(7,2,143,25),
        12,Color("#c1f6d5"),HORIZONTAL_ALIGNMENT_CENTER)
    auto_text33.add_theme_constant_override("outline_size",2)
    auto_text33.add_theme_color_override("font_outline_color",Color("#0a2532"))

func _create_health_loss_trails33() -> void:
    # A thin lingering color between the HP background and current HP fill.
    # This makes each hit readable without adding clutter or fake numbers.
    enemy_damage_tail33 = ColorRect.new()
    enemy_damage_tail33.name = "EnemyRecentDamage"
    enemy_damage_tail33.color = Color("#ffd49b")
    enemy_damage_tail33.position = enemy_hp_bar.position
    enemy_damage_tail33.size = enemy_hp_bar.size
    enemy_damage_tail33.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(enemy_damage_tail33)
    move_child(enemy_damage_tail33,enemy_hp_bar.get_index())
    hero_damage_tail33 = ColorRect.new()
    hero_damage_tail33.name = "HeroRecentDamage"
    hero_damage_tail33.color = Color("#c5ecb6")
    hero_damage_tail33.position = hero_hp_bar.position
    hero_damage_tail33.size = hero_hp_bar.size
    hero_damage_tail33.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(hero_damage_tail33)
    move_child(hero_damage_tail33,hero_hp_bar.get_index())
    _reset_health_trails33()

func _reset_health_trails33() -> void:
    if enemy_damage_tail33 == null:
        return
    enemy_damage_tail33.size.x = enemy_hp_bar.size.x
    hero_damage_tail33.size.x = hero_hp_bar.size.x
    last_tail_stage33 = game.stage
    last_enemy_health33 = game.enemy_hp
    last_hero_health33 = game.hero_hp

func _refresh() -> void:
    super._refresh()
    if not clarity33_ready:
        return
    # Show a state rather than another button. The existing button remains
    # an optional manual assist, while the creature auto-attacks normally.
    if game.fighting:
        auto_text33.text = "AUTO FARMING" if game.farming else "AUTO ATTACK ON"
        auto_badge33.add_theme_stylebox_override("panel",
            _style(Color("#153a38",0.94),Color("#8ee1a6"),9,1,2))
        next_button.text = "⚔  TAP TO ATTACK"
        next_button.tooltip_text = "Optional bonus attack. Your creature fights automatically."
    elif game.defeated:
        auto_text33.text = "TRAIN & RETRY"
        auto_badge33.add_theme_stylebox_override("panel",
            _style(Color("#46302e",0.94),Color("#eeaa93"),9,1,2))
    elif game.awaiting_next:
        auto_text33.text = "STAGE COMPLETE"
        auto_badge33.add_theme_stylebox_override("panel",
            _style(Color("#293c36",0.94),Color("#f0d48b"),9,1,2))
    else:
        auto_text33.text = "READY TO BATTLE"
        auto_badge33.add_theme_stylebox_override("panel",
            _style(Color("#223441",0.94),Color("#9fc2d0"),9,1,2))
    auto_text33.add_theme_color_override("font_color",
        Color("#c7f6d8") if game.fighting else Color("#fff0c9"))
    var footer: Label = get_node("FooterHelp") as Label
    footer.text = ("Your creature attacks automatically  •  Tap to help"
        if game.fighting else
        "Train or switch creatures, then continue your adventure")
    if game.stage != last_tail_stage33 or (last_enemy_health33 >= 0.0 and game.enemy_hp > last_enemy_health33+1.0):
        _reset_health_trails33()
    last_enemy_health33 = game.enemy_hp
    last_hero_health33 = game.hero_hp

func _process(delta: float) -> void:
    super._process(delta)
    if not clarity33_ready or enemy_damage_tail33 == null:
        return
    # Catch up gradually to the actual health after impacts; refill
    # instantly on respawn. Both trails are cosmetic.
    var lerp_speed: float = clampf(delta*2.25,0.0,1.0)
    enemy_damage_tail33.size.x = maxf(enemy_hp_bar.size.x,
        lerpf(enemy_damage_tail33.size.x,enemy_hp_bar.size.x,lerp_speed))
    hero_damage_tail33.size.x = maxf(hero_hp_bar.size.x,
        lerpf(hero_damage_tail33.size.x,hero_hp_bar.size.x,lerp_speed))
