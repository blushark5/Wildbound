extends Control
## Battle VFX v0.31 — tiny deterministic-feeling, frame-driven visual effects.
## This layer does not touch progression, saves, enemy targeting or damage.
var motes: Array[Dictionary] = []
var particles: Array[Dictionary] = []
var rings: Array[Dictionary] = []
var clock: float = 0.0
var rng := RandomNumberGenerator.new()
var arena: Rect2 = Rect2(425,174,796,367)

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    rng.randomize()
    for i in range(24):
        motes.append({"at":Vector2(rng.randf_range(440.0,1200.0),rng.randf_range(190.0,533.0)),
            "phase":rng.randf_range(0.0,TAU),"rate":rng.randf_range(0.55,1.45),
            "radius":rng.randf_range(1.2,3.1),"tone":Color("#fff4bf") if i%3 == 0 else Color("#b0fff1")})

func _element_color(element_name: String) -> Color:
    match element_name:
        "Fire":
            return Color("#ffae57")
        "Water":
            return Color("#57d8ff")
        "Earth":
            return Color("#b5ed7f")
        _:
            return Color("#ffdc97")

func impact(where: Vector2,element_name: String,strong: bool = false) -> void:
    var tint: Color = _element_color(element_name)
    var amount: int = 24 if strong else 13
    var speed: float = 200.0 if strong else 132.0
    for i in range(amount):
        var angle: float = TAU*float(i)/float(amount)+rng.randf_range(-0.25,0.25)
        var unit: Vector2 = Vector2(cos(angle),sin(angle))
        var life: float = rng.randf_range(0.30,0.67)
        particles.append({"at":where+unit*rng.randf_range(3.0,18.0),
            "v":unit*rng.randf_range(speed*0.40,speed),"life":life,"ttl":life,
            "tone":tint.lightened(rng.randf_range(0.0,0.46)),"radius":rng.randf_range(2.0,5.4),
            "gravity":rng.randf_range(32.0,90.0),"streak":true})
    rings.append({"at":where,"age":0.0,"ttl":0.36 if strong else 0.24,
        "tone":tint,"radius":19.0 if strong else 11.0})
    queue_redraw()

func celebrate() -> void:
    var center: Vector2 = Vector2(831,318)
    for i in range(55):
        var angle: float = rng.randf_range(0.12,PI-0.12)
        var speed: float = rng.randf_range(70.0,310.0)
        var tone: Color = [Color("#ffe9a3"),Color("#f4bf59"),Color("#80ecb5"),
            Color("#b7ebff"),Color("#f9ab79")][i%5]
        var ttl: float = rng.randf_range(0.75,1.35)
        particles.append({"at":center+Vector2(rng.randf_range(-190.0,190.0),rng.randf_range(-80.0,25.0)),
            "v":Vector2(cos(angle),-sin(angle))*speed,
            "life":ttl,"ttl":ttl,"tone":tone,"radius":rng.randf_range(2.0,5.5),
            "gravity":170.0,"streak":false})
    rings.append({"at":center,"age":0.0,"ttl":0.75,"tone":Color("#ffe6a2"),"radius":45.0})
    queue_redraw()

func _process(delta: float) -> void:
    var dt: float = minf(0.05,delta)
    clock += dt
    for i in range(particles.size()-1,-1,-1):
        var p: Dictionary = particles[i]
        p["life"] = float(p["life"])-dt
        if float(p["life"]) <= 0.0:
            particles.remove_at(i)
            continue
        p["at"] = (p["at"] as Vector2)+(p["v"] as Vector2)*dt
        p["v"] = (p["v"] as Vector2)+Vector2(0.0,float(p["gravity"])*dt)
    for i in range(rings.size()-1,-1,-1):
        var ring: Dictionary = rings[i]
        ring["age"] = float(ring["age"])+dt
        if float(ring["age"]) >= float(ring["ttl"]):
            rings.remove_at(i)
    queue_redraw()

func _draw() -> void:
    for mote in motes:
        var origin: Vector2 = mote["at"]
        var phase: float = float(mote["phase"])
        var rate: float = float(mote["rate"])
        var point: Vector2 = origin+Vector2(sin(clock*rate+phase)*7.0,
            cos(clock*rate*0.83+phase)*9.0)
        var alpha: float = 0.14+0.19*(0.5+0.5*sin(clock*1.4+phase))
        draw_circle(point,float(mote["radius"])*2.8,Color("#b7ffd8",alpha*0.19))
        draw_circle(point,float(mote["radius"]),Color(mote["tone"],alpha))
    for ring in rings:
        var progress: float = float(ring["age"])/float(ring["ttl"])
        var shade: Color = Color(ring["tone"],(1.0-progress)*0.72)
        var rad: float = float(ring["radius"])+progress*85.0
        draw_arc(ring["at"],rad,0.0,TAU,38,shade,3.0, true)
    for part in particles:
        var t: float = float(part["life"])/float(part["ttl"])
        var color: Color = Color(part["tone"],clampf(t,0.0,1.0))
        var p: Vector2 = part["at"]
        var v: Vector2 = part["v"]
        if bool(part["streak"]):
            draw_line(p,p-v.normalized()*minf(16.0,v.length()*0.085),color,
                maxf(1.0,float(part["radius"])*0.7),true)
        draw_circle(p,float(part["radius"])*clampf(t,0.25,1.0),color)
