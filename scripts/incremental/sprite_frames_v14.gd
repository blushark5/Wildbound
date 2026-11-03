extends RefCounted
## Original illustrated 192px poses for all newly discovered Wildbound species.
## Preserve approved v0.7 starter bestiary images for the original three.
const CORE = preload("res://scripts/incremental/collection_art_v12.gd")
const STARTERS: Dictionary = {
    "spriglet": {
        "idle":preload("res://assets/incremental/v15/spriglet_idle.svg"),
        "attack":preload("res://assets/incremental/v15/spriglet_attack.svg"),
        "evolved_idle":preload("res://assets/incremental/v15/spriglet_evolved_idle.svg"),
        "evolved_attack":preload("res://assets/incremental/v15/spriglet_evolved_attack.svg")
    },
    "brinlet": {
        "idle":preload("res://assets/incremental/v15/brinlet_idle.svg"),
        "attack":preload("res://assets/incremental/v15/brinlet_attack.svg"),
        "evolved_idle":preload("res://assets/incremental/v15/brinlet_evolved_idle.svg"),
        "evolved_attack":preload("res://assets/incremental/v15/brinlet_evolved_attack.svg")
    },
    "cindlet": {
        "idle":preload("res://assets/incremental/v15/cindlet_idle.svg"),
        "attack":preload("res://assets/incremental/v15/cindlet_attack.svg"),
        "evolved_idle":preload("res://assets/incremental/v15/cindlet_evolved_idle.svg"),
        "evolved_attack":preload("res://assets/incremental/v15/cindlet_evolved_attack.svg")
    }
}
const POSES: Dictionary = {
    "pebblit": {
        "idle":preload("res://assets/incremental/v14/pebblit_idle.svg"),
        "attack":preload("res://assets/incremental/v14/pebblit_attack.svg"),
        "evolved_idle":preload("res://assets/incremental/v14/pebblit_evolved_idle.svg"),
        "evolved_attack":preload("res://assets/incremental/v14/pebblit_evolved_attack.svg")
    },
    "mossling": {
        "idle":preload("res://assets/incremental/v14/mossling_idle.svg"),
        "attack":preload("res://assets/incremental/v14/mossling_attack.svg"),
        "evolved_idle":preload("res://assets/incremental/v14/mossling_evolved_idle.svg"),
        "evolved_attack":preload("res://assets/incremental/v14/mossling_evolved_attack.svg")
    },
    "driplet": {
        "idle":preload("res://assets/incremental/v14/driplet_idle.svg"),
        "attack":preload("res://assets/incremental/v14/driplet_attack.svg"),
        "evolved_idle":preload("res://assets/incremental/v14/driplet_evolved_idle.svg"),
        "evolved_attack":preload("res://assets/incremental/v14/driplet_evolved_attack.svg")
    },
    "tidefin": {
        "idle":preload("res://assets/incremental/v14/tidefin_idle.svg"),
        "attack":preload("res://assets/incremental/v14/tidefin_attack.svg"),
        "evolved_idle":preload("res://assets/incremental/v14/tidefin_evolved_idle.svg"),
        "evolved_attack":preload("res://assets/incremental/v14/tidefin_evolved_attack.svg")
    },
    "ashcub": {
        "idle":preload("res://assets/incremental/v14/ashcub_idle.svg"),
        "attack":preload("res://assets/incremental/v14/ashcub_attack.svg"),
        "evolved_idle":preload("res://assets/incremental/v14/ashcub_evolved_idle.svg"),
        "evolved_attack":preload("res://assets/incremental/v14/ashcub_evolved_attack.svg")
    },
    "emberlyn": {
        "idle":preload("res://assets/incremental/v14/emberlyn_idle.svg"),
        "attack":preload("res://assets/incremental/v14/emberlyn_attack.svg"),
        "evolved_idle":preload("res://assets/incremental/v14/emberlyn_evolved_idle.svg"),
        "evolved_attack":preload("res://assets/incremental/v14/emberlyn_evolved_attack.svg")
    },
    "zephlet": {
        "idle":preload("res://assets/incremental/v14/zephlet_idle.svg"),
        "attack":preload("res://assets/incremental/v14/zephlet_attack.svg"),
        "evolved_idle":preload("res://assets/incremental/v14/zephlet_evolved_idle.svg"),
        "evolved_attack":preload("res://assets/incremental/v14/zephlet_evolved_attack.svg")
    },
    "gustling": {
        "idle":preload("res://assets/incremental/v14/gustling_idle.svg"),
        "attack":preload("res://assets/incremental/v14/gustling_attack.svg"),
        "evolved_idle":preload("res://assets/incremental/v14/gustling_evolved_idle.svg"),
        "evolved_attack":preload("res://assets/incremental/v14/gustling_evolved_attack.svg")
    },
    "skyray": {
        "idle":preload("res://assets/incremental/v14/skyray_idle.svg"),
        "attack":preload("res://assets/incremental/v14/skyray_attack.svg"),
        "evolved_idle":preload("res://assets/incremental/v14/skyray_evolved_idle.svg"),
        "evolved_attack":preload("res://assets/incremental/v14/skyray_evolved_attack.svg")
    }
}
static func creature(kind: String,evolved: bool = false,attacking: bool = false) -> Texture2D:
    if STARTERS.has(kind):
        var starter_pose: String = ("evolved_" if evolved else "") + ("attack" if attacking else "idle")
        return STARTERS[kind][starter_pose] as Texture2D
    if POSES.has(kind):
        var key: String = ("evolved_" if evolved else "") + ("attack" if attacking else "idle")
        return POSES[kind][key] as Texture2D
    return CORE.get_creature(kind,evolved)
