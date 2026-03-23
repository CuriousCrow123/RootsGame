# NPC AI Navigation System — Brainstorm

**Date:** 2026-03-22
**Status:** Draft

## What We're Building

A foundational NPC AI navigation system that supports multiple movement behaviors — hardcoded paths, planned waypoints, constrained/unconstrained random wander, and schedule-based routines. The system serves three goals: making the world feel alive (atmosphere), enabling gameplay mechanics (escort, patrol, flee), and supporting time-based NPC schedules.

### Behavior Types

| Behavior | Description | Example |
|---|---|---|
| **Static** | NPC stands in place, plays idle animation. Current behavior. | Shopkeeper behind counter |
| **Path Follow** | NPC follows a fixed Path3D curve, looping or ping-ponging. Smooth curves, not point-to-point. | Merchant walking a winding trade route |
| **Waypoint Patrol** | NPC walks point-to-point between Marker3D positions via NavigationAgent3D pathfinding. | Guard patrolling between gate and tower |
| **Constrained Wander** | NPC picks random points within an Area3D zone or nav layer. | Villagers milling around market square |
| **Unconstrained Wander** | NPC picks random points within a radius of home position. | Animal grazing in a field |
| **Free Roam** | NPC navigates anywhere on the nav mesh with no spatial constraint. Used by other behaviors (Follow, flee) when bounds don't apply. | Fleeing enemy, escorting player |
| **Schedule-based** | Behavior changes based on game time or conditions. | NPC patrols by day, wanders near tavern at night |
| **Follow** | NPC follows a target (player, another NPC) at a set distance. | Escort quest companion |

## Why This Approach

### Node-based Behavior Tree Architecture

Each NPC's AI is defined as a **behavior tree composed of Godot Nodes**, saved as a PackedScene. This was chosen over Resource-based BTs or a StateMachine hybrid because:

1. **Visual editing** — BT structure is visible and editable in Godot's scene tree. Designers can reorder priorities, add conditions, and tweak exports without touching code.
2. **Godot-native composition** — Follows the project's "composition over inheritance" principle. BT nodes are small, single-purpose, and composable.
3. **Runtime swappable** — Quest events can swap an NPC's entire behavior tree by changing the PackedScene reference, or modify individual branches.
4. **Debuggable** — Node inspector shows current state. Each BT node can expose its status (running, success, failure) as a property.

### Navigation Stack

- **NavigationAgent3D** on each moving NPC for pathfinding + RVO avoidance
- **NavigationRegion3D** per room, baked from GridMap geometry in the editor (not runtime)
- **Navigation layers** for walkability constraints (e.g., guard-only paths, civilian areas)
- **Area3D zones** for spatial wander boundaries (visual in editor, shareable between NPCs)
- Moving NPCs use **CharacterBody3D** (not StaticBody3D). Static NPCs remain StaticBody3D.

### Player Interaction

- Player initiates dialogue → NPC halts, faces player, enters Interact leaf node
- NPC has **two-zone awareness** (from research on shipped RPGs):
  - **Outer zone** (~5 units): NPC becomes "aware" — eligible for greeting bark, subtle facing shift
  - **Inner zone** (~2 units): NPC is "engaged" — full face-toward-player, interaction prompt appears
- **Cardinal snap facing** (not smooth rotation) — matches 4-direction pixel sprites. Same logic as player's `update_facing()`.
- **Post-dialogue facing hold** — NPC holds player-facing direction for 0.3-0.5s before reverting to default. Prevents robotic snap-back.
- After dialogue ends, NPC resumes previous behavior (BT re-evaluates from root)
- **Optional bark system** — `bark_lines: PackedStringArray` export, triggered on outer zone entry with 30-60s cooldown per NPC, displayed as auto-dismissing Label3D

### Persistence

- **Full persistence** — NPC position, current BT state, and behavior configuration save/load across scene transitions and game saves
- NPCs register with SaveManager (disk) and WorldState (session) per existing saveable contract
- Save data includes: position, active behavior tree path, BT node states, current waypoint index, etc.

## Key Decisions

