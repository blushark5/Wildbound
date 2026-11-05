# Wildbound v0.15 — creature illustrations, Essence pacing and farm control

- Original Spriglet, Brinlet and Cindlet families now have illustrated 192px idle, attack, evolved idle and evolved attack frames. The nine newer species' v0.14 frames remain unchanged; all twelve families share the same sprite rig.
- Essence wallet has **no fixed cap**, but Essence is awarded only on the first-ever clear of a stage number: **1** for ordinary stages, **4** for Guardians. Farming, repeating and stages already beaten in previous Ascensions give **0** Essence. Gold and Bond XP still accrue on farming runs.
- The permanently saved best-stage watermark identifies first clears without changing the v0.14 save schema.
- The action control now says **FARM STAGE N** while pushing or **RESUME PUSH** while farming. It takes players to their most recently cleared stage even during a live wall, and the arena HUD labels the active mode and currency rewards.
- Continue playtesting the same **/bond/** URL with the same save identity. No changes to the stable root game or older preview saves.
- CI checks `tests/check_iteration_v15.gd` alongside v0.14 and previous regression tests, and validates the new artwork is included in the Web pack.
