extends "res://scripts/duel/duel_ui_v31.gd"
## Wildbound v0.32 — art polish and combat clarity, still exactly three 1v1 creatures.
## Inherits the v0.30 save namespace deliberately, avoiding player resets.
const AMBIENT32 = preload("res://scripts/duel/duel_ambient_v32.gd")
const FX32 = preload("res://scripts/duel/duel_vfx_v32.gd")
var ambient32
var polish32_ready: bool = false
var last_view_stage32: int = -1
var stage_ribbon32: Panel
var stage_ribbon_name32: Label
var stage_ribbon_detail32: Label
var ribbon_timer32: float = 0.0
var guardian_label32: Label
var progress_pips32: Array[Panel] = []
var display_tint32: Color = Color("#a6edba")
var frame_clock32: float = 0.0
var toast32: Array[Label] = []

func _ready() -> void:
    super._ready()
    ambient32 = AMBIENT32.new()
    ambient32.name = "LivingArenaAtmosphere"
    ambient32.position = Vector2.ZERO
    ambient32.size = Vector2(1280,720)
    ambient32.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(ambient32)
    move_child(ambient32,landscape.get_index()+1)
    fx31.queue_free()
    fx31 = FX32.new()
    fx31.name = "ElementalImpactTrailsV32"
    fx31.position = Vector2.ZERO
    fx31.size = Vector2(1280,720)
    fx31.z_index = 8
    add_child(fx31)

    # Faces toward the hero; v0.31 accidentally had both creatures face right.
    enemy_art.flip_h = true
    _build_battle_guidance32()
    _build_stage_ribbon32()
    _tune_game_buttons32()
    # Player-facing build label. Leave Godot config/name unchanged so browser saves survive.
    # Runtime window title overrides the preserved internal Godot project name.
    DisplayServer.window_set_title("Wildbound: Creature Ascension v0.32")
    var version_tag: Label = get_node("Tagline") as Label
    version_tag.text = "CREATURES  •  ELEMENTS  •  ASCENSION     v0.32"
    version_tag.add_theme_color_override("font_color",Color("#bfe8cf"))
    game.strike_landed.connect(_on_strike32)
    game.duel_finished.connect(_on_finished32)
    polish32_ready = true
    _refresh()

func _build_battle_guidance32() -> void:
    guardian_label32 = _text(self,"GuardianCountdown","",
        Rect2(977,123,240,22),12,Color("#fae4ae"),
        HORIZONTAL_ALIGNMENT_CENTER)
    guardian_label32.z_index = 2
    guardian_label32.add_theme_constant_override("outline_size",3)
    guardian_label32.add_theme_color_override("font_outline_color",Color("#0c2938"))
    for i in range(5):
        var x: float = 1026.0+float(i)*31.0
        var dot: Panel = _panel(self,"StagePip_%d" % i,
            Rect2(x,150,18,12),Color("#294851"),
            Color("#6a8e82"),4,1)
        dot.z_index = 2
        progress_pips32.append(dot)
    power_text.add_theme_font_size_override("font_size",16)
    power_text.add_theme_constant_override("outline_size",2)
    power_text.add_theme_color_override("font_outline_color",Color("#071c29"))
    # A more readable end-of-combat hint, not three stacked tooltips.
    (get_node("FooterHelp") as Label).text = "Click the enemy to help your creature attack"
    (get_node("FooterHelp") as Label).add_theme_color_override(
        "font_color",Color("#d7e6d7"))

func _build_stage_ribbon32() -> void:
    stage_ribbon32 = _panel(self,"StageEntryRibbon",
        Rect2(719,263,400,115),Color("#182e41",0.94),
        Color("#f7d78f"),17,3)
    stage_ribbon32.z_index = 9
    stage_ribbon32.mouse_filter = Control.MOUSE_FILTER_IGNORE
    stage_ribbon_name32 = _text(stage_ribbon32,"StageEntryName","STAGE 1",
        Rect2(18,12,364,49),33,Color("#ffe8b1"),
        HORIZONTAL_ALIGNMENT_CENTER)
    stage_ribbon_detail32 = _text(stage_ribbon32,"StageEntryTag","ELEMENTAL DUEL",
        Rect2(18,65,364,31),17,Color("#b7e8d5"),
        HORIZONTAL_ALIGNMENT_CENTER)
    stage_ribbon32.hide()

