extends "res://scripts/incremental/squad_ui_v11.gd"
## Unique individuals, explicit collection acquisition, and four readable elements.
const COLLECTION_ENGINE = preload("res://scripts/incremental/collection_engine_v12.gd")
const COLLECTION_ART = preload("res://scripts/incremental/collection_art_v12.gd")
const ELEMENT_COLORS: Dictionary = {
    "Earth":Color("#91d59b"),"Water":Color("#87cdef"),
    "Fire":Color("#f2ad82"),"Air":Color("#c7c5fc")
}

var collection_ready: bool = false
var chosen_slot: int = 1
var collect_button: Button
var team_note: Label

func _ready() -> void:
    super._ready()
    game = COLLECTION_ENGINE.new()
    game.initialize_alpha()
    game.load_save()
    game.notice.connect(_on_notice)
    last_kills = game.kills
    last_guardian = game.last_boss_wave
    _install_collection_ui()
    collection_ready = true
    _switch_tab("NEST")
    _refresh()

func _show_first_steps() -> void:
    if not is_inside_tree() or not is_instance_valid(guide_dialog):
        return
    guide_dialog.title = "Wildbound • Creatures Worth Earning"
    guide_dialog.dialog_text = (
        "Your Spriglet is a UNIQUE creature. The other two squad slots begin EMPTY. No more buying companions with Gold or duplicating one monster into multiple slots.\n\n"
        +"WIN trainer battles to earn Essence. Open COLLECT to hatch new creatures. Your first hatch costs 5 Essence. Later hatches cost more, so a complete twelve-species collection is a long-term achievement. Every egg guarantees a species you don't already own.\n\n"
        +"ELEMENTS: EARTH beats WATER, WATER beats FIRE, FIRE beats AIR, AIR beats EARTH. Advantage deals 2x and disadvantage deals 0.45x. Creatures automatically select effective targets and switch when something is knocked out.\n\n"
        +"HATCHED CREATURES have individual traits. Tap an empty squad slot or CHANGE, then ASSIGN an owned creature in COLLECT. Each unique species can appear only once in your active team.\n\n"
        +"LEVEL upgrades your chosen individual. BONDS grow from battles, and evolution at level 15 + 25 bonds is permanent. Your individuals, their traits, genes, and evolutions all survive Ascension. NEXT STAGE and FARM are still your choices."
    )
    guide_dialog.popup_centered_ratio(0.77)

func _install_collection_ui() -> void:
    tab_buttons["NEST"].text = "COLLECT"
    tab_buttons["GROW"].text = "UPGRADES"
    tab_buttons["LEGACY"].text = "LEGACY"
    tab_buttons["WORLD"].text = "WORLD"
    tab_buttons["GROW"].add_theme_font_size_override("font_size",10)
    collect_button = _button("CollectionShortcut","COLLECT  1 / 12",
        Rect2(680,417,145,29),_open_collection,GOLD)
    collect_button.add_theme_font_size_override("font_size",12)
    screen_labels["PackDps"].position.x = 358.0
    screen_labels["PackDps"].size.x = 308.0
    team_note = _label("IndividualRosterHelp","",Rect2(861,286,396,15),11,MUTED)
    for i in range(3):
        var key: String = String(CHALLENGE.ORDER[i])
        focus_buttons[key].tooltip_text = "Choose ONE unique creature from your collection. Duplicate species cannot occupy multiple slots."
        card_buy[key].tooltip_text = "Spend Gold to raise this INDIVIDUAL'S level. Each creature has its own trait and combat growth."
        card_art[key].tooltip_text = "Every creature is individually earned by hatching in COLLECT."
    speed_button.tooltip_text = "Optional automatic NEXT STAGE unlocks with Ascension. Hatching, lineup and level choices remain yours."
    _toast("COLLECT ESSENCE FROM TRAINER WINS TO HATCH YOUR NEXT UNIQUE MONSTER!")

func _creature_texture(kind: String,evolved: bool,is_enemy: bool) -> Texture2D:
    if kind == "":
        return null
    var picture: Texture2D = COLLECTION_ART.get_creature(kind,evolved)
    if picture != null:
        return picture
    return super._creature_texture(kind,evolved,is_enemy)

func _open_collection() -> void:
    chosen_slot = 1 if game.squad_slots[1] == "" else (2 if game.squad_slots[2] == "" else 0)
    _switch_tab("NEST")

