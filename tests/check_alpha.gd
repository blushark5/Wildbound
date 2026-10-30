extends SceneTree
const ALPHA = preload("res://scripts/incremental/alpha_engine.gd")
func _initialize() -> void:
    call_deferred("_test")
func _die(reason: String) -> void:
    push_error("WILDBOUND ALPHA VALIDATION: " + reason)
    quit(1)
func _test() -> void:
    var g = ALPHA.new()
    g.initialize_alpha()
    if g.wave != 1 or g.gold != 0.0 or g.total_dps() < 1.0:
        _die("Base game progression not initialized")
        return
    if g.region_available("sky") or not g.region_available("meadow"):
        _die("Region unlock gate invalid")
        return
    if g.nests != 0 or g.hatch_egg() != "":
        _die("Hatching incorrectly works without shards")
        return
    var old_enemy_health: float = g.enemy_max_hp
    g.toggle_overclock()
    if g.enemy_max_hp < old_enemy_health*1.9:
        _die("Overclock difficulty failed to scale enemy health")
        return
    g.toggle_overclock()
    var before: float = g.enemy_max_hp
    g.attack(g.enemy_hp+10)
    if g.wave != 2 or g.enemy_max_hp < before:
        _die("Enemies not advancing correctly")
        return
    if g.effective_damage("spriglet") <= 0:
        _die("Elemental combat broken")
        return
    if not g.use_ability("spriglet") or g.use_ability("spriglet"):
        _die("Ability and cooldown not enforced")
        return
    g.nests = 50
    var count: int = 0
    for i in range(10):
        if g.hatch_egg() == "":
            _die("Earned egg hatch failed")
            return
        count += 1
    if g.eggs_hatched != count or g.rare_pity > 9:
        _die("Rare hatch pity counter exceeded its guarantee")
        return
    g.rare_pity = 9
    g.nests += g.hatch_cost()
    var guaranteed: String = g.hatch_egg()
    if not bool(g.rare[guaranteed]) or g.rare_pity != 0:
        _die("Tenth egg did not guarantee Shimmer rarity")
        return
    g.gold = 1.0e12
    if not g.buy_levels("spriglet",15):
        _die("Creature leveling broke")
        return
    g.bonds["spriglet"] = 25
    g._check_evolution("spriglet")
    if not g.evolved["spriglet"]:
        _die("Persistent creature evolution broken")
        return
    if not g.buy_module("crit") or not g.buy_module("recovery"):
        _die("New field modules did not purchase")
        return
    g.best_wave = 120
    if not g.region_available("sky") or not g.select_region("sky"):
        _die("Late-game region not unlockable")
        return
    g.wave = 20
    g.run_peak = 20
    g._spawn_enemy()
    g._fit_enemy_to_region()
    if g.available_echoes() <= 0 or not g.ascend():
        _die("Ascension broken")
        return
    if g.wave != 1 or g.gold != 0.0 or not g.evolved["spriglet"] or g.modules["crit"] != 0:
        _die("Prestige fails to preserve lineage while resetting temporary field mods")
        return
    if not g.claim_milestone("wave10") or g.claim_milestone("wave10"):
        _die("Milestone claims must be earned and one-time")
        return
    g.echoes = 40
    if not g.buy_research("automation") or not g.buy_research("instinct"):
        _die("Unlockable automation unavailable")
        return
    g.auto_buy = true
    g.auto_skills = true
    var before_autobuy: int = int(g.levels["spriglet"])
    g.gold = 100000.0
    for i in range(6):
        g.tick(0.20)
    if int(g.levels["spriglet"]) <= before_autobuy and int(g.modules["power"]) == 0:
        _die("Auto-buy did not spend Gold once its research was unlocked")
        return
    g.gene["spriglet"] = 5
    g.rare["spriglet"] = true
    g.game_speed = 2.0
    g.gold = 9876.0
    var persisted: Dictionary = g.to_dict()
    if int(persisted.get("alpha_save_version",0)) != 2:
        _die("Extended save version missing")
        return
    if not g.save():
        _die("Save failed")
        return
    var restored = ALPHA.new()
    restored.initialize_alpha()
    if not restored.load_save():
        _die("v1-compatible save could not be reloaded")
        return
    if restored.gene["spriglet"] != 5 or not restored.rare["spriglet"] or \
        not restored.evolved["spriglet"] or restored.research["automation"] < 1 or \
        restored.region != "sky" or not restored.auto_buy or restored.game_speed != 2.0:
        _die("Permanent alpha progression lost during save/load")
        return
    # Legacy v0.1 records deliberately omit new alpha fields.
    var old_format: Dictionary = persisted.duplicate(true)
    for key in ["alpha_save_version","nests","eggs_hatched","gene","rare","rare_pity",
        "milestones_claimed","region","overclock","auto_buy","auto_skills",
        "lifetime_gold","lifetime_echoes","greatest_streak","last_boss_wave",
        "total_seconds","game_speed"]:
        old_format.erase(key)
    var old_file: FileAccess = FileAccess.open(ALPHA.SAVE_FILE,FileAccess.WRITE)
    old_format["saved_at"] = Time.get_unix_time_from_system() - 3600
    old_file.store_string(JSON.stringify(old_format))
    old_file.close()
    var migrated = ALPHA.new()
    migrated.initialize_alpha()
    if not migrated.load_save() or not migrated.evolved["spriglet"] or \
        migrated.gene["spriglet"] != 0 or migrated.region != "meadow":
        _die("Legacy v0.1 save migration failed")
        return
    if migrated.offline_gold <= 0.0 or migrated.offline_gold > 1.0e18 or migrated.wave != 1:
        _die("Offline Gold must not advance waves or award unlimited currency")
        return
    DirAccess.remove_absolute(ProjectSettings.globalize_path(ALPHA.SAVE_FILE))
    var ui: PackedScene = load("res://scenes/incremental/wildbound_alpha.tscn") as PackedScene
    if ui == null:
        _die("Alpha scene cannot load")
        return
    var instance: Control = ui.instantiate() as Control
    root.add_child(instance)
    if instance.get_node_or_null("Tap") == null or \
        instance.get_node_or_null("tab_NEST") == null or \
        instance.get_node_or_null("AutoBuy") == null:
        _die("Critical game buttons missing")
        return
    var previous_enemy_hp: float = float(instance.game.enemy_hp)
    instance.get_node("Tap").emit_signal("pressed")
    if instance.game.enemy_hp >= previous_enemy_hp and instance.game.wave == 1:
        _die("Visible attack button does not affect live gameplay")
        return
    instance.call("_switch_tab","LEGACY")
    var has_ascend: bool = false
    for row in instance.right_rows:
        if row.get("mode","") == "ascend":
            has_ascend = true
    if not has_ascend or instance.get_node_or_null("Guide") == null or instance.get_node_or_null("Sound") == null:
        _die("Ascension, guide or sound controls missing")
        return
    instance.call("_switch_tab","MAP")
    instance.call("_switch_tab","GOALS")
    instance.call("_switch_tab","NEST")
    instance.call("_switch_tab","FORGE")
    print("PASS: wave combat, abilities, eggs/pity, evolution, modules, regions, overclock, ascension, milestones, research, auto unlocks, v0.1 migration, alpha UI tabs")
    quit(0)
