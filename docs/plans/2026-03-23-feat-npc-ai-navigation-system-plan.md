---
title: "feat: NPC AI Navigation System"
type: feat
status: active
date: 2026-03-23
origin: docs/brainstorms/2026-03-22-npc-ai-navigation-brainstorm.md
---

# feat: NPC AI Navigation System

## Enhancement Summary

**Deepened on:** 2026-03-23
**Sections enhanced:** All major sections
**Research agents used:** Architecture reviewer, Timing reviewer, Performance reviewer, Pattern recognition, Code simplicity, Resource safety, Framework docs (Godot 4.6 NavigationAgent3D), BT best practices, godot-patterns skill analysis, GridMap learnings

### Critical Bugs Found (Must Fix)

1. **SaveManager restore ordering** — `NPCWorldManager.populate_room()` runs during `change_scene()` with stale registry data, BEFORE `load_save_data()` overwrites it from the save file. NPCs spawn at wrong positions on load. Fix: pre-load NPCWorldManager's registry before the scene change, same pattern as WorldState.
2. **Nav map not synced on first frame** — `populate_room()` calls `NavigationServer3D.map_get_closest_point()` immediately after `scene_changed`, but the nav map hasn't synced yet (iteration_id == 0). Fix: defer nav-mesh-dependent operations or use the `map_get_iteration_id` guard.
3. **BT scene sub-resources shared across instances** — `PackedScene.instantiate()` creates unique nodes but shares exported `.tres` sub-resources. If any BT leaf mutates an exported Resource, all NPCs sharing that BT corrupt each other. Fix: convention that BT leaves never mutate exported Resources, or `.duplicate()` in `bt_enter()`.

### Key Improvements from Research

- **Simplify BT serialization** — Production BTs (Unreal, LimboAI) serialize the blackboard, not tree execution state. The reactive Selector naturally resumes correct behavior from blackboard state. Drop `bt_get_state()`/`bt_load_state()` from composites/decorators; only leaves need it.
- **Centralize distance-based activation** — Per-NPC `_process()` polling defeats the purpose. Move activation checks to `NPCWorldManager._process()` with round-robin staggering; use `set_physics_process(false)` on dormant NPCs for zero per-frame cost.
- **Use `%UniqueNodeNames`** — Replace `owner.get_node("NavigationAgent3D")` with `%NavigationAgent3D` scene unique names for robust internal references.
- **AnimationController: call down, don't poll** — `npc_controller.gd` should call `_animation_controller.update(velocity)` in `_physics_process()` after `move_and_slide()`, not have AnimationController poll `owner.velocity`.
- **Pause BT between snapshot and scene change** — `snapshot_room()` should disable BT physics processing on all room NPCs to prevent state drift before `change_scene_to_file()`.
- **Validate `behavior_tree_path` on load** — Guard with `ResourceLoader.exists()` before `load()`. Fall back to default BT scene or `push_error()`.
- **Add NPC container node in rooms** — Dynamically spawned cross-room NPCs should be added to a designated "NPCs" container, not the scene root.
- **Remove `class_name` from NPCWorldManager** — No existing autoload uses `class_name`. Follow convention.
- **Default tick_interval to 0.15** (not 0.0) — Prevents accidental per-frame ticking when designers forget to set it. Explicit `0.0` for NPCs that truly need per-frame.
- **Verify GridMap tile import settings** before nav mesh baking — `apply_root_scale=true` and Apply MeshInstance Transforms must be enabled or nav mesh geometry won't match visible room geometry (from GridMap learnings).

### YAGNI Deferred (Build When Needed)

- BTParallel, BTCooldown, BTTimeLimit — no described behavior uses them
- BTPlayAnimation — AnimationController already handles velocity-to-animation
- BTFollowPath — no Path3D curves exist in the project yet
- IsTimeInRange placeholder — a node that returns FAILURE adds nothing
- Composite/decorator state serialization — BT restarts from root; only leaf state matters

## Overview

Build a foundational NPC AI navigation system with node-based behavior trees, NavigationAgent3D pathfinding, cross-room tracking via a new NPCWorldManager autoload, and full persistence across scene transitions and saves. The system supports multiple movement behaviors (patrol, wander, follow, path-follow, schedule-based) and integrates with the existing interaction, dialogue, save/load, and scene transition systems.

This is the largest system addition to the project since the initial RPG foundation. It touches autoloads, scene composition, the save system, and scene transitions. The plan is phased to deliver value incrementally and catch integration issues early.

## Problem Statement / Motivation

NPCs are currently static `StaticBody3D` nodes with no movement, no navigation, no state machine, and no persistence. The world feels lifeless. This system enables:
- **Atmosphere** — NPCs wander towns, patrol routes, react to the player
- **Gameplay mechanics** — escort quests, fleeing enemies, guard patrols, NPC roadblocks
- **Schedules** — NPCs follow time-based routines (deferred until a game-time system exists)

## Proposed Solution

A **node-based Behavior Tree framework** where each BT node is a Godot `Node`, composed visually in the scene tree, saved as `PackedScene`. NPCs use `NavigationAgent3D` for pathfinding within `NavigationRegion3D`-baked rooms. An `NPCWorldManager` autoload tracks all NPCs globally for cross-room movement and off-screen simulation. (See brainstorm: `docs/brainstorms/2026-03-22-npc-ai-navigation-brainstorm.md`)

## Critical Architectural Decisions

These questions were identified by SpecFlow analysis and resolved here. They are load-bearing — changing them later requires significant rework.

### AD1: NPC Spawn Authority — Scene-First with Manager Override

NPCs are placed in `.tscn` files by the level designer and self-register with `NPCWorldManager` in `_ready()`. NPCWorldManager is **not** the spawn authority for room-native NPCs — it only spawns NPCs that have **migrated** to a room they were not originally placed in (cross-room movement). On room load, NPCWorldManager checks if any off-screen NPCs should be in this room and instantiates them dynamically.

**Duplicate prevention:** NPCWorldManager tracks which NPCs are "away from home" (in a different room than their `.tscn` origin). When a room loads, scene-native NPCs self-register. NPCWorldManager only spawns NPCs whose `home_room != current_room` and who are tracked as being in `current_room`.

**Why:** Preserves the existing level-design workflow (place NPCs in the editor), avoids a massive migration to fully dynamic spawning, and keeps the common case simple. Cross-room movement is the exception, handled by the manager.

### AD2: Reactive Selector (Re-evaluates from First Child Each Tick)

The `BTSelector` composite re-evaluates from child 0 every tick, even if a lower-priority child was RUNNING. If a higher-priority child returns SUCCESS or RUNNING, the previously-RUNNING child receives `bt_exit()` (interrupted).

**Why:** Required for the player-awareness pattern. If the NPC is patrolling (branch 3, RUNNING) and the player enters the inner zone (branch 1, IsPlayerNear succeeds), the patrol must be interrupted. A resumptive Selector would require explicit abort decorators — unnecessary complexity.

