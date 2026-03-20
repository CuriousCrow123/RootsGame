# Handoff: Phase 3 Editor Scene Setup (2026-03-20)

## Overview

Phase 3 editor setup for the RPG Playable Loop Foundation. Agent wrote all scripts (SceneManager, SaveManager, DoorInteractable) and tests. User needs to build scenes in the Godot editor following instructions below.

**Scripts already committed:** `scene_manager.gd`, `save_manager.gd`, `door_interactable.gd`, plus modifications to `player_controller.gd`, `chest_interactable.gd`, and `project.godot`.

---

## Editor Instructions

### 1. SceneManager — No Editor Setup Needed

SceneManager is registered as a `.gd` autoload (not `.tscn`). It builds its CanvasLayer + ColorRect fade overlay programmatically in `_ready()`. This avoids the known Godot issue where `.tscn` autoloads lose type information, causing `unsafe_method_access` warnings with strict typing.

**Verification:** Run the game. No errors in Output panel. The game behaves as before.

### 2. Build Door Scene (`scenes/interactables/door.tscn`)

1. New Scene > **StaticBody3D** (rename "Door")
2. Set Collision Layer = 4 (interactables), Mask = none
3. Add children:
   - **CollisionShape3D** — BoxShape3D (size roughly 1.0 x 2.0 x 0.3 for a doorway shape), Position Y=1.0
   - **MeshInstance3D** — BoxMesh (same approximate size), Position Y=1.0
     - Apply a distinct material color (e.g., brown or dark grey) to distinguish from walls
4. Attach `res://scripts/interactables/door_interactable.gd` to root
5. Save as `scenes/interactables/door.tscn`

> **Note:** The door's exports (`target_scene_path`, `target_spawn_point`, `door_id`) are set per-instance in each room, not on the prefab.

### 3. Build Second Room (`scenes/world/test_room_2.tscn`)

1. New Scene > **Node3D** (rename "TestRoom2")
2. Add children (same pattern as test_room.tscn):
   - **GridMap** — use the same `resources/mesh_library.tres`
     - Paint a visually distinct layout (different shape/size than Room 1 so you can tell them apart)
     - Floor tiles on level 0, wall tiles on level 1 (same as Room 1)
   - **DirectionalLight3D** — same settings as Room 1 (Rotation X=-45, Y=30, shadows)
   - **WorldEnvironment** — same Environment resource or a slightly different ambient color to distinguish rooms
   - **Camera3D** (rename "RoomCamera"):
     - Projection = Orthographic, Size = 10, Near = 0.05, Far = 100
     - Rotation X = -30° (or -45°), Y = 45°
     - Position Y ≈ 15
     - **Current = true**
     - Attach `res://scripts/camera/camera_follow.gd`
   - **Marker3D** (rename "spawn_from_room_1") — position near the door entrance, this is where the player appears when arriving from Room 1
3. Save as `scenes/world/test_room_2.tscn`

> **No Player instance in Room 2.** The player persists across scenes via SceneManager. Only Room 1 (the starting room) should have a Player instance. Room 2's camera will find the player via the `"player"` group automatically.

### 4. Add Spawn Points to Room 1 (`scenes/world/test_room.tscn`)

1. Open `scenes/world/test_room.tscn`
2. Add **Marker3D** (rename "spawn_from_room_2") — position near where the door to Room 2 will be placed. This is where the player appears when returning from Room 2.
   - The existing "DefaultSpawn" marker can stay as-is (used for initial game start)
3. Save

### 5. Place Doors in Both Rooms

**In Room 1 (`test_room.tscn`):**
1. Instance `scenes/interactables/door.tscn`
2. Position near a wall edge (the "exit" to Room 2)
3. In Inspector, set:
   - `target_scene_path` = `res://scenes/world/test_room_2.tscn` (use the file picker)
   - `target_spawn_point` = `spawn_from_room_1`
   - `door_id` = `door_room1_to_room2`

**In Room 2 (`test_room_2.tscn`):**
1. Instance `scenes/interactables/door.tscn`
2. Position near the `spawn_from_room_1` marker (so the player sees the return door immediately)
3. In Inspector, set:
   - `target_scene_path` = `res://scenes/world/test_room.tscn` (use the file picker)
   - `target_spawn_point` = `spawn_from_room_2`
   - `door_id` = `door_room2_to_room1`
4. Save both rooms

### 6. Add Chest to Room 2 (Optional)

To test save/load of chest state across rooms:

1. Instance `scenes/interactables/chest.tscn` in Room 2
2. In Inspector, set:
   - `chest_id` = `chest_room2` (must be unique across all chests)
   - `item` = assign an ItemData resource (can reuse `key_item.tres` or create a new one)
   - `item_quantity` = 1
3. Save

### 7. Verify Input Actions

The debug save/load input actions were added to `project.godot` programmatically. Verify they appear in **Project > Project Settings > Input Map**:

| Action | Key |
|--------|-----|
| `debug_save` | F5 |
| `debug_load` | F9 |

If they don't appear or the keycodes are wrong, add them manually:
- F5 physical keycode = 4194340
- F9 physical keycode = 4194344

---

## Verification Checklist

After completing all editor setup, verify each of these:

### Scene Transitions
- [ ] Run game in Room 1
- [ ] Walk near the door — interaction prompt appears
- [ ] Press E on door — screen fades to black, Room 2 loads, screen fades in
- [ ] Player appears at `spawn_from_room_1` marker position in Room 2
- [ ] Walk to return door in Room 2, press E — back to Room 1 at `spawn_from_room_2` position
- [ ] Rapidly pressing E on a door during transition does NOT cause double transition

### Player Persistence
- [ ] Pick up an item from a chest in Room 1
- [ ] Travel to Room 2 — check inventory still has the item
- [ ] Start a quest with the NPC, travel to Room 2 and back — quest state persists

### Save/Load
- [ ] Move player to a specific position, pick up items, progress quest
- [ ] Press F5 — "Game saved" appears in Output panel
- [ ] Move player elsewhere, pick up different items
- [ ] Press F9 — "Game loaded" appears; player position, inventory, and quest state restore
- [ ] Save in Room 2, close game, reopen, press F9 — Room 2 loads with correct state
- [ ] Check `user://saves/save_001.json` is human-readable JSON

### Camera
- [ ] Camera follows player in Room 2 (finds player via "player" group)
- [ ] No grey screen in Room 2 (RoomCamera has Current=true)

### Error Cases
- [ ] Press F9 with no save file — warning in Output, no crash
- [ ] No errors about SceneManager in Output

---

## What Was Actually Done

*(To be filled in by user after completing editor setup)*

---

## Issues Encountered and Resolved

*(To be filled in by user — document any deviations from instructions above)*
