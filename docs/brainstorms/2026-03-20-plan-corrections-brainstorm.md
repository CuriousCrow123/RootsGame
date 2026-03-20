# Plan Corrections: Remaining Assumption Errors (2026-03-20)

## Context

During Phase 3 implementation, 7 bugs were found and fixed (documented in [scene-transition-patterns-retrospective](2026-03-20-scene-transition-patterns-retrospective.md)). A systematic audit of the remaining plan ([feat-rpg-playable-loop-foundation-plan](../plans/2026-03-19-feat-rpg-playable-loop-foundation-plan.md)) revealed 12 additional issues — same classes of incorrect assumptions that will cause bugs in Phase 4 or mislead future implementers.

## Issues by Category

### A. Strict Typing Violations in Plan Code

**A1. SaveManager code uses direct method calls on group nodes (plan lines 956-974)**
- Plan shows: `node.get_save_key()` / `node.get_save_data()` / `node.load_save_data()`
- Problem: `get_nodes_in_group()` returns `Array[Node]`. Strict typing rejects methods not on `Node`.
- Correct: `node.call("get_save_key")` — already fixed in implementation, but plan code is stale.

**A2. SaveManager accesses private var `SceneManager._is_transitioning` (plan line 905)**
- Problem: Cross-autoload access to a `_`-prefixed var. Works but violates encapsulation.
- Recommendation: Add `func is_transitioning() -> bool` to SceneManager. SaveManager calls the public method.
- Severity: Style, not a crash. Fix during Phase 4 cleanup.

### B. Timing Assumptions

**B3. `process_frame` used everywhere instead of `scene_changed` signal**
- Plan lines: 813 (SceneManager), 969 (SaveManager `_restore_save_data`)
- Problem: `await get_tree().process_frame` is fragile and version-dependent. One frame wasn't enough (we had to use two). The official pattern for Godot 4.5+ is `await get_tree().scene_changed`.
- Impact: SceneManager already uses two frames (works). SaveManager's `_restore_save_data` uses one frame after `scene_change_completed` (may be OK since SceneManager already waited, but fragile).
- Recommendation: Replace all post-`change_scene_to_file` waits with `await get_tree().scene_changed`. This is the single highest-value fix.

### C. Persistent Node Lifecycle Bugs

**C4. No UI duplicate prevention**
- Problem: InteractionPrompt, ItemToast, QuestIndicator reparent to root in `_ready()`. When Room 1 reloads, new instances are created from the `.tscn`. The reparented originals still exist at root. Result: duplicate UI nodes accumulating on every Room 1 visit.
- This is the exact same bug as the duplicate player, but we only fixed it for the player.
- Options:
  - **(a) Guard in each UI script** (like `register_player`): check if an instance already exists at root, `queue_free()` the duplicate. Repetitive.
  - **(b) Move UI to autoloads**: register InteractionPrompt, ItemToast, QuestIndicator as autoloads (or children of a single HUD autoload). They naturally persist. No reparenting. No duplicates.
  - **(c) Remove UI from room scenes entirely**: build them in code from an autoload's `_ready()`, like SceneManager builds its overlay. No editor scene needed.
- Recommendation: **(b)** — a single `HUD` autoload that builds/owns all persistent UI. Matches the research finding that persistent UI should be autoloads, not reparented nodes. Also resolves the EventBus concern (A7).

**C5. Plan says "remove Player from test_room.tscn" (plan line 1400)**
- Problem: `register_player()` is called from `PlayerController._ready()`. If no scene contains a Player instance, who creates the first one? SceneManager doesn't instantiate the player — it only reparents one that already exists.
- The plan contradicts itself: it says to remove the Player from Room 1, but provides no alternative creation mechanism.
- Current approach (keep Player in Room 1, guard against duplicates) works. The plan instruction should be deleted or replaced with: "Keep Player in Room 1's scene. SceneManager will reparent it to root on first load and guard against duplicates on revisit."

**C6. Saveable group added both in code AND editor (plan lines 1406-1409)**
- Problem: The plan tells the user to add "saveable" group in the editor, but our scripts already call `add_to_group("saveable")` in `_ready()`. Doing both is harmless but confusing.
- Recommendation: Delete the editor instructions. Code-based group membership is the correct pattern — it's self-documenting and can't be forgotten when creating new scenes.

### D. Architecture Gaps

**D7. EventBus signal for `quest_completed` may be unnecessary (plan lines 1026-1028)**
- Plan says: *"QuestTracker is under Player and the UI may be a separate CanvasLayer"* — implying EventBus is needed to bridge them.
- Reality: QuestIndicator already connects to QuestTracker signals via `get_nodes_in_group("player")` lookup. This works fine.
- If UI becomes an autoload (C4 recommendation), it can still find the player the same way. EventBus isn't needed for this signal.
- Recommendation: When Phase 4 Step 7 arrives, re-evaluate which signals actually need EventBus. The plan's "likely candidates" may all be solvable without it.

