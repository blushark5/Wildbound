# WILDBOUND — Creature Ascension Alpha v0.4

## Release identity
Web: https://blushark5.github.io/Wildbound/reboot/
Godot: 4.7.2
The original GBA creature RPG remains on main and develop, with the incremental reboot isolated on its feature branch. This release retains the preexisting browser save location and Godot project identity for backward compatibility.

## Gameplay additions
### Permanent creature specializations
After evolution and 25 accumulated bond victories, each creature selects one permanent mastery. A first selection is free; a replacement costs 12 earned Nest Shards.

- Spriglet / Thornhart: **Briarheart** (+40% personal damage, extra critical damage) or **Lifebloom** (+30% maximum Ward, enhanced healing ability).
- Brinlet / Tidemare: **Riptide** (+32% personal damage and 35% stronger burst ability) or **Harborkeeper** (+15% Gold and maximum Ward).
- Cindlet / Blazetail: **Inferno** (+50% personal damage versus guardians) or **Swiftflame** (faster attacks and 4 extra Frenzy seconds).
- These masteries persist through Ascension, including after browser reload. Six cards appear on the PACK tab.

### Manual combo
Consecutive STRIKE actions inside a 1.4-second window increment a multiplier by 4% per consecutive click (capped to 25 earned bonus stacks), without making automatic battles require manual actions. The longest combo is tracked.

### Guardian Fury
Guardian enemies enrage after 18 seconds, increasing incoming damage by 50% for the remainder of the fight. UI warns with a Fury countdown and active indicator. Encounter timers reset on a new wave or retreat.

### Earned choice rewards
Every 25 newly completed waves awards a **Wild Cache**, never repeated infinitely by farming. In Goals, players select:
- Golden Cache: wave-scaled immediate Gold.
- Nest Cache: earned permanent Nest Shards.
- Battle Cache: stacking +12% creature damage until next Ascension.
Unclaimed caches persist through Ascension, while temporary Battle bonuses reset. Cache history is persisted and exploit-checked.

## Interface and visual polish
- 7 tabs: FORGE, NEST, PACK, RELICS, LEGACY, MAP and GOALS.
- Full 1280 × 720 interface keeps the team's original pixel-art sprites and illustrated regional arenas.
- Guardian Fury indicator, manual combo counter, subtle optional hit shake.
- Contextual progression hints guiding recruitment, Ascension, earned caches and mastery unlocks.
- Compact Gold/Echo/Shards/Ascension header, contextual tooltips and ready-to-claim tab highlights.
- Options menu for reduced motion, preserved across reloads.
- Smaller-browser-window scaling changed from integer-only to fractional.
- No crude geometric substitute creatures or environments were introduced.

## Systems retained from earlier alphas
Three original creature families, turnless auto-battles with manual assistance, affinities, species abilities, seven run Forge upgrades, 4 tactical formations, Wild Resonance burst, exponential enemy and income scaling, elite monsters, 4 zones, Overclock, repeat farming, rare Shimmer eggs with pity, 6 permanent Relics (2 slots), 3 permanent Camp buildings, 8 Echo research paths, automation, repeatable contracts, one-time milestones, offline Gold and prestige.

## Save, source, validation
- v0.4 lives in scripts/incremental/v04_engine.gd, inheriting stable v0.3 logic.
- Adds only v04 schema fields; legacy v0.1-v0.3 saves load without losing creatures, research, items, shards, old milestones or Ascensions.
- Existing stable and /dev/ websites are preserved.
- Dedicated v0.4 tests cover mastery gating, mastery respec costs and permanence, combo timing, Guardian Fury, earned Wild Caches, repeat-farming prevention, choice rewards, Ascension persistence and legacy save import.
- Existing v0.1, v0.2 and v0.3 automated tests remain part of GitHub Actions.
- Actual Godot/Xvfb screenshot, startup and HTML5 export checks supplement but do not replace manual browser gameplay.

## Scope / follow-up priorities
This is a substantive playable alpha, NOT a finished commercial or mobile product. Next refinements should emphasize extended human playtests for economy pacing, custom monster animation and sound, additional fully authored species art, better battle encounter identity, prestige build presets and accessible browser/mobile UI. No paid gacha or premium currency is included.
