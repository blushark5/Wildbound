extends RefCounted
# Proof-of-concept sprites sampled from our original Wildbound art direction board.
# Sprite PNG pixels are stored as base64 for a zero-download GitHub text-asset test.
# This is temporary: replace with source PNG spritesheets after visual approval.
const PNG_DATA: Dictionary = {
    "down": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAgCAMAAAA/gEgKAAAAkFBMVEVpY14lUGPZnWuZnp/q5dIYGyPqs4iqimtoTDvt1a4YMVCTcFYjYooqjJCzaTpedYXIc0d5hH5hppe/wrm7wsNCJR1KP0NpwKu1v8IAAAArKC1ONjJzRjgxMzgtOkcRHCkUJjOOUzyHTDuoZERIRkgHKkkFChcXNlEoSGewtrVIKidSVlhlPDONV0GxdlL6yJGpietWAAAAMHRSTlP/////////////////////////////////AP////////////////////////////80bkX5AAABrklEQVR42nWSB24jMQxFSWmqe8qWkOqeXu9/u1UytuNdYAkBAvTET+KT8PGfgNsF8WhQ8A8gyFkpdfLsngFUzBxUmAMP0wzjHaCeQoj/I/EhTFzdwKg5XH1899cYnn8+pCp1FYuffFCfJKihugGtlDgNuvCDWmalhpQ2QLHyjHh8zQG9p4nNJmWIyODxiL9ej2igjf/GW3GqD9gqRmSlEZ0lfa9BqaXUz1Nw/KPWBPeuKG9AukWIq82WZike7ZJgkbTZugpXZoPgB9CKRfmyrmv2Ugqlxm+vtMvXchWiLLOF3LO7VapEjEwUTfXsrrFd3VBRUOOwNt9At3jYww6uBKLDlh5gd8DdHgCqM+Q7PJg7IJmc67zoe5lUMUNKewdLltcC+iRJRoGQ5JsWROHLcAOxRnoR8CUGbr9mVZ2DLJM3EIZEtt/moSGbiZbCFkrzhaPAfsuIk6WGT9wCdPrEjVX82BK0LZmurtvOoKVnS1yH2FpnEbu/Fu7DmsrEmTQ71PYJ9PpzH1KQabyI5NsGZP+bJq84Hc/p5GeVynf5Bfq+H2MGOZCaBqboyfsn+ANE8EV+ic2aPgAAAABJRU5ErkJggg==",
    "up": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAgCAMAAAA/gEgKAAAAkFBMVEWWnqCiY0gkUWpoWlXjlWoQEBscbo3YXDnX29RjRz3lz7GTOy6sSja8w8fptI8VP2FeIyBCNEBAboyehW3SbUYAAAAtKDBRNjNzRDgLGSkTJTXSVTiGTDmTVTwyMzoqHSVJSEs4Q08RRmdNKShqPTSRWUMPOVELV2cuOEeoWjwMKkMUSFZQVVfZaENnbG2mPC5ENPbAAAAAMHRSTlP///////////////////////////8A//////////////////////////////////+B+Kl4AAABwElEQVR42nWS6barIAyFcbbjGZuQFBDHOtT2/d/ugLpu++fGpUv5SLKzUVz+E2J5RvZxiR53G7X3dxBdUEaIKHWA9v4Cj95KbBqptEaoUe7uKwAjXTTuVi60ROgXYAFVoD2Tug1ardBspazUgx6UdJfSbaukROuBQb9TuwZu3WOEwucIQFc+UGoYBt+qcersUgrA60SnSflV6b5hAz0YdCplg3UNwMRQrnK5mhjcAAhgpokZVlWlbGm6heHUTbc0vTH+0ArCXZwAdbclOkNBzNsc0Y7Ml6vNI7tmCciXiYbhC8GAiyKBN3ctUVEUbrUgKh8vQFR15FQyd1xVtPkuBIffY1VVaZpWXRiOIdtNbpkL4t43ILLQpWG5As5zURznObv6+Oy+859kAea8F/V1+M2ybJ6DQ7nfB6tXcfwL9bU++P2NPEIwxzt/hOJ8jqHOjofn8/AchiO18T7o14zAZawxXxXtgjhaAEYFwefa+vmsKUGJ24Alf7B3w02ejGRek7sRw2X2rvqoxjevIjJlOXJuqS97pn9gOXUEzktC/3Lfr+AkEul/PxKmaNq2LexJiMVEYVwGkBWR9wvNQ4iTA39QqkaTQ5JNGQAAAABJRU5ErkJggg==",
    "left": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAgCAMAAAA/gEgKAAAAkFBMVEUeWGZSXGbUlGudak7i4M6emZHy1a6VOC0TEhkILlDjtY1ddIetVzq3xMQNbYK0vcHjeVNlKixCpaYAAAAxJytONzJzRDeUVTxISU0TGykUJDJtOC8xNDiKSzitZUMVN1Owt7lKKykwO0cuSE74xpVpa2ptdnSjrK1TVVSXW0LGSjVWQztqV07NVDrwqHUVFRonjlwKAAAAMHRSTlP/////////////////////////AP/////////////////////////////////////Y5iHdAAABnklEQVR42nXS15ajMAwAUJuaOmWRXDEdQgnJ///dijCThYflUM+VbCSbJf852Ouu1L3rOnqpENsdDJlAxGlCN9zTf9C3KGQmhbDOYYkvWqBNUUp/ASGkpIdSK3AKz7KLdMK5IRuc6NeM1AqKziQNJi9ykMIiKAKoaAJUGZBZmVEWAvRLRne3wP4wVjsHJcULW/brHACGLQficgGdsIIyRkqLNavZB6sNgDZqrUPpDJ5+BilQzgcz+l35wVM8OvngP16j5m/AE+dB4w1eg7rUef0L4EenJmoenucDzaDevWrvXtQ03uNLHAg2TUySSVI0VaaNUdu200LA86DzY56zH/kFanye8y7Xdnb9LkOdWRsEnbHzl6s3kIbXYxgEQfUdz7HZQhTVaRiGuZ1jm24hCNh08nwdj6PbZYTd1ESRX46XeQ+A8Ggeh3IcR1ttoeK6FFbrMrZq+7s9lZYfj0zX6b7yxGh25pyZNtmDMrRsSlVabaH45MABBO3CJ/8sih8oiuIawhNpg1iheVAUtxWut9utCGkPlJiiPhfLZ5L8BQcoQB7iKSSfAAAAAElFTkSuQmCC",
    "right": "iVBORw0KGgoAAAANSUhEUgAAABgAAAAgCAMAAAA/gEgKAAAAkFBMVEUdV2djaGrhn26caVCtVDjacEnv1aqXn57q6dWdOy4MLEtdRj7LUjYrk4pmLiykhWzdu5YREB8PdIJkoJBAPUN0fYK2v8G4wsMAAAB0RThPNzQuJy2FSjkQGiprOjAWJjUzNjqTVDsRNlNKR0istbc2RUz4xpENEx0vOkmsaEcDBxZRVFJnWVFUKiqkrKslGyM2TK0tAAAAMHRSTlP///////////////////////////////8A//////////////////////////////9GarqkAAABjElEQVR42nWS6XajMAyFvbBlT6fTTi15xZglEHj/txunIanbOaMfYO53JKRrkY//BFnfdudpjADUpwA/vIYYQjhBU2B3IorCOaeRTv4BPEonoy7iI57ArmBEFEP2KWfDwKWeHhmjkFmWOTc4KfXgtAZ6zwARlUzwXMBkQcJi7xm/Yzda6kVIS14PBAWspRABrtYED4cDIcQg+DvoFaIhv6JGrNZSmZGuPzefcjCddh0O4TkgrW8FGL9wdh5H1j9Bb5RFZLlmbXGazrvEEouAnOURtG3BVeJVWFBBBDHYlJo4GhNbk5yxAdL7CIbUt+g61acX5d3+uK0DJbW/O7sCI/L9sQ5FNdcTvyTgorPNVb1WVRVomYLuutnLF1qdT1gW34DIbynTwNjpR6l8E0nH26LgLwmwOsv2R1TL0LJ17Ee7oK9q26tlJ7D7sXDGRIvrrcJ/NtFso/f91+BfoPc+XqUK38BcUQVxaxQILJsnaJrmD+2ElI4j2jJ+3kHzPpfN221VQFjazOXczBH8BbdkSGzA8AJrAAAAAElFTkSuQmCC"
}
# Each walking frame is a native 24×32 pixel edit of the approved concept
# character. Entire legs AND boots are redrawn so both feet visibly leave their
# idle positions; the upper body/face/backpack remain unchanged.
# pose 0 = original idle, pose 1/2 = alternating left and right footfalls.
const OUTLINE: Color = Color8(25, 30, 41)
const PANT: Color = Color8(26, 62, 84)
const PANT_LIGHT: Color = Color8(39, 84, 111)
const BOOT: Color = Color8(104, 60, 49)
const BOOT_HIGHLIGHT: Color = Color8(145, 86, 61)
const BOOT_SHADE: Color = Color8(72, 45, 44)
const SHADOW: Color = Color8(153, 163, 164, 140)

