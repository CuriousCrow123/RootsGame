---
title: "GridMap Tile Import Pipeline Learnings"
date: 2026-03-20
tags: [gridmap, meshlibrary, fbx, import, quaternius, tiles]
status: active
---

# GridMap Tile Import Pipeline Learnings

## Context

First attempt at replacing placeholder BoxMesh tiles with Quaternius "Ultimate Modular Ruins Pack" FBX models in a GridMap MeshLibrary. Godot 4.6, ufbx importer. Includes both trial-and-error learnings and follow-up research.

## What We Learned

### 1. FBX scale: centimeters vs meters

Blender's FBX exporter applies a 100x scale to convert from its internal meters to FBX's centimeter convention. The ufbx importer (`fbx/importer=0`) uses `UFBX_SPACE_CONVERSION_MODIFY_GEOMETRY` which bakes unit scaling (divide by 100) into vertex data — so meshes should appear at correct meter-scale automatically.

However, for pre-made asset packs (like Quaternius) where you don't control the Blender export settings, the scale may still be off. Our Quaternius tiles were ~0.01 units (centimeters) in the MeshLibrary.

**What `nodes/root_scale` does:** A multiplier on the imported scene. With `apply_root_scale=false` (default), it scales the root node's transform. With `apply_root_scale=true`, it bakes the scale directly into mesh vertex data, keeping the root node at scale `(1,1,1)`.

**Fix:** Set `nodes/apply_root_scale=true` so scale is baked into geometry (critical for MeshLibrary). Adjust `nodes/root_scale` until tiles are the correct size. For Quaternius FBX tiles targeting 1x1 GridMap cells, `root_scale=0.5` worked (native models are 2x2 at meter scale).

**Best practice for custom models:** In Blender's FBX export dialog, set "Apply Scalings" to "FBX Units Scale" — this exports at 1m units, eliminating the 100x discrepancy entirely.

### 2. MeshLibrary export strips transforms — critical hierarchy requirement

