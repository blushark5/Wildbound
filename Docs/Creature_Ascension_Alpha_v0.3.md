# WILDBOUND — Creature Ascension Alpha v0.3

## Overview
This release iterates on the working incremental game. The main **Clicker Heroes + Perfect Tower style wave-loop** remains, but with more player agency, visual hierarchy and replayable progression. The game runs directly at https://blushark5.github.io/Wildbound/reboot/ and retains the original `user://wildbound_incremental_reboot_v1.json` browser save namespace.

### What is new

**Art and battle readability**
- The battle panel now uses existing original Wildbound arena artwork from the repository, switched automatically by region.
- Large original creature illustrations with subtle idle movement and hit tint.
- Enemy modifiers are named in the active wave HUD, and combat, Ward, Resonance and Gold indicators remain visible.
- A new 12-second purple Resonance burst meter fills via auto victories and manual strikes, activates for 2x pack damage, and is gated until 100%.
- Forge, Nest, Relics, Legacy, Map and Goals each remain accessible from one screen.
- Contextual purchasing tooltips, ready-to-claim Goals highlights, and a Nest badge when enough shards have been collected.
- Existing original audio, optional sound toggle, Field Guide, boss and evolution notifications preserved.

**Tactical play**
- Balanced: standard attack/defense/rewards.
- Feral: +30% creature damage; +20% incoming damage.
- Bulwark: -18% creature damage; -35% incoming damage and faster Ward renewal.
- Forager: -20% creature damage; +40% Gold income and bonus Nest chances.
- Tactics can change at any time and persist in saved game state.

**Enemy encounters**
- Armored elites (wave divisible by 7, non-boss) gain 65% health.
- Frenzied elites (wave divisible by 11) deal 55% increased damage.
- Gilded elites (wave divisible by 13) yield 85% extra Gold.
- Standard guardians still occur every ten waves, offering Shards and collectible Relics.
- Elite visuals appear directly in the wave banner.

**Repeatable field contracts**
- Win 12 + 8 per tier additional battles.
- Defeat 1 + approximately 1 per 3 tiers additional guardians.
- Use 4 + 2 per tier creature abilities.
- Earn Gold and Nest Shards, plus occasional Echoes. Objectives scale after claiming rather than ending at finite milestone counts.
- Contracts persist through Ascension; stage and current progress tracked independently.
- Existing one-time milestone rewards remain in the Goals tab.

**Permanent Camp**
- Nest Expansion: +8% earned Nest drop chance per rank.
- Pack Lodgings: +10% creature damage per rank.
- Echo Altar: +8% Echoes from Ascensions per rank.
- Build with earned Nest Shards. No premium currency and no payments.
- Camp upgrades survive Ascension and browser reload.

**Existing full alpha systems retained**
- Three original creature families and illustrated evolutions, distinct abilities, elemental strengths/weaknesses.
- Gold-based recruitment and levels, seven temporary field upgrades, repeat farming, 2x speed.
- Earn-only egg hatchery with rare Shimmer pity and genetic ranks.
- Six permanent Relics, two equipment slots and duplicate ranks.
- Four regions, Overclock challenge and permanent Echo research.
- Automation research, offline Gold capped to four hours, separate game save.
- Ascension from wave 20 onward, preserving roster, evolution, relics and research.

### Compatibility
Alpha v0.3 is implemented as a subclass of the previous `alpha_engine.gd`, with additive fields in the same save JSON. v0.1/v0.2 saves load with Balanced stance, 0 Resonance, no Camps and fresh contracts. Evolved creatures, collection, research and completed goals remain. Do not rename the Godot project, change the save filename or use a different web path during this upgrade.

### Tests and QA
- Existing v0.1 and v0.2 progression/save/UI tests.
- Added v0.3 regression checks for tactics, Resonance gates and duration, elite enemies, 3 repeatable contracts, camp construction, Ascension preservation, browser save reload and v0.2 migration, UI buttons and tab content.
- 1280×720 screenshot captured by an actual Godot renderer under Xvfb, not generated mock art.
- GitHub Actions browser export and Pages deployment. Human browser playtesting and longer-term economy balance remain ongoing.

### Limitations
This is a substantive playable alpha, not a storefront-ready commercial title. In particular, there are three original playable creature species (not hundreds), only one main combat presentation, relatively simple animation/VFX, and no multiplayer or monetization. We should deepen and polish the systems supported by the existing art library before multiplying species or adding a world.