**BTSequence** is resumptive — it resumes from the RUNNING child, not from child 0. This is the standard BT convention.

### AD3: SceneManager Integration Points

NPCWorldManager hooks into the existing scene transition flow:

```
SceneManager.change_scene():
  1. _is_transitioning = true, emit scene_change_started
  2. Fade out
  3. WorldState.snapshot()
  4. NPCWorldManager.snapshot_room(current_room)     ← NEW
  5. get_tree().change_scene_to_file(path)
  6. await get_tree().scene_changed
  7. NPCWorldManager.populate_room(new_room)          ← NEW
  8. WorldState.restore()
  9. Fade in
  10. emit scene_change_completed
```

NPCWorldManager.snapshot_room() iterates all registered NPCs in the current room, captures their state (position, BT state, blackboard-serializable keys), stores it in the registry, **and disables BT physics processing** on all room NPCs to prevent state drift before the scene is freed. NPCWorldManager.populate_room() spawns any NPCs that should be in the room but aren't scene-native (cross-room migrants), adding them to the room's "NPCs" container node.

**Why:** Matches the existing WorldState.snapshot()/restore() pattern exactly. SceneManager already owns the transition flow — extending it with two more calls is minimal coupling.

### Research Insight: SaveManager Restore Ordering (CRITICAL)

`SaveManager._restore_save_data()` calls `SceneManager.change_scene()` BEFORE restoring individual saveables. This means `NPCWorldManager.populate_room()` runs with **stale registry data** during the load's scene change. Only afterward does `load_save_data()` overwrite the registry with save-file data.

