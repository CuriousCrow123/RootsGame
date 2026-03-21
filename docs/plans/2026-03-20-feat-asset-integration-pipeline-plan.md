---
title: "feat: Asset Integration Pipeline"
type: feat
status: active
date: 2026-03-20
origin: docs/brainstorms/2026-03-20-asset-integration-brainstorm.md
deepened: 2026-03-20
---

# feat: Asset Integration Pipeline

## Enhancement Summary

**Deepened on:** 2026-03-20
**Agents used:** architecture, timing, gdscript, resource-safety, performance, pattern-recognition, framework-docs, code-simplicity

### Critical Bugs Caught

1. **`_sprite` null on game start.** StateMachine._ready() fires before PlayerController._ready(), so the initial `enter("Idle")` calls `play_animation()` when `_sprite` is still null. Fix: null guard in `play_animation()`.
2. **NPC `_face_toward()` would use wrong coordinate space.** World-space diff doesn't match screen-space facing under isometric rotation. Fix: deferred to a future task (simplification).
3. **Save migration math would be wrong.** Stored `rotation_y` encodes post-ISO-rotation angles; naively mapping to FacingDirection without undoing the rotation produces wrong results. Fix: dropped entirely (simplification — no users have saves worth preserving).

### Simplifications Applied

- **String-based facing** instead of enum + conversion function (~15 LOC saved)
- **No save migration** — delete old saves, use simple `.get()` with default (~15 LOC saved)
- **NPC face-toward deferred** — fixed facing direction via `@export` for now (~15 LOC saved)
- **No `has_animation()` guard** — fail fast during development; crash = fix your SpriteFrames

### Key Corrections

- `play_animation("walk")` moved from `physics_update()` to `enter()` + direction-change only (performance)
- Explicit `as AnimatedSprite3D` casts required for strict typing
- `.import` sidecar files must be committed to git
- Tile .glb/.fbx textures should use VRAM Compressed (default), NOT Lossless
- FBX imports natively in Godot 4.6 via ufbx — no external conversion to .glb needed. Vertex-colored packs (Quaternius) require "Colors" enabled in import settings.
- GridMap default cell_size is Vector3(2,2,2), not (1,1,1) — project already overrides to (1,1,1)

---

## Overview

Replace all placeholder primitives (CapsuleMesh, BoxMesh, untextured GridMap tiles) with real art assets across three sequential phases: environment tiles, character sprites, and interactable models.

The approach is tile-first (see brainstorm: biggest visual impact, simplest pipeline, validates the import workflow before tackling animation). Pre-made asset packs initially, with a path toward custom voxel authoring later.

## How This Plan Works

This is a collaborative walkthrough. Each phase has numbered steps that alternate between:

- **You (editor)** — Work you do in the Godot editor (scene changes, imports, GridMap layout)
- **Claude (code)** — Script changes I write for you
- **Together (verify)** — Checkpoints where we confirm things work before continuing

The phases are sequential. Don't start Phase 2 until Phase 1 is verified.

## Architecture Reference

**Asset directory structure** (new top-level directory):
```
assets/
  models/
    tiles/              # .glb/.fbx tile models for GridMap MeshLibrary
    interactables/      # .glb/.fbx models for chest, door
  sprites/
    characters/
      player/           # Player sprite sheet PNGs + SpriteFrames .tres
      npcs/             # NPC sprite sheets + per-archetype SpriteFrames .tres
  materials/            # Shared materials extracted from imports (if needed)
```

**Available assets:** See [temp_resources/temp-resources-asset-catalog.md](../../temp_resources/temp-resources-asset-catalog.md) for a full inventory of downloaded asset packs with specifications, format details, and per-phase compatibility ratings.

**Key technical decisions** (resolved in brainstorm + deepening research):

