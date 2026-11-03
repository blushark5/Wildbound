extends "res://scripts/incremental/challenge_ui_v10.gd"
## True three-on-three combat presentation on top of the proven Journey shell.
const SQUAD_ENGINE = preload("res://scripts/incremental/squad_engine_v11.gd")

const ALLY_X: Array[float] = [64.0,181.0,298.0]
const RIVAL_X: Array[float] = [499.0,610.0,721.0]
const UNIT_Y: float = 203.0

var squad_display_ready: bool = false
var ally_widgets: Array[Dictionary] = []
var rival_widgets: Array[Dictionary] = []
var rival_title: Label
var ally_title: Label
var squad_status: Label
var target_threads: Array[Line2D] = []

func _ready() -> void:
    # Inherit panel geometry, navigation, saved progression and callbacks.
    super._ready()
    game = SQUAD_ENGINE.new()
    game.initialize_alpha()
    game.load_save()
    if game.ally_units.size() != 3:
        game.initialize_squads()
    game.notice.connect(_on_notice)
    last_kills = game.kills
    last_guardian = game.last_boss_wave
    _install_squad_stage()
    _switch_tab("GROW")
    squad_display_ready = true
    _refresh()

func _show_first_steps() -> void:
    if not is_inside_tree() or not is_instance_valid(guide_dialog):
        return
    guide_dialog.title = "Wildbound • Three Against Three"
    guide_dialog.dialog_text = (
        "Every trainer battle is now 3 vs 3. Each creature has its own HP and attack timer, and automatically selects the opponent it counters.\n\n"
        +"ELEMENTS: GROVE beats TIDE, TIDE beats EMBER, EMBER beats GROVE. Strong attacks hit for 2x; resisted attacks only 0.45x.\n\n"
        +"The first team is THREE SPRIGLETS. All three counter Brinlet but struggle against Cindlet. After recruiting Brinlet or Cindlet, tap SWAP on a squad slot to change its species. You can field duplicates.\n\n"
        +"The whole opposing team must fall to clear a stage. A KO forces the surviving monsters to retarget. Defeat the rival trainer for one Gold/Bond reward. NEXT STAGE and FARM still require your choice.\n\n"
        +"LEVELING improves each copy of that species. EGGS give a new species or permanent Gene upgrades to duplicates. EVOLUTION persists through Ascension. AUTO ADVANCE still unlocks after your first Ascension."
    )
    guide_dialog.popup_centered_ratio(0.74)

