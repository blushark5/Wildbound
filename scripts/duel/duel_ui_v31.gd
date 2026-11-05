extends "res://scripts/duel/duel_ui_v30.gd"
## Wildbound v0.31 — art-first production polish.
## No new creatures, currencies, progression, battles or save fields.
## All effects use events emitted by the *real* 1v1 combat engine.
const FXSCRIPT = preload("res://scripts/duel/duel_vfx_v31.gd")
const ORNAMENTS = preload("res://assets/duel/duel_ui_ornaments_v31.svg")
const WARM_GOLD: Color = Color("#f8cf72")
const FIRE_RED: Color = Color("#b74626")
const EMERALD: Color = Color("#30a663")
var art31_ready: bool = false
var fx31
var trim31: TextureRect
var victory31: Panel
var victory31_title: Label
var victory31_reward: Label
var victory31_left: float = 0.0
var victory31_total: float = 2.35
var lunge31: float = 0.0
var stagger31: float = 0.0
var enemy_hit31: float = 0.0
var scene_clock31: float = 0.0
var damage_labels31: Array[Label] = []
var last_stage31: int = 0

func _ready() -> void:
    super._ready()
    _install_production_art()
    fx31 = FXSCRIPT.new()
    fx31.name = "ElementalBattleEffects"
    fx31.position = Vector2.ZERO
    fx31.size = Vector2(1280,720)
    fx31.z_index = 8
    add_child(fx31)
    _install_victory_card()
    game.strike_landed.connect(_on_strike31)
    game.duel_finished.connect(_on_finished31)
    last_stage31 = game.stage
    art31_ready = true
    _refresh()

