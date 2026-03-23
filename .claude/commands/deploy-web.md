Deploy the Godot web export to GitHub Pages.

## Steps

1. Verify `export/web/` contains a recent export with at minimum: `index.html`, `index.js`, `index.wasm`, `index.pck`. If any are missing, tell the user to re-export from Godot first and stop.

2. Copy export files to a temp dir **before any branch switching** (gh-pages tracks `export/web/` and will overwrite the fresh export):
   ```bash
   DEPLOY_TMP=$(mktemp -d)
   cp export/web/index.* export/web/*.worklet.js "$DEPLOY_TMP/"
   ```
   Save `DEPLOY_TMP` path for later steps.

3. Stash any uncommitted changes on the current branch:
   ```bash
   git stash --include-untracked
   ```

4. Record the current branch name so we can return to it later.

5. Switch to the `gh-pages` branch:
   ```bash
   git checkout gh-pages
   ```

6. Remove old deploy files from the repo root:
   ```bash
   rm -f index.* *.worklet.js
   ```

7. Copy fresh files from temp dir (use the saved `DEPLOY_TMP` path):
   ```bash
   cp "$DEPLOY_TMP"/index.* "$DEPLOY_TMP"/*.worklet.js .
   ```
   Then clean up the temp dir:
   ```bash
   rm -r "$DEPLOY_TMP"
   ```

8. Stage, commit, and push:
   ```bash
   git add -A
   git commit -m "Deploy web export"
   git push origin gh-pages
   ```

9. Switch back to the original branch. If checkout fails due to `.obsidian/workspace.json` or similar untracked conflicts, stash on gh-pages first, then checkout, then drop that stash:
   ```bash
   git checkout <original-branch>
   git stash pop
   ```

10. Confirm to the user that the deploy is complete and the game will be live at https://curiouscrow123.github.io/RootsGame/ within 1-2 minutes.