var textures: Dictionary = {}

func _rect(img: Image, x1: int, y1: int, x2: int, y2: int, col: Color) -> void:
    img.fill_rect(Rect2i(x1, y1, x2 - x1 + 1, y2 - y1 + 1), col)

func _leg_front(img: Image, x: int, ankle_y: int, foot_x: int) -> void:
    # Pants, left/right ankle and the same boot move together as a unit.
    _rect(img, x + 1, 25, x + 4, 26, OUTLINE)
    _rect(img, x + 1, 26, x + 4, ankle_y - 1, PANT)
    _rect(img, x + 2, 26, x + 2, maxi(26, ankle_y - 2), PANT_LIGHT)
    _rect(img, foot_x, ankle_y, foot_x + 6, ankle_y + 2, OUTLINE)
    _rect(img, foot_x + 1, ankle_y, foot_x + 5, ankle_y + 1, BOOT)
    img.set_pixel(foot_x + 3, ankle_y, BOOT_HIGHLIGHT)
    _rect(img, foot_x + 1, ankle_y + 2, foot_x + 6, ankle_y + 2, BOOT_SHADE)

func _leg_side(img: Image, x: int, ankle_y: int, foot_x: int, leading: bool) -> void:
    _rect(img, x, 25, x + 3, 26, OUTLINE)
    _rect(img, x + 1, 26, x + 3, ankle_y - 1, PANT)
    _rect(img, x + 2, 26, x + 2, maxi(26, ankle_y - 2), PANT_LIGHT)
    if leading:
        # Extended toe is unmistakably further forward than the back shoe.
        _rect(img, foot_x, ankle_y, foot_x + 6, ankle_y + 2, OUTLINE)
        _rect(img, foot_x + 1, ankle_y, foot_x + 5, ankle_y + 1, BOOT)
        img.set_pixel(foot_x + 3, ankle_y, BOOT_HIGHLIGHT)
    else:
        _rect(img, foot_x, ankle_y, foot_x + 4, ankle_y + 2, OUTLINE)
        _rect(img, foot_x + 1, ankle_y, foot_x + 3, ankle_y + 1, BOOT_SHADE)

