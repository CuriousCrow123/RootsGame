# Retrospective: Scene Transition Patterns (2026-03-20)

## What Happened

Phase 3 implementation (SceneManager, SaveManager, doors) encountered 7 bugs during editor testing. All stemmed from incorrect assumptions in the plan about how Godot handles scene transitions, node reparenting, and strict typing with autoloads.

## Errors Found and Root Causes

### 1. `.tscn` autoload breaks strict typing
- **Error:** `unsafe_method_access` / `unsafe_property_access` on every `SceneManager.method()` call
- **Plan assumed:** `.tscn` autoload needed for CanvasLayer + ColorRect child nodes
- **Root cause:** Godot's parser infers `.tscn` autoloads as `Node` type, not the script type ([godot#86300](https://github.com/godotengine/godot/issues/86300))
- **Fix:** Switch to `.gd` autoload, build child nodes in `_ready()`

### 2. Duck-typed group methods fail strict typing
- **Error:** `get_save_key()` not present on inferred type `Node`
- **Plan assumed:** `has_method()` guard would satisfy the type checker
- **Root cause:** `get_nodes_in_group()` returns `Array[Node]`. GDScript's strict typing doesn't narrow types through `has_method()` checks.
- **Fix:** Use `.call("method_name")` for duck-typed dispatch (same pattern as `interact()`)

### 3. `current_scene` null after `change_scene_to_file`
- **Error:** `Cannot call method 'find_child' on a null value`
- **Plan assumed:** One `process_frame` wait is enough after `change_scene_to_file()`
- **Root cause:** `change_scene_to_file()` is deferred — one frame isn't enough. The new scene isn't instantiated and `current_scene` isn't set until after the deferred call executes.
- **Fix applied:** Two `process_frame` waits. **Better fix available:** `await get_tree().scene_changed` (available in Godot 4.5+, our target is 4.6.1)

### 4. `remove_child()` blocked during `_ready()`
- **Error:** `Parent node is busy adding/removing children`
- **Plan assumed:** `register_player()` could directly call `remove_child()` + `add_child()`
- **Root cause:** `_ready()` fires while the tree is still building. Direct tree mutations are blocked.
- **Fix:** `call_deferred("remove_child", player)` + `call_deferred("add_child", player)`

### 5. Duplicate player on re-entering Room 1
- **Error:** Multiple player instances, all responding to input
- **Plan assumed:** Persistent player pattern "just works" with scene instances
- **Root cause:** Room 1's `.tscn` contains a Player instance. Returning to Room 1 instantiates a new Player that calls `register_player()` again.
- **Fix:** Guard in `register_player()` — if a player already exists, `queue_free()` the duplicate

### 6. UI dies on scene change
- **Error:** InteractionPrompt, ItemToast, QuestIndicator disappear in Room 2
- **Plan assumed:** UI would persist, but didn't specify how
- **Root cause:** UI nodes were children of the room scene. `change_scene_to_file()` frees the entire scene subtree.
- **Fix applied:** Each UI script reparents itself to root in `_ready()`. **Better pattern:** CanvasLayer autoload (see below)

### 7. Chest state resets on re-entering room
- **Error:** Opened chests appear closed again
- **Plan assumed:** Save/load contract would handle this (but that's for save files, not transitions)
- **Root cause:** Scene instances are recreated fresh from `.tscn` each time. No in-session state tracking between transitions.
- **Fix:** SceneManager snapshots saveable state before scene change and restores after load

## Pattern Analysis: What the Plan Assumed vs. Reality

| Topic | Plan Assumed | Reality | Best Practice |
|-------|-------------|---------|---------------|
| `.tscn` autoloads | Needed for child nodes | Breaks strict typing | `.gd` autoload, build children in `_ready()` |
| `process_frame` timing | One frame after `change_scene_to_file` | Not enough (deferred) | `await get_tree().scene_changed` (4.5+) |
| Reparenting in `_ready()` | Direct `remove_child`/`add_child` | Blocked by tree lock | `call_deferred()` or `reparent.call_deferred()` |
| Persistent player | Reparent to root, done | Duplicate on scene reload | Guard against existing player, free duplicate |
| Persistent UI | Not addressed | Room children die | CanvasLayer autoload (not reparenting) |
| Interactable state | Save/load contract | Only covers save files | Autoload dictionary for in-session state |
| Group iteration typing | `has_method()` then call | Strict typing ignores guards | `.call()` for duck-typed dispatch |

## Recommended Patterns Going Forward

### 1. Use `scene_changed` signal (not frame counting)
```gdscript
get_tree().change_scene_to_file(path)
await get_tree().scene_changed  # Available in Godot 4.5+
# current_scene is now guaranteed valid
```
This is the official Godot pattern. Frame counting is fragile and version-dependent.

### 2. Manual scene management for more control
The official docs recommend bypassing `change_scene_to_file()` entirely for complex transitions:
```gdscript
func _deferred_goto_scene(path: String) -> void:
    current_scene.free()
    var packed: PackedScene = ResourceLoader.load(path)
    current_scene = packed.instantiate()
    get_tree().root.add_child(current_scene)
    get_tree().current_scene = current_scene
```
This gives explicit control over player reparenting, scene freeing, and spawn placement order.

### 3. Persistent UI should be autoloads, not reparented nodes
Current fix (reparenting in `_ready()`) works but is fragile:
- Same timing issues as player reparenting
- Multiple instances if the scene is reloaded (same duplicate problem)
- Input handling can break if CanvasLayer leaves and re-enters the tree

Better: Register UI as autoloads, or have a single UI autoload that owns all persistent HUD elements.

### 4. Interactable state needs a dedicated autoload
Current fix (dictionary on SceneManager) conflates two responsibilities. A dedicated `WorldState` autoload would be cleaner:
- Stores interactable state keyed by string ID
- Interactables check state in `_ready()` and update on interaction
- Naturally extends to save files (serialize the dictionary)

### 5. Always `call_deferred()` when mutating the tree from `_ready()`
This is a universal Godot rule, not specific to this project. The tree is locked during `_ready()` traversal.

## What Should Change in CLAUDE.md

Already added:
- `.gd` autoloads over `.tscn` (godot#86300)
- `.call()` for duck-typed group methods

Should also add:
- `await get_tree().scene_changed` over `process_frame` counting
- `call_deferred()` required for tree mutations in `_ready()`
- Persistent UI as autoloads, not reparented scene children

## Open Questions

1. Should we refactor SceneManager to use `scene_changed` signal now, or defer to a cleanup pass?
2. Should persistent UI (InteractionPrompt, ItemToast, QuestIndicator) be refactored into autoloads now, or is the reparenting fix acceptable for the prototype?
3. Should interactable state tracking be extracted to a `WorldState` autoload, or stay on SceneManager?
