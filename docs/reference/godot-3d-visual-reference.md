# Godot 4.6 — 3D Visuals, Lighting & GridMap Reference

Covers vertex colors, GridMap workflow, lighting/shadow configuration, and what can be edited outside the Godot editor. Written for the RootsGame project (GL Compatibility renderer).

---

## Table of Contents

1. [Vertex Colors](#vertex-colors)
2. [GridMap & MeshLibrary](#gridmap--meshlibrary)
3. [Lighting & Shadows](#lighting--shadows)
4. [Environment & Post-Processing](#environment--post-processing)
5. [GL Compatibility Renderer Limitations](#gl-compatibility-renderer-limitations)
6. [.tscn Editable Properties Reference](#tscn-editable-properties-reference)
7. [project.godot Rendering Settings](#projectgodot-rendering-settings)
8. [.import File Settings (3D Scenes)](#import-file-settings-3d-scenes)
9. [Sources](#sources)

---

## Vertex Colors

### What They Are

Each vertex in a 3D mesh can store an RGBA color value (3–4 bytes) alongside its position and normal. The GPU interpolates colors smoothly between vertices across each triangle face. When adjacent vertices have different colors, the surface gradients between them. Artists can create hard color boundaries by assigning uniform colors to all vertices of a polygon, or by using "vertex face" painting mode to restrict color to specific faces. For flat-shaded low-poly models (like the Quaternius Ruins Pack), this produces solid-colored surfaces with no texture files needed.

### Vertex Colors vs. UV Textures

| | Vertex Colors | UV Textures |
|--|---|---|
| **Storage** | RGBA per vertex (3–4 bytes each) | Separate image file mapped via UV coordinates |
| **Detail level** | Limited by polygon count | Arbitrarily fine, independent of poly count |
| **File size** | Tiny — no texture files | Larger — texture images can be several MB |
| **VRAM** | Very low | Higher — textures loaded into GPU memory |
| **Workflow** | Fast — color directly on mesh, no UV unwrapping | Slower — UV layout, 2D painting, re-import |
| **Best for** | Stylized low-poly, prototyping, mobile | Realistic surfaces, pixel art, detailed patterns |

### Vertex Colors in Godot

When Godot imports vertex-colored FBX/GLB models, the importer creates a `StandardMaterial3D`. For vertex colors to display:

1. **Import setting:** Enable "Colors" checkbox in the Import dock (for FBX models)
2. **Material properties:** `vertex_color_use_as_albedo = true`, `vertex_color_is_srgb = true` (for FBX from Blender)
3. **Albedo color:** Set to white `Color(1, 1, 1, 1)` so vertex colors aren't tinted

Once enabled, vertex colors act as the **albedo** and participate in the full lighting pipeline — they receive diffuse lighting, cast/receive shadows, and are modulated by ambient light, just like any textured surface.

**If models appear white/grey:** Vertex colors were not imported. Verify the "Colors" checkbox is enabled in import settings and reimport.

### Material Settings for Low-Poly Vertex-Colored Models

When vertex colors are used as albedo, the material's other PBR properties still apply. Recommended settings for a consistent low-poly look:

| Property | Recommended | Why |
|----------|-------------|-----|
| `roughness` | `1.0` | Fully matte, no shininess — consistent non-reflective low-poly appearance |
| `metallic` | `0.0` | No metallic reflections |
| `specular` | `0.0`–`0.5` | `0.0` = zero specular highlights (fully matte). `0.5` = default, subtle highlights. |
| `shading_mode` | `0` (Unshaded) or `1` (Per-Pixel) | Unshaded ignores all lighting (flat colors only). Per-Pixel is the standard PBR lit mode. |

---

## GridMap & MeshLibrary

### Concept

GridMap is Godot's 3D equivalent of TileMap — building with snap-to-grid blocks. It has two parts:

- **MeshLibrary** (`.tres`) — A catalog of tile types. Each tile = mesh + optional collision + optional navmesh. Like a palette of Lego pieces.
- **GridMap** (node) — References a MeshLibrary and stores which tile is at each grid cell (x, y, z) at what rotation. Like a baseplate where you snap blocks.

Each cell has a configurable `cell_size` (this project uses `Vector3(1, 1, 1)`). Tiles snap to the grid with no fractional positioning. The Y axis is the "floor level" for vertical stacking.

### Creating a MeshLibrary

The MeshLibrary is built from a scene with this structure:

```
Node3D (root)
├── Floor (MeshInstance3D)        → becomes tile item 0
│   └── StaticBody3D
│       └── CollisionShape3D
├── Wall (MeshInstance3D)         → becomes tile item 1
│   └── StaticBody3D
│       └── CollisionShape3D
└── ... more tiles
```

**Rules:**
- Root must be **Node3D**
- Each direct child must be a **MeshInstance3D** — becomes one tile in the library
- Materials must be on the **mesh resource itself**, not the MeshInstance3D material override slot
- Each MeshInstance3D can have **one StaticBody3D** child with one or more **CollisionShape3D** children
- Each can optionally have one **NavigationRegion3D** child
- **Transforms on parent Node3D are ignored** by MeshLibrary export (Godot issue #96357). MeshInstance3D must be a direct child of root with transforms applied to itself, not via a parent wrapper node.
- **Scale must be baked into vertices** — MeshLibrary export silently drops transform scale. For Blender models: `Ctrl+A > Apply Scale` before export.

### Adding Collision

Two approaches:

1. **Auto-generate in editor:** Select MeshInstance3D → **Mesh menu** → **Create Trimesh Static Body** (complex shapes) or **Create Convex Static Body** (simple boxes)
2. **From Blender:** Name meshes with `-col` suffix — Godot auto-generates collision on import

### Exporting the MeshLibrary

1. Open `mesh_library_source.tscn`
2. **Scene menu → Export As... → MeshLibrary**
3. Save as `mesh_library.tres`

**Critical:** After first export, never remove or reorder children — only append. Removing/reordering shifts item IDs, scrambling any GridMap that references them (Godot issue #83272).

### GridMap Editor Controls

When a GridMap node is selected, the GridMap panel appears at the bottom of the editor.

**Tools:**

| Tool | What it does |
|------|---|
| Transform | Add gizmo to reposition/rotate the entire GridMap in the scene |
| Selection | Select an area in the viewport |
| Paint | Place selected tile (left-click) |
| Erase | Remove tiles (right-click, or Erase tool + left-click) |
| Pick | Click existing tile to select that type (eyedropper) |
| Fill | Fill selected rectangular area with chosen tile |
| Move | Reposition selected tiles |
| Duplicate | Copy selected tiles |
| Delete | Remove entire selected area |
| Filter Meshes | Search/filter tiles in the palette |

**Key controls:**

| Control | Action |
|---------|--------|
| Left-click | Place tile |
| Right-click | Erase tile |
| Shift + right-click drag | Erase in a straight line |
| Ctrl+Shift + click drag | Fill rectangular region |
| A / D | Rotate tile before placing |
| Cursor Rotate X/Y/Z buttons | Rotate on specific axes |
| Q / E (or floor buttons) | Change grid floor level up/down |

**Floor level** is how you build vertically — floor 0 is ground level, switch to floor 1 for ceiling/second story. The orange grid plane shows which floor you're painting on.

**Settings:** The Tools dropdown provides a **Pick Distance** setting — the maximum distance (in meters) at which tiles can be placed relative to the camera.

### Quaternius Ruins Pack Grid Notes

- Uses a 1x1 modular grid (matches project's `cell_size = Vector3(1, 1, 1)`)
- Walls require 180° vertical rotation on 90° turns for edges to fit
- Curve pieces handle rotation automatically and span 2 wall units
- All models use vertex colors (no textures except tree bark/leaves)

### Workflow for Quaternius Ruins Pack

```
1. Copy FBX files into assets/models/tiles/
2. Godot auto-imports — verify "Colors" is ON in Import dock
3. Open mesh_library_source.tscn
4. For each tile type:
   a. Add MeshInstance3D child to root
   b. Assign imported mesh
   c. Mesh menu → Create Trimesh Static Body (adds collision)
5. Scene menu → Export As → MeshLibrary → overwrite mesh_library.tres
6. Open room scene → select GridMap → paint with new tiles
```

---

## Lighting & Shadows

### How Lighting Works with Vertex-Colored Models

Final pixel color is computed as:

```
final_color = vertex_color × (ambient_light + direct_light × shadow)
```

Vertex colors are the albedo. Lighting modulates them — bright areas show original vertex color, shadowed areas darken it.

### DirectionalLight3D

Acts like sunlight — infinitely far, parallel rays. **Only orientation matters, not position.** The node's rotation determines light direction.

Inherits shadow properties from **Light3D**. DirectionalLight3D-specific properties are prefixed `directional_shadow_`.

**Shadow modes and performance:** The default PSSM 4 Splits divides the view frustum into 4 cascade zones, each with its own shadow map. Objects large enough to appear in all 4 splits are rendered 5 times total (once per split + once for the scene). PSSM 2 = 3 renders. Orthogonal = 2 renders. For small dungeon rooms, PSSM 2 or Orthogonal is sufficient.

**Practical settings for dungeon rooms:**
- Angle ~45° downward, ~30° to the side (side lighting shows wall detail — not directly overhead)
- Energy: 1.0–1.5
- Shadow mode: PSSM 2 Splits (sufficient for small rooms)
- Shadow max distance: 30–50 (rooms are small)
- Shadow blur: 0.0–0.5 for stylized sharp shadows
- Shadow bias: start with default 0.1, increase if shadow acne appears
- Shadow fade start: `1.0` if max distance covers the whole scene (prevents fade-out)

### WorldEnvironment Ambient Light

Ambient light simulates indirect/bounced light, filling shadows so they aren't pure black. Without it, surfaces not hit by DirectionalLight3D are completely black.

**Ambient + directional ratio controls mood:**
- High ambient energy → flat, evenly lit (overcast)
- Low ambient energy → dramatic, high-contrast (dungeon with one torch)

**Practical settings for dungeon:**
- Source: Color (no sky in dungeon)
- Color: Warm dark grey, e.g., `Color(0.15, 0.12, 0.1)` for torchlit, cool grey for moonlight
- Energy: 0.3–0.5 for dramatic shadows
- Tonemap: Filmic (`tonemap_mode = 2`) prevents color blowout

### Shadow Bias vs. Normal Bias

Both fix shadow acne (self-shadowing artifacts), but they work differently:

- **`shadow_bias`** — Offsets the shadow map lookup. Simple but causes **peter-panning** (shadow detaches from object) at high values.
- **`shadow_normal_bias`** — Offsets along the surface normal. Much better at eliminating acne with minimal peter-panning. Preferred fix. Use values ~10x smaller than you would for regular bias.

### Common Shadow Issues

| Problem | Cause | Fix |
|---------|-------|-----|
| Shadow acne (shimmering dots) | shadow_bias too low | Increase `shadow_normal_bias` first (preferred), then `shadow_bias` |
| Peter-panning (shadow floats away) | shadow_bias too high | Decrease `shadow_bias`; rely on `shadow_normal_bias` instead |
| Everything too dark | Low ambient + low light energy | Increase ambient energy or light energy |
| Flat/no shadows visible | Shadows not enabled, or ambient too high | `shadow_enabled = true`; reduce ambient energy |
| Shadow cut-off at distance | shadow_max_distance too low | Increase `directional_shadow_max_distance` |
| Grainy/noisy shadow edges | shadow_blur too high | Reduce `shadow_blur`; also affects performance |
| Performance drop with many tiles | PSSM 4 splits + many meshes | Switch to PSSM 2 or Orthogonal; reduce max distance |

---

## Environment & Post-Processing

### Ambient Light Source Enum

| Value | Name | Use case |
|-------|------|----------|
| 0 | Background | Uses sky/background as ambient source |
| 1 | Disabled | No ambient light |
| 2 | Color | Flat color fill — best for dungeons with no sky |
| 3 | Sky | Uses sky resource |

### Background Mode Enum

| Value | Name | Use case |
|-------|------|----------|
| 0 | Clear Color | Uses project clear color (default) |
| 1 | Custom Color | Solid color via `background_color` |
| 2 | Sky | Uses a Sky resource |
| 3 | Canvas | Shows 2D canvas behind 3D |
| 4 | Keep | Keeps previous frame (for custom effects) |
| 5 | Camera Feed | Uses camera input |

### Tonemap Modes

| Value | Name | Notes |
|-------|------|-------|
| 0 | Linear | No tonemapping (default) |
| 1 | Reinhard | Soft rolloff |
| 2 | Filmic | Prevents color blowout, good for stylized |
| 3 | ACES | Film industry standard |
| 4 | AgX | Newer alternative to ACES |

### Reflected Light Source Enum

| Value | Name |
|-------|------|
| 0 | Background |
| 1 | Disabled |
| 2 | Sky |

### Fog Mode Enum

| Value | Name | Notes |
|-------|------|-------|
| 0 | Exponential | Density-based, uniform in all directions (default) |
| 1 | Depth | Distance from camera only |

### Glow Blend Mode Enum

| Value | Name |
|-------|------|
| 0 | Additive |
| 1 | Screen |
| 2 | Softlight |
| 3 | Replace |
| 4 | Mix |

---

## GL Compatibility Renderer Limitations

The project uses `gl_compatibility`. This affects which visual features actually work.

### Confirmed Working

| Feature | Notes |
|---------|-------|
| DirectionalLight3D (all properties) | Shadow mapping uses multi-pass sRGB blending (visual diff vs Forward+) |
| Soft shadow filter quality | Project setting applies correctly |
| Ambient light (source, color, energy) | Full support |
| Tonemap | Works but operates on LDR data (limited range vs Forward+) |
| Basic distance fog | `fog_enabled`, `fog_light_color`, `fog_density` |
| Background mode/color | Full support |
| DOF (depth of field) | Implemented in gles3 |
| Environment adjustments (brightness, contrast, saturation) | Applied via tonemap UBO pass |

### Not Available (Forward+ Only)

| Feature | Status |
|---------|--------|
| SDFGI | Forward+ only, no-op stubs in gles3 |
| Volumetric fog | Forward+ only |
| SSR (screen-space reflections) | Forward+ only |
| SSIL (screen-space indirect lighting) | Forward+ only |
| VoxelGI | Forward+ only |
| `light_angular_distance` (PCSS soft shadows) | Forward+ only — silently ignored |

### Disputed (Test Before Relying)

| Feature | Notes |
|---------|-------|
| SSAO | Source code has references in gles3 renderer, but a proposal says it's not implemented. Test in your build. |
| Glow | Source shows ~50 references in gles3. May work with LDR limitations. Test in your build. |

Setting `ssao_enabled = true` or `glow_enabled = true` is syntactically valid but may have zero visual effect under gl_compatibility. The properties are silently ignored if unsupported.

---

## .tscn Editable Properties Reference

These are **safe edits** per [tscn-edit-safety.md](tscn-edit-safety.md) — changing property values on existing nodes/sub_resources. Properties at default values are omitted from .tscn files. Adding a line sets a non-default value.

### DirectionalLight3D Node Properties

```
[node name="DirectionalLight3D" type="DirectionalLight3D" parent="."]
transform = Transform3D(...)
light_color = Color(1, 0.95, 0.85, 1)
light_energy = 1.2
shadow_enabled = true
shadow_bias = 0.05
shadow_normal_bias = 3.0
shadow_blur = 0.5
shadow_opacity = 0.85
directional_shadow_mode = 1
directional_shadow_max_distance = 40.0
directional_shadow_fade_start = 1.0
directional_shadow_blend_splits = true
```

| Property | Type | Default | Valid values |
|----------|------|---------|-------------|
| `light_energy` | float | `1.0` | 0+ |
| `light_color` | Color | `Color(1, 1, 1, 1)` | Any Color |
| `light_specular` | float | `1.0`* | 0–1 |
| `shadow_enabled` | bool | `false` | |
| `shadow_bias` | float | `0.1` | 0+ |
| `shadow_normal_bias` | float | `2.0`* | 0+ |
| `shadow_blur` | float | `1.0` | 0+ |
| `shadow_opacity` | float | `1.0` | 0–1 |
| `directional_shadow_mode` | int | `2` | 0=Orthogonal, 1=PSSM 2, 2=PSSM 4 |
| `directional_shadow_max_distance` | float | `100.0` | 0+ |
| `directional_shadow_fade_start` | float | `0.8` | 0–1 |
| `directional_shadow_split_1` | float | `0.1` | 0–1 |
| `directional_shadow_split_2` | float | `0.2` | 0–1 |
| `directional_shadow_split_3` | float | `0.5` | 0–1 (PSSM 4 only) |
| `directional_shadow_blend_splits` | bool | `false` | |
| `shadow_pancake_size` | float | `20.0` | 0+ (flattens shadow casters to reduce artifacts) |
| `sky_mode` | int | `0` | 0=Light+Sky, 1=Light Only, 2=Sky Only |
| `light_intensity_lux` | float | `100000.0` | Physical light units (DirectionalLight3D uses lux; Omni/Spot use lumens) |

*\*DirectionalLight3D overrides the Light3D base defaults for `shadow_normal_bias` (1.0→2.0), `light_specular` (0.5→1.0), `directional_shadow_max_distance` (0→100.0), and `directional_shadow_fade_start` (1.0→0.8).*

### Environment Sub-Resource Properties

```
[sub_resource type="Environment" id="Environment_abc12"]
background_mode = 1
background_color = Color(0.1, 0.1, 0.15, 1)
ambient_light_source = 2
ambient_light_color = Color(0.25, 0.2, 0.18, 1)
ambient_light_energy = 0.5
tonemap_mode = 2
tonemap_exposure = 1.2
fog_enabled = true
fog_light_color = Color(0.3, 0.25, 0.35, 1)
fog_density = 0.02
```

| Property | Type | Default | Valid values |
|----------|------|---------|-------------|
| `background_mode` | int | `0` | 0=Clear Color, 1=Custom Color, 2=Sky, 3=Canvas, 4=Keep, 5=Camera Feed |
| `background_color` | Color | `Color(0, 0, 0, 1)` | Only visible when mode=1 |
| `ambient_light_source` | int | `0` | 0=Background, 1=Disabled, 2=Color, 3=Sky |
| `ambient_light_color` | Color | `Color(0, 0, 0, 1)` | |
| `ambient_light_energy` | float | `1.0` | 0–16 |
| `tonemap_mode` | int | `0` | 0=Linear, 1=Reinhard, 2=Filmic, 3=ACES, 4=AgX |
| `tonemap_exposure` | float | `1.0` | 0+ |
| `fog_enabled` | bool | `false` | |
| `fog_mode` | int | `0` | 0=Exponential, 1=Depth |
| `fog_light_color` | Color | `Color(0.518, 0.553, 0.608, 1)` | Note: property is `fog_light_color`, not `fog_color` |
| `fog_density` | float | `0.01` | 0+ |
| `ssao_enabled` | bool | `false` | May not work in gl_compatibility |
| `ssao_radius` | float | `1.0` | 0.01–16 |
| `ssao_intensity` | float | `2.0` | 0–16 |
| `glow_enabled` | bool | `false` | May not work in gl_compatibility |

### What Cannot Be Edited Outside the Editor

| Thing | Why |
|-------|-----|
| GridMap tile placement (`PackedInt32Array` data) | Binary-encoded cell data |
| MeshLibrary contents (`mesh_library.tres`) | Complex binary with mesh refs, collision, item IDs |
| Add/remove nodes | Forbidden — requires `[node]` entries with unique_ids |
| Add/remove sub_resources | Forbidden — requires unique IDs and ordering |
| Add/remove ext_resources | Forbidden — requires unique IDs and UID matching |
| Collision shape geometry | Must create StaticBody3D + CollisionShape3D in editor |
| Mesh swaps (placeholder → imported) | Requires new ext_resource reference |
| SpriteFrames creation | Editor-only resource |

---

## project.godot Rendering Settings

Under `[rendering]` section. The `rendering/` prefix is implicit (stripped from the key).

```ini
[rendering]
lights_and_shadows/directional_shadow/size=4096
lights_and_shadows/directional_shadow/soft_shadow_filter_quality=2
lights_and_shadows/directional_shadow/16_bits=true
lights_and_shadows/positional_shadow/atlas_size=4096
lights_and_shadows/positional_shadow/soft_shadow_filter_quality=2
```

| Key | Type | Default | Valid values |
|-----|------|---------|-------------|
| `lights_and_shadows/directional_shadow/size` | int | `4096` | 256–16384 |
| `lights_and_shadows/directional_shadow/soft_shadow_filter_quality` | int | `2` | 0=Hard, 1=Soft Very Low, 2=Soft Low, 3=Soft Medium, 4=Soft High, 5=Soft Ultra |
| `lights_and_shadows/directional_shadow/16_bits` | bool | `true` | |
| `lights_and_shadows/positional_shadow/atlas_size` | int | `4096` | 256–16384 |
| `lights_and_shadows/positional_shadow/soft_shadow_filter_quality` | int | `2` | Same enum as directional |

---

## .import File Settings (3D Scenes)

Under `[params]` section. Editing outside the editor is safe — Godot 4.3+ auto-detects changes and reimports when the editor regains focus.

See [godot-import-settings.md](godot-import-settings.md) for the full reference. Key settings for low-poly vertex-colored models:

```ini
[params]
nodes/apply_root_scale=true
nodes/root_scale=1.0
meshes/ensure_tangents=false
meshes/generate_lods=false
meshes/create_shadow_meshes=true
meshes/light_baking=1
animation/import=false
fbx/importer=0
```

| Key | Type | Default | Recommended override | Why |
|-----|------|---------|---------------------|-----|
| `meshes/generate_lods` | bool | `true` | **`false`** | Destroys low-poly geometry |
| `meshes/ensure_tangents` | bool | `true` | **`false`** | No normal maps on vertex-colored models |
| `meshes/light_baking` | int | `1` | `1` (Static) | 0=Disabled, 1=Static, 2=Static Lightmaps, 3=Dynamic |
| `animation/import` | bool | `true` | **`false`** | Static props have no animations |
| `nodes/root_scale` | float | `1.0` | `0.5` for Quaternius FBX | Quaternius is 2x at meter scale |
| `fbx/importer` | int | `0` | `0` (ufbx) | Native importer, preserves vertex colors |
| `gltf/naming_version` | int | `2` | `2` (Godot 4.5+) | 0=Godot 4.0-4.1, 1=4.2-4.4, 2=4.5+ |
| `gltf/embedded_image_handling` | int | `1` | `0` for vertex-colored | 0=Discard, 1=Extract Textures, 2=Embed as Basis Universal, 3=Embed as Uncompressed |

**Additional FBX-specific settings** (beyond `fbx/importer`):
- `fbx/allow_geometry_helper_nodes` — bool, default `false`
- `fbx/embedded_image_handling` — same enum as glTF (default `1`)
- `fbx/naming_version` — same enum as glTF (default `2`)

### Corrections to godot-import-settings.md

The verification against Godot 4.6-stable source found 3 inaccuracies in [godot-import-settings.md](godot-import-settings.md):

1. **`meshes/light_baking`** (line 29): Lists only values 0, 1, 2. Missing value `3` = Dynamic.
2. **`gltf/naming_version`** (line 73): Descriptions slightly stale. Actual: `1` = "Godot 4.2 to 4.4", `2` = "Godot 4.5 or later".
3. **`gltf/embedded_image_handling`** (line 74): Values 2 and 3 incorrectly described. Actual: `2` = "Embed as Basis Universal", `3` = "Embed as Uncompressed".

---

## Sources

### Official Godot Documentation
- [3D Lights and Shadows](https://docs.godotengine.org/en/stable/tutorials/3d/lights_and_shadows.html)
- [Environment and Post-Processing](https://docs.godotengine.org/en/stable/tutorials/3d/environment_and_post_processing.html)
- [Using GridMaps](https://docs.godotengine.org/en/stable/tutorials/3d/using_gridmaps.html)
- [DirectionalLight3D Class Reference](https://docs.godotengine.org/en/stable/classes/class_directionallight3d.html)
- [Light3D Class Reference](https://docs.godotengine.org/en/stable/classes/class_light3d.html)
- [Environment Class Reference](https://docs.godotengine.org/en/stable/classes/class_environment.html)
- [StandardMaterial3D](https://docs.godotengine.org/en/stable/tutorials/3d/standard_material_3d.html)
- [Import Configuration](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/import_configuration.html)

### Godot Source Code (4.6-stable)
- [light_3d.cpp](https://github.com/godotengine/godot/blob/4.6-stable/scene/3d/light_3d.cpp) — DirectionalLight3D default overrides
- [environment.h](https://github.com/godotengine/godot/blob/master/scene/resources/environment.h) — Environment enum definitions
- [rasterizer_scene_gles3.cpp](https://github.com/godotengine/godot/blob/4.6-stable/drivers/gles3/rasterizer_scene_gles3.cpp) — GL Compatibility feature implementation
- [editor_scene_importer_ufbx.cpp](https://github.com/godotengine/godot/blob/4.6-stable/modules/fbx/editor/editor_scene_importer_ufbx.cpp) — FBX import settings
- [editor_scene_importer_gltf.cpp](https://github.com/godotengine/godot/blob/4.6-stable/modules/gltf/editor/editor_scene_importer_gltf.cpp) — glTF import settings

### Community Resources
- [Vertex Coloring Primer](https://vertexcoloring.webflow.io/)
- [Low-poly lighting setup — Godot Forums](https://godotforums.org/d/21876-light-and-environment-setup-for-3d-low-poly-style-game)
- [Vertex colors in Godot 4 — Godot Forum](https://forum.godotengine.org/t/how-to-display-vertex-colors-in-godot-4-for-cool-retro-3d-look/126993)
- [GL Compatibility tracker — #66458](https://github.com/godotengine/godot/issues/66458)
- [SSAO proposal for Compatibility — #12059](https://github.com/godotengine/godot-proposals/issues/12059)

### Godot Issues & PRs
- [MeshLibrary item ID stability — #83272](https://github.com/godotengine/godot/issues/83272)
- [MeshLibrary export ignores parent transforms — #96357](https://github.com/godotengine/godot/issues/96357)
- [Shadow bias scaling — PR #68339](https://github.com/godotengine/godot/pull/68339)
- [GridMap editable shortcuts — PR #79529](https://github.com/godotengine/godot/pull/79529)
- [Auto reimport .import files — Proposal #10264](https://github.com/godotengine/godot-proposals/issues/10264) (completed)
- [Glow in Compatibility — #66455](https://github.com/godotengine/godot/issues/66455)

### Internal References
- [tscn-edit-safety.md](tscn-edit-safety.md) — Rules for safe .tscn editing outside the editor
- [godot-import-settings.md](godot-import-settings.md) — Full .import file reference (has known inaccuracies noted above)
