extends RefCounted
## Browser-local, three-slot save manager. The current slot continues using
## the historic engine SAVE_FILE; switching swaps snapshots instead of
## changing the Godot project identity, so legacy saves remain accessible.
const META: String = "user://wildbound_bond_save_slots_v19.json"
const SLOTS: int = 3

static func slot_path(index: int) -> String:
    return "user://wildbound_bond_slot_%d_v19.json" % index

static func active_slot() -> int:
    if not FileAccess.file_exists(META):
        return 1
    var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(META))
    if not (data is Dictionary):
        return 1
    return clampi(int(data.get("active",1)),1,SLOTS)

static func _write_active(index: int) -> bool:
    var f: FileAccess = FileAccess.open(META,FileAccess.WRITE)
    if f == null:
        return false
    f.store_string(JSON.stringify({"active":clampi(index,1,SLOTS)}))
    return true

static func _delete(path: String) -> bool:
    if not FileAccess.file_exists(path):
        return true
    return DirAccess.remove_absolute(ProjectSettings.globalize_path(path)) == OK

static func _copy(source: String,target: String) -> bool:
    if not FileAccess.file_exists(source):
        return false
    var data: PackedByteArray = FileAccess.get_file_as_bytes(source)
    if data.is_empty():
        return false
    var dst: FileAccess = FileAccess.open(target,FileAccess.WRITE)
    if dst == null:
        return false
    dst.store_buffer(data)
    dst.flush()
    return true

static func slot_exists(canonical: String,index: int) -> bool:
    if index < 1 or index > SLOTS:
        return false
    return FileAccess.file_exists(canonical if index == active_slot() else slot_path(index))

static func slot_summary(canonical: String,index: int) -> String:
    if not slot_exists(canonical,index):
        return "EMPTY • NEW GAME"
    var path: String = canonical if index == active_slot() else slot_path(index)
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
    if not (parsed is Dictionary):
        return "UNREADABLE SAVE"
    var data: Dictionary = parsed
    var collection: Dictionary = data.get("v12_collection",{})
    return "STAGE %d • ASC %d • %d CREATURES" % [
        int(data.get("wave",1)),int(data.get("ascensions",0)),
        maxi(1,collection.size())]

static func switch_to(canonical: String,index: int) -> bool:
    if index < 1 or index > SLOTS:
        return false
    var current: int = active_slot()
    if current == index:
        return true
    # Keep active canonical progress safe before loading another slot.
    if FileAccess.file_exists(canonical):
        if not _copy(canonical,slot_path(current)):
            return false
    elif not _delete(slot_path(current)):
        return false
    var target: String = slot_path(index)
    if FileAccess.file_exists(target):
        if not _copy(target,canonical):
            return false
    elif not _delete(canonical):
        return false
    return _write_active(index)

static func erase_slot(canonical: String,index: int) -> bool:
    if index < 1 or index > SLOTS:
        return false
    var ok: bool = _delete(slot_path(index))
    if index == active_slot():
        ok = _delete(canonical) and ok
    return ok

static func erase_all(canonical: String) -> bool:
    var ok: bool = _delete(canonical)
    for i in range(1,SLOTS+1):
        ok = _delete(slot_path(i)) and ok
    ok = _delete(META) and ok
    return ok
