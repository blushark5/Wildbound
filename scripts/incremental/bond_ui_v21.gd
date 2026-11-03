extends "res://scripts/incremental/bond_ui_v20.gd"
## Wildbound v0.21: readable on-phone tutorial, integer-only displayed
## team DPS, and real per-rank + cumulative Gold-upgrade math. Combat and
## Gold purchase coefficients deliberately remain unchanged.

var qol21_ready: bool = false
var wrapped_guide: RichTextLabel

func _ready() -> void:
    super._ready()
    _install_wrapped_guide()
    qol21_ready = true
    _refresh()

func _install_wrapped_guide() -> void:
    # AcceptDialog's built-in dialog_text label doesn't word-wrap, which
    # made each introduction paragraph spill off the right side on phones.
    # Use a bounded, scrollable RichTextLabel inside the modal instead.
    guide_dialog.dialog_text = ""
    wrapped_guide = RichTextLabel.new()
    wrapped_guide.name = "WrappedGuideContent"
    wrapped_guide.position = Vector2(16,26)
    wrapped_guide.size = Vector2(592,378)
    wrapped_guide.custom_minimum_size = Vector2(592,378)
    wrapped_guide.bbcode_enabled = true
    wrapped_guide.fit_content = false
    wrapped_guide.scroll_active = true
    wrapped_guide.scroll_following = false
    wrapped_guide.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    wrapped_guide.selection_enabled = false
    wrapped_guide.mouse_filter = Control.MOUSE_FILTER_STOP
    wrapped_guide.add_theme_font_size_override("normal_font_size",16)
    wrapped_guide.add_theme_color_override("default_color",Color("#f0f3eb"))
    guide_dialog.add_child(wrapped_guide)

func _show_first_steps() -> void:
    if not is_inside_tree() or not is_instance_valid(guide_dialog):
        return
    if not is_instance_valid(wrapped_guide):
        _install_wrapped_guide()
    guide_dialog.title = "Wildbound • A New Adventure"
    var start_text: String = (
        "[b]1. START THE FIRST BATTLE[/b]\n"
        +"Your opening Fox, Bird and Lizard are unique, with three randomized elements. "
        +"Close this guide, then press [b]START FIRST BATTLE[/b]. Nothing fights or earns rewards until then.\n\n"
        if game != null and not game.battle_started else
        "[b]1. BATTLE CONTROLS[/b]\n"
        +"Your three creatures attack automatically. You can assist with abilities and change your squad in the Field Guide. "
        +"Opening this guide pauses the battle.\n\n")
    wrapped_guide.text = (
        start_text
        +"[b]2. COUNTER THE ENEMY[/b]\n"
        +"Earth beats Water, Water beats Fire, Fire beats Air, Air beats Earth. "
        +"Use the element icons by each creature to build a three-creature counter team.\n\n"
        +"[b]3. PUSH OR FARM[/b]\n"
        +"A stage keeps its enemy lineup within the current Ascension. "
        +"First-ever clears grant Essence. FARM replays cleared stages for Gold and Bond XP, never Essence. "
        +"Choose a stage from [b]CHOOSE FARM STAGE[/b]; the last successful team will be restored where known. "
        +"Failed farms automatically retreat to an earlier stage. [b]RESUME PUSH[/b] returns to your previous wall.\n\n"
        +"[b]4. GOLD UPGRADES[/b]\n"
        +"Your creatures have individual Bond-based level caps. The GROW upgrades affect the whole squad. "
        +"Each upgrade now shows exactly how much one rank adds and your combined bonus.\n\n"
        +"[b]5. ASCENSION[/b]\n"
        +"Reach Stage 20 in one run to unlock Ascension and gain Echoes. "
        +"Gold, temporary upgrades and creature levels reset, but owned creatures, Bonds, evolution and permanent rewards survive. "
        +"Ascension also rerolls stage enemy teams.\n\n"
        +"[b]6. SAVE SLOTS[/b]\n"
        +"Tap SAVES to manage three separate adventures, create a new game, or delete a slot. "
        +"Existing saves and their progress are preserved until you confirm a deletion.")
    wrapped_guide.scroll_to_line(0)
    guide_dialog.popup_centered(Vector2i(630,484))

func _whole_dps(value: float) -> String:
    if is_nan(value):
        return "0"
    if is_inf(value):
        return "MAX"
    # Direct integer figures through the first billion; beyond that,
    # abbreviate with whole-number suffixes to avoid line overflow.
    if absf(value) < 1.0e9:
        return "%.0f" % value
    var units: Array[String] = ["B","T","Qa","Qi","Sx"]
    var number: float = value/1.0e9
    for unit in units:
        if absf(number) < 1000.0:
            return "%.0f%s" % [number,unit]
        number /= 1000.0
    return "%.0e" % value

