# Wildbound v0.28 — Play First, Menu Second

## Primary screen
User feedback: prior visuals were still confusing, with too many buttons. v0.28 substantially simplifies the default screen: retain the large 3v3 battle, the three painted creature summaries, a single top MENU toggle, and a primary START/NEXT/RETRY/HELP ATTACK/RESUME button. Farming appears as the only secondary button after Stage 1 is cleared. Creatures auto-attack without input; the one-line battle instruction clearly states that manual attacks are optional. Stage-specific farming awards Gold and Bond XP but not Essence.

Hide all direct Gold purchase, ability, Resonance, speed, optional automation, Field Guide, stage picker, matchups, upgrade, Ascension and Save shortcut buttons from the *main* screen; they all remain available under MENU.

## Menu
MENU opens a clearly organized list of large touch targets with descriptive subtitles:
CREATURES & TRAINING; GOLD UPGRADES; NEST & RELICS; ASCENSION; QUESTS & WORLD; ABILITIES & OPTIONS; SAVES & NEW GAME.

Each section uses the existing functional side drawer, with quick tabs available only after entering it. CREATURES adds three real TRAIN SLOT actions for Gold-based individual levels, including cost and Bond cap. ABILITIES & OPTIONS adds a dedicated subpage for the three existing creature abilities, Resonance and Speed, in addition to Auto-Form, Replay, farming selection, matchups, Chronicle, and font size. All actions connect to the current game engine. New Game and destructive save management still require confirmation.

## Save and testing
No economy/combat changes, no creature artwork changes, no save namespace change. Reuse the v0.25 engine and preserve all existing browser saves and the v0.24 post-Ascension battle recovery.

Validate first-battle gating, obvious screen controls, menu navigation, team training, ability/speed controls, stage victory/farming and Essence integrity, Ascension restart and per-slot migration. Capture six actual 1280×720 Godot screenshots before publishing to the existing /bond/ browser route.
