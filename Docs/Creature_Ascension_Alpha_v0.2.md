# WILDBOUND — CREATURE ASCENSION ALPHA v0.2
**Game type:** original creature-centric idle/clicker incremental combat and team-optimization game
**Engine:** Godot 4.7.2, GDScript, HTML5 export
**Online:** https://blushark5.github.io/Wildbound/reboot/

## Experience
Three original Wildbound creature families fight endless waves. You can click to attack or idle, recruit teammates with Gold, level them, improve the run with field modules, use manual abilities, farm guardians, hatch earned eggs, discover Relics, level bloodlines and Ascend for permanent Echo research. Rewards and enemy HP scale exponentially.

This is a standalone incremental reboot. No towns, explorable map, capture RPG or world-image tiles are part of its gameplay. The earlier creature RPG is preserved separately on main and develop.

### Pack
- Spriglet / Thornhart: Grove affinity, **Verdant Bloom** heals 42% of max Ward; 25s cooldown.
- Brinlet / Tidemare: Tide affinity, **Tidal Surge** bursts for 6× current pack DPS; 19s cooldown.
- Cindlet / Blazetail: Ember affinity, **Ember Frenzy** boosts all creature damage for 12s; 38s cooldown.
- Grove beats Tide; Tide beats Ember; Ember beats Grove. Build selection matters.
- Evolve at Level 15 and 25 accumulated bond victories.
- Three species, all three original front and evolved illustrations retained.
- Permanent earned egg lineage: duplicates grant +1 gene rank (+6.5% damage/rank); rare Shimmer variant gives +22% damage, with guaranteed rarity by 10 unrewarded hatches.

### Combat / economy
- Continuous auto-attacks with manual tap damage.
- Every tenth wave is a Guardian with higher HP and reward.
- Gold income and enemy health exponential; losing Sanctuary Ward retreats four waves without wiping Gold/upgrades.
- Repeat-wave farming for Gold and bonds.
- Seven temporary field modules: Might, Ward, Speed, Crit, Gold income, Regeneration, Guardian damage.
- Earn Nest Shards from Guardian victories and occasional normal fights; hatch an egg for five shards.
- Guardian kills drop random permanent Relics (first kill guaranteed, subsequent drops ~35% with research bonuses).
- Equip two of six Relics: elemental attack charms, Guardian Sigil, Gold Amulet, Sanctuary Hearthstone. Duplicates increase rank.
- Four selectable expedition regions unlocked by best wave: Meadow 1, Shore 30, Ember Hollow 65, Skyglass Peaks 120. Deeper regions offer Gold multipliers at greater difficulty.
- Optional Overclock doubles enemy HP, raises retaliation and gives 2.4× Gold.
- Manual x1 / x10 / x25 creature purchases, repeat farming and 1x / 2x battle speed.

### Permanent meta-progression
- Ascend starting at wave 20. Resets waves, Gold, temporary creature levels and field modules; earns Echoes.
- Preserves all recruited creatures, their evolutions and bonds, Shimmer status, genes, egg history, Relics and Legacy research.
- Eight permanent research paths: Might, Living Ward, income, speed, nest drops/Echo gain, Shimmer chance, auto-buy, auto-ability casting.
- Earnable milestones for waves, combat, breeding, relics, evolution and Ascensions. Claim Echoes and shards.
- Offline **Gold only** earned for up to 4 hours at deliberately limited efficiency; no fake boss defeats or free Nest Shards.
- Auto-saves every 20 seconds and on key progression decisions.
- Existing v0.1 user://wildbound_incremental_reboot_v1.json save schema is migrated in place. The game's project identity and website path are preserved to maximize browser-save continuity.

### Visual / accessibility
- 1280×720 game view, original illustrated creature artwork, themed three-column layout.
- Always-visible pack and arena. Tabbed right pane: Forge, Nest, Relics, Legacy, Map, Goals.
- Creature action cooldowns, floating hit feedback, HP/Ward bars, boss identity, upgrade availability, color distinctions.
- On-demand Field Guide, confirmation before Ascension, opt-in original chiptune sound and effects.
- Space triggers Strike and Escape pauses combat. Native mouse/touch buttons.

## Validation gates
- Existing v0.1 regression suite runs independently.
- Alpha tests: entry state, wave scaling, challenges, regions, relic drops/equipment/persistence, egg Shimmer pity, creature evolution, Ascension/permanent state, research and auto-buy, milestones, legacy-save upgrade, offline Gold bounds, UI controls and tab initialization.
- Godot headless import/startup, physical rendered 1280×720 screenshot via Xvfb, export-release Web artifact.
- GitHub Pages retains / for the original stable game, /dev/ for the original creature RPG experiment, and /reboot/ for this alpha.
- CI is not a substitute for player-driven browser pacing and user feedback.

## Known alpha limitations
- No dozens of species, multiplayer or large world: three original starter families are the defined alpha roster.
- No sophisticated animations or custom relic/item icons yet; existing original creature sprites are reused.
- Not designed for offline wave progress or unlimited free automated Ascension.
- Browser local save is specific to browser/profile/site data, and can be lost if browser storage is cleared.
- Economy and automation balance still need extended real-player sessions. No payment, ads, paid gacha or commercial store integration.
- The project remains alpha, not a completed storefront release.

## Playtest checklist
1. Open /reboot/, press GUIDE, toggle sound.
2. Recruit Brinlet and Cindlet; test each creature's active skill.
3. Clear first Guardian at wave 10 and verify Relics and Nest Shards.
4. Hatch an egg, equip a Relic, farm with Repeat.
5. Level a creature to 15 with 25 bonds and watch its evolution.
6. Reach wave 20, confirm Ascension; verify evolution, genes and Relics survive and Echoes increase.
7. Unlock Legacy research and toggle automation.
8. Close and reload the webpage. Ensure permanent progress persists and offline Gold accrues without changing wave.
9. Examine all six tabs, scrollable lists, challenging regions and Overclock.
