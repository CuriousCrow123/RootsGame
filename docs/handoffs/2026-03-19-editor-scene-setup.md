# Handoff: Editor Scene Setup (2026-03-19)

## Overview

Phase 1 editor setup for the RPG Playable Loop Foundation. Agent wrote all scripts; user built all scenes in the Godot editor following instructions below. This document records the instructions given, what was actually done (including deviations), and issues encountered.

---

## Editor Instructions

> **Important:** Describe everything you do in the editor as you go, so the agent can document it accurately.

### 1. Configure Input Actions

**Project > Project Settings > Input Map**

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| `move_forward` | W | Left Stick Up |
| `move_back` | S | Left Stick Down |
| `move_left` | A | Left Stick Left |
| `move_right` | D | Left Stick Right |
| `interact` | E | South (A/Cross) |
| `cancel` | Escape | East (B/Circle) |

### 2. Configure Collision Layer Names

**Project > Project Settings > Layer Names > 3D Physics**

| Layer | Name |
|-------|------|
| 1 | environment |
| 2 | player |
| 3 | npcs |
| 4 | interactables |

### 3. Enable Dialogue Manager Plugin

**Project > Project Settings > Plugins > Dialogue Manager > Enable**

### 4. Build Player Scene (`scenes/player/player.tscn`)

1. New Scene > **CharacterBody3D** (rename to "Player")
2. Set Collision Layer = 2 (player), Mask = 1 (environment)
3. Add children:
   - **CollisionShape3D** — CapsuleShape3D (radius=0.3, height=1.8), **Position Y=0.9**
   - **MeshInstance3D** — CapsuleMesh (radius=0.3, height=1.8), **Position Y=0.9**
   - **Area3D** (rename "InteractionArea") — Layer = none, Mask = 3 + 4
     - Child **CollisionShape3D** — SphereShape3D (radius=2.0)
   - **Node** (rename "StateMachine") — attach `res://shared/state_machine/state_machine.gd`
     - **Node** (rename "Idle") — attach `res://scripts/player/player_states/player_idle.gd`
     - **Node** (rename "Walk") — attach `res://scripts/player/player_states/player_walk.gd`
     - **Node** (rename "Interact") — attach `res://scripts/player/player_states/player_interact.gd`
   - **Node** (rename "Inventory") — attach `res://scripts/inventory/inventory.gd`
4. Select StateMachine node > Inspector: set `initial_state` = drag the **Idle** node into the slot
5. Select root "Player" node > attach `res://scripts/player/player_controller.gd`
6. Save as `scenes/player/player.tscn`

> **Why Y=0.9?** A CapsuleShape3D with height 1.8 centered at Y=0 extends from Y=-0.9 to Y=0.9, burying half underground. Setting both CollisionShape3D and MeshInstance3D to Position Y=0.9 places the capsule bottom at ground level (Y=0).

### 5. Build Test Room (`scenes/world/test_room.tscn`)

1. New Scene > **Node3D** (rename "TestRoom")
2. Add children:
   - **GridMap** — create a MeshLibrary with Floor and Wall tiles:
     - Create a new scene with root **Node3D**, add **MeshInstance3D** children for Floor (PlaneMesh) and Wall (BoxMesh)
     - Scene > Convert To > MeshLibrary, save to `resources/mesh_library.tres`
     - Paint floor tiles on level 0, wall tiles on **level 1** (see Issues below)
   - **DirectionalLight3D** — Rotation X=-45°, Y=30°, shadows enabled
   - **WorldEnvironment** — new Environment resource, Ambient Light source=Color, color=#404040, energy=0.5
   - **Camera3D** (rename "RoomCamera"):
     - Projection = Orthographic, Size = 10, Near = 0.05, Far = 100
     - Rotation X = -30°, Y = 45°
     - Position Y ≈ 15
     - **Current = true** (required — without this you get a grey screen)
     - Attach `res://scripts/camera/camera_follow.gd`
   - Instance **Player** scene (`scenes/player/player.tscn`) at room center
   - **Marker3D** (rename "DefaultSpawn") at player start position
3. Save as `scenes/world/test_room.tscn`

### 6. Build NPC Scene (`scenes/interactables/npc.tscn`)

1. New Scene > **StaticBody3D** (rename "NPC")
2. Set Collision Layer = 3 (npcs), Mask = none
3. Add children:
   - **CollisionShape3D** — CapsuleShape3D (radius=0.3, height=1.8), Position Y=0.9
   - **MeshInstance3D** — CapsuleMesh (same dims), Position Y=0.9, apply a different material color than the player
4. Attach `res://scripts/interactables/npc_interactable.gd` to root
5. Inspector: set `npc_id` = "nathan", `dialogue_title` = "start"
6. Save as `scenes/interactables/npc.tscn`

### 7. Build Interaction Prompt (`scenes/ui/interaction_prompt.tscn`)

1. New Scene > **CanvasLayer** (rename "InteractionPrompt")
2. Add **PanelContainer** (anchors bottom-center, Custom Minimum Size 200×40)
   - Add child **Label** (text "Press E", centered)
