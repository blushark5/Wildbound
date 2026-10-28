extends RefCounted
# Hand-authored walkable footprints aligned to the ACTUAL painted Willowrest scene.
# The previous code allowed large rectangular shortcuts through tree canopies.
# Feet stand at the center of a 24px tile; only visually clear terrain is open.
const WIDTH: int = 48
const HEIGHT: int = 14
const TILE: int = 24
const SPAWN: Vector2i = Vector2i(24, 7)
const KEEPER: Vector2i = Vector2i(23, 8)

func build() -> Dictionary:
    var blocked: Dictionary = {}
    var tall: Dictionary = {}
    # Areas intentionally traversable: plaza, roads, door approaches and meadow.
    var open_areas: Array[Rect2i] = [
        Rect2i(408, 110, 375, 88),
        Rect2i(525, 180, 627, 52),
        Rect2i(549, 0, 90, 336),
        Rect2i(449, 92, 63, 132),
        Rect2i(676, 92, 70, 135),
        Rect2i(772, 127, 376, 57),
        Rect2i(813, 230, 135, 55),
    ]
    # These shapes are occupied by the ILLUSTRATED scenery: house walls,
    # flowerbeds, trees, bushes, well, bench, lantern and fence. No alpha fades.
    var scenery: Array[Rect2i] = [
        Rect2i(397, 0, 151, 109),   # red-roof house
        Rect2i(630, 0, 154, 107),   # blue-roof house
        Rect2i(505, 105, 61, 59),   # west flowerbed
        Rect2i(634, 98, 66, 66),    # center flowerbed
        Rect2i(735, 108, 48, 62),   # flowers/sign near blue house
        Rect2i(798, 0, 126, 148),   # eastern treeline 1
        Rect2i(904, 0, 115, 138),   # eastern treeline 2
        Rect2i(987, 0, 165, 135),   # eastern treeline 3
        Rect2i(992, 122, 93, 60),   # bench and garden
        Rect2i(1078, 141, 48, 86),  # lamppost
        Rect2i(627, 218, 182, 118), # lower grove of broadleaf/pine trees
        Rect2i(783, 233, 191, 103), # lower-right trees
        Rect2i(922, 224, 230, 66),  # fence and shrubs
        Rect2i(781, 139, 38, 40),   # signpost
        Rect2i(398, 104, 55, 55),   # sign and flowers
        Rect2i(405, 169, 57, 24),   # water-side boundary
    ]
    for y in range(HEIGHT):
        for x in range(WIDTH):
            var cell: Vector2i = Vector2i(x, y)
            var foot: Vector2i = Vector2i(x * TILE + TILE / 2, y * TILE + TILE / 2)
            var open: bool = false
            for area in open_areas:
                if area.has_point(foot):
                    open = true
                    break
            if open:
                for object_rect in scenery:
                    if object_rect.has_point(foot):
                        open = false
                        break
            if x == 0 or y == 0 or x == WIDTH - 1 or y == HEIGHT - 1:
                open = false
            if not open:
                blocked[cell] = true
            elif foot.x >= 841 and foot.y >= 128 and foot.y <= 182 and (x * 3 + y * 2) % 3 != 0:
                tall[cell] = true
    blocked.erase(SPAWN)
    blocked.erase(KEEPER)
    return {"blocked": blocked, "tall": tall}