1. **Node-based Behavior Tree** over Resource-based BT or StateMachine hybrid — visual editing, Godot-native, runtime-swappable
2. **NavigationAgent3D + NavigationRegion3D** over grid-based A* — smooth paths, built-in avoidance, background thread processing (Godot 4.5+)
3. **Nav mesh baked in editor** (not runtime) — rooms are static GridMap layouts, no need for runtime baking overhead
4. **Area3D zones + navigation layers** for wander constraints — two complementary tools serving different purposes (spatial bounds vs walkability rules)
5. **CharacterBody3D for moving NPCs** — required for `move_and_slide()`, NavigationAgent3D pairing
6. **Full state persistence** — NPC exact position, BT state, and behavior config persist across scene transitions and saves. On load, NPC resumes from exact saved position toward next waypoint.
7. **Behavior trees as PackedScene exports** — data-driven, editor-configured, quest-swappable at runtime
8. **Player awareness on NPCs** — face nearby player, greeting animations, stop-talk-resume pattern
9. **Context-dependent blocked path handling** — configurable per-NPC: guards push through, villagers wait then reroute, etc. Exposed as a BT decorator or NPC export.
10. **Per-behavior speed multipliers** — NPC has `@export var base_speed: float`, each BT action node can apply a multiplier (0.5x stroll, 1.0x walk, 1.5x hurry, 2.0x flee)
11. **Cross-room NPC movement** — NPCs can move between scenes. When a room is unloaded, NPCs in it are tracked by an NPC World Manager autoload.
12. **Approximate off-screen simulation** — unloaded NPCs don't run physics. Their position is estimated based on time elapsed and behavior (e.g., "60% through patrol route by now"). When a room loads, NPCs are placed at their estimated positions.
13. **AnimationController node** — dedicated child node watches NPC velocity/state and picks the correct animation + facing direction. BT actions handle movement only.
14. **Configurable BT tick rate** — `@export var tick_interval: float` on BehaviorTreeRunner. Key NPCs tick every physics frame, background NPCs throttled.
15. **Blackboard Dictionary for BT context** — BehaviorTreeRunner populates a Dictionary with NPC references (nav_agent, base_speed, etc.). BT nodes receive it on `tick()`. Decouples BT nodes from NPC scene structure.

## NPC Node Composition

```
MovingNPC (CharacterBody3D)
├── CollisionShape3D (CapsuleShape3D)
├── AnimatedSprite3D (billboard)
├── AnimationController (Node, watches velocity → picks animation + facing)
├── NavigationAgent3D (avoidance_enabled=true)
├── AwarenessArea (Area3D, outer ~5 units, triggers barks + facing)
├── InteractionArea (Area3D, inner ~2 units, shows prompt)
├── BehaviorTreeRunner (Node, ticks the BT, @export tick_interval)
│   └── [BT scene instantiated as child]
└── Label3D (interaction prompt, built in _ready)
```

## BT Data Flow: Blackboard Pattern

The `BehaviorTreeRunner` creates a **blackboard** `Dictionary` populated with references to the NPC and its child nodes. Every BT node receives the blackboard on `tick()`. This decouples BT nodes from the NPC scene structure — they read/write keys, not hardcoded node paths.

**Standard blackboard keys:**
- `"npc"` → `CharacterBody3D` (the NPC root)
- `"nav_agent"` → `NavigationAgent3D`
- `"base_speed"` → `float`
- `"home_position"` → `Vector3` (spawn position)
- `"player"` → `PlayerController` (set by PlayerDetectionArea when nearby, null otherwise)

BT nodes can also write to the blackboard for sibling communication (e.g., a condition sets `"wander_target"` that an action reads).

**Blackboard safety rules (from research):**
- Use `StringName` constants for keys (not raw strings) — typos become compile errors
- Always guard node references with `is_instance_valid()` — a `queue_free()`'d node leaves a stale reference in the blackboard
- Namespace keys by subsystem: `&"nav_target"`, `&"perception_player"` — prevents pollution as trees grow
- Erase keys when they become irrelevant (e.g., `blackboard.erase(&"follow_target")` when follow ends)

## Behavior Tree Node Types

### Base Classes
- **BTNode** — base for all BT nodes. Extends `Node`. Returns SUCCESS/FAILURE/RUNNING.
  - `tick(delta: float, blackboard: Dictionary) -> int` — called each BT tick while active
  - `bt_enter(blackboard: Dictionary) -> void` — called once when node transitions from inactive to active
  - `bt_exit(blackboard: Dictionary) -> void` — called when node completes OR is interrupted by a parent abort. Essential for cleanup (stopping animations, releasing locks).
  - **Never `await` inside `tick()`** — use the poll pattern with RUNNING instead. `await` suspends the entire BT traversal.
- **BTComposite** — has children (Selector, Sequence, Parallel). Tracks `_running_child_index` to resume RUNNING children next tick.
- **BTDecorator** — wraps one child (Repeater, Inverter, Succeeder)
- **BTLeaf** — no children (conditions and actions)

### Composites
- **Selector** — tries children left-to-right, returns first SUCCESS
- **Sequence** — runs children left-to-right, fails on first FAILURE
- **Parallel** — runs all children, configurable success/fail policy

### Decorators
- **Repeater** — repeats child N times or forever
- **Inverter** — flips SUCCESS/FAILURE
- **Cooldown** — prevents child from running for N seconds after last run
- **TimeLimit** — fails child if it runs longer than N seconds

### Conditions (Leaf)
- **IsPlayerNear** — `@export var radius: float`
- **IsTimeInRange** — `@export var start_hour: int`, `@export var end_hour: int`
- **IsQuestState** — `@export var quest_id: String`, `@export var required_state: String`
- **IsAtPosition** — checks if NPC is near a target position
- **RandomChance** — `@export var probability: float` (0-1)

### Actions (Leaf)
- **Idle** — play idle animation, wait for duration
- **PatrolRoute** — follow waypoints via NavigationAgent3D
- **WanderInZone** — pick random point in Area3D zone, walk to it
- **WanderRadius** — pick random point within radius of home, walk to it
- **FollowPath** — follow a Path3D curve
- **FollowTarget** — navigate toward a target node (player, marker)
- **FaceTarget** — rotate to face a position/node
- **PlayAnimation** — play a specific animation on AnimatedSprite3D
- **TalkToPlayer** — enter dialogue, await completion
- **Wait** — do nothing for a duration

