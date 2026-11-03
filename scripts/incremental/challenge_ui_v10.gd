extends "res://scripts/incremental/journey_ui_v09.gd"
## v0.10: teach the existing mechanics where players use them.
## Focus and next-stage choices call genuine Challenge Engine methods.

const CHALLENGE = preload("res://scripts/incremental/challenge_engine_v10.gd")
const SKILL_SHORT = {"spriglet":"HEAL","brinlet":"BURST","cindlet":"FRENZY"}
const SKILL_HELP = {
    "spriglet":"Verdant Bloom heals 42% of your Ward. Choose it when a Guardian is wearing your pack down.",
    "brinlet":"Tidal Surge immediately bursts an enemy for heavy damage. Strong for clearing a wall.",
    "cindlet":"Ember Frenzy boosts pack damage for a short duration. Time it before a Guardian."
}
var focus_buttons: Dictionary = {}
var focus_caption: Label

func _ready() -> void:
    # Build the established journey-first shell, then replace its base game
    # instance with the extended real combat engine (same save schema).
    super._ready()
    game = CHALLENGE.new()
    game.initialize_alpha()
    game.load_save()
    game.notice.connect(_on_notice)
    last_kills = game.kills
    last_guardian = game.last_boss_wave
    _install_challenge_controls()
    if not game.onboarding_seen:
        game.onboarding_seen = true
        call_deferred("_show_first_steps")
    _refresh()

func _show_first_steps() -> void:
    if not is_inside_tree():
        return
    guide_dialog.title = "Wildbound • A Pack That Must Grow"
    guide_dialog.dialog_text = (
        "1. Your pack attacks on its own. Strike to help, but you must press NEXT STAGE after each victory.\n\n"
        +"2. Enemies get stronger quickly. When you hit a wall, FARM the previous stage for Gold and Bonds.\n\n"
        +"3. LEVEL means +19% damage for that creature per level. FOCUS one creature for 1.85x power. "
        +"Match its element: Grove beats Tide, Tide beats Ember, Ember beats Grove.\n\n"
        +"4. GUARDIANS give Nest Shards and Relics. EGGS are random creature hatches: duplicates improve a permanent Gene bonus, Shimmer eggs add more damage.\n\n"
        +"5. EVOLUTION requires level 15 plus 25 Bonds (earned by winning). It stays with you after ASCENSION. "
        +"Your first Ascension unlocks optional AUTO ADVANCE."
    )
    guide_dialog.popup_centered_ratio(0.72)

func _install_challenge_controls() -> void:
    # Each card gives a true choice of frontliner. The other two contribute
    # as support rather than being meaningless identical auto-attackers.
    for i in range(CHALLENGE.ORDER.size()):
        var kind: String = String(CHALLENGE.ORDER[i])
        var x: float = 24.0+float(i)*269.0
        var ability: Button = card_skill[kind]
        ability.size = Vector2(125,29)
        ability.tooltip_text = String(SKILL_HELP[kind])
        var focus: Button = _button("Focus_"+kind,"FOCUS",Rect2(x+143,576,103,29),_focus.bind(kind),COLORS[kind])
        focus.add_theme_font_size_override("font_size",11)
        focus.tooltip_text = "Focused creature deals 1.85x damage; supports deal 0.60x. Element matchups give 1.5x advantage or 0.75x resistance."
        focus_buttons[kind] = focus
        card_buy[kind].tooltip_text = "Leveling adds approximately +19% damage per level, permanently until your next Ascension. Evolution and Genes survive Ascension."
        card_art[kind].tooltip_text = "Creature portrait. Choose FOCUS to lead with this element in battle."
    focus_caption = _label("FocusReadout","",Rect2(39,346,514,18),12,GREEN)
    focus_caption.add_theme_color_override("font_shadow_color",Color("#10222b"))
    focus_caption.add_theme_constant_override("shadow_offset_x",1)
    focus_caption.add_theme_constant_override("shadow_offset_y",1)
    repeat_button.tooltip_text = "FARM: replay the just-cleared stage automatically for Gold and Bonds. PUSH: resume progressing after clearing foes."
    speed_button.tooltip_text = "Unlock automatic next-stage progression by completing your first Ascension. It starts OFF and is always optional."
    strike_button.tooltip_text = "After a victory, NEXT STAGE actively starts the next fight. During battle, STRIKE deals damage."
    guide_dialog.dialog_text = ""
    _switch_tab("GROW")