| Decision | Choice | Why |
|----------|--------|-----|
| Character rendering | AnimatedSprite3D | Purpose-built for frame cycling, simpler API |
| Billboard mode | `BaseMaterial3D.BILLBOARD_FIXED_Y` | Stays upright, faces camera on Y axis |
| Animation naming | `action_direction` (`walk_down`, `idle_up`) | Community standard |
| Texture filtering | Per-node `BaseMaterial3D.TEXTURE_FILTER_NEAREST` | Global setting does NOT apply to Sprite3D |
| Alpha handling | `SpriteBase3D.ALPHA_CUT_DISCARD`, threshold 0.5 | Prevents transparency sorting |
| Direction storage | String (`"down"`, `"up"`, `"left"`, `"right"`) | Serializes directly to JSON, no enum↔string conversion needed |
| Direction source | Raw input (pre-ISO-rotation) | Matches screen-space, not world-space |
| Diagonal quantization | Larger axis wins; ties prefer horizontal | RPG convention |
| Import format | .glb or .fbx (not .obj) | Both are first-class in Godot 4.6; FBX via native ufbx importer. No external conversion needed. |
| Sprite compression | Lossless (PNG sprites) | VRAM Compressed ruins pixel art |
| Tile texture compression | VRAM Compressed (default for .glb) | Standard for 3D textures |

---

## Phase 1: Environment Tiles (GridMap MeshLibrary) ✅

**Status:** Complete (2026-03-21)

**Goal:** Replace the 2 primitive BoxMesh tiles (Wall, Floor) with low-poly 3D tile models.

**Before you start:** Pick a tile asset pack (.glb or .fbx — both import natively in Godot 4.6). You'll need at minimum: floor, wall, wall-corner, wall-end. More tile types (door frame, stairs, pillar, window) are optional but make rooms more interesting. Prefer packs that use a shared texture atlas across tile types — this maximizes GridMap draw call batching.

**Available packs** (see [asset catalog](../../temp_resources/temp-resources-asset-catalog.md) for details):
- **Ruins Pack (Quaternius)** — 92 dungeon/ruins models (FBX), excellent RPG fit, includes floors, walls, arches, stairs, chests, doors. Uses vertex colors (no textures needed). 1x1 modular grid.
- **Kenney Retro Urban Kit** — 124 urban models (GLB), walls + roads + terrain. Urban/post-apocalyptic aesthetic — better for town exteriors than dungeons.

### Step 1.1 — Claude creates the directory structure

**Claude (code):** I create the `assets/models/tiles/` directory for you.

### Step 1.2 — You add tile models to the project

**You (editor):**
1. Copy your tile model files (.glb or .fbx) into `assets/models/tiles/`
2. Open the Godot editor — it will auto-import them and generate `.import` sidecar files. Godot 4.6 imports both GLB and FBX natively (FBX via the ufbx importer) — no external conversion tools needed.
3. **For vertex-colored models (e.g., Quaternius packs):** Click an imported model in the FileSystem dock, check Import settings. Verify the "Colors" option is enabled so vertex colors are preserved. These packs have no texture atlases — all color is baked per-vertex.
4. **Verify tile texture compression:** For textured models (e.g., Kenney), textures should use **VRAM Compressed** (the default). Do NOT change tile textures to Lossless — that wastes VRAM and is only needed for pixel art sprites.
5. **Scale check:** Click on one imported tile, check its bounding box. If it's not approximately 1x1x1 (matching your GridMap cell size), you have two options:
   - **Resize in Blender** and re-export (preferred — `Ctrl+A > Apply Scale` after resizing)
   - **Adjust GridMap cell_size** to match the tile dimensions
   - Do NOT try to scale via the MeshInstance3D transform in Godot — MeshLibrary export silently drops it

Tell me what tile types you imported and what scale they are. I'll help troubleshoot any issues.

### Step 1.3 — You add collision to the tiles

**You (editor):** Each tile needs collision for the player to walk on/bump into. Two approaches:

**Option A — If your .glb models were made in Blender with `-col` suffix meshes:** Collision is auto-generated on import. Check that each imported tile scene has a StaticBody3D child. If so, skip to Step 1.4.

**Option B — Add collision manually:**
1. Open `resources/mesh_library_source.tscn`
2. For each MeshInstance3D child, select it, then go to **Mesh menu > Create Trimesh Static Body** (for complex shapes) or **Create Convex Static Body** (for simple boxes)
3. This adds a StaticBody3D + CollisionShape3D as children

### Step 1.4 — You rebuild the MeshLibrary source scene

**You (editor):**
1. Open `resources/mesh_library_source.tscn`
2. The current children are "Wall" (BoxMesh 1x3x1) and "Floor" (BoxMesh 1x1x1, invisible)
3. Replace each child's mesh resource with your imported tile mesh. Or delete both and add new MeshInstance3D children — one per tile type, each using an imported mesh
4. Make sure each MeshInstance3D has a StaticBody3D + CollisionShape3D child (from Step 1.3)