func _switch_tab(next: String) -> void:
    super._switch_tab(next)
    if not collection_ready or game == null or not game.has_method("collection_count"):
        return
    if next == "NEST":
        for child in sidebar.get_children():
            sidebar.remove_child(child)
            child.queue_free()
        active_rows.clear()
        _sidebar_card("HATCH • A NEW UNIQUE CREATURE",
            "Win trainer battles for Essence. Each hatch guarantees a NEW species, with its own traits. No duplicate creatures in your squad.",
            "HATCH",_hatch_owned,"unique_hatch")
        for kind in COLLECTION_ENGINE.COLLECTION_ORDER:
            var name: String = String(COLLECTION_ENGINE.CATALOG[kind]["name"])
            var elem: String = String(COLLECTION_ENGINE.CATALOG[kind]["element"])
            _sidebar_card(name+"   •   "+elem,
                "A unique creature to discover, raise and evolve.",
                "ASSIGN",_assign_owned.bind(String(kind)),"individual",String(kind))
        _refresh_sidebar()
    elif next == "GROW":
        _sidebar_card("Why levels matter",
            "Each level adds 19% damage to ONE individual. Raise your favorites; traits, Genes and evolution are permanent across Ascension.",
            "COLLECT",_open_collection,"tutorial")
        _refresh_sidebar()
    elif next == "WORLD":
        _sidebar_card("Four-element circle",
            "EARTH > WATER > FIRE > AIR > EARTH. Strong matchups hit for 2x; resisted attacks only 0.45x. Your fighters target automatically.",
            "GUIDE",_show_first_steps,"tutorial")
        _refresh_sidebar()

func _refresh_sidebar() -> void:
    super._refresh_sidebar()
    if not collection_ready or game == null or not game.has_method("collection_count"):
        return
    for row in active_rows:
        var mode: String = String(row["mode"])
        var button: Button = row["button"]
        var info: Label = row["info"]
        if mode == "unique_hatch":
            var cost: int = game.hatch_cost()
            button.text = "HATCH %d" % cost
            button.disabled = game.essence < cost or game.collection_count() >= 12
            info.text = "%d / %d Essence • %d / 12 discovered • Next egg GUARANTEES a new species. Each later egg costs more." % [
                game.essence,cost,game.collection_count()]
        elif mode == "individual":
            var key: String = String(row["key"])
            var exists: bool = game.has_instance(key)
            var element: String = String(COLLECTION_ENGINE.CATALOG[key]["element"])
            if exists:
                var record: Dictionary = game.unit_record(key)
                var current_slot: int = game.squad_slots.find(key)
                button.text = ("ACTIVE" if current_slot == chosen_slot else "ASSIGN")
                button.disabled = current_slot == chosen_slot
                info.text = "Lv %d • %s trait • %d Bonds • %d Genes • %s" % [
                    int(record["level"]),String(record["trait"]),int(record["bond"]),int(record["gene"]),
                    "SQUAD "+str(current_slot+1) if current_slot >= 0 else "IN COLLECTION"]
            else:
                button.text = "UNDISCOVERED"
                button.disabled = true
                info.text = element+" • An individual still waiting to be hatched."