**Required fix:** NPCWorldManager needs the same special treatment as WorldState in `_restore_save_data()`:
1. `_restore_save_data()` pre-loads NPCWorldManager's registry from save data BEFORE calling `change_scene()`
2. The scene change's `populate_room()` now uses correct save-file data
3. After `scene_change_completed`, call `NPCWorldManager.restore()` to push registry state to live NPC instances (matching WorldState's two-step pattern)
4. In the remaining-saveables loop, skip NPCWorldManager with `if node == NPCWorldManager: continue`

This mirrors the existing WorldState special-case at `save_manager.gd:104-106`.

### AD4: BT State Serialization — Blackboard-First (Simplified from Research)

**Production BTs (Unreal, LimboAI) do NOT serialize tree execution state.** They serialize the blackboard. The tree naturally resumes correct behavior from blackboard state because the reactive Selector re-evaluates from root each tick. (Source: Unreal BehaviorTreeComponent marks internal state `transient`; LimboAI has no built-in save/load for tree execution state.)

**Simplified approach:** Only **leaf nodes** implement optional `bt_get_state() -> Dictionary` / `bt_load_state(data: Dictionary)` for behavior-specific state (waypoint index, elapsed time). Composites and decorators do NOT serialize — the BT restarts from root on restore and naturally finds the correct branch.

```gdscript
# BehaviorTreeRunner serialization — leaf-only walk
func get_bt_state() -> Dictionary:
    var state: Dictionary = {}
    _collect_leaf_state(_bt_root, "", state)
    return state

func _collect_leaf_state(node: BTNode, path: String, state: Dictionary) -> void:
    if node is BTLeaf:
        var leaf_state: Dictionary = node.bt_get_state()
        if not leaf_state.is_empty():
            state[path] = leaf_state
    for i: int in node.get_child_count():
        var child: BTNode = node.get_child(i) as BTNode
        if child:
            _collect_leaf_state(child, path + "/" + child.name, state)
```

**Default implementation:** `bt_get_state()` returns `{}` (nothing to save). Leaves opt in by overriding. On restore, `bt_load_state()` should silently skip unknown paths (tree structure may change between game versions).

**Blackboard persistence:** Serializable blackboard keys (primitives, Vectors, Strings) are saved alongside the BT state. Transient keys (node references like `"npc"`, `"nav_agent"`) are rebuilt fresh from the NPC node on instantiation. Use naming convention: keys starting with `_` are transient and not saved.

### AD5: Transit State Serialization

NPCs in transit are serialized as:
```gdscript
{
    "is_in_transit": true,
    "from_room": "res://scenes/world/test_room.tscn",
    "to_room": "res://scenes/world/test_room_2.tscn",
    "progress": 0.6,  # 0.0-1.0
    "behavior_tree_path": "res://scenes/npc/behaviors/guard_bt.tscn",
    "bt_state": { ... }
}
```

On load: if `progress >= 0.5`, NPC spawns in `to_room` at the entry point. Otherwise, NPC spawns in `from_room` at the exit point. This avoids the "NPC in limbo" problem.

### AD6: Static NPCs Remain StaticBody3D

Existing static NPCs (shopkeepers, quest givers who never move) keep `StaticBody3D` and the current `npc_interactable.gd` script. They do **not** use the BT framework. The blackboard `"npc"` key is typed as `Node3D` (common ancestor of both `CharacterBody3D` and `StaticBody3D`) to support both NPC types in shared BT conditions like `IsPlayerNear`.

Moving NPCs use a new `npc_controller.gd` extending `CharacterBody3D`. Both scripts implement the interaction protocol (`interact()`, `get_prompt_text()`, `show_prompt()`, `hide_prompt()`).

**Why:** Refactoring working static NPCs to CharacterBody3D adds complexity with zero functional benefit. Two NPC types is acceptable — the interaction protocol is duck-typed, so the player doesn't care.

### AD7: Blackboard Rebuild on Re-instantiation

When a destroyed-and-recreated NPC has its BT state restored, `BehaviorTreeRunner` rebuilds the blackboard in two steps:
1. **Standard keys** populated from the NPC node (npc, nav_agent, base_speed, home_position) — always fresh
2. **BT-written keys** restored from saved BT state — each BTNode's `bt_load_state()` can write to the blackboard during restoration

The `"player"` key starts as `null` and is set when the awareness area detects the player. BT nodes that read `"player"` must handle null gracefully (return FAILURE if player required but absent).

## Technical Approach

### Architecture

```
scripts/
  autoloads/
    npc_world_manager.gd          # NEW — cross-room NPC tracking, off-screen sim
  npc/
    npc_controller.gd             # NEW — CharacterBody3D, moving NPC root script
    animation_controller.gd       # NEW — velocity→animation+facing
shared/
  behavior_tree/
    bt_node.gd                    # NEW — base class, tick/enter/exit
    bt_composite.gd               # NEW — base composite
    bt_decorator.gd               # NEW — base decorator
    bt_leaf.gd                    # NEW — base leaf
    bt_runner.gd                  # NEW — BehaviorTreeRunner
    bt_keys.gd                  # NEW — StringName constants for blackboard keys
    composites/
      bt_selector.gd             # NEW — reactive selector (Phase 1)
      bt_sequence.gd             # NEW — resumptive sequence (Phase 1)
    decorators/
      bt_repeater.gd             # NEW (Phase 1)
      bt_inverter.gd             # NEW (Phase 1)
    conditions/
      bt_is_player_near.gd       # NEW (Phase 2)
      bt_is_at_position.gd       # NEW (Phase 2)
      bt_random_chance.gd        # NEW (Phase 2)
      bt_is_quest_state.gd       # NEW (Phase 4)
    actions/
      bt_idle.gd                 # NEW (Phase 2)
      bt_patrol_route.gd         # NEW (Phase 2)
      bt_wander_radius.gd        # NEW (Phase 2)
      bt_follow_target.gd        # NEW (Phase 2)
      bt_face_target.gd          # NEW (Phase 2)
      bt_talk_to_player.gd       # NEW (Phase 2)
      bt_wait.gd                 # NEW (Phase 2)
      bt_wander_in_zone.gd       # NEW (Phase 4)
# Future (add when needed): bt_parallel, bt_cooldown, bt_time_limit,
# bt_follow_path, bt_play_animation, bt_is_time_in_range
scenes/
  npc/
    moving_npc.tscn              # NEW — CharacterBody3D composition
    behaviors/
      patrol_example_bt.tscn     # NEW — example BT scene
      wander_example_bt.tscn     # NEW
resources/
  npc/                           # NEW — NPC-specific resources if needed
```

### NPC Node Composition (moving_npc.tscn)

```
MovingNPC (CharacterBody3D, script: npc_controller.gd)
├── CollisionShape3D (CapsuleShape3D, r=0.3, h=1.8)
├── %AnimatedSprite3D (billboard, pixel_size=0.035)
├── %AnimationController (Node, script: animation_controller.gd)
├── %NavigationAgent3D (avoidance_enabled=true, see recommended values below)
├── %AwarenessArea (Area3D, SphereShape3D r=5.0, collision_mask=2 player)
├── %InteractionArea (Area3D, SphereShape3D r=2.0, collision_mask=2 player)
├── %BehaviorTreeRunner (Node, script: bt_runner.gd, @export tick_interval=0.15)
│   └── [BT PackedScene instantiated as child]
└── Label3D (interaction prompt, created in _ready via call_deferred)
```

All internal child nodes use `%UniqueNodeName` for robust references (no string paths).

**Collision configuration for MovingNPC:**
- `collision_layer = 4` (npcs, layer 3)
- `collision_mask = 7` (environment layer 1 + player layer 2 + npcs layer 3)
- AwarenessArea: `collision_layer = 0`, `collision_mask = 2` (detect player only)
- InteractionArea: `collision_layer = 0`, `collision_mask = 2` (detect player only)

### Research Insight: NavigationAgent3D Recommended Values (1x1x1 GridMap)

From Godot 4.6 docs, tuned for capsule r=0.3 h=1.8 on 1x1 GridMap:

| Property | Default | Recommended | Reason |
|----------|---------|-------------|--------|
| `path_desired_distance` | 1.0 | **0.5** | Half a cell — default 1.0 skips waypoints on tight corners |
| `target_desired_distance` | 1.0 | **0.5** | Stops close enough to interact without clipping |
| `radius` | 0.5 | **0.3** | Match capsule collision radius |
| `height` | 1.0 | **1.8** | Match capsule height |
| `max_speed` | 10.0 | **4.0** | Match NPC walk speed (avoidance clamps to this) |
| `neighbor_distance` | 50.0 | **10.0** | Sufficient for indoor RPG rooms |
| `use_3d_avoidance` | false | **false** | 2D XZ plane avoidance is sufficient for ground NPCs |

**NavigationMesh baking values:**
- `cell_size = 0.25` (4 voxels per grid cell, matches default navigation map)
- `cell_height = 0.25` (matches default navigation map — **must match**)
- `agent_radius = 0.3` (rounds up to 0.5 during bake = good wall margin)
- `agent_height = 1.8`
- `parsed_geometry_type = BOTH_MESHES_AND_STATIC_COLLIDERS`

### BTNode Base Class API

```gdscript
# shared/behavior_tree/bt_node.gd
class_name BTNode
extends Node

enum Status { SUCCESS, FAILURE, RUNNING }

var status: Status = Status.FAILURE  # Exposed for debugging in Remote inspector
var _debug_tick_count: int = 0       # Debug: total tick invocations
var _debug_last_tick_usec: int = 0   # Debug: last tick duration

# --- Public API (called by composites/runner) ---

## Wraps lifecycle: calls bt_enter on first activation, bt_exit on completion.
## Subclasses override _tick(), NOT execute().
func execute(delta: float, blackboard: Dictionary) -> Status:
    if status != Status.RUNNING:
        bt_enter(blackboard)
    var start: int = Time.get_ticks_usec() if OS.is_debug_build() else 0
    status = _tick(delta, blackboard)
    if OS.is_debug_build():
        _debug_tick_count += 1
        _debug_last_tick_usec = Time.get_ticks_usec() - start
    if status != Status.RUNNING:
        bt_exit(blackboard)
    return status

## Recursively aborts this node and all RUNNING descendants.
## MUST be called when a parent interrupts a RUNNING child.
func abort(blackboard: Dictionary) -> void:
    if status == Status.RUNNING:
        bt_exit(blackboard)
        status = Status.FAILURE
    for child: Node in get_children():
        if child is BTNode:
            var bt_child: BTNode = child as BTNode
            bt_child.abort(blackboard)

# --- Virtual methods (override in subclasses) ---

func _tick(_delta: float, _blackboard: Dictionary) -> Status:
    return Status.FAILURE

func bt_enter(_blackboard: Dictionary) -> void:
    pass

func bt_exit(_blackboard: Dictionary) -> void:
    pass

func bt_get_state() -> Dictionary:
    return {}

func bt_load_state(_data: Dictionary) -> void:
    pass
```

### Research Insight: BT Framework Design Rules

From LimboAI, BehaviorTree.CPP, Unreal BT, and Game AI Pro:

1. **`execute()` wraps `_tick()`** — handles the enter/exit lifecycle automatically. Subclasses override `_tick()`, never `execute()`.
2. **`abort()` must propagate recursively** — the #1 BT implementation bug is forgetting to call `bt_exit()` on interrupted RUNNING descendants. This causes phantom navigation, stuck animations, and leaked timers.
3. **Never add extra statuses** (ERROR, CANCELLED, TIMEOUT) — "makes the rest of the tree much more complex without making it more powerful" (Game AI Pro). Map everything to SUCCESS/FAILURE/RUNNING. A timeout is FAILURE. An error is FAILURE + `push_warning()`.
4. **Never `await` inside `_tick()`** — return RUNNING and poll on subsequent ticks instead.
5. **Do NOT store per-execution state on shared node instances** — `PackedScene.instantiate()` creates unique nodes, but if Resources are shared, state corrupts. BT nodes store mutable state as instance variables, never on exported Resources.

### BehaviorTreeRunner

```gdscript
# shared/behavior_tree/bt_runner.gd
class_name BehaviorTreeRunner
extends Node

@export var behavior_tree_scene: PackedScene
@export var tick_interval: float = 0.15  # Default 150ms; 0.0 = every physics frame

var blackboard: Dictionary = {}

var _bt_root: BTNode = null
var _tick_timer: float = 0.0
var _is_active: bool = true
```

**Tick loop:** In `_physics_process`, guard with `is_queued_for_deletion()` and `_is_active`. Accumulate delta. When `_tick_timer >= tick_interval`, tick the root node via `_bt_root.execute(delta, blackboard)`. Stagger initial timer with `randf_range(0.0, tick_interval)`.

**Default tick_interval is 0.15** (not 0.0) — prevents accidental per-frame ticking when designers forget to set it. Override to 0.0 for NPCs that truly need per-frame responsiveness.

**Blackboard setup in _ready():**
```gdscript
blackboard[&"npc"] = owner
blackboard[&"nav_agent"] = owner.get_node("%NavigationAgent3D")
blackboard[&"base_speed"] = owner.base_speed
blackboard[&"home_position"] = owner.global_position
blackboard[&"player"] = null  # Set by awareness area signal
```

**Blackboard key constants** — define in a shared file (e.g., `shared/behavior_tree/bt_keys.gd`) to catch typos at parse time:
```gdscript
class_name BTKeys
const NPC: StringName = &"npc"
const NAV_AGENT: StringName = &"nav_agent"
const BASE_SPEED: StringName = &"base_speed"
const HOME_POSITION: StringName = &"home_position"
const PLAYER: StringName = &"player"
```

**Tree hot-swap** (quest changes NPC behavior):
```gdscript
func swap_tree(new_scene: PackedScene) -> void:
    if _bt_root:
        _bt_root.abort(blackboard)  # Propagates bt_exit to all RUNNING nodes
        _bt_root.queue_free()
    _bt_root = new_scene.instantiate() as BTNode
    add_child(_bt_root)
    # Blackboard persists across swap — new tree reads existing state
```

### NPCWorldManager Autoload

```gdscript
# scripts/autoloads/npc_world_manager.gd
# NOTE: No class_name — matches existing autoload convention.
# Access via the autoload singleton name: NPCWorldManager
extends Node

# Registry: npc_id -> NPCRecord
var _registry: Dictionary = {}  # Dictionary[String, Dictionary]

func _ready() -> void:
    SaveManager.register(self)  # Works because autoload globals are set at _enter_tree time

# --- Saveable contract ---
func get_save_key() -> String: return "npc_world_manager"
func get_save_data() -> Dictionary: return _registry.duplicate(true)
func load_save_data(data: Dictionary) -> void:
    _registry.clear()  # "Clear then rebuild"
    # Rebuild entry-by-entry with explicit casts (JSON returns untyped Dictionaries)
    for npc_id: String in data:
        _registry[npc_id] = {}
        # ... rebuild each field with type casts

# --- Scene transition hooks ---
func snapshot_room(room_path: String) -> void: ...
func populate_room(room_path: String) -> void: ...
## Push registry state to live NPC instances (called after load_save_data during restore)
func restore() -> void: ...

# --- NPC lifecycle ---
func register_npc(npc_id: String, npc: Node3D) -> void:
    # Connect tree_exiting for automatic cleanup (prevents orphaned registry entries)
    npc.tree_exiting.connect(unregister_npc.bind(npc_id), CONNECT_ONE_SHOT)
    # Must NOT emit signals synchronously (called from NPC _ready)
func unregister_npc(npc_id: String) -> void: ...

# --- Off-screen estimation (no per-frame simulation) ---
## Called only at populate_room time, not every frame.
## Uses stored timestamp + elapsed calculation, not _process() accumulation.
func estimate_npc_position(npc_id: String) -> Vector3: ...
```

### Research Insight: Timestamp vs Per-Frame Accumulation

Instead of tracking `elapsed_time += delta` in `_process()` for every off-screen NPC, store the **timestamp when the NPC was unloaded** and compute elapsed on demand in `populate_room()`:
```gdscript
var elapsed: float = Time.get_ticks_msec() / 1000.0 - record.unloaded_at_sec
```
This avoids per-frame iteration over the registry entirely — zero per-frame cost for off-screen simulation.

**Autoload order:** Insert after WorldState, before SceneManager:
1. EventBus
2. GameState
3. DialogueManager
4. WorldState
5. **NPCWorldManager** ← NEW
6. SceneManager
7. SaveManager
8. HUD

**Why before SceneManager:** NPCWorldManager must be a registered saveable, so `SaveManager.register(self)` must succeed in `_ready()`. The `change_scene()` calls to NPCWorldManager happen at runtime, not init-time — the real ordering constraint is SaveManager access.

### AnimationController

```gdscript
# scripts/npc/animation_controller.gd
class_name AnimationController
extends Node

@export var sprite_tint: Color = Color.WHITE
@export var side_faces_right: bool = false

var _sprite: AnimatedSprite3D
var _facing_locked: bool = false
var _locked_facing: String = ""
var _lock_timer: float = 0.0

## Called by npc_controller in _physics_process after move_and_slide().
## Parent calls down — AnimationController does NOT poll owner.velocity.
func update_animation(current_velocity: Vector3) -> void: ...
func lock_facing(direction: String, duration: float = 0.0) -> void: ...
func unlock_facing() -> void: ...
```

**"Call down, not poll up"** — `npc_controller.gd` explicitly calls `_animation_controller.update_animation(velocity)` in `_physics_process()` after `move_and_slide()`. AnimationController does NOT read `owner.velocity` in its own `_process()`. This avoids the `_process()` vs `_physics_process()` frame mismatch (velocity set in physics, animation reads in process = one frame behind) and follows the "call down, signal up" principle.

Picks cardinal direction (down/up/side) based on largest XZ velocity component. Applies `flip_h` for left/right. When `_facing_locked`, ignores velocity and holds the locked direction. After `duration` expires, unlocks automatically.

**Distance-based deactivation:** When NPCWorldManager deactivates a distant NPC, it calls `set_physics_process(false)` on the NPC root. Since AnimationController is called from `_physics_process`, it automatically stops updating — no separate disable needed.

### Player Interaction Flow for Moving NPCs

1. Player presses interact → `player.interact_with_nearest()` → `npc.call("interact", self)`
2. `npc_controller.gd.interact(player)`:
   - Calls `_bt_runner.interrupt()` — calls `abort()` on the active RUNNING branch, sets `_is_active = false`
   - Sets `velocity = Vector3.ZERO`
   - Calls `_animation_controller.lock_facing(direction_to_player)`
   - Sets `GameState.set_mode(GameState.GameMode.DIALOGUE)`
   - Shows dialogue balloon with extra_game_states: `[quest_tracker, inventory, self]` (matching existing npc_interactable pattern)
   - Awaits `dialogue_ended`
   - Guards `if not is_instance_valid(self): return`
   - Calls `_animation_controller.unlock_facing()` (immediate release — 0.4s hold felt laggy)
   - Sets `GameState.set_mode(GameState.GameMode.OVERWORLD)`
   - Guards `if not is_instance_valid(self): return` ← **CRITICAL: GameState signal can trigger quest handlers that queue_free the NPC**
   - Calls `_bt_runner.resume()` — BT re-evaluates from root next tick

**BehaviorTreeRunner.interrupt():** Walks the active branch calling `bt_exit()` on all RUNNING nodes, then sets `_is_active = false`.

**BehaviorTreeRunner.resume():** Sets `_is_active = true`. Next tick, the tree evaluates from root with no RUNNING history — fresh start. The reactive Selector pattern means the NPC naturally picks up the highest-priority applicable behavior.

### Off-Screen Simulation

NPCWorldManager uses **timestamp-based estimation** (not per-frame accumulation). When an NPC is unloaded, the registry stores `unloaded_at_sec: float`. When `populate_room()` runs, elapsed time is computed on demand. **Zero per-frame cost** for off-screen NPCs.

When a room loads and `populate_room()` is called, each off-screen NPC targeted at that room gets its position estimated:

| Behavior | Estimation Method |
|----------|-------------------|
| Patrol/Waypoint | Interpolate along waypoint path: `elapsed * speed` modulo total path length |
| Path Follow | Interpolate along Path3D curve length |
| Wander | Random position within stored zone AABB, snapped to nav mesh via `NavigationServer3D.map_get_closest_point()` |
| Follow | Place at room entry point (cannot simulate without player position) |
| Static/Idle | Same position as when room unloaded |
| In Transit | If progress >= 0.5, spawn at destination entry; else spawn at source exit |

**Nav mesh snap:** After estimation, every spawned NPC position is snapped to the nav mesh via `NavigationServer3D.map_get_closest_point()`. If the nearest nav mesh point is >3.0 units away (use `distance_squared_to()` with threshold 9.0), fall back to home_position.

**CRITICAL: Nav map sync guard.** `populate_room()` runs immediately after `scene_changed`. The NavigationServer may not have synced the new room's nav mesh yet (`map_get_iteration_id() == 0`). **Two options:**
1. Defer nav-mesh-dependent operations to the next physics frame (`_deferred_nav_snap.call_deferred()`)
2. Set NPC position without nav snap; let the first BT tick (which already guards `map_get_iteration_id`) correct it

Option 2 is simpler — accept approximate initial position, let navigation self-correct.

**First-frame guard in BT movement actions:**
```gdscript
func _tick(delta: float, blackboard: Dictionary) -> Status:
    var nav: NavigationAgent3D = blackboard[BTKeys.NAV_AGENT] as NavigationAgent3D
    if NavigationServer3D.map_get_iteration_id(nav.get_navigation_map()) == 0:
        return Status.RUNNING  # Nav map not synced yet — wait
    # ... normal pathfinding logic
```

**Schedule-based NPCs:** Deferred until a game-time system exists. The BT framework supports `IsTimeInRange` as a condition node, so schedule behavior will work once the time system feeds data.

### Persistence Integration

**Session persistence (WorldState bridge):**
- Moving NPCs register with `NPCWorldManager` (not WorldState directly)
- NPCWorldManager implements the saveable contract and registers with SaveManager
- NPCWorldManager's `get_save_data()` returns the entire `_registry` dictionary
- On `load_save_data()`: clear registry, rebuild from save data, mark all as unloaded

**Disk persistence (SaveManager):**
- NPCWorldManager is in the `"saveable"` group
- **Special restore ordering** (same pattern as WorldState): pre-loaded before `change_scene()`, then `restore()` called after scene ready. Skipped in remaining-saveables loop.
- Save data structure per NPC:
```gdscript
{
    "npc_id": {
        "home_room": "res://scenes/world/test_room.tscn",
        "current_room": "res://scenes/world/test_room_2.tscn",
        "position": {"x": 4.0, "y": 1.0, "z": 2.5},  # Manual dict — JSON.stringify() does not support Vector3
        "behavior_tree_path": "res://scenes/npc/behaviors/guard_bt.tscn",
        "bt_state": { "Selector/Sequence_patrol/PatrolRoute": {"waypoint_index": 2} },
        "is_loaded": false,
        "is_in_transit": false,  # NOTE: is_ prefix per naming convention
        "unloaded_at_sec": 1234567.8,  # Timestamp-based, not accumulated
        "base_speed": 2.0,
        "speed_multiplier": 1.0
    }
}
```

**load_save_data contract:** "Clear then rebuild" — wipe `_registry`, then rebuild entry-by-entry from save data.

## Implementation Phases

### Pre-work: Extract Prompt Label Factory

Before Phase 2, extract the duplicated `_create_prompt_label()` method from `npc_interactable.gd` and `chest_interactable.gd` into a shared utility (e.g., `shared/prompt_label_factory.gd`). Both existing interactables and the new `npc_controller.gd` will use this. Prevents tripling the existing duplication.

**Status: Complete** — extracted `shared/prompt_label_factory.gd`, used by `chest_interactable.gd`, `npc_interactable.gd`, and `npc_controller.gd`.

### Phase 1: BT Framework Foundation

**Goal:** Standalone, testable behavior tree framework with no NPC dependencies.

**Files:**
- `shared/behavior_tree/bt_node.gd` — base class with execute/tick/enter/exit/abort/get_state/load_state
- `shared/behavior_tree/bt_composite.gd` — base composite with child tracking + running child index
- `shared/behavior_tree/bt_decorator.gd` — base decorator (single child)
- `shared/behavior_tree/bt_leaf.gd` — base leaf (no children)
- `shared/behavior_tree/bt_keys.gd` — StringName constants for blackboard keys
- `shared/behavior_tree/bt_runner.gd` — BehaviorTreeRunner with blackboard, tick loop, interrupt/resume/swap
- `shared/behavior_tree/composites/bt_selector.gd` — reactive selector
- `shared/behavior_tree/composites/bt_sequence.gd` — resumptive sequence
- `shared/behavior_tree/decorators/bt_repeater.gd`
- `shared/behavior_tree/decorators/bt_inverter.gd`

**Deferred to when needed:** BTParallel, BTCooldown, BTTimeLimit — no described behavior uses them. Add when a concrete behavior demands them.

**Acceptance criteria:**
- [x] BTNode base class with `execute()` wrapper (manages enter/exit lifecycle), `_tick()` virtual, `abort()` recursive, `bt_get_state()`/`bt_load_state()` (leaf-only)
- [x] BTSelector is reactive (re-evaluates from child 0, calls `abort()` on interrupted RUNNING children)
- [x] BTSequence is resumptive (resumes from RUNNING child)
- [x] BTSelector `abort()` propagates `bt_exit()` to ALL RUNNING descendants, not just the direct child
- [x] Decorators: Repeater (count + forever), Inverter
- [x] BehaviorTreeRunner: configurable tick_interval (default 0.15), staggered initial timer, blackboard with BTKeys constants
- [x] BehaviorTreeRunner: `interrupt()` (abort active branch + deactivate), `resume()` (reactivate, fresh root eval), `swap_tree()` (abort old + instantiate new)
- [x] BehaviorTreeRunner: `is_queued_for_deletion()` guard at top of `_physics_process()`
- [x] BehaviorTreeRunner: leaf-only state serialization via `get_bt_state()`/`load_bt_state()`
- [x] Empty Selector returns FAILURE, empty Sequence returns SUCCESS
- [x] Stuck detection: `push_warning()` if any node RUNNING >30s (debug builds only)
- [x] No `await` anywhere in the BT framework
- [x] All scripts pass `gdformat --check` and `gdlint`
- [x] GUT unit tests for: Selector reactivity + abort propagation, Sequence resumption, decorator behaviors, interrupt/resume/swap, leaf state serialization round-trip

### Phase 2: Moving NPC + Navigation

**Goal:** A CharacterBody3D NPC that can move via NavigationAgent3D, with basic BT leaf actions.

**Files:**
- `scripts/npc/npc_controller.gd` — CharacterBody3D root script
- `scripts/npc/animation_controller.gd` — velocity→animation+facing, facing lock
- `scenes/npc/moving_npc.tscn` — NPC scene composition
- `shared/behavior_tree/conditions/bt_is_player_near.gd`
- `shared/behavior_tree/conditions/bt_is_at_position.gd`
- `shared/behavior_tree/conditions/bt_random_chance.gd`
- `shared/behavior_tree/actions/bt_idle.gd`
- `shared/behavior_tree/actions/bt_patrol_route.gd`
- `shared/behavior_tree/actions/bt_wander_radius.gd`
- `shared/behavior_tree/actions/bt_follow_target.gd`
- `shared/behavior_tree/actions/bt_face_target.gd`
- `shared/behavior_tree/actions/bt_wait.gd`
- `shared/behavior_tree/actions/bt_talk_to_player.gd`
- `shared/prompt_label_factory.gd` — extracted shared prompt label creation
- `scenes/npc/behaviors/wander_example_bt.tscn` — example wander BT scene
- Room scenes updated: add `NavigationRegion3D`, bake nav mesh from GridMap

**Acceptance criteria:**
- [x] `npc_controller.gd` extends CharacterBody3D with exports: npc_id, base_speed, behavior_tree_scene, dialogue_resource, dialogue_title, quest_resource (QuestData), sprite_frames, default_facing, display_name, sprite_tint (Color), side_faces_right (bool)
- [x] NPC moves smoothly via NavigationAgent3D.get_next_path_position() + move_and_slide()
- [x] AnimationController picks correct cardinal animation from velocity, supports facing lock
- [x] Post-dialogue facing: unlock immediately on dialogue end (0.4s hold removed — felt laggy)
- [x] BT actions use NavigationAgent3D: PatrolRoute follows waypoints, WanderRadius picks random nav-mesh-snapped points, FollowTarget tracks a node
- [x] BTIdle plays idle animation via AnimationController, waits configurable duration
- [x] BTTalkToPlayer: returns RUNNING, NPC controller handles dialogue await and calls `_bt_runner.resume()`. **No await inside the BT node.**
- [x] Player can interact with moving NPCs (stop-talk-resume pattern works)
- [x] Two-zone awareness: AwarenessArea (5u) sets blackboard `"player"`, InteractionArea (2u) shows prompt
- [x] Path update throttling: `set_target_position()` recalculated every 300ms (staggered). `get_next_path_position()` called every physics frame for steering.
- [x] `NavigationRegion3D` baked in test_room.tscn
- [ ] `NavigationRegion3D` baked in test_room_2.tscn
- [x] **Pre-bake verification:** NavigationRegion3D must be a parent of GridMap (not sibling), `parsed_geometry_type` = Mesh Instances. Discovered: default `source_geometry_mode` only parses children, not siblings.
- [x] **Post-bake verification:** Debug > Visible Navigation shows nav mesh covering floor, avoiding walls
- [x] All BT movement actions guard `map_get_iteration_id() != 0` before first path query
- [x] NPC collision: layer 3 (npcs), mask includes layers 1 (environment) + 2 (player) + 3 (npcs)
- [x] RVO avoidance enabled, uses `velocity_computed` signal pattern
- [ ] ~~Set `avoidance_layers` to group NPCs~~ — deferred, only matters with 20+ NPCs
- [x] NPC implements interaction protocol: interact(), get_prompt_text(), show_prompt(), hide_prompt()
- [x] Extra_game_states passed to dialogue balloon: `[quest_tracker, inventory, self]` (matching npc_interactable pattern)
- [x] Per-behavior speed multipliers work (@export on BT action nodes)
- [x] All distance checks use `distance_squared_to()` with squared thresholds (hot-path optimization)
- [x] AnimationController called via `update_animation(velocity)` from npc_controller._physics_process(), NOT polling
- [ ] GUT tests for: patrol completes loop, wander stays in radius, follow tracks target, interaction interrupts and resumes

### Implementation Lessons Discovered (Phase 2)

**Bugs found and fixed during implementation:**

1. **BT delta timing** — `BehaviorTreeRunner` was passing physics frame delta (~0.016s) to BT nodes, but ticking at 0.15s intervals. Actions accumulating time (BTWait, BTIdle) perceived time ~10x slower. Fix: pass actual elapsed time since last tick (`bt_delta = _tick_timer`).
2. **Nav arrival false positive** — `NavigationAgent3D.is_navigation_finished()` returns `true` before a newly set target is processed. PatrolRoute skipped all waypoints instantly. Fix: skip `is_nav_finished()` check for 1 tick after setting a new target (`_ticks_since_target > 1`).
3. **Isometric facing** — `_cardinal_from_direction()` used raw world-space XZ to pick cardinal directions, but the isometric camera means screen-right is a mix of +X and -Z in world space. Fix: project world direction onto screen space via `Camera3D.unproject_position()`.
4. **%UniqueNodeName lookup failure** — `%BehaviorTreeRunner` returned null in instanced sub-scenes despite `unique_name_in_owner = true` being set. Root cause unclear. Fix: use direct path `get_node("BehaviorTreeRunner")` instead.
5. **NavigationRegion3D baking empty** — NavigationRegion3D as sibling to GridMap produces empty bake. The default `source_geometry_mode = ROOT_NODE_CHILDREN` only parses children, not siblings. Fix: make GridMap a child of NavigationRegion3D, or use group-based parsing.
6. **Post-dialogue facing lock stale** — `lock_facing(dir, 0.4)` after dialogue caused NPC to appear frozen facing the wrong direction when it resumed movement. The lock timer was long enough to feel laggy. Fix: `unlock_facing()` immediately on dialogue end; velocity-based facing takes over on next tick.
7. **Facing direction preserved on lock expiry** — When timed lock expired, `_facing` still held the pre-dialogue direction. NPC would snap to stale facing if idle. Fix: set `_facing = _locked_facing` when lock timer expires.
8. **NPCs walk through obstacles** — NavigationObstacle3D needed on obstacles (chests, etc.) that aren't part of the baked NavigationRegion3D geometry. Use `vertices` polygon (not `radius`) for rectangular obstacles.
9. **Wander gets stuck near obstacles** — `map_get_closest_point()` snaps random targets to the edge of NavigationObstacle3D carved holes, producing targets too close to NPC. Fix: retry up to 5 times, rejecting targets within 0.5 units of current position.
10. **NPCs walk through player** — NPC collision_mask didn't include player layer (2). Fix: add layer 2 to MovingNPC collision_mask (now `collision_mask = 7`, layers 1+2+3).

### Phase 3: NPCWorldManager + Persistence

**Goal:** NPCs persist across scene transitions and saves. Cross-room tracking.

**Files:**
- `scripts/autoloads/npc_world_manager.gd` — new autoload
- `scripts/autoloads/scene_manager.gd` — modified to call NPCWorldManager hooks
- `project.godot` — add NPCWorldManager autoload, adjust order

**Acceptance criteria:**
- [ ] NPCWorldManager autoload registered after WorldState, before SceneManager
- [ ] NPCWorldManager autoload is `.gd` with `res://` path, **no `class_name`** (per autoload convention)
- [ ] NPCWorldManager calls `SaveManager.register(self)` in `_ready()` (with comment explaining autoload singleton timing)
- [ ] NPCs register with NPCWorldManager in `_ready()` via npc_id. `register_npc()` connects `tree_exiting` signal for automatic cleanup.
- [ ] `register_npc()` does NOT emit signals synchronously (called during NPC `_ready()`)
- [ ] SceneManager calls `NPCWorldManager.snapshot_room()` before scene change. **Snapshot also disables BT `_physics_process` on all room NPCs** to prevent state drift before scene free.
- [ ] SceneManager calls `NPCWorldManager.populate_room()` after `scene_changed`. Dynamic NPCs added to room's "NPCs" container node.
- [ ] `populate_room()` sets NPC position BEFORE `add_child()` (prevents `home_position` capturing Vector3.ZERO in `_ready()`)
- [ ] NPC position + BT state survive room transitions (leave room, return, NPC at correct position)
- [ ] **SaveManager restore ordering:** NPCWorldManager gets same special treatment as WorldState in `_restore_save_data()` — pre-load registry before `change_scene()`, `restore()` after, skip in remaining-saveables loop
- [ ] `behavior_tree_path` validated with `ResourceLoader.exists()` before `load()` — fall back to default or `push_error()` on missing path
- [ ] NPCWorldManager implements saveable contract (get_save_key, get_save_data, load_save_data)
- [ ] load_save_data uses "clear then rebuild" pattern
- [ ] Save/load round-trip: save game with NPC mid-patrol, load, NPC resumes from saved position + waypoint
- [ ] Duplicate prevention: scene-native NPCs self-register, NPCWorldManager only spawns migrants
- [ ] Off-screen estimation: patrol interpolation, wander random snap (nav-mesh-snapped), follow at entry point
- [ ] Nav mesh snap tolerance: positions >3u from nav mesh fall back to home_position
- [ ] GUT integration tests for: save/load round-trip, scene transition persistence, off-screen estimation accuracy

### Phase 4: Cross-Room Movement + Polish

**Goal:** NPCs can transit between rooms. Remaining BT actions. Polish.

**Files:**
- `shared/behavior_tree/actions/bt_wander_in_zone.gd`
- `shared/behavior_tree/conditions/bt_is_quest_state.gd`
- Example BT scenes in `scenes/npc/behaviors/`

**Acceptance criteria:**
- [ ] Cross-room transit: NPC behavior triggers "go to room B", NPCWorldManager marks as in-transit
- [ ] Transit serialization: in-transit NPCs save from_room, to_room, progress
- [ ] Transit load: progress >= 0.5 spawns at destination, < 0.5 spawns at source
- [ ] WanderInZone: uses Area3D reference, picks random point within zone, walks to it
- [ ] IsQuestState: checks quest tracker for quest_id + state match
- [ ] Context-dependent blocked path handling: @export enum on npc_controller (WAIT_REROUTE, PUSH_THROUGH, PHASE_THROUGH)
- [ ] Blocked detection: if velocity near zero and nav not finished for >2s, trigger reroute
- [ ] Bark system: optional bark_lines PackedStringArray, triggered on awareness area entry, 30-60s cooldown, auto-dismissing Label3D
- [ ] Bark cooldown NOT persisted (resets on room change — acceptable)
- [ ] **Centralized distance-based activation in NPCWorldManager** — NPCWorldManager checks distances in its own `_physics_process()` with round-robin staggering (check N NPCs per frame). Deactivated NPCs get `set_physics_process(false)` + `nav_agent.avoidance_enabled = false` for true zero per-frame cost. Activation threshold: <15u (squared: 225.0). Deactivation: >20u (squared: 400.0). 5u hysteresis prevents oscillation.
- [ ] On reactivation, BT restarts from root via `resume()` (not stale RUNNING state)
- [ ] Example BT scenes demonstrate patrol, wander, and awareness patterns
- [ ] **Export filter** ensures dynamically-loaded BT scene files are included in builds (add `scenes/npc/behaviors/*.tscn` to export filter or verify via preload reference)
- [ ] All scripts pass gdformat/gdlint

**Deferred to when needed:** BTFollowPath (no Path3D curves exist), BTPlayAnimation (AnimationController handles it), IsTimeInRange (no time system), BTCooldown, BTTimeLimit, BTParallel.

## Alternative Approaches Considered

| Approach | Why Rejected |
|----------|-------------|
| Resource-based BT (LimboAI pattern) | Requires custom editor or manual .tres editing; `.duplicate()` trap for mutable state; less Godot-native (see brainstorm) |
| StateMachine hybrid (SM for actions + BT conditions) | Less composable; conditions and actions in different systems; hard to express priority chains (see brainstorm) |
| Grid-based A* instead of NavigationAgent3D | More rigid movement, no built-in avoidance, reinventing the wheel for smooth paths (see brainstorm) |
| Use Beehave addon | Zero-dependency preference; project uses GDScript-only with strict typing; custom implementation gives full control |
| Reparent NPC nodes to autoload across scenes | Breaks signal connections, @onready refs, and `owner` property; documented failure mode in Godot (see brainstorm research) |
| All NPCs become CharacterBody3D | Unnecessary refactor of working static NPCs for no functional benefit (AD6) |

## System-Wide Impact

### Signal Chain

```
Player presses interact
  → player.interact_with_nearest()
    → npc.call("interact", player)
      → BehaviorTreeRunner.interrupt()
        → abort() on active RUNNING branch (recursive bt_exit)
      → GameState.set_mode(DIALOGUE)
        → GameState.game_state_changed signal
          → Player StateMachine transitions to Interact state
      → DialogueManager.show_dialogue_balloon()
      → await DialogueManager.dialogue_ended
      → GameState.set_mode(OVERWORLD)
        → GameState.game_state_changed signal
          → Player StateMachine transitions to Idle
      → BehaviorTreeRunner.resume()
        → Next tick: BT evaluates from root
```

```
SceneManager.change_scene()
  → scene_change_started signal
  → WorldState.snapshot()
  → NPCWorldManager.snapshot_room()
    → iterates registered NPCs, captures state
  → change_scene_to_file()
  → scene_changed signal
    → New scene _ready() → NPCs call NPCWorldManager.register_npc()
  → NPCWorldManager.populate_room()
    → spawns cross-room NPCs
  → WorldState.restore()
    → pushes interactable state to scene nodes
  → scene_change_completed signal
```

### Error Propagation

- BT `tick()` errors: catch in BehaviorTreeRunner, log via `push_error()`, treat as FAILURE for that node
- Null blackboard references: `is_instance_valid()` guard in every leaf that reads node refs
- Missing nav mesh: NavigationAgent3D returns current position for `get_next_path_position()`; NPC stays still. BT PatrolRoute returns RUNNING indefinitely → stuck detection warns after 30s
- NPC freed during dialogue: `is_instance_valid(self)` check after `await dialogue_ended` (existing pattern)

### State Lifecycle Risks

- **Orphaned registry entries:** If an NPC is freed without `NPCWorldManager.unregister_npc()`, the registry leaks a stale entry. Mitigate with `tree_exiting` signal connection in register_npc().
- **Corrupt BT state in save:** If BT structure changes between game versions (designer modifies tree), saved node paths won't match. `bt_load_state()` should silently skip unknown paths.
- **Partial save during transit:** Handled by AD5 — transit progress is a single float, always loadable.

### Scene Interface Parity

| System | Equivalent Feature | Needs Same Change? |
|--------|-------------------|-------------------|
| ChestInteractable | WorldState persistence | No — chests use WorldState; NPCs use NPCWorldManager |
| DoorInteractable | Scene transition trigger | No — doors trigger SceneManager; NPC transit is internal |
| PlayerController | move_and_slide, save/load | Pattern reference only — no changes needed |
| SceneManager | Transition flow | Yes — add NPCWorldManager hook calls (Phase 3) |

### Integration Test Scenarios

1. **Save mid-patrol, load, verify position:** Place NPC on patrol route. Walk to waypoint 3 of 5. Save. Load. Verify NPC is at saved position and resumes toward waypoint 4.
2. **Cross-room persistence:** Talk to NPC in room 1. Leave to room 2. Return to room 1. Verify NPC is at the position they were when you left (not reset to home).
3. **Interaction during movement:** NPC is patrolling. Player talks to them mid-patrol. Verify NPC stops, faces player, dialogue plays, NPC resumes patrol after.
4. **Off-screen estimation:** Leave room with patrolling NPC. Wait 10 seconds. Return. Verify NPC is ~10*speed units further along their patrol route (approximate).
5. **Save with NPC in different room than home:** Quest triggers NPC to move to room 2 (home is room 1). Save in room 2. Load. Verify NPC spawns in room 2, not room 1.

## Dependencies & Prerequisites

- **NavigationRegion3D must be baked** in test rooms before Phase 2 NPC testing
- **Phase 1 must complete** before Phase 2 (BT framework is the foundation)
- **Phase 2 must complete** before Phase 3 (NPCs must exist before persistence)
- **No time system dependency** — IsTimeInRange is a placeholder until a game clock exists

## Risk Analysis & Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| GridMap nav mesh baking issues | Blocks all NPC movement | Medium | Test baking early in Phase 2; fall back to manual NavigationRegion3D if GridMap baking fails |
| BT framework too complex | Delays all phases | Medium | Phase 1 is isolated; can simplify (drop Parallel, Cooldown) if needed |
| Scene transition timing bugs | Data loss, duplicate NPCs | High | Follow existing WorldState pattern exactly; test transitions obsessively in Phase 3 |
| Off-screen estimation feels wrong | NPCs teleport noticeably | Low | Estimation is approximate by design; nav-mesh snap + home fallback handles edge cases |
| Static NPC / moving NPC divergence | Maintenance burden | Low | Shared interaction protocol via duck typing; both types coexist peacefully |

## Success Metrics

- NPCs visibly move along patrol routes and wander within zones
- Player can talk to a moving NPC (stop-talk-resume works)
- NPCs persist position across room transitions (no reset on room re-entry)
- Save/load preserves NPC position and behavior state
- No duplicate NPCs after scene transitions
- No crashes or stale references during BT execution
- All GUT tests pass

## Sources & References

### Origin

- **Brainstorm document:** [docs/brainstorms/2026-03-22-npc-ai-navigation-brainstorm.md](docs/brainstorms/2026-03-22-npc-ai-navigation-brainstorm.md) — Key decisions carried forward: node-based BT architecture, NavigationAgent3D + NavigationRegion3D, blackboard Dictionary, two-zone awareness, approximate off-screen simulation, destroy-and-recreate pattern

### Internal References

- State machine framework: [shared/state_machine/state_machine.gd](shared/state_machine/state_machine.gd), [shared/state_machine/state.gd](shared/state_machine/state.gd)
- Save/load contract: [scripts/autoloads/save_manager.gd](scripts/autoloads/save_manager.gd), [scripts/autoloads/world_state.gd](scripts/autoloads/world_state.gd)
- Scene transitions: [scripts/autoloads/scene_manager.gd](scripts/autoloads/scene_manager.gd)
- Existing NPC: [scripts/interactables/npc_interactable.gd](scripts/interactables/npc_interactable.gd)
- Player interaction: [scripts/player/player_controller.gd](scripts/player/player_controller.gd)
- Scene transition retrospective: [docs/brainstorms/2026-03-20-scene-transition-patterns-retrospective.md](docs/brainstorms/2026-03-20-scene-transition-patterns-retrospective.md)

### External References

- [Godot NavigationAgent3D docs](https://docs.godotengine.org/en/stable/classes/class_navigationagent3d.html)
- [LimboAI blackboard patterns](https://github.com/limbonaut/limboai) — informed blackboard design
- [Beehave node-based BT](https://github.com/bitbrain/beehave) — informed node-based approach
- [Radiant AI tiered processing](https://blog.paavo.me/radiant-ai/) — informed off-screen simulation
- [Stardew Valley schedule system](https://stardewvalleywiki.com/Modding:Schedule_data) — informed schedule-snap pattern
