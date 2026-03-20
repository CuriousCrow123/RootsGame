# RPG Foundation Brainstorm

**Date:** 2026-03-19
**Status:** Complete — ready for `/gc:plan`

## What We're Building

A playable foundation for a 3D orthographic RPG with quest-driven gameplay, inspired by Cassette Beasts (but will differ significantly). Core mechanic is TBD. Combat intentionally deferred until the core mechanic is decided.

The first milestone is a **playable loop with production-quality data foundations** — one room, one NPC, one quest, proving all core patterns work together.

## Why This Approach

### 3D Orthographic (Not 2D Isometric)

Both reference games (Hades, Cassette Beasts) are 3D with fixed cameras, not 2D isometric. Cassette Beasts uses Godot's GridMap with voxel tiles and a fixed overhead camera — the "2D look" is art direction, not engine 2D.

3D orthographic gives depth sorting, occlusion, collision volumes, and pathfinding natively — eliminating the Y-sort, stair transition, and mouse picking pain points of 2D isometric. Community research validated this as the lower-risk path.

### Playable Loop (Not Skeleton Systems)

Community consensus (Derek Yu, Bob Nystrom) warns against building systems in isolation before gameplay. The refactoring cost of incremental development concentrates in the **data layer** — if you design Resources, IDs, and serialization contracts upfront, the wiring can emerge through gameplay without rework.

Each build step produces production-quality code. Autoloads are added when concrete gameplay needs trigger them, not speculatively.

### Quest & Story Driven Core

Core mechanic is TBD, so story/quest systems are the safest investment. These systems are needed regardless of what the core mechanic becomes.

### Dialogue Manager over Dialogic 2

