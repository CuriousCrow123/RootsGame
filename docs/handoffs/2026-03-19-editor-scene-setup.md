# Handoff: Editor Scene Setup (2026-03-19)

## What was done

Manually built core scenes in the Godot 4 editor following the implementation plan.

## Scenes created

### Player (`scenes/player/player.tscn`)
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

### Interaction Prompt (`scenes/ui/interaction_prompt.tscn`)
- Root: **CanvasLayer** renamed "InteractionPrompt"
- **PanelContainer** (anchors bottom-center, Custom Minimum Size 200x40)
  - **Label** (text "Press E", centered)
- Script: `res://scripts/ui/interaction_prompt.gd`
- Visible = false on root

### Dialogue Balloon (`scenes/ui/dialogue_balloon.tscn`)
- Duplicated from `addons/dialogue_manager/example_balloon/example_balloon.tscn`
- Script remains pointing at `res://addons/dialogue_manager/example_balloon/example_balloon.gd` (works out of the box)

### Test Room (`scenes/world/test_room.tscn`)
- Root: **Node3D** renamed "TestRoom"
- **GridMap** — MeshLibrary with Floor and Wall tiles (created from primitives via Scene > Convert To > MeshLibrary, saved to `resources/mesh_library.tres`)
  - Walls painted on floor level 1 (one layer up) to avoid centering/clipping issue — Godot's built-in BoxMesh has origin at center, no way to offset without Blender
- **DirectionalLight3D** — Rotation X=-45, Y=30, shadows enabled
- **WorldEnvironment** — New Environment, Ambient Light source=Color, color=#404040, energy=0.5
- **Camera3D** "RoomCamera" — Projection=Orthogonal, Size=10, Near=0.05, Far=100, Rotation X=-30 Y=45, Position Y~15, script: `res://scripts/camera/camera_follow.gd`
- **Player** instanced from `scenes/player/player.tscn` at origin
- **Marker3D** "DefaultSpawn" at player start position

## Issues encountered and resolved

### StateMachine `initial_state` not visible in Inspector
- **Cause:** `state_machine.gd` had a parse error — strict typing flagged `child.state_finished.connect()` because `child` was typed as `Node`, and GDScript doesn't narrow types after `is` checks.
- **Fix:** Added explicit cast: `var state: State = child as State` before accessing `.state_finished`. This was added as a rule in CLAUDE.md.

### GridMap wall tiles clipping into floor
- **Cause:** Godot's BoxMesh has its origin at geometric center. GridMap centers items on the cell origin. The MeshLibrary converter does NOT bake parent Node3D transforms (known Godot limitation).
- **Workaround:** Painted walls on GridMap floor level 1 instead of level 0. Proper fix requires authoring meshes in Blender with origin at bottom edge.

### MeshLibrary missing Floor tile
- **Cause:** The converter only picks up children of the root node, not the root itself. Floor was initially the root MeshInstance3D.
- **Fix:** Changed root to plain Node3D, put both Floor and Wall as children, re-exported.

## Still TODO
- Instance NPC in test_room and assign dialogue resource (`res://resources/dialogue/npc_greeting.dialogue`)
- Instance InteractionPrompt as child of test_room
- Verify NPC scene exists and has exported `dialogue_resource` property
- Create `npc_greeting.dialogue` file if it doesn't exist
