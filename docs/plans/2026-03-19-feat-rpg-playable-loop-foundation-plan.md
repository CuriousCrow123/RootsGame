---
title: "feat: RPG Playable Loop Foundation"
type: feat
status: completed
date: 2026-03-19
origin: docs/brainstorms/2026-03-19-rpg-skeleton-systems-brainstorm.md
---

# RPG Playable Loop Foundation

## Enhancement Summary

**Deepened on:** 2026-03-19
**Sections enhanced:** All 4 phases + architecture + system-wide impact
**Review agents used:** gc-godot-architecture-reviewer, gc-godot-timing-reviewer, gc-gdscript-reviewer, gc-resource-safety-reviewer, gc-godot-performance-reviewer, gc-pattern-recognition-specialist, gc-code-simplicity-reviewer, gc-best-practices-researcher, gc-framework-docs-researcher, godot-patterns skill analysis, save system security review

### Key Improvements
1. **Critical timing fixes:** `await get_tree().tree_changed` replaced with `await get_tree().process_frame` in SceneManager/SaveManager (fires too early; new scene isn't ready yet)
2. **Coroutine safety:** Added `is_instance_valid(self)` guards on all `await` resumption points (NPC freed during dialogue = orphaned coroutine)
3. **Simplifications adopted:** Removed condition_type/params system (dialogue handles all logic), simplified quest steps to single `next_step_id`, removed unused ItemData fields, removed door lock/key (not used in prototype)
4. **Encapsulation fixes:** Added `get_inventory()`/`get_quest_tracker()` accessors on PlayerController; eliminated all cross-tree `get_node()` paths
5. **Save system hardened:** Atomic write (temp+rename), `Error` return type, `json.data` type validation, version checking on load
6. **Saveable contract refined:** Added `get_save_key() -> String` method instead of embedding `_save_key` in data dictionaries
7. **Persistent player pattern:** Changed from Option A (save/restore) to persistent player node under SceneManager, avoiding state serialization on every room transition
8. **Camera decoupled from player:** Camera as room-level sibling with follow script, enabling bounds clamping in Step 5 without refactoring

### New Considerations Discovered
- Dialogue mutations (`advance_quest` + `remove_item`) must be on the same dialogue line for atomicity
- Quest indicator UI needs EventBus or `@export` injection to reach QuestTracker signals (child of Player)
- Autoload initialization order matters: EventBus → GameState → SceneManager → SaveManager
- `GameState.set_mode()` must emit synchronously (not deferred) for player state machine timing
- Item registry (string ID → ItemData lookup) will be needed for toast UI; plan for it in Step 3

## Overview

Build the playable foundation for a 3D orthographic RPG: one room, one NPC, one quest, proving all core patterns work together with production-quality data foundations. Each build step produces shippable code. The architecture uses a two-layer pattern (Resource for data, Node for behavior) with serialization contracts from day one.

This plan covers all 8 build steps from the brainstorm, organized into 4 phases:

- **Phase 1 (Steps 1-2):** Core movement + interaction patterns
- **Phase 2 (Steps 3-4):** Items + quest = playable loop
- **Phase 3 (Steps 5-6):** Multi-room + persistence
- **Phase 4 (Steps 7-8):** Cross-system events + game modes

## Problem Statement / Motivation

The project is at Step 0 — tooling, conventions, and architecture decisions are complete but no game systems exist. The risk of building systems in isolation (without gameplay) is well-documented (Derek Yu, Bob Nystrom). The brainstorm chose a "playable loop first" approach: design data foundations upfront so the wiring can emerge through gameplay without rework.

The first milestone is a **single-room fetch quest** (Steps 1-4) that proves the interactable pattern, dialogue integration, inventory, and quest tracking all work together. Steps 5-8 extend this into a multi-room game with persistence and mode switching.

## Proposed Solution

Follow the brainstorm's 8-step build order exactly. Each step adds one system and proves it integrates with everything before it. Autoloads are triggered by concrete gameplay needs (SceneManager at Step 5, SaveManager at Step 6), not built speculatively.

### Gap Resolutions

The SpecFlow analysis identified gaps in the brainstorm. These are resolved here and carried into the implementation phases:

| Gap | Resolution | Rationale |
|-----|-----------|-----------|
| Input actions undefined | Define `move_forward/back/left/right`, `interact`, `cancel`, `pause` with WASD + gamepad defaults | Needed before Step 1 |
| Inventory data structure | `Array[Dictionary]` with `{ "item_id": String, "quantity": int }` | Simple, serializable, quest-checkable |
| Dialogue ↔ quest bridge | Dialogue Manager's `extra_game_states` — pass quest tracker as game state | DM's native condition system; no custom bridge needed |
| QuestStepData conditions | Removed — dialogue file handles all quest logic via `if`/`do` natively | YAGNI: only one condition type was real (`has_item`), and dialogue already evaluates it |
| Save trigger | Debug keybinds (F5 save, F9 load) for prototype; proper menu deferred | Unblocks Step 6 without menu dependency |
| Interaction priority | Player-owned Area3D; closest interactable wins | Player owns detection = simpler, single responsibility |
| Dialogue UI | Global CanvasLayer scene | Persists across scene transitions, single instance |
| Quest states | INACTIVE → ACTIVE → COMPLETE (no failure) | Minimal for fetch quest; failure added when needed |
| Camera follow | Camera as room-level sibling with follow script (not player child) | Enables bounds clamping in Step 5 without refactoring; player child = rigid attach, no lerp |
| Interactable state tracking | Global dictionary keyed by string ID (in SaveManager later, local dict until then) | String IDs are the brainstorm's cross-reference pattern |
| Player persistence | Persistent player node under SceneManager (not save/restore per transition) | Avoids serialization dance on every room change; state naturally persists |
| Autoload stubs (EventBus, GameState) | Keep existing stubs; populate when triggered | Already registered; removing and re-adding is churn |
| Audio | Deferred — not in scope for foundation | Conscious omission, not oversight |
| Accessibility | Deferred to post-foundation; note text size and prompt visibility as future concerns | Foundation must work before it can be accessible |

## Technical Approach

### Architecture

**Two-Layer Pattern** (see brainstorm: [docs/brainstorms/2026-03-19-rpg-skeleton-systems-brainstorm.md](docs/brainstorms/2026-03-19-rpg-skeleton-systems-brainstorm.md))

| Layer | Type | Role | Examples |
|-------|------|------|----------|
| Data | Resource (.tres) | Definitions, serializable state | ItemData, QuestData, QuestStepData |
| Behavior | Node | Scene-tree logic, UI | PlayerController, QuestTracker, DialogueBalloon |

**Serialization Contract:** Every stateful system implements (added in Step 6 when SaveManager is built):
```gdscript
func get_save_key() -> String:
    return "unique_id"  # Stable identifier for save data lookup

func get_save_data() -> Dictionary:
    return {}

func load_save_data(data: Dictionary) -> void:
    pass
```

**Existing Infrastructure:**
- `StateMachine` + `State` classes at `shared/state_machine/` — use for player states (Idle, Walk, Interact)
- `GameState` autoload with `GameMode` enum — use DIALOGUE mode to block input during dialogue
- `EventBus` autoload — empty stub, populated when concrete cross-system signals emerge
- GUT testing framework at `addons/gut/`

**Autoload Initialization Order** (order matters — later autoloads may depend on earlier ones):
1. EventBus (no dependencies)
2. GameState (no dependencies)
3. SceneManager (may reference GameState for mode blocking)
4. SaveManager (references SceneManager for transition-safe saves)

`GameState.set_mode()` must emit `game_state_changed` **synchronously** (not deferred). Player state machine timing depends on this.

**Collision Layers** (configured in Step 1):

| Layer | Name | Purpose |
|-------|------|---------|
| 1 | environment | GridMap, static props |
| 2 | player | Player CharacterBody3D |
| 3 | npcs | NPC StaticBody3Ds |
| 4 | interactables | Interaction Area3Ds |

**Input Actions** (configured in Step 1):

| Action | Keyboard | Gamepad | Used From |
|--------|----------|---------|-----------|
| `move_forward` | W | Left Stick Up | Step 1 |
| `move_back` | S | Left Stick Down | Step 1 |
| `move_left` | A | Left Stick Left | Step 1 |
| `move_right` | D | Left Stick Right | Step 1 |
| `interact` | E | South (A/Cross) | Step 2 |
| `cancel` | Escape | East (B/Circle) | Step 2 |
| `pause` | Tab | Start | Step 6+ |
| `debug_save` | F5 | — | Step 6 |
| `debug_load` | F9 | — | Step 6 |

### Project File Structure (End State)

```
scenes/
  world/
    test_room.tscn              # Step 1: GridMap room
    test_room_2.tscn            # Step 5: second room
  player/
    player.tscn                 # Step 1: CharacterBody3D scene
  ui/
    dialogue_balloon.tscn       # Step 2: Dialogue Manager balloon
    interaction_prompt.tscn     # Step 2: "Press E" prompt
    item_toast.tscn             # Step 3: item pickup feedback
    quest_indicator.tscn        # Step 4: active quest HUD

scripts/
  autoloads/
    event_bus.gd                # Exists (empty stub)
    game_state.gd               # Exists (GameMode enum)
    world_state.gd              # Refactor: interactable session state
    scene_manager.gd            # Step 5: scene transitions
    save_manager.gd             # Step 6: serialization
    hud.gd                      # Refactor: persistent UI container
  player/
    player_controller.gd        # Step 1: movement + interaction
    player_states/
      player_idle.gd            # Step 1: idle state
      player_walk.gd            # Step 1: walk state
      player_interact.gd        # Step 2: locked during interaction
  interactables/
    npc_interactable.gd         # Step 2: dialogue trigger
    chest_interactable.gd       # Step 3: item container
    door_interactable.gd        # Step 5: scene transition trigger
  inventory/
    inventory.gd                # Step 3: item storage + query
  quest/
    quest_tracker.gd            # Step 4: quest state management
  ui/
    dialogue_balloon.gd         # Step 2: Dialogue Manager UI
    interaction_prompt.gd       # Step 2: prompt show/hide
    item_toast.gd               # Step 3: pickup notification
    quest_indicator.gd          # Step 4: quest HUD

resources/
  items/
    item_data.gd                # Step 3: class_name ItemData
    key_item.tres               # Step 3: test quest item
  quests/
    quest_data.gd               # Step 4: class_name QuestData
    quest_step_data.gd          # Step 4: class_name QuestStepData
    fetch_quest.tres            # Step 4: test fetch quest
  dialogue/
    npc_greeting.dialogue       # Step 2: test NPC dialogue

tests/
  unit/
    test_example.gd             # Exists
    test_inventory.gd           # Step 3
    test_quest_tracker.gd       # Step 4
    test_save_data_contracts.gd # Step 6
  integration/
    test_quest_loop.gd          # Step 4
    test_scene_transition.gd    # Step 5
    test_save_load_cycle.gd     # Step 6
```

### Implementation Phases

---

#### Phase 1: Core Movement + Interaction (Steps 1-2)

**Goal:** Player walks in a 3D room, approaches an NPC, and has a branching dialogue conversation.

##### Step 1: Player Walking in GridMap Room

**What it proves:** 3D scene structure, orthographic camera, analog movement, collision.

**Tasks:**

1. **Configure input actions in project.godot** — Add `move_forward`, `move_back`, `move_left`, `move_right` actions with WASD keyboard + left stick gamepad bindings. Add `interact` (E + gamepad south), `cancel` (Escape + gamepad east).
   - *Note: Input actions must be configured in the Godot editor (Project > Project Settings > Input Map), which writes to `project.godot`. Agents cannot reliably edit the `[input]` section directly. This step requires the editor.*

2. **Configure collision layer names in project.godot** — Set layer names: 1=environment, 2=player, 3=npcs, 4=interactables.
   - *Same editor constraint as input actions.*

3. **Create player scene** (`scenes/player/player.tscn`) — CharacterBody3D root with:
   - CollisionShape3D (CapsuleShape3D, radius ~0.3, height ~1.8)
   - MeshInstance3D (placeholder — CapsuleMesh or imported KayKit model)
   - Area3D for interaction detection (child, collision mask = layers 3+4, slightly larger sphere ~2.0m radius)
   - StateMachine node with Idle and Walk state children
   - Inventory node (child)
   - QuestTracker node (child, added in Step 4 but planned from scene creation)
   - **Camera is NOT a child** — it lives in the room scene as a sibling, with a follow script

4. **Write player_controller.gd** (`scripts/player/player_controller.gd`):

```gdscript
# scripts/player/player_controller.gd
class_name PlayerController
extends CharacterBody3D
## Player character with movement, interaction detection, and state management.

@export var move_speed: float = 5.0

var _nearest_interactable: Node3D = null

@onready var _state_machine: StateMachine = $StateMachine
@onready var _interaction_area: Area3D = $InteractionArea
@onready var _inventory: Inventory = $Inventory
@onready var _quest_tracker: QuestTracker = $QuestTracker

# Fixed camera angle — hardcoded for consistent isometric feel.
# Avoids reading camera basis each frame and floating-point drift.
const ISO_ANGLE: float = -0.7854  # deg_to_rad(-45.0)

func _ready() -> void:
    _interaction_area.body_entered.connect(_on_interactable_entered)
    _interaction_area.body_exited.connect(_on_interactable_exited)

# -- Public accessors (interactables call these, not get_node) --

func get_inventory() -> Inventory:
    return _inventory

func get_quest_tracker() -> QuestTracker:
    return _quest_tracker

func get_movement_input() -> Vector3:
    var input_dir: Vector2 = Input.get_vector(
        "move_left", "move_right", "move_forward", "move_back"
    )
    # Rotate input by fixed camera angle for camera-relative movement
    var rotated: Vector2 = input_dir.rotated(ISO_ANGLE)
    return Vector3(rotated.x, 0.0, rotated.y).normalized()

func get_save_key() -> String:
    return "player"

func get_save_data() -> Dictionary:
    return {
        "position": {"x": global_position.x, "y": global_position.y, "z": global_position.z},
        "rotation_y": rotation.y,
    }

func load_save_data(data: Dictionary) -> void:
    var pos: Dictionary = data.get("position", {})
    global_position = Vector3(pos.get("x", 0.0), pos.get("y", 0.0), pos.get("z", 0.0))
    rotation.y = data.get("rotation_y", 0.0)
```

> **Research Insight — Movement:** For a fixed orthographic camera (Cassette Beasts style), hardcode the rotation offset as a constant rather than reading `_camera.rotation.y` each frame. This avoids floating-point drift and is simpler to reason about. The `Input.get_vector()` parameter order is `(neg_x, pos_x, neg_y, pos_y)` — the returned Vector2 is already normalized to max length 1.0.

> **Research Insight — Camera:** Camera should be a **room-level sibling** of the player (not a child) to enable lerp follow and bounds clamping in Step 5 without refactoring. A simple follow script on the camera reads the player's position each frame. In Step 1 (single room), this behaves identically to a child camera but decouples the transform hierarchy.

5. **Write player states** — `player_idle.gd` (waits for movement input, transitions to Walk), `player_walk.gd` (applies velocity from `get_movement_input()`, calls `move_and_slide()`, transitions to Idle when input stops). Both extend the existing `State` class. Add `player_interact.gd` stub (blocks movement, used in Step 2).

6. **Create test room scene** (`scenes/world/test_room.tscn`) — Node3D root with:
   - GridMap child (using a MeshLibrary with simple box tiles — Kenney Fantasy Town Kit or primitive boxes for first pass)
   - A simple enclosed room (~10x10 tiles with walls)
   - DirectionalLight3D for basic lighting
   - WorldEnvironment with Environment resource (ambient light so scene isn't dark)
   - Player scene instanced at spawn point

7. **Camera setup** — Orthographic Camera3D as a sibling of the player in the room scene (not a child of player). Fixed rotation (~-30° X, 45° Y). Projection = orthographic, size ~10. A simple follow script reads the player's position each `_process` frame with lerp smoothing. Room bounds clamping added in Step 5 by extending the follow script — no refactoring needed. Camera properties: `projection = PROJECTION_ORTHOGONAL`, `size = 10.0`, `near = 0.05`, `far = 100.0`, `keep_aspect = KEEP_HEIGHT`.

8. **Update main scene** — Replace placeholder main.tscn to load test_room.tscn (or change `run/main_scene` in project settings to test_room).

**Acceptance Criteria:**
- [x] Player moves in 8 directions with analog input (WASD + gamepad left stick)
- [x] Movement is camera-relative (pressing W moves "forward" relative to the isometric view)
- [x] Player collides with GridMap walls and cannot pass through them
- [x] Camera maintains fixed orthographic angle, follows player
- [x] Player StateMachine transitions between Idle and Walk states
- [x] Collision layers configured: player on layer 2, environment on layer 1
- [x] `get_save_data()` / `load_save_data()` implemented on PlayerController
- [x] Runs at 60fps in the editor

##### Step 2: Interactable Pattern + NPC with Dialogue

**What it proves:** Interactable composition pattern generalizes. Dialogue Manager integration works. GameState mode switching (OVERWORLD ↔ DIALOGUE) blocks input correctly.

**Prerequisites:** Install Dialogue Manager plugin (Nathan Hoad) via git clone into addons.

**Tasks:**

1. **Install Dialogue Manager plugin** — Vendored copy (not submodule — the repo nests the plugin under `addons/dialogue_manager/`, which conflicts with submodule path):
   ```bash
   git clone --depth 1 https://github.com/nathanhoad/godot_dialogue_manager.git /tmp/dm_repo
   cp -r /tmp/dm_repo/addons/dialogue_manager addons/dialogue_manager
   ```
   Then enable in Godot: Project > Project Settings > Plugins > Dialogue Manager > Enable. Verify plugin loads without errors in Godot 4.6.

2. **Create interaction prompt UI** (`scenes/ui/interaction_prompt.tscn`) — CanvasLayer with a centered-bottom Label or PanelContainer showing "Press E to interact". Script toggles visibility.

3. **Write interaction_prompt.gd** (`scripts/ui/interaction_prompt.gd`):

```gdscript
# scripts/ui/interaction_prompt.gd
extends CanvasLayer

@onready var _label: Label = $PanelContainer/Label

func show_prompt(text: String = "Press E") -> void:
    _label.text = text
    visible = true

func hide_prompt() -> void:
    visible = false
```

4. **Create NPC interactable scene** (`scenes/interactables/npc.tscn`) — StaticBody3D root (collision layer 3 = npcs, also layer 4 = interactables for Area3D detection):
   - CollisionShape3D (CapsuleShape3D for physical bounds)
   - MeshInstance3D (placeholder character model)
   - The StaticBody3D itself is on layer 3 (npcs). The player's interaction Area3D has mask on layer 4. So the NPC's StaticBody3D also needs to be on layer 4, OR the player's Area3D masks layer 3 as well.
   - *Design decision:* Player's InteractionArea masks layers 3 + 4. NPCs are on layer 3. Chests/doors are on layer 4. This way the player can interact with both NPC bodies and interactable objects.

5. **Write npc_interactable.gd** (`scripts/interactables/npc_interactable.gd`):

```gdscript
# scripts/interactables/npc_interactable.gd
extends StaticBody3D
## NPC that triggers dialogue on interaction. Stateless — does not need save/load.

@export var dialogue_resource: Resource  # DialogueResource (type properly after plugin install)
@export var dialogue_title: String = "start"
@export var npc_id: String = ""

func interact(player: PlayerController) -> void:
    if not dialogue_resource:
        push_warning("NPC %s has no dialogue_resource assigned" % npc_id)
        return
    var quest_tracker: QuestTracker = player.get_quest_tracker()
    var inventory: Inventory = player.get_inventory()
    GameState.set_mode(GameState.GameMode.DIALOGUE)
    DialogueManager.show_dialogue_balloon(
        dialogue_resource, dialogue_title, [quest_tracker, inventory]
    )
    await DialogueManager.dialogue_ended
    # Guard: NPC may have been freed during dialogue (scene transition, load game)
    if not is_instance_valid(self):
        return
    GameState.set_mode(GameState.GameMode.OVERWORLD)
```

> **Research Insight — Timing:** The coroutine awaits a signal on `DialogueManager` (an autoload). If the NPC's scene is freed during the await (scene transition or load game via F9), the coroutine **still resumes** because the awaited signal is on the autoload. Without the `is_instance_valid(self)` guard, `GameState.set_mode(OVERWORLD)` would execute on a freed NPC at an unpredictable time.

> **Research Insight — Encapsulation:** Use `player.get_quest_tracker()` and `player.get_inventory()` instead of `self.get_node("../Player/QuestTracker")`. The player parameter is already passed in — no tree traversal needed. Hardcoded relative paths violate scene encapsulation and break on restructuring.

> **Note:** NPCs are stateless — they are NOT added to the `"saveable"` group. Don't implement empty save methods on stateless entities.

6. **Create dialogue balloon UI** (`scenes/ui/dialogue_balloon.tscn`) — Custom balloon scene for Dialogue Manager. CanvasLayer with PanelContainer, RichTextLabel for dialogue text, VBoxContainer for response choices. Based on Dialogue Manager's example balloon but styled for the game.

7. **Write dialogue_balloon.gd** (`scripts/ui/dialogue_balloon.gd`) — Handles `DialogueManager.show_dialogue_balloon()` lifecycle: display line, wait for input or choice selection, advance to next line, emit completion.

8. **Create test dialogue file** (`resources/dialogue/npc_greeting.dialogue`):

```
~ start

Nathan: Welcome, traveler! I've been waiting for someone brave enough to help.
- Tell me more.
    Nathan: There's a chest in this room with something I need. Could you fetch it for me?
    Nathan: I'd get it myself but... well, I'm an NPC. I don't move.
- Maybe later.
    Nathan: Take your time. I'm not going anywhere.
```

9. **Wire player interaction** — In `player_controller.gd`, track nearest interactable via `_on_interactable_entered` / `_on_interactable_exited` (pick closest by distance). On `interact` input action, call `nearest_interactable.interact(self)`. Transition player StateMachine to Interact state (blocks movement). Return to Idle when `GameState.game_state_changed` emits OVERWORLD.

10. **Wire GameState input blocking** — In player Idle and Walk states, check `GameState.current_mode == GameState.GameMode.OVERWORLD` before processing movement. When mode is DIALOGUE, player input is suppressed.

**Acceptance Criteria:**
- [x] Walking near the NPC shows "Press E" interaction prompt
- [x] Walking away hides the prompt
- [x] Pressing E opens dialogue balloon with NPC text
- [x] Player cannot move during dialogue (GameState = DIALOGUE)
- [x] Dialogue choices work (selecting a response shows the correct follow-up)
- [x] Dialogue ends cleanly, GameState returns to OVERWORLD, player can move again
- [x] Pressing E again re-triggers dialogue (NPC is re-interactable)
- [ ] Interaction prompt only shows for the nearest interactable if multiple are in range (not tested yet but pattern supports it)

> **Research Insight — Interaction Detection:** Player-owned Area3D (interactor pattern) is the community-preferred approach. It follows "call down" (player calls `interact()` on detected bodies), handles multiple overlapping interactables naturally (pick closest by distance), and requires only one Area3D node vs. N per-interactable. Keep distance comparison inside signal callbacks only — never poll `get_overlapping_bodies()` per frame.

> **Research Insight — Interact State Asymmetry:** NPC `interact()` is async (uses `await`), while Chest and Door are synchronous. The Interact player state listens for `GameState.game_state_changed → OVERWORLD` to exit, but Chest and Door never change GameState. **Resolution:** Only transition to Interact state for NPC interactions (which set DIALOGUE mode). Chest and Door interactions are instantaneous — the player stays in Idle/Walk state and calls `interact()` as a one-shot method call.

> **Research Insight — Performance:** Call `_state_machine.set_active(false)` when entering Interact state (dialogue). This disables `_process`, `_physics_process`, and `_unhandled_input` forwarding — eliminating three engine-to-GDScript callbacks per frame during dialogue. The `set_active()` method already exists on StateMachine. Re-enable in Interact state's `exit()`.

---

#### Phase 2: Game Loop — Items + Quest (Steps 3-4)

**Goal:** Player picks up an item from a chest, completes a fetch quest by returning it to the NPC. This is the **playable loop milestone**.

##### Step 3: Chest Interactable + Item Pickup

**What it proves:** Second interactable type validates the pattern generalizes. ItemData Resource layer works. Inventory system functions.

**Tasks:**

1. **Define ItemData resource** (`resources/items/item_data.gd`):

```gdscript
# resources/items/item_data.gd
class_name ItemData
extends Resource
## Definition for an item type. Read-only at runtime — never mutate shared Resources.

@export var item_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var icon: Texture2D = null
```

> **Simplification:** Removed `is_stackable` and `max_stack` — the inventory works with string IDs and doesn't consult ItemData for stacking rules. The prototype has one quest item. Add stacking limits when a concrete use case requires them.

2. **Create test item resource** (`resources/items/key_item.tres`) — ItemData with `item_id = "quest_amulet"`, `display_name = "Old Amulet"`, `description = "A tarnished amulet that hums faintly."`.

   > **Research Insight — Item Registry (RESOLVED):** Resolved by storing `display_name` in the Inventory alongside the item_id (passed via `add_item(id, quantity, display_name)`). ItemToast reads the display name from Inventory via `get_display_name()`. No separate registry needed for the prototype. Plan for a proper registry when item count grows.

3. **Write inventory system** (`scripts/inventory/inventory.gd`):

```gdscript
# scripts/inventory/inventory.gd
class_name Inventory
extends Node

signal item_added(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)

# Array of { "item_id": String, "quantity": int }
var _items: Array[Dictionary] = []

func add_item(item_id: String, quantity: int = 1) -> void:
    for entry: Dictionary in _items:
        if entry["item_id"] == item_id:
            entry["quantity"] += quantity
            item_added.emit(item_id, quantity)
            return
    _items.append({"item_id": item_id, "quantity": quantity})
    item_added.emit(item_id, quantity)

func remove_item(item_id: String, quantity: int = 1) -> bool:
    for i: int in range(_items.size()):
        if _items[i]["item_id"] == item_id:
            _items[i]["quantity"] -= quantity
            if _items[i]["quantity"] <= 0:
                _items.remove_at(i)
            item_removed.emit(item_id, quantity)
            return true
    return false

func has_item(item_id: String, quantity: int = 1) -> bool:
    for entry: Dictionary in _items:
        if entry["item_id"] == item_id and entry["quantity"] >= quantity:
            return true
    return false

func get_save_key() -> String:
    return "inventory"

func get_save_data() -> Dictionary:
    return {"items": _items.duplicate(true)}

func load_save_data(data: Dictionary) -> void:
    _items.assign(data.get("items", []))
```

4. **Inventory as child of Player** — Inventory node is a child of the Player scene. The player "owns" the inventory. Other systems access it via the player reference or via the quest tracker (which receives a reference during setup). This follows "call down, signal up."

5. **Create chest interactable scene** (`scenes/interactables/chest.tscn`) — StaticBody3D root (layer 4 = interactables):
   - CollisionShape3D (BoxShape3D for physical bounds)
   - MeshInstance3D (placeholder box mesh or Kenney chest model)
   - No separate Area3D needed — player's InteractionArea already detects bodies on layer 4 (chests are on layer 4 directly)

   *Wait — reconsider:* The brainstorm's interactable pattern puts an Area3D *on the interactable* for detection. But the gap resolution chose player-owned Area3D instead. These are compatible: the player's Area3D detects StaticBody3Ds on layers 3+4. No Area3D needed on the interactable itself. This is simpler.

6. **Write chest_interactable.gd** (`scripts/interactables/chest_interactable.gd`):

```gdscript
# scripts/interactables/chest_interactable.gd
extends StaticBody3D
## Item container that gives its contents on first interaction.

@export var item: ItemData = null
@export var item_quantity: int = 1
@export var chest_id: String = ""

var _is_opened: bool = false

func interact(player: PlayerController) -> void:
    if _is_opened:
        return
    if not item:
        push_warning("Chest %s has no item assigned" % chest_id)
        return
    var inventory: Inventory = player.get_inventory()
    if not inventory:
        return
    inventory.add_item(item.item_id, item_quantity)
    _is_opened = true  # Set AFTER successful add — never consume chest without giving item
    # TODO: swap mesh to open chest visual

func get_save_key() -> String:
    return chest_id

func get_save_data() -> Dictionary:
    return {"is_opened": _is_opened}

func load_save_data(data: Dictionary) -> void:
    _is_opened = data.get("is_opened", false)
    # TODO: update visual if opened
```

7. **Create item toast UI** (`scenes/ui/item_toast.tscn`) — Simple CanvasLayer notification that shows "Acquired: Old Amulet" for ~2 seconds. Script `item_toast.gd` connects to `Inventory.item_added` signal.

8. **Place chest in test room** — Add chest instance to test_room.tscn (via editor) containing `quest_amulet` ItemData.

9. **Write unit tests** (`tests/unit/test_inventory.gd`):
   - `test_add_item` — adds item, verifies `has_item` returns true
   - `test_remove_item` — adds then removes, verifies gone
   - `test_add_stackable` — adds same item twice, quantity increases
   - `test_has_item_quantity` — checks quantity threshold
   - `test_save_load_roundtrip` — `get_save_data()` → `load_save_data()` preserves state

**Acceptance Criteria:**
- [x] Walking near chest shows interaction prompt
- [x] Pressing E on chest adds item to inventory (toast notification appears)
- [x] Pressing E again on opened chest does nothing (no duplicate items)
- [x] `has_item("quest_amulet")` returns true after pickup
- [ ] Chest visual changes to opened state (even if just a color change for prototype)
- [x] Inventory save/load roundtrip preserves items
- [ ] Chest save/load roundtrip preserves opened state
- [x] All inventory unit tests pass

##### Step 4: Quest — "Fetch Item from Chest"

**What it proves:** QuestData Resources work. Quest tracking wires NPC, chest, and inventory into a complete gameplay loop. Dialogue branches on quest state via Dialogue Manager's `extra_game_states`.

**Tasks:**

1. **Define QuestData resource** (`resources/quests/quest_data.gd`):

```gdscript
# resources/quests/quest_data.gd
class_name QuestData
extends Resource

@export var quest_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var steps: Array[QuestStepData] = []
```

2. **Define QuestStepData resource** (`resources/quests/quest_step_data.gd`):

```gdscript
# resources/quests/quest_step_data.gd
class_name QuestStepData
extends Resource
## A single step in a quest. Dialogue files handle condition logic via if/do.

@export var step_id: String = ""
@export var description: String = ""
@export var next_step_id: String = ""  # Empty string = terminal step
```

> **Simplification:** Removed `condition_type`, `condition_params`, and `next_step_ids` array. The dialogue file already handles all quest logic through Dialogue Manager's native `if`/`do` syntax — the condition evaluation engine in QuestTracker was dead code (only one type was real, and dialogue bypassed it anyway). Single `next_step_id` replaces the array since the prototype has linear quests. When branching is needed, the dialogue file already supports it natively.

3. **Create fetch quest resource** (`resources/quests/fetch_quest.tres`) — QuestData:
   - `quest_id = "fetch_amulet"`
   - `display_name = "The Old Amulet"`
   - Step 1: `step_id = "get_amulet"`, `description = "Find the amulet in the chest"`, `next_step_id = "return_amulet"`
   - Step 2: `step_id = "return_amulet"`, `description = "Return the amulet to Nathan"`, `next_step_id = ""` (terminal)

4. **Write quest tracker** (`scripts/quest/quest_tracker.gd`):

```gdscript
# scripts/quest/quest_tracker.gd
class_name QuestTracker
extends Node
## Tracks active quests and their current step. Dialogue files drive all
## condition logic — this class only manages state transitions.
## Accessed by Dialogue Manager via extra_game_states.

signal quest_started(quest_id: String)
signal quest_step_completed(quest_id: String, step_id: String)
signal quest_completed(quest_id: String)

enum QuestState { INACTIVE, ACTIVE, COMPLETE }

# { quest_id: { "state": QuestState, "current_step_id": String, "data": QuestData } }
var _quests: Dictionary = {}

func start_quest(quest_data: QuestData) -> void:
    var qid: String = quest_data.quest_id
    if _quests.has(qid):
        return
    # Store read-only reference to QuestData. If future code needs to mutate
    # quest data at runtime, .duplicate(true) must be called here first.
    _quests[qid] = {
        "state": QuestState.ACTIVE,
        "current_step_id": quest_data.steps[0].step_id if quest_data.steps.size() > 0 else "",
        "data": quest_data,
    }
    quest_started.emit(qid)

func advance_quest(quest_id: String) -> void:
    if not _quests.has(quest_id):
        return
    var quest_info: Dictionary = _quests[quest_id]
    var step: QuestStepData = _get_current_step(quest_id)
    if not step:
        return
    quest_step_completed.emit(quest_id, step.step_id)
    if step.next_step_id == "":
        quest_info["state"] = QuestState.COMPLETE
        quest_info["current_step_id"] = ""
        quest_completed.emit(quest_id)
    else:
        quest_info["current_step_id"] = step.next_step_id

func get_quest_state(quest_id: String) -> QuestState:
    if not _quests.has(quest_id):
        return QuestState.INACTIVE
    return _quests[quest_id]["state"]

func is_quest_active(quest_id: String) -> bool:
    return get_quest_state(quest_id) == QuestState.ACTIVE

func is_quest_complete(quest_id: String) -> bool:
    return get_quest_state(quest_id) == QuestState.COMPLETE

func get_save_key() -> String:
    return "quest_tracker"

func get_save_data() -> Dictionary:
    var save: Dictionary = {}
    for qid: String in _quests:
        save[qid] = {
            "state": _quests[qid]["state"],
            "current_step_id": _quests[qid]["current_step_id"],
        }
    return save

func load_save_data(data: Dictionary) -> void:
    # Note: quest_data Resources must be re-attached after load
    for qid: String in data:
        if _quests.has(qid):
            _quests[qid]["state"] = data[qid].get("state", QuestState.INACTIVE)
            _quests[qid]["current_step_id"] = data[qid].get("current_step_id", "")

# -- Private --

func _get_current_step(quest_id: String) -> QuestStepData:
    var quest_info: Dictionary = _quests[quest_id]
    var quest_data: QuestData = quest_info["data"]
    for step: QuestStepData in quest_data.steps:
        if step.step_id == quest_info["current_step_id"]:
            return step
    return null
```

> **Simplification:** Removed `check_step_condition()` and `_evaluate_condition()` entirely (~25 lines). The dialogue file handles all condition logic through Dialogue Manager's native `if Inventory.has_item(...)` / `do QuestTracker.advance_quest(...)` syntax. The QuestTracker is now a pure state machine: start, advance, complete. No condition evaluation engine.

> **Research Insight — Resource Safety:** `_quests[qid]["data"]` stores a read-only reference to the shared QuestData Resource. If future code mutates quest data at runtime (e.g., removing completed steps), it must `.duplicate(true)` first. For Godot 4.6, `duplicate(true)` deep-copies sub-resources in arrays (PR #100673), but verify with a test that `quest_data.steps[0] != duplicated.steps[0]`.

5. **QuestTracker as child of Player** — Like Inventory, the QuestTracker is a child node of the Player scene. This keeps all player state co-located and follows the "call down" pattern.

6. **Wire quest-aware dialogue** — Update NPC dialogue file to branch on quest state using Dialogue Manager's `extra_game_states`:

```
~ start

if QuestTracker.is_quest_complete("fetch_amulet")
    Nathan: Thank you for the amulet! You're a true hero.
elif QuestTracker.is_quest_active("fetch_amulet")
    Nathan: Have you found the amulet yet?
    if Inventory.has_item("quest_amulet")
        Nathan: You have it! Wonderful!
        do QuestTracker.advance_quest("fetch_amulet")
    else
        Nathan: It should be in that chest over there.
else
    Nathan: Welcome, traveler! I need your help.
    Nathan: There's an old amulet in that chest. Could you bring it to me?
    - I'll help you.
        do QuestTracker.start_quest(fetch_quest_resource)
        Nathan: Wonderful! The chest is right over there.
    - Not right now.
        Nathan: Come back if you change your mind.
```

   *Key integration detail:* The NPC's `interact()` method passes `[player.get_quest_tracker(), player.get_inventory()]` as `extra_game_states` to `DialogueManager.show_dialogue_balloon()`. This lets the `.dialogue` file reference `QuestTracker` and `Inventory` methods/properties directly. The player reference is already passed to `interact()` — no tree traversal needed.

   *Alternative considered:* Making QuestTracker and Inventory autoloads. Rejected — they're player-owned state, not global. The `extra_game_states` approach is Dialogue Manager's intended mechanism for this.

   *Note on dialogue mutations:* `advance_quest` and `remove_item` calls must be on the **same dialogue line** (or consecutive `do` statements within the same dialogue step) to ensure atomicity. If they are on different dialogue lines, there is a frame between them where the quest is advanced but the item still exists — a force-quit between those lines would produce inconsistent save state.

7. **Create quest indicator UI** (`scenes/ui/quest_indicator.tscn`) — Simple HUD element showing active quest name and current step description. CanvasLayer at top of screen. Updates when `quest_started` / `quest_step_completed` / `quest_completed` signals fire.

8. **Handle quest item consumption** — When the NPC's dialogue calls `QuestTracker.advance_quest("fetch_amulet")` on the "return" step, also remove the item: `do Inventory.remove_item("quest_amulet")`. This happens in the dialogue file mutation.

9. **Write unit tests** (`tests/unit/test_quest_tracker.gd`):
   - `test_start_quest` — starts quest, verifies ACTIVE state
   - `test_advance_quest` — advances through steps
   - `test_quest_completes` — final step has no next, state becomes COMPLETE
   - `test_check_condition_has_item` — with mock inventory
   - `test_save_load_roundtrip` — preserves quest state and current step

10. **Write integration test** (`tests/integration/test_quest_loop.gd`):
    - Full loop: start quest → add item to inventory → check condition → advance → complete
    - Verifies signals fire in correct order

**Acceptance Criteria:**
- [x] Talking to NPC before accepting quest shows intro dialogue with choice
- [x] Accepting quest starts tracking (quest indicator shows "The Old Amulet")
- [x] Talking to NPC mid-quest (without item) shows "have you found it?" dialogue
- [x] Picking up amulet from chest triggers item toast
- [x] Talking to NPC with amulet in inventory triggers recognition dialogue
- [x] Quest completes, amulet is removed from inventory
- [x] Talking to NPC after completion shows thank-you dialogue
- [x] Quest indicator updates at each step and shows "Complete" at end
- [x] All quest tracker unit tests pass
- [x] Integration test for full quest loop passes
- [x] **Playable loop milestone achieved:** One room, one NPC, one quest, all systems integrated

---

#### Phase 3: Multi-Room + Persistence (Steps 5-6)

**Goal:** Expand to two rooms with scene transitions. Add save/load persistence.

##### Step 5: Second Room + Door Interactable

**What it proves:** Third interactable type (door). Scene transitions work. SceneManager autoload justified by concrete need.

**Tasks:**

1. **Create SceneManager autoload** (`scripts/autoloads/scene_manager.gd`):

```gdscript
# scripts/autoloads/scene_manager.gd (current implementation)
extends Node
## Manages scene transitions with fade overlay and persistent player.

signal scene_change_started
signal scene_change_completed
signal player_registered(player: PlayerController)

var _is_transitioning: bool = false
var _player: PlayerController = null
var _transition_overlay: ColorRect

func is_transitioning() -> bool:
    return _is_transitioning

func get_player() -> PlayerController:
    return _player

func _ready() -> void:
    var canvas: CanvasLayer = CanvasLayer.new()
    canvas.layer = 100
    add_child(canvas)
    _transition_overlay = ColorRect.new()
    _transition_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
    _transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    canvas.add_child(_transition_overlay)

func register_player(player: PlayerController) -> void:
    if _player and is_instance_valid(_player):
        player.queue_free()
        return
    _player = player
    player.get_parent().call_deferred("remove_child", player)
    get_tree().root.call_deferred("add_child", player)
    player_registered.emit(_player)

func change_scene(target_scene_path: String, spawn_point_id: String = "") -> void:
    if _is_transitioning:
        return
    _is_transitioning = true
    scene_change_started.emit()
    var tween: Tween = create_tween()
    tween.tween_property(_transition_overlay, "color:a", 1.0, 0.3)
    await tween.finished
    if not _is_transitioning:
        return
    WorldState.snapshot()
    var err: Error = get_tree().change_scene_to_file(target_scene_path)
    if err != OK:
        push_error("Failed to change scene: %s" % error_string(err))
        _is_transitioning = false
        return
    await get_tree().scene_changed
    WorldState.restore()
    if spawn_point_id != "" and _player:
        _place_player_at_spawn(spawn_point_id)
    tween = create_tween()
    tween.tween_property(_transition_overlay, "color:a", 0.0, 0.3)
    await tween.finished
    _is_transitioning = false
    scene_change_completed.emit()
```

   *Note:* SceneManager is registered as a `.gd` autoload (not `.tscn`) to preserve full type inference with strict typing. The CanvasLayer + ColorRect fade overlay is built programmatically in `_ready()`. Using a `.tscn` autoload causes the parser to infer `Node` type, breaking `unsafe_method_access` checks across all call sites ([godot#86300](https://github.com/godotengine/godot/issues/86300)).

> **Research Insight — Timing (UPDATED):** The original plan used `process_frame` counting. Post-Phase 3 refactor now uses `await get_tree().scene_changed` (Godot 4.5+ signal, fires after new scene's `_ready()` completes). This is more reliable than frame counting. See [refactor plan](2026-03-20-refactor-pre-phase4-cleanup-plan.md) Phase 3.

> **Research Insight — Persistent Player:** Changed from Option A (save/restore across scenes) to persistent player pattern. The player is reparented to root via `register_player()` in Step 1, then persists across all scene changes. Inventory, QuestTracker, and all player state naturally survive transitions without serialization. This is the pattern used by Cassette Beasts and recommended by the community for RPGs.

2. **Create second room** (`scenes/world/test_room_2.tscn`) — Similar GridMap layout to test_room but visually distinct (different tile arrangement). Contains a Marker3D node named by spawn_point_id for player placement on entry.

3. **Add spawn points to rooms** — Each room has Marker3D nodes at door locations, named with IDs (e.g., `"spawn_from_room_1"`, `"spawn_from_room_2"`). SceneManager finds these by name after scene load.

4. **Create door interactable scene** (`scenes/interactables/door.tscn`) — StaticBody3D on layer 4:
   - CollisionShape3D
   - MeshInstance3D (door/archway mesh)

5. **Write door_interactable.gd** (`scripts/interactables/door_interactable.gd`):

```gdscript
# scripts/interactables/door_interactable.gd
extends StaticBody3D
## Scene transition trigger. Interact to move to target scene.

@export_file("*.tscn") var target_scene_path: String = ""
@export var target_spawn_point: String = ""
@export var door_id: String = ""

func interact(_player: PlayerController) -> void:
    SceneManager.change_scene(target_scene_path, target_spawn_point)
```

> **Simplification:** Removed `is_locked`, `required_item_id`, and the key-checking interaction flow. No door in the prototype is locked. The fetch quest uses no locked doors. Add lock/key when a gameplay need requires it. Also removed save/load methods — doors with no mutable state don't need to be saveable.

> **Research Insight:** Use `@export_file("*.tscn")` instead of bare `@export var ... : String`. This gives the editor a file picker and makes the path dependency visible, preventing typos.

6. **Register SceneManager autoload** — Add to project.godot: `SceneManager="*res://scripts/autoloads/scene_manager.gd"`. Always use `.gd` autoloads (not `.tscn`) to preserve strict typing — build child nodes programmatically in `_ready()` instead.

7. **Place doors in both rooms** — Room 1 has a door leading to Room 2 and vice versa. Each door's `target_scene_path` and `target_spawn_point` are configured via exports.

8. **Player persistence across scenes** — The player lives under the scene tree root (reparented by SceneManager in Step 1 via `register_player()`). The player naturally persists across `change_scene_to_file()` calls since only the current_scene subtree is freed. Inventory, QuestTracker, and all child nodes survive transitions without serialization.

   *Why not save/restore per transition:* Community best practice for RPGs is persistent player. Save/restore on every room change introduces a serialization dance, creates a frame where the player doesn't exist, and tests the save contract on every door interaction rather than reserving it for actual saves.

9. **Write integration test** (`tests/integration/test_scene_transition.gd`):
   - Verify SceneManager loads target scene
   - Verify player position matches spawn point after transition
   - Verify player inventory persists across transition

**Acceptance Criteria:**
- [ ] Walking near door shows interaction prompt
- [ ] Pressing E on door triggers scene transition (fade to black, load, fade in)
- [ ] Player appears at correct spawn point in new room
- [ ] Player inventory and quest state persist across rooms
- [ ] Return door in Room 2 leads back to Room 1 at correct spawn
- [ ] Cannot trigger another transition while one is in progress
- [ ] Scene transition integration test passes

##### Step 6: Save/Load

**What it proves:** The `get_save_data()` / `load_save_data()` contract works across all systems. SaveManager iterates and serializes without system-specific knowledge.

**Tasks:**

1. **Create SaveManager autoload** (`scripts/autoloads/save_manager.gd`):

```gdscript
# scripts/autoloads/save_manager.gd (current implementation — key changes only)
# Full file: see scripts/autoloads/save_manager.gd

func save_game() -> void:
    if SceneManager.is_transitioning():  # Public accessor, not private var
        push_warning("Cannot save during scene transition")
        return
    # ... (collect + atomic write unchanged)

func _collect_save_data() -> Dictionary:
    # ... iterates "saveable" group with .call() for duck typing
    # WorldState is in "saveable" group — serialized as "world_state" key

func _restore_save_data(data: Dictionary) -> void:
    var scene_path: String = data.get("scene_path", "")
    if scene_path != "" and scene_path != get_tree().current_scene.scene_file_path:
        SceneManager.change_scene(scene_path)
        await SceneManager.scene_change_completed
    # CRITICAL: Load WorldState AFTER scene change completes.
    # change_scene() calls WorldState.snapshot() — loading before would be clobbered.
    if data.has("world_state"):
        var world_data: Dictionary = data["world_state"]
        WorldState.load_save_data(world_data)
        WorldState.restore()
    # Restore remaining saveables, skip WorldState (already restored above)
    for node: Node in get_tree().get_nodes_in_group("saveable"):
        if node == WorldState:
            continue
        if node.has_method("get_save_key") and node.has_method("load_save_data"):
            var key: String = node.call("get_save_key")
            if data.has(key):
                node.call("load_save_data", data[key])
```

   *Key pattern (UPDATED):* Saveable nodes add themselves to `"saveable"` group in `_ready()`. SaveManager iterates the group for disk persistence. Interactables (chests) use `"interactable_saveable"` group instead — WorldState handles their session state as a single blob. SaveManager uses `SceneManager.is_transitioning()` (not `._is_transitioning`). `_restore_save_data()` loads WorldState AFTER scene change to prevent `snapshot()` from clobbering loaded data. See [refactor plan](2026-03-20-refactor-pre-phase4-cleanup-plan.md) Phase 3.

> **Research Insight — Atomic Writes:** Write to `.tmp` then `DirAccess.rename_absolute()` (maps to POSIX `rename()` / Windows `MoveFileEx`). If the process crashes mid-write, the old save file is still intact.

> **Research Insight — Timing:** `_restore_save_data()` routes scene changes through SceneManager (not direct `change_scene_to_file()`) to avoid bypassing the transition state. Uses `await get_tree().process_frame` (not `tree_changed`) to ensure the new scene is fully ready.

> **Research Insight — Save Key:** Dedicated `get_save_key() -> String` method replaces the `_save_key` embedded in data dictionaries. Cleaner separation — no need to call `get_save_data()` just to extract a key during load.

2. **Register SaveManager autoload** — Add to project.godot.

3. **Add debug keybinds** — Input actions `debug_save` (F5) and `debug_load` (F9). A simple script (on the root or an autoload) listens for these and calls `SaveManager.save_game()` / `SaveManager.load_game()`.

4. **Add groups to stateful nodes** — `"saveable"` group: PlayerController, Inventory, QuestTracker, WorldState (disk persistence). `"interactable_saveable"` group: chests (WorldState session state). Doors are NOT saveable (no mutable state).

5. **Save key strategy** — Each saveable node implements `get_save_key() -> String` returning a unique identifier. PlayerController returns `"player"`, Inventory returns `"inventory"`, QuestTracker returns `"quest_tracker"`, chests return their `chest_id`. Doors and NPCs are not saveable (no mutable state in prototype).

6. **Write unit test** (`tests/unit/test_save_data_contracts.gd`):
   - For each saveable class: call `get_save_data()`, modify state, call `load_save_data()`, verify state matches original

7. **Write integration test** (`tests/integration/test_save_load_cycle.gd`):
   - Full cycle: move player, pick up item, start quest, save, modify state, load, verify everything restored

**Acceptance Criteria:**
- [ ] F5 saves game to `user://saves/save_001.json`
- [ ] F9 loads game from save file
- [ ] Player position restores correctly
- [ ] Player inventory restores correctly
- [ ] Quest progress restores correctly
- [ ] Chest opened states restore correctly
- [ ] Save version is validated on load (incompatible version shows error)
- [ ] Current scene restores correctly (if saved in Room 2, loads Room 2)
- [ ] Save file is human-readable JSON
- [ ] Loading a save in a different room triggers scene change first
- [ ] Loading with no save file shows warning, doesn't crash
- [ ] Save/load contract unit tests pass for all saveable classes
- [ ] Full save/load integration test passes

---

#### Phase 4: Cross-System Events + Game Modes (Steps 7-8)

**Goal:** Wire up cross-system communication and a second game mode.

##### Step 7: Cross-System Events (EventBus)

**What it proves:** EventBus is justified by concrete need — signals between systems that can't reach each other through the scene tree.

**Tasks:**

1. **Identify concrete cross-system signals needed** — At this point, review which signals are awkwardly wired through parents and would benefit from EventBus. Likely candidates:
   - `quest_completed` — the quest indicator UI needs to know, but QuestTracker is under Player and the UI may be a separate CanvasLayer
   - `item_acquired` — global notification (achievements, statistics) beyond the immediate parent

2. **Add signals to EventBus** — Only signals identified in task 1. Do not speculate.

3. **Refactor existing signal connections** — Replace any "reaching up through the tree" hacks with EventBus signals where justified. Keep direct parent-child signals where they work fine.

4. **Audit signal architecture** — Verify "call down, signal up" is followed everywhere. Document any exceptions.

**Audit Result (2026-03-20):**

The pre-Phase 4 refactor (HUD autoload + `player_registered` signal) already eliminated all cross-tree wiring. Every signal has a natural owner and direct connection:
- QuestTracker → QuestIndicator: via HUD `connect_to_player()` pattern
- Inventory → ItemToast: via HUD `connect_to_player()` pattern
- PlayerController → InteractionPrompt: via HUD `connect_to_player()` pattern
- GameState → Player states: direct autoload reference (fine — GameState is a global singleton by design)
- SceneManager → HUD: `player_registered` signal (SceneManager owns player lifecycle)

**No EventBus signals needed.** EventBus stays empty. All candidate signals (`quest_completed`, `item_acquired`) already reach their consumers through the HUD pattern without tree traversal. No achievements or statistics system exists to consume global broadcasts.

EventBus will gain signals when a concrete consumer emerges that cannot be connected through HUD or parent-child relationships (e.g., an achievement system, an analytics tracker, or a world-reaction system).

**Acceptance Criteria:**
- [x] EventBus has only concrete, justified signals (zero — all wired via HUD pattern)
- [x] No system imports or references another system directly (except parent→child and autoloads)
- [x] All existing functionality still works after refactor
- [x] Signal flow is documented in comments or a brief architecture note

##### Step 8: Second Game Mode (GameState)

**What it proves:** GameState mode switching works. The existing GameMode enum handles a second mode beyond OVERWORLD + DIALOGUE.

**Tasks:**

1. **Choose the second mode** — Most likely MENU (pause menu). This is the simplest additional mode and naturally follows from having save/load (the player needs a menu to access save/load properly instead of debug keybinds).

2. **Create pause menu UI** — Simple CanvasLayer with Resume, Save, Load, Quit buttons. Opens on `pause` input action (Tab/Start). Calls `GameState.set_mode(GameState.GameMode.MENU)`.

3. **Input blocking per mode** — Formalize which inputs are blocked per GameMode:
   - OVERWORLD: all inputs active
   - DIALOGUE: movement blocked, interact/cancel active (for dialogue advancement)
   - MENU: all game inputs blocked, only menu navigation active

4. **Wire pause menu to SaveManager** — Save/Load buttons call `SaveManager.save_game()` / `SaveManager.load_game()`.

5. **Remove debug keybinds** — Remove F5/F9 entirely. Save/load is menu-only.

6. **Quit behavior** — `get_tree().quit()` for now. Eventually return to a main menu scene (deferred).

7. **Pause menu follows HUD pattern** — Instantiated by HUD autoload like other UI. HUD handles `pause` input in `_unhandled_input()` and toggles menu visibility + GameState mode.

**Acceptance Criteria:**
- [x] Tab/Start opens pause menu
- [x] Game world pauses (or at minimum, input is blocked)
- [x] Resume returns to OVERWORLD
- [x] Save/Load work from menu
- [x] Quit calls `get_tree().quit()` (main menu deferred)
- [x] Cannot open pause menu during dialogue
- [x] Cannot move during menu

---

## Alternative Approaches Considered

| Approach | Considered For | Why Rejected |
|----------|---------------|--------------|
| Dialogic 2 | Dialogue system | Alpha stability, confirmed Godot 4.6 crashes (issue #2736). Dialogue Manager is stable + stateless. |
| 2D isometric | Rendering | Eliminates Y-sort, depth sorting, mouse picking pain. 3D orthographic gives these natively. Both reference games (Hades, Cassette Beasts) are 3D. |
| Skeleton systems first | Build approach | Community consensus warns against systems in isolation. Playable loop concentrates refactoring in the data layer where upfront design prevents it. |
| Interactable base class | Interaction pattern | Violates "derive only from engine node types" (CLAUDE.md). Composition via shared Area3D detection pattern instead. |
| Inventory/QuestTracker as autoloads | State ownership | They're player state, not global state. Autoloads hide ownership. `extra_game_states` in Dialogue Manager handles cross-reference. |
| Resource-based saves | Persistence | Research shows Resources silently drop data on rename, no built-in versioning. Dictionary→JSON is safer for early development with frequent schema changes. |
| NavigationRegion3D | NPC pathfinding | Decision deferred per brainstorm. NPCs don't move in the prototype. Will decide between NavMesh and AStar3D when needed. |
| RefCounted middle layer | Data architecture | Community consensus says niche. Add only if concrete performance need arises. Two-layer (Resource + Node) is sufficient. |
| Services pattern (single autoload) | Autoload management | Research recommends this for 8+ autoloads. We have 7 (EventBus, GameState, DialogueManager, WorldState, SceneManager, SaveManager, HUD). Individual autoloads are simpler at this scale. Revisit if autoload count grows past 10. |
| Save/restore player per transition | Player persistence | Creates serialization dance on every door interaction, brief frame with no player, tests save contract unnecessarily. Persistent player node is simpler and community-preferred for RPGs. |
| Player state files (Idle/Walk/Interact) | Player states | Existing StateMachine infra is sunk cost. Three states with ~25 lines total logic could be inlined into player_controller.gd with a single `if GameState.current_mode != OVERWORLD: return` check. Keep StateMachine approach for future complexity (combat, knockback) but acknowledge the tradeoff. |

## System-Wide Impact

### Signal Chain

**Interaction flow:**
Action `interact` → PlayerController._unhandled_input() → calls `_nearest_interactable.interact(self)` → interactable-specific behavior:
- NPC: `GameState.set_mode(DIALOGUE)` → `GameState.game_state_changed` signal → Player states check mode → movement blocked → `DialogueManager.show_dialogue_balloon()` → dialogue mutations may call `QuestTracker.start_quest()` / `QuestTracker.advance_quest()` / `Inventory.add_item()` / `Inventory.remove_item()` → `DialogueManager.dialogue_ended` → `GameState.set_mode(OVERWORLD)` → movement unblocked
- Chest: `Inventory.add_item()` → `Inventory.item_added` signal → ItemToast shows notification
- Door: `SceneManager.change_scene()` → `SceneManager.scene_change_started` → fade → `WorldState.snapshot()` → scene load → `await scene_changed` → `WorldState.restore()` → player spawn → `SceneManager.scene_change_completed`

**Quest state check (during NPC dialogue):**
Dialogue Manager evaluates conditions → calls `QuestTracker.is_quest_active()` / `QuestTracker.is_quest_complete()` / `Inventory.has_item()` via `extra_game_states` → branches dialogue accordingly

### Error & Failure Propagation

- **Missing interactable method:** If a StaticBody3D on layers 3/4 doesn't have `interact()`, PlayerController should guard with `has_method("interact")` check. Silent skip, no crash.
- **Missing dialogue resource:** NPC with null `dialogue_resource` should early-return from `interact()`. `push_warning()` for developer visibility.
- **Save file corruption:** `JSON.parse()` failure → `push_error()` + return. Game continues from current state. No crash.
- **Missing save key on load:** `data.get()` with defaults everywhere. Missing keys restore to defaults, never crash.
- **Scene load failure:** `change_scene_to_file()` with invalid path → Godot prints error. SceneManager should validate path before attempting. `push_error()` + reset `_is_transitioning` flag.

### State Lifecycle Risks

- **Chest opened but item not added:** FIXED — chest now sets `_is_opened = true` AFTER `inventory.add_item()` with null guard. If inventory is null, chest stays closed.
- **Quest advanced but item not removed:** Place `do QuestTracker.advance_quest(...)` and `do Inventory.remove_item(...)` on the same dialogue line or consecutive `do` statements within the same step. Dialogue Manager executes mutations within a single step atomically.
- **Save during scene transition:** FIXED — SaveManager now checks `SceneManager.is_transitioning()` and refuses to save during transitions.
- **NPC coroutine survives node destruction:** FIXED — `is_instance_valid(self)` guard added after `await DialogueManager.dialogue_ended`. Also, SaveManager routes scene changes through SceneManager (not direct `change_scene_to_file()`), preventing SceneManager from being permanently locked by a bypassed transition.
- **Player state between scenes:** No longer a risk — persistent player node survives scene changes without serialization.

### Scene Interface Parity

**Interactable interface** (duck-typed, checked via `has_method()`):
- `func interact(player: PlayerController) -> void` — called by PlayerController

**Saveable interface** (for nodes with mutable state, two tiers):
- `func get_save_key() -> String` — unique identifier for save data
- `func get_save_data() -> Dictionary` — serialize current state
- `func load_save_data(data: Dictionary) -> void` — restore from saved state
- `"saveable"` group — disk persistence (SaveManager iterates): Player, Inventory, QuestTracker, WorldState
- `"interactable_saveable"` group — session state (WorldState iterates): chests

NPCs and Doors (stateless in prototype) are not in either group. See CLAUDE.md for full convention.

### Integration Test Scenarios

1. **Full quest loop across rooms** — Start in Room 1, talk to NPC, accept quest, walk to Room 2 via door, open chest, walk back to Room 1, turn in quest. Verifies scene transitions preserve quest + inventory state.
2. **Save mid-quest, load, complete quest** — Accept quest, save, pick up item, load (item should be gone, quest still active), pick up item again, complete quest. Verifies save/load doesn't corrupt quest state.
3. **Save in Room 2, load from Room 1** — Save while in Room 2. Start a new game (in Room 1). Load save. Should transition to Room 2 with correct player position and state.
4. **Interact during mode transitions** — Rapidly press interact while GameState is changing. Verify no double-interactions or state corruption.
5. **Multiple chests, verify independent state** — Open one chest, save, verify only that chest is marked opened in save data. Load and verify other chests are still closed.

## Acceptance Criteria

### Functional Requirements

- [x] Player moves freely in 3D orthographic world with analog input
- [x] Player interacts with NPCs (dialogue), chests (items), and doors (scene transitions)
- [x] Complete fetch quest loop: accept → find item → return → complete
- [x] Dialogue branches based on quest state
- [x] Scene transitions with fade effect preserve all player state
- [x] Save/load preserves player position, inventory, quest progress, and interactable states
- [x] GameState mode switching blocks input appropriately

### Non-Functional Requirements

- [x] 60fps in editor with test room (~100 GridMap tiles)
- [x] Static typing on all declarations (enforced by project settings)
- [x] `gdformat --check .` and `gdlint .` pass
- [x] All Resources use string IDs, never direct node references
- [x] All stateful systems implement `get_save_data()` / `load_save_data()`

### Quality Gates

- [x] All unit tests pass (inventory, quest tracker, save contracts)
- [x] All integration tests pass (quest loop, scene transition, save/load cycle)
- [x] No orphaned Resources or dangling node references after scene transitions
- [x] Save file is valid JSON and human-readable

## Dependencies & Prerequisites

| Dependency | Type | Status | Needed By |
|-----------|------|--------|-----------|
| Godot 4.6.1 | Engine | Installed (assumed) | Step 1 |
| GUT | Testing | Installed (`addons/gut/`) | Step 3 |
| Dialogue Manager plugin | Addon | **Installed** — vendored copy at `addons/dialogue_manager/` (enable in editor) | Step 2 |
| Kenney/KayKit 3D assets | Art | **Not downloaded** | Step 1 (can use primitives) |
| MeshLibrary | Asset | **Not created** | Step 1 |
| gdtoolkit 4.x | Tooling | Installed (assumed) | All steps |

**Critical path:** Dialogue Manager is vendored at `addons/dialogue_manager/` — must be enabled in editor before Step 2. Step 1 can use primitive meshes (BoxMesh, CapsuleMesh) if art assets aren't ready — the MeshLibrary can be swapped later.

## Work Split: Agent vs. Editor

**Agent writes:** All `.gd` scripts, `.dialogue` files, `.tres` resource files (text format), test files, `project.godot` edits (input actions, autoloads, collision layers). Runs `gdformat`/`gdlint`/GUT.

**You build in editor:** `.tscn` scene files (node trees, visual layout, GridMap painting), MeshLibrary creation. Detailed instructions for each scene are below.

Agent will complete its script work for a step first, then hand you the scene instructions. You build the scenes, then we test together.

> **Prompt for agent when writing editor instructions:**
> The user builds scenes manually in the Godot editor. Editor instructions must be **step-by-step, explicit, and assume no prior Godot knowledge**. For every node:
> - State the exact node type to add and what to rename it to
> - List every Inspector property to change, with the exact value (e.g., "Rotation X: **-45°**" not "tilt downward")
> - Explain **why** non-obvious values are set (e.g., "Y=0.9 because a 1.8-tall capsule centered at Y=0 buries half underground")
> - For collision layers/masks, state which **bit numbers** to enable and name them (e.g., "Mask = bits 1 + 3 (environment + npcs)")
> - Explain the consequence of getting it wrong (e.g., "if Current is not true, you see a grey screen")
> - Include a **verification step** after anything that can silently fail (e.g., "click Preview to confirm the camera sees the scene", "check that `shapes` is not an empty array in the .tres file")
> - Show the expected node tree structure when the hierarchy matters
> - Do not assume the user will know which Inspector section a property lives in — give the full path (e.g., "Inspector > Collision > Mask")

### Before Step 1

- [x] **MeshLibrary** — This requires the editor's "Export As MeshLibrary" workflow. **Every MeshInstance3D must have a StaticBody3D > CollisionShape3D child**, otherwise GridMap tiles will have no collision and the player will walk through walls/floors.
  1. Create new scene (Scene > New Scene > Other Node > **Node3D** as root)
  2. Add child **MeshInstance3D** nodes for each tile type. The converter only picks up **children** of the root — the root node itself is ignored:
     - **"Floor"** (MeshInstance3D): Mesh = new BoxMesh (default 1×1×1). Add child **StaticBody3D**, and under that add **CollisionShape3D** with a new BoxShape3D (keep default 1×1×1 to match the mesh).
     - **"Wall"** (MeshInstance3D): Mesh = new BoxMesh, set size to (1, 3, 1). Add child **StaticBody3D**, and under that add **CollisionShape3D** with a new BoxShape3D, set size to **(1, 3, 1)** to match the mesh exactly.
  3. Verify the scene tree looks like:
     ```
     Node3D (root)
       ├── Wall (MeshInstance3D)
       │   └── StaticBody3D
       │       └── CollisionShape3D (BoxShape3D, size 1×3×1)
       └── Floor (MeshInstance3D)
           └── StaticBody3D
               └── CollisionShape3D (BoxShape3D, size 1×1×1)
     ```
  4. Save this source scene to `resources/mesh_library_source.tscn` (keep it — you'll need it to re-export if you add tiles later)
  5. Scene menu > **Export As... > MeshLibrary** > Save as `resources/mesh_library.tres`
  6. **Verify collision was exported:** Open `mesh_library.tres` in the text editor and confirm `item/0/shapes` and `item/1/shapes` are **not empty arrays**. If they show `shapes = []`, the StaticBody3D/CollisionShape3D hierarchy is wrong — go back to step 2.

- [x] **Player scene** (`scenes/player/player.tscn`):
  1. Scene > New Scene > Other Node > **CharacterBody3D** (rename to "Player")
  2. Inspector > Collision:
     - **Layer** = 2 (player) — only bit 2 enabled
     - **Mask** = 1 + 3 (environment + npcs) — bits 1 and 3 enabled. **The mask controls what `move_and_slide()` collides with.** If npcs (layer 3) is not in the mask, the player walks straight through NPC bodies.
  3. Add children in this order:
     - **CollisionShape3D** — Shape: New CapsuleShape3D (radius=0.3, height=1.8). **Position Y=0.9** (a capsule with height 1.8 centered at Y=0 buries half underground; Y=0.9 places the bottom at floor level).
     - **MeshInstance3D** — Mesh: New CapsuleMesh (radius=0.3, height=1.8). **Position Y=0.9** (must match CollisionShape3D offset).
     - **Area3D** (rename to "InteractionArea") — This detects nearby interactables for the "Press E" prompt. Collision **Layer = none** (all bits off — the area doesn't need to be detected by others), **Mask = 3 + 4** (npcs + interactables — these are the layers it scans for). Add child **CollisionShape3D** with **SphereShape3D** (radius=2.0). The 2.0m radius defines how close the player must be to trigger the prompt.
     - **StateMachine** (type: Node, attach `res://shared/state_machine/state_machine.gd`)
       - **Idle** (type: Node, attach `res://scripts/player/player_states/player_idle.gd`)
       - **Walk** (type: Node, attach `res://scripts/player/player_states/player_walk.gd`)
       - **Interact** (type: Node, attach `res://scripts/player/player_states/player_interact.gd`)
     - **Inventory** (type: Node, attach `res://scripts/inventory/inventory.gd`)
  4. Select StateMachine node > Inspector: Initial State = drag the **Idle** node into the slot
  5. Select root "Player" node > attach script `res://scripts/player/player_controller.gd`
  6. Save as `scenes/player/player.tscn`

  *Note: QuestTracker node is added in Step 4. Omit it for now.*

  > **Collision layer vs. mask — quick reference:**
  > - **Layer** = "I am on these layers" (what others detect me as)
  > - **Mask** = "I detect/collide with these layers" (what I scan for)
  > - For CharacterBody3D, the mask determines what `move_and_slide()` treats as solid. If a StaticBody3D is on layer 3 but the player's mask doesn't include 3, the player phases through it.
  > - For Area3D, the mask determines which bodies trigger `body_entered`/`body_exited` signals.

- [x] **Test room scene** (`scenes/world/test_room.tscn`):
  1. Scene > New Scene > Other Node > **Node3D** (rename to "TestRoom")
  2. Add children in this order:

     **GridMap:**
     - Add child > GridMap node
     - Inspector: Mesh Library = load `resources/mesh_library.tres`
     - Inspector: Cell Size = (1, 1, 1)
     - Use the GridMap toolbar (bottom panel) to paint tiles:
       - Select the **Floor** tile, paint a ~16×32 area on **Y level 0** (the default level)
       - Select the **Wall** tile, paint walls around the perimeter on **Y level 1** (one layer up — walls are 3 units tall with origin at center, so placing on level 1 raises them above the floor). Use the GridMap toolbar's level selector to switch levels.
     - **Verify collision:** After painting, click **Play Scene (F6)**. If the player walks through walls, the MeshLibrary is missing collision shapes — go back to the MeshLibrary instructions above.

     **DirectionalLight3D:**
     - Add child > DirectionalLight3D
     - Inspector: Transform > Rotation = X: **-45°**, Y: **30°**, Z: 0°
     - Inspector: Shadow > Enabled = **true**

     **WorldEnvironment:**
     - Add child > WorldEnvironment
     - Inspector: Environment = New Environment
     - In the Environment resource: Ambient Light > Source = **Color**, Color = **#404040**, Energy = **0.5**

     **Camera3D (rename to "RoomCamera"):**
     - Add child > Camera3D, rename to "RoomCamera"
     - Inspector: Projection = **Orthographic**
     - Inspector: Size = **10** (controls zoom — how many world units fit vertically on screen)
     - Inspector: Near = **0.05**, Far = **100**
     - Inspector: **Current = true** (required — without this Godot uses no camera and you see a grey screen)
     - Inspector: Transform > Rotation = X: **-45°**, Y: **45°**, Z: **0°**. The X rotation tilts the camera to look downward (negative = nose points down). The Y rotation gives the isometric angle. **Do not use positive X values** — that makes the camera look upward away from the scene.
     - Inspector: Transform > Position = Y: **10** (puts the camera above the scene; the exact value doesn't matter for orthographic rendering, but it must be high enough that the scene is between the near and far clip planes)
     - Attach script: `res://scripts/camera/camera_follow.gd`
     - **Verify in editor:** Click the "Preview" checkbox on the Camera3D node. You should see the GridMap tiles from above at an angle. If you see grey, the rotation is wrong.

     **Player:**
     - Instance `scenes/player/player.tscn` as child of TestRoom
     - Inspector: Transform > Position = (0, 1, 0) — Y=1 places the player on top of the floor tiles

     **DefaultSpawn:**
     - Add child > Marker3D, rename to "DefaultSpawn"
     - Position at the player's start location (same as Player position)

  3. Save as `scenes/world/test_room.tscn`

- [x] **Update main scene** — Project > Project Settings > General > Run > Main Scene: change to `res://scenes/world/test_room.tscn`

### Before Step 2

- [x] **Install Dialogue Manager** — Vendored copy into `addons/dialogue_manager/`. Enabled in editor.

- [x] **NPC scene** (`scenes/interactables/npc.tscn`):
  1. Scene > New Scene > Other Node > **StaticBody3D** (rename to "NPC")
  2. Inspector > Collision:
     - **Layer** = 3 (npcs) — only bit 3 enabled. This is what the player's InteractionArea scans for (mask bit 3) and what the player's CharacterBody3D collides with (mask bit 3).
     - **Mask** = none (all bits off) — NPCs don't need to detect or collide with anything themselves.
  3. Add children:
     - **CollisionShape3D** — Shape: New CapsuleShape3D (radius=0.3, height=1.8). Inspector > Transform > Position Y = **0.9** (same offset as player — places bottom at floor level).
     - **MeshInstance3D** — Mesh: New CapsuleMesh (radius=0.3, height=1.8). Inspector > Transform > Position Y = **0.9**. Give it a visually distinct material: Inspector > Mesh > expand > Material > New StandardMaterial3D > Albedo > Color = blue or another color that contrasts with the player.
  4. Select root "NPC" node > attach script `res://scripts/interactables/npc_interactable.gd`
  5. Inspector (script exports): set `npc_id` = "nathan", `dialogue_title` = "start". Leave `dialogue_resource` empty for now (assigned after the agent creates the `.dialogue` file).
  6. Save as `scenes/interactables/npc.tscn`

- [x] **Interaction prompt scene** (`scenes/ui/interaction_prompt.tscn`):
  1. Scene > New Scene > Other Node > **CanvasLayer** (rename to "InteractionPrompt")
  2. Add children:
     - **PanelContainer** — Anchors: bottom-center. Custom minimum size: 200×40.
       - **Label** — Text: "Press E". Horizontal alignment: Center.
  3. Attach `res://scripts/ui/interaction_prompt.gd` to root
  4. Set `visible = false` in inspector (hidden by default)
  5. Save as `scenes/ui/interaction_prompt.tscn`

- [x] **Dialogue balloon scene** (`scenes/ui/dialogue_balloon.tscn`):
  1. Check if Dialogue Manager ships an example balloon: look in `addons/dialogue_manager/example_balloon/`. If it does, **duplicate it** to `scenes/ui/dialogue_balloon.tscn` and customize. If not:
  2. Create: CanvasLayer > MarginContainer (anchors: full rect, bottom half) > VBoxContainer:
     - **RichTextLabel** (rename to "DialogueLabel") — BBCode enabled, fit content height, size flags: expand + fill
     - **VBoxContainer** (rename to "ResponsesContainer") — For dialogue choice buttons (populated at runtime by script)
  3. Attach `res://scripts/ui/dialogue_balloon.gd` to root
  4. Save as `scenes/ui/dialogue_balloon.tscn`

- [x] **Place NPC in test room** — Open `test_room.tscn`:
  1. Instance `scenes/interactables/npc.tscn` as child of TestRoom
  2. Position the NPC a few tiles away from the player spawn (e.g., X=4, Z=0)
  3. In inspector: assign the dialogue resource once agent creates it (`resources/dialogue/npc_greeting.dialogue`)
  4. Save test_room.tscn

- [x] **InteractionPrompt** — Now instanced by HUD autoload (not in test room). Remove from test_room.tscn if still present.

### Before Step 3

- [x] **Chest scene** (`scenes/interactables/chest.tscn`):
  1. Scene > New Scene > Other Node > **StaticBody3D** (rename to "Chest")
  2. Inspector: Collision Layer = 4 (interactables), Mask = none
  3. Add children:
     - **CollisionShape3D** — Shape: New BoxShape3D (size: 0.8×0.8×0.8)
     - **MeshInstance3D** — Mesh: New BoxMesh (same dimensions). Material: brown/wood color.
  4. Attach `res://scripts/interactables/chest_interactable.gd` to root
  5. Set exports: Item = key_item.tres, Chest Id = "chest_amulet". Add to "saveable" group.
  6. Save as `scenes/interactables/chest.tscn`

- [x] **Item toast scene** (`scenes/ui/item_toast.tscn`):
  1. Scene > New Scene > Other Node > **CanvasLayer** (rename to "ItemToast", Layer = 10)
  2. Add children:
     - **PanelContainer** — Anchors: center-bottom. Custom minimum size: 300×40.
       - **Label** — Text: "Acquired: Item". Horizontal alignment: Center.
  3. Attach `res://scripts/ui/item_toast.gd` to root
  4. Save as `scenes/ui/item_toast.tscn`

- [x] **Place chest in test room** — Open `test_room.tscn`:
  1. Instance `scenes/interactables/chest.tscn` as child of TestRoom
  2. Position in room reachable by player, not overlapping NPC
  3. Exports pre-configured from chest scene (Item = key_item.tres, Chest Id = "chest_amulet")
  4. Save test_room.tscn

- [x] **ItemToast** — Now instanced by HUD autoload (not in test room). Remove from test_room.tscn if still present.

### Before Step 4

- [x] **Quest indicator scene** (`scenes/ui/quest_indicator.tscn`):
  1. Scene > New Scene > Other Node > **CanvasLayer** (rename to "QuestIndicator", Layer = 10)
  2. Add children:
     - **PanelContainer** — Anchors: top-right. Custom minimum size: 250×60.
       - **VBoxContainer**:
         - **Label** (rename to "QuestNameLabel") — Text: "Quest Name"
         - **Label** (rename to "StepLabel") — Smaller font, text: "Current step..."
  3. Attach `res://scripts/ui/quest_indicator.gd` to root
  4. Save as `scenes/ui/quest_indicator.tscn`

- [x] **Add QuestTracker to player** — Open `scenes/player/player.tscn`:
  1. Add child **Node** to Player root (rename to "QuestTracker")
  2. Attach `res://scripts/quest/quest_tracker.gd`
  3. Save player.tscn

- [x] **QuestIndicator** — Now instanced by HUD autoload (not in test room). Remove from test_room.tscn if still present.
- [x] **Set NPC quest_resource** — Select NPC instance in test_room.tscn, Inspector > Quest Resource > Load `res://resources/quests/fetch_quest.tres`.

### Before Step 5

- [x] **SceneManager autoload** — No editor scene needed. Registered as `.gd` autoload in `project.godot`. Builds CanvasLayer + ColorRect fade overlay programmatically in `_ready()`. This avoids the known Godot issue where `.tscn` autoloads lose type info ([godot#86300](https://github.com/godotengine/godot/issues/86300)).

- [ ] **Second room scene** (`scenes/world/test_room_2.tscn`):
  1. Duplicate test_room.tscn structure: Node3D root, GridMap, lights, WorldEnvironment, Camera3D with follow script
  2. Paint a different room layout in GridMap (L-shape, larger, different feel)
  3. Add **Marker3D** nodes: "spawn_from_room_1" (near the door from room 1)
  4. Do NOT instance the Player — SceneManager handles the persistent player
  5. Save as `scenes/world/test_room_2.tscn`

- [ ] **Door scenes in both rooms:**
  1. Create `scenes/interactables/door.tscn`: StaticBody3D (layer 4), BoxShape3D collision (archway shape), MeshInstance3D (tall thin box or archway). Attach `res://scripts/interactables/door_interactable.gd`. Save.
  2. Open `test_room.tscn`:
     - Instance door scene, position near room edge
     - Inspector: `target_scene_path` = `res://scenes/world/test_room_2.tscn`, `target_spawn_point` = "spawn_from_room_1", `door_id` = "room1_to_room2"
     - Add **Marker3D** named "spawn_from_room_2" near this door
  3. Open `test_room_2.tscn`:
     - Instance door scene, position near room edge
     - Inspector: `target_scene_path` = `res://scenes/world/test_room.tscn`, `target_spawn_point` = "spawn_from_room_2", `door_id` = "room2_to_room1"

- [x] **Player persistence via SceneManager** — Keep Player in test_room.tscn. SceneManager.register_player() guards against duplicates on room revisit (frees the scene-instanced copy, keeps the persistent one).

### Before Step 6

- [x] **Register SaveManager autoload** — Project > Project Settings > Autoload. Add `res://scripts/autoloads/save_manager.gd`. Autoload order: EventBus, GameState, DialogueManager, WorldState, SceneManager, SaveManager, HUD.

- [x] **Saveable groups** — Groups are assigned in code via `_ready()`, not in the editor. `"saveable"` group: Player, Inventory, QuestTracker, WorldState (for disk persistence). `"interactable_saveable"` group: chests (for WorldState session state). See CLAUDE.md for contract details.

### Before Step 8

- [ ] **Pause menu scene** (`scenes/ui/pause_menu.tscn`):
  1. Scene > New Scene > Other Node > **CanvasLayer** (rename to "PauseMenu", layer = 99)
  2. Add children:
     - **ColorRect** — Anchors: full rect. Color: black with ~50% alpha (dim background).
     - **CenterContainer** — Anchors: full rect.
       - **VBoxContainer** — Custom minimum size: 200×300.
         - **Button** (rename to "ResumeButton") — Text: "Resume"
         - **Button** (rename to "SaveButton") — Text: "Save"
         - **Button** (rename to "LoadButton") — Text: "Load"
         - **Button** (rename to "QuitButton") — Text: "Quit"
  3. Attach `res://scripts/ui/pause_menu.gd` to root
  4. Set `visible = false` (hidden until Tab/Start pressed)
  5. Save as `scenes/ui/pause_menu.tscn`

## Risk Analysis & Mitigation

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Dialogue Manager incompatible with Godot 4.6 | Low | High | Test immediately after install (Step 2 prereq). Fallback: raw Label + input for prototype. |
| GridMap performance with collision | Low | Medium | Keep test rooms under 50x50 tiles. Performance ceiling is ~3K tiles per chunk (from research). |
| MeshLibrary creation complexity | Medium | Medium | Start with primitive BoxMesh tiles. Swap for Kenney assets once workflow is proven. |
| Scene transition state loss | Low | Medium | Persistent player pattern eliminates save/restore dance. Player node survives scene changes naturally. |
| Quest system too simple for future needs | Low | Low | Dialogue files handle all condition logic. QuestTracker is a pure state machine. Add programmatic conditions when dialogue can't handle a use case. |
| Save format migration on schema changes | Medium | Medium | Version field in save data. `Dictionary.merge()` with defaults for backward compatibility. Sequential patch chains if needed. |
| Scope creep during implementation | High | Medium | Each step has explicit acceptance criteria. Mark complete when criteria met, not when "polished." |

## Future Considerations

These are explicitly **not in scope** but influence current decisions:

- **Combat system** — Core mechanic TBD. The two-layer architecture (Resource data + Node behavior) will support combat Resources (MonsterData, MoveData) when the time comes. The StateMachine class is generic enough for battle states.
- **Sprite3D character migration** — Swap MeshInstance3D for Sprite3D under the same CharacterBody3D. All gameplay code is visual-agnostic. No refactoring needed.
- **NPC movement** — When NPCs need to move, promote from StaticBody3D to CharacterBody3D. The `interact()` interface is unchanged.
- **Audio** — Hook into existing signals (item_added, quest_completed, scene_change_started) to play sound effects. Signal architecture supports this with zero system changes.
- **Accessibility** — Dialogue UI text size, interaction prompt visibility, and input remapping are future concerns. Foundation decisions (CanvasLayer UI, input action names) support these additions.
- **Modding** — String IDs and Resource-based data layer align with Cassette Beasts' proven modding approach. No special modding infrastructure needed now.
- **Localization** — Dialogue Manager supports translation keys. Can adopt `tr()` calls and CSV translation files when needed.

## Documentation Plan

- [ ] Update CLAUDE.md if any new conventions emerge (e.g., "saveable" group pattern)
- [ ] Add architecture diagram to `docs/` after Phase 2 (when the playable loop works)
- [ ] No README or external docs needed for prototype

## Sources & References

### Origin

- **Brainstorm document:** [docs/brainstorms/2026-03-19-rpg-skeleton-systems-brainstorm.md](docs/brainstorms/2026-03-19-rpg-skeleton-systems-brainstorm.md) — Key decisions carried forward: 3D orthographic rendering, two-layer Resource/Node architecture, 8-step build order with autoloads triggered by gameplay, Dialogue Manager over Dialogic 2.

### Internal References

- [scripts/autoloads/game_state.gd](scripts/autoloads/game_state.gd) — GameMode enum, `set_mode()`, `game_state_changed` signal
- [scripts/autoloads/event_bus.gd](scripts/autoloads/event_bus.gd) — Empty stub, populated when cross-system signals emerge
- [shared/state_machine/state_machine.gd](shared/state_machine/state_machine.gd) — Generic StateMachine, used for player states
- [shared/state_machine/state.gd](shared/state_machine/state.gd) — Base State class with `enter/exit/handle_input/update/physics_update`
- [docs/research/godot-rpg-fundamentals.md](docs/research/godot-rpg-fundamentals.md) — 100+ source research on RPG architecture, save systems, quest patterns
- [docs/research/cassette-beasts-technical-reference.md](docs/research/cassette-beasts-technical-reference.md) — Proven patterns from shipped 30-hour Godot RPG
- [docs/reference/godot-best-practices.md](docs/reference/godot-best-practices.md) — Architecture, signals, Resources, performance guidelines

### External References

- Godot CharacterBody3D docs: `move_and_slide()`, velocity-based movement, collision layers
- Dialogue Manager (Nathan Hoad): `show_dialogue_balloon()`, `extra_game_states` for condition resolution, `if/set/do` syntax in `.dialogue` files
- Kenney.nl CC0 asset kits: Fantasy Town, Castle, Nature, Furniture
- KayKit/Quaternius: rigged/animated character models (CC0)
