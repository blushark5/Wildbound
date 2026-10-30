@tool
extends StaticBody2D
# Editor-placeable illustrated tree with footprint collision, not canopy collision.
@export_range(0,3) var tree_variant: int = 0:
    set(value):
        tree_variant = clampi(value,0,3)
        if is_node_ready():
            _apply_art()

func _ready() -> void:
    _apply_art()

func _apply_art() -> void:
    var source: Texture2D = load("res://assets/trees_atlas.png") as Texture2D
    if source == null:
        push_error("Original tree atlas not found")
        return
    var cropped := AtlasTexture.new()
    cropped.atlas = source
    cropped.region = Rect2i(tree_variant * 64,0,64,80)
    cropped.filter_clip = true
    var artwork: Sprite2D = get_node("TreeArtwork") as Sprite2D
    artwork.texture = cropped
    artwork.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