## Performance Considerations

- **Path update throttling** — recalculate paths every 300ms, not every frame
- **Staggered timers** — randomize initial offset so NPCs don't all recalculate on the same frame
- **Distance-based activation** — disable BT ticking and navigation for NPCs far from the player
- **Avoidance layers** — partition NPC groups to reduce O(n^2) avoidance checks
- **Async navigation** — enable Project Settings > Navigation > 3D > Use Async Iterations (4.5+)

## Debugging (from research)

- **BT status property** — each BTNode exposes its last status (SUCCESS/FAILURE/RUNNING) as a property visible in the Remote inspector
- **Blackboard change logging** — in debug builds, log key changes to catch stale references and unexpected writes
- **Stuck detection** — warn if any task has been RUNNING for >30 seconds (configurable threshold)
- **Performance target** — <1ms per NPC per frame. Most common culprits: raycasts every tick, pathfinding every tick, `get_node()` in leaf nodes

## Cross-Room & Off-Screen Simulation

### NPC World Manager (Autoload)

A new autoload (`NPCWorldManager`) tracks all NPCs globally, even when their room is unloaded:

- **Registry:** Every NPC registers on `_ready()` with its `npc_id`, current room, position, and active behavior reference
- **Room unload:** When a room unloads, its NPCs are removed from the scene tree but their state is preserved in the manager (position, behavior, waypoint progress, elapsed time)
- **Room load:** When a room loads, the manager checks which NPCs should be in that room, estimates their current position, and spawns them at the estimated location
- **Approximate simulation:** For unloaded NPCs, the manager uses time-based interpolation. No physics, no nav mesh queries. Behavior-specific estimation:
  - **Patrol/Path Follow:** Interpolate along the known waypoint/curve path based on elapsed time and speed. Straightforward.
  - **Wander:** Snap to a random valid position within their zone/radius. Exact path doesn't matter since it's random anyway.
  - **Follow:** Cannot simulate off-screen (depends on player position). NPC "catches up" to the player when the room loads.
  - **Static/Idle:** No simulation needed — NPC stays where they were.
- **Cross-room transitions:** When an NPC's behavior says "go to room B," the manager despawns them from room A's scene and records them as "in transit to room B." When room B loads, they spawn at the entry point.
- **Destroy and recreate, never reparent** (from research — Skyrim, Stardew, and Godot best practices all agree). NPC nodes are freed with their scene. The registry is the source of truth. Fresh NPC nodes are instantiated when a room loads. Reparenting to autoloads breaks signal connections, `@onready` refs, and `owner`.
- **Room connectivity graph** (stretch goal): A simple Dictionary mapping room→connected rooms with estimated travel times. Enables NPCs in transit to appear in intermediate rooms if the player visits them.

### Save/Load Integration

- NPCWorldManager implements the saveable contract (`get_save_key`, `get_save_data`, `load_save_data`)
- Save data: `{ npc_id: { room: String, position: Vector3, behavior_tree_path: String, bt_state: Dictionary, ... } }`
- On load: "clear then rebuild" — wipe all tracked NPCs, rebuild from save data only

## Open Questions

None — all resolved.

## Resolved Questions

1. **Time system dependency** — Deferred. Build BT infrastructure now with a placeholder `IsTimeInRange` condition node. Add actual time system later. The BT architecture doesn't depend on it.
2. **Animation integration** — Dedicated **AnimationController** child node that watches NPC velocity/state and automatically picks the correct animation + facing direction. BT actions focus on movement, controller handles visuals.
3. **BT tick rate** — **Configurable per-NPC** via `@export var tick_interval: float` on BehaviorTreeRunner. Important/nearby NPCs tick every physics frame, background NPCs throttled to 100-200ms.
4. **NPC-NPC interaction** — **Not now, design for it later.** Keep interactions player-only. Don't block future NPC-NPC interaction but don't build infrastructure for it yet.
5. **Behavior tree editor tooling** — **Standard Godot scene tree is sufficient.** BT nodes are regular Nodes with @export vars, edited in the scene tree and Inspector panels. No custom graph editor needed.
6. **Save precision** — **Exact position + resume path.** Save precise Vector3 position + current waypoint index. On load, NPC resumes from saved position toward next waypoint.
7. **Blocked path handling** — **Context-dependent, configurable per-NPC.** Guards push through, villagers wait then reroute. Exposed as a BT decorator or NPC export enum.
8. **Movement speed** — **Per-behavior speed multiplier.** NPC has a base speed, each BT action applies a multiplier (stroll=0.5x, walk=1.0x, hurry=1.5x, flee=2.0x).
9. **Cross-room movement** — **NPCs can move between rooms** with off-screen simulation. NPCWorldManager autoload tracks all NPCs globally.
10. **Off-screen fidelity** — **Approximate.** Time-based interpolation along known routes. No physics or nav mesh queries for unloaded NPCs.