func _refresh() -> void:
    super._refresh()
    # super._ready() invokes this before challenge controls have been added.
    if game == null or focus_buttons.size() != 3 or not game.has_method("battle_dps"):
        return

    var waiting: bool = game.awaiting_next
    var focused: String = game.focused_companion
    var foe: String = String(CHALLENGE.SPECIES[game.enemy_species]["element"])
    var advantage: String = game.element_relation(focused)
    var enemy_name: String = game.species_name(game.enemy_species)
    if game.enemy_is_boss():
        enemy_name = String(CHALLENGE.SPECIES[game.enemy_species]["evolved"])
    screen_labels["Wave"].text = ("STAGE %d CLEARED  •  NEXT %d" % [
        game.last_stage_cleared,game.wave] if waiting else
        "STAGE %d  •  %s" % [game.wave,String(CHALLENGE.REGIONS[game.region]["name"])])
    screen_labels["EnemyName"].text = ("NEXT FOE: " if waiting else
        ("GUARDIAN: " if game.enemy_is_boss() else "WILD: "))+enemy_name
    screen_labels["EncounterHint"].text = ("CHOOSE: NEXT STAGE OR FARM FOR UPGRADES" if waiting else
        ("GUARDIAN! FURY IN %ds  •  USE YOUR SKILLS" % maxi(0,18-ceili(game.guardian_seconds))
        if game.enemy_is_boss() else "EACH STAGE IS HARDER  •  FOCUS A COUNTER"))
    screen_labels["EncounterHint"].add_theme_color_override("font_color",GOLD if waiting or game.enemy_is_boss() else GREEN)
    screen_labels["FieldStatus"].text = "WARD  %s / %s  •  THREAT %.1fx" % [
        game.format_number(game.ward),game.format_number(game.max_ward()),game.challenge_multiplier()]
    screen_labels["DamageReadout"].text = ("STAGE CLEARED  •  CHOOSE NEXT" if waiting else
        "REAL DPS VS FOE  "+game.format_number(game.battle_dps()))
    screen_labels["PackDps"].text = (
        "FOCUS %s  •  %s" % [game.species_name(focused).to_upper(),advantage])
    focus_caption.text = (
        "ELEMENT COUNTERS: GROVE > TIDE > EMBER > GROVE"
        if waiting else "FOCUS: %s  •  %s VS %s" % [
            game.species_name(focused).to_upper(),advantage,foe.to_upper()])
    strike_button.text = "NEXT STAGE  ▶" if waiting else "STRIKE  •  CLICK / SPACE"
    strike_button.disabled = not playing
    repeat_button.text = "PUSH" if game.repeat_wave else "FARM"
    speed_button.disabled = not game.auto_advance_unlocked()
    speed_button.text = ("AUTO LOCKED" if not game.auto_advance_unlocked()
        else ("AUTO ON" if game.auto_advance_enabled else "AUTO OFF"))
    resonance_button.disabled = waiting or game.overdrive < 99.99 or game.overdrive_left > 0.0
    for kind in CHALLENGE.ORDER:
        var k: String = String(kind)
        var owned: bool = int(game.levels[k]) > 0
        var selected: bool = game.focused_companion == k
        var focus: Button = focus_buttons[k]
        focus.disabled = not owned or selected
        focus.text = "LEADER" if selected else "FOCUS"
        focus.add_theme_stylebox_override("normal",_style(
            Color("#526b4a") if selected else Color("#244b56"),
            GOLD if selected else COLORS[k],6))
        var level: int = int(game.levels[k])
        var genes: int = int(game.gene[k])
        var gene_pct: int = roundi((pow(1.065,float(genes))-1.0)*100.0)
        if owned:
            var dps: float = game.species_damage(k)/game.attack_interval(k)
            card_details[k].text = "LV %d  •  %s DPS\nBOND %d/25  •  GENE +%d%%" % [
                level,game.format_number(dps),int(game.bonds[k]),gene_pct]
            card_details[k].tooltip_text = (
                "Every level: +19% damage. Bonds: 25 for evolution at level 15. "
                +"Every duplicate egg: +6.5% permanent damage (multiplicative). "
                +("Shimmer form: +22% more damage." if bool(game.rare[k]) else "Shimmer forms add +22% damage."))
        else:
            card_details[k].text = "RECRUIT FOR\nELEMENT "+String(CHALLENGE.SPECIES[k]["element"]).to_upper()
        var ability: Button = card_skill[k]
        var remaining: float = float(game.ability_clock[k])
        ability.text = String(SKILL_SHORT[k])+("  %ds" % ceili(remaining) if remaining > 0.0 else "  READY")
        ability.disabled = waiting or not owned or remaining > 0.0
    # Put the selected creature at the front, and the other two behind.
    team_art[0].texture = _creature_texture(focused,bool(game.evolved[focused]),false)
    var i: int = 1
    for kind in CHALLENGE.ORDER:
        var k: String = String(kind)
        if k == focused or int(game.levels[k]) < 1:
            continue
        if i < team_art.size():
            team_art[i].texture = _creature_texture(k,bool(game.evolved[k]),false)
            team_art[i].visible = true
            i += 1
    for j in range(i,team_art.size()):
        team_art[j].visible = false
    enemy_art.texture = _creature_texture(game.enemy_species,game.enemy_is_boss(),true)
    for kind in CHALLENGE.ORDER:
        var k: String = String(kind)
        card_art[k].texture = _creature_texture(k,bool(game.evolved[k]),false)

