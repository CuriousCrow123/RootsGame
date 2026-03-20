---
paths:
  - "scripts/interactables/**"
  - "scenes/interactables/**"
---

# Interactable Patterns

- Two-tier group system: `"saveable"` (disk persistence, SaveManager iterates) vs `"interactable_saveable"` (session state, WorldState iterates). Both use the same three-method duck-typed contract: `get_save_key()`, `get_save_data()`, `load_save_data()`.
- Chests call `WorldState.set_state()` immediately on interaction for session state, in addition to implementing the duck-typed contract for WorldState's `snapshot()`/`restore()` orchestration.
- WorldState passes `.duplicate(true)` when pushing data to interactables via `load_save_data()` to prevent shared reference mutation.
