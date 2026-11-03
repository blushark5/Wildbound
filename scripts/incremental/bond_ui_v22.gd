extends "res://scripts/incremental/bond_ui_v21.gd"
## Wildbound v0.22: repeat-Ascension smart Auto-Form, exact bulk Gold
## buying, elemental matchup readout, and meaningful Ascension previews.
const ENGINE_22 = preload("res://scripts/incremental/bond_engine_v22.gd")

var qol22_ready: bool = false
var autoform_button: Button
var matchup_button: Button
var matchup_label: Label
var matchup_dialog: AcceptDialog
var ascent_results: AcceptDialog
var bulk_amount: int = 1
var bulk_mode_buttons: Dictionary = {}
var ascent_report_playing: bool = false

func _ready() -> void:
    super._ready()
    game = ENGINE_22.new()
    game.initialize_alpha()
    game.load_save()
    game.notice.connect(_on_notice)
    last_kills = game.kills
    last_guardian = game.last_boss_wave
    playing = game.battle_started
    _install_ascent_ui()
    _install_matchup_ui()
    _install_autoform_ui()
    qol22_ready = true
    _switch_tab("GROW")
    _refresh()

func _install_autoform_ui() -> void:
    autoform_button = _button("AutoFormSquad","AUTO-FORM • LOCKED",
        Rect2(673,417,158,29),_toggle_autoform,Color("#98e1b7"))
    _skin_button(autoform_button,PALETTE["sage"],true)
    autoform_button.add_theme_font_size_override("font_size",11)
    autoform_button.tooltip_text = "Auto-Form becomes available after your first Ascension."

func _toggle_autoform() -> void:
    if game == null:
        return
    if game.toggle_auto_form():
        game.save()
        _toast("AUTO-FORM %s • Applies at your NEXT stage. Manual changes are kept." %
            ("ON" if game.auto_form_enabled else "OFF"))
        _refresh()

func _install_matchup_ui() -> void:
    matchup_label = _label("CounterSummary","",
        Rect2(39,183,440,24),12,PALETTE["sage"])
    matchup_button = _button("MatchupDetails","MATCHUPS",
        Rect2(445,104,100,30),_show_matchups,Color("#98e1b7"))
    _skin_button(matchup_button,PALETTE["sage"],true)
    matchup_button.add_theme_font_size_override("font_size",11)
    matchup_button.tooltip_text = "See your entire squad's real elemental advantages versus all three opponents."
    matchup_dialog = AcceptDialog.new()
    matchup_dialog.title = "Your Elemental Matchups"
    matchup_dialog.ok_button_text = "CLOSE"
    add_child(matchup_dialog)

func _show_matchups() -> void:
    var lines: Array[String] = []
    lines.append("STAGE %d  •  ELEMENT ADVANTAGES" % game.wave)
    lines.append("Earth > Water > Fire > Air > Earth")
    lines.append("")
    var foes: Array = game.roster_for(game.wave)
    for kind in game.squad_slots:
        if kind == "" or not game.has_instance(kind):
            continue
        var element: String = String(ENGINE_22.CATALOG[kind]["element"])
        var names: Array[String] = []
        for enemy in foes:
            var target: String = String(enemy)
            var factor: float = game.multiplier(kind,target)
            var relation: String = "STRONG" if factor >= 1.95 else ("WEAK" if factor <= 0.50 else "EVEN")
            names.append("%s: %s" % [game.display_name(target),relation])
        lines.append("%s [%s]" % [game.combat_name(kind),element])
        lines.append("  "+", ".join(names))
        lines.append("")
    lines.append("STRONG = 2x damage. WEAK = 0.45x.")
    lines.append("Manual squad swaps always override Auto-Form.")
    matchup_dialog.dialog_text = "\n".join(lines)
    matchup_dialog.popup_centered(Vector2i(640,370))

func _install_ascent_ui() -> void:
    ascent_results = AcceptDialog.new()
    ascent_results.title = "Ascension Complete • Permanent Progress"
    ascent_results.ok_button_text = "RETURN TO THE WILDS"
    ascent_results.confirmed.connect(_close_ascent_results)
    ascent_results.canceled.connect(_close_ascent_results)
    add_child(ascent_results)

func _prepared_bond_names() -> Array[String]:
    var names: Array[String] = []
    for key in game.owned_creatures:
        var kind: String = String(key)
        if (game.unit_bond_rank(kind) < game.MAX_BOND_RANK and
            game.unit_bond(kind) >= game.next_bond_goal(kind)):
            names.append(game.combat_name(kind))
    names.sort()
    return names

