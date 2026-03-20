---
paths:
  - "scripts/autoloads/**"
---

# Autoload Patterns

- Autoload order matters: EventBus, GameState, DialogueManager, WorldState, SceneManager, SaveManager, HUD. Wrong order causes null references at startup.
- WorldState restore must happen AFTER `scene_change_completed` in `_restore_save_data()`. `SceneManager.change_scene()` calls `WorldState.snapshot()` before freeing the old scene — loading WorldState before the scene change means `snapshot()` clobbers the loaded data.
- Use identity checks (`node == WorldState`) over string comparison (`key == "world_state"`) when skipping nodes in saveable iteration.
- `player_registered` signal lives on SceneManager (owns player lifecycle), not EventBus. EventBus is reserved for genuinely cross-system events.
- If `load_save_data()` needs Resource references to reconstruct state (e.g., QuestTracker needs QuestData), save the `resource_path` and `load()` it on restore.
- SaveManager always reloads the scene on load (even if already on the saved scene) to guarantee clean slate for scene-local state.
- When extracting values from untyped `Dictionary` for typed parameters, use an intermediate typed variable: `var world_data: Dictionary = data["world_state"]` before passing to a function expecting `Dictionary`.
- Typed dictionaries (e.g., `Dictionary[String, Dictionary]`) cannot receive `data.duplicate(true)` from JSON — the duplicate returns untyped `Dictionary`. Rebuild entry-by-entry: `for key in data: _state[key] = (data[key] as Dictionary).duplicate(true)`.