func _install_production_art() -> void:
    # Restore the colorful landscape by removing the dark translucent circles.
    var player_shadow: Panel = get_node("HeroAura") as Panel
    player_shadow.position = Vector2(477,424)
    player_shadow.size = Vector2(201,30)
    player_shadow.add_theme_stylebox_override("panel",
        _style(Color("#071f26",0.42),Color("#9dd7ba",0.20),36,1,0))
    var rival_shadow: Panel = get_node("RivalAura") as Panel
    rival_shadow.position = Vector2(785,429)
    rival_shadow.size = Vector2(287,33)
    rival_shadow.add_theme_stylebox_override("panel",
        _style(Color("#082027",0.44),Color("#d7e2b5",0.20),36,1,0))
    rival_frame.add_theme_stylebox_override("panel",
        _style(Color("#0b2835",0.03),Color("#ddb46d",0.57),18,1,1))
    landscape.modulate = Color("#ffffff")

    # Pixel-illustrated creatures have clean edges, not blurry bilinear upscaling.
    hero_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    enemy_art.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
    hero_art.position = Vector2(454,260)
    hero_art.size = Vector2(222,212)
    hero_art.pivot_offset = hero_art.size/2.0
    enemy_art.position = Vector2(742,165)
    enemy_art.size = Vector2(332,306)
    enemy_art.pivot_offset = enemy_art.size/2.0
    enemy_hit_button.position = Vector2(733,180)
    enemy_hit_button.size = Vector2(351,283)

    # More substantial fantasy RPG hierarchy with warm gold and elemental color.
    (get_node("MainHeader") as Panel).add_theme_stylebox_override("panel",
        _style(Color("#0d2436",0.99),Color("#e4bd70"),15,2,5))
    (get_node("TrainingPanel") as Panel).add_theme_stylebox_override("panel",
        _style(Color("#10263a",0.99),Color("#c79b54"),20,2,6))
    (get_node("ElementGuide") as Panel).add_theme_stylebox_override("panel",
        _style(Color("#172b37",0.99),Color("#ac854f"),14,2,4))
    battle_header.add_theme_stylebox_override("panel",
        _style(Color("#0b2537",0.98),WARM_GOLD,15,3,7))
    (get_node("GoldChip") as Panel).add_theme_stylebox_override("panel",
        _style(Color("#142e3c"),WARM_GOLD,12,2,4))
    (get_node("EchoChip") as Panel).add_theme_stylebox_override("panel",
        _style(Color("#211f3c"),Color("#bb9fea"),12,2,4))
    (get_node("ProgressChip") as Panel).add_theme_stylebox_override("panel",
        _style(Color("#14273a"),Color("#d8b672"),12,2,4))
    (get_node("InfoStrip") as Panel).add_theme_stylebox_override("panel",
        _style(Color("#11263b",0.98),Color("#b3a779"),12,2,5))
    (get_node("EnemyHealthBg") as Panel).add_theme_stylebox_override("panel",
        _style(Color("#2b2938",0.97),Color("#ffbe77"),12,2,4))
    (get_node("HeroHealthBg") as Panel).add_theme_stylebox_override("panel",
        _style(Color("#152b37",0.97),Color("#b8f4c2"),12,2,4))
    enemy_hp_bar.color = Color("#ee6348")
    hero_hp_bar.color = Color("#4bcf78")
    (get_node("MenuDrawer/DrawerBackground") as Panel).add_theme_stylebox_override("panel",
        _style(Color("#13263a",0.99),WARM_GOLD,18,2,7))

    var label_names: Array[String] = ["Logo","TrainingTitle","StageTitle",
        "StageDetail","ActiveName","RivalName","CombatInfo","ElementGuideTitle"]
    for name in label_names:
        var label: Label = get_node(name) as Label
        label.add_theme_constant_override("outline_size",3)
        label.add_theme_color_override("font_outline_color",Color("#0a1c28"))
    var logo: Label = get_node("Logo") as Label
    logo.text = "WILDBOUND"
    logo.add_theme_font_size_override("font_size",38)
    logo.add_theme_color_override("font_color",WARM_GOLD)
    var subtitle: Label = get_node("TrainingTitle") as Label
    subtitle.add_theme_font_size_override("font_size",23)
    subtitle.add_theme_color_override("font_color",Color("#ffe6b1"))
    var note: Label = get_node("TrainingDescription") as Label
    note.add_theme_color_override("font_color",Color("#c4dfd3"))
    (get_node("ElementGuideTitle") as Label).add_theme_color_override(
        "font_color",Color("#ffe6a0"))
    hero_name.position = Vector2(475,454)
    hero_name.size.x = 212
    hero_element.position = Vector2(475,478)
    hero_element.size.x = 212
    enemy_name.position = Vector2(763,446)
    enemy_element.position = Vector2(763,476)
    stage_title.add_theme_font_size_override("font_size",25)
    _paint_button(menu_button,Color("#825523"),WARM_GOLD)
    _paint_button(next_button,Color("#b73522"),Color("#ffe09a"))
    _paint_button(farm_button,Color("#99621e"),Color("#ffe19b"))
    next_button.add_theme_font_size_override("font_size",25)
    farm_button.add_theme_font_size_override("font_size",19)

    for kind in DUEL.ORDER:
        var row: Dictionary = roster_rows[kind]
        var picture: TextureRect = row["image"]
        picture.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
        var color: Color = COLORS[game.element(kind)]
        var art_bg: Panel = row["frame"]
        art_bg.add_theme_stylebox_override("panel",_style(
            Color("#182b34"),color.lightened(0.25),12,2,4))
        var switcher: Button = row["choose"]
        _paint_button(switcher,Color("#20465c"),Color("#7dbad7"))
        var trainer: Button = row["spend"]
        _paint_button(trainer,Color("#3f853d"),Color("#c9ec88"))
        (row["name"] as Label).add_theme_font_size_override("font_size",19)

    # Ornament texture is transparent, on top of the UI, and ignores mouse.
    trim31 = _art(self,"GameArtOrnaments",ORNAMENTS,
        Rect2(0,0,1280,720))
    trim31.stretch_mode = TextureRect.STRETCH_SCALE
    trim31.z_index = 6
    trim31.mouse_filter = Control.MOUSE_FILTER_IGNORE
    (get_node("DamagePop") as Label).hide()

