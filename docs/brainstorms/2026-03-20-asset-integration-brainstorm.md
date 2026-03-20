# Asset Integration Brainstorm

**Date:** 2026-03-20
**Status:** Reviewed

---

## What We're Building

A complete visual asset pipeline to replace all placeholder primitives in the project with real art assets. The project currently uses CapsuleMesh/BoxMesh primitives with colored materials for every entity and untextured GridMap tiles for the world. This brainstorm covers the full scope of asset integration across environment, characters, and interactables.

### Target Aesthetic

- **Environment:** Low-poly 3D tiles via GridMap, with a path toward voxel-authored tiles (Cassette Beasts style). Pre-made asset packs initially, custom Qubicle/MagicaVoxel models later.
- **Characters (Player, NPCs):** Sprite3D billboards with pixel art sprite sheets. 4-directional, idle + walk animations to start.
- **Interactables (Chest, Door):** Low-poly 3D models from the same pack as environment tiles, replacing current BoxMesh primitives.

### Current State (100% Placeholder)

| Entity | Current Visual | Target Visual |
|--------|---------------|---------------|
| Player | White CapsuleMesh | Sprite3D with 4-dir animated sprite sheet |
| NPC | Blue CapsuleMesh | Sprite3D with 4-dir animated sprite sheet |
| Chest | Gold BoxMesh (0.8^3) | Low-poly 3D model |
| Door | Brown BoxMesh (1x2x0.3) | Low-poly 3D model |
| Floor tile | Invisible BoxMesh (1x1x1) | Textured/modeled low-poly mesh |
| Wall tile | Gray BoxMesh (1x3x1) | Textured/modeled low-poly mesh |

---

## Why This Approach

### Approach A: Tile-First, Bottom-Up (Selected)

**Order:** GridMap tiles -> Sprite3D characters -> interactable models

**Rationale:**
1. **Biggest visual impact first** -- environment is on screen everywhere, transforms both test rooms immediately
2. **Simplest pipeline first** -- MeshLibrary swap is a contained task (no animation system, no direction tracking)
3. **Validates the long-term import pipeline** -- the same workflow (model -> import -> MeshLibrary) applies when moving to custom voxel tiles later
4. **Characters in a real world look better** -- Sprite3D characters in a gray box world looks worse than capsule characters in a textured world

**Rejected alternatives:**
- **Character-First (B):** De-risks animation wiring early but creates visual dissonance (animated sprites in gray boxes). More complex first step.
- **Parallel Tracks (C):** Fastest total time but more context switching, harder to maintain focus.

---

## Key Decisions

### 1. GridMap stays as the world system

GridMap is proven (Cassette Beasts used it for their entire open world). Current cell size (1x1x1) is compatible with most asset packs. The MeshLibrary just needs its meshes swapped.

### 2. Hybrid rendering: 3D environment + 2D character sprites

Matches the Cassette Beasts "HD-2D" approach (voxel 3D tiles + Sprite3D pixel art characters). The fixed isometric camera makes billboard sprites look natural.

### 3. Pre-made asset packs first, custom assets later

Fastest path to visual fidelity. Asset packs validate the pipeline; custom assets can replace them incrementally. CC0-licensed packs (Kenney, Quaternius) avoid licensing complexity.

### 4. 4-directional, idle + walk animations as starting scope

Minimum viable character animation. 4 directions suit the isometric camera. Walk + idle cover all current player states (Interact state freezes the player, so idle suffices). Run and emote animations can be added later.

### 5. All entities upgraded together (per-domain)

When tiles are done, both rooms get new tiles. When characters are done, both player and NPC get sprites. When interactables are done, chest and door both get models. No half-upgraded visual states.

---

## Implementation Overview

### Phase 1: Environment Tiles (GridMap MeshLibrary)

