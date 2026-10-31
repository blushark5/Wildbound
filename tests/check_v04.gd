extends SceneTree
const ENGINE = preload("res://scripts/incremental/v04_engine.gd")
func _initialize() -> void:
    call_deferred("_test")
func fail(reason: String) -> void:
    push_error("WILDBOUND V0.4 TEST: "+reason)
    quit(1)
func _test() -> void:
    var g = ENGINE.new()
    g.initialize_alpha()
    if g.specialization["spriglet"] != "" or g.caches_pending != 0 or g.combo_hits != 0:
        fail("Fresh v0.4 state invalid")
        return
    if g.specialize("spriglet","briar") or g.claim_cache("gold"):
        fail("Mastery/caches available before earning them")
        return
    # First specialization is free and requires both evolution and bonds.
    g.evolved["spriglet"] = true
    g.bonds["spriglet"] = 25
    var plain_damage: float = g.species_damage("spriglet")
    if not g.specialize("spriglet","briar") or g.species_damage("spriglet") <= plain_damage*1.35:
        fail("Briarheart specialization fails to strengthen damage")
        return
    if not g.spec_name("spriglet") == "Briarheart":
        fail("Selected creature mastery not displayed correctly")
        return
    if g.specialize("spriglet","bloom"):
        fail("Mastery changes should require 12 Nest Shards")
        return
    g.nests = 15
    if not g.specialize("spriglet","bloom") or g.nests != 3 or g.max_ward() < 129.0:
        fail("Paid mastery switch or Lifebloom Ward effect failed")
        return
    if g.specialize("spriglet","bloom"):
        fail("No-op mastery change should be rejected")
        return
    g.gold = 3000.0
    g.evolved["brinlet"] = true
    g.evolved["cindlet"] = true
    g.bonds["brinlet"] = 25
    g.bonds["cindlet"] = 25
    g.levels["brinlet"] = 1
    g.levels["cindlet"] = 1
    if not g.specialize("brinlet","harbor") or not g.specialize("cindlet","swift"):
        fail("Different creature mastery choices unavailable")
        return
    var interval: float = g.attack_interval("cindlet")
    g.specialization["cindlet"] = ""
    if g.attack_interval("cindlet") <= interval:
        fail("Swiftflame does not increase attack rate")
        return
    g.specialization["cindlet"] = "swift"
    # Timed manual combos are accessible, capped and reset by inactivity.
    g.tap()
    g.tap()
    g.tap()
    if g.combo_hits != 3 or g.highest_combo < 3:
        fail("Consecutive manual taps did not increase combo")
        return
    g.tick(0.25)
    for i in range(7):
        g.tick(0.25)
    if g.combo_hits != 0:
        fail("Manual combo did not reset after inactivity")
        return
    # Damage/risk clock for bosses. The timer is not preserved across kills.
    g.wave = 20
    g._spawn_enemy()
    g._fit_enemy_to_region()
    var base_guardian_damage: float = g.enemy_damage()
    for i in range(80):
        g.tick(0.25)
        g.ward = g.max_ward()
    if not g.guardian_enraged or g.enemy_damage() <= base_guardian_damage*1.45:
        fail("Guardian fury is not active after 18 seconds")
        return
    g.attack(g.enemy_hp+1.0e10)
    if g.guardian_enraged or g.guardian_seconds != 0.0:
        fail("Guardian fury should reset after battle")
        return
    # Clear wave 25 and choose one of three earned reward paths.
    g.wave = 25
    g.repeat_wave = false
    g._spawn_enemy()
    g._fit_enemy_to_region()
    g.attack(g.enemy_hp+1.0e10)
    if g.caches_pending != 1 or not g.cache_wave_awarded.has(str(g.ascensions)+":25"):
        fail("Milestone cache not earned on wave 25")
        return
    g.wave = 25
    g._spawn_enemy()
    g.repeat_wave = true
    g.attack(g.enemy_hp+1.0e10)
    if g.caches_pending != 1:
        fail("Repeat farming duplicated a milestone cache")
        return
    if not g.claim_cache("surge") or g.cache_surges != 1 or g.caches_claimed != 1:
        fail("Battle cache not granted correctly")
        return
    if g.claim_cache("surge") or g.claim_cache("unknown"):
        fail("Cannot claim nonexistent/empty caches")
        return
    g.caches_pending = 2
    var earlier_shards: int = g.nests
    if not g.claim_cache("shards") or g.nests <= earlier_shards:
        fail("Nest cache not granted")
        return
    var earlier_gold: float = g.gold
    if not g.claim_cache("gold") or g.gold <= earlier_gold:
        fail("Gold cache not granted")
        return
    # Reaching another wave 25 after Ascension may earn another cache.
    g.caches_pending = 1
    g.wave = 30
    g.run_peak = 30
    g.best_wave = maxi(g.best_wave,31)
    if not g.ascend() or g.cache_surges != 0 or g.caches_pending != 1:
        fail("Ascension should clear temporary buffs but preserve unclaimed rewards")
        return
    if g.specialization["spriglet"] != "bloom":
        fail("Ascension lost permanent creature mastery")
        return
    if not g.save():
        fail("Cannot save game")
        return
    var loaded = ENGINE.new()
    loaded.initialize_alpha()
    if not loaded.load_save() or loaded.specialization["spriglet"] != "bloom" or loaded.caches_pending != 1:
        fail("v0.4 state failed to persist")
        return
    var snapshot: Dictionary = loaded.to_dict()
    if int(snapshot.get("v04",0)) != 4:
        fail("Missing v0.4 schema marker")
        return
    # Simulate an existing v0.3 save with no new v0.4 keys.
    var previous: Dictionary = snapshot.duplicate(true)
    for key in ["v04","specialization","caches_pending","caches_claimed","cache_surges",
                "cache_wave_awarded","highest_combo","raw_damage_done",
                "onboarding_seen","ui_compact"]:
        previous.erase(key)
    previous["saved_at"] = Time.get_unix_time_from_system()
    var file: FileAccess = FileAccess.open(ENGINE.SAVE_FILE,FileAccess.WRITE)
    file.store_string(JSON.stringify(previous))
    file.close()
    var migrated = ENGINE.new()
    migrated.initialize_alpha()
    if not migrated.load_save() or migrated.specialization["spriglet"] != "" or \
        migrated.caches_pending != 0 or migrated.best_wave != loaded.best_wave:
        fail("Legacy v0.3 migration altered existing progression")
        return
    DirAccess.remove_absolute(ProjectSettings.globalize_path(ENGINE.SAVE_FILE))
    var packed: PackedScene = load("res://scenes/incremental/wildbound_alpha.tscn") as PackedScene
    if packed == null:
        fail("Main game scene failed to import")
        return
    var screen: Control = packed.instantiate() as Control
    root.add_child(screen)
    if screen.get_node_or_null("Options") == null or screen.get_node_or_null("ComboCounter") == null or \
        screen.get_node_or_null("FuryCountdown") == null or not screen.TABS.has("PACK"):
        fail("Critical v0.4 controls not in game")
        return
    screen.call("_switch_tab","PACK")
    var mastery_count: int = 0
    for row in screen.right_rows:
        if row.get("mode","") == "mastery":
            mastery_count += 1
    if mastery_count != 6:
        fail("Six unique mastery choices not available in PACK tab")
        return
    screen.call("_switch_tab","GOALS")
    var cache_count: int = 0
    for row in screen.right_rows:
        if row.get("mode","") == "cache":
            cache_count += 1
    if cache_count != 3:
        fail("Three cache reward choices missing in GOALS tab")
        return
    screen.get_node("Options").emit_signal("pressed")
    if screen.options_dialog == null:
        fail("Accessibility dialog missing")
        return
    DirAccess.remove_absolute(ProjectSettings.globalize_path(ENGINE.SAVE_FILE))
    print("PASS v0.4: specialization, switching, abilities, combo, Guardian fury, caches, Ascension, save migration and UI")
    quit(0)