**D8. No in-session interactable state tracking in plan architecture**
- The plan covers save/load (to disk) but never mentions tracking state between scene transitions within a single session.
- We had to add `_interactable_state` dictionary to SceneManager as a bug fix.
- Better pattern: dedicated `WorldState` autoload that owns all interactable state. Interactables check it in `_ready()`. Naturally extends to save files.
- This was a genuine gap in the architecture section, not just a code error.

### E. Phase 4 Specific Issues

**E9. Pause menu location unspecified (plan line 1050)**
- Plan says: *"Simple CanvasLayer with Resume, Save, Load, Quit buttons"* but doesn't say where it lives.
- If it's a room child: dies on scene change (same bug as UI nodes).
- If it's instanced per-room: duplicates on revisit (same bug as player).
- Recommendation: Make it part of the HUD autoload (C4) or its own autoload. Must persist across scenes.

**E10. `GameState.current_mode = MENU` bypasses signal (plan line 1050)**
- Plan says: `Sets GameState.current_mode = MENU`
- GameState has a `set_mode()` method that emits `game_state_changed`. Direct property assignment skips the signal. Player state machine depends on this signal to block input.
- Recommendation: Plan should say `GameState.set_mode(GameState.GameMode.MENU)`.

### F. Plan Maintenance

**F11. Plan code snippets are now outdated**
- SceneManager code (lines 775-828): still shows `.tscn` pattern, `@onready var %TransitionOverlay`, non-deferred reparenting, single `process_frame`
- SaveManager code (lines 893-974): still shows direct method calls on group nodes
- These snippets no longer match the implementation. Anyone reading the plan will be misled.
- Recommendation: Either update the code snippets or add a prominent note: "Code snippets in this plan are design-time drafts. See the actual implementation for the current patterns."

**F12. Plan doesn't mention `scene_changed` signal anywhere**
- Godot 4.5+ provides `await get_tree().scene_changed` — the official way to wait for scene transitions.
- The plan targets 4.6.1 but never mentions this signal. All timing code uses `process_frame`.
- Recommendation: Add to the plan's "Research Insights" and to CLAUDE.md conventions.

## Summary Table

| # | Category | Severity | Fix Complexity | When to Fix |
|---|----------|----------|----------------|-------------|
| A1 | Strict typing | Stale docs | Low | Plan update |
| A2 | Encapsulation | Style | Low | Phase 4 cleanup |
| B3 | Timing | Fragile | Medium | Before Phase 4 |
| C4 | Duplicate UI | **Will crash** | Medium | Before Phase 4 |
| C5 | Player creation | Contradictory | Low | Plan update |
| C6 | Group setup | Confusing | Low | Plan update |
| D7 | EventBus scope | Over-design | Low | Phase 4 Step 7 |
| D8 | Session state | Architecture gap | Medium | Before Phase 4 |
| E9 | Pause menu | Will break | Medium | Phase 4 Step 8 |
| E10 | Mode setting | Silent bug | Low | Phase 4 Step 8 |
| F11 | Stale code | Misleading | Medium | Plan update |
| F12 | Missing signal | Missing pattern | Low | CLAUDE.md + plan |

## Recommended Priority

**Fix before Phase 4 starts (blocking):**
1. **C4** — UI duplicate prevention (will cause visible bugs immediately)
2. **B3** — Switch to `scene_changed` signal (eliminates fragile frame counting)
3. **F12** — Add `scene_changed` to CLAUDE.md conventions
4. **D8** — Extract WorldState autoload for interactable state tracking

**Fix during Phase 4 (non-blocking):**
4. **E9** — Pause menu as autoload, not room child
6. **E10** — Use `set_mode()` not direct assignment
7. **A2** — Public `is_transitioning()` accessor
8. **D7** — Re-evaluate EventBus candidates with current architecture

**Plan documentation updates (low priority):**
9. **F11** — Add "stale snippets" note to plan
10. **C5** — Delete "remove Player from test_room" instruction
11. **C6** — Delete editor group assignment instructions
12. **A1** — Update SaveManager snippet to use `.call()`

## Resolved Questions

1. **UI approach:** Refactor to a single HUD autoload before Phase 4. This eliminates reparenting, duplicates, and room coupling. Clean foundation for Phase 4 pause menu.

2. **WorldState:** New dedicated autoload. Tradeoffs considered:
   - *New autoload* (chosen): Single responsibility. Clean save target. 5th autoload is still well under the "Services pattern at 8+" threshold.
   - *Merge into GameState*: Rejected — mode management + interactable state are unrelated. GameState becomes a catch-all.
   - *Keep on SceneManager*: Rejected — conflates transition management with state tracking. SaveManager would need to reach into SceneManager internals.

3. **Stale plan snippets:** Update in-place. Rewrite code snippets to match current implementation. Cleaner for future readers.

## Refactoring Scope

The following work should be planned and executed before Phase 4 begins:

### Blocking Refactors (pre-Phase 4)