The MeshLibrary export only reads transforms from `MeshInstance3D` nodes themselves. It **ignores transforms on parent Node3D wrappers** (godot issue #96357). This caused:
- **Scale not applied:** If scale is on a parent node, tiles appear tiny.
- **Axis rotation not applied:** FBX Z-up to Y-up correction is a node transform (ufbx does NOT bake axis conversion into vertices, unlike unit scaling). Walls appeared flat.

**Fix:** Enable **"Apply MeshInstance Transforms"** in the MeshLibrary export dialog — this bakes the MeshInstance3D's local transform into vertex data.

**Critical caveat:** This only works for transforms on the MeshInstance3D itself. If your FBX import creates:
```
Node3D (with rotation)  ← IGNORED by MeshLibrary export
  MeshInstance3D (identity transform)
```
...the rotation is lost. The MeshInstance3D must be a **direct child of root** with the correct transform applied to it, not to a wrapper.

### 3. LOD generation breaks low-poly models

With `meshes/generate_lods=true` (default), Godot uses meshoptimizer to auto-generate simplified LOD meshes. On already-low-poly models (hundreds of triangles), the algorithm aggressively removes vertices, creating holes/transparency at normal viewing distances.

**Fix:** Set `meshes/generate_lods=false`. Low-poly asset packs (Quaternius, Kenney) are already optimized for real-time and don't benefit from LOD. If you need LOD later for large scenes, create custom LOD meshes in your modeling tool using `_LOD0`/`_LOD1`/`_LOD2` naming suffixes.

### 4. Vertex colors work automatically with ufbx

The ufbx importer reads vertex color data from FBX mesh attributes without any special toggle. There is no "Colors" checkbox in the FBX import panel (that only exists for `.blend` direct import). If models appear white, it's a material issue, not an import issue.

**Known color space issue (godot #82994):** Blender exports vertex colors as sRGB in FBX. Set `vertex_color_is_srgb=true` on your material to interpret them correctly.

### 5. MeshLibrary ghost items on re-export

Re-exporting over an existing `.tres` can leave stale entries from the previous export.

**Fix:** Use **"Remove existing items"** / disable **"Merge with existing"** in the export dialog for clean exports.

### 6. Imported FBX materials are read-only

Materials embedded in imported FBX scenes cannot be edited in the Inspector.

**Fix:** Use **Surface Material Override** on the MeshInstance3D to apply a new editable material. Or better: create a standalone `.tres` material file (see section below) and assign it as an override.

### 7. Vertex-colored material setup

For vertex-colored models, create a standalone `StandardMaterial3D` resource:

| Property | Value | Purpose |
|----------|-------|---------|
| `vertex_color_use_as_albedo` | `true` | Use vertex colors as base color |
| `vertex_color_is_srgb` | `true` | Correct for FBX from Blender (sRGB encoded) |
| `albedo_color` | `Color(1, 1, 1, 1)` | White — vertex colors are multiplied by this, so non-white tints them |
| `shading_mode` | `Unshaded` or `Per-Pixel` | Unshaded = flat/clean, Per-Pixel = lit by scene lights |

**Unshaded** is recommended for low-poly vertex-colored models with uneven surfaces — it avoids harsh shadow/bright spot artifacts from directional lighting on bumpy geometry.

**Alternative: GridMap `material_override`** — instead of setting materials per-tile, you can apply one material to the entire GridMap node. Works well for uniformly vertex-colored packs.

## Recommended .import Settings for Quaternius FBX Tiles

```ini
nodes/apply_root_scale=true
nodes/root_scale=0.5
meshes/generate_lods=false
meshes/create_shadow_meshes=true
meshes/light_baking=1
fbx/importer=0
```

## Correct MeshLibrary Source Scene Hierarchy

The MeshInstance3D **must** be a direct child of root with transforms on itself:

```
Root (Node3D)
  FloorTile (MeshInstance3D)      ← transform HERE, direct child of root
    StaticBody3D
      CollisionShape3D
  WallTile (MeshInstance3D)       ← transform HERE, direct child of root
    StaticBody3D
      CollisionShape3D
```

**NOT** this (transforms on parent Node3D are silently ignored):
```
Root (Node3D)
  WallWrapper (Node3D)            ← transform here is LOST
    WallMesh (MeshInstance3D)
```

## MeshLibrary Export Settings

- **Apply MeshInstance Transforms** = enabled (critical — bakes scale + rotation into vertices)
- **Remove existing items** / don't merge = enabled (prevents ghost entries)

## Collision Shape Reference

| Shape type | Use for | How to create |
|-----------|---------|---------------|
| BoxShape3D / ConvexShape3D | Floors, walls, simple boxes | Mesh menu > Create Single Convex Collision Sibling |
| ConcavePolygonShape3D (trimesh) | Stairs, arches, complex shapes | Mesh menu > Create Trimesh Static Body |

After creating collision via the Mesh menu, it appears as a sibling — reparent it under the MeshInstance3D if needed.

## Complete Workflow

1. Copy FBX files to `assets/models/tiles/`
2. Set `.import` settings: `apply_root_scale=true`, appropriate `root_scale`, `generate_lods=false`
3. Reimport in Godot and verify scale/orientation by dragging into a test scene
4. Create a standalone `.tres` material (vertex color unshaded) in `assets/materials/`
5. Build `mesh_library_source.tscn`:
   - MeshInstance3D as **direct child of root** (not nested under Node3D)
   - All transforms on the MeshInstance3D itself
   - StaticBody3D + CollisionShape3D as children
   - Apply material override
6. Export MeshLibrary with **"Apply MeshInstance Transforms"** enabled
7. Set GridMap `cell_size` to match tile dimensions
8. Paint GridMap in room scenes

## Sources

- [ufbx importer in Godot 4.3](https://godotengine.org/article/introducing-the-improved-ufbx-importer-in-godot-4-3/)
- [MeshLibrary transform issue — godot #96357](https://github.com/godotengine/godot/issues/96357)
- [FBX empties 100x scale — godot #90314](https://github.com/godotengine/godot/issues/90314)
- [Vertex color sRGB/linear mismatch — godot #82994](https://github.com/godotengine/godot/issues/82994)
- [Godot import configuration docs](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html)
- [Using GridMaps — Godot docs](https://docs.godotengine.org/en/stable/tutorials/3d/using_gridmaps.html)