func _paint_button(button: Button,fill: Color,edge: Color) -> void:
    button.add_theme_stylebox_override("normal",
        _style(fill,edge,10,2,5))
    button.add_theme_stylebox_override("hover",
        _style(fill.lightened(0.23),edge.lightened(0.17),10,3,7))
    button.add_theme_stylebox_override("pressed",
        _style(fill.darkened(0.26),edge.darkened(0.13),10,2,1))
    button.add_theme_stylebox_override("disabled",
        _style(Color("#263c46"),Color("#60777a"),10,1,1))
    button.add_theme_color_override("font_color",Color("#fff4d7"))
    button.add_theme_color_override("font_hover_color",Color("#fffcec"))
    button.add_theme_color_override("font_disabled_color",Color("#8fa6ac"))

func _install_victory_card() -> void:
    victory31 = _panel(self,"VictoryFXCard",Rect2(706,280,401,136),
        Color("#1b283b",0.96),Color("#ffdf85"),16,3)
    victory31.z_index = 9
    victory31.mouse_filter = Control.MOUSE_FILTER_IGNORE
    victory31_title = _text(victory31,"VictoryText","VICTORY!",
        Rect2(13,17,374,49),36,WARM_GOLD,HORIZONTAL_ALIGNMENT_CENTER)
    victory31_title.add_theme_constant_override("outline_size",5)
    victory31_title.add_theme_color_override("font_outline_color",Color("#60321e"))
    victory31_reward = _text(victory31,"VictoryReward","",
        Rect2(14,75,371,37),20,Color("#fff1c7"),HORIZONTAL_ALIGNMENT_CENTER)
    victory31.visible = false

func _refresh() -> void:
    super._refresh()
    if not art31_ready or game == null:
        return
    # Maintain an intentional palette while v0.30 updates the active state.
    for kind in DUEL.ORDER:
        var row: Dictionary = roster_rows[kind]
        var chosen: bool = kind == game.active
        var tint: Color = COLORS[game.element(kind)]
        var rich_bg: Color = (
            Color("#553326") if kind == "cindlet" else
            Color("#1a4364") if kind == "brinlet" else
            Color("#304a33"))
        (row["shell"] as Panel).add_theme_stylebox_override("panel",
            _style(rich_bg.lightened(0.13) if chosen else rich_bg,
                WARM_GOLD if chosen else tint,14,3 if chosen else 2,5))
        (row["name"] as Label).add_theme_color_override(
            "font_color",Color("#fff2d7") if chosen else Color("#fff6eb"))
        var spend: Button = row["spend"]
        if not spend.disabled:
            _paint_button(spend,Color("#3e883b"),Color("#e4f2a0"))
        else:
            _paint_button(spend,Color("#263b40"),Color("#63787d"))
    (get_node("ElementGuide1") as Label).add_theme_color_override(
        "font_color",Color("#ffe9ba"))
    # Victory controls should look rewarding; farming is secondary.
    next_button.add_theme_font_size_override("font_size",25)
    if game.awaiting_next and not game.defeated and not game.farming:
        next_button.add_theme_color_override("font_color",Color("#fff6c7"))
    if game.defeated:
        next_button.add_theme_color_override("font_color",Color("#ffedcf"))

func _on_strike31(amount: float,enemy_target: bool,
        element_name: String,manual: bool) -> void:
    if not art31_ready:
        return
    var spot: Vector2 = (Vector2(922,319) if enemy_target
        else Vector2(564,367))
    spot += Vector2(randf_range(-32.0,32.0),randf_range(-22.0,22.0))
    var strong: bool = amount >= 25.0 or manual
    fx31.impact(spot,element_name,strong)
    _float_damage31(amount,spot,enemy_target,element_name,strong)
    if enemy_target:
        enemy_hit31 = 0.22
        lunge31 = 0.20
    else:
        stagger31 = 0.23

