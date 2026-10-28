# Deployment checklist and troubleshooting

- The GitHub Actions workflow is `.github/workflows/deploy.yml`.
- Engine pinned to Godot **4.7.2**, no C#, single-threaded Web target.
- First Pages deployment requires repository Settings → Pages → Source: GitHub Actions.
- GitHub repo must be **public** for GitHub Pages on the Free plan.
- The workflow automatically publishes stable from `main`. Optional `develop` publishes to the `/dev/` subfolder on the same site. It rebuilds both on a change to either branch, avoiding destructive competing Pages deployments.
- If you see `index.wasm not found`, inspect whether the export actually ran and uploaded all generated assets; don't commit the generated HTML/WASM into the Godot source repository.
- Godot `user://` browser saves use browser site storage; clearing site data may delete the save. Desktop saves are a separate storage location.
- GitHub Actions needs Actions enabled. Deployment permissions are explicitly granted by this workflow (`pages: write`, `id-token: write`).
- Important: the browser build is currently desktop-playable; full touch controls and audio-resume on mobile remain later tasks.
- For fast future updates, edit and push to `develop`, test at `/Wildbound/dev/`, and merge into `main` after approval.
