---
title: "refactor: Pre-Phase 4 Cleanup — HUD Autoload, WorldState, scene_changed Signal"
type: refactor
status: completed
date: 2026-03-20
origin: docs/brainstorms/2026-03-20-plan-corrections-brainstorm.md
---

# refactor: Pre-Phase 4 Cleanup — HUD Autoload, WorldState, scene_changed Signal

## Enhancement Summary

**Deepened on:** 2026-03-20
**Sections enhanced:** All 6 phases + architecture + system-wide impact
**Review agents used:** gc-godot-architecture-reviewer, gc-godot-timing-reviewer, gc-gdscript-reviewer, gc-resource-safety-reviewer, gc-code-simplicity-reviewer, gc-godot-performance-reviewer, gc-pattern-recognition-specialist, gc-best-practices-researcher, gc-framework-docs-researcher

### Key Improvements
1. **Critical timing fix:** `_restore_save_data` must load WorldState AFTER `scene_change_completed` (not before), because `WorldState.snapshot()` inside `change_scene()` would clobber pre-loaded data
2. **Strict typing compliance:** HUD uses `.call()` for duck-typed `connect_to_player()`, typed `Dictionary[String, Dictionary]` for WorldState `_state`. `.call()` returns trigger `unsafe_cast` (level 1 = warning only, not error) — matches existing codebase pattern, no `@warning_ignore` needed.
3. **HUD catch-up pattern:** Added `get_player()` accessor on SceneManager + catch-up check in HUD `_ready()` for defensive initialization
4. **SaveManager identity check:** Uses `node == WorldState` instead of fragile `key == "world_state"` string comparison
5. **Defensive copies:** `WorldState.restore()` passes `.duplicate(true)` to interactables, matching `get_save_data()` defensive pattern
6. **YAGNI applied:** Removed `WorldState.clear()` (no caller exists), merged Phase 6 tests into Phase 2
7. **Documented simplification opportunity:** Orchestrated `snapshot()`/`restore()` may be replaceable with simpler self-registering pattern (chests read/write WorldState directly), confirmed by best-practices research showing two-group pattern is non-standard

### Verified Assumptions (from framework docs research)
- `scene_changed` fires after all new scene `_ready()` callbacks complete (source: engine `scene_tree.cpp`)
- Autoload `_ready()` order matches `project.godot` listing (guaranteed by insertion-ordered HashMap)
- `add_child()` in autoload `_ready()` triggers child `_ready()` synchronously (not deferred)
- `preload()` in autoloads is safe for `.tscn` files (no circular dependency risk in this design)

## Overview

Phase 3 implementation exposed 7 runtime bugs (documented in [retrospective](../../docs/brainstorms/2026-03-20-scene-transition-patterns-retrospective.md)). A systematic audit found 46 additional issues in the plan — same classes of incorrect assumptions. This refactor addresses the 4 blocking issues before Phase 4 begins, updates CLAUDE.md with new conventions, and updates stale plan documentation.

## Problem Statement / Motivation

1. **UI duplicates on room revisit (C4)** — InteractionPrompt, ItemToast, QuestIndicator reparent to root but have no duplicate guard. Every Room 1 revisit creates additional copies.
2. **Fragile frame counting (B3)** — SceneManager uses `await process_frame` x2 after `change_scene_to_file()`. Godot 4.5+ provides `scene_changed` signal.
3. **Interactable state on wrong autoload (D8)** — `_interactable_state` lives on SceneManager, conflating transition management with state tracking.
4. **Private var access (A2)** — SaveManager reads `SceneManager._is_transitioning` directly.

## Proposed Solution

Four sequential refactors, each producing a clean commit:

1. **`is_transitioning()` accessor** on SceneManager (trivial, unblocks SaveManager cleanup)
2. **WorldState autoload** — owns all interactable session state + disk persistence
3. **`scene_changed` signal** — replace all `process_frame` waits
4. **HUD autoload** — single persistent UI container, `player_registered` signal for connection

Then a documentation pass: CLAUDE.md conventions + plan snippet updates.

## Technical Considerations

