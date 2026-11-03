extends "res://scripts/incremental/v04_engine.gd"
## v0.9: authored, claimable, permanent journey milestones.
## No parallel combat simulation. All rewards use the real existing economy.
const TRAIL = [
    {"name":"First Footsteps","hint":"Beat the first 2 rival trainer squads; then recruit Brinlet to counter the Ember trio.","kind":"kills","target":2,"gold":45.0,"shards":0,"echoes":0},
    {"name":"A Second Companion","hint":"Recruit Brinlet from its creature card. Different elements counter different foes.","kind":"brinlet","target":1,"gold":65.0,"shards":0,"echoes":0},
    {"name":"Growing Stronger","hint":"Level Spriglet to 5. Each level strengthens every automatic attack.","kind":"level","target":5,"gold":110.0,"shards":0,"echoes":0},
    {"name":"The Full Pack","hint":"Recruit Cindlet. All three creatures can fight together.","kind":"cindlet","target":1,"gold":115.0,"shards":1,"echoes":0},
    {"name":"The First Guardian","hint":"Defeat the Guardian at wave 10. Guardian victories grant Nest Shards and Relics.","kind":"guardian","target":10,"gold":185.0,"shards":3,"echoes":0},
    {"name":"A New Beginning","hint":"Hatch an egg in the Nest using 5 Nest Shards. Duplicate eggs improve your genes.","kind":"egg","target":1,"gold":220.0,"shards":5,"echoes":0},
    {"name":"True Evolution","hint":"Evolve any companion: level 15 and 25 bonds. Bonds grow after battles.","kind":"evolution","target":1,"gold":360.0,"shards":4,"echoes":0},
    {"name":"Into the Deep Wilds","hint":"Reach wave 20. The first Ascension becomes available beyond this point.","kind":"wave","target":20,"gold":500.0,"shards":0,"echoes":2},
    {"name":"Renew the Circle","hint":"Ascend once in Legacy. Gold and levels reset, but bonds and evolution remain.","kind":"ascend","target":1,"gold":180.0,"shards":5,"echoes":3},
    {"name":"Beyond the Meadow","hint":"Reach wave 30 to unlock Moonlit Shore in World.","kind":"wave","target":30,"gold":800.0,"shards":8,"echoes":3}
]
var trail_rank: int = 0

func trail_complete() -> bool:
    return trail_rank >= TRAIL.size()

func trail_info() -> Dictionary:
    return {"name":"The Journey Continues","hint":"The opening trail is complete. Push deeper, hatch rare variants, and master the four regions.","kind":"end","target":1,"gold":0.0,"shards":0,"echoes":0} if trail_complete() else TRAIL[trail_rank]

func trail_progress() -> int:
    if trail_complete():
        return 1
    match String(trail_info()["kind"]):
        "kills":
            return kills
        "brinlet":
            return 1 if int(levels["brinlet"]) > 0 else 0
        "level":
            return int(levels["spriglet"])
        "cindlet":
            return 1 if int(levels["cindlet"]) > 0 else 0
        "guardian":
            return last_boss_wave
        "egg":
            return eggs_hatched
        "evolution":
            var evolved_count: int = 0
            for kind in ORDER:
                if bool(evolved[kind]):
                    evolved_count += 1
            return evolved_count
        "wave":
            return best_wave
        "ascend":
            return ascensions
    return 0

func trail_ready() -> bool:
    return not trail_complete() and trail_progress() >= int(trail_info()["target"])

func claim_trail() -> bool:
    if not trail_ready():
        return false
    var step: Dictionary = trail_info()
    trail_rank += 1
    gold += float(step["gold"])
    lifetime_gold += float(step["gold"])
    nests += int(step["shards"])
    echoes += int(step["echoes"])
    lifetime_echoes += int(step["echoes"])
    _report("TRAIL COMPLETE: %s! Permanent pack bond +12%%. +%s Gold, +%d Shards, +%d Echoes." % [
        String(step["name"]),format_number(float(step["gold"])),int(step["shards"]),int(step["echoes"])])
    return true

func species_damage(kind: String) -> float:
    return super.species_damage(kind) * pow(1.12,float(trail_rank))

func wave_reward() -> float:
    return super.wave_reward() * pow(1.06,float(trail_rank))

func to_dict() -> Dictionary:
    var state: Dictionary = super.to_dict()
    state["v09_trail_rank"] = trail_rank
    return state

func load_save() -> bool:
    var loaded: bool = super.load_save()
    if not loaded:
        return false
    var file: FileAccess = FileAccess.open(SAVE_FILE,FileAccess.READ)
    if file == null:
        return true
    var data: Variant = JSON.parse_string(file.get_as_text())
    if data is Dictionary:
        trail_rank = clampi(int(data.get("v09_trail_rank",0)),0,TRAIL.size())
    return true