func _install_squad_stage() -> void:
    for t in team_art:
        t.visible = false
    enemy_art.visible = false
    focus_caption.visible = false
    screen_labels["Toast"].position = Vector2(224,182)
    screen_labels["Toast"].size = Vector2(421,26)
    screen_labels["Toast"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    ally_title = _label("SquadTeamTitle","YOUR SQUAD",Rect2(55,178,350,21),14,GREEN)
    rival_title = _label("RivalTeamTitle","RIVAL TRAINER",Rect2(505,178,310,21),14,CORAL)
    rival_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    squad_status = _label("SquadTip","",Rect2(397,217,101,65),12,GOLD)
    squad_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    squad_status.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    squad_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

    for i in range(3):
        var ax: float = ALLY_X[i]
        var rx: float = RIVAL_X[i]
        var ally_picture: TextureRect = _texture("SquadAlly_%d" % i,Rect2(ax,204,98,108))
        var rival_picture: TextureRect = _texture("SquadRival_%d" % i,Rect2(rx,204,91,108))
        rival_picture.flip_h = true
        var a: Dictionary = {
            "portrait":ally_picture,
            "name":_label("SquadAllyName_%d"%i,"",Rect2(ax-7,196,116,18),12,GREEN),
            "bar":_paint("SquadAllyHp_%d"%i,Rect2(ax,314,97,6),GREEN),
            "hp":_label("SquadAllyVital_%d"%i,"",Rect2(ax-6,325,112,16),10,TEXT),
            "target":_label("SquadAllyAim_%d"%i,"",Rect2(ax-13,345,127,17),10,GOLD)
        }
        var e: Dictionary = {
            "portrait":rival_picture,
            "name":_label("SquadRivalName_%d"%i,"",Rect2(rx-7,196,108,18),12,CORAL),
            "bar":_paint("SquadRivalHp_%d"%i,Rect2(rx,314,89,6),CORAL),
            "hp":_label("SquadRivalVital_%d"%i,"",Rect2(rx-6,325,105,16),10,TEXT),
            "target":_label("SquadRivalAim_%d"%i,"",Rect2(rx-11,345,112,17),10,GOLD)
        }
        a["name"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        e["name"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        a["hp"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        e["hp"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        a["target"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        e["target"].horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        ally_widgets.append(a)
        rival_widgets.append(e)
        var line := Line2D.new()
        line.name = "TargetLine_%d"%i
        line.width = 1.8
        line.default_color = COLORS[String(game.squad_slots[i])].lightened(0.1)*Color(1.0,1.0,1.0,0.36)
        add_child(line)
        target_threads.append(line)
    for i in range(3):
        var reference: String = String(CHALLENGE.ORDER[i])
        focus_buttons[reference].tooltip_text = "Change SQUAD SLOT %d to the next recruited species. You may use the same species in multiple slots. Changing the squad restarts this trainer fight." % (i+1)
        card_buy[reference].tooltip_text = "Upgrade the species assigned to this slot. Each level improves EVERY copy of that creature."
    speed_button.tooltip_text = "The whole enemy trainer team must be defeated. Auto-entering the next trainer battle unlocks after your first Ascension."
    repeat_button.tooltip_text = "FARM a beaten trainer for Gold and Bonds, or PUSH to face a stronger trainer."
    _toast("3 ON 3 • YOUR CREATURES NOW PICK THEIR OWN COUNTERS!")

func _refresh() -> void:
    super._refresh()
    if not squad_display_ready or game == null or not game.has_method("rival_alive"):
        return
    var cleared: bool = bool(game.awaiting_next)
    var wiped: bool = cleared and String(game.last_clash).begins_with("SQUAD DEFEATED")
    var ally_count: int = game.ally_alive()
    var rival_count: int = game.rival_alive()
    var guardian: bool = game.enemy_is_boss()
    ally_title.text = "YOUR SQUAD   %d / 3" % ally_count
    rival_title.text = "GUARDIAN TRAINER   %d / 3" % rival_count if guardian else "RIVAL TEAM   %d / 3" % rival_count
    screen_labels["EnemyName"].text = "THREE-ON-THREE BATTLE"
    screen_labels["EnemyHp"].text = "%d rivals standing  •  %s HP total" % [rival_count,game.format_number(game.enemy_hp)]
    screen_labels["EncounterHint"].text = ("SQUAD WIPED • RETRY OR FARM AND COUNTER THE RIVAL" if wiped else
        "TRAINER DEFEATED! NEXT STAGE OR FARM" if cleared else
        "YOUR TEAM AUTO-TARGETS ELEMENTAL COUNTERS  •  2x STRONG / 0.45x WEAK")
    screen_labels["FieldStatus"].text = "YOUR SQUAD HP %s / %s   •   STAGE THREAT %.1fx" % [
        game.format_number(game.ward),game.format_number(game.party_max_hp()),game.challenge_multiplier()]
    ward_bar.size.x = 784.0*clampf(game.ward/game.party_max_hp(),0.0,1.0)
    screen_labels["PackDps"].text = ("3 SLOTS • EACH COPY FIGHTS INDEPENDENTLY • MATCHUP DPS "+game.format_number(game.squad_dps()))
    screen_labels["DamageReadout"].text = ("SQUAD DEFEATED • REBUILD YOUR LINEUP" if wiped else
        "TRAINER CLEARED • CHOOSE NEXT" if cleared else
        "ALIVE: %d vs %d  •  TEAM DPS %s" % [ally_count,rival_count,game.format_number(game.squad_dps())])
    if wiped:
        squad_status.text = "RETRY\nOR\nFARM"
    elif cleared:
        squad_status.text = "NEXT\nOR\nFARM"
    else:
        squad_status.text = "VS\n2x COUNTER\n0.45x WEAK"
    if wiped:
        strike_button.text = "RETRY STAGE  ▶"
    for i in range(3):
        var my: Dictionary = game.ally_units[i]
        var foe: Dictionary = game.rival_units[i]
        _update_unit(ally_widgets[i],my,false,i)
        _update_unit(rival_widgets[i],foe,true,i)
        var current: Line2D = target_threads[i]
        var dest: int = int(my.get("target",-1))
        current.visible = not cleared and float(my["hp"]) > 0.0 and dest >= 0
        if current.visible:
            current.default_color = Color(COLORS[String(my["kind"])],0.25)
            current.points = PackedVector2Array([
                Vector2(ALLY_X[i]+95.0,239.0),
                Vector2(439.0,224.0+float(i)*9.0),
                Vector2(RIVAL_X[dest]+4.0,240.0)
            ])
        var original: String = String(CHALLENGE.ORDER[i])
        var current_species: String = String(game.squad_slots[i])
        var owned: bool = int(game.levels[current_species]) > 0
        var level: int = int(game.levels[current_species])
        var genes: int = int(game.gene[current_species])
        card_art[original].texture = _creature_texture(current_species,bool(game.evolved[current_species]),false)
        card_art[original].modulate = Color.WHITE
        screen_labels["Name_"+original].text = "SLOT %d • %s" % [i+1,String(CHALLENGE.SPECIES[current_species]["name"])]
        card_details[original].text = "Lv %d  •  %s DPS\nBOND %d/25  •  GENE %d" % [
            level,game.format_number(game.species_damage(current_species)/game.attack_interval(current_species)),
            int(game.bonds[current_species]),genes]
        card_details[original].tooltip_text = (
            "Levels boost EVERY copy of "+game.species_name(current_species)+
            ". Eggs give permanent Gene damage or new species. Evolution persists across Ascension.")
        var cost: float = game.purchase_cost(current_species,batch)
        card_buy[original].text = "LEVEL x%d • %s G" % [batch,game.format_number(cost)]
        card_buy[original].disabled = not owned or game.gold < cost
        var remaining: float = float(game.ability_clock[current_species])
        card_skill[original].text = String(SKILL_SHORT[current_species]) + ("  %ds" % ceili(remaining) if remaining > 0.0 else " READY")
        card_skill[original].disabled = cleared or float(my["hp"]) <= 0.0 or remaining > 0.0
        focus_buttons[original].text = "SWAP" if game.ORDER.size() > 1 else "LOCKED"
        var available: int = 0
        for kind in CHALLENGE.ORDER:
            if int(game.levels[kind]) > 0:
                available += 1
        focus_buttons[original].disabled = available < 2
    for item in team_art:
        item.visible = false
    enemy_art.visible = false
    focus_caption.visible = false

func _update_unit(visual: Dictionary,unit: Dictionary,enemy: bool,index: int) -> void:
    var kind: String = String(unit["kind"])
    var hp: float = float(unit["hp"])
    var alive: bool = hp > 0.0
    var cap: float = maxf(1.0,float(unit["max_hp"]))
    var art: TextureRect = visual["portrait"]
    art.texture = _creature_texture(kind,enemy and game.enemy_is_boss() or not enemy and bool(game.evolved[kind]),enemy)
    art.modulate = Color("#c0c8c5",0.25) if not alive else (
        Color("#ffc6a0") if float(unit.get("flash",0.0)) > 0.0 else Color.WHITE)
    art.position.y = UNIT_Y+(3.0*sin(animation_clock*1.5+float(index)) if alive else 9.0)
    visual["name"].text = String(CHALLENGE.SPECIES[kind]["evolved" if enemy and game.enemy_is_boss() or not enemy and bool(game.evolved[kind]) else "name"])
    visual["name"].add_theme_color_override("font_color",Color("#778f94") if not alive else COLORS[kind])
    visual["bar"].size.x = (89.0 if enemy else 97.0)*clampf(hp/cap,0.0,1.0)
    visual["bar"].color = CORAL if enemy else GREEN
    visual["hp"].text = "KO" if not alive else "%s / %s HP" % [game.format_number(hp),game.format_number(cap)]
    var target: int = int(unit.get("target",-1))
    if not alive:
        visual["target"].text = "KNOCKED OUT"
    elif target < 0:
        visual["target"].text = "VICTORY"
    else:
        var opponents: Array[Dictionary] = game.ally_units if enemy else game.rival_units
        var target_kind: String = String(opponents[target]["kind"])
        var multi: float = game.multiplier(kind,target_kind)
        visual["target"].text = "→ %s  %sx" % [
            String(CHALLENGE.SPECIES[target_kind]["name"]),str(snappedf(multi,0.05))]
        visual["target"].add_theme_color_override("font_color",GREEN if multi > 1.0 else (CORAL if multi < 1.0 else MUTED))

func _focus(kind: String) -> void:
    if game == null or not game.has_method("cycle_slot"):
        return
    var index: int = CHALLENGE.ORDER.find(kind)
    if game.cycle_slot(index):
        _toast("SLOT %d: %s • SMART TARGETS UPDATED" % [index+1,game.species_name(game.squad_slots[index])])
        game.save()
    _refresh()

func _buy_creature(kind: String) -> void:
    if game == null or not game.has_method("squad_dps"):
        super._buy_creature(kind)
        return
    var index: int = CHALLENGE.ORDER.find(kind)
    if index < 0:
        return
    var member: String = String(game.squad_slots[index])
    var before: float = game.squad_dps()
    if game.buy_levels(member,batch):
        _toast("LEVEL UP: %s • TEAM DPS %s → %s" % [
            game.species_name(member),game.format_number(before),game.format_number(game.squad_dps())])
    _refresh()

func _use_skill(kind: String) -> void:
    if game == null or not game.has_method("squad_dps"):
        super._use_skill(kind)
        return
    var index: int = CHALLENGE.ORDER.find(kind)
    if index >= 0:
        var active: String = String(game.squad_slots[index])
        if game.use_ability(active):
            _toast("%s used %s!" % [game.species_name(active),String(CHALLENGE.ABILITY_NAMES[active])])
    _refresh()

func _switch_tab(next: String) -> void:
    super._switch_tab(next)
    if game == null or not game.has_method("cycle_slot") or sidebar == null:
        return
    if next == "GROW":
        for kind in CHALLENGE.ORDER:
            _sidebar_card("RECRUIT • "+String(CHALLENGE.SPECIES[kind]["name"]),
                "Unlock this species for squad slots. Grove > Tide > Ember > Grove. Copies in your lineup use its level and Gene bonuses.",
                "RECRUIT",_recruit_species.bind(String(kind)),"recruit",String(kind))
        _refresh_sidebar()
    elif next == "WORLD":
        _sidebar_card("Squad AI and Priority",
            "All SIX monsters independently target their best elemental matchup. After a KO they immediately retarget the most efficient living enemy.",
            "GUIDE",_show_first_steps,"information")
        _refresh_sidebar()

func _refresh_sidebar() -> void:
    super._refresh_sidebar()
    if game == null or not game.has_method("cycle_slot"):
        return
    for row in active_rows:
        if String(row["mode"]) != "recruit":
            continue
        var key: String = String(row["key"])
        var button: Button = row["button"]
        var details: Label = row["info"]
        var owned: bool = int(game.levels[key]) > 0
        var price: float = game.purchase_cost(key,1)
        button.text = "OWNED" if owned else game.format_number(price)+" G"
        button.disabled = owned or game.gold < price
        details.text = ("Recruited! Tap SWAP on any squad slot; duplicate species are allowed." if owned
            else "%s element • Recruit for %s Gold. Swap it into a squad slot after purchase." % [
                String(CHALLENGE.SPECIES[key]["element"]),game.format_number(price)])

func _recruit_species(kind: String) -> void:
    if int(game.levels[kind]) == 0 and game.buy_levels(kind,1):
        _toast("%s RECRUITED! USE SWAP TO ENTER THE 3-UNIT SQUAD." % game.species_name(kind))
        game.save()
    _refresh()

func _hatch() -> void:
    super._hatch()
    # An egg may recruit a previously locked species; the roster must show it.
    if tab == "GROW":
        _switch_tab("GROW")
    _refresh()
