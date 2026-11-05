# Wildbound v0.14 — Living Creature Sprites & Bond Mastery

## Economics clarification
**Gold is for two kinds of run power:** (1) creature-specific levels and (2) general modules that affect everyone. Both Gold investments reset when Ascending. **Essence still only acquires new unique creatures** and is not spent on power. This distinction is unchanged.

### New Bond Rank: a permanent training ceiling
Before v0.14, each active creature earned +1 lifetime Bond per defeated trainer and kept Bond and evolution at Ascension. Bond had *no level cap* and was not earned exclusively from prestige.

Now those battle-earned victories become **Bond XP**. A newly hatched creature starts at **Bond Rank I**, which permits **level 8** during a run. Leveling past the ceiling is forbidden even if Gold is available. At **Ascension**, any owned individual with sufficient lifetime XP promotes one Bond Rank permanently, raising its level ceiling by 5. One Ascension can grant at most one rank per creature; the new rank persists in saves. General run modules remain uncapped. A multi-level purchase stops at the current ceiling, charging only the actual levels bought. Automated spending favors real general upgrades rather than trying to buy impossible creature levels.

- Rank I: max creature level 8; promotion requires 8 lifetime trainer victories with that individual.
- Rank II: level 13; next promotion requires 20 lifetime trainer victories.
- Rank III: level 18; next promotion requires 35 lifetime trainer victories.
- Further ranks continue with increasingly costly lifetime experience thresholds. A creature can evolve at level 15 + 25 Bond victories; this now generally requires at least two Ascensions.
- Ascension remains available after reaching stage 20. The old level-15 onboarding objective is replaced by **First Bond Mastery: level 8**, so the player isn't given an unavailable quest before two Ascensions.
- Hatching, Essence cost and the original 12 owned individuals remain unchanged.

## New original creature sprite art
- 9 newer species (Pebblit, Mossling, Driplet, Tidefin, Ashcub, Emberlyn, Zephlet, Gustling, Skyray) now have **4 distinctive 192px illustrated frames each**: normal idle, normal attack, evolved idle and evolved attack. Includes species-specific shading/markings, elemental crests on evolution and attack energy effects.
- Preserve the approved illustrated v0.7 sprites for Spriglet, Brinlet and Cindlet (including evolutions); give all 12 creatures actual in-engine animated movement, attack lunges, hit reactions and visible KO postures.
- Combat includes a new original elemental FX sprite for Earth, Water, Fire and Air; each of six fighters triggers the correct effect on its own attack.
- Field Guide and battle portraits use the upgraded art, with individual Bond Rank, level cap and current level displayed in the cards.

## Context-correct battle primary action
- During auto battle: **ASSIST ATTACK • SPACE** (optional manual attack, not leveling or stage progression)
- After a trainer win: **ENTER NEXT STAGE**
- After wipe: **RETRY TRAINER**
- Farm, auto-unlock, Gold module purchase, hatch and Assign actions stay unchanged.

## QA / release
Keep v0.13 at /world/. Validate engine-level cap, Gold spending after cap, battle XP vs prestige-only rank, multi-buy partial purchase, save, original sprites, 36 unique variant frames, 6 live effects, contextual button, and previous 0.1–0.13 regression. Render five actual 1280x720 Godot screenshots. Ship independent /bond/ browser preview with isolated save.
