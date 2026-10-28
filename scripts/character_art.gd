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
# Standing poses come from our original concept; walking poses adjust only a few
# existing lower-leg pixels so the face, clothing and backpack never change.
# 0 = standing, 1 and 2 = alternating strides (each completed tile toggles).
var textures: Dictionary = {}

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
        if facing == "up" or facing == "down":
            # Two alternating footfalls retain the original 24×32 silhouette
            # and preserve the faint ground contact/shadow pixels.
            img.fill_rect(Rect2i(2, 27, 20, 3), Color.TRANSPARENT)
            img.fill_rect(Rect2i(10, 26, 4, 4), Color8(24, 38, 49))
            if pose == 1:
                img.blend_rect(base, Rect2i(0, 27, 12, 3), Vector2i(0, 26))
                img.blend_rect(base, Rect2i(12, 27, 12, 3), Vector2i(13, 27))
            else:
                img.blend_rect(base, Rect2i(0, 27, 12, 3), Vector2i(1, 27))
                img.blend_rect(base, Rect2i(12, 27, 12, 3), Vector2i(12, 26))
        else:
            # One foot leads in a side view, so shift the lower stride without
            # distorting the face, cap or backpack.
            img.fill_rect(Rect2i(2, 27, 20, 3), Color.TRANSPARENT)
            img.fill_rect(Rect2i(9, 26, 7, 4), Color8(27, 43, 54))
            img.blend_rect(base, Rect2i(2, 26, 20, 4), Vector2i(3 if pose == 1 else 1, 26))
    var texture: ImageTexture = ImageTexture.create_from_image(img)
    textures[key] = texture
    return texture
