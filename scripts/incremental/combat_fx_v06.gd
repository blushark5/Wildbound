extends Control
## Decorative arena effects. Never handles gameplay or receives mouse input.
var elapsed: float = 0.0
var element: String = "Grove"
var active_resonance: bool = false
var selected_boss: bool = false
var reduced_motion: bool = false
var momentum: float = 0.0
var sparkles: Array[Vector2] = []

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    for i in range(24):
        var px: float = 12.0 + float((i*73 + 29) % 445)
        var py: float = 30.0 + float((i*113 + 47) % 230)
        sparkles.append(Vector2(px,py))

func _process(delta: float) -> void:
    if not reduced_motion:
        elapsed += delta
        queue_redraw()

func refresh_from_game(game, low_motion: bool) -> void:
    element = String(game.SPECIES[game.enemy_species]["element"])
    selected_boss = game.enemy_is_boss()
    active_resonance = game.overdrive_left > 0.0
    momentum = game.damage_flash
    reduced_motion = low_motion
    queue_redraw()

func _draw() -> void:
    var light: Color = Color("#83efb6") if element == "Grove" else (
        Color("#6dd3ff") if element == "Tide" else Color("#ffba65"))
    var wave: float = 0.0 if reduced_motion else elapsed
    # Small hand-placed ground highlights and drifting particles around
    # the real illustrated characters, with no placeholder monster shapes.
    draw_arc(Vector2(90,234),58,0.04,PI-0.04,28,Color(light,0.34),2.0,true)
    draw_arc(Vector2(370,201),83,0.0,PI,32,Color(light,0.27),2.0,true)
    for index in range(sparkles.size()):
        var point: Vector2 = sparkles[index]
        var shimmer: float = 0.15 + 0.16 * sin(wave * 1.8 + float(index)*1.73)
        var radius: float = 1.1 + float(index % 3) * 0.45
        if index % 5 == 0:
            radius += 0.8
        var move: Vector2 = Vector2(0.0,-sin(wave*0.42+float(index))*10.0)
        draw_circle(point + move,maxf(0.65,radius),Color(light,shimmer))
    if selected_boss:
        draw_arc(Vector2(366,157),86,PI*1.03,PI*1.96,44,Color("#f6bd6f",0.52),3.0,true)
    if active_resonance:
        var ring: float = 58.0 + sin(wave*5.0)*8.0
        draw_arc(Vector2(90,163),ring,0.0,TAU,64,Color("#d9a5ff",0.45),3.0,true)
    if momentum > 0.0 and not reduced_motion:
        for i in range(5):
            var vector: Vector2 = Vector2(cos(float(i)*TAU/5.0),sin(float(i)*TAU/5.0))
            draw_line(Vector2(368,137)+vector*15.0,Vector2(368,137)+vector*36.0,Color("#ffdbb3",0.68),2.0,true)