func _float_damage31(amount: float,at: Vector2,
        is_enemy: bool,element_name: String,strong: bool) -> void:
    # Dynamic labels follow actual engine strikes, never fake animation damage.
    if damage_labels31.size() >= 16:
        var old: Label = damage_labels31.pop_front()
        if is_instance_valid(old):
            old.queue_free()
    var paint: Color = COLORS.get(element_name,WARM_GOLD)
    var floating: Label = _text(self,"FloatingHit_%d" % Time.get_ticks_msec(),
        "-%s" % game.format_number(amount),Rect2(at.x-65,at.y-30,130,38),
        28 if strong else 23,paint.lightened(0.26),
        HORIZONTAL_ALIGNMENT_CENTER)
    floating.z_index = 9
    floating.add_theme_constant_override("outline_size",5)
    floating.add_theme_color_override("font_outline_color",Color("#15202c"))
    damage_labels31.append(floating)
    var duration: float = 0.80 if strong else 0.59
    var tween := create_tween()
    tween.tween_property(floating,"position",
        floating.position+Vector2(randf_range(-14.0,14.0),-68.0),duration)\
        .set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
    tween.parallel().tween_property(floating,"modulate:a",0.0,
        duration*0.63).set_delay(duration*0.37)
    tween.tween_callback(func() -> void:
        if is_instance_valid(floating):
            damage_labels31.erase(floating)
            floating.queue_free()
    )

func _on_finished31(won: bool,reward: float,_record: bool) -> void:
    if not art31_ready:
        return
    if won:
        fx31.celebrate()
        victory31_left = victory31_total
        victory31.visible = true
        victory31_title.text = "VICTORY!"
        victory31_reward.text = "+%s GOLD   •   STAGE %d" % [
            game.format_number(reward),game.stage]
        victory31.add_theme_stylebox_override("panel",_style(
            Color("#173c3a",0.97),WARM_GOLD,16,3,8))
    else:
        victory31_left = 1.4
        victory31.visible = true
        victory31_title.text = "DEFEATED"
        victory31_reward.text = "TRAIN OR SWITCH TO TRY AGAIN"
        victory31.add_theme_stylebox_override("panel",_style(
            Color("#40272c",0.97),Color("#f5a891"),16,3,8))

func _primary_action() -> void:
    victory31_left = 0.0 if art31_ready else victory31_left
    if art31_ready:
        victory31.hide()
    super._primary_action()

func _farm() -> void:
    if art31_ready:
        victory31_left = 0.0
        victory31.hide()
    super._farm()

func _process(delta: float) -> void:
    super._process(delta)
    if not art31_ready:
        return
    scene_clock31 += delta
    enemy_hit31 = maxf(0.0,enemy_hit31-delta)
    lunge31 = maxf(0.0,lunge31-delta)
    stagger31 = maxf(0.0,stagger31-delta)
    hero_art.position = Vector2(
        454.0+sin((1.0-lunge31/0.20)*PI)*24.0 if lunge31 > 0.0 else 454.0,
        260.0+sin(scene_clock31*1.9)*3.8)
    enemy_art.position = Vector2(
        742.0+sin(scene_clock31*96.0)*enemy_hit31*23.0,
        165.0+sin(scene_clock31*1.52+0.4)*4.3)
    enemy_art.rotation = sin(scene_clock31*84.0)*enemy_hit31*0.06
    hero_art.rotation = -sin(scene_clock31*77.0)*stagger31*0.13
    if enemy_hit31 > 0.0:
        enemy_art.modulate = Color("#fff4e7") if enemy_hit31 > 0.08 else Color.WHITE
    else:
        enemy_art.modulate = (
            Color("#9faeb6",0.49) if game.awaiting_next and not game.defeated
            else Color.WHITE)
    numbers.hide()
    if victory31_left > 0.0:
        victory31_left = maxf(0.0,victory31_left-delta)
        victory31.visible = victory31_left > 0.0
        victory31.modulate.a = clampf(victory31_left*1.8,0.0,1.0)
    else:
        victory31.hide()
