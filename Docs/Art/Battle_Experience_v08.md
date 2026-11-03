# Wildbound v0.8 — Battle Experience Pass

This is the next review candidate atop the v0.7 illustrated game. It retains the existing creature economy, evolution, Prestige/Ascension, 7 Sanctuary tabs, local browser saves, optional automation, and ten-wave Guardian cycle.

## Implemented
- Ten-step Guardian progress indicator, tied to current wave and boss encounter.
- Dynamic threat readout, party count, streak, farming state, and visible Fury countdown.
- Three-column Sanctuary tabs with larger touch targets and scrollable progression cards.
- Battle effects reanchored to the real 704×332 stage, with per-element ambiance and Guardian/Resonance/hit cues.
- Contrast and tactical framing polish; real independent battle sprites preserved.
- Keyboard shortcuts: Space strike; 1/2/3 pack abilities; R Resonance; Q next Sanctuary tab; B purchase batch; F repeat/farm; P pause; S save.
- New headless gameplay test and genuine 1280×720 rendered screenshots for QA.

## Release discipline
- New branch only until full CI passes and genuine screenshots are reviewed.
- The older /reboot/ game and root RPG remain unmodified.
- Browser saves still live locally and do not sync between devices.
- Touch layouts and creature animation frames still need dedicated on-device visual and interaction QA.