func _request_ascension() -> void:
    if game == null or game.available_echoes() < 1:
        return
    var names: Array[String] = _prepared_bond_names()
    var list_text: String = ", ".join(names) if not names.is_empty() else "None ready yet. Earn Bond XP first."
    var permanent_stage: int = maxi(game.lifetime_cleared_stage,game.best_wave-1)
    ascend_dialog.title = "Ascend Now? Review Your Permanent Gains"
    ascend_dialog.dialog_text = (
        "+%d ECHOES  •  Ascension #%d\n\n" % [game.available_echoes(),game.ascensions+1]
        +"BONDED RANKS +1: "+list_text+"\n\n"
        +"LIFETIME RECORD: Stage %d cleared\n" % permanent_stage
        +"NEXT RUN: Auto-Form %s through cleared Stage %d.\n\n" %
            ["ON" if game.auto_form_enabled else "OFF",permanent_stage]
        +"PRESERVED: owned creatures, Bonds, evolutions,\n"
        +"genes, Echo research, and Essence.\n"
        +"RESET: Gold, run levels, Gold upgrades, enemy seed.\n\n"
        +"Your opponents reroll, so even old stages can vary.")
    ascend_dialog.popup_centered(Vector2i(610,375))

func _ascend() -> void:
    if game == null:
        return
    var before: int = game.ascensions
    var earned: int = game.available_echoes()
    if earned < 1:
        return
    var before_record: int = maxi(game.lifetime_cleared_stage,game.best_wave-1)
    super._ascend()
    if game.ascensions <= before:
        return
    ascent_report_playing = playing
    playing = false
    var promotion: String = game.last_promotion if game.last_promotion != "" else "No Bond Ranks advanced yet."
    ascent_results.dialog_text = (
        "ASCENSION %d COMPLETE  •  +%d ECHOES\n\n" % [game.ascensions,earned]
        +"BONDED COMPANIONS: "+promotion+"\n\n"
        +"Record Stage %d is saved forever.\n" % before_record
        +"New opponents have been generated for this run.\n"
        +"Auto-Form: %s, up to Stage %d.\n\n" %
            ["ON" if game.auto_form_enabled else "OFF",game.lifetime_cleared_stage]
        +"Your creature collection and permanent power\n"
        +"survived. Try your newly expanded Gold level caps!")
    ascent_results.popup_centered(Vector2i(615,360))
    _refresh()

func _close_ascent_results() -> void:
    playing = ascent_report_playing and game.battle_started
    ascent_report_playing = false
    _refresh()

func _switch_tab(next: String) -> void:
    super._switch_tab(next)
    if not qol22_ready or sidebar == null:
        return
    bulk_mode_buttons.clear()
    if next == "GROW":
        var bar := HBoxContainer.new()
        bar.name = "ModulePurchaseAmount"
        bar.custom_minimum_size = Vector2(360,42)
        bar.add_theme_constant_override("separation",6)
        sidebar.add_child(bar)
        sidebar.move_child(bar,0)
        for quantity in [1,10,25,0]:
            var btn := Button.new()
            btn.text = "xMAX" if quantity == 0 else ("x%d" % quantity)
            btn.custom_minimum_size = Vector2(81,40)
            btn.pressed.connect(_choose_bulk.bind(quantity))
            btn.add_theme_font_size_override("font_size",12)
            _skin_button(btn,PALETTE["sage"],true)
            bar.add_child(btn)
            bulk_mode_buttons[quantity] = btn
    elif next == "LEGACY":
        var record: int = game.lifetime_cleared_stage if game.has_method("recommended_team_for") else 0
        _sidebar_card("LIFETIME ASCENT RECORD",
            "Highest cleared: Stage %d  •  Ascensions: %d\n" % [record,game.ascensions]
            +"Milestones: %s  /  %s  /  %s" % [
                "10 ✓" if record >= 10 else "10 ·",
                "15 ✓" if record >= 15 else "15 ·",
                "20 ✓" if record >= 20 else "20 ·"],
            "RECORDED",_noop,"information")
        var card: Control = sidebar.get_child(sidebar.get_child_count()-1)
        sidebar.move_child(card,0)
    _refresh_sidebar()

func _choose_bulk(quantity: int) -> void:
    bulk_amount = quantity
    _refresh_sidebar()