func _creature_texture(kind: String,evolved: bool,is_enemy: bool) -> Texture2D:
    # Native .base64 WebP atlases must be explicitly packed for HTML5.
    # Legacy PNGs remain a visible fallback if a browser cannot decode WebP.
    var texture: Texture2D = CREATURES.get_creature(kind,evolved)
    if texture != null:
        return texture
    var path: String = "res://assets/%s%s_%s.png" % [
        kind,"_evo" if evolved else "","front" if is_enemy else "back"]
    return load(path) as Texture2D

func _refresh_sidebar() -> void:
    super._refresh_sidebar()
    if game == null or not game.has_method("auto_advance_unlocked"):
        return
    for row in active_rows:
        var mode: String = String(row["mode"])
        var info: Label = row["info"]
        if mode == "egg":
            info.text = "5 Shards → creature or duplicate (+6.5% permanent Gene damage). Shimmer +22% damage; guaranteed by pity."
        elif mode == "ascend":
            info.text = "Earn %d Echoes. Resets Gold/levels; keeps Genes, Bonds & Evolution. Unlocks optional AUTO ADVANCE." % game.available_echoes()
        elif mode == "relic":
            info.tooltip_text = "Guardian Relics are permanent and can be equipped two at a time."
        elif mode == "research":
            info.tooltip_text = "Echo research is permanent. Reaching a wall is your signal to consider an Ascension."

func _switch_tab(next: String) -> void:
    super._switch_tab(next)
    if game == null or not game.has_method("battle_dps"):
        return
    if next == "WORLD":
        # Explanatory primer available in the same panel as tactic changes.
        _sidebar_card("Elemental Counterplay",
            "GROVE beats TIDE. TIDE beats EMBER. EMBER beats GROVE. Pick FOCUS on a creature card to double down on the matchup.",
            "GUIDE",_show_first_steps,"information")
        sidebar.move_child(sidebar.get_child(sidebar.get_child_count()-1),0)

func _focus(kind: String) -> void:
    if game.focus(kind):
        _toast("%s takes the lead! %s" % [game.species_name(kind),game.element_relation(kind)])
    _refresh()

func _strike() -> void:
    if game != null and game.has_method("enter_next_stage") and game.awaiting_next:
        if game.enter_next_stage():
            game.save()
            _toast("STAGE %d  •  NEW CHALLENGE!" % game.wave)
        _refresh()
        return
    super._strike()

func _repeat() -> void:
    if game.set_farming():
        _toast(game.last_notice)
    _refresh()

func _speed() -> void:
    if game.toggle_auto_advance():
        _toast(game.last_notice)
    _refresh()

func _buy_creature(kind: String) -> void:
    if not game.has_method("battle_dps"):
        super._buy_creature(kind)
        return
    var prior: float = game.battle_dps()
    var level_before: int = int(game.levels[kind])
    super._buy_creature(kind)
    var level_after: int = int(game.levels[kind])
    if level_after > level_before:
        _toast("%s Lv %d → %d! DAMAGE +19%%/LV. Team DPS %s → %s" % [
            game.species_name(kind),level_before,level_after,
            game.format_number(prior),game.format_number(game.battle_dps())])
    _refresh()

func _hatch() -> void:
    var eggs_before: int = game.eggs_hatched
    super._hatch()
    if game.eggs_hatched > eggs_before:
        _toast(game.last_notice+" • Egg bonuses stay after Ascension.")
    _refresh()
