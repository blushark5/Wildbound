extends Control
## v0.32 art layer. Fully cosmetic and bounded for browser/mobile.
## Draws foreground depth, light shafts, elemental climate and a grounded arena.
var t: float = 0.0
var current_element: String = "Earth"
var old_stage: int = -1
var rng := RandomNumberGenerator.new()
var dust: Array[Dictionary] = []
var leafy: Array[Dictionary] = []
var ambient_tint: Color = Color("#9fe2a7")

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    rng.seed = 20261104
    for i in range(30):
        dust.append({"at":Vector2(rng.randf_range(450.0,1212.0),rng.randf_range(200.0,527.0)),
            "phase":rng.randf_range(0.0,TAU),"size":rng.randf_range(1.5,3.7),
            "speed":rng.randf_range(0.18,0.58)})
    for i in range(25):
        leafy.append({"x":rng.randf_range(425.0,1225.0),
            "y":rng.randf_range(210.0,585.0),
            "phase":rng.randf_range(0.0,TAU),
            "speed":rng.randf_range(0.16,0.48),
            "size":rng.randf_range(2.0,6.0)})

func set_stage(stage: int,element_name: String) -> void:
    if stage == old_stage and element_name == current_element:
        return
    old_stage = stage
    current_element = element_name
    ambient_tint = (Color("#ffc17c") if element_name == "Fire"
        else Color("#92dcff") if element_name == "Water"
        else Color("#a8eb97"))
    queue_redraw()

func _process(delta: float) -> void:
    t += minf(delta,0.06)
    queue_redraw()

func _ellipse(at: Vector2,w: float,h: float,color: Color) -> void:
    var shape := PackedVector2Array()
    for j in range(32):
        var a: float = float(j)*TAU/32.0
        shape.append(at+Vector2(cos(a)*w,sin(a)*h))
    draw_colored_polygon(shape,color)

func _draw() -> void:
    var area := Rect2(405,93,854,526)
    draw_rect(area,Color(ambient_tint,0.065),true)
    # Light entering from canopy, restrained so sprites remain legible.
    var glint: float = 0.7+0.3*sin(t*0.52)
    for j in range(4):
        var x: float = 530.0+float(j)*172.0
        var polygon := PackedVector2Array([
            Vector2(x-18,96),Vector2(x+9,96),
            Vector2(x+158,445),Vector2(x+82,445)])
        draw_colored_polygon(polygon,Color("#fffae3",0.020*glint))
    # Playful painterly staging: living green platforms and light rim edges.
    _ellipse(Vector2(565,454),107,17,Color("#082e30",0.42))
    _ellipse(Vector2(898,461),163,22,Color("#082e30",0.38))
    _ellipse(Vector2(565,449),102,12,Color(ambient_tint,0.115))
    _ellipse(Vector2(899,457),161,13,Color(ambient_tint,0.10))
    # Magical surroundings in the distance; no new game systems or NPCs.
    for i in range(dust.size()):
        var mote: Dictionary = dust[i]
        var origin: Vector2 = mote["at"]
        var phase: float = float(mote["phase"])
        var rise: float = float(mote["speed"])
        var xy: Vector2 = origin+Vector2(12.0*sin(t*rise+phase),
            8.0*cos(t*rise*0.8+phase))
        var alpha: float = 0.05+0.13*(0.5+0.5*sin(t*0.9+phase))
        draw_circle(xy,float(mote["size"])*2.4,Color(ambient_tint,alpha*0.24))
        draw_circle(xy,float(mote["size"]),Color("#fff8d8",alpha))
    # Distinct elemental weather identity for every encounter.
    for i in range(leafy.size()):
        var mote: Dictionary = leafy[i]
        var phase: float = float(mote["phase"])
        var size: float = float(mote["size"])
        var speed: float = float(mote["speed"])
        var x: float = float(mote["x"])+14.0*sin(t*speed+phase)
        var y: float = float(mote["y"])-fmod(t*15.0*speed+phase*13.0,75.0)
        if y < 190.0:
            y += 335.0
        var tint: Color = ambient_tint
        if current_element == "Water":
            draw_line(Vector2(x,y),Vector2(x-2.0,y+size*1.9),
                Color(tint,0.23),1.4,true)
        elif current_element == "Fire":
            draw_circle(Vector2(x,y),size*0.57,Color(tint,0.17))
            draw_circle(Vector2(x,y),size*0.24,Color("#ffebbe",0.26))
        else:
            draw_colored_polygon(PackedVector2Array([
                Vector2(x,y-size),Vector2(x+size*0.6,y),
                Vector2(x,y+size),Vector2(x-size*0.6,y)]),
                Color(tint,0.13))
    # Hand-clipped foreground silhouettes frame rather than block the duel.
    var greens: Array[Color] = [Color("#154c47",0.75),
        Color("#255d4e",0.68),Color("#49805d",0.55)]
    for i in range(24):
        var x: float = 410.0+float(i)*36.0
        var fringe: float = 554.0+7.0*sin(float(i)*1.8)
        var height: float = 10.0+float(i%4)*3.8
        var shade: Color = greens[i%3]
        if x > 485.0 and x < 1113.0:
            continue
        draw_line(Vector2(x,fringe+24),Vector2(x+7.0*sin(t*0.6+float(i)),fringe-height),
            shade,3.2,true)
        draw_colored_polygon(PackedVector2Array([
            Vector2(x,fringe-height),Vector2(x-9,fringe-height+12),
            Vector2(x+5,fringe-height+10)]),shade)