func _tune_game_buttons32() -> void:
    var targets: Array[Button] = [next_button,farm_button,menu_button]
    for kind in DUEL.ORDER:
        targets.append(roster_rows[kind]["spend"] as Button)
        targets.append(roster_rows[kind]["choose"] as Button)
    for b in targets:
        b.pivot_offset = b.size*0.5
        b.button_down.connect(_button_press32.bind(b))
        b.button_up.connect(_button_release32.bind(b))
        b.mouse_exited.connect(_button_release32.bind(b))

func _button_press32(button: Button) -> void:
    if button.disabled:
        return
    var tween := create_tween()
    tween.tween_property(button,"scale",Vector2(0.965,0.965),0.075)

func _button_release32(button: Button) -> void:
    if not is_instance_valid(button):
        return
    var tween := create_tween()
    tween.tween_property(button,"scale",Vector2.ONE,0.14)\
        .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _refresh() -> void:
    super._refresh()
    if not polish32_ready or game == null:
        return
    var next_boss: int = 5-((game.stage-1)%5)
    guardian_label32.text = (
        "GUARDIAN BATTLE" if game.is_boss()
        else "GUARDIAN IN %d STAGE%s" % [next_boss,"" if next_boss==1 else "S"])
    guardian_label32.add_theme_color_override("font_color",
        Color("#ffbd94") if game.is_boss() else Color("#fde9bd"))
    var filled: int = ((game.stage-1)%5)+1
    for i in range(progress_pips32.size()):
        var dot: Panel = progress_pips32[i]
        var active: bool = i < filled
        var fill: Color = (
            Color("#ee9874") if game.is_boss() else Color("#f8d58b"))
        dot.add_theme_stylebox_override("panel",_style(
            fill if active else Color("#264653"),
            Color("#fff1bc",0.74) if active else Color("#5d8b91",0.68),
            4,1,1))
    var element_name: String = game.element(game.opponent)
    ambient32.set_stage(game.stage,element_name)
    if game.is_boss():
        battle_header.add_theme_stylebox_override("panel",
            _style(Color("#532b2f",0.97),Color("#ffd890"),14,3,7))
        stage_title.add_theme_color_override("font_color",Color("#ffe1a5"))
    else:
        battle_header.add_theme_stylebox_override("panel",
            _style(Color("#0c293a",0.97),Color("#f6d88e"),14,2,6))
        stage_title.add_theme_color_override("font_color",PEARL)

    var matchup_factor: float = game.matchup(game.active,game.opponent)
    if matchup_factor > 1.0:
        power_text.text = "YOUR DPS  %s     •     STRONG MATCHUP  2×" % game.format_number(game.dps(game.active))
        display_tint32 = Color("#acf5a3")
    elif matchup_factor < 1.0:
        power_text.text = "YOUR DPS  %s     •     RESISTED  0.5×" % game.format_number(game.dps(game.active))
        display_tint32 = Color("#ffb19a")
    else:
        power_text.text = "YOUR DPS  %s     •     NEUTRAL  1×" % game.format_number(game.dps(game.active))
        display_tint32 = Color("#e7e3be")
    power_text.add_theme_color_override("font_color",display_tint32)

    if last_view_stage32 != game.stage:
        last_view_stage32 = game.stage
        if game.battle_started and game.fighting:
            _stage_enter32()

func _stage_enter32() -> void:
    ribbon_timer32 = 1.45
    stage_ribbon32.show()
    stage_ribbon32.modulate.a = 1.0
    stage_ribbon_name32.text = (
        "GUARDIAN STAGE %d" % game.stage if game.is_boss()
        else "STAGE %d" % game.stage)
    stage_ribbon_detail32.text = "%s • %s" % [
        game.element(game.opponent).to_upper(),
        game.display_name(game.opponent).to_upper()]
    if fx31 != null:
        fx31.impact(Vector2(913,380),game.element(game.opponent),true)