- **Autoload order after refactor:** EventBus → GameState → DialogueManager → WorldState → SceneManager → SaveManager → HUD (7 total, validated as normal for RPGs — see [brainstorm research](docs/brainstorms/2026-03-20-plan-corrections-brainstorm.md#external-research-validation))
- **HUD extends Node** (not CanvasLayer) — child UI scenes already extend CanvasLayer, nesting is unnecessary
- **`.tscn` files are read-only for agents** — editor tasks listed separately as user checklists
- **`scene_changed` signal** — no parameters, simple `await get_tree().scene_changed` (confirmed via Godot 4.6 docs)
- **`_input()` reverse order** — HUD last in project.godot means it receives input first, correct for future pause menu

## System-Wide Impact

- **Signal chain:** `SceneManager.player_registered` is new — HUD listens to connect UI to player. Existing `scene_change_started`/`scene_change_completed` signals unchanged but `scene_change_completed` now fires after `scene_changed` instead of after frame counting.
- **Error propagation:** If `change_scene_to_file()` returns error, `scene_changed` never fires. Existing error check (line 56 of scene_manager.gd) already guards this — no change needed.
- **State lifecycle:** WorldState replaces SceneManager's `_interactable_state`. Chests drop out of "saveable" group — WorldState is the single owner of interactable persistence. No save file migration needed (session-only state).
- **Scene interface parity:** All three UI scripts get identical refactors (remove reparenting). chest_interactable moves from `"saveable"` to `"interactable_saveable"` group (keeps save contract methods — WorldState calls them via duck typing).

## Implementation Phases

### Phase 0: Prerequisite — Commit Untracked Scenes

Three `.tscn` files are untracked (`chest.tscn`, `item_toast.tscn`, `quest_indicator.tscn`). Commit them before starting refactor work to ensure a safe rollback point for editor changes.

- [ ] `git add scenes/interactables/chest.tscn scenes/ui/item_toast.tscn scenes/ui/quest_indicator.tscn`
- [ ] Commit: `chore: track untracked scene files before refactor`

### Phase 1: SceneManager.is_transitioning() Accessor

Trivial change, no dependencies.

**Files modified:**
- `scripts/autoloads/scene_manager.gd` — add public method
- `scripts/autoloads/save_manager.gd` — replace direct access

**Steps:**
- [x] Add to `scene_manager.gd` (after `_interactable_state` declaration):
  ```gdscript
  func is_transitioning() -> bool:
      return _is_transitioning
  ```
- [x] In `save_manager.gd` line 21, replace `SceneManager._is_transitioning` with `SceneManager.is_transitioning()`
- [x] Run `gdformat --check . && gdlint .`
- [x] Commit: `refactor(scene): add is_transitioning() accessor, remove private var access`

### Phase 2: WorldState Autoload

**Files created:**
- `scripts/autoloads/world_state.gd`

**Files modified:**
- `scripts/autoloads/scene_manager.gd` — remove `_interactable_state`, `_save_interactable_state()`, `_load_interactable_state()`, replace calls with WorldState delegation
- `scripts/interactables/chest_interactable.gd` — remove saveable contract methods (`get_save_key`, `get_save_data`, `load_save_data`), remove `add_to_group("saveable")` from `_ready()`, add WorldState update on interaction
- `project.godot` — register WorldState autoload (user does this in editor)

**WorldState design:**

```gdscript
extends Node
## Tracks interactable state across scene transitions within a session.
## Implements the saveable contract so SaveManager can serialize/deserialize
## all interactable state as a single blob.

## All values are flat Dictionaries of primitives (e.g., {"is_opened": true}).
## If interactables begin storing nested Resources, manual duplication is needed.
var _state: Dictionary[String, Dictionary] = {}


func _ready() -> void:
    add_to_group("saveable")


func get_state(key: String) -> Dictionary:
    if _state.has(key):
        return _state[key]
    return {}


func set_state(key: String, data: Dictionary) -> void:
    _state[key] = data


func snapshot() -> void:
    ## Called by SceneManager BEFORE old scene is freed.
    ## Collects state from all interactables in the current scene.
    for node: Node in get_tree().get_nodes_in_group("interactable_saveable"):
        if node.has_method("get_save_key") and node.has_method("get_save_data"):
            var key: String = node.call("get_save_key")
            _state[key] = node.call("get_save_data")


func restore() -> void:
    ## Called by SceneManager AFTER new scene is ready.
    ## Pushes stored state to matching interactables.
    for node: Node in get_tree().get_nodes_in_group("interactable_saveable"):
        if node.has_method("get_save_key") and node.has_method("load_save_data"):
            var key: String = node.call("get_save_key")
            if _state.has(key):
                node.call("load_save_data", _state[key].duplicate(true))



# --- Saveable contract (for SaveManager disk persistence) ---

func get_save_key() -> String:
    return "world_state"


func get_save_data() -> Dictionary:
    return _state.duplicate(true)


func load_save_data(data: Dictionary) -> void:
    _state = data.duplicate(true)
```

**Key design decisions:**
- Chests move to a new `"interactable_saveable"` group (separate from `"saveable"`) so WorldState can iterate them without picking up Player/Inventory/QuestTracker. WorldState itself stays in `"saveable"` for disk persistence.
- `snapshot()` / `restore()` are the orchestrated pattern — SceneManager calls them at the same points it currently calls `_save/_load_interactable_state()`.
- `load_save_data()` replaces the entire dictionary (not merge) to avoid stale session state after loading a save file.

> **Simplification opportunity (deferred decision):** The `snapshot()`/`restore()` orchestration could be eliminated entirely. If chests self-register (read WorldState in `_ready()`, write in `interact()`), no group iteration or SceneManager coupling is needed. WorldState becomes a pure 20-line key-value store. The SaveManager "load WorldState before scene change" ordering still works because without `snapshot()`, there's nothing to clobber. This reduces ~25 lines and removes the `"interactable_saveable"` group. Tradeoff: chests are more tightly coupled to WorldState (call it directly instead of implementing a duck-typed contract). Consider during implementation if the orchestrated pattern feels over-engineered.

**chest_interactable.gd changes:**

Chests KEEP `get_save_key()`, `get_save_data()`, `load_save_data()` — WorldState's `snapshot()`/`restore()` calls these via duck typing. The only change is the group: move from `"saveable"` to `"interactable_saveable"` so SaveManager skips them (WorldState handles their persistence as a single blob).

- `_ready()`: Replace `add_to_group("saveable")` with `add_to_group("interactable_saveable")`
- Add `WorldState.set_state()` in `interact()` for immediate session state update:
  ```gdscript
  func interact(player: PlayerController) -> void:
      # ... existing logic ...
      _is_opened = true
      WorldState.set_state(chest_id, {"is_opened": true})
      chest_opened.emit(item)
  ```

**scene_manager.gd changes:**
- Remove `var _interactable_state: Dictionary = {}`
- Remove `_save_interactable_state()` and `_load_interactable_state()` methods
- In `change_scene()`: replace `_save_interactable_state()` with `WorldState.snapshot()`, replace `_load_interactable_state()` with `WorldState.restore()`

**Steps:**
- [x] Create `scripts/autoloads/world_state.gd` with design above
- [x] Modify `chest_interactable.gd`: change group from `"saveable"` to `"interactable_saveable"`, add `WorldState.set_state()` call in `interact()`
- [x] Modify `scene_manager.gd`: remove state dictionary + methods, delegate to WorldState
- [x] Update `tests/unit/test_save_data_contracts.gd`: update chest test to check `"interactable_saveable"` group, add WorldState save/load roundtrip test
- [x] Update `tests/integration/test_save_load_cycle.gd`: verify WorldState is serialized as `"world_state"` key
- [x] Run `gdformat --check . && gdlint .`
- [x] Commit: `refactor(state): extract WorldState autoload from SceneManager`

**Editor tasks (user must do manually):**
- [ ] Register WorldState autoload in Project Settings → Autoload: path `res://scripts/autoloads/world_state.gd`, name `WorldState`
- [ ] Move WorldState ABOVE SceneManager in the autoload list (after DialogueManager)
- [ ] Verify autoload order: EventBus, GameState, DialogueManager, WorldState, SceneManager, SaveManager

### Phase 3: scene_changed Signal

**Files modified:**
- `scripts/autoloads/scene_manager.gd` — replace `process_frame` waits
- `scripts/autoloads/save_manager.gd` — remove redundant `process_frame` wait

**scene_manager.gd changes in `change_scene()`:**
Replace lines 63-64:
```gdscript
# OLD:
await get_tree().process_frame
await get_tree().process_frame

# NEW:
await get_tree().scene_changed
```

Remove the frame-counting comments (lines 60-62).

> **Research insight — `scene_changed` edge cases:** (1) Does NOT fire for manual scene changes (`remove_child`/`add_child` without `change_scene_to_*`). (2) The old scene is already freed when the signal fires — do not reference it in the handler. (3) Verify behavior with `reload_current_scene()` on Godot 4.6.1. Sources: [PR #102986](https://github.com/godotengine/godot/pull/102986), [godot#86452](https://github.com/godotengine/godot/issues/86452).

**save_manager.gd changes in `_restore_save_data()`:**
Line 94 (`await get_tree().process_frame` after `scene_change_completed`): This wait is redundant because `scene_change_completed` now fires after `scene_changed` has already guaranteed the scene is ready. Remove it.

Also: when `load_game()` calls `_restore_save_data()`, WorldState must be loaded AFTER the scene change. **Critical timing:** `SceneManager.change_scene()` calls `WorldState.snapshot()` before freeing the old scene — if we load WorldState before the scene change, `snapshot()` overwrites our loaded data with stale current-scene state.

The correct flow: let the scene change complete (including its snapshot/restore cycle), then overwrite WorldState with save file data and manually push it to interactables.

```gdscript
func _restore_save_data(data: Dictionary) -> void:
    var scene_path: String = data.get("scene_path", "")
    if scene_path != "" and scene_path != get_tree().current_scene.scene_file_path:
        SceneManager.change_scene(scene_path)
        await SceneManager.scene_change_completed
    # AFTER scene change: overwrite WorldState with save file data.
    # This must happen after change_scene's snapshot()/restore() cycle,
    # otherwise snapshot() clobbers the loaded data.
    if data.has("world_state"):
        WorldState.load_save_data(data["world_state"])
        WorldState.restore()  # Push save-file state to interactables in new scene
    # Restore remaining saveables (Player, Inventory, QuestTracker).
    # Skip WorldState — already restored above.
    for node: Node in get_tree().get_nodes_in_group("saveable"):
        if node == WorldState:
            continue  # Already restored above (identity check, not string)
        if node.has_method("get_save_key") and node.has_method("load_save_data"):
            var key: String = node.call("get_save_key")
            if data.has(key):
                node.call("load_save_data", data[key])
```

**Steps:**
- [x] In `scene_manager.gd`: replace double `process_frame` with `await get_tree().scene_changed`, clean up comments
- [ ] **Verify timing:** Add temporary print in `chest_interactable._ready()` and after `scene_changed` await to confirm `scene_changed` fires AFTER new scene's `_ready()` completes (interactables must be in `"interactable_saveable"` group before `WorldState.restore()` runs)
- [x] In `save_manager.gd`: restore WorldState AFTER scene change, skip in saveable loop, remove redundant `process_frame`
- [x] Run `gdformat --check . && gdlint .`
- [x] Commit: `refactor(scene): use scene_changed signal instead of process_frame counting`

### Phase 4: HUD Autoload

**Files created:**
- `scripts/autoloads/hud.gd`

**Files modified:**
- `scripts/autoloads/scene_manager.gd` — add `player_registered` signal
- `scripts/ui/interaction_prompt.gd` — remove reparenting, simplify `_ready()`
- `scripts/ui/item_toast.gd` — remove reparenting, simplify `_ready()`
- `scripts/ui/quest_indicator.gd` — remove reparenting, simplify `_ready()`
- `project.godot` — register HUD autoload (user does this in editor)

**scene_manager.gd — add signal and accessor:**
```gdscript
signal player_registered(player: PlayerController)

func get_player() -> PlayerController:
    return _player
```

In `register_player()`, after the existing reparenting logic, emit:
```gdscript
player_registered.emit(_player)
```

Note: `player_registered` fires only once — when the first Player instance calls `register_player()`. On room revisits, the duplicate Player is freed and the signal does NOT re-emit (the existing player persists with its connections intact).

**Why `player_registered` on SceneManager, not EventBus:** SceneManager owns the player's persistence lifecycle (`register_player`, reparenting to root, spawn positioning). The signal is a direct consequence of that lifecycle, not a cross-system broadcast. EventBus is reserved for Phase 4 Step 7 evaluation of genuinely decoupled signals (see brainstorm D7). If future systems (camera, audio) need to know about the player, re-evaluate then.

**hud.gd design:**
```gdscript
extends Node
## Persistent HUD container. Instantiates UI scenes in _ready() so they
## survive scene transitions without reparenting. Connects to player via
## SceneManager.player_registered signal.

var _interaction_prompt: CanvasLayer = null
var _item_toast: CanvasLayer = null
var _quest_indicator: CanvasLayer = null


func _ready() -> void:
    _interaction_prompt = preload("res://scenes/ui/interaction_prompt.tscn").instantiate()
    add_child(_interaction_prompt)
    _item_toast = preload("res://scenes/ui/item_toast.tscn").instantiate()
    add_child(_item_toast)
    _quest_indicator = preload("res://scenes/ui/quest_indicator.tscn").instantiate()
    add_child(_quest_indicator)
    SceneManager.player_registered.connect(_on_player_registered)
    # Catch-up: if player was already registered before HUD._ready() ran
    # (shouldn't happen with current autoload order, but defensive)
    var existing_player: PlayerController = SceneManager.get_player()
    if existing_player:
        _on_player_registered(existing_player)


func _on_player_registered(player: PlayerController) -> void:
    # Connect each UI element to the player's signals.
    # Uses .call() because CanvasLayer doesn't declare connect_to_player().
    # player_registered fires once on initial load. Signal connections persist
    # across scene transitions because the player object persists.
    _interaction_prompt.call("connect_to_player", player)
    _item_toast.call("connect_to_player", player)
    _quest_indicator.call("connect_to_player", player)
```

**UI script changes — all three scripts:**

Remove from `_ready()`:
- `get_parent().call_deferred("remove_child", self)`
- `get_tree().root.call_deferred("add_child", self)`
- `_connect_to_player.call_deferred()`

Rename `_connect_to_player()` to `connect_to_player(player: PlayerController)` (public, receives player directly instead of group lookup):

**interaction_prompt.gd:**
```gdscript
func _ready() -> void:
    visible = false


func connect_to_player(player: PlayerController) -> void:
    player.nearest_interactable_changed.connect(_on_nearest_interactable_changed)
```

**item_toast.gd:**
```gdscript
func _ready() -> void:
    _panel.modulate.a = 0.0


func connect_to_player(player: PlayerController) -> void:
    _player = player  # Store ref — used by _get_item_display_name() instead of group lookup
    var inventory: Inventory = player.get_inventory()
    if inventory:
        inventory.item_added.connect(show_toast)
```
Also: refactor `_get_item_display_name()` to use stored `_player` ref instead of `get_tree().get_nodes_in_group("player")` lookup.

**quest_indicator.gd:**
```gdscript
func _ready() -> void:
    _panel.visible = false


func connect_to_player(player: PlayerController) -> void:
    _quest_tracker = player.get_quest_tracker()
    if not _quest_tracker:
        return
    _quest_tracker.quest_started.connect(_on_quest_started)
    _quest_tracker.quest_step_completed.connect(_on_quest_step_completed)
    _quest_tracker.quest_completed.connect(_on_quest_completed)
```

**Steps:**
- [x] Add `player_registered` signal and emission to `scene_manager.gd`
- [x] Create `scripts/autoloads/hud.gd`
- [x] Refactor `interaction_prompt.gd`: remove reparenting, make `connect_to_player` public with player param
- [x] Refactor `item_toast.gd`: same pattern
- [x] Refactor `quest_indicator.gd`: same pattern
- [x] Run `gdformat --check . && gdlint .`
- [x] Commit: `refactor(ui): HUD autoload with player_registered signal for persistent UI`

**Editor tasks (user must do manually):**
- [ ] Remove InteractionPrompt instance from `test_room.tscn`
- [ ] Remove ItemToast instance from `test_room.tscn`
- [ ] Remove QuestIndicator instance from `test_room.tscn`
- [ ] Check `test_room_2.tscn` for UI instances — remove if present
- [ ] Register HUD autoload in Project Settings → Autoload: path `res://scripts/autoloads/hud.gd`, name `HUD`
- [ ] Move HUD to LAST position in autoload list
- [ ] Verify final autoload order: EventBus, GameState, DialogueManager, WorldState, SceneManager, SaveManager, HUD

### Phase 5: CLAUDE.md + Documentation Updates

**Files modified:**
- `CLAUDE.md` — add new conventions
- `docs/plans/2026-03-19-feat-rpg-playable-loop-foundation-plan.md` — update stale snippets and instructions

**CLAUDE.md additions:**
- [x] Add: `await get_tree().scene_changed` over `process_frame` counting (Godot 4.5+)
- [x] Add: `call_deferred()` required for tree mutations in `_ready()`
- [x] Add: Persistent UI as autoloads, not reparented scene children
- [x] Add: Saveable group contracts — `"saveable"` group iterated by SaveManager for disk persistence, `"interactable_saveable"` group iterated by WorldState for session state. Both use the same three-method contract (`get_save_key`, `get_save_data`, `load_save_data`). Note: HUD uses `preload().instantiate()` for UI scenes (not programmatic build like SceneManager) because UI children are non-trivial scene trees with editor-tweakable layout.

**Plan document updates (batch — all items from brainstorm F11, G1-G24, H1-H6):**
- [ ] Update SceneManager snippet (lines 775-828) to match current implementation
- [ ] Update SaveManager snippet (lines 893-974) to match current implementation
- [ ] Delete "remove Player from test_room" instruction (line 1400) — replace with "keep Player, SceneManager guards duplicates"
- [ ] Delete editor group assignment instructions (lines 1406-1409) — code handles groups
- [ ] Fix door saveable contradiction (line 989) — doors are NOT saveable
- [ ] Update autoload count in Alternative Approaches table (line 1084) — "4 max" → "7"
- [ ] Update editor instructions for UI: "instanced by HUD autoload" not "instance in room"
- [ ] Update autoload order in "Before Step 6" editor instructions
- [ ] Update signal chain descriptions to include WorldState
- [ ] Mark item registry gap (line 452) as resolved
- [ ] Update file structure section (lines 136-198) with new files
- [ ] Add `scene_changed` to Research Insights section
- [ ] Fix `GameState.current_mode = MENU` to `GameState.set_mode()` (line 1050)

**Steps:**
- [x] Update CLAUDE.md with new conventions
- [x] Update plan document (batch all stale snippet/instruction fixes)
- [x] Run `gdformat --check . && gdlint .`
- [x] Commit: `docs: update CLAUDE.md conventions and plan snippets for post-Phase 3 patterns`

### Phase 6: Cross-Room Integration Test (if time permits)

**New test (see brainstorm G17):**
- `tests/integration/test_cross_room_quest.gd` — quest loop across scene transitions

Note: WorldState save/load roundtrip tests ship with Phase 2 (tests belong with the code they test). This phase is only for the optional cross-room quest integration test.

## Acceptance Criteria

- [ ] No duplicate UI nodes after revisiting Room 1 multiple times
- [ ] `scene_changed` signal used instead of `process_frame` counting everywhere
- [ ] WorldState autoload owns interactable state; SceneManager has no state dictionary
- [ ] SaveManager uses `SceneManager.is_transitioning()` (not `._is_transitioning`)
- [ ] HUD connects to player via `player_registered` signal on initial load (connections persist across room transitions because the player object persists)
- [ ] Chest state persists across room transitions (session) and save/load (disk)
- [ ] All existing tests pass
- [ ] `gdformat --check . && gdlint .` passes
- [ ] CLAUDE.md includes `scene_changed`, `call_deferred`, persistent UI, and interactable/saveable conventions

## Dependencies & Risks

- **Editor-dependent tasks:** Removing UI from `.tscn` files and registering autoloads must be done manually in Godot editor
- **Autoload order matters:** WorldState before SceneManager, HUD last. Wrong order causes null references.
- **SaveManager WorldState restore ordering:** WorldState must be restored AFTER `scene_change_completed` in `load_game()` (not before — `snapshot()` inside `change_scene()` would clobber pre-loaded data). Then manually call `WorldState.restore()` to push save-file state to interactables. This is the highest-risk change.

## Sources & References

### Origin

- **Brainstorm document:** [docs/brainstorms/2026-03-20-plan-corrections-brainstorm.md](docs/brainstorms/2026-03-20-plan-corrections-brainstorm.md) — Key decisions: HUD autoload for persistent UI, WorldState autoload for interactable state, orchestrated state pattern, `scene_changed` signal
- **Retrospective:** [docs/brainstorms/2026-03-20-scene-transition-patterns-retrospective.md](docs/brainstorms/2026-03-20-scene-transition-patterns-retrospective.md) — Documents the 7 Phase 3 bugs that motivated this refactor

### Internal References

- `scripts/autoloads/scene_manager.gd` — lines 14, 53, 63-64, 116-128 (state management, timing)
- `scripts/autoloads/save_manager.gd` — line 21 (private var access), line 94 (process_frame)
- `scripts/ui/interaction_prompt.gd` — lines 11-14 (reparenting pattern)
- `scripts/ui/item_toast.gd` — lines 12-15 (reparenting pattern)
- `scripts/ui/quest_indicator.gd` — lines 15-17 (reparenting pattern)

### External References

- [Godot Docs: SceneTree.scene_changed](https://docs.godotengine.org/en/stable/classes/class_scenetree.html)
- [Godot Forum: Global CanvasLayer for UI](https://forum.godotengine.org/t/global-canvaslayer-for-ui/112787)
- [Godot PR #102986: scene_changed signal](https://github.com/godotengine/godot/pull/102986)
