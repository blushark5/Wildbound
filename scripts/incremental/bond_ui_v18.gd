extends "res://scripts/incremental/bond_ui_v14.gd"
## v0.18: swap painted 3-form roster into the already validated v0.16
## battlefield/Field Guide and bind an actual randomized-run engine.
const ENGINE_18 = preload("res://scripts/incremental/bond_engine_v18.gd")
const PAINTED_18 = preload("res://scripts/incremental/roster_art_v18.gd")

func _ready() -> void:
    super._ready()
    game = ENGINE_18.new()
    game.initialize_alpha()
    game.load_save()
    game.notice.connect(_on_notice)
    last_kills = game.kills
    last_guardian = game.last_boss_wave
    screen_labels["Tagline"].text = "12 FAMILIES • COLLECT • BOND • ASCEND"
    screen_labels["PackHeader"].text = "YOUR WILD SQUAD"
    collect_button.tooltip_text = "A new save starts with a random Fox, Bird and Lizard across three elements; eggs grant new species without duplicates."
    _switch_tab("GROW")
    _refresh()
    _toast("TWELVE ELEMENTAL LINES • THREE FAMILIES • SEE YOUR NEW ENCOUNTER EACH ASCENSION")

func _creature_texture(kind: String,evolved: bool,is_enemy: bool) -> Texture2D:
    if kind == "":
        return null
    var mythic: bool = (is_enemy and game.wave >= 20 and game.enemy_is_boss()) or (
        not is_enemy and game.has_method("unit_ascended") and game.unit_ascended(kind))
    return PAINTED_18.creature(kind,evolved,false,mythic)

func _animate_fighters() -> void:
    super._animate_fighters()
    if game == null or not game.has_method("unit_ascended"):
        return
    for i in range(3):
        for foe in [false,true]:
            var unit: Dictionary = game.rival_units[i] if foe else game.ally_units[i]
            var kind: String = String(unit.get("kind",""))
            if kind == "":
                continue
            var visual: Dictionary = rival_widgets[i] if foe else ally_widgets[i]
            var portrait: TextureRect = visual["portrait"]
            var evolved: bool = game.enemy_is_boss() if foe else game.unit_evolved(kind)
            var mythic: bool = (foe and game.wave >= 20 and game.enemy_is_boss()) or (
                not foe and game.unit_ascended(kind))
            portrait.texture = PAINTED_18.creature(kind,evolved,float(unit.get("action",0.0)) > 0.045,mythic)

func _refresh() -> void:
    super._refresh()
    if not sprite_ready or game == null or not game.has_method("family_of"):
        return
    screen_labels["PackDps"].text = "FOX • BIRD • LIZARD  •  %d / 3" % game.occupied_slots()
    screen_labels["EncounterHint"].tooltip_text = "Encounter seed %d • This exact trainer formation stays fixed when farming or reloading. Ascension rolls a new seed." % game.run_seed
    for i in range(3):
        var kind: String = String(game.squad_slots[i])
        var ckey: String = String(CHALLENGE.ORDER[i])
        if not game.has_instance(kind):
            continue
        screen_labels["Name_"+ckey].text = "SLOT %d • %s" % [
            i+1,game.display_name(kind,2 if game.unit_ascended(kind) else (1 if game.unit_evolved(kind) else 0))]
        card_art[ckey].texture = PAINTED_18.creature(kind,game.unit_evolved(kind),false,game.unit_ascended(kind))
        card_art[ckey].tooltip_text = "%s • %s • %s. Three evolutionary forms keep the same body family." % [
            game.family_of(kind),String(ENGINE_18.CATALOG[kind]["element"]),String(ENGINE_18.LINES[kind][3])]
    for i in range(3):
        var ally: Dictionary = game.ally_units[i]
        var ally_kind: String = String(ally.get("kind",""))
        if ally_kind != "":
            ally_widgets[i]["name"].text = game.display_name(ally_kind,2 if game.unit_ascended(ally_kind) else (1 if game.unit_evolved(ally_kind) else 0))
        var unit: Dictionary = game.rival_units[i]
        var enemy_kind: String = String(unit.get("kind",""))
        if enemy_kind != "":
            rival_widgets[i]["name"].text = game.display_name(enemy_kind,2 if game.wave >= 20 and game.enemy_is_boss() else (1 if game.enemy_is_boss() else 0))

func _refresh_codex() -> void:
    super._refresh_codex()
    if not sprite_ready or game == null or not game.has_method("family_of"):
        return
    for id in codex_cards:
        var kind: String = String(id)
        var entry: Dictionary = codex_cards[id]
        var owned: bool = game.has_instance(kind)
        var current_form: int = 2 if owned and game.unit_ascended(kind) else (1 if owned and game.unit_evolved(kind) else 0)
        entry["picture"].texture = PAINTED_18.creature(kind,current_form >= 1,false,current_form == 2)
        entry["name"].text = game.display_name(kind,current_form)
        if owned:
            entry["trait"].tooltip_text = "%s %s • %s disposition. Evolutions keep their species anatomy." % [
                String(ENGINE_18.CATALOG[kind]["element"]),game.family_of(kind),String(ENGINE_18.LINES[kind][3])]

func _show_first_steps() -> void:
    if not is_inside_tree() or not is_instance_valid(guide_dialog):
        return
    guide_dialog.title = "Wildbound • The Living Roster"
    guide_dialog.dialog_text = (
        "A NEW ADVENTURE begins with three different creature families: a FOX, BIRD, and LIZARD. Their elements are randomized for variety, without duplicates in your opening team. Existing saves keep their creatures and squad.\n\n"
        +"Four elements form a circle: EARTH beats WATER, WATER beats FIRE, FIRE beats AIR, and AIR beats EARTH. Your three creatures automatically choose favorable targets; bad matchups can be overcome by farming Gold and Bond XP.\n\n"
        +"Each stage generates a random opponent team that STAYS THE SAME on reload, retry and farming. ASCENDING rerolls future opponents while keeping your collection, traits, Genes, evolution and Bond Ranks. Guardians still appear every ten stages.\n\n"
        +"Your first EARNED hatch is only 5 Essence regardless of receiving three starters. Each egg guarantees a NEW creature; the first tends to supply your missing fourth element. Essence comes ONLY from the first-ever clear of a stage number (+1 normally, +4 Guardian), NEVER farming or replayed Ascension stages.\n\n"
        +"GOLD levels individuals to the ceiling permitted by their BOND RANK, or buys unlimited general upgrades. Bond XP grows through battles; Ascension raises prepared Bonds. Personal evolved art unlocks normally; its Ascended artwork shows at Bond Rank 4 after evolution."
    )
    guide_dialog.popup_centered_ratio(0.78)
