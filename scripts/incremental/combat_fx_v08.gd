extends "res://scripts/incremental/combat_fx_v06.gd"
## Sized for the actual 704 x 332 v0.8 stage, independent of combat math.

func _draw() -> void:
    var bounds: Vector2 = size
    if bounds.x <= 0.0 or bounds.y <= 0.0:
        return
    var light: Color = Color("#a0e6aa") if element == "Grove" else (
        Color("#8ad5f5") if element == "Tide" else Color("#ffbb86"))
    var time: float = 0.0 if reduced_motion else elapsed
    var lead: Vector2 = Vector2(bounds.x*0.16,bounds.y*0.89)
    var ally_two: Vector2 = Vector2(bounds.x*0.35,bounds.y*0.91)
    var ally_three: Vector2 = Vector2(bounds.x*0.49,bounds.y*0.93)
    var enemy: Vector2 = Vector2(bounds.x*0.79,bounds.y*0.89)
    draw_rect(Rect2(0,bounds.y*0.77,bounds.x,bounds.y*0.23),Color("#0d2e2b",0.055))
    for location in [lead,ally_two,ally_three]:
        draw_arc(location,34,0.03,PI-0.03,22,Color(light,0.22),2.0,true)
        draw_arc(location,39,PI*1.05,PI*1.95,22,Color("#203c41",0.30),1.5,true)
    draw_arc(enemy,72,0.04,PI-0.04,40,Color(light,0.40),2.5,true)
    draw_arc(enemy,80,PI*1.06,PI*1.94,36,Color("#233340",0.34),2.0,true)
    for i in range(sparkles.size()):
        var seed: Vector2 = sparkles[i]
        var point: Vector2 = Vector2(14+fmod(seed.x*1.49,bounds.x-28.0),
            35+fmod(seed.y*1.23,bounds.y-95.0))
        var opacity: float = 0.12 if reduced_motion else 0.14+0.13*sin(time*1.6+float(i)*1.71)
        draw_circle(point+Vector2(0,0 if reduced_motion else sin(time*0.7+float(i))*5.0),
            1.0+float(i%3)*0.45,Color(light,opacity))
    if selected_boss:
        draw_arc(enemy+Vector2(0,-77),98,PI*1.01,PI*1.99,48,
            Color("#f7bb74",0.48),3.0,true)
        draw_arc(enemy+Vector2(0,-77),105,0.02,PI*0.99,48,
            Color("#fbe1aa",0.23),2.0,true)
    if active_resonance:
        draw_arc(lead+Vector2(0,-85),66+sin(time*3.0)*6.0,0,TAU,48,
            Color("#dab5ff",0.42),2.5,true)
    if momentum > 0.0 and not reduced_motion:
        var impact: Vector2 = enemy+Vector2(0,-106)
        for i in range(7):
            var v: Vector2 = Vector2(cos(float(i)*TAU/7.0),sin(float(i)*TAU/7.0))
            draw_line(impact+v*14,impact+v*34,Color("#ffe5ba",0.77),2.2,true)
