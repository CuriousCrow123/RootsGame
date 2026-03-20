# Handoff: Editor Scene Setup (2026-03-19)

## Overview

Phase 1 editor setup for the RPG Playable Loop Foundation. Agent wrote all scripts; user built all scenes in the Godot editor following instructions below.

## Instructions Given (Agent → User)

### 1. Configure Input Actions (Project > Project Settings > Input Map)

| Action | Keyboard | Gamepad |
|--------|----------|---------|
| `move_forward` | W | Left Stick Up |
| `move_back` | S | Left Stick Down |
| `move_left` | A | Left Stick Left |
| `move_right` | D | Left Stick Right |
| `interact` | E | South (A/Cross) |
| `cancel` | Escape | East (B/Circle) |

### 2. Configure Collision Layer Names (Project > Project Settings > Layer Names > 3D Physics)

| Layer | Name |
|-------|------|
| 1 | environment |
| 2 | player |
| 3 | npcs |
| 4 | interactables |

### 3. Enable Dialogue Manager Plugin

Project > Project Settings > Plugins > Dialogue Manager > Enable

### 4. Build Player Scene (`scenes/player/player.tscn`)

1. New Scene > **CharacterBody3D** (rename to "Player")
2. Collision Layer = 2 (player), Mask = 1 (environment)
3. Add children:
   - **CollisionShape3D** — CapsuleShape3D (radius=0.3, height=1.8). Position Y=0.9
   - **MeshInstance3D** — CapsuleMesh (same dims). Position Y=0.9
   - **Area3D** (rename "InteractionArea") — Layer = none, Mask = 3 + 4. Add child CollisionShape3D with SphereShape3D (radius=2.0)
   - **Node** (rename "StateMachine") — attach `res://shared/state_machine/state_machine.gd`
     - **Node** (rename "Idle") — attach `res://scripts/player/player_states/player_idle.gd`
     - **Node** (rename "Walk") — attach `res://scripts/player/player_states/player_walk.gd`
     - **Node** (rename "Interact") — attach `res://scripts/player/player_states/player_interact.gd`
   - **Node** (rename "Inventory") — attach `res://scripts/inventory/inventory.gd`
4. Select StateMachine > Inspector: `initial_state` = drag **Idle** node
5. Select root "Player" > attach `res://scripts/player/player_controller.gd`
6. Save as `scenes/player/player.tscn`

**Clarification during setup:** Both CollisionShape3D and MeshInstance3D need Position Y=0.9 — a CapsuleShape3D with height 1.8 centered at Y=0 extends from Y=-0.9 to Y=0.9, burying half the capsule underground. Raising both to Y=0.9 puts the bottom at ground level (Y=0).

### 5. Build Test Room (`scenes/world/test_room.tscn`)

1. New Scene > **Node3D** (rename "TestRoom")
2. Add children:
   - **GridMap** — assign a MeshLibrary (create one with Floor + Wall tiles, or use primitives)
   - **DirectionalLight3D** — Rotation X=-45°, Y=30°, shadows on
   - **WorldEnvironment** — ambient light color #404040, energy 0.5
   - **Camera3D** (rename "RoomCamera") — Projection=Orthographic, Size=10, Near=0.05, Far=100. Rotation X=-30°, Y=45°. Position Y~15. Attach `res://scripts/camera/camera_follow.gd`
   - Instance **Player** scene (`scenes/player/player.tscn`) at room center
   - **Marker3D** (rename "DefaultSpawn") at player start
3. Save as `scenes/world/test_room.tscn`

### 6. Build NPC Scene (`scenes/interactables/npc.tscn`)

1. New Scene > **StaticBody3D** (rename "NPC")
2. Collision Layer = 3 (npcs), Mask = none
3. Add: CollisionShape3D (CapsuleShape3D), MeshInstance3D (CapsuleMesh, different color from player, Y=0.9)
4. Attach `res://scripts/interactables/npc_interactable.gd`
5. Inspector: `npc_id` = "nathan", `dialogue_title` = "start"
6. Save as `scenes/interactables/npc.tscn`

### 7. Build Interaction Prompt (`scenes/ui/interaction_prompt.tscn`)

1. New Scene > **CanvasLayer** (rename "InteractionPrompt")
2. Add **PanelContainer** (anchors bottom-center, min size 200×40) > **Label** (text "Press E", centered)
3. Attach `res://scripts/ui/interaction_prompt.gd`
4. Set `visible = false`
5. Save as `scenes/ui/interaction_prompt.tscn`

### 8. Set Up Dialogue Balloon

Duplicate `addons/dialogue_manager/example_balloon/example_balloon.tscn` to `scenes/ui/dialogue_balloon.tscn`. The example script works out of the box.

### 9. Wire Up Test Room

- Instance NPC in test_room (position a few tiles from player, e.g., X=4)
- Assign dialogue resource: `res://resources/dialogue/npc_greeting.dialogue`
- Instance InteractionPrompt as child of TestRoom