- Dialogic 2 still in alpha, has confirmed Godot 4.6 crashes (GitHub issue #2736)
- Dialogue Manager is stable, stateless, community-proven
- Stateless/headless — game owns all state, no parallel state system to sync
- `.dialogue` files are plain text, version-control friendly
- We build our own UI (full control over look and feel)

## Key Decisions

1. **Rendering:** 3D orthographic with fixed camera at ~(30°, 45°, 0°)
2. **World building:** GridMap with modular 3D kits (Kenney, KayKit)
3. **Characters:** Start with 3D models (Option C), migrate to Sprite3D billboard later if desired — visual-layer swap only
4. **Movement:** Free analog movement (CharacterBody3D + capsule + move_and_slide), grid-snapped world objects
5. **Core loop:** Quest & story driven (core mechanic TBD, combat deferred)
6. **Dialogue:** Dialogue Manager plugin (stateless, headless)
7. **Architecture:** Resource for data, Node for behavior (two layers). Autoloads added when triggered by gameplay needs.
8. **Data foundations:** Resources with string IDs, serialization contract (`get_save_data()`/`load_save_data()`) from day one
9. **Milestone:** Playable loop, not skeleton systems

## Architecture

### Data Layer (Design Upfront)

| Resource | Purpose |
|----------|---------|
| QuestData | Quest definitions with steps, conditions, outcomes |
| QuestStepData | Individual quest step definitions |
| ItemData | Item definitions (name, description, properties) |

**Patterns from day one:**
- String IDs for cross-scene references (quest IDs, item IDs) — never direct node references
- Every system implements `get_save_data() -> Dictionary` and `load_save_data(data: Dictionary)`
- `.duplicate()` any Resource before mutating at runtime (Godot shares loaded Resources by path)

### Two-Layer Pattern

| Layer | Type | Role | Examples |
|-------|------|------|----------|
| Data | Resource (.tres) | Definitions, serializable state | ItemData, QuestData, QuestStepData |
| Behavior | Node | Scene-tree integration, logic, UI | PlayerController, QuestTracker, InventoryUI |

RefCounted middle layer omitted — community consensus says it's niche. Add only if a concrete performance need arises.

### Interactable Pattern

All interactive world objects share the same composition:

```
StaticBody3D (blocks movement)
├── CollisionShape3D (physical bounds)
├── MeshInstance3D (visual)
└── Area3D (interaction detection zone, slightly larger)
    └── CollisionShape3D (detection bounds)
```

Player enters Area3D → "interact" prompt. Press interact → type-specific response (dialogue, give item, open door, toggle state). NPC, chest, door, sign, lever are all interactable types.

### Autoload Roadmap

Not built speculatively — each triggered by a concrete gameplay need. Knowing the destination prevents rework:

| Autoload | Responsibility | Trigger | Design Ahead |
|----------|---------------|---------|--------------|
| SceneManager | Area transitions with threaded loading + fade | Step 5: second room | Keep scene transitions behind a callable (e.g., `_change_scene(path)` helper) so wiring to SceneManager is a one-line change |
| SaveManager | Serialize/deserialize all system states | Step 6: save/load | The `get_save_data()`/`load_save_data()` contract means SaveManager just iterates and calls. Zero refactoring if the contract exists from day one |
| EventBus | Cross-system signals only | When 2+ systems can't reach each other through the tree | Use direct signals until then. May never be needed |
| GameState | Current game mode (OVERWORLD, BATTLE, MENU, etc.) | Second game mode | A simple enum. Until then, game mode is implicitly OVERWORLD |

### Collision Layers

Set up on day one:

| Layer | Purpose |
|-------|---------|
| 1 | Environment (GridMap, static props) |
| 2 | Player |
| 3 | NPCs |
| 4 | Interactables/pickups |

### Plugin Dependencies

- **Dialogue Manager** (Nathan Hoad) — dialogue parsing and branching
- **GUT** (already installed) — unit/integration testing

## Build Order

Each step produces production-quality code. Steps 1-4 = single-room prototype. Steps 5-8 extend into a real game.

| Step | What | Foundation It Builds | Autoload Trigger |
|------|------|---------------------|-----------------|
| 1 | Player walking in GridMap room | 3D scene structure, movement, camera | None |
| 2 | Interactable pattern + NPC with dialogue | Interactable base composition, Dialogue Manager integration. NPC is the first interactable type. | None |
| 3 | Chest interactable + item pickup | Second interactable type. ItemData Resources, inventory array. Proves the pattern generalizes. | None |
| 4 | Quest ("fetch item from chest") | QuestData Resources, quest tracking. Wires together NPC, chest, and inventory into a complete loop. | None |
| 5 | Second room + door interactable | Third interactable type (door/exit). Scene transition pattern. | **SceneManager** |
| 6 | Save/load | Serialize all system states via existing contracts | **SaveManager** |
| 7 | Multiple cross-system events | Signal routing beyond scene tree | **EventBus** (if needed) |
| 8 | Second game mode | Mode switching | **GameState** |

## Technical Notes

### GridMap

- Stable in Godot 4.6, not being deprecated, got Bresenham paint fix
- No autotiling (community addons exist: AutoGrid, GridMapLayer)
- Performance ceiling at ~3K tiles with collision per chunk — keep chunks under 50x50
- No dedicated maintainer, but not going away
- TileMap3D proposal (#3518, 220+ upvotes) has no timeline — don't plan around it

### MeshLibrary Workflow

One-time setup per tileset:
- Apply scale in Blender (Ctrl+A > Apply Scale) before export — Godot resets scale during conversion
- Set mesh origins in Blender — Godot respects imported origins but can shift them during conversion
- Use simple convex collision shapes (BoxShape3D, ConvexPolygonShape3D) — never trimesh/concave
- Keep flat hierarchy — child MeshInstances of MeshInstances are dropped during conversion

### Navigation (Decision Deferred)

Two options, decide during prototyping:
- **NavigationRegion3D + NavMesh:** Flexible pathfinding, must chunk (fails at 56K tiles). Bake per-chunk.
- **AStar3D on the grid:** Simpler, predictable for tile-based movement. No baking needed.

### Character Rendering Migration (Option C)

Start with 3D models. If switching to Sprite3D later:
- Swap MeshInstance3D for Sprite3D under same CharacterBody3D — all gameplay code unchanged
- Set `shaded = false` (3D lighting distorts sprite palettes), use decals for shadows
- Set `alpha_cut = ALPHA_CUT_DISCARD` for depth sorting
- Set `texture_filter = TEXTURE_FILTER_NEAREST` for crisp pixel art
- Use "Spatial View-Depending Directional Billboard" shader or GodotSprite3DPlus for direction selection
- Fixed orthographic camera makes transparency sorting predictable (Z-position based)

### Art Migration

When swapping placeholder kits for custom art (voxel or otherwise):
- Tile positions in GridMap transfer (integer indices)
- Meshes, collision shapes, origins, scales, and materials need rebuilding
- Budget 1-2 days per tileset

### Save Format

Dictionary → JSON hybrid. Human-readable, safe schema migration (merge with defaults), no code execution risk. Upgrade path: `store_var()` if type conversion becomes painful.

## Assets for Prototyping (All CC0)

**Environments:**
- Kenney Fantasy Town Kit (160), Castle Kit (75), Modular Dungeon Kit (40), Nature Kit (330), Furniture Kit (140)

**Characters:**
- KayKit Adventurers (5 rigged/animated), Quaternius RPG Character Pack (6 rigged/animated)

**UI:**
- Kenney Fantasy UI Borders + UI Pack RPG Expansion

**Import pipeline:**
- godot-kenney-gridmap (GitHub, MeshLibrary reference)

## Resolved Questions

- **Quest complexity:** Branching from the start. Quest steps support conditions, multiple paths, and outcomes.
- **Menu UI:** Kenney UI assets. CC0 licensed, consistent style, fast to set up.
- **Save format:** Dictionary → JSON with `get_save_data()`/`load_save_data()` contract.

## References

- [Cassette Beasts Technical Reference](../research/cassette-beasts-technical-reference.md) — full breakdown of how Cassette Beasts was built in Godot
- [3D Isometric Technical Validation](2026-03-19-3d-isometric-technical-validation.md) — community validation of each technical claim