func _upgrade(kind: String) -> void:
    if game == null or not game.has_method("buy_module_batch"):
        super._upgrade(kind)
        return
    var bought: int = game.buy_module_batch(kind,bulk_amount)
    if bought <= 0:
        _toast("Not enough Gold to buy %s ranks of %s." % [
            "MAX" if bulk_amount == 0 else str(bulk_amount),String(ENGINE.MODULE_NAMES[kind])])
    else:
        game.save()
        _toast("%s • +%d RANK%s! Now Rank %d." % [
            String(ENGINE.MODULE_NAMES[kind]),bought,"S" if bought != 1 else "",int(game.modules[kind])])
    _refresh()

func _refresh_sidebar() -> void:
    super._refresh_sidebar()
    if not qol22_ready or game == null or not game.has_method("module_batch_quote"):
        return
    for quantity in bulk_mode_buttons:
        var button: Button = bulk_mode_buttons[quantity]
        button.add_theme_stylebox_override("normal",_style(
            Color("#477a69") if bulk_amount == quantity else Color("#264653"),
            PALETTE["gold"] if bulk_amount == quantity else PALETTE["sage"],7))
        button.tooltip_text = ("BUY MAX: spend all affordable Gold on one type." if quantity == 0
            else "Purchase exactly %d upgrade ranks at once." % quantity)
    for row in active_rows:
        if String(row["mode"]) != "module":
            continue
        var kind: String = String(row["key"])
        var quote: Dictionary = game.module_batch_quote(kind,bulk_amount)
        var button: Button = row["button"]
        button.disabled = not bool(quote["full"])
        button.text = "%s G" % game.format_number(float(quote["cost"])) if bool(quote["full"]) else (
            "NEED GOLD" if int(quote["count"]) == 0 else "CAN'T BUY x%d" % bulk_amount)
        var amount: int = int(quote["count"])
        button.tooltip_text = ("Buy %d rank%s of %s for %s Gold.\n" %
            [amount,"s" if amount != 1 else "",String(ENGINE.MODULE_NAMES[kind]),game.format_number(float(quote["cost"]))]
            +String(upgrade_breakdown(kind)["details"]))

func _refresh() -> void:
    super._refresh()
    if not qol22_ready or game == null or not game.has_method("recommended_team_for"):
        return
    var high: int = game.lifetime_cleared_stage
    if game.ascensions <= 0:
        autoform_button.text = "AUTO-FORM • LOCKED"
        autoform_button.disabled = true
        autoform_button.tooltip_text = "Unlock after the first Ascension. The first adventure stays fully manual."
    else:
        autoform_button.disabled = false
        var eligible: bool = game.is_autoform_eligible(game.wave)
        autoform_button.text = (
            "AUTO-FORM ON" if eligible else
            ("AUTO-FORM • NEW" if game.auto_form_enabled and game.wave > high else
            ("AUTO-FORM ON • FARM" if game.auto_form_enabled and game.repeat_wave else "AUTO-FORM OFF")))
        autoform_button.tooltip_text = ("After Ascension, automatically prepare the strongest elemental lineup at the start of stages 1-%d. New stages remain manual. %s" %
            [high,"Current stage has a manual override." if game.manual_override_stage == game.wave else
                "Tap to toggle. Your manual swaps remain in effect for this stage."])
    var favorable: int = 0
    var resisted: int = 0
    var neutral: int = 0
    for kind in game.squad_slots:
        if kind == "" or not game.has_instance(kind):
            continue
        var match: Dictionary = game.matchup_analysis(kind)
        var best: float = float(match["best"])
        if best >= 1.95:
            favorable += 1
        elif best <= 0.50:
            resisted += 1
        else:
            neutral += 1
    matchup_label.text = "YOUR MATCHUPS  •  %d STRONG   %d EVEN   %d WEAK" % [
        favorable,neutral,resisted]
    matchup_label.tooltip_text = "Counts the best target for each of your three allies. Tap MATCHUPS for each opponent."

func _refresh_codex() -> void:
    super._refresh_codex()
    if not qol22_ready or game == null or not game.has_method("matchup_analysis"):
        return
    for key in codex_cards:
        var kind: String = String(key)
        if not game.has_instance(kind):
            continue
        var matchup: Dictionary = game.matchup_analysis(kind)
        var row: Dictionary = codex_cards[key]
        var action: Button = row["action"]
        action.tooltip_text = "STAGE %d COUNTERS • %d strong, %d neutral, %d resisted. Auto-Form stops after lifetime Stage %d. Manual equips are respected." % [
            game.wave,int(matchup["strong"]),int(matchup["neutral"]),int(matchup["weak"]),game.lifetime_cleared_stage]
