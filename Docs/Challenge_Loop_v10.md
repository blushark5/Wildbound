# Wildbound v0.10: Challenge, Choice, and Creature Purpose

This is a systems redesign in response to the v0.9 playtest, not a cosmetic pass. Manual NEXT STAGE replaces automatic advancement. FARM replays the cleared wave for Gold and Bonds. AUTO ADVANCE unlocks only after the first Ascension, and starts OFF.

Difficulty compounds sharply starting at stage 4; Guardians remain every 10 stages. A defeat requires adapting the build rather than repeating an identical easy wave.

The new selectable FOCUS leader deals 1.85x damage, while supporting creatures deal 0.60x. Elemental counterplay uses Grove > Tide > Ember > Grove, with 1.5x super-effective damage or 0.75x resisted damage.

The visible interface reports actual matchup DPS and the need for upgrades: creature levels scale attacks by 19%, genes from duplicate eggs add permanent 6.5% damage each, rare Shimmer adds 22%, and evolution adds 2.8x base damage after Lv15 and 25 Bonds. Guardian battles grant Nest Shards and relics, while 5-shard eggs improve collection or lasting genes. Ascension preserves lasting gains.

Web export explicitly packs bestiary WebP base64 atlases, with original PNG fallbacks if texture decode fails. The CI validates both native play and exported PCK asset paths and renders authentic screenshots.

Deliver as an isolated browser preview /challenge/ without overwriting /journey/, /next/, /visual/, /reboot/, or the original game. Await actual playtest confirmation before promotion.
