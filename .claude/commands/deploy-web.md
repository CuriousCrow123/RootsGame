Deploy the Godot web export to GitHub Pages.

## Steps

1. Verify `export/web/` contains a recent export with at minimum: `index.html`, `index.js`, `index.wasm`, `index.pck`. If any are missing, tell the user to re-export from Godot first and stop.

2. Stash any uncommitted changes on the current branch:
   ```bash
   git stash --include-untracked
   ```

3. Record the current branch name so we can return to it later.

4. Switch to the `gh-pages` branch:
   ```bash
   git checkout gh-pages
   ```

5. Remove old deploy files from the repo root (index.*, *.worklet.js, *.png, *.import) and copy the fresh export files:
   ```bash
   rm -f index.* *.worklet.js
   cp export/web/index.* export/web/*.worklet.js .
   ```

6. Stage, commit, and push:
   ```bash
   git add -A
   git commit -m "Deploy web export"
   git push origin gh-pages
   ```

7. Switch back to the original branch and restore stashed changes:
   ```bash
   git checkout <original-branch>
   git stash pop
   ```

8. Confirm to the user that the deploy is complete and the game will be live at https://curiouscrow123.github.io/RootsGame/ within 1-2 minutes.
