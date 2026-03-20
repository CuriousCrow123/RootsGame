# RootsGame — Project Architecture

**Current as of:** 2026-03-20

> **Audience:** Human developers returning from a break and AI agents starting new sessions. This document describes *how things work*. For prescriptive rules, see [CLAUDE.md](../CLAUDE.md). For scoped implementation patterns, see [.claude/rules/](../.claude/rules/).

---

## 1. Project Overview

A Cassette Beasts-inspired RPG built with Godot 4.6.1 and GDScript. 3D orthographic rendering with a fixed isometric camera. Core combat mechanic is TBD — the current foundation focuses on quest-driven gameplay, proving all systems work together.

**Current milestone:** Phase 4 complete (all 8 build steps from the foundation plan). The project has a playable fetch quest loop across 2 rooms with full save/load, scene transitions, dialogue, inventory, and quest tracking.

**Tech stack:** Godot 4.6.1, GDScript (static typing enforced as errors), GL Compatibility renderer, Nathan Hoad's Dialogue Manager, GUT test framework.

---

## 2. Directory Structure

```
RootsGame/
├── scripts/
│   ├── autoloads/          # 6 custom autoload scripts (.gd only, no .tscn)
│   ├── camera/             # camera_follow.gd (room-level camera)
│   ├── interactables/      # chest, door, npc interactable scripts
│   ├── inventory/          # Inventory node (child of Player)
│   ├── player/
│   │   ├── player_controller.gd
│   │   └── player_states/  # Idle, Walk, Interact state scripts
│   ├── quest/              # QuestTracker node (child of Player)
│   └── ui/                 # interaction_prompt, item_toast, quest_indicator, pause_menu
├── scenes/
│   ├── interactables/      # chest.tscn, door.tscn, npc.tscn
│   ├── main/               # main.tscn (placeholder launcher scene, not the run target)
│   ├── player/             # player.tscn (CharacterBody3D composition)
│   ├── ui/                 # dialogue_balloon, interaction_prompt, item_toast, pause_menu, quest_indicator
│   └── world/              # test_room.tscn (run target), test_room_2.tscn
├── resources/
│   ├── dialogue/           # .dialogue files (Dialogue Manager format)
│   ├── items/              # ItemData resource class + .tres instances
│   ├── quests/             # QuestData, QuestStepData classes + .tres instances
│   └── mesh_library.tres   # GridMap tile definitions
├── shared/
│   └── state_machine/      # Reusable StateMachine + State base classes
├── tests/
│   ├── unit/               # 6 test files (GameState, Inventory, PlayerController, QuestTracker, SaveDataContracts, Example)
│   └── integration/        # 3 test files (QuestLoop, SaveLoadCycle, SceneTransition)
├── addons/
│   ├── dialogue_manager/   # Nathan Hoad's Dialogue Manager plugin
│   └── gut/                # GUT test framework
└── docs/                   # Plans, brainstorms, research, handoffs, reference
```

---

## 3. Autoload Architecture

Seven autoloads registered in `project.godot` as `.gd` files with explicit `res://` paths. Load order matters — later autoloads reference earlier ones.

| # | Autoload | Script | Responsibility |
|---|----------|--------|---------------|
| 1 | **EventBus** | `scripts/autoloads/event_bus.gd` | Cross-system signal bus. Intentionally empty — no signal currently needs it (see §12). |
| 2 | **GameState** | `scripts/autoloads/game_state.gd` | Tracks `GameMode` enum. Emits `game_state_changed`. |
| 3 | **DialogueManager** | `addons/dialogue_manager/dialogue_manager.gd` | Third-party dialogue plugin. Stateless/headless. |
| 4 | **WorldState** | `scripts/autoloads/world_state.gd` | Session-scoped interactable state. Bridge between per-scene nodes and persistent cross-scene state. |
| 5 | **SceneManager** | `scripts/autoloads/scene_manager.gd` | Scene transitions with fade overlay. Owns persistent player lifecycle. |
| 6 | **SaveManager** | `scripts/autoloads/save_manager.gd` | JSON serialization to disk. Registrar pattern validates saveable contracts. |
| 7 | **HUD** | `scripts/autoloads/hud.gd` | Persistent UI container. Instantiates UI scenes, owns pause menu lifecycle. |

