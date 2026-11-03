extends SceneTree
## v0.21: readable intro, integer DPS presentation and exact permanent/Gold
## module explanations. Nothing modifies original enemy or economy curves.
const SCENE = preload("res://scenes/incremental/wildbound_bond_v21.tscn")
const SLOTS = preload("res://scripts/incremental/save_slots_v19.gd")
const GAME = preload("res://scripts/incremental/bond_engine_v20.gd")
const KINDS: Array[String] = ["power","tempo","guard","crit","bounty","recovery","pierce"]

func _initialize() -> void:
    call_deferred("_check")

func _fail(message: String) -> void:
    push_error("v0.21: "+message)
    SLOTS.erase_all(GAME.SAVE_FILE)
    quit(1)

func _close(actual: float, expected: float, eps: float=0.001) -> bool:
    return absf(actual-expected) < eps

func _check() -> void:
    SLOTS.erase_all(GAME.SAVE_FILE)
    var ui: Control = SCENE.instantiate() as Control
    root.add_child(ui)
    await process_frame
    if not is_instance_valid(ui.wrapped_guide) or not ui.wrapped_guide.scroll_active:
        _fail("Guide lacks scrollable wrapped long-form text");return
    ui._show_first_steps()
    if not ui.guide_dialog.visible:
        _fail("Guide failed to open");return
    if ui.guide_dialog.dialog_text != "":
        _fail("Legacy non-wrapping guide label still contains paragraphs");return
    if ui.wrapped_guide.size.x > 610.0 or ui.guide_dialog.size.x > 700.0:
        _fail("Guide extends past available phone-landscape width");return
    if ui.wrapped_guide.autowrap_mode != TextServer.AUTOWRAP_WORD_SMART:
        _fail("Guide word wrap was not activated");return
    if not ui.wrapped_guide.text.contains("START FIRST BATTLE") or not ui.wrapped_guide.text.contains("CHOOSE FARM STAGE"):
        _fail("Guide fails to explain actual v0.20 battle and farming controls");return
    ui.guide_dialog.hide()
    ui.game.gold = 1.0e8
    ui._switch_tab("GROW")
    ui._refresh()
    for kind in KINDS:
        var found: bool = false
        for row in ui.active_rows:
            if String(row["mode"]) != "module" or String(row["key"]) != kind:
                continue
            found = true
            var info: Label = row["info"]
            var button: Button = row["button"]
            if info.text.count("\n") < 1 or not info.text.contains("Rank 0") or not info.text.contains("→"):
                _fail("Gold module missing current-vs-next explanation: "+kind);return
            if button.tooltip_text.length() < 70 or button.disabled:
                _fail("Missing useful detail or upgrade action: "+kind);return
        if not found:
            _fail("Gold module absent from GROW: "+kind);return

    var base_damage: float = ui.game.combat_damage(String(ui.game.squad_slots[0]))
    if not ui.game.buy_module("power") or not _close(ui.game.combat_damage(String(ui.game.squad_slots[0]))/base_damage,1.13):
        _fail("Power module math mismatch");return
    ui._refresh()
    if not ui.upgrade_breakdown("power")["line2"].contains("+13.0%"):
        _fail("Power cumulative upgrade effect incorrect");return

    var creature: String = String(ui.game.squad_slots[0])
    var old_interval: float = ui.game.combat_interval(creature)
    if not ui.game.buy_module("tempo") or not _close(ui.game.combat_interval(creature)/old_interval,0.94):
        _fail("Tempo module math mismatch");return
    var old_hp: float = ui.game.max_ward()
    if not ui.game.buy_module("guard") or not _close(ui.game.max_ward()-old_hp,22.0):
        _fail("Ward +22 effect mismatch");return
    if not ui.game.buy_module("crit") or not ui.upgrade_breakdown("crit")["line2"].contains("8.5%"):
        _fail("Crit must show exactly +3.5 percentage points (from 5.0 to 8.5%)");return
    var pre_gold: float = ui.game.wave_reward()
    if not ui.game.buy_module("bounty") or not _close(ui.game.wave_reward()/pre_gold,1.15):
        _fail("Gold bounty multiplier mismatch");return
    if not ui.upgrade_breakdown("bounty")["line2"].contains("+15.0%"):
        _fail("Gold current cumulative return isn't displayed");return
    if not ui.game.buy_module("recovery") or not ui.upgrade_breakdown("recovery")["line2"].contains("1.7%/s"):
        _fail("Regen %/second breakdown is inaccurate");return
    if not ui.game.buy_module("pierce") or not ui.upgrade_breakdown("pierce")["line2"].contains("+20%"):
        _fail("Guardian damage needs its cumulative bonus");return

    # The live UI earlier interpolated a bare float using %s. Verify it
    # uses rounded whole numbers even for arbitrary fractional DPS values.
    ui._refresh()
    var expected: String = ui._whole_dps(ui.game.squad_dps())
    var display: String = ui.screen_labels["DamageReadout"].text
    if not display.contains("TEAM DPS "+expected) or display.contains("."):
        _fail("Actual battle DPS text is not displayed as an integer: "+display);return
    if ui._whole_dps(1234.567) != "1235" or ui._whole_dps(18.315) != "18":
        _fail("DPS round-to-whole helper inaccurate");return
    ui.game.save()
    var reloaded = GAME.new()
    reloaded.initialize_alpha()
    if not reloaded.load_save() or int(reloaded.modules["crit"]) != 1 or int(reloaded.modules["bounty"]) != 1:
        _fail("The extra display metadata disrupted save persistence");return
    SLOTS.erase_all(GAME.SAVE_FILE)
    print("PASS v0.21: phone-width word-wrapped guide, integer-only combat DPS, exact cumulative +next-rank Gold/crit/regen/guardian/attack/Ward stats, save compatibility")
    quit(0)
