extends "res://scripts/incremental/bond_engine_v18.gd"
## v0.19: explicit first-battle consent. Old saves are NOT re-gated.
var battle_started: bool = false

func to_dict() -> Dictionary:
    var data: Dictionary = super.to_dict()
    data["v19_battle_started"] = battle_started
    return data

func load_save() -> bool:
    var loaded: bool = super.load_save()
    if not loaded:
        battle_started = false
        return false
    var file: FileAccess = FileAccess.open(SAVE_FILE,FileAccess.READ)
    if file == null:
        battle_started = true
        return true
    var parsed: Variant = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        # No v19 marker = player previously used the old auto-battling game.
        # Do not interrupt their existing encounter or force a new tutorial.
        battle_started = bool(parsed.get("v19_battle_started",true))
    else:
        battle_started = true
    return true
