# Wildbound: First Steps — Web-ready Godot project

**Baseline:** The playtested, GBA-style **First Steps v0.2** game, with web deployment support. This is *not* a release of the previously discussed v0.3 music/VFX changes. The original game content and save key are preserved.

## Play in a browser (one-time setup)

1. Extract this ZIP to a permanent folder, for example `Documents\Wildbound`.
2. Open **GitHub Desktop**. Choose **File → Add local repository → Choose** that folder. If prompted, select **Create a repository here**, then commit the initial files.
3. Click **Publish repository** with name **`Wildbound`** and **uncheck** **Keep this code private** (public GitHub Pages hosting on GitHub Free). Don't accidentally publish into the Veilbreak repository.
4. Open the new repo on GitHub. Navigate to **Settings → Pages → Build and deployment → Source → GitHub Actions**.
5. Check the repository **Actions** tab for the `Build and publish Wildbound Web` run. Once successful, the address is `https://blushark5.github.io/Wildbound/` if you used that exact owner and repo name.
6. Future changes pushed to `main` rebuild that page automatically. If you add a `develop` branch, pushes to either branch update the stable site and a preview at `/Wildbound/dev/`.

If you prefer, create an empty **public** `Wildbound` repository at github.com/new and use GitHub Desktop to initialize the local folder and push it there.

**Note:** The site link above is a *target*, not live until GitHub Pages deploys successfully. The automated workflow uses Godot 4.7.2, matches your local engine, and exports a single-threaded Web build (no cross-origin isolation configuration needed).

## Current limitations

- This prototype still uses **keyboard-based overworld movement**. Browser testing on desktop is the first goal; mobile touch controls are a subsequent task.
- The browser saves to its own local storage. These saves don't sync between browsers, devices, or incognito sessions. Keep the same origin and path (`/Wildbound/`) for stable builds. The preview build uses a separate save filename (`wildbound_first_steps_preview_v0_1.json`) to avoid overwriting your stable playthrough.
- Web pages cannot programmatically close a browser tab: title-screen Exit and pause-menu Save & Exit are suppressed in web builds. Use Save & Title or close the tab.
- First Steps v0.3 planned presentation/audio polish has *not yet been merged*. No new gameplay has been introduced as part of hosting setup.
- If export fails, open **Actions → failed run → Import or Export step** for errors. Source integrity and GitHub Actions config were prepared here; a real hosted run is necessary to verify the final web export.

## Controls (desktop browser)

- WASD / arrows: move
- E / Enter / Space: interact
- Tab: team
- Esc: pause
- Battle: click buttons and use Next where shown

## Branch policy

- `main`: tested stable version. Changes deploy to the root URL.
- `develop`: optional experimental version. Changes deploy to `/dev/`, without replacing stable.
- Promote a proven preview by merging `develop` into `main` using GitHub Desktop or a pull request.

## Rights and independence

This is an original creature-RPG prototype inspired by the *genre conventions* of classic GBA role-playing games. No Pokémon ROM, Nintendo assets, or decompiled code is included.