func sprite(facing: String, pose: int = 0) -> Texture2D:
    var key: String = "%s:%d" % [facing, pose]
    if textures.has(key):
        return textures[key]
    var source: String = String(PNG_DATA.get(facing, PNG_DATA["down"]))
    var base: Image = Image.new()
    var err: Error = base.load_png_from_buffer(Marshalls.base64_to_raw(source))
    if err != OK:
        push_error("Wildbound hero image decode failed for " + facing)
        return null
    var img: Image = base.duplicate() as Image
    if pose != 0:
        img.convert(Image.FORMAT_RGBA8)
        # Clear the original legs, BOTH stationary shoes, and baked shadow.
        # Never alter the face or torso.
        _rect(img, 1, 25, 22, 31, Color.TRANSPARENT)
        _rect(img, 4, 31, 20, 31, SHADOW)
        if facing == "down" or facing == "up":
            if pose == 1:
                _leg_front(img, 6, 29, 4)
                _leg_front(img, 14, 27, 14)
            else:
                _leg_front(img, 6, 27, 5)
                _leg_front(img, 14, 29, 14)
        elif facing == "right":
            if pose == 1:
                _leg_side(img, 7, 27, 6, false)
                _leg_side(img, 13, 29, 15, true)
            else:
                _leg_side(img, 7, 29, 5, true)
                _leg_side(img, 13, 27, 14, false)
        elif facing == "left":
            if pose == 1:
                _leg_side(img, 11, 27, 13, false)
                _leg_side(img, 6, 29, 3, true)
            else:
                _leg_side(img, 11, 29, 13, true)
                _leg_side(img, 6, 27, 4, false)
    var texture: ImageTexture = ImageTexture.create_from_image(img)
    textures[key] = texture
    return texture
