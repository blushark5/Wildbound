extends "res://scripts/incremental/bond_engine_v24.gd"
## Wildbound v0.25 — presentation preferences only.
## Game economy, creature statistics, Ascension and saves are unchanged.
var ui_compact_journey: bool = true
var ui_large_text: bool = false

func to_dict() -> Dictionary:
    var data: Dictionary = super.to_dict()
    data["v25_compact_journey"] = ui_compact_journey
    data["v25_large_text"] = ui_large_text
    return data

func load_save() -> bool:
    var loaded: bool = super.load_save()
    ui_compact_journey = true
    ui_large_text = false
    if not loaded:
        return false
    var handle: FileAccess = FileAccess.open(SAVE_FILE,FileAccess.READ)
    if handle == null:
        return loaded
    var parsed: Variant = JSON.parse_string(handle.get_as_text())
    if parsed is Dictionary:
        ui_compact_journey = bool(parsed.get("v25_compact_journey",true))
        ui_large_text = bool(parsed.get("v25_large_text",false))
    return loaded
