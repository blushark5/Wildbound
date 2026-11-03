extends "res://scripts/incremental/ui_v07.gd"
## Wildbound v0.8 — a functional, combat-first readability pass.
## This layer leaves every economy, save and progression rule in its existing engine.

const BATTLE_FX_V08 = preload("res://scripts/incremental/combat_fx_v08.gd")
const TRACK_EMPTY := Color("#304651")
const TRACK_READY := Color("#80c9aa")
const TRACK_GUARDIAN := Color("#ffc37d")

var journey_ticks: Array[ColorRect] = []
var tactic_readout: Label
var threat_readout: Label

func _layout() -> void:
    super._layout()
    _install_stage_effects()
    _reflow_sanctuary()
    _create_battle_readouts()
    _polish_readability()

func _install_stage_effects() -> void:
    # v0.6 particles occupied only the upper-left portion of the larger
    # v0.7 stage. Replace the decorative effect, never the battle engine.
    var previous: Control = art_fx
    var fx: Control = BATTLE_FX_V08.new()
    fx.name = "BattleFieldEffectsV08"
    fx.position = Vector2(288,168)
    fx.size = Vector2(704,332)
    fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(fx)
    move_child(fx,previous.get_index())
    previous.queue_free()
    art_fx = fx

func _reflow_sanctuary() -> void:
    # Three legible columns instead of seven squeezed into tiny buttons.
    for i in range(TABS.size()):
        var key: String = TABS[i]
        var button: Button = tab_buttons[key]
        button.position = Vector2(1031.0+float(i%3)*75.0,136.0+float(i/3)*31.0)
        button.size = Vector2(72,28)
        button.add_theme_font_size_override("font_size",10)
        button.tooltip_text = "Open "+key.to_lower().capitalize()+" progression"
    tab_scroll.position = Vector2(1032,234)
    tab_scroll.size = Vector2(225,397)
    _move("WaveTitle",Vector2(286,129),Vector2(565,30))
    _move("FuryCountdown",Vector2(856,134),Vector2(130,23))

func _create_battle_readouts() -> void:
    # Ten individually updated markers show distance to each Guardian.
    # They are standard UI rectangles, not painted into the background.
    for i in range(10):
        var segment := ColorRect.new()
        segment.name = "GuardianStep_%02d" % (i+1)
        segment.position = Vector2(289+float(i)*70,158)
        segment.size = Vector2(67,4)
        segment.color = TRACK_EMPTY
        segment.mouse_filter = Control.MOUSE_FILTER_IGNORE
        add_child(segment)
        journey_ticks.append(segment)
    tactic_readout = _label(self,"TacticalReadout","",Rect2(307,474,374,22),12,Color("#e5f5da"))
    tactic_readout.add_theme_color_override("font_shadow_color",Color("#071b22"))
    tactic_readout.add_theme_constant_override("shadow_offset_x",1)
    tactic_readout.add_theme_constant_override("shadow_offset_y",1)
    threat_readout = _label(self,"ThreatReadout","",Rect2(707,474,275,22),12,Color("#f8d8b1"))
    threat_readout.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    threat_readout.add_theme_color_override("font_shadow_color",Color("#071b22"))
    threat_readout.add_theme_constant_override("shadow_offset_x",1)
    threat_readout.add_theme_constant_override("shadow_offset_y",1)

func _polish_readability() -> void:
    labels["Sublogo"].text = "CREATURE ASCENSION  •  BATTLE EXPERIENCE v0.8"
    labels["Sublogo"].add_theme_font_size_override("font_size",10)
    labels["WaveTitle"].add_theme_color_override("font_color",LIGHT)
    fury_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    fury_label.add_theme_font_size_override("font_size",12)
    fury_label.add_theme_color_override("font_shadow_color",Color("#081821"))
    fury_label.add_theme_constant_override("shadow_offset_x",1)
    fury_label.add_theme_constant_override("shadow_offset_y",1)
    labels["EnemyName"].horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    labels["EnemyName"].add_theme_color_override("font_color",Color("#ffefd1"))
    labels["DpsText"].add_theme_font_size_override("font_size",14)
    labels["DpsText"].add_theme_color_override("font_color",Color("#f3cf90"))
    _move("DamageText",Vector2(737,445),Vector2(237,24))
    _move("ComboCounter",Vector2(532,447),Vector2(178,23))
    for creature in ENGINE.ORDER:
        var card: Panel = get_node("PackCard_"+String(creature)) as Panel
        card.add_theme_stylebox_override("panel",_style(Color("#163345"),SHADES[creature].darkened(0.22),8))
        ally_skills[creature].tooltip_text = "Use with keys 1, 2, 3 in pack order. Abilities require an owned creature and a finished cooldown."
    buttons["Tap"].tooltip_text = "Space: Strike | 1/2/3: Pack abilities | R: Resonance | Q: Next tab | B: Buy batch | F: Repeat | P: Pause | S: Save"
    buttons["Tap"].add_theme_stylebox_override("pressed",_style(Color("#71372a"),Color("#ffe0a6"),9))
    buttons["Save"].tooltip_text = "Saves your progress locally in this browser. Browser saves do not transfer between devices."
    buttons["Speed"].tooltip_text = "Switch expedition speed between 1x and 2x."
    buttons["Repeat"].tooltip_text = "Farm this wave rather than advancing to new regions and Guardians."
    buttons["Batch"].tooltip_text = "Cycle purchases between 1, 10 and 25 levels."
    buttons["AutoBuy"].tooltip_text = "Unlock the Automation research in Legacy to purchase upgrades automatically."
    buttons["AutoSkills"].tooltip_text = "Unlock Instinct research in Legacy to use creature abilities automatically."

