# Wildbound v0.27 — Unified Right-side Navigation

In response to playtesting feedback, v0.27 replaces mixed full-screen menus and large modal windows with **one consistent side drawer whose tabs are at the top**. The living 3v3 battle remains in view behind the side panel.

Top tabs: **TEAM / GOLD / NEST / ASCEND / WORLD / TOOLS / SAVE**.

- TEAM: field guide is now a **scrollable, element-grouped collection in the side drawer**. View all 12 painted creatures; select slot 1, 2 or 3; Equip or Swap any owned creature; hatch with first-ever-clear Essence; save/load 3 squad presets. The previous enormous fullscreen Field Guide is not used. The top TEAM section is used for first-time onboarding.
- GOLD, NEST, ASCEND: the existing real upgrade cards, eggs/relics, and permanent Echo research are shown in the same side drawer, not separate screens. Full gameplay/cost code remains unchanged. Existing x1/x10/x25/MAX is retained.
- WORLD: the Journey and functioning CLAIM reward action live here, above the existing world cards. Journey is no longer constantly displayed while shopping.
- TOOLS: Auto-Form, Replay Route, farm-stage selection, elemental matchups, Ascension Chronicle and larger-text controls are all integrated *inside* the drawer. Farming still awards no Essence; choosing a previously cleared stage retains the original winner behavior.
- SAVE: all three independent browser slots, Save Now, New Game and Delete actions appear in the same drawer. Destructive actions still show a confirmation. Switching slots creates the latest engine and returns to battle.
- Header Ascend and Save shortcuts navigate to the respective drawer tabs.

Opening a section requires at most one tap from battle. Switching tabs doesn't repeatedly open/close large windows. The drawer has a prominent CLOSE to return to the full-width battle.

Existing saving, creature art, progression, Stage 20 first Ascension, random enemies, manual squad overrides, auto-form cutoff, Replay, Gold and Essence economy and corrected post-Ascension combat resume remain unchanged.

Tests: `tests/check_side_navigation_v27.gd` and real Godot screenshot capture `tests/capture_side_navigation_v27.gd`, plus all v0.15–v0.26 tests. Publishing uses the existing GitHub Pages `/bond/` route.
