---
title: "feat: Interaction Prompts, Direction Scoring, Tabbed Menu & Camera-Relative Movement"
type: feat
status: completed
date: 2026-03-21
origin: docs/brainstorms/2026-03-21-interaction-menu-camera-brainstorm.md
---

## Enhancement Summary

**Deepened on:** 2026-03-21
**External research review:** 2026-03-21
**Agents used:** gc-godot-architecture-reviewer, gc-godot-timing-reviewer, gc-godot-performance-reviewer, gc-code-simplicity-reviewer, gc-pattern-recognition-specialist, gc-gdscript-reviewer, gc-resource-safety-reviewer, gc-best-practices-researcher, gc-framework-docs-researcher, gc-repo-research-analyst, gc-learnings-researcher, Context7

### Key Improvements
1. **Camera-relative movement via basis vectors** — use camera forward/right basis decomposition instead of `atan2` angle extraction. Avoids trigonometry entirely, handles camera roll, and is the canonical Godot pattern for 3D camera-relative input (see Phase 1 research)
2. **Hysteresis bonus** — prevent prompt flickering between equidistant interactables. 0.15–0.20 additive bonus confirmed standard (Elden Ring, Witcher 3 use similar patterns)
3. **Label3D readability** — outline, font_size/pixel_size tuning, and render_priority for crisp world-space text. Use `set_draw_flag(FLAG_DISABLE_DEPTH_TEST, true)` API. Never apply `material_override` (breaks billboard — Godot #92379)
4. **`is_instance_valid` guards** — fix existing latent bug in `interact_with_nearest()` and prevent freed-node access during scene transitions. Null checks are insufficient after `queue_free()` — the variable does NOT become null
5. **Explicit tab switching** — handle `ui_left`/`ui_right` in `_input()` on menu script. Disable TabBar `focus_mode` via `get_tab_bar().focus_mode = FOCUS_NONE` to prevent focus stealing
6. **Resource cleanup** — `.uid` sidecar files must be deleted alongside removed source files

### New Considerations Discovered
- `interact_with_nearest()` has a latent freed-node bug (no `is_instance_valid` guard) — fix as part of this work
- `_score_interactable()` match statement needs a default arm to avoid uninitialized `direction` on future enum additions
- Pause tab's Resume/Save/Load should call HUD methods directly (existing pattern), not via signal indirection
- Facing re-evaluation debounce should use dot-product threshold (`< 0.7` = ~45° change), not a timer
- **File path correction:** Plan referenced `scripts/player/states/` but actual path is `scripts/player/player_states/`
- **Scoring: flatten to XZ plane** — zero out `to_target.y` before dot product to prevent vertical offset from skewing scores
- **Label3D: `visible = false` = zero GPU cost** — confirmed by docs; no draw calls, no billboard computation. Use `visible` not `modulate.a` for off-state
- **TabContainer visibility timing** — setting `current_tab` does not immediately update child visibility (Godot #99065). Defer `grab_focus()` after tab switch
- **`alpha_cut` must stay `ALPHA_CUT_DISABLED`** — render_priority only works with this setting, and modulate.a fade requires it

---

# Interaction Prompts, Direction Scoring, Tabbed Menu & Camera-Relative Movement

## Overview

Four related improvements to the player interaction system, in-game UI, and movement controls:

1. **World-space interaction prompts** — Label3D billboards on each interactable showing `[E] Talk to Elena` instead of the generic screen-space "Press E" prompt
2. **Direction-based interaction priority** — Three pluggable scoring strategies (facing bias, facing required, last movement) for selecting the nearest interactable when multiple overlap
3. **Tabbed in-game menu** — TabContainer-based menu with Quest, Inventory, Stats, and Pause tabs, replacing the standalone pause menu
4. **Camera-relative movement** — Decouple player movement from the hardcoded `ISO_ANGLE` constant by reading the camera's actual Y-rotation

## Problem Statement / Motivation

**Interaction prompts:** The current "Press E" prompt gives no context about what the player is interacting with. Players near multiple interactables have no way to tell which one they'll activate.

**Direction scoring:** `_update_nearest_interactable()` selects purely by distance. When two interactables are nearby, the player has no intuitive control over which one is selected — they must physically move closer to the desired target.

**Menu system:** The pause menu is a standalone screen with four buttons. There is no way to view quests, inventory, or character stats in-game. These are fundamental RPG systems that need a unified, extensible menu.

**Camera-relative movement:** Player movement is hardcoded to `ISO_ANGLE = -0.7854` (-45°). If any future room uses a different camera angle, movement will feel wrong. Decoupling this is a small refactor with high future-proofing value.

## Proposed Solution

(see brainstorm: `docs/brainstorms/2026-03-21-interaction-menu-camera-brainstorm.md`)

### Feature 1: Interactable-Owned Label3D Billboards

Each interactable spawns a Label3D child (billboard mode) displaying `[E] <verb> <name>`. The player calls `show_prompt()` / `hide_prompt()` on interactables directly (call-down pattern). Type-based defaults with `@export` overrides for `display_name` and `action_verb`. Replaces `interaction_prompt.gd` CanvasLayer entirely.

### Feature 2: Pluggable Scoring via Enum

An `@export` enum on PlayerController selects one of three strategies: `FACING_BIAS`, `FACING_REQUIRED`, `LAST_MOVEMENT`. Scoring uses dot-product between a direction vector and the vector-to-interactable, combined with inverse distance. Facing direction representation adds a `_facing_vector: Vector3` alongside the existing `_facing_direction: String` — the string remains source of truth for animations and save data; the vector is derived for scoring.

### Feature 3: TabContainer Menu

A single CanvasLayer scene with Godot's built-in TabContainer holding four tab panels (Quest, Inventory, Stats, Pause). Each tab is its own scene. Replaces the standalone `pause_menu.gd`. Tab key opens/closes. Left/right arrows switch tabs. Opens to last-viewed tab (defaults to first). `process_mode = PROCESS_MODE_ALWAYS` on the CanvasLayer and all children.

### Feature 4: Camera Basis Read

Replace `ISO_ANGLE` constant with `_get_camera_angle() -> float` that extracts the camera's horizontal angle via `atan2` on the basis forward vector. Fallback to `DEFAULT_CAMERA_ANGLE` if no camera exists (scene transitions).

## Technical Approach

### Architecture

#### Signal & Data Flow Changes

**Prompt lifecycle (Feature 1):**
```
PlayerController._update_nearest_interactable()
  ├─ if is_instance_valid(_prompted_interactable):
  │     _prompted_interactable.call("hide_prompt")  # call-down
  ├─ _prompted_interactable = new_nearest
  └─ if _prompted_interactable != null:
        _prompted_interactable.call("show_prompt")  # call-down

GameState.game_state_changed → PlayerController._on_game_state_changed()
  └─ if mode != OVERWORLD: hide current prompt
     if mode == OVERWORLD: re-evaluate and show if applicable
```

**Scoring flow (Feature 2):**
```
_update_nearest_interactable()
  ├─ for each body in _interaction_area.get_overlapping_bodies():
  │     if body.has_method("interact"):
  │       score = _score_interactable(body)
  │       track best score (with hysteresis bonus for current selection)
  └─ _score_interactable(body) uses match on _interaction_strategy enum
```

**Menu flow (Feature 3):**
```
HUD._input(event)
  ├─ Tab pressed + current_mode == OVERWORLD:
  │     GameState.set_mode(MENU)
  │     get_tree().paused = true
  │     _game_menu.call("open_menu", can_save_load)
  └─ Tab pressed + _is_menu_open:
        _game_menu.call("close_menu")
        get_tree().paused = false
        GameState.set_mode(_mode_before_pause)

Pause tab Resume/Save/Load → HUD.close_game_menu() (direct call-up, matching existing pattern)
```

#### Files to Create

| File | Purpose |
|---|---|
| `scenes/ui/game_menu.tscn` | CanvasLayer > PanelContainer > TabContainer with four tab scenes |
| `scripts/ui/game_menu.gd` | Menu lifecycle, tab memory, open/close, explicit tab switching input |
| `scenes/ui/tabs/quest_tab.tscn` | Quest list UI |
| `scripts/ui/tabs/quest_tab.gd` | Read-only quest list from QuestTracker |
| `scenes/ui/tabs/inventory_tab.tscn` | Inventory list UI |
| `scripts/ui/tabs/inventory_tab.gd` | Read-only item list from Inventory |
| `scenes/ui/tabs/stats_tab.tscn` | Placeholder stats panel |
| `scripts/ui/tabs/stats_tab.gd` | Placeholder with "Coming Soon" label |
| `scenes/ui/tabs/pause_tab.tscn` | Resume/Save/Load/Quit buttons |
| `scripts/ui/tabs/pause_tab.gd` | Migrated pause logic (buttons only; lifecycle stays in HUD) |

#### Files to Modify

| File | Changes |
|---|---|
| `scripts/player/player_controller.gd` | Add `_facing_vector`, `_prompted_interactable`, `_interaction_strategy` enum, `_get_camera_angle()`, `_score_interactable()`, refactor `_update_nearest_interactable()` and `get_movement_input()`, add `is_instance_valid` guards |
| `scripts/player/player_states/player_walk.gd` | Update `_facing_vector` alongside `_facing_direction` |
| `scripts/player/player_states/player_idle.gd` | No changes needed (facing doesn't update in idle) |
| `scripts/interactables/npc_interactable.gd` | Add Label3D prompt, `show_prompt()`, `hide_prompt()`, `@export display_name` |
| `scripts/interactables/chest_interactable.gd` | Add Label3D prompt, `show_prompt()`, `hide_prompt()`, `@export display_name` |
| `scripts/interactables/door_interactable.gd` | Add Label3D prompt, `show_prompt()`, `hide_prompt()`, `@export display_name` |
| `scripts/autoloads/hud.gd` | Replace `pause_menu` with `game_menu`, remove `interaction_prompt`, update open/close/Tab handling, add OVERWORLD-only guard |
| `scenes/player/player.tscn` | No structural changes needed |

#### Files to Remove

| File | Reason |
|---|---|
| `scripts/ui/interaction_prompt.gd` | Replaced by per-interactable Label3D prompts |
| `scripts/ui/interaction_prompt.gd.uid` | Sidecar for removed script |
| `scenes/ui/interaction_prompt.tscn` | Replaced by per-interactable Label3D prompts |
| `scenes/ui/interaction_prompt.tscn.uid` | Sidecar for removed scene (if exists) |
| `scripts/ui/pause_menu.gd` | Migrated into `pause_tab.gd` within tabbed menu |
| `scripts/ui/pause_menu.gd.uid` | Sidecar for removed script |
| `scenes/ui/pause_menu.tscn` | Migrated into `pause_tab.tscn` within tabbed menu |
| `scenes/ui/pause_menu.tscn.uid` | Sidecar for removed scene (if exists) |

> **Resource safety:** `hud.gd` has `preload()` references to both removed `.tscn` files (lines 17, 23). These preloads are resolved at parse time — deleting the files without updating `hud.gd` first will crash autoload initialization. Update `hud.gd` preload paths **before or atomically with** file deletion.

### Implementation Phases

#### Phase 1: Camera-Relative Movement (Feature 4) — Foundation

This must come first because Feature 2 depends on a facing vector that is consistent with camera-relative movement.

**Tasks:**

- [x] Add `const DEFAULT_CAMERA_ANGLE: float = -PI / 4.0` to replace magic number `-0.7854` (used as fallback only)
- [x] Add `_get_camera() -> Camera3D` helper — cached in `var _camera: Camera3D`, found via `get_viewport().get_camera_3d()`, re-found lazily on null via `is_instance_valid()` (mirrors `camera_follow.gd` pattern)
- [x] Refactor `get_movement_input()` to use **basis vector decomposition** instead of angle rotation: extract camera forward/right, flatten to XZ plane, combine with input. Falls back to `input_dir.rotated(DEFAULT_CAMERA_ANGLE)` if no camera
- [x] Add `_facing_vector: Vector3 = Vector3(0, 0, 1)` to `player_controller.gd` — updated alongside `_facing_direction` string
- [x] Update `update_facing()` to also set `_facing_vector` from the raw input rotated by camera angle (world-space direction)
- [x] Add `get_facing_vector() -> Vector3` public accessor
- [x] Verify: movement feels identical with default isometric camera (no behavioral change)
- [x] Verify: facing direction animations still work correctly

**Key decisions:**
- `_facing_direction: String` remains source of truth for animations and save data (see brainstorm: decision #8)
- `_facing_vector: Vector3` is derived — used only for interaction scoring
- `update_facing()` still takes raw input for animation selection; separately computes world-space vector for scoring
- Null camera fallback preserves current behavior during scene transitions

```gdscript
# scripts/player/player_controller.gd — new constants and methods
const DEFAULT_CAMERA_ANGLE: float = -PI / 4.0

var _camera: Camera3D = null

func _get_camera() -> Camera3D:
    if not is_instance_valid(_camera):
        _camera = get_viewport().get_camera_3d()
    return _camera

## Basis vector decomposition — avoids atan2/rotated() entirely.
## Canonical Godot pattern for camera-relative 3D input.
func get_movement_input() -> Vector3:
    var input_dir: Vector2 = Input.get_vector(
        "move_left", "move_right", "move_forward", "move_back"
    )
    if input_dir.is_zero_approx():
        return Vector3.ZERO

    var cam: Camera3D = _get_camera()
    if cam == null:
        # Fallback: rotate by default isometric angle (scene transitions, tests)
        var rotated: Vector2 = input_dir.rotated(DEFAULT_CAMERA_ANGLE)
        return Vector3(rotated.x, 0.0, rotated.y).normalized()

    # Extract camera's forward and right, flattened to XZ plane
    var cam_forward: Vector3 = -cam.global_transform.basis.z
    cam_forward.y = 0.0
    cam_forward = cam_forward.normalized()

    var cam_right: Vector3 = cam.global_transform.basis.x
    cam_right.y = 0.0
    cam_right = cam_right.normalized()

    var direction: Vector3 = cam_right * input_dir.x + cam_forward * input_dir.y
    return direction.normalized()
```

#### Research Insights — Phase 1

**Why basis vector decomposition over `atan2`:** The original plan used `atan2` on the camera forward vector to extract a rotation angle, then called `input_dir.rotated(angle)`. External research confirms that **basis vector decomposition is the canonical Godot pattern** for camera-relative 3D input. It avoids trigonometry entirely (no `atan2`, no `rotated()`), handles cameras with non-trivial roll, and is the approach shown in official third-person controller examples and community solutions. Both methods produce identical results for the current fixed isometric camera, but basis decomposition generalizes better and is more readable.

**Why not `global_rotation.y`:** `global_rotation` returns Euler angles decomposed using Godot's YXZ convention. For isometric cameras with rotation on multiple axes (both X tilt and Y rotation), Euler decomposition can produce unexpected values due to gimbal lock. Basis vectors avoid this entirely.

**Camera caching pattern:** The existing `camera_follow.gd` already caches its target via `_find_player()` and re-finds lazily. Follow the same pattern for the camera reference — avoids `get_viewport().get_camera_3d()` every physics frame while handling scene transitions gracefully. The official Godot docs recommend validating cached camera references with `is_instance_valid()` and noting that `get_camera_3d()` returns null between scene changes.

**Performance:** Reading `cam.global_transform.basis` is a property access on a cached `Transform3D` — negligible cost. The matrix multiplication (basis * input) is three dot products. This is cheaper than `atan2 + rotated()`.

**Handling future camera transitions:** If camera transitions are added later, continue using the previous camera's basis during the transition. Never interpolate the movement angle during transitions — this causes disorienting "input drift." Snap to the new camera's basis once the transition completes.

---

#### Phase 2: Direction-Based Interaction Scoring (Feature 2)

Depends on Phase 1's `_facing_vector` and `_get_camera_angle()`.

**Tasks:**

- [x] Add `InteractionStrategy` enum to `player_controller.gd`: `FACING_BIAS`, `FACING_REQUIRED`, `LAST_MOVEMENT`
- [x] Add `@export var _interaction_strategy: InteractionStrategy = InteractionStrategy.FACING_BIAS`
- [x] Add `_last_movement_vector: Vector3` — updated in `player_walk.gd` physics_update from the camera-rotated movement direction
- [x] Refactor `_update_nearest_interactable()` to use `_score_interactable(body)` instead of raw `distance_squared_to()`
- [x] Add `is_instance_valid` guard at the top of `_update_nearest_interactable()` to clear stale `_nearest_interactable` references
- [x] Add `is_instance_valid` guard in `interact_with_nearest()` (fixes existing latent bug — `_nearest_interactable` can reference a freed node during scene teardown)
- [x] Implement `_score_interactable(body: Node3D) -> float` with match on `_interaction_strategy` + default arm
- [x] Add hysteresis bonus: current `_nearest_interactable` gets a `HYSTERESIS_BONUS` score addition to prevent flickering
- [x] Re-evaluate nearest on facing direction change — call `_update_nearest_interactable()` when `_facing_vector` changes beyond dot-product threshold (`< 0.7` ≈ 45° change)
- [x] Verify: single interactable behaves identically regardless of strategy
- [x] Verify: two nearby interactables, facing bias correctly favors the one in front
- [x] Verify: no flickering between equidistant interactables during diagonal movement

**Scoring formula:**

```gdscript
const FACING_WEIGHT: float = 0.5  # tune via playtesting
const HYSTERESIS_BONUS: float = 0.2  # bias toward current selection to prevent flickering
const MIN_DISTANCE: float = 0.1
const MOVEMENT_THRESHOLD: float = 0.01
const FACING_CHANGE_THRESHOLD: float = 0.7  # dot product (~45° change triggers re-evaluation)

func _score_interactable(body: Node3D) -> float:
    var to_body: Vector3 = body.global_position - global_position
    to_body.y = 0.0  # Flatten to XZ plane — prevents vertical offset from skewing scores
    var distance: float = to_body.length()
    to_body = to_body.normalized()
    var distance_score: float = 1.0 / maxf(distance, MIN_DISTANCE)

    var direction: Vector3 = _facing_vector  # default, overridden by match
    match _interaction_strategy:
        InteractionStrategy.FACING_BIAS, InteractionStrategy.FACING_REQUIRED:
            direction = _facing_vector
        InteractionStrategy.LAST_MOVEMENT:
            direction = _last_movement_vector if _last_movement_vector.length_squared() > MOVEMENT_THRESHOLD else _facing_vector

    var dot: float = direction.dot(to_body)

    if _interaction_strategy == InteractionStrategy.FACING_REQUIRED and dot <= 0.0:
        return -1.0

    var score: float = distance_score * (1.0 + FACING_WEIGHT * dot)

    # Hysteresis: bias toward current selection to prevent flickering
    if body == _nearest_interactable:
        score += HYSTERESIS_BONUS

    return score
```

**Existing bug fix (must be included):**

```gdscript
# scripts/player/player_controller.gd — fix interact_with_nearest()
func interact_with_nearest() -> void:
    if is_instance_valid(_nearest_interactable) and _nearest_interactable.has_method("interact"):
        _nearest_interactable.call("interact", self)

# At the top of _update_nearest_interactable()
func _update_nearest_interactable() -> void:
    if _nearest_interactable and not is_instance_valid(_nearest_interactable):
        _nearest_interactable = null
    # ... rest of method
```

#### Research Insights — Phase 2

**Hysteresis is standard practice:** AAA RPGs (Witcher 3, Elden Ring lock-on) use sticky selection to prevent target flickering. A bonus of `0.1–0.3` on the current selection prevents ping-ponging without making it hard to intentionally switch. Start at `0.2`.

**Debounce via dot-product, not timer:** Comparing `old_facing.dot(new_facing) < 0.7` prevents re-evaluation during minor analog stick wobble while catching genuine direction changes. Timers add latency and decouple re-evaluation from actual direction change.

**Facing weight `0.5` is a good RPG default:** Gives a `[0.5, 1.5]` multiplier range on distance score. For slow-paced RPG interactions, facing should break ties, not override proximity. Tune range: `0.25` (subtle) to `1.0` (strong).

**`FACING_REQUIRED` threshold:** `dot > 0.0` = forward hemisphere (180° cone). This is lenient but intuitive. A stricter threshold (e.g., `0.5` = 120° cone) can be added later if needed.

---

#### Phase 3: World-Space Interaction Prompts (Feature 1)

Depends on Phase 2's scoring (prompts show on the scored-nearest interactable).

**Tasks:**

- [x] Add `_prompted_interactable: Node3D = null` to `player_controller.gd` — tracks which interactable currently has its prompt visible
- [x] Update `_update_nearest_interactable()`: guard with `is_instance_valid(_prompted_interactable)` before calling `hide_prompt()`, then call `show_prompt()` on new nearest, update `_prompted_interactable`
- [x] Connect `GameState.game_state_changed` in `player_controller.gd`: hide prompt when leaving OVERWORLD, re-evaluate when entering OVERWORLD
- [x] Add to `npc_interactable.gd`:
  - `@export var display_name: String = ""` — falls back to `npc_id` if empty
  - Default `action_verb = "Talk to"` (not exported — type default)
  - `var _prompt_label: Label3D` — created in `_ready()`, billboard mode, hidden by default, positioned above the NPC
  - `func show_prompt() -> void` — sets `_prompt_label.visible = true` (with optional fade tween)
  - `func hide_prompt() -> void` — sets `_prompt_label.visible = false` (with optional fade tween)
  - `func get_prompt_text() -> String` — returns `"[E] %s %s" % [action_verb, display_name]`
- [x] Add same pattern to `chest_interactable.gd` (default verb: "Open")
- [x] Add same pattern to `door_interactable.gd` (default verb: "Enter")
- [x] Remove `interaction_prompt.gd`, `interaction_prompt.tscn`, and their `.uid` sidecars
- [x] Remove interaction prompt instantiation and wiring from `hud.gd` (lines 7, 17-18, 64)
- [x] Remove `nearest_interactable_changed` signal consumer (signal itself may remain for other uses)
- [x] Verify: approaching a single NPC shows "[E] Talk to Elena" above them
- [x] Verify: leaving range hides the prompt
- [x] Verify: switching between two interactables hides old prompt, shows new
- [x] Verify: entering dialogue hides the prompt; returning to overworld re-shows if still in range
- [x] Verify: Label3D text is readable at the isometric camera distance (~20 units)

**Label3D configuration:**

```gdscript
# Created in _ready() of each interactable
const PROMPT_LABEL_OFFSET: Vector3 = Vector3(0.0, 2.0, 0.0)
const PROMPT_PIXEL_SIZE: float = 0.005
const PROMPT_FONT_SIZE: int = 24

func _ready() -> void:
    # ... existing _ready() code ...
    _prompt_label = Label3D.new()
    _prompt_label.text = get_prompt_text()
    _prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    _prompt_label.set_draw_flag(Label3D.FLAG_DISABLE_DEPTH_TEST, true)  # Always on top
    _prompt_label.render_priority = 10
    _prompt_label.pixel_size = PROMPT_PIXEL_SIZE
    _prompt_label.font_size = PROMPT_FONT_SIZE
    _prompt_label.outline_size = 8
    _prompt_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
    _prompt_label.position = PROMPT_LABEL_OFFSET
    _prompt_label.visible = false
    add_child.call_deferred(_prompt_label)
```

#### Research Insights — Phase 3

**Label3D readability tuning:** The Godot docs confirm: "Increase `font_size` while decreasing `pixel_size` for more detailed text when viewing up close." For isometric camera at ~20 unit distance, `pixel_size = 0.005` with `font_size = 24` produces crisper text than `pixel_size = 0.01`. Higher `font_size` causes a one-time stutter when the character texture is first generated — not a concern since prompts are created in `_ready()`. Keep `font_size` at or below 48 to avoid noticeable atlas rasterization stutter.

**Outline is essential for world-space text:** Without it, white text disappears against light terrain and dark text against shadows. `outline_size = 8` with `Color(0, 0, 0, 0.8)` provides contrast without looking harsh.

**`FLAG_DISABLE_DEPTH_TEST` API:** Use `set_draw_flag(Label3D.FLAG_DISABLE_DEPTH_TEST, true)` — this is the correct API (Label3D inherits DrawFlags from SpriteBase3D with enum value 3). Does NOT cause Z-fighting — it bypasses the depth buffer entirely. Tradeoff: prompts visible through walls, acceptable since the player is within Area3D range.

**`render_priority` constraints:** Only works when `alpha_cut` is `ALPHA_CUT_DISABLED` (the default). Only affects sorting among transparent objects. Value `10` ensures prompts draw on top of particle effects. Keep `alpha_cut` as default to allow `modulate.a` fade animations.

**NEVER apply `material_override` to Label3D:** Godot issue #92379 confirms that `material_override` disables billboard behavior entirely. Use `modulate`/`outline_modulate` for color changes instead.

**Hidden Label3D has zero GPU cost:** When `visible = false`, Label3D is excluded from the render list entirely — no draw calls, no billboard computation. This is fundamentally different from `modulate.a = 0` which still issues a draw call. Use `visible = false` for the off-state; only use `modulate.a` during active fade animations.

**`add_child.call_deferred()`:** CLAUDE.md requires `call_deferred()` for tree mutations in `_ready()`. While adding children to self during `_ready()` is generally safe in Godot 4, follow the project convention.

**Alternatives considered (confirmed inferior):** SubViewport + Sprite3D is heavier (separate render pass per viewport — overkill for text). TextMesh generates 3D geometry and regenerates on text change (explicitly documented as slow). Label3D is the standard for world-space text prompts in Godot 3D games.

**Fade animation (optional enhancement):**
```gdscript
var _prompt_tween: Tween = null

func show_prompt() -> void:
    if _prompt_tween and _prompt_tween.is_valid():
        _prompt_tween.kill()
    _prompt_label.visible = true
    _prompt_tween = create_tween()
    _prompt_label.modulate.a = 0.0
    _prompt_tween.tween_property(_prompt_label, "modulate:a", 1.0, 0.15)

func hide_prompt() -> void:
    if _prompt_tween and _prompt_tween.is_valid():
        _prompt_tween.kill()
    _prompt_tween = create_tween()
    _prompt_tween.tween_property(_prompt_label, "modulate:a", 0.0, 0.1)
    _prompt_tween.tween_callback(_prompt_label.set.bind("visible", false))
```

**Prompt duplication across 3 interactables:** The three interactable scripts each get ~15 lines of prompt boilerplate (Label3D creation + show/hide/get_prompt_text). This is acceptable duplication at 3 files — extracting a shared composition node adds scene tree complexity for minimal LOC savings. If a 4th interactable type is added, consider extracting a shared `PromptLabel` child scene at that point.

---

#### Phase 4: Tabbed In-Game Menu (Feature 3)

Independent of Phases 1-3. Can be developed in parallel but listed last for logical ordering.

**Tasks:**

- [x] Create `scripts/ui/game_menu.gd` extending `CanvasLayer`:
  - `layer = 110` (same as current pause menu)
  - `process_mode = PROCESS_MODE_ALWAYS`
  - Contains `TabContainer` child
  - Disable TabBar focus: `_tab_container.get_tab_bar().focus_mode = Control.FOCUS_NONE` in `_ready()`
  - Tracks `_last_tab_index: int = 0` for tab memory
  - Handle tab switching explicitly via `_input()` with `ui_left`/`ui_right` actions (don't rely on TabContainer's built-in focus-based navigation)
  - `func open_menu(can_save_load: bool) -> void` — shows menu, restores last tab, passes `can_save_load` to pause tab, defers focus to active tab
  - `func close_menu() -> void` — saves current tab index, hides menu
- [x] Create `scenes/ui/game_menu.tscn` — CanvasLayer > PanelContainer (full-screen opaque background) > TabContainer
- [x] Create `scripts/ui/tabs/pause_tab.gd`:
  - Migrate button logic from current `pause_menu.gd`
  - Resume/Save/Load buttons call `HUD.close_game_menu()` directly (matching existing `pause_menu.gd` pattern — menu calls HUD method)
  - Quit button works as before
  - `func set_save_load_enabled(enabled: bool) -> void`
  - `func grab_initial_focus() -> void` — focuses Resume button
- [x] Create `scenes/ui/tabs/pause_tab.tscn` — VBoxContainer with Resume, Save, Load, Quit buttons
- [x] Create `scripts/ui/tabs/quest_tab.gd`:
  - Read-only list of quests from QuestTracker
  - Shows quest name + current step description
  - Active quests listed first, completed quests below
  - `func connect_to_player(player: PlayerController) -> void` — wires to QuestTracker signals
  - `func grab_initial_focus() -> void` — focuses first quest item if any exist
- [x] Create `scenes/ui/tabs/quest_tab.tscn` — VBoxContainer with ScrollContainer > VBoxContainer for quest items
- [x] Create `scripts/ui/tabs/inventory_tab.gd`:
  - Read-only list of items from Inventory
  - Shows item name + quantity
  - `func connect_to_player(player: PlayerController) -> void` — wires to Inventory signals
  - `func grab_initial_focus() -> void` — focuses first item if any exist
- [x] Create `scenes/ui/tabs/stats_tab.tscn` — CenterContainer > Label
- [x] Create `scripts/ui/tabs/stats_tab.gd`:
  - Placeholder with centered "Character Stats — Coming Soon" label
  - `func grab_initial_focus() -> void` — no-op (nothing to focus)
- [x] Update `hud.gd`:
  - Replace `_pause_menu` instantiation with `_game_menu` (preload `game_menu.tscn`)
  - Remove `_interaction_prompt` instantiation (handled in Phase 3)
  - Update `_input()` Tab handler: only open when `GameState.current_mode == GameState.GameMode.OVERWORLD` (tighten from current `!= MENU`)
  - Add `close_game_menu()` method (mirrors existing `close_pause_menu()` pattern)
  - Pass `can_save_load` based on `_mode_before_pause == OVERWORLD`
- [x] Remove `pause_menu.gd`, `pause_menu.tscn`, and their `.uid` sidecars
- [x] Ensure no tab script defines `_process()` or `_physics_process()` — tabs should be signal-driven only
- [x] Verify: Tab opens menu to last-viewed tab
- [x] Verify: Left/Right arrows switch tabs from any focused control within a tab
- [x] Verify: Resume in Pause tab closes entire menu
- [x] Verify: Save/Load work from Pause tab
- [x] Verify: Tab key closes menu from any tab
- [x] Verify: Menu cannot open during DIALOGUE, BATTLE, or CUTSCENE modes
- [x] Verify: Quest tab shows active quests from QuestTracker
- [x] Verify: Inventory tab shows items from Inventory

**Tab contents — scope boundaries:**
- Quest tab: read-only list (name + step). No quest detail view, no quest tracking toggle.
- Inventory tab: read-only list (name + quantity). No item use, no item detail, no drag-and-drop.
- Stats tab: placeholder only. No stat values, no character info.
- Pause tab: identical functionality to current pause menu.

**Explicit tab switching input:**

```gdscript
# scripts/ui/game_menu.gd — handle tab switching regardless of focus state
func _input(event: InputEvent) -> void:
    if not visible:
        return
    if event.is_action_pressed("ui_left"):
        _tab_container.current_tab = wrapi(
            _tab_container.current_tab - 1, 0, _tab_container.get_tab_count()
        )
        get_viewport().set_input_as_handled()
    elif event.is_action_pressed("ui_right"):
        _tab_container.current_tab = wrapi(
            _tab_container.current_tab + 1, 0, _tab_container.get_tab_count()
        )
        get_viewport().set_input_as_handled()

func _on_tab_container_tab_changed(tab: int) -> void:
    _last_tab_index = tab
    # Defer focus so the new tab's controls are ready
    _set_tab_focus.call_deferred(tab)

func _set_tab_focus(tab: int) -> void:
    var tab_control: Control = _tab_container.get_tab_control(tab)
    if tab_control.has_method("grab_initial_focus"):
        tab_control.call("grab_initial_focus")
```

#### Research Insights — Phase 4

**Why explicit tab switching:** TabContainer's built-in keyboard navigation only works when the TabBar itself has focus. Once a child control inside a tab grabs focus (e.g., Resume button in Pause tab), left/right navigates within that tab's controls instead of switching tabs. Handling `ui_left`/`ui_right` in `_input()` on the menu script ensures tab switching always works regardless of focus state.

**Disable TabBar focus_mode:** The internal TabBar is a separate focusable Control that can steal focus from tab content. Add `_tab_container.get_tab_bar().focus_mode = Control.FOCUS_NONE` in `_ready()` to prevent this. This is confirmed best practice from Godot community solutions.

**TabContainer visibility timing (Godot #99065):** Setting `current_tab` does NOT immediately update child visibility. If you call `grab_focus()` on a control inside the new tab immediately after switching, it may fail silently because the control is not yet visible. Always defer focus grabs: `_grab_tab_focus.call_deferred()`.

**Gamepad focus drop:** `grab_focus()` can silently fail when the last input was from a gamepad and no control currently has focus. Workaround: check `get_viewport().gui_get_focus_owner()` and force-grab if null.

**`process_mode = PROCESS_MODE_ALWAYS` propagation:** Confirmed by Godot docs: children inherit the parent's `process_mode` by default (`PROCESS_MODE_INHERIT`). As long as no tab scene explicitly overrides `process_mode` in the inspector, all tabs will process input while the tree is paused. **Critical:** if any child explicitly sets `PROCESS_MODE_PAUSABLE`, it will stop receiving input during pause even if the parent is `ALWAYS`.

**No `_process()` on tab scripts:** TabContainer hides non-active tabs (`visible = false`) but does NOT disable their `_process()` callbacks. If any tab defines `_process()`, it runs every frame regardless of which tab is active. Since tabs are read-only lists populated on menu open, they should be signal-driven only.

**Signals still fire during pause:** Connected functions run even if attached to paused nodes (signals bypass process_mode). However, button `pressed` signals require the button to receive input events, which requires `PROCESS_MODE_ALWAYS` or `WHEN_PAUSED`.

**Focus management:** Each tab implements `grab_initial_focus()` (duck-typed via `.call()`). This is called deferred after tab switch so the new tab's controls are ready. Stats tab's `grab_initial_focus()` is a no-op — the placeholder label doesn't need focus. This is simpler than a dummy invisible button.

**JRPG tab switching conventions:** L/R shoulder buttons (or `ui_left`/`ui_right`) cycle tabs. D-pad/stick navigates within the current tab. B/Cancel closes the menu. Tab indicators should visually highlight the active tab.

**ScrollContainer for Quest/Inventory:** VBoxContainer inside ScrollContainer recalculates layout only when children change, not per-frame. Scrolling is GPU-handled. No virtualization needed — an RPG with 50 quests and 100 items is well within comfortable range.

**Opaque background:** Use a PanelContainer with an opaque StyleBox as the menu background. This prevents Label3D prompts from bleeding through the menu overlay in 3D space.

---

## System-Wide Impact

### Signal Chain

- `InteractionArea.body_entered/exited` → `_update_nearest_interactable()` → `show_prompt()`/`hide_prompt()` calls on interactables + `nearest_interactable_changed` signal (retained for any other consumers)
- `GameState.game_state_changed` → `PlayerController._on_game_state_changed()` → hides prompts when leaving OVERWORLD
- `GameState.game_state_changed` → `HUD._on_game_state_changed()` (new) → blocks menu input in non-OVERWORLD modes
- Pause tab buttons → `HUD.close_game_menu()` → unpauses tree, restores GameState (direct call, matching existing pattern)

### Error Propagation

- Null camera in `_get_camera_angle()`: fallback to `DEFAULT_CAMERA_ANGLE` constant, no error logged (expected during transitions)
- Interactable freed while prompted: `_prompted_interactable` becomes invalid. Guard with `is_instance_valid()` before calling `hide_prompt()`
- Empty `display_name`: prompt shows `[E] Talk` without a name — acceptable degraded state
- **Existing bug fix:** `interact_with_nearest()` must add `is_instance_valid(_nearest_interactable)` guard (currently missing — freed-node access possible during scene teardown)

### State Lifecycle Risks

- **Menu open + scene load**: Current ordering (close menu → unpause → load) must be preserved. Pause tab Load button calls `HUD.close_game_menu()` first, then triggers load.
- **Prompt on freed interactable**: Use `is_instance_valid(_prompted_interactable)` check. The Label3D is a child of the interactable and freed with it automatically.
- **Save data**: `_facing_vector` is NOT saved. It is derived from `_facing_direction` string on load. `_last_tab_index` is NOT saved — menu state is session-only.
- **Invariant:** `can_save_load` in HUD must remain `false` during DIALOGUE mode — the NPC coroutine's `GameState.set_mode(OVERWORLD)` after `await dialogue_ended` depends on this to avoid orphaned state.

### Scene Interface Parity

- All three interactable scripts (`npc_interactable.gd`, `chest_interactable.gd`, `door_interactable.gd`) must implement `show_prompt()`, `hide_prompt()`, and `get_prompt_text()` with the same signature
- All four tab scripts must implement `connect_to_player()` if they need player data
- All four tab scripts should implement `grab_initial_focus()` for focus management on tab switch

## Acceptance Criteria

### Functional Requirements

- [x] Approaching an interactable shows a Label3D billboard with `[E] <verb> <name>` above it
- [x] Leaving range hides the prompt; switching nearest hides old and shows new
- [x] Prompts hide during DIALOGUE, MENU, BATTLE, CUTSCENE modes
- [x] With two nearby interactables, facing the desired one (FACING_BIAS) increases its selection priority
- [x] FACING_REQUIRED excludes interactables behind the player
- [x] LAST_MOVEMENT uses the last movement direction for scoring
- [x] No flickering between equidistant interactables (hysteresis)
- [x] Interaction strategy is switchable via `@export` enum in the editor
- [x] Tab key opens a tabbed menu with Quest, Inventory, Stats, and Pause tabs
- [x] Menu only opens in OVERWORLD mode
- [x] Left/Right arrows switch tabs regardless of which control has focus; menu remembers last-viewed tab
- [x] Resume button closes the entire menu, not just the Pause tab
- [x] Save/Load work from the Pause tab identically to the old pause menu
- [x] Player movement corresponds to the camera's actual orientation (currently identical behavior; verified with default camera)
- [x] Movement does not break during scene transitions (null camera fallback)

### Non-Functional Requirements

- [x] No new autoloads — all changes use existing autoload structure
- [x] All new code is strictly typed (every var, param, return)
- [x] Label3D prompts use `.call()` pattern for duck-typed methods
- [x] `gdformat` and `gdlint` pass on all new/modified files
- [x] No `.tscn` structural edits (Label3D nodes created programmatically in `_ready()`)
- [x] All magic numbers extracted to named constants
- [x] No `_process()` or `_physics_process()` on tab scripts
- [x] `.uid` sidecar files deleted alongside removed source files

## Dependencies & Risks

| Risk | Mitigation |
|---|---|
| Label3D text readability at varying distances | `pixel_size = 0.005`, `font_size = 24`, `outline_size = 8` with black outline; tune in-editor |
| Scoring weights feel wrong | `FACING_WEIGHT` is a named constant, easy to tune; `HYSTERESIS_BONUS` prevents flickering |
| TabContainer theme doesn't match game aesthetic | Use default Godot theme initially; visual polish via `get_tab_bar().add_theme_stylebox_override()` is a separate pass |
| Tab input not working while paused | `process_mode = PROCESS_MODE_ALWAYS` on CanvasLayer; explicit `_input()` tab switching bypasses focus issues |
| Facing re-evaluation overhead | Dot-product threshold (`< 0.7`) prevents unnecessary re-evaluation during minor input wobble |
| Freed-node access during scene transitions | `is_instance_valid()` guards on `_nearest_interactable` and `_prompted_interactable` |
| Camera null between scenes | Cached camera reference with lazy re-find + `DEFAULT_CAMERA_ANGLE` fallback |
| `hud.gd` preload crash on file deletion | Update preload paths before or atomically with deleting old `.tscn` files |

## Sources & References

### Origin

- **Brainstorm document:** [docs/brainstorms/2026-03-21-interaction-menu-camera-brainstorm.md](docs/brainstorms/2026-03-21-interaction-menu-camera-brainstorm.md)
- Key decisions carried forward: Label3D billboards (decision #2), three scoring strategies via enum (decision #3), TabContainer with four tabs (decision #4), camera basis read (decision #6), facing direction dual representation (decision #8)

### Internal References

- Interaction system: `scripts/player/player_controller.gd` (lines 115-141: `_update_nearest_interactable`)
- Current prompt: `scripts/ui/interaction_prompt.gd`
- HUD autoload: `scripts/autoloads/hud.gd`
- Pause menu: `scripts/ui/pause_menu.gd`
- Camera: `scripts/camera/camera_follow.gd`
- Player states: `scripts/player/player_states/player_walk.gd`, `scripts/player/player_states/player_idle.gd`
- Interactables: `scripts/interactables/npc_interactable.gd`, `chest_interactable.gd`, `door_interactable.gd`
- GameState: `scripts/autoloads/game_state.gd`
- Input actions: `project.godot` (lines 49-83)

### External References

- [Label3D docs](https://docs.godotengine.org/en/stable/classes/class_label3d.html) — pixel_size, font_size, billboard, FLAG_DISABLE_DEPTH_TEST, render_priority
- [3D Text Guide](https://docs.godotengine.org/en/stable/tutorials/3d/3d_text.html) — Label3D vs TextMesh vs SubViewport comparison
- [Label3D material_override breaks billboard (#92379)](https://github.com/godotengine/godot/issues/92379) — never apply material_override to Label3D
- [TabContainer docs](https://docs.godotengine.org/en/stable/classes/class_tabcontainer.html) — tab_changed signal, keyboard navigation
- [TabContainer current_tab visibility timing (#99065)](https://github.com/godotengine/godot/issues/99065) — defer focus after tab switch
- [GUI Navigation docs](https://docs.godotengine.org/en/stable/tutorials/ui/gui_navigation.html) — focus management
- [Pausing games and process mode](https://docs.godotengine.org/en/stable/tutorials/scripting/pausing_games.html) — PROCESS_MODE_ALWAYS inheritance, input callbacks during pause
- Dot product scoring: standard game dev pattern for directional target selection (Elden Ring lock-on, Zelda Z-targeting, AI vision cones)
- [Improving Elden Ring's Lock-On Experience](https://www.jeleniauskas.com/writing/improving-elden-ring's-lock-on-experience) — multi-factor scoring with distance, facing, obstruction
- Camera-relative input: basis vector decomposition preferred over `atan2` angle extraction (canonical Godot pattern for 3D input)
