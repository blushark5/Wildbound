# Wildbound v0.11 — Living Three-on-Three Trainer Battles

**Gameplay premise:** both teams field three live creatures. Every creature has separate HP and attack timing and independently aims at the highest-effective-damage living enemy. A knockout triggers immediate retargeting for all surviving monsters.

**Elemental circle:** Grove beats Tide, Tide beats Ember, Ember beats Grove. Advantage 2.0x, disadvantage 0.45x. The first trainer's three Brinlets are ideal victims for the default three Spriglets. The third trainer's all-Cindlet squad becomes the first serious counter-wall. This encourages recruiting Brinlet and swapping a squad slot. Mixed compositions generate natural split targeting without scripted attacks.

**Squad building:** three active slots. Each can be set to any recruited species, including duplicates. During this *prototype* slots represent species copies, not individually captured Pokémon-like monsters. Each species' existing levels, genes, evolution, abilities and equipment affect all copies in that squad. The GROW tab provides the missing Recruit controls; SWAP on each active slot cycles through recruited species. A slot change forfeits/restarts the current encounter. Eggs still improve permanent species genes/rare variants or recruit a missing species.

**Encounter loop:** beat all three opposing creatures for one Gold and Bond reward, then select NEXT STAGE or FARM. Surviving fighters still fight and retarget if teammates fall. A squad wipe leaves the player at the failed trainer with RETRY or FARM, rather than automatically losing several stages. Guardian trainers field three evolved rivals; defeating the squad grants one Guardian-level reward. Auto progression still unlocks only after first Ascension.

**Engineering:** v0.11 overrides the original single-HP battle simulator rather than running two simulations in parallel. Legacy systems (Gold, genes, Ward, Nest, research, achievements, Guardian drops, Ascensions and save) remain inherited from v0.10. Dynamic target selection depends on living enemy species and health fraction. Screenshot tests verify actual Godot rendering.

**QA:** unit target mapping, mono-Grove vs mono-Tide damage advantage, mono-Grove vs mono-Ember early difficulty wall, mixed-squad split targeting, no phantom rewards per individual knockout, explicit next-stage gate, swap and saved squad state, and exported browser images.

**Deliverable:** isolated preview at `/squads/` with a separate save from `/challenge/`. Retain earlier versions until a human playtest confirms fun/pacing.