**Important — append-only rule for future re-exports:** After this first export, never remove or reorder children in subsequent re-exports. To "remove" a tile later, replace its mesh with a placeholder. This prevents MeshLibrary item ID shifts that scramble GridMap layouts (Godot issue #83272). For this first build, order doesn't matter yet.

### Step 1.5 — You export the MeshLibrary

**You (editor):**
1. With `mesh_library_source.tscn` open, go to **Scene menu > Export As > MeshLibrary**
2. Overwrite `resources/mesh_library.tres`
3. Save the scene

### Step 1.6 — Together: verify the MeshLibrary export

**Together (verify):**
- Tell me you've exported. I'll diff the `.tres` file in git to verify item IDs look correct and the export worked.

### Step 1.7 — You rebuild the room layouts

**You (editor):**
1. Open `scenes/world/test_room.tscn`
2. Select the GridMap node — it should already reference `mesh_library.tres`
3. Rebuild the room layout using the new tiles in the GridMap editor. The old layout data may look scrambled since tile IDs changed — that's expected for this first rebuild
4. Repeat for `scenes/world/test_room_2.tscn`
5. Make sure spawn points (`DefaultSpawn`, `spawn_from_room_2`, etc.) are still positioned correctly relative to the new layout

### Step 1.8 — Together: playtest and commit

**Together (verify):**
1. Run the game (F5). Walk around both rooms:
   - Can the player walk on all floor tiles? (no falling through)
   - Do walls block movement? (no clipping)
   - Do the doors still work? (scene transition between rooms)
2. Quick save/load test — does the game restore correctly?
3. If everything works, tell me and I'll commit Phase 1.
4. **Delete any old save files** in `user://saves/` — Phase 2 changes the save format and we're not preserving backward compatibility.

**Phase 1 is done.**

**Deviations from plan:**
- Scale: `root_scale` in .import files did not work reliably. Instead, scale is applied via MeshInstance3D Transform in `mesh_library_source.tscn` with "Apply MeshInstance Transforms" enabled on MeshLibrary export.
- FBX mesh extraction: FBX imports as PackedScene (Node3D root), not a direct Mesh resource. To get meshes into MeshLibrary, each FBX must be dragged into the source scene, then right-click > Make Local > reparent MeshInstance3D to root.
- Wall orientation: Quaternius FBX walls import laying flat (Blender Z-up vs Godot Y-up). Fixed with -90° X rotation on the MeshInstance3D in the source scene.
- Tree (Tree_1) uses textures (Bark_Texture.jpg, Leaf_Texture.png), not vertex colors. Placed as standalone prop scene (`resources/tree_1.tscn`) via inherited scene, not in GridMap.
- Chest moved to `assets/models/interactables/` for Phase 3.
- Gravity fix required: trimesh wall collision nudges the player upward. Added `is_on_floor()` gravity check to both walk and idle states.
- 6 tiles imported instead of planned 4: Floor_Standard, Floor_Standard_Half, Floor_Squares, Floor_SquareLarge, Wall, Stairs.

---

## Phase 2: Character Sprites (AnimatedSprite3D + Animation)

**Goal:** Replace player and NPC CapsuleMesh with animated sprites. This is the most complex phase — it mixes editor work and code changes.

**Before you start:** Pick character sprite sheet packs. You need:
- 1 player sprite sheet (4-directional idle + walk, PNG)
- 2-3 NPC sprite sheets (at minimum idle in 4 directions, PNG)

Each sheet should have these animations (or the equivalent frames to create them): `idle_down`, `idle_up`, `idle_left`, `idle_right`, `walk_down`, `walk_up`, `walk_left`, `walk_right`.

**Available packs** (see [asset catalog](../../temp_resources/temp-resources-asset-catalog.md) for details):
- **RPGMCharacter v1.0** — Best 2D fit. 64x64 isometric sprites, 3 directions (flip for 4th), idle/walk/attack/pick-up animations. Single character only.
- **td_char_freepack** — 64x64 top-down, 2 characters. No license file (risky for commercial use).
- **Pixel Gnome DEMO** — Limited (idle is 1 frame, different perspective than RPGMCharacter).
- **Quaternius 3D Characters** — 50+ rigged 3D models (glTF). Would require pivoting from AnimatedSprite3D to 3D character rendering, but provides massive NPC variety.

### Step 2.1 — Claude creates directories and writes code

**Claude (code):** When you're ready with your sprite sheets, I will:
1. Create `assets/sprites/characters/player/` and `assets/sprites/characters/npcs/` directories
2. Modify `scripts/player/player_controller.gd`:
   - Add `_facing_direction: String = "down"` (private, with getter `get_facing_direction()`)
   - Add `@onready var _sprite: AnimatedSprite3D = $AnimatedSprite3D as AnimatedSprite3D`
   - Add `update_facing(input_direction: Vector2)` — uses raw input (pre-ISO-rotation) for screen-space correctness
   - Add `play_animation(action: String)` — combines action + direction to play the right animation, with null guard on `_sprite` (critical: StateMachine._ready() calls initial enter() before PlayerController._ready() resolves @onready)
   - Update `get_save_data()` to save `facing_direction` string
   - Update `load_save_data()` to read `facing_direction` with `.get("facing_direction", "down")` default
3. Modify `scripts/player/player_states/player_walk.gd`:
   - Remove `player.rotation.y = atan2(...)` line
   - In `enter()`: call `player.update_facing(raw_input)` and `player.play_animation("walk")`
   - In `physics_update()`: read raw input, compare to previous facing — if direction changed, call `update_facing()` + `play_animation("walk")` again (the walk animation loops, so it only needs restarting when the direction suffix changes, e.g., `walk_right` → `walk_down`)
4. Modify `scripts/player/player_states/player_idle.gd`:
   - Add `player.play_animation("idle")` in `enter()`
5. Modify `scripts/interactables/npc_interactable.gd`:
   - Add `@export var sprite_frames: SpriteFrames` for per-NPC variety
   - Add `@export var default_facing: String = "down"` for fixed NPC orientation
   - Add `@onready var _sprite: AnimatedSprite3D = $AnimatedSprite3D as AnimatedSprite3D`
   - In `_ready()`: assign sprite_frames and play idle in default facing direction (with null guard for unassigned sprites)

I'll show you the full diffs before applying anything.

**Key design decisions (from deepening research):**

- **String-based facing** (`"down"`, `"up"`, `"left"`, `"right"`) instead of an enum. Serializes directly to JSON, builds animation names via simple concatenation (`action + "_" + _facing_direction`), no conversion function needed.
- **Null guard on `_sprite`** in `play_animation()` is mandatory — StateMachine._ready() fires before PlayerController._ready(), so the initial Idle state's `enter()` runs when `_sprite` is still null.
- **No save migration** — old saves (with `rotation_y`) are simply incompatible. `.get("facing_direction", "down")` defaults gracefully. Delete old saves at the end of Phase 1.
- **NPC face-toward deferred** — NPCs use a fixed `@export var default_facing` for now. Dynamic face-toward-player requires ISO rotation math that is easy to get wrong; not worth the complexity for test room NPCs.
- **`as AnimatedSprite3D` cast** required on all `$NodePath` references per project strict typing settings.

### Step 2.2 — You add sprite sheets to the project

**You (editor):**
1. Copy your sprite sheet PNGs into `assets/sprites/characters/player/` and `assets/sprites/characters/npcs/`
2. For each PNG, configure the import settings in the Import dock:
   - **Filter:** Off (Nearest)
   - **Mipmaps:** Off
   - **Compress Mode:** Lossless (required for pixel art — VRAM Compressed introduces block artifacts)
3. Click "Reimport" after changing settings
4. **Commit the `.import` files** alongside the PNGs — they store your import settings. Without them, a clean clone gets default (blurry) settings.

### Step 2.3 — You create SpriteFrames resources

**You (editor):** For each character (player + each NPC archetype):
1. In the FileSystem dock, right-click the character's folder > New Resource > SpriteFrames
2. Name it descriptively (e.g., `player_frames.tres`, `villager_frames.tres`)
3. Open the SpriteFrames editor and create 8 animations:
   - `idle_down`, `idle_up`, `idle_left`, `idle_right`
   - `walk_down`, `walk_up`, `walk_left`, `walk_right`
4. For each animation, add the appropriate frames from the sprite sheet
5. Set consistent FPS across all animations (e.g., 10 FPS, matching Cassette Beasts convention)
6. Enable "Loop" on all animations

Tell me when the SpriteFrames are ready — I need to know the sprite height in pixels so I can advise on `pixel_size` calibration.

### Step 2.4 — You modify player.tscn in the editor

**You (editor):**
1. Open `scenes/player/player.tscn`
2. Select the `MeshInstance3D` child and delete it
3. Add a new `AnimatedSprite3D` child to the Player root. **Name it exactly `AnimatedSprite3D`** (the scripts reference `$AnimatedSprite3D`)
4. Configure the AnimatedSprite3D in the Inspector:
   - **Sprite Frames:** assign your `player_frames.tres`
   - **Billboard:** `BILLBOARD_FIXED_Y` (under the billboard dropdown)
   - **Texture Filter:** Nearest
   - **Alpha Cut:** Discard
   - **Alpha Scissor Threshold:** 0.5
   - **Pixel Size:** start with `1.0 / sprite_height_in_pixels` (e.g., if sprite is 32px tall, use `0.03125`). We'll tune this visually.
   - **Position Y:** start with 0.9 (same as the old MeshInstance3D). Adjust until the sprite's feet align with the ground plane.
   - **Shading:** Leave unshaded for now (default). We can try shaded later.
5. **Collision shape:** Keep the existing `CapsuleShape3D` (r=0.3, h=1.8) as-is. It's the gameplay hitbox, not the visual. Only adjust if the sprite is drastically different in size.
6. Save the scene.

### Step 2.5 — You modify npc.tscn in the editor

**You (editor):**
1. Open `scenes/interactables/npc.tscn`
2. Delete the `MeshInstance3D` child
3. Add `AnimatedSprite3D` child named exactly `AnimatedSprite3D`
4. Same settings as player (billboard, texture filter, alpha cut, pixel size)
5. **Leave Sprite Frames empty** — this gets assigned per-instance via the `@export`. The NPC won't display a sprite until you complete Step 2.6.
6. Save the scene

### Step 2.6 — You assign NPC sprite frames per instance

**You (editor):**
1. Open `scenes/world/test_room.tscn`
2. Select the NPC instance in the scene tree
3. In the Inspector, find the `Sprite Frames` export and assign the appropriate NPC SpriteFrames `.tres`
4. Set the `Default Facing` export if you want the NPC facing a direction other than down
5. Repeat for any NPCs in `test_room_2.tscn`

### Step 2.7 — Together: playtest sprite integration

**Together (verify):** Run the game and check:
1. **Player movement:** Walk in all 4 directions. Does the sprite face the correct direction? (pressing right should show the "right" sprite, etc.)
2. **Idle animation:** Stop moving. Does the sprite play idle facing the last walk direction?
3. **Visual quality:** Is the pixel art crisp? No blurriness? If blurry, double-check texture filter is set to Nearest on the AnimatedSprite3D node (global setting doesn't apply).
4. **Billboard:** Does the sprite stay upright and face the camera? It should not tilt.
5. **NPC:** Does the NPC show its sprite in the default facing direction?
6. **Dialogue:** Does the full dialogue flow still work? (NPC interaction > dialogue > back to overworld)
7. **Size/position:** Does the sprite look proportional to the environment? If too big/small, we adjust `pixel_size`. If floating or underground, we adjust Y position.

Tell me what looks right and what needs tweaking.

### Step 2.8 — Together: test save/load

**Together (verify):**
1. Walk to a specific spot facing a specific direction
2. Save the game
3. Quit and reload
4. Verify: player is at the correct position, facing the correct direction, idle animation playing

If everything works, I'll run linting and commit Phase 2.

---

## Phase 3: Interactable Models

**Goal:** Replace chest and door BoxMesh with 3D models. Add chest open animation.

**Before you start:** Pick chest and door models (.glb or .fbx). Ideally from the same pack as your tiles for visual consistency. If the chest model includes an open/close animation baked in, great. If not, we can create a simple one in the editor — or use a simple mesh swap between open/closed variants.

**Available packs** (see [asset catalog](../../temp_resources/temp-resources-asset-catalog.md) for details):
- **Ruins Pack (Quaternius)** — Chest, Chest_Gold, Doors_GothicArch, Doors_RoundArch (+ covered variants). Also has Barrel, Crate, Bookcase, Cart, Pot, Trapdoor, BearTrap for future interactables.
- **Kenney Urban** — door-type-a, door-type-b. No chest model.

### Step 3.1 — Claude creates directory and writes code

**Claude (code):** I will:
1. Create `assets/models/interactables/` directory
2. Modify `scripts/interactables/chest_interactable.gd`:
   - **If your model has an animation:** Replace `_mesh` / `_closed_material` with `@onready var _anim_player: AnimationPlayer = $AnimationPlayer as AnimationPlayer`
     - Refactor `_update_visual()` to use `_anim_player.play("open")` then `_anim_player.seek(length, true)` for instant state restore on load
     - Update `interact()` to play the "open" animation visually
   - **If your model is two static meshes (open/closed):** Replace the material swap with a mesh resource swap — same pattern, different visual
   - Remove the old material-swap code either way

`door_interactable.gd` needs no changes — it has no visual logic.

### Step 3.2 — You add models and modify chest.tscn

**You (editor):**
1. Copy model files (.glb or .fbx) into `assets/models/interactables/`
2. Open `scenes/interactables/chest.tscn`
3. Delete the `MeshInstance3D` child
4. Instance your imported chest model as a child of the Chest root (or add a MeshInstance3D and assign the mesh)
5. **If using animation:** Add an `AnimationPlayer` child node named exactly `AnimationPlayer`. Create an "open" animation (~0.3s) — either from the baked model animation or by keyframing the lid rotation/scale.
6. Adjust the `CollisionShape3D` to roughly match the new model's footprint
7. Save the scene

### Step 3.3 — You modify door.tscn

**You (editor):**
1. Open `scenes/interactables/door.tscn`
2. Delete the `MeshInstance3D` child
3. Instance your imported door model as a child
4. Adjust the `CollisionShape3D` to match the new model
5. Save the scene

### Step 3.4 — Together: playtest interactables

**Together (verify):**
1. **Chest:** Walk up to the chest and interact. Does it play the open animation (or swap to open mesh)? Does it give the item?
2. **Save/load chest:** Open the chest, save, reload. Does the chest appear already opened? (Should NOT replay the animation — should snap to opened state)
3. **Door:** Walk up to the door and interact. Does the scene transition work?
4. **Collision:** Can you walk up to both objects naturally? No weird gaps or overlaps with the collision shape?

If everything works, I'll run tests, lint, and commit Phase 3.

---

## Post-Integration Checklist

After all 3 phases are done, one final verification:

- [ ] Full quest loop: talk to NPC > start quest > find chest > get item > return to NPC > complete quest
- [ ] Save mid-quest, reload, continue quest
- [ ] Scene transition: walk between both rooms via doors
- [ ] All existing unit/integration tests pass
- [ ] `gdformat --check .` and `gdlint .` pass

---

## Gotchas to Watch For

These are the things most likely to trip us up, collected and validated from multi-agent research:

| Gotcha | When It Bites | What To Do |
|--------|--------------|------------|
| MeshLibrary export drops transform scale | Phase 1, if tiles aren't 1x1x1 | Resize in Blender + Apply Scale, not in Godot |
| MeshLibrary re-export shifts item IDs | Future tile additions after Phase 1 | Append-only: never remove/reorder children in source scene |
| Vertex colors lost after FBX import | Phase 1/3, Quaternius models appear white | Verify "Colors" checkbox is enabled in Godot import settings. Do NOT use external CLI converters (FBX2glTF, obj2gltf) — they drop vertex colors |
| Collision not auto-generated from .glb/.fbx | Phase 1, tiles have no collision | Use Blender `-col` naming or add manually in editor |
| Tile textures set to Lossless | Phase 1, wastes VRAM | Keep .glb textures at default VRAM Compressed; Lossless is only for pixel art sprites |
| Global texture filter doesn't apply to Sprite3D | Phase 2, sprites look blurry | Set `texture_filter = Nearest` per-node on every AnimatedSprite3D |
| `.import` files not committed | Phase 2, import settings lost on clone | Commit all `.import` sidecar files alongside assets |
| `_sprite` null on initial state enter | Phase 2, crash on game start | **Critical:** `play_animation()` must guard `if not _sprite: return` — StateMachine._ready() fires before PlayerController._ready() |
| `play()` called every physics frame | Phase 2, unnecessary overhead | Call `play_animation("walk")` in `enter()` and on direction change only, not every frame |
| Chest animation replays on load | Phase 3, visual state restore | `_anim_player.play("open")` then `seek(length, true)` to jump to end frame instantly |

---

## Risk Analysis

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| MeshLibrary re-export shifts item IDs | Medium | High | Append-only workflow, git diff after export |
| Asset pack scale mismatch | High | Medium | Scale in Blender, not Godot |
| Direction mapping feels wrong | Medium | High | Test all 4 directions immediately in Step 2.7 |
| Sprite transparency sorting | Medium | Low | ALPHA_CUT_DISCARD with threshold 0.5 |
| Collision mismatch after visual swap | Medium | Medium | Tune after playtest; hitbox is gameplay, not visual |
| Gamepad diagonal flickering | Low | Low | Add hysteresis threshold if noticed during testing |

## Future Considerations

- **NPC face-toward-player:** Add `_face_toward()` that projects world-space diff through inverse ISO rotation before quantizing. Deferred from this plan to avoid ISO rotation math complexity.
- **8-directional sprites:** String-based facing extends naturally — just add "down_left", etc.
- **Run animation:** Add `run_*` to SpriteFrames, play from walk state when sprint held.
- **Custom voxel tiles:** Same MeshLibrary pipeline — Qubicle/MagicaVoxel > .glb/.fbx > import.
- **Audio:** SFX via AnimationPlayer tracks alongside sprite animations.
- **UI icons:** `ItemData.icon` field already exists as `Texture2D` — assign textures later.

## Sources & References

### Origin

- **Brainstorm:** [docs/brainstorms/2026-03-20-asset-integration-brainstorm.md](docs/brainstorms/2026-03-20-asset-integration-brainstorm.md)
- **Asset Catalog:** [temp_resources/temp-resources-asset-catalog.md](../../temp_resources/temp-resources-asset-catalog.md) — full inventory of downloaded asset packs with specs, formats, licenses, and import pipeline research

### Internal References

- [player_controller.gd](scripts/player/player_controller.gd) — direction tracking, save/load, ISO_ANGLE
- [player_walk.gd:27](scripts/player/player_states/player_walk.gd#L27) — current `rotation.y` logic to replace
- [chest_interactable.gd:52-60](scripts/interactables/chest_interactable.gd#L52-L60) — material swap to replace
- [state_machine.gd:16-17](shared/state_machine/state_machine.gd#L16-L17) — initial state enter() timing (fires before parent _ready)
- [mesh_library_source.tscn](resources/mesh_library_source.tscn) — 2 items (Wall, Floor)
- [cassette-beasts-technical-reference.md](docs/research/cassette-beasts-technical-reference.md) — voxel pipeline, Sprite3D patterns

### External References

- Godot GridMap: https://docs.godotengine.org/en/stable/tutorials/3d/using_gridmaps.html
- Godot AnimatedSprite3D: https://docs.godotengine.org/en/stable/classes/class_animatedsprite3d.html
- MeshLibrary item ID issue: https://github.com/godotengine/godot/issues/83272
- Sprite3D texture filter issue: https://github.com/godotengine/godot/issues/74629
- Godot ufbx FBX importer (native since 4.3): https://godotengine.org/article/introducing-the-improved-ufbx-importer-in-godot-4-3/
- Godot available 3D formats: https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/available_formats.html

### API Reference (verified via Godot 4.6 docs)

| Property/Method | Type | Notes |
|----------------|------|-------|
| `AnimatedSprite3D.play(name)` | `StringName` | No-ops if same animation already playing |
| `SpriteBase3D.billboard` | `BaseMaterial3D.BillboardMode` | Use `.BILLBOARD_FIXED_Y` (value 2) |
| `SpriteBase3D.texture_filter` | `BaseMaterial3D.TextureFilter` | Use `.TEXTURE_FILTER_NEAREST` (value 0) |
| `SpriteBase3D.alpha_cut` | `SpriteBase3D.AlphaCutMode` | Use `.ALPHA_CUT_DISCARD` (value 1) |
| `AnimationPlayer.seek(sec, update, update_only)` | `float, bool, bool` | `seek(len, true)` snaps immediately but does NOT emit `animation_finished` |
| `GridMap.cell_size` | `Vector3` | Default `(2,2,2)` — project overrides to `(1,1,1)` |