**What changes:**
- Find/select a low-poly or voxel tile pack with ~8-12 types (floor, wall, wall-corner, wall-end, door frame, stairs/ramp, pillar, window)
- Import .glb models into Godot (prefer .glb over .obj -- first-class format with material/hierarchy support)
- Rebuild `resources/mesh_library_source.tscn` with real meshes + collision shapes
- Re-export `resources/mesh_library.tres` via Godot editor (Scene > Export As > MeshLibrary)
- Rebuild GridMap layouts in `test_room.tscn` and `test_room_2.tscn` using new tiles

**Collision shapes require explicit setup.** Imported .glb models do NOT automatically get collision in the MeshLibrary. Two options:
- **Blender naming convention (preferred):** Name meshes with `-col` suffix in Blender before export. Godot's importer auto-generates StaticBody3D + trimesh collision from these.
- **Godot editor:** Select each MeshInstance3D in the source scene, use Mesh menu > Create Trimesh/Convex Static Body.

**Scale must be applied in the 3D tool, not Godot.** MeshLibrary export silently drops MeshInstance3D transform scale. If tile pack meshes don't match cell size, resize and `Ctrl+A > Apply Scale` in Blender before re-exporting the .glb.

**MeshLibrary item ID stability (critical risk).** Re-exporting a MeshLibrary can shift item IDs, scrambling existing GridMap placements (known issue #83272). Mitigation:
- Only append new MeshInstance3D children to the source scene -- never remove or reorder existing ones.
- To "remove" a tile, replace its mesh with a placeholder rather than deleting the node.
- Version-control the `.tres` file and diff after re-export to catch ID shifts.

**What stays the same:**
- GridMap node structure in scenes
- All scripts -- no code changes needed
- Scene transition flow, camera, physics layers

**Editor-required steps:**
- MeshLibrary export (must be done in Godot editor)
- GridMap tile placement (must be done in Godot editor)
- Collision shape verification (walk-test with CharacterBody3D)

**Asset directory structure:**
```
assets/
  models/
    tiles/          # .glb tile models from asset pack
  materials/        # Shared materials if needed (or extract via import settings)
```

### Phase 2: Character Sprites (Sprite3D + Animation)

**What changes:**
- Find/select pixel art character sprite sheets (4-dir, idle + walk)
- Create `assets/sprites/characters/` directory for sprite sheet PNGs
- Replace MeshInstance3D with AnimatedSprite3D in `player.tscn` and `npc.tscn` (editor work)
- Create SpriteFrames resources (.tres) per character, defining animations per direction
- Add `FacingDirection` enum and tracking to `player_controller.gd`
- Wire animation state changes into player states (Idle -> play idle anim, Walk -> play walk anim)
- Configure billboard mode and pixel art rendering on AnimatedSprite3D

**Resolved technical decisions (from research):**
- **AnimatedSprite3D** (not Sprite3D + AnimationPlayer) -- purpose-built for frame-by-frame cycling, simpler API (`play("walk_down")`), directly supports per-character SpriteFrames via `@export`. AnimationPlayer can be added alongside later for multi-property animations (particles, SFX).
- **`BILLBOARD_FIXED_Y`** -- rotates to face camera on Y axis only, keeps sprites upright. Works correctly with orthographic projection.
- **`action_direction` naming** -- `idle_down`, `walk_left`, etc. Community standard, scales to future animations (`run_down`, `attack_left`).
- **Pixel art rendering settings (per-node, not global):**
  - `texture_filter = TEXTURE_FILTER_NEAREST` (global project setting does NOT apply to Sprite3D nodes)
  - `alpha_cut = ALPHA_CUT_DISCARD` with `alpha_scissor_threshold = 0.5` (prevents transparency sorting artifacts)
  - `pixel_size` -- adjust to match world scale (e.g., `1.0 / 32.0` for a 32px-tall sprite to be 1 world unit tall)
  - PNG import settings: Filter Off, Mipmaps Off, Compress Mode Lossless
- **Shading mode:** Try both unshaded (flat pixel art) and shaded (reacts to lights) during implementation. Toggle via a single flag.

**Script changes needed:**
- `player_controller.gd` -- add `FacingDirection` enum, `facing_direction` var, `update_facing()` method
- `player_walk.gd` -- call `update_facing()` instead of setting `rotation.y` (billboard handles visual rotation now)
- `player_idle.gd` -- trigger idle animation on enter
- AnimatedSprite3D child script -- `play_directional(action)` method that combines action + facing direction

**Direction tracking architecture:**
- Controller owns `facing_direction` (persists across state transitions -- idle remembers which way you faced)
- AnimatedSprite3D child reads direction + receives `play_directional()` calls from states
- States trigger animations on enter/exit (follows "call down" convention)
- Player no longer rotates via `rotation.y` -- the sprite handles its own camera-facing via billboard

**Asset directory structure:**
```
assets/
  sprites/
    characters/
      player/       # Player sprite sheets
      npc/          # NPC sprite sheets
```

### Phase 3: Interactable Models

**What changes:**
- Find/select low-poly models for chest and door (ideally from same pack as tiles for visual consistency)
- Replace BoxMesh MeshInstance3D nodes in `chest.tscn` and `door.tscn` with imported 3D models (editor work)
- Adjust collision shapes to match new model geometry
- Optionally add open/close animation to chest (AnimationPlayer)

**Script changes needed:**
- `chest_interactable.gd` -- optionally trigger open animation on interact
- `door_interactable.gd` -- no changes unless adding door-open animation

**Asset directory structure:**
```
assets/
  models/
    interactables/  # .glb/.obj models for chest, door, etc.
```

---

## Open Questions

1. **Sprite `pixel_size` calibration:** The `pixel_size` property controls how many world units one sprite pixel occupies. The correct value depends on the chosen sprite sheet's pixel dimensions relative to the GridMap cell size. Must be determined after asset pack selection.

---

## Resolved Questions

1. **Asset pack selection:** User will pick their own packs. The pipeline documentation should be pack-agnostic, focused on import requirements and integration steps.

2. **Lighting interaction:** Deferred to implementation -- try both unshaded (flat pixel art) and shaded (reacts to world lights) and compare. Architecture should support toggling this easily (material flag).

3. **NPC sprite variety:** 2-3 distinct NPC sprite sheets from the start. Architecture should support per-NPC SpriteFrames resources via an `@export` on the NPC scene.

4. **Scale/unit matching:** Decide per-pack. Document both strategies in the plan. Key constraint: scale must be applied in Blender (`Ctrl+A > Apply Scale`), not via Godot's MeshInstance3D transform -- MeshLibrary export silently drops transform scale.

5. **Texture filtering:** Resolved by research. Sprite3D nodes require `texture_filter = TEXTURE_FILTER_NEAREST` set per-node (global project setting does not apply). PNG imports need Filter Off, Mipmaps Off, Compress Mode Lossless.

6. **Animation system:** Resolved by research. AnimatedSprite3D with per-character SpriteFrames resources. `BILLBOARD_FIXED_Y` mode. `action_direction` naming convention (`walk_down`, `idle_up`).

7. **Collision on imported tiles:** Resolved by research. Must use Blender `-col` naming convention or manually add collision in the Godot editor. Not automatic.

---

## Scope Boundaries

**In scope:**
- Asset directory structure and import pipeline
- GridMap MeshLibrary rebuild with real tiles
- Sprite3D character rendering with 4-dir idle/walk
- Interactable 3D model replacement
- Necessary script changes for animation

**Out of scope (future work):**
- Audio/SFX (separate brainstorm)
- UI theme/fonts (separate brainstorm)
- Battle sprites or combat animations
- Particle effects
- Custom asset creation (Qubicle, Aseprite)
- Run/interact/emote animations beyond idle+walk
- 8-directional movement
