extends "res://scripts/incremental/visual_ui_v13.gd"
## v0.14: individual Bond Ranks, honest context-sensitive battle action
## and expressive sprite frames/attack effects while preserving visual shell.
const BOND_ENGINE = preload("res://scripts/incremental/bond_engine_v14.gd")
const SPRITE_RIG = preload("res://scripts/incremental/sprite_frames_v14.gd")
const SPARKS = {
    "Earth":preload("res://assets/incremental/v14/fx_earth.svg"),
    "Water":preload("res://assets/incremental/v14/fx_water.svg"),
    "Fire":preload("res://assets/incremental/v14/fx_fire.svg"),
    "Air":preload("res://assets/incremental/v14/fx_air.svg")
}
var sprite_ready: bool = false
var battle_sparks: Array[TextureRect] = []
var ally_base: Array[Vector2] = []
var rival_base: Array[Vector2] = []
var last_owned_count: int = 1

func _ready() -> void:
    super._ready()
    game = BOND_ENGINE.new()
    game.initialize_alpha()
    game.load_save()
    game.notice.connect(_on_notice)
    last_kills = game.kills
    last_guardian = game.last_boss_wave
    _install_sprite_stage()
    sprite_ready = true
    _switch_tab("GROW")
    _refresh()

func _install_sprite_stage() -> void:
    for i in range(3):
        var left: TextureRect = ally_widgets[i]["portrait"]
        var right: TextureRect = rival_widgets[i]["portrait"]
        left.pivot_offset = left.size*0.5
        right.pivot_offset = right.size*0.5
        ally_base.append(Vector2(ALLY_X[i],217))
        rival_base.append(Vector2(RIVAL_X[i],217))
        for enemy in [false,true]:
            var x: float = RIVAL_X[i] if enemy else ALLY_X[i]
            var fx: TextureRect = _texture("CombatSpark_%s_%d" % ["Enemy" if enemy else "Ally",i],
                Rect2(x+44,212,59,61),SPARKS["Earth"])
            fx.pivot_offset = Vector2(30,30)
            fx.visible = false
            fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
            battle_sparks.append(fx)
        var ckey: String = String(CHALLENGE.ORDER[i])
        card_buy[ckey].tooltip_text = "Spend Gold on this creature's current run level, only up to its permanent Bond Rank cap. General upgrades can still grow after that cap."
        card_details[ckey].tooltip_text = "Bond XP grows from real trainer victories. Ascension raises this creature's Bond Rank and its future level cap once XP is sufficient."
        card_art[ckey].pivot_offset = card_art[ckey].size*0.5
    strike_button.tooltip_text = "During a live fight this is an optional manual ASSIST ATTACK. After a trainer is defeated it becomes NEXT STAGE. A loss changes it to RETRY."
    strike_button.add_theme_font_size_override("font_size",17)
    screen_labels["PackHeader"].text = "YOUR PARTNERS"
    screen_labels["Tagline"].text = "COLLECT • BOND • ASCEND • GROW"
    _toast("WIN TO GAIN BOND XP • ASCEND TO RAISE LEVEL CAPS")

func _creature_texture(kind: String,evolved: bool,is_enemy: bool) -> Texture2D:
    if kind == "":
        return null
    var active: bool = false
    if game != null and game.has_method("unit_bond_rank"):
        var fighters: Array[Dictionary] = game.rival_units if is_enemy else game.ally_units
        for unit in fighters:
            if String(unit["kind"]) == kind and float(unit.get("action",0.0)) > 0.065:
                active = true
                break
    return SPRITE_RIG.creature(kind,evolved,active)

func _process(delta: float) -> void:
    super._process(delta)
    if sprite_ready and game != null:
        _animate_fighters()

func _animate_fighters() -> void:
    for i in range(3):
        for enemy in [false,true]:
            var visual: Dictionary = rival_widgets[i] if enemy else ally_widgets[i]
            var unit: Dictionary = game.rival_units[i] if enemy else game.ally_units[i]
            var art: TextureRect = visual["portrait"]
            var base: Vector2 = rival_base[i] if enemy else ally_base[i]
            var kind: String = String(unit.get("kind",""))
            var flare: TextureRect = battle_sparks[i*2+(1 if enemy else 0)]
            if kind == "":
                flare.visible = false
                continue
            var active: float = float(unit.get("action",0.0))
            var hit: float = float(unit.get("flash",0.0))
            var alive: bool = float(unit["hp"]) > 0.0
            var pulse: float = clampf(active/0.26,0.0,1.0)
            var jolt: float = sin(animation_clock*57.0)*hit*17.0
            var lunge: float = sin(pulse*PI)*17.0*( -1.0 if enemy else 1.0)
            art.position.x = base.x+lunge+jolt
            art.position.y = base.y+(
                -6.0*sin(pulse*PI) if active > 0.0 else
                3.0*sin(animation_clock*1.75+float(i)*1.8+(0.9 if enemy else 0.0)))
            art.rotation = (-0.10 if enemy else 0.10)*pulse if alive else (0.44 if enemy else -0.44)
            art.scale = (Vector2(1.0+0.12*pulse,1.0-0.09*pulse) if alive else Vector2(0.74,0.74))
            art.modulate = (Color("#90a8b2",0.18) if not alive else
                Color("#fff3cf") if hit > 0.06 else Color.WHITE)
            var evolved: bool = game.enemy_is_boss() if enemy else game.unit_evolved(kind)
            art.texture = SPRITE_RIG.creature(kind,evolved,active > 0.045)
            var element: String = String(BOND_ENGINE.CATALOG[kind]["element"])
            flare.texture = SPARKS[element]
            flare.visible = alive and active > 0.025
            if flare.visible:
                flare.position = Vector2(base.x+(-21 if enemy else 72)+lunge,base.y+16+sin(animation_clock*22.0)*4.0)
                flare.rotation = animation_clock*2.9*( -1.0 if enemy else 1.0)
                flare.scale = Vector2.ONE*(0.75+0.55*sin(pulse*PI))
                flare.modulate.a = clampf(active*4.0,0.0,0.85)
    for i in range(3):
        var key: String = String(CHALLENGE.ORDER[i])
        var card: TextureRect = card_art[key]
        card.position.y = 467+1.3*sin(animation_clock*1.5+float(i)*2.1)

