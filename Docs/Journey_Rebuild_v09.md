# Wildbound v0.9 — Journey-first redesign
User-reported issue: the previous build was visually messy and did not communicate progression or a satisfying play loop. Repeated cosmetic-only passes are not enough.

## Why this is a gameplay redesign
The battle engine already has companions, elemental counters, evolution, eggs, Guardian relics, research, regions, abilities, contracts and Ascension. The old seven-tab interface obscured them. This candidate is a **fresh UI**, not another inherited set of coordinates on top of v0.5–v0.8.

## Clear 30-minute intention
1. Win 3 battles -> claim Gold and permanent damage.
2. Recruit Brinlet -> permanent damage and more Gold.
3. Level Spriglet to 5 -> a meaningful boost.
4. Recruit Cindlet -> full three-creature party.
5. Beat first Guardian at wave 10 -> real Nest Shards and guaranteed Relic, then claim extra Trail rewards.
6. Hatch an egg -> duplicates increase genes; rare pity remains.
7. Evolve a creature by reaching Lv15 and 25 bonds -> persists after Ascension.
8. Reach wave 20 -> unlock the first Ascension.
9. Ascend -> preserve evolution, bonds and permanent unlocks.
10. Reach wave 30 -> open Moonlit Shore.

Milestones are claimable, provide meaningful Gold/Shards/Echoes, and grant a *permanent* stacking 12% pack damage bonus plus 6% Gold bonus. Progress is saved under `v09_trail_rank` in the actual gameplay save. It does not simulate rewards on a separate fake UI.

## Screen architecture
- Left: one legible, illustrated battle stage; three distinct creature cards; primary Strike and Resonance controls.
- Right: one highly visible *Journey* objective with a claim action and four contextual tabs: Grow, Nest, Legacy, World.
- Hide unrecruited side creatures instead of showing empty battlefield placeholders.
- Existing game engine remains the source of truth for all unlocks, combat, prices, prestige and cooldowns.
- Save every 20 seconds, on quest rewards, and on confirmed Ascension.
- Self-contained candidate branch, with a separate web location and browser save namespace.

## Still to validate by human QA
The actual visual hierarchy, mobile landscape legibility, early-game pacing (3 / 10 / 20 / 30 waves), onboarding comprehension, and what it feels like to play. Automated tests check behavior, not enjoyment. Keep prior browser branches unchanged until human approval.