**Interdependencies (who references whom):**
- WorldState → SaveManager (registers itself as saveable)
- SceneManager → WorldState (calls snapshot/restore during transitions)
- SaveManager → SceneManager (reloads scene on load), WorldState (restores after scene change)
- HUD → SceneManager (listens to `player_registered`), GameState (sets mode on pause)
- Player states → GameState (check `current_mode`, listen to `game_state_changed`)

### Why `.gd`-Only Autoloads

A `.tscn` autoload causes Godot's parser to infer the singleton type as `Node`, breaking `unsafe_method_access`/`unsafe_property_access` checks. A `uid://` path is fragile if `.uid` sidecars desync. See CLAUDE.md > Autoload registration.

**See also:** `.claude/rules/autoload-patterns.md` for ordering nuances and timing constraints.

---

## 4. Entity System

**Key files:** `scripts/player/player_controller.gd`, `scripts/interactables/*.gd`, `scenes/player/player.tscn`, `scenes/interactables/*.tscn`

### Player Composition

```
Player (CharacterBody3D) [player_controller.gd]
├── CollisionShape3D (CapsuleShape3D)
├── MeshInstance3D (placeholder capsule)
├── InteractionArea (Area3D, mask=layers 3+4)
│   └── CollisionShape3D (SphereShape3D, r=2.0)
├── StateMachine [state_machine.gd]
│   ├── Idle [player_idle.gd]
│   ├── Walk [player_walk.gd]
│   └── Interact [player_interact.gd]
├── Inventory [inventory.gd]
└── QuestTracker [quest_tracker.gd]
```

