extends "res://scripts/duel/duel_vfx_v31.gd"
## v0.32 - visually meaningful Fire, Water and Earth strikes with short arcs.
## The underlying hit is already resolved by the 1v1 engine.
var traveling: Array[Dictionary] = []

func launch(from: Vector2,to: Vector2,element_name: String,manual: bool) -> void:
    if traveling.size() >= 10:
        traveling.pop_front()
    traveling.append({"from":from,"to":to,"element":element_name,
        "elapsed":0.0,"duration":0.31 if manual else 0.23,
        "thick":manual,"arc":-54.0 if manual else -31.0})
    queue_redraw()

func _process(delta: float) -> void:
    super._process(delta)
    var dt: float = minf(delta,0.06)
    for i in range(traveling.size()-1,-1,-1):
        traveling[i]["elapsed"] = float(traveling[i]["elapsed"])+dt
        if float(traveling[i]["elapsed"]) >= float(traveling[i]["duration"]):
            traveling.remove_at(i)
    queue_redraw()

func _path(m: Dictionary,f: float) -> Vector2:
    var source: Vector2 = m["from"]
    var dest: Vector2 = m["to"]
    return source.lerp(dest,f)+Vector2(0.0,float(m["arc"])*sin(f*PI))

func _draw() -> void:
    super._draw()
    # Animated energy tails are purely visual, attached to actual game hits.
    for projectile in traveling:
        var p: float = clampf(float(projectile["elapsed"])/
            float(projectile["duration"]),0.0,1.0)
        var tone: Color = _element_color(String(projectile["element"]))
        var bold: bool = bool(projectile["thick"])
        var radius: float = 11.0 if bold else 7.0
        var cursor: Vector2 = _path(projectile,p)
        for j in range(11,0,-1):
            var q: float = maxf(0.0,p-float(j)*0.026)
            var p1: Vector2 = _path(projectile,q)
            var p2: Vector2 = _path(projectile,maxf(0.0,q-0.022))
            var opacity: float = 0.10+0.065*float(12-j)
            draw_line(p1,p2,Color(tone,opacity),maxf(1.0,radius*(1.0-float(j)/13.0)),true)
        var inner: Color = Color("#fff8df",0.8)
        if String(projectile["element"]) == "Water":
            draw_circle(cursor,radius*1.7,Color("#4fdfff",0.13))
            draw_circle(cursor,radius,Color(tone,0.53))
            draw_circle(cursor,radius*0.48,inner)
            for k in range(3):
                var aa: float = t_step(p,k)
                draw_arc(cursor+Vector2(-22.0,0.0),7.0+float(k)*3.0,
                    aa,aa+PI,14,Color(tone,0.20),1.5,true)
        elif String(projectile["element"]) == "Fire":
            var lick := PackedVector2Array([
                cursor+Vector2(12,0),cursor+Vector2(-6,13),
                cursor+Vector2(-16,-1),cursor+Vector2(-5,-14)])
            draw_colored_polygon(lick,Color(tone,0.75))
            draw_circle(cursor,radius*0.55,Color("#ffecac",0.95))
        else:
            var shard := PackedVector2Array([
                cursor+Vector2(12,-2),cursor+Vector2(0,8),
                cursor+Vector2(-14,4),cursor+Vector2(-1,-12)])
            draw_colored_polygon(shard,Color("#b8f69f",0.85))
            draw_line(cursor+Vector2(-8,-4),cursor+Vector2(7,1),
                Color("#fff6c6",0.75),2.5,true)

func t_step(progress: float,offset: int) -> float:
    return progress*TAU+float(offset)*1.43