### 10. Update Main Scene

Project Settings > Run > Main Scene = `res://scenes/world/test_room.tscn`

## What Was Actually Done

All 10 steps completed. Specific details and deviations recorded below.

### Player Scene (`scenes/player/player.tscn`)

- Root: **CharacterBody3D** renamed "Player"
- Collision Layer = 2 (player), Mask = 1 (environment)
- **CollisionShape3D** — CapsuleShape3D (radius=0.3, height=1.8), Position Y=0.9
- **MeshInstance3D** — CapsuleMesh (same dims), Position Y=0.9, custom StandardMaterial3D color applied
- **Area3D** "InteractionArea" — Layer = none, Mask = 3 + 4
  - Child CollisionShape3D with SphereShape3D (radius=2.0)
- **Node** "StateMachine" — `res://shared/state_machine/state_machine.gd` attached
  - Initial State = Idle node (assigned via Inspector)
  - Children: Idle, Walk, Interact (Node type, scripts attached from `scripts/player/player_states/`)
- **Node** "Inventory" — `res://scripts/inventory/inventory.gd` attached
- Root script: `res://scripts/player/player_controller.gd`

### NPC Scene (`scenes/interactables/npc.tscn`)

- Root: **StaticBody3D** renamed "NPC"
- Collision Layer = 3 (npcs), Mask = none
- **CollisionShape3D** — CapsuleShape3D (radius=0.3, height=1.8), Position Y=0.9
- **MeshInstance3D** — CapsuleMesh (same dims), Position Y=0.9, different material color than player
- Root script: `res://scripts/interactables/npc_interactable.gd`
- Inspector: `npc_id` = "nathan", `dialogue_title` = "start"

### Interaction Prompt (`scenes/ui/interaction_prompt.tscn`)

- Root: **CanvasLayer** renamed "InteractionPrompt"
- **PanelContainer** (anchors bottom-center, Custom Minimum Size 200×40)
  - **Label** (text "Press E", centered)
- Script: `res://scripts/ui/interaction_prompt.gd`
- Visible = false on root

### Dialogue Balloon

- Duplicated from `addons/dialogue_manager/example_balloon/example_balloon.tscn`
- Script remains pointing at `res://addons/dialogue_manager/example_balloon/example_balloon.gd`

### Test Room

- Root: **Node3D** renamed "TestRoom"
- **GridMap** — MeshLibrary with Floor and Wall tiles (created from primitives via Scene > Convert To > MeshLibrary, saved to `resources/mesh_library.tres`)
  - Walls painted on floor level 1 (one layer up) to avoid centering/clipping issue — Godot's built-in BoxMesh has origin at center, no way to offset without Blender
  - MeshLibrary source scene: root changed to plain Node3D, put both Floor and Wall as children (converter only picks up children, not root)
- **DirectionalLight3D** — Rotation X=-45, Y=30, shadows enabled
- **WorldEnvironment** — New Environment, Ambient Light source=Color, color=#404040, energy=0.5
- **Camera3D** "RoomCamera" — Projection=Orthogonal, Size=10, Near=0.05, Far=100, Rotation X=-30 Y=45, Position Y~15, script: `res://scripts/camera/camera_follow.gd`
- **Player** instanced from `scenes/player/player.tscn` at origin
- **Marker3D** "DefaultSpawn" at player start position
- **NPC** instanced, dialogue resource assigned (`res://resources/dialogue/npc_greeting.dialogue`)
- **InteractionPrompt** instanced as child

### Project Settings

- Input actions configured (WASD + E + Escape, keyboard only — no gamepad bindings added yet)
- Collision layer names set
- Dialogue Manager plugin enabled
- Main scene set to `res://scenes/world/test_room.tscn`

## Issues Encountered and Resolved

### StateMachine `initial_state` not visible in Inspector

- **Cause:** `state_machine.gd` had a parse error — strict typing flagged `child.state_finished.connect()` because `child` was typed as `Node`, and GDScript doesn't narrow types after `is` checks.
- **Fix:** Added explicit cast: `var state: State = child as State` before accessing `.state_finished`. This was added as a convention in CLAUDE.md: "Explicit casts after `is` checks."

### GridMap wall tiles clipping into floor

- **Cause:** Godot's BoxMesh has its origin at geometric center. GridMap centers items on the cell origin. The MeshLibrary converter does NOT bake parent Node3D transforms (known Godot limitation).
- **Workaround:** Painted walls on GridMap floor level 1 instead of level 0. Proper fix requires authoring meshes in Blender with origin at bottom edge.

### MeshLibrary missing Floor tile

- **Cause:** The converter only picks up children of the root node, not the root itself. Floor was initially the root MeshInstance3D.
- **Fix:** Changed root to plain Node3D, put both Floor and Wall as children, re-exported.