func _on_strike32(amount: float,enemy_target: bool,
        element_name: String,manual: bool) -> void:
    if not polish32_ready or fx31 == null:
        return
    # Engines apply damage immediately. This short matching trail is feedback.
    var source: Vector2 = Vector2(643,349) if enemy_target else Vector2(884,354)
    var dest: Vector2 = Vector2(839,350) if enemy_target else Vector2(610,367)
    fx31.launch(source,dest,element_name,manual)
    if enemy_target and amount >= 0.0:
        var factor: float = game.matchup(game.active,game.opponent)
        if factor > 1.0 and manual:
            _mini_toast32("SUPER EFFECTIVE!",Vector2(908,212),Color("#b8fba6"))

func _on_finished32(won: bool,reward: float,is_record: bool) -> void:
    if not polish32_ready:
        return
    ribbon_timer32 = 0.0
    stage_ribbon32.hide()
    if won:
        if game.is_boss():
            victory31_title.text = "GUARDIAN DEFEATED"
            victory31_title.add_theme_font_size_override("font_size",27)
            victory31_reward.text = "+%s GOLD • BOSS BONUS" % game.format_number(reward)
        else:
            victory31_title.add_theme_font_size_override("font_size",36)
            victory31_title.text = "VICTORY!"
        if is_record:
            _mini_toast32("NEW STAGE RECORD",Vector2(891,217),Color("#ffeab0"))
    else:
        victory31_title.add_theme_font_size_override("font_size",32)

func _mini_toast32(message: String,at: Vector2,tint: Color) -> void:
    if toast32.size() >= 5:
        var old: Label = toast32.pop_front()
        if is_instance_valid(old):
            old.queue_free()
    var msg: Label = _text(self,"CombatMoment_%d" % Time.get_ticks_msec(),
        message,Rect2(at.x-135,at.y-15,270,31),17,tint,
        HORIZONTAL_ALIGNMENT_CENTER)
    msg.z_index = 9
    msg.add_theme_constant_override("outline_size",4)
    msg.add_theme_color_override("font_outline_color",Color("#102335"))
    toast32.append(msg)
    var tween := create_tween()
    tween.tween_property(msg,"position",msg.position+Vector2(0,-38),0.69)
    tween.parallel().tween_property(msg,"modulate:a",0.0,0.45).set_delay(0.24)
    tween.tween_callback(func() -> void:
        if is_instance_valid(msg):
            toast32.erase(msg)
            msg.queue_free()
    )

func _train(kind: String) -> void:
    var before: int = int(game.levels[kind])
    super._train(kind)
    if not polish32_ready or int(game.levels[kind]) <= before:
        return
    var i: int = DUEL.ORDER.find(kind)
    if i < 0:
        return
    var at: Vector2 = Vector2(217,228+123*i)
    fx31.impact(at,game.element(kind),false)
    _mini_toast32("+1 LEVEL",at,Color("#c6f59a"))

func _choose(kind: String) -> void:
    var old_kind: String = game.active
    super._choose(kind)
    if polish32_ready and game.active != old_kind:
        fx31.impact(Vector2(552,363),game.element(kind),true)
        _mini_toast32("GO, %s!" % game.display_name(kind).to_upper(),
            Vector2(581,224),Color("#fff3c1"))

func _process(delta: float) -> void:
    super._process(delta)
    if not polish32_ready:
        return
    frame_clock32 += delta
    if ribbon_timer32 > 0.0:
        ribbon_timer32 = maxf(0.0,ribbon_timer32-delta)
        stage_ribbon32.visible = ribbon_timer32 > 0.0
        if ribbon_timer32 > 0:
            stage_ribbon32.modulate.a = (
                clampf(ribbon_timer32*3.5,0.0,1.0)
                if ribbon_timer32 < 0.3 else
                clampf((1.45-ribbon_timer32)*5.0,0.0,1.0))
    elif stage_ribbon32.visible:
        stage_ribbon32.hide()
    # Subtle visual weight, not constant full-screen shaking.
    if game.fighting:
        enemy_art.scale = Vector2.ONE*(1.0+0.010*sin(frame_clock32*2.5))
        hero_art.scale = Vector2.ONE*(1.0+0.013*sin(frame_clock32*2.8+0.7))
    else:
        enemy_art.scale = enemy_art.scale.lerp(Vector2.ONE,minf(1.0,delta*6.0))
        hero_art.scale = hero_art.scale.lerp(Vector2.ONE,minf(1.0,delta*6.0))