3. Attach `res://scripts/ui/interaction_prompt.gd` to root
4. Set root `visible = false`
5. Save as `scenes/ui/interaction_prompt.tscn`

### 8. Set Up Dialogue Balloon

Duplicate `addons/dialogue_manager/example_balloon/example_balloon.tscn` to `scenes/ui/dialogue_balloon.tscn`. The example script works out of the box — no modifications needed.

### 9. Wire Up Test Room

- Instance NPC in test_room (position a few tiles from player, e.g., X=4)
- In NPC instance Inspector: assign dialogue resource = `res://resources/dialogue/npc_greeting.dialogue`
- Instance InteractionPrompt as child of TestRoom

### 10. Update Main Scene

**Project Settings > Run > Main Scene** = `res://scenes/world/test_room.tscn`

---

## What Was Actually Done

All 10 steps completed. Deviations and specifics recorded below.

### Project Settings

- Input actions configured: WASD + E + Escape (keyboard only — no gamepad bindings added yet)
- Collision layer names set for layers 1–4
- Dialogue Manager plugin enabled
- Main scene set to `res://scenes/world/test_room.tscn`

### Player Scene

- Built as instructed
- Both CollisionShape3D and MeshInstance3D set to Position Y=0.9
- Custom StandardMaterial3D color applied to MeshInstance3D
- StateMachine `initial_state` set to Idle node via Inspector drag

### Test Room

- Root: **Node3D** renamed "TestRoom"
- **GridMap** with MeshLibrary saved to `resources/mesh_library.tres`
  - Walls painted on floor level 1 (one layer up) to avoid centering/clipping — Godot's BoxMesh has origin at center, no offset possible without Blender
  - MeshLibrary source scene: changed root to plain Node3D, put both Floor and Wall as children (converter only picks up children, not the root)
- **DirectionalLight3D** — Rotation X=-45, Y=30, shadows enabled
- **WorldEnvironment** — Environment with Ambient Light source=Color, color=#404040, energy=0.5
- **Camera3D** "RoomCamera" — Orthogonal, Size=10, Near=0.05, Far=100, Rotation X=-30 Y=45, Position Y≈15, Current=true
- **Player** instanced at origin
- **Marker3D** "DefaultSpawn" at player start
- **NPC** instanced with dialogue resource assigned
- **InteractionPrompt** instanced as child

### NPC Scene

- Built as instructed
- Different material color than player applied
- `npc_id` = "nathan", `dialogue_title` = "start"

### Interaction Prompt

- Built as instructed
- Root visible = false

### Dialogue Balloon

- Duplicated from example balloon
- Script still points to `res://addons/dialogue_manager/example_balloon/example_balloon.gd`

---

## Issues Encountered and Resolved

### StateMachine `initial_state` not visible in Inspector

- **Cause:** `state_machine.gd` had a parse error — strict typing flagged `child.state_finished.connect()` because `child` was typed as `Node`, and GDScript doesn't narrow types after `is` checks.
- **Fix:** Added explicit cast: `var state: State = child as State` before accessing `.state_finished`. This pattern was added as a convention in CLAUDE.md.

### GridMap wall tiles clipping into floor

- **Cause:** Godot's BoxMesh has its origin at geometric center. GridMap centers items on the cell origin. The MeshLibrary converter does NOT bake parent Node3D transforms.
- **Workaround:** Painted walls on GridMap floor level 1 instead of level 0. Proper fix requires authoring meshes in Blender with origin at bottom edge.

### MeshLibrary missing Floor tile

- **Cause:** The converter only picks up children of the root node, not the root itself. Floor was initially the root MeshInstance3D.
- **Fix:** Changed root to plain Node3D, put both Floor and Wall as children, re-exported.

### Grey screen — nothing visible at runtime

- **Cause:** Camera3D did not have `Current = true` set. Without it, Godot uses no camera and renders nothing.
- **Fix:** Set `Current = true` on RoomCamera in Inspector.

### PlayerController class failed to load (strict typing)

- **Cause:** Three strict typing violations prevented `player_controller.gd` from parsing:
  1. `_nearest_interactable.interact(self)` — `interact()` not known on `Node3D` type
  2. `Dictionary.get()` returns `Variant`, not `float`, so `Vector3(pos.get(...))` failed
  3. `inventory.gd` had same `Variant` issue with `_items.assign()`
- **Effect:** Since PlayerController class never loaded, `as PlayerController` always returned `null` in state scripts, causing cascading `Nil` errors.
- **Fix:** Used `.call("interact", self)` for duck-typed method, `@warning_ignore("unsafe_call_argument")` for deserialization lines, replaced `owner` with `get_parent().get_parent()` in state scripts.

### Unused signal warnings (non-blocking)

- **Symptoms:** Warnings for `quest_started`, `quest_step_completed`, `quest_completed` in `quest_tracker.gd` and `state_finished` in `state.gd`.
- **Cause:** These signals are stubs for Phase 2 / consumed externally by StateMachine, not within the declaring class.
- **Fix:** Added `@warning_ignore("unused_signal")` annotations above each declaration.