func _refresh() -> void:
    super._refresh()
    if not collection_ready or game == null or not game.has_method("collection_count"):
        return
    var wiped: bool = bool(game.awaiting_next) and String(game.last_clash).begins_with("SQUAD DEFEATED")
    var done: bool = bool(game.awaiting_next)
    screen_labels["Shards"].text = "ESSENCE  %d / %d" % [game.essence,game.hatch_cost()]
    screen_labels["PackDps"].text = "UNIQUE INDIVIDUALS • %d/3 ACTIVE" % game.occupied_slots()
    screen_labels["EnemyName"].text = "RIVAL TRAINER • %d/3" % game.rival_alive()
    screen_labels["EnemyHp"].text = "%s enemy HP remaining" % game.format_number(game.enemy_hp)
    screen_labels["FieldStatus"].text = "TEAM HP %s / %s  •  THREAT %.1fx" % [
        game.format_number(game.ward),game.format_number(game.party_max_hp()),game.challenge_multiplier()]
    ward_bar.size.x = 784.0*clampf(game.ward/game.party_max_hp(),0.0,1.0)
    screen_labels["EncounterHint"].text = (
        "TEAM WIPED • CHANGE YOUR SQUAD OR FARM" if wiped else
        "TRAINER DEFEATED • NEXT STAGE OR FARM" if done else
        "YOUR MONSTERS AUTOMATICALLY SEEK ELEMENTAL COUNTERS")
    screen_labels["DamageReadout"].text = (
        "RETRY OR FARM" if wiped else
        "STAGE CLEARED" if done else
        "%d VS %d • %s DPS" % [game.ally_alive(),game.rival_alive(),game.squad_dps()])
    team_note.text = "Squad slot %d selected • COLLECT to discover/assign" % (chosen_slot+1)
    collect_button.text = "COLLECT  %d / 12" % game.collection_count()
    squad_status.text = "RETRY\nOR\nFARM" if wiped else ("NEXT\nOR\nFARM" if done else "VS\nAUTO\nTARGETS")
    if wiped:
        strike_button.text = "RETRY STAGE  ▶"
    for i in range(3):
        var ally: Dictionary = game.ally_units[i]
        var foe: Dictionary = game.rival_units[i]
        _update_unit(ally_widgets[i],ally,false,i)
        _update_unit(rival_widgets[i],foe,true,i)
        var link: Line2D = target_threads[i]
        var aim: int = int(ally.get("target",-1))
        var key: String = String(ally["kind"])
        link.visible = not done and key != "" and float(ally["hp"]) > 0.0 and aim >= 0
        if link.visible:
            var element: String = String(COLLECTION_ENGINE.CATALOG[key]["element"])
            var tint: Color = ELEMENT_COLORS[element]
            link.default_color = Color(tint,0.30)
            link.points = PackedVector2Array([
                Vector2(ALLY_X[i]+95.0,239.0),
                Vector2(439.0,224.0+float(i)*9.0),
                Vector2(RIVAL_X[aim]+4.0,240.0)
            ])
        var card_key: String = String(CHALLENGE.ORDER[i])
        var existing: bool = key != "" and game.has_instance(key)
        var portrait: TextureRect = card_art[card_key]
        portrait.visible = existing
        var buy: Button = card_buy[card_key]
        var ability: Button = card_skill[card_key]
        var change: Button = focus_buttons[card_key]
        change.text = "CHOOSE" if not existing else "CHANGE"
        change.disabled = false
        if not existing:
            screen_labels["Name_"+card_key].text = "SLOT %d • EMPTY" % (i+1)
            card_details[card_key].text = "Hatch a unique creature\nand choose it in COLLECT"
            buy.text = "NO CREATURE"
            buy.disabled = true
            ability.text = "NO SKILL"
            ability.disabled = true
            continue
        var record: Dictionary = game.unit_record(key)
        var element: String = String(COLLECTION_ENGINE.CATALOG[key]["element"])
        var level: int = game.unit_level(key)
        screen_labels["Name_"+card_key].text = "SLOT %d • %s" % [
            i+1,String(COLLECTION_ENGINE.CATALOG[key]["name"])]
        screen_labels["Name_"+card_key].add_theme_color_override("font_color",ELEMENT_COLORS[element])
        portrait.texture = _creature_texture(key,bool(record["evolved"]),false)
        card_details[card_key].text = "Lv %d • %s • %s\nBond %d/25 • Gene %d" % [
            level,element,String(record["trait"]),int(record["bond"]),int(record["gene"])]
        card_details[card_key].tooltip_text = (
            "Individual #%d • %s trait. Damage %s. Only this creature gains levels when upgraded." % [
                int(record["id"]),String(record["trait"]),game.format_number(game.combat_damage(key))])
        var price: float = game.creature_level_price(key,batch)
        buy.text = "LEVEL x%d • %s G" % [batch,game.format_number(price)]
        buy.disabled = game.gold < price
        var cooldown: float = float(game.unlock_clock.get(key,0.0))
        ability.text = String(COLLECTION_ENGINE.CATALOG[key]["ability"])+(
            " %ds" % ceili(cooldown) if cooldown > 0.0 else " READY")
        ability.disabled = done or float(ally["hp"]) <= 0.0 or cooldown > 0.0
    for t in team_art:
        t.visible = false
    enemy_art.visible = false
    focus_caption.visible = false
    _refresh_sidebar()