func _refresh() -> void:
    super._refresh()
    if game == null or journey_ticks.size() != 10:
        return
    var guardian: bool = game.enemy_is_boss()
    var step: int = (maxi(game.wave,1)-1)%10
    for i in range(journey_ticks.size()):
        var indicator: ColorRect = journey_ticks[i]
        indicator.color = TRACK_GUARDIAN if guardian else (TRACK_READY if i <= step else TRACK_EMPTY)
        if i == 9 and not guardian:
            indicator.color = Color("#6b5948")
    var active: int = _active_creatures()
    tactic_readout.text = "PACK %d / 3   •   STREAK %d   •   %s" % [
        active,game.current_streak,"FARMING" if game.repeat_wave else "ADVANCING"]
    var kind: String = String(ENGINE.SPECIES[game.enemy_species]["element"])
    var mutator: String = game.enemy_mutator()
    threat_readout.text = ("GUARDIAN  •  " if guardian else "")+kind.to_upper()+(
        "  •  "+mutator.to_upper() if mutator != "" else "")
    fury_label.text = ("FURY ACTIVE" if game.guardian_enraged else
        "FURY IN %ds" % maxi(0,18-ceili(game.guardian_seconds))) if guardian else (
        "GUARDIAN IN %d" % (10-step))
    fury_label.add_theme_color_override("font_color",TRACK_GUARDIAN if guardian else PALE)
    enemy_fill.color = Color("#ffac6d") if guardian else (
        Color("#f48c8b") if game.enemy_hp/maxf(game.enemy_max_hp,1.0) < 0.25 else Color("#e5a185"))
    ward_fill.color = Color("#e9a47d") if game.ward/maxf(game.max_ward(),1.0) < 0.25 else Color("#8addb5")
    resonance_fill.color = Color("#ebc0ff") if game.overdrive >= 99.99 else Color("#af8ce7")
    labels["Notice"].tooltip_text = game.last_notice
    for key in TABS:
        var button: Button = tab_buttons[key]
        button.add_theme_stylebox_override("normal",_style(
            Color("#4c615b") if tab == key else Color("#203d50"),
            Color("#f8d28b") if tab == key else Color("#506d7c"),5))
    buttons["Tap"].text = "STRIKE  •  GUARDIAN" if guardian else "STRIKE  •  CLICK / SPACE"

func _unhandled_key_input(event: InputEvent) -> void:
    super._unhandled_key_input(event)
    if not (event is InputEventKey):
        return
    var key: InputEventKey = event as InputEventKey
    if not key.pressed or key.echo or key.alt_pressed or key.ctrl_pressed or key.meta_pressed:
        return
    if get_viewport().is_input_handled():
        return
    if options_dialog.visible or help_dialog.visible or ascend_dialog.visible:
        return
    if _handle_shortcut(key.keycode):
        get_viewport().set_input_as_handled()

func _handle_shortcut(keycode: Key) -> bool:
    # Single source of truth for shortcut QA; all actions call live game methods.
    match keycode:
        KEY_1:
            _ability("spriglet")
        KEY_2:
            _ability("brinlet")
        KEY_3:
            _ability("cindlet")
        KEY_R:
            _activate_resonance()
        KEY_Q:
            _switch_tab(TABS[(TABS.find(tab)+1)%TABS.size()])
        KEY_B:
            _toggle_batch()
        KEY_F:
            _toggle_repeat()
        KEY_P:
            _toggle_running()
        KEY_S:
            _save()
        _:
            return false
    return true
