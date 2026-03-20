---
paths:
  - "scripts/interactables/**"
  - "scenes/interactables/**"
---

# Interactable Patterns

- Chests call `WorldState.set_state()` immediately on interaction for session state, in addition to the saveable contract (see CLAUDE.md) for WorldState's `snapshot()`/`restore()` orchestration.
- WorldState passes `.duplicate(true)` when pushing data to interactables via `load_save_data()` to prevent shared reference mutation.
- `load_save_data()` must update visuals unconditionally (both opened and closed states). WorldState `restore()` runs on existing nodes during scene transitions, not just fresh ones.