**Public API** (used by interactables and UI via §11's `connect_to_player()` pattern):
- `get_inventory() -> Inventory`
- `get_quest_tracker() -> QuestTracker`
- `get_nearest_interactable() -> Node3D`
- `interact_with_nearest() -> void`
- Signal: `nearest_interactable_changed(interactable: Node3D)`

**Persistent player:** SceneManager reparents the player to `root` on registration so it survives scene changes. If a scene-instanced Player already exists when entering a room, the duplicate is `queue_free()`'d.

### Interactable Pattern

All interactables are `StaticBody3D` nodes with a duck-typed `interact(player: PlayerController)` method. The player's `InteractionArea` detects overlapping bodies on physics layers 3 (NPCs) and 4 (interactables), then calls `.call("interact", self)` on the nearest by distance.

**Current limitation:** Detection is pure radius (SphereShape3D). The player can interact with objects behind them.

| Type | Script | Stateful? | Group | Key Behavior |
|------|--------|-----------|-------|-------------|
| NPC | `npc_interactable.gd` | No | — | Triggers dialogue via DialogueManager (see §6) |
| Chest | `chest_interactable.gd` | Yes | `interactable_saveable` | Gives item, marks opened via WorldState |
| Door | `door_interactable.gd` | No | — | Calls `SceneManager.change_scene()` |

**See also:** `.claude/rules/interactable-patterns.md`

### `[PROJECTED]` Extensions

- **Direction-based interaction** — filter candidates by player facing direction (dot product check), not just radius
- **Specific interaction prompts** — interactables provide custom prompt text ("Talk", "Open", "Enter") instead of generic "Press E"

---

## 5. State Machine

**Key files:** `shared/state_machine/state_machine.gd`, `shared/state_machine/state.gd`, `scripts/player/player_states/*.gd`

### How It Works

Generic, reusable framework. `StateMachine` is a `Node` that manages `State` children. States emit `state_finished(next_state_path, data)` to request transitions. The machine calls `exit()` on the current state and `enter(previous_state_path, data)` on the next.

`StateMachine` delegates `_process`, `_physics_process`, and `_unhandled_input` to the current state.

### Player States

| State | Transitions To | Trigger |
|-------|---------------|---------|
| **Idle** | Walk | Movement input detected (`physics_update`) |
| **Idle** | Interact | `game_state_changed` → DIALOGUE |
| **Walk** | Idle | No movement input or non-OVERWORLD mode |
| **Walk** | Interact | `game_state_changed` → DIALOGUE |
| **Interact** | Idle | `game_state_changed` → OVERWORLD |

All states check `GameState.current_mode` and connect/disconnect `game_state_changed` on enter/exit. The Interact state disables the state machine's processing (`set_active(false)`) to freeze the player during dialogue.

### `[PROJECTED]` Extensions

- **Animation states** — current states will trigger animation player when character models/sprites are added

---

## 6. Dialogue System

**Key files:** `addons/dialogue_manager/`, `resources/dialogue/npc_greeting.dialogue`, `scripts/interactables/npc_interactable.gd`, `scenes/ui/dialogue_balloon.tscn`

### How It Works

Uses Nathan Hoad's Dialogue Manager addon — a stateless, headless dialogue engine. The game owns all state; DM only parses `.dialogue` files and evaluates expressions.

**`.dialogue` file syntax:** Plain text with `if`/`elif`/`else` branching, `do` for side effects, `- Choice text` for player choices. Human-readable, version-control friendly.

### The `extra_game_states` Bridge

This is the key integration pattern. When an NPC starts dialogue:

```gdscript
DialogueManager.call(
    "show_dialogue_balloon",
    dialogue_resource, dialogue_title, [quest_tracker, inventory, self]
)
```

DM iterates `extra_game_states` to resolve method calls and property lookups in `.dialogue` files. This allows dialogue to:
- Call `start_quest(quest_resource)` — finds `quest_resource` property on the NPC, `start_quest()` on QuestTracker
- Call `advance_quest("fetch_amulet")` — finds method on QuestTracker
- Call `has_item("quest_amulet")` — finds method on Inventory
- Call `remove_item("quest_amulet")` — finds method on Inventory
- Check `is_quest_active("fetch_amulet")` / `is_quest_complete("fetch_amulet")` — finds methods on QuestTracker

**Dialogue balloon:** `scenes/ui/dialogue_balloon.tscn` is the addon's example balloon scene. It renders dialogue text, handles response selection, and emits `dialogue_ended`. Not instantiated by HUD — managed by DM's own machinery.

**Safety:** `is_instance_valid(self)` guard after `await dialogue_ended` because the NPC may be freed during dialogue (scene transition or load game).

---

## 7. Quest System

**Key files:** `resources/quests/quest_data.gd`, `resources/quests/quest_step_data.gd`, `scripts/quest/quest_tracker.gd`, `resources/quests/fetch_quest.tres`

### How It Works

**Resources (data layer):**
- `QuestData` — `quest_id`, `display_name`, `description`, `steps: Array[QuestStepData]`
- `QuestStepData` — `step_id`, `description`, `next_step_id` (empty string = terminal)

Steps form a linked list. No branching quest paths in the current model.

**QuestTracker (behavior layer):** Pure state store — does not evaluate conditions. Lifecycle:

`INACTIVE` → `start_quest(data)` → `ACTIVE` → `advance_quest(id)` → ... → `COMPLETE`

Signals: `quest_started`, `quest_step_completed`, `quest_completed`, `quests_reset`

**All quest logic lives in dialogue files** (see §6 `extra_game_states` bridge). The `.dialogue` file checks conditions (`is_quest_active()`, `has_item()`) and calls mutations (`start_quest()`, `advance_quest()`).

**Save/load:** Saves `resource_path` per quest so `load()` can reconstruct the QuestData on restore. Uses clear-then-rebuild pattern (see CLAUDE.md > Saveable contracts).

### `[PROJECTED]` Extensions

- **Branching quests** — `QuestStepData` could gain conditional `next_step_id` fields
- **Quest journal UI** — tab in the inventory menu (see §8, §11) displaying all quests and their states

---

## 8. Inventory System

**Key files:** `resources/items/item_data.gd`, `scripts/inventory/inventory.gd`, `resources/items/key_item.tres`

### How It Works

**ItemData** (Resource): Read-only definition — `item_id`, `display_name`, `description`, `icon`. Never mutated at runtime.

**Inventory** (Node, child of Player): Stores items as `Array[Dictionary]` with `{"item_id": String, "quantity": int}`. Flat structure — no Resource references at runtime, which simplifies serialization.

**Key methods** (consumed by dialogue via §6 bridge):
- `add_item(item_id, quantity, display_name)` — stacks duplicates, emits `item_added`
- `remove_item(item_id, quantity) -> bool` — emits `item_removed`
- `has_item(item_id, quantity) -> bool` — threshold check
- `get_display_name(item_id) -> String` — lookup from internal cache

Save contract: `get_save_key() → "inventory"`, saves `{"items": [...]}`.

### `[PROJECTED]` Extensions

- **Item categories** — equipment, consumables, key items
- **Item registry** — global `item_id → ItemData` lookup for UI icons/descriptions
- **Inventory menu** — tabbed UI panel (inventory + quest journal) as part of the in-game menu (see §11)

---

## 9. World & Scene Management

**Key files:** `scripts/autoloads/scene_manager.gd`, `scenes/world/test_room.tscn`, `scenes/world/test_room_2.tscn`, `scripts/interactables/door_interactable.gd`, `scripts/camera/camera_follow.gd`

### Room Structure

Each room is a `Node3D` scene containing:
- `GridMap` — world geometry using shared `mesh_library.tres`
- `DirectionalLight3D` + `WorldEnvironment`
- `Camera3D` with `camera_follow.gd`
- `Marker3D` spawn points (named `DefaultSpawn`, `spawn_from_room_2`, etc.)
- Entity instances (Player, NPCs, Chests, Doors)

Two rooms exist: `test_room.tscn` (run target, has Player/NPC/Chest/Door) and `test_room_2.tscn` (linked by doors).

### Scene Transition Flow

```
Door.interact() → SceneManager.change_scene(path, spawn_id)
  1. Fade out (0.3s tween)
  2. WorldState.snapshot()          — collect interactable state from old scene
  3. change_scene_to_file(path)     — deferred scene swap
  4. await get_tree().scene_changed — fires after new scene's _ready()
  5. WorldState.restore()           — push stored state to new scene's interactables
  6. Position player at spawn point
  7. Fade in (0.3s tween)
```

**Persistent player:** Reparented to `root` by SceneManager on registration. Rooms that have a Player instance in the `.tscn` get duplicate detection — the scene-instanced copy is freed.

### Camera

`camera_follow.gd` (extends `Camera3D`): Per-room camera, not a player child. Finds the player via `"player"` group in `_process()`. Lerp-follows the player's position along the camera's backward axis. Fixed orthographic projection (size=10).

**Current limitation:** Movement input is rotated by a hardcoded `ISO_ANGLE` (-45°) in `player_controller.gd`. This assumes a fixed camera angle. If the camera faces a different direction, controls won't correspond with the view.

### Why Room-Level Camera

Player-child camera would rigidly attach with no lerp smoothing. Room-level allows future bounds clamping without refactoring.

**See also:** `.claude/rules/autoload-patterns.md` for transition timing constraints.

### `[PROJECTED]` Extensions

- **Camera bounds clamping** — constrain camera to room boundaries
- **Camera-relative controls** — derive movement rotation from the active camera's basis instead of hardcoded `ISO_ANGLE`, so controls stay correct when camera angle varies per room
- **Threaded scene loading** — `ResourceLoader.load_threaded_request()` for larger maps
- **Navigation** — NavigationRegion3D + NavMesh or AStar3D (decision deferred)

---

## 10. World State & Persistence

**Key files:** `scripts/autoloads/world_state.gd`, `scripts/autoloads/save_manager.gd`

### Two-Tier Architecture

| Tier | Manager | Group | Scope | Members |
|------|---------|-------|-------|---------|
| **Disk** | SaveManager | `saveable` | Serialized to JSON file | Player, Inventory, QuestTracker, WorldState |
| **Session** | WorldState | `interactable_saveable` | In-memory across scene changes | Chests, destructibles |

WorldState is both a tier-2 manager (orchestrates session state for interactables) AND a tier-1 saveable (serialized by SaveManager). This dual role makes it the bridge between per-scene nodes and persistent cross-scene state.

### Registrar Pattern

Saveables call `SaveManager.register(self)` or `WorldState.register(self)` in `_ready()`. Registration asserts the three-method contract exists (`get_save_key()`, `get_save_data()`, `load_save_data()`), then adds the node to the appropriate group. See CLAUDE.md > Saveable contracts.

### Save Format

JSON at `user://saves/save_001.json`. Single slot, hardcoded path. Atomic write (tmp file + rename). Structure:

```json
{
  "version": 1,
  "scene_path": "res://scenes/world/test_room.tscn",
  "timestamp": 1742486400,
  "player": { "position": {...}, "rotation_y": 0.0 },
  "inventory": { "items": [...] },
  "quest_tracker": { "fetch_amulet": {...} },
  "world_state": { "chest_01": { "is_opened": true } }
}
```

### Load Sequence (cross-system timing)

```
SaveManager.load_game()
  1. Parse JSON, validate version
  2. SceneManager.change_scene(saved_scene_path)
     └── This triggers snapshot/restore cycle internally
  3. await scene_change_completed
  4. WorldState.load_save_data(saved_world_data)  ← AFTER scene change
  5. WorldState.restore()                         ← Push to new scene's interactables
  6. Restore Player, Inventory, QuestTracker (skip WorldState — already done)
```

**Critical timing:** WorldState must be restored AFTER `scene_change_completed` because `change_scene()` calls `snapshot()` which would clobber the loaded data. SaveManager always reloads the scene (even if already on the saved scene) to guarantee a clean slate.

**See also:** `.claude/rules/autoload-patterns.md`, `.claude/rules/interactable-patterns.md`

---

## 11. UI System

**Key files:** `scripts/autoloads/hud.gd`, `scripts/ui/*.gd`, `scenes/ui/*.tscn`

### How It Works

HUD autoload instantiates 4 UI scenes in `_ready()` via `preload().instantiate()`:

| UI Element | Scene | Purpose |
|-----------|-------|---------|
| InteractionPrompt | `interaction_prompt.tscn` | "Press E" label near interactables |
| ItemToast | `item_toast.tscn` | Fade notification on item pickup |
| QuestIndicator | `quest_indicator.tscn` | Active quest name + current step |
| PauseMenu | `pause_menu.tscn` | Resume/Save/Load/Quit (layer 110) |

### The `connect_to_player()` Pattern

All UI scripts expose `connect_to_player(player: PlayerController)`. HUD calls it via `.call()` (duck-typed dispatch on `CanvasLayer` children) when `SceneManager.player_registered` fires. UI scripts wire themselves to player signals internally — they never self-connect.

```
SceneManager.player_registered → HUD._on_player_registered()
  → interaction_prompt.call("connect_to_player", player)
  → item_toast.call("connect_to_player", player)
  → quest_indicator.call("connect_to_player", player)
```

### Pause Menu Lifecycle

1. HUD handles `"pause"` input in `_input()` (not `_unhandled_input` — Tab is consumed by UI focus)
2. Open: save previous GameMode → set MENU → `get_tree().paused = true` → `pause_menu.call("open_menu", can_save_load)`
3. Close: `get_tree().paused = false` → restore previous GameMode
4. Save/Load disabled when pausing from non-OVERWORLD modes (prevents corruption)

HUD has `process_mode = PROCESS_MODE_ALWAYS` so it responds to input while the tree is paused.

**Current limitation:** Single save slot (`save_001.json`). No slot selection UI — save/load buttons act immediately.

**See also:** `.claude/rules/ui-patterns.md`

### `[PROJECTED]` Extensions

- **In-game menu** (distinct from pause menu) — tabbed panel with inventory, quest journal, and other gameplay tabs. Does NOT pause the tree — the game world continues. Opened via a separate input action. The pause menu remains a separate system-level overlay for save/load/quit/settings.
- **Multiple save slots** — replace single `save_001.json` with numbered slots. Pause menu gets a save slot selector and load slot picker.
- **Settings menu** — audio, display, controls (in pause menu)

---

## 12. Signal Architecture

**Principle:** "Call down, signal up." Parents call methods on children. Children emit signals. Siblings communicate through a shared parent. EventBus is for genuinely cross-system events only — currently empty.

### Signal Map

| Signal | Emitter | Consumer(s) | Purpose |
|--------|---------|-------------|---------|
| `nearest_interactable_changed` | PlayerController | InteractionPrompt | Show/hide "Press E" |
| `item_added` | Inventory | ItemToast | Show pickup notification |
| `item_removed` | Inventory | (none currently) | — |
| `quest_started` | QuestTracker | QuestIndicator | Show quest panel |
| `quest_step_completed` | QuestTracker | QuestIndicator | Update step text |
| `quest_completed` | QuestTracker | QuestIndicator | Show "Complete!" + hide |
| `quests_reset` | QuestTracker | QuestIndicator | Hide panel on load |
| `game_state_changed` | GameState | PlayerIdle, PlayerWalk, PlayerInteract | Mode gating / state transitions |
| `scene_change_started` | SceneManager | (internal use) | — |
| `scene_change_completed` | SceneManager | SaveManager | Triggers save data restore |
| `player_registered` | SceneManager | HUD | Wires UI to player |
| `state_finished` | State (any) | StateMachine | Request state transition |
| `chest_opened` | ChestInteractable | (none currently) | Available for future use |
| `dialogue_ended` | DialogueManager | NpcInteractable | Resume OVERWORLD mode |

### Group-Based `.call()` Dispatch

`get_nodes_in_group()` returns `Array[Node]`. Even with `has_method()` guards, calling methods directly fails strict typing. All group dispatch uses `.call("method_name")` — saveable iteration in SaveManager/WorldState, and `connect_to_player()` in HUD.

---

## 13. Game Modes

**Key files:** `scripts/autoloads/game_state.gd`, `project.godot` (input map), `scripts/player/player_states/*.gd`

### GameState Enum

```
OVERWORLD — default, player can move and interact
BATTLE    — defined but unused (no combat system planned yet)
MENU      — pause menu open, tree paused
DIALOGUE  — NPC dialogue active, movement blocked
CUTSCENE  — defined but unused
```

`set_mode()` emits `game_state_changed` synchronously (not deferred) — player states rely on immediate timing.

### Mode Transitions

```
OVERWORLD → DIALOGUE  (NPC.interact sets mode before dialogue)
DIALOGUE  → OVERWORLD (NPC.interact restores after dialogue_ended)
OVERWORLD → MENU      (HUD opens pause menu)
MENU      → [previous] (HUD restores saved mode on close)
```

### Input Map

| Action | Key | Consuming Systems | Mode Gated? |
|--------|-----|-------------------|-------------|
| `move_forward` | W | PlayerIdle, PlayerWalk | OVERWORLD only |
| `move_back` | S | PlayerIdle, PlayerWalk | OVERWORLD only |
| `move_left` | A | PlayerIdle, PlayerWalk | OVERWORLD only |
| `move_right` | D | PlayerIdle, PlayerWalk | OVERWORLD only |
| `interact` | E | PlayerIdle | OVERWORLD only |
| `cancel` | Escape | (unused currently) | — |
| `pause` | Tab | HUD | All modes (toggles) |

---

## 14. Physics Layers

| Layer | Name | Used By (collision_layer) |
|-------|------|--------------------------|
| 1 | environment | GridMap, static world geometry |
| 2 | player | Player (CharacterBody3D) |
| 3 | npcs | NPC (StaticBody3D) |
| 4 | interactables | Chest, Door (StaticBody3D) |

**Mask configurations:**
- **Player** collision_mask = 1+3+4 (environment + NPCs + interactables)
- **InteractionArea** (Area3D) mask = 3+4 (NPCs + interactables only — no environment)

---

## 15. Resource Patterns

### Two-Layer Pattern

| Layer | Type | Role |
|-------|------|------|
| **Data** | Resource (.tres) | Definitions, serializable state |
| **Behavior** | Node | Scene-tree logic, UI, runtime state |

Resources are read-only at runtime. Never mutate a shared `.tres` — call `.duplicate()` first (see CLAUDE.md > Resource safety). Prefer `preload()` over dynamic `load()`.

### Custom Resource Types

| Class | File | Fields | Instances |
|-------|------|--------|-----------|
| `ItemData` | `resources/items/item_data.gd` | `item_id`, `display_name`, `description`, `icon` | `key_item.tres` ("Old Amulet") |
| `QuestData` | `resources/quests/quest_data.gd` | `quest_id`, `display_name`, `description`, `steps` | `fetch_quest.tres` ("The Old Amulet") |
| `QuestStepData` | `resources/quests/quest_step_data.gd` | `step_id`, `description`, `next_step_id` | (inline in fetch_quest.tres) |

---

## 16. Testing

**Framework:** GUT (Godot Unit Test), installed at `addons/gut/`.

### Unit Tests (6 files, ~55 test functions)

| File | Covers |
|------|--------|
| `test_game_state.gd` | Mode switching, signal emission, initial state |
| `test_inventory.gd` | Add/remove/stack items, signals, save/load roundtrip |
| `test_player_controller.gd` | Save data structure, position roundtrip, save key |
| `test_quest_tracker.gd` | Quest lifecycle, step advancement, signals, save/load roundtrip |
| `test_save_data_contracts.gd` | All saveable contracts (Inventory, QuestTracker, Chest, WorldState, Player) — keys, roundtrips, defensive copies |
| `test_example.gd` | GUT framework smoke test |

### Integration Tests (3 files, ~12 test functions)

| File | Covers |
|------|--------|
| `test_quest_loop.gd` | Full quest lifecycle (start → advance → complete), signal ordering, save/load mid-quest |
| `test_save_load_cycle.gd` | Full save/load cycle, empty state handling, WorldState in save cycle, JSON serializability |
| `test_scene_transition.gd` | SceneManager autoload presence, player saveable group, position save/restore, Inventory/QuestTracker persistence |

**Pattern:** Unit tests use `GutTest` base class with `before_each` setup. Test naming: `test_<behavior_being_tested>`.

---

## 17. Projected Systems Summary

Consolidated view of all `[PROJECTED]` markers. Each links back to the section where it appears inline.

### Navigation (§9)
- NavigationRegion3D + NavMesh or AStar3D on grid (decision deferred)
- Needed for NPC pathfinding and enemy movement

### Art Migration (§4, §9)
- Swap placeholder capsule meshes for 3D models or Sprite3D billboards
- Visual-layer swap only — gameplay code unchanged
- GridMap tile positions transfer; meshes/materials need rebuilding

### Audio (new)
- No audio system exists yet — consciously deferred
- Will need SFX for interactions, dialogue, ambient, and music management

### Extended Quests (§7)
- Branching quest steps with conditional `next_step_id`
- Quest journal UI for displaying all quest states

### Item System Growth (§8)
- Item categories (equipment, consumables, key items)
- Global item registry for UI icon/description lookup

### Interaction Improvements (§4)
- Direction-based interaction filtering (dot product on player facing)
- Context-specific prompts ("Talk", "Open", "Enter") instead of generic "Press E"

### In-Game Menu (§11)
- Tabbed panel (inventory, quest journal, etc.) — separate from pause menu
- Does not pause the tree; pause menu remains system-level for save/load/quit

### Multiple Save Slots (§10, §11)
- Replace single `save_001.json` with numbered slots
- Save slot selector and load picker in pause menu

### Camera Improvements (§9)
- Bounds clamping to room boundaries
- Camera-relative controls — derive movement rotation from camera basis instead of hardcoded angle
- Threaded scene loading for larger maps

---

## 18. Maintenance

### When to Update This Document

- Adding a new autoload
- Adding a new custom Resource type
- Adding a new system-level script (autoload, state machine, manager)
- Changing signal architecture (new cross-system signals)
- Implementing a `[PROJECTED]` system (move from projected to current)

### Related Documentation

| Document | Purpose |
|----------|---------|
| [CLAUDE.md](../CLAUDE.md) | Prescriptive rules for agents and developers |
| `.claude/rules/*.md` | Scoped patterns auto-injected when editing specific files |
| `docs/plans/` | Implementation plans with phases and acceptance criteria |
| `docs/brainstorms/` | Design exploration and decision rationale |
| `docs/research/` | External research on Godot patterns and tools |
| `docs/handoffs/` | Editor setup instructions between sessions |