func _update_unit(visual: Dictionary,unit: Dictionary,enemy: bool,index: int) -> void:
    # The inherited squad screen briefly uses the legacy engine during
    # Control._ready. Its creatures don't have personal collection methods.
    if game == null or not game.has_method("collection_count"):
        super._update_unit(visual,unit,enemy,index)
        return
    var kind: String = String(unit["kind"])
    var alive: bool = float(unit["hp"]) > 0.0
    var art: TextureRect = visual["portrait"]
    if kind == "":
        art.visible = false
        visual["name"].text = "EMPTY"
        visual["hp"].text = "UNASSIGNED"
        visual["bar"].size.x = 0.0
        visual["target"].text = "HATCH CREATURE"
        return
    art.visible = true
    var evolved: bool = game.enemy_is_boss() if enemy else game.unit_evolved(kind)
    art.texture = _creature_texture(kind,evolved,enemy)
    art.modulate = Color("#8496a0",0.20) if not alive else (
        Color("#f7c4a6") if float(unit.get("flash",0.0)) > 0.0 else Color.WHITE)
    art.position.y = UNIT_Y+(3.0*sin(animation_clock*1.8+float(index)) if alive else 9.0)
    var info: Dictionary = COLLECTION_ENGINE.CATALOG[kind]
    visual["name"].text = String(info["evolved"] if evolved else info["name"])
    var color: Color = ELEMENT_COLORS[String(info["element"])]
    visual["name"].add_theme_color_override("font_color",color if alive else MUTED)
    visual["bar"].size.x = (89.0 if enemy else 97.0)*clampf(
        float(unit["hp"])/maxf(1.0,float(unit["max_hp"])),0.0,1.0)
    visual["bar"].color = CORAL if enemy else GREEN
    visual["hp"].text = "KNOCKED OUT" if not alive else "%s / %s HP" % [
        game.format_number(float(unit["hp"])),game.format_number(float(unit["max_hp"]))]
    var target: int = int(unit.get("target",-1))
    if not alive:
        visual["target"].text = "KNOCKED OUT"
    elif target < 0:
        visual["target"].text = "NO TARGET"
    else:
        var opposing: Array[Dictionary] = game.ally_units if enemy else game.rival_units
        var victim: String = String(opposing[target]["kind"])
        var multi: float = game.multiplier(kind,victim)
        visual["target"].text = "→ %s  %.2fx" % [
            String(COLLECTION_ENGINE.CATALOG[victim]["name"]),multi]
        visual["target"].add_theme_color_override("font_color",
            GREEN if multi > 1.0 else (CORAL if multi < 1.0 else MUTED))

func _focus(kind: String) -> void:
    var index: int = CHALLENGE.ORDER.find(kind)
    if index < 0:
        return
    chosen_slot = index
    _switch_tab("NEST")
    _toast("CHOOSE A UNIQUE CREATURE TO ASSIGN TO SLOT %d" % (index+1))

func _assign_owned(kind: String) -> void:
    if game.assign_creature(chosen_slot,kind):
        _toast("%s ASSIGNED TO SLOT %d" % [
            String(COLLECTION_ENGINE.CATALOG[kind]["name"]),chosen_slot+1])
        game.save()
    _refresh()

func _buy_creature(kind: String) -> void:
    var slot: int = CHALLENGE.ORDER.find(kind)
    if slot < 0:
        return
    var member: String = String(game.squad_slots[slot])
    if member != "" and game.level_creature(member,batch):
        _toast("%s LEVEL %d • INDIVIDUAL POWER INCREASED" % [
            game.combat_name(member),game.unit_level(member)])
    _refresh()

func _use_skill(kind: String) -> void:
    var slot: int = CHALLENGE.ORDER.find(kind)
    if slot < 0:
        return
    var member: String = String(game.squad_slots[slot])
    if member != "" and game.use_ability(member):
        _toast("%s USED %s" % [
            game.combat_name(member),String(COLLECTION_ENGINE.CATALOG[member]["ability"])])
    _refresh()

func _hatch_owned() -> void:
    var kind: String = game.hatch_egg()
    if kind != "":
        _toast("A NEW INDIVIDUAL! %s • %s TRAIT" % [
            String(COLLECTION_ENGINE.CATALOG[kind]["name"]),game.unit_trait(kind)])
        game.save()
        for i in range(3):
            if String(game.squad_slots[i]) == "":
                chosen_slot = i
                break
        _switch_tab("NEST")
    _refresh()

func _hatch() -> void:
    _hatch_owned()
