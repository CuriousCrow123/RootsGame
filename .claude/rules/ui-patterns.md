---
paths:
  - "scripts/ui/**"
  - "scenes/ui/**"
---

# UI Patterns

- UI scripts expose `connect_to_player(player: PlayerController)` as a public method. HUD autoload calls it — UI scripts do not self-connect via group lookup.
- No reparenting in `_ready()`. HUD autoload owns UI instantiation via `preload().instantiate()`. UI scenes are children of HUD and persist across scene transitions naturally.
- HUD uses `.call("connect_to_player", player)` for duck-typed dispatch because the children are typed as `CanvasLayer` (strict typing can't see the script method).
