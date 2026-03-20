---
paths:
  - "scripts/autoloads/**"
---

# Autoload Patterns

- Autoload order matters: EventBus, GameState, DialogueManager, WorldState, SceneManager, SaveManager, HUD. Wrong order causes null references at startup.
- WorldState restore must happen AFTER `scene_change_completed` in `_restore_save_data()`. `SceneManager.change_scene()` calls `WorldState.snapshot()` before freeing the old scene — loading WorldState before the scene change means `snapshot()` clobbers the loaded data.
- Use identity checks (`node == WorldState`) over string comparison (`key == "world_state"`) when skipping nodes in saveable iteration.
- `player_registered` signal lives on SceneManager (owns player lifecycle), not EventBus. EventBus is reserved for genuinely cross-system events.
- `load_save_data()` replaces entire state (not merge) to avoid stale data after loading a save file.
- When extracting values from untyped `Dictionary` for typed parameters, use an intermediate typed variable: `var world_data: Dictionary = data["world_state"]` before passing to a function expecting `Dictionary`.
