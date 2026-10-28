extends RefCounted
# Illustrated Willowrest: 48 by 14 tiles, 24 pixels per tile.
const WIDTH: int = 48
const HEIGHT: int = 14
const TILE: int = 24
const SPAWN: Vector2i = Vector2i(24, 7)
const KEEPER: Vector2i = Vector2i(22, 7)

func build() -> Dictionary:
    var blocked: Dictionary = {}
    var tall: Dictionary = {}
    for y in range(HEIGHT):
        for x in range(WIDTH):
            var xx: int = x * TILE + 12
            var yy: int = y * TILE + 12
            var solid: bool = x == 0 or x >= 47 or y == 0 or y >= 13
            if yy < 125 or xx < 410:
                solid = true
            if (xx > 395 and xx < 553 and yy < 106) or (xx > 631 and xx < 776 and yy < 106):
                solid = true
            if xx > 760 and yy < 117:
                solid = true
            if (xx >= 552 and xx <= 631 and yy >= 24 and yy <= 335) or (xx >= 535 and yy >= 178 and yy <= 242):
                solid = false
            if (xx >= 451 and xx <= 505 and yy >= 99 and yy <= 213) or (xx >= 684 and xx <= 731 and yy >= 96 and yy <= 206):
                solid = false
            if xx > 408 and xx < 640 and yy > 112 and yy < 240:
                solid = false
            if xx > 820 and yy > 129 and yy < 179:
                solid = false
            if xx > 645 and yy > 235:
                solid = true
            if xx > 860 and yy > 235:
                solid = true
            if xx < 560 and yy > 248:
                solid = true
            if x == 0 or x == 47 or y == 0 or y == 13:
                solid = true
            var cell: Vector2i = Vector2i(x, y)
            if solid:
                blocked[cell] = true
            elif xx >= 800 and yy >= 129 and (x * 11 + y * 5) % 4 < 3:
                tall[cell] = true
    blocked.erase(SPAWN)
    blocked.erase(KEEPER)
    return {"blocked": blocked, "tall": tall}