func _show_first_steps() -> void:
    if not is_inside_tree() or not is_instance_valid(guide_dialog):
        return
    guide_dialog.title = "Wildbound • Bond Mastery"
    guide_dialog.dialog_text = (
        "GOLD has two uses: upgrade an individual creature's level, or invest in GENERAL RUN UPGRADES for your whole team. General upgrades have no Bond cap.\n\n"
        +"Your creature's BOND RANK controls its level ceiling. Rank 1 allows level 8; each higher rank increases the ceiling by 5 levels. Battle victories earn permanent Bond XP, but they DO NOT automatically raise Bond Rank.\n\n"
        +"Ascend after reaching stage 20: an individual with enough Bond XP gains one permanent Bond Rank. Your level and Gold purchases reset, but your new ceiling survives. More Rank = higher damage potential on later runs.\n\n"
        +"Creatures need level 15 and 25 lifetime Bond victories to evolve. Their evolved form, trait and Genes remain yours forever. Hatching new unique creatures still costs only Essence.\n\n"
        +"In the battle, creatures attack automatically. ASSIST ATTACK gives you optional manual damage. After victory the main button becomes NEXT STAGE; after defeat it becomes RETRY. Farming is still your choice."
    )
    guide_dialog.popup_centered_ratio(0.77)

func _switch_tab(next: String) -> void:
    super._switch_tab(next)
    if not sprite_ready or next != "GROW":
        return
    _sidebar_card("BOND-RANKED TRAINING",
        "Creature levels are limited by permanent Bond Rank. Win battles for Bond XP; Ascend to raise the level cap. General Gold upgrades remain uncapped.",
        "GUIDE",_show_first_steps,"tutorial")
    sidebar.move_child(sidebar.get_child(sidebar.get_child_count()-1),0)
    _polish_sidebar_rows()

func _refresh() -> void:
    super._refresh()
    if not sprite_ready or game == null or not game.has_method("unit_bond_rank"):
        return
    var lost: bool = game.awaiting_next and String(game.last_clash).begins_with("SQUAD DEFEATED")
    if game.awaiting_next:
        strike_button.text = "RETRY TRAINER  ↻" if lost else "ENTER NEXT STAGE  ▶"
    else:
        strike_button.text = "ASSIST ATTACK  •  SPACE"
    strike_button.disabled = not playing
    screen_labels["PackDps"].text = "BOND-RANKED PARTNERS  •  %d / 3" % game.occupied_slots()
    for i in range(3):
        var key: String = String(game.squad_slots[i])
        if key == "" or not game.has_instance(key):
            continue
        var ckey: String = String(CHALLENGE.ORDER[i])
        var cap: int = game.bond_level_cap(key)
        var level: int = game.unit_level(key)
        var rank: int = game.unit_bond_rank(key)
        var xp: int = game.unit_bond(key)
        var goal: int = game.next_bond_goal(key)
        var element: String = String(BOND_ENGINE.CATALOG[key]["element"])
        var individual_trait: String = game.unit_trait(key).to_upper()
        card_details[ckey].text = "Lv %d / %d • %s\nBOND %d • XP %d/%d" % [
            level,cap,element,rank,xp,goal]
        card_details[ckey].tooltip_text = (
            "%s trait • %d Genes. Win trainer battles to build Bond XP. At Ascension, %d XP promotes Bond Rank %d to %d and raises the future level cap to %d." % [
                individual_trait,game.unit_gene(key),goal,rank,rank+1,cap+5])
        var remaining: int = game.level_batch_available(key,batch)
        var price: float = game.creature_level_price(key,batch)
        if remaining == 0:
            card_buy[ckey].text = "BOND CAP • LV %d" % cap
            card_buy[ckey].disabled = true
        else:
            card_buy[ckey].text = "LV +%d • %s G" % [remaining,game.format_number(price)]
            card_buy[ckey].disabled = game.gold < price
        var track: ColorRect = get_node("BondFill_"+str(i))
        track.size.x = 132.0*game.bond_progress(key)
        track.tooltip_text = "%d / %d Bond XP toward next permanent Ascension rank" % [xp,goal]

func _refresh_codex() -> void:
    super._refresh_codex()
    if not sprite_ready or game == null or not game.has_method("unit_bond_rank"):
        return
    for kind in codex_cards:
        var entry: Dictionary = codex_cards[kind]
        var owned: bool = game.has_instance(String(kind))
        var img: TextureRect = entry["picture"]
        img.texture = SPRITE_RIG.creature(String(kind),game.unit_evolved(String(kind)) if owned else false)
        if not owned:
            continue
        var name: Label = entry["name"]
        var trait_label: Label = entry["trait"]
        var status: Label = entry["status"]
        name.add_theme_font_size_override("font_size",14)
        trait_label.text = "%s  •  LV %d/%d" % [
            game.unit_trait(String(kind)).to_upper(),game.unit_level(String(kind)),game.bond_level_cap(String(kind))]
        var slot: int = game.squad_slots.find(String(kind))
        status.text = "BOND %d  •  %s" % [
            game.unit_bond_rank(String(kind)),"SQUAD "+str(slot+1) if slot >= 0 else "COLLECTION"]