1. **HUD autoload** — Create `scripts/autoloads/hud.gd` that instantiates the existing `.tscn` scenes (interaction_prompt, item_toast, quest_indicator) as children in `_ready()`. This preserves editor-tweakable layout while making the UI persistent. Remove reparenting code from UI scripts. Remove UI instances from room `.tscn` files (user does this in editor). Register as autoload.
   - **Signal reconnection:** HUD `_ready()` runs once at game start, before any player exists. UI scripts currently connect to player signals via `_connect_to_player.call_deferred()`. This still works — the player is instanced from Room 1's scene before the first frame. But if the connection fails (player not yet reparented), add a fallback: reconnect on `SceneManager.scene_change_completed`.
   - **Autoload order:** EventBus → GameState → WorldState → SceneManager → SaveManager → HUD. HUD last because it may need player (which is created by the scene, after autoloads).

2. **WorldState autoload** — Create `scripts/autoloads/world_state.gd` with interactable state dictionary. Move `_interactable_state` + `_save_interactable_state()` + `_load_interactable_state()` out of SceneManager. Interactables check WorldState in `_ready()` and update on interaction. Implement saveable contract (joins "saveable" group so SaveManager serializes it).
   - **Autoload order:** Before SceneManager, since SceneManager calls save/load during transitions.

3. **`scene_changed` signal** — Replace all `process_frame` waits in SceneManager with `await get_tree().scene_changed`. Remove frame-counting comments. Add to CLAUDE.md conventions.

4. **SceneManager.is_transitioning()** — Public accessor replacing direct `_is_transitioning` access from SaveManager.

### Plan Document Updates

5. **Update code snippets in-place** — Rewrite SceneManager and SaveManager code in the plan to match current patterns (`.gd` autoload, `.call()`, `scene_changed`, deferred reparenting, duplicate guard).

6. **Delete contradictory instructions** — Remove "remove Player from test_room" (line 1400). Remove editor group assignment instructions (lines 1406-1409). Fix `GameState.current_mode = MENU` to use `set_mode()` (line 1050).

7. **Add architecture notes** — Document HUD autoload pattern, WorldState autoload, `scene_changed` signal in plan's architecture section.

## External Research Validation

Three proposed patterns were validated against Godot documentation and community best practices.

### HUD Autoload Pattern — VALIDATED
- Instantiating `.tscn` scenes from an autoload's `_ready()` is a standard, documented Godot pattern.
- CanvasLayer children of autoloads handle input correctly. One nuance: `_input()` is called in **reverse** tree order across autoloads, so the HUD autoload's position in project.godot matters if it needs to consume input before other autoloads.
- Community consensus: single CanvasLayer-rooted autoload for persistent HUD, with individual panels as child scenes. Multiple UI autoloads cause "HUD appears in main menu" problems.
- Sources: [Godot Forum: Global CanvasLayer for UI](https://forum.godotengine.org/t/global-canvaslayer-for-ui/112787), [Godot Docs: First 2D Game HUD](https://github.com/godotengine/godot-docs/blob/4.5/getting_started/first_2d_game/06.heads_up_display.md)

### `scene_changed` Signal — VALIDATED
- Available in Godot 4.5+ ([PR #102986](https://github.com/godotengine/godot/pull/102986)). Our target is 4.6.1.
- Fires **after** the new scene is in the tree and `current_scene` is valid. Works with both `change_scene_to_file()` and `change_scene_to_packed()`.
- **If `change_scene_to_file()` fails, the signal does NOT fire.** Must check the `Error` return value before awaiting. Our existing code already does this.
- No known bugs in 4.5/4.6 for the runtime signal.
- Sources: [Godot Docs: SceneTree](https://docs.godotengine.org/en/stable/classes/class_scenetree.html), [PR #102986](https://github.com/godotengine/godot/pull/102986)

### Autoload Count (7) — VALIDATED
- 7 autoloads is within normal range for RPGs. Official docs have no maximum. Community projects commonly have 5-10.
- Initialization order is guaranteed to match `project.godot` listing order for `_ready()`. `_input()` is reverse order (standard Godot behavior).
- No concerns at this scale. The "Services pattern for 8+" threshold from the plan is conservative — we're fine at 7.
- Sources: [Godot Docs: Autoloads vs Regular Nodes](https://docs.godotengine.org/en/stable/tutorials/best_practices/autoloads_versus_internal_nodes.html), [Godot Forum: Autoload input order](https://forum.godotengine.org/t/within-multiple-autoloads-input-is-called-in-reverse-execution-order/120257)

### Design Impact from Research

One finding affects our design: **`_input()` reverse order.** The HUD autoload should be listed **last** in project.godot so it receives `_input()` **first** (reverse order). This means the pause menu (future Phase 4, part of HUD) can consume the `pause` input action before other autoloads process it. Current proposed order already has HUD last — confirmed correct.

### Workflow

The user's planned approach:
1. Review this brainstorm document
2. Run `/gc:plan` on this brainstorm to create a detailed implementation plan
3. Execute the plan: refactor code + update original plan document
4. Then proceed to Phase 4
