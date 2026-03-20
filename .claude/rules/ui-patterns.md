---
paths:
  - "scripts/ui/**"
  - "scenes/ui/**"
---

# UI Patterns

- UI scripts expose `connect_to_player(player: PlayerController)` as a public method. HUD autoload calls it — UI scripts do not self-connect via group lookup.
- No reparenting in `_ready()`. HUD autoload owns UI instantiation via `preload().instantiate()`. UI scenes are children of HUD and persist across scene transitions naturally.
- HUD uses `.call("connect_to_player", player)` for duck-typed dispatch because the children are typed as `CanvasLayer` (strict typing can't see the script method).
- Use `_input()` (not `_unhandled_input()`) for pause/menu toggle actions. If the action key overlaps with UI focus navigation (e.g., Tab), `_unhandled_input()` never sees it because Button focus handling consumes it first. Call `set_input_as_handled()` to prevent propagation.
- HUD sets `process_mode = PROCESS_MODE_ALWAYS` and uses `get_tree().paused = true/false` when opening/closing the pause menu. CanvasLayer ordering affects rendering but NOT input exclusivity — tree pause is required to block input to layers behind the pause menu (e.g., dialogue balloon).
- Save/load must be disabled when pausing from non-OVERWORLD modes (e.g., DIALOGUE). Loading mid-dialogue frees the NPC while its coroutine awaits `DialogueManager.dialogue_ended` — the `is_instance_valid(self)` guard prevents restoring OVERWORLD, leaving GameState permanently stuck. Saving captures partial quest mutations (advance without item removal).