func upgrade_breakdown(kind: String) -> Dictionary:
    # Uses exact coefficients from engine.gd, alpha_engine.gd and the
    # currently active v0.20 six-unit combat engine.
    if game == null or not game.modules.has(kind):
        return {"line1":"","line2":"","details":""}
    var rank: int = int(game.modules[kind])
    var next: int = rank+1
    var line1: String = ""
    var line2: String = ""
    var details: String = ""
    match kind:
        "power":
            var now_pct: float = (pow(1.13,float(rank))-1.0)*100.0
            var next_pct: float = (pow(1.13,float(next))-1.0)*100.0
            line1 = "Each rank: +13% damage (multiplicative)"
            line2 = "Total +%.1f%%  →  +%.1f%% next  •  Rank %d" % [now_pct,next_pct,rank]
            details = "All creatures deal 1.13x damage per rank. Damage multiplier: %.3fx now, %.3fx next. Each rank stacks on earlier purchases." % [pow(1.13,float(rank)),pow(1.13,float(next))]
        "tempo":
            var now_pct: float = (1.0/pow(0.94,float(rank))-1.0)*100.0
            var next_pct: float = (1.0/pow(0.94,float(next))-1.0)*100.0
            line1 = "Each rank: attack interval -6%"
            line2 = "Attack rate +%.1f%%  →  +%.1f%%  •  Rank %d" % [now_pct,next_pct,rank]
            details = "Each rank makes automatic attacks 6% faster by reducing the interval to 94% of its previous value. Effective attack-rate gain: +%.2f%% now, +%.2f%% with next rank." % [now_pct,next_pct]
        "guard":
            var old_hp: float = game.max_ward()
            var new_hp: float = old_hp*float(100+22*next)/float(100+22*rank)
            line1 = "Each rank: +22 base Ward HP"
            line2 = "Total %s  →  %s HP  •  Rank %d" % [_whole_dps(old_hp),_whole_dps(new_hp),rank]
            details = "Base maximum Ward = 100 + 22 per rank, then permanent research/relic modifiers multiply the result. Actual maximum team Ward HP increases from %s to %s." % [_whole_dps(old_hp),_whole_dps(new_hp)]
        "crit":
            var current_chance: float = minf(0.70,0.05+float(rank)*0.035)
            var next_chance: float = minf(0.70,0.05+float(next)*0.035)
            line1 = "Each rank: +3.5 points crit (70% cap)"
            line2 = "%.1f%%  →  %.1f%% chance  •  Rank %d" % [current_chance*100.0,next_chance*100.0,rank]
            details = "Critical hits deal 2.5x normal damage. Base chance is 5%; each rank adds 3.5 percentage points, capped at 70%. Current expected hit multiplier: %.3fx; next: %.3fx." % [1.0+current_chance*1.5,1.0+next_chance*1.5]
        "bounty":
            var current_pct: float = (pow(1.15,float(rank))-1.0)*100.0
            var next_pct: float = (pow(1.15,float(next))-1.0)*100.0
            line1 = "Each rank: +15% victory Gold (stacks)"
            line2 = "Total +%.1f%%  →  +%.1f%%  •  Rank %d" % [current_pct,next_pct,rank]
            var gold_now: float = game.wave_reward()
            details = "Victory Gold is multiplied by 1.15x for every rank, compounding with region, research and relic Gold bonuses. At your current stage the payout is about %s Gold now versus %s next rank, before any on-kill extras." % [game.format_number(gold_now),game.format_number(gold_now*1.15)]
        "recovery":
            var current_rate: float = 1.0+float(rank)*0.7
            var next_rate: float = 1.0+float(next)*0.7
            line1 = "Each rank: +0.7% max HP regenerated/sec"
            line2 = "%.1f%%/s  →  %.1f%%/s  •  Rank %d" % [current_rate,next_rate,rank]
            details = "During combat, each 0.25s healing pulse restores 0.25% of the team's max HP multiplied by (1 + 0.7 × rank). This is approximately %.1f%% of maximum HP per second now, %.1f%% after the next rank, before stance effects." % [current_rate,next_rate]
        "pierce":
            var current_pct: int = rank*20
            var next_pct: int = next*20
            line1 = "Each rank: +20% damage vs Guardians"
            line2 = "Total +%d%%  →  +%d%%  •  Rank %d" % [current_pct,next_pct,rank]
            details = "Boss-only damage multiplier is 1 + 0.20 × Pierce rank. Normal-stage damage is unchanged. Guardian multiplier is %.2fx now and %.2fx at the next rank." % [1.0+0.2*rank,1.0+0.2*next]
    return {"line1":line1,"line2":line2,"details":details,"rank":rank}

func _refresh_sidebar() -> void:
    super._refresh_sidebar()
    if not qol21_ready or game == null:
        return
    for row in active_rows:
        if String(row["mode"]) != "module":
            continue
        var kind: String = String(row["key"])
        var metrics: Dictionary = upgrade_breakdown(kind)
        var info: Label = row["info"]
        var button: Button = row["button"]
        info.text = String(metrics["line1"])+"\n"+String(metrics["line2"])
        info.tooltip_text = String(metrics["details"])
        button.tooltip_text = "%s\nCurrent rank %d • Next Gold cost %s.\n%s" % [
            String(ENGINE.MODULE_NAMES[kind]),
            int(metrics["rank"]),game.format_number(game.module_cost(kind)),
            String(metrics["details"])]

func _refresh() -> void:
    super._refresh()
    if not qol21_ready or game == null or not game.has_method("squad_dps"):
        return
    # v0.12 used %s on the raw floating-point squad_dps value, yielding
    # unwieldy strings such as 1526.483729325 in the actual 3v3 HUD.
    # Show an integer on the main line. Don't hide hit/crit animations.
    if game.damage_flash <= 0.0:
        screen_labels["DamageReadout"].text = "%d vs %d  •  TEAM DPS %s" % [
            game.ally_alive(),game.rival_alive(),_whole_dps(game.squad_dps())]
