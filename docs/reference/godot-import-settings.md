# Godot 4.6 Import Settings Reference

Quick-reference for `.import` file settings. Covers 3D scene imports (GLB/glTF/FBX) and texture imports (PNG).

---

## 3D Scene Import (`importer="scene"`)

### `nodes/` — Scene Node Configuration

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `root_type` | String | `""` | Override root node type. Empty = use type from file (usually `Node3D`). |
| `root_name` | String | `""` | Override root node name. Empty = use filename. |
| `root_script` | Resource | `null` | Attach a GDScript (`res://` path) to root on import. |
| `apply_root_scale` | bool | `true` | When `true`, bakes `root_scale` into mesh vertex data so root node stays at `(1,1,1)`. When `false`, applies as transform. **Must be `true` for MeshLibrary/GridMap** — MeshLibrary export ignores parent transforms. |
| `root_scale` | float | `1.0` | Multiplier on entire imported scene. Fix unit mismatches here. Kenney GLB = `1.0`, Quaternius FBX = `0.5`. |
| `import_as_skeleton_bones` | bool | `false` | Import all nodes as skeleton bones. Only for character rigs. |
| `use_name_suffixes` | bool | `true` | Enables `-col`, `-rigid`, `-navmesh`, `-loop` suffix-based node type conversion on import. |
| `use_node_type_suffixes` | bool | `true` | Uses node type info from glTF/FBX (cameras become Camera3D, lights become Light3D, etc.). |

### `meshes/` — Mesh Processing

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `ensure_tangents` | bool | `true` | Generate vertex tangents if missing. Required for normal maps. **Disable for low-poly vertex-colored models** — saves VRAM. |
| `generate_lods` | bool | `true` | Auto-generate LOD meshes via meshoptimizer. **DISABLE for low-poly assets** — aggressively removes vertices on simple geometry, creating holes/artifacts. |
| `create_shadow_meshes` | bool | `true` | Create optimized shadow-only meshes by welding vertices. Minor optimization, harmless. Set `false` if unshaded (no shadows). |
| `light_baking` | int | `1` | GI mode. `0` = Disabled, `1` = Static (default, correct for tiles), `2` = Static Lightmaps (generates UV2). |
| `lightmap_texel_size` | float | `0.2` | Lightmap UV density. Only relevant when `light_baking=2`. |
| `force_disable_compression` | bool | `false` | Disable vertex compression. Enable only if you see vertex snapping on very small meshes. |

### `skins/` — Skeletal Mesh

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `use_named_skins` | bool | `true` | Use skin names from source file. Irrelevant for props/tiles. |

### `animation/` — Animation Import

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `import` | bool | `true` | Import animations. **Set `false` for static props/tiles** — avoids importing phantom rest-pose animations. |
| `fps` | int | `30` | Keyframe baking FPS. Standard: `24`, `30`, `60`. |
| `trimming` | bool | `false` | Trim leading/trailing no-change frames. |
| `remove_immutable_tracks` | bool | `true` | Remove constant-value animation tracks. |
| `import_rest_as_RESET` | bool | `false` | Import skeleton rest pose as RESET track. Only for character rigs with AnimationTree. |

### `import_script/`

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `path` | String | `""` | Path to `EditorScenePostImport` script for post-import scene modification. |

### `materials/` — Material Handling

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `extract` | int | `0` | `0` = Keep embedded, `1` = Extract as `.tres`, `2` = Extract as `.res`. |
| `extract_format` | int | `0` | `0` = `.tres` (text, VCS-friendly), `1` = `.res` (binary, smaller). |
| `extract_path` | String | `""` | Directory for extracted materials. Empty = same as source file. |

### `_subresources`

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `_subresources` | Dictionary | `{}` | Per-subresource overrides. Nested dict keyed by resource type and name for fine-grained control. |

### `gltf/` — glTF/GLB-Specific

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `naming_version` | int | `2` | Naming convention. `0` = legacy 4.0-4.1, `1` = 4.2, `2` = current (4.3+). **Always use `2`.** |
| `embedded_image_handling` | int | `1` | `0` = Discard textures, `1` = Extract to files (default), `2` = Embed in scene, `3` = Extract + replace with refs. Use `0` for vertex-colored models. |

### `fbx/` — FBX-Specific

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `importer` | int | `0` | `0` = ufbx (built-in, recommended), `1` = FBX2glTF (legacy, requires external binary). **Always use `0`.** |

---

## Texture Import (`importer="texture"`)

### `compress/` — Compression

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `mode` | int | `0`/`2` | `0` = Lossless, `1` = Lossy, `2` = VRAM Compressed (S3TC/ETC2), `3` = VRAM Uncompressed, `4` = Basis Universal. Default is `0` for 2D, auto-detected `2` for 3D. **Use `2` for 3D model textures, `0` for pixel art sprites.** |
| `high_quality` | bool | `false` | Use BPTC (BC7) instead of S3TC. ~2x VRAM. Not needed for low-poly. |
| `lossy_quality` | float | `0.7` | Quality for lossy mode (0.0–1.0). Only applies when mode=1. |
| `normal_map` | int | `0` | `0` = Disabled, `1` = Use RGTC compression for normal maps. Only for actual normal map textures. |
| `channel_pack` | int | `0` | `0` = sRGB Friendly (color textures), `1` = Optimized (non-color data like ORM). |

### `mipmaps/` — Mipmap Generation

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `generate` | bool | varies | `true` for 3D textures (prevents shimmering at distance), `false` for 2D pixel art (keeps sharp pixels). |
| `limit` | int | `-1` | Max mipmap levels. `-1` = all. |

### `process/` — Image Processing

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `fix_alpha_border` | bool | `true` | Fill transparent pixels with nearest opaque color. Prevents dark halos on transparency. |
| `premult_alpha` | bool | `false` | Pre-multiply RGB by alpha. For specific blending modes. |
| `normal_map_invert_y` | bool | `false` | Invert Y channel. `true` for DirectX-convention normal maps → OpenGL (Godot). |
| `size_limit` | int | `0` | Max texture dimension in pixels. `0` = no limit. |

### `detect_3d/`

| Setting | Type | Default | Description |
|---------|------|---------|-------------|
| `compress_to` | int | `0` | Auto-compression when texture is detected as 3D. `0` = VRAM, `1` = Basis Universal. |

---

## Recommended Overrides for Low-Poly Asset Packs

Three settings that **must** change from defaults:

| Setting | Default | Override | Why |
|---------|---------|----------|-----|
| `meshes/generate_lods` | `true` | **`false`** | Meshoptimizer destroys low-poly geometry (100-500 tris), creating holes at normal distances. |
| `meshes/ensure_tangents` | `true` | **`false`** | Low-poly/vertex-colored models rarely use normal maps. Saves per-vertex VRAM. |
| `animation/import` | `true` | **`false`** | Static props have no animations. Prevents importing phantom rest-pose animations. |

### Full recommended `[params]` for low-poly GLB tiles

```ini
nodes/apply_root_scale=true
nodes/root_scale=1.0
meshes/ensure_tangents=false
meshes/generate_lods=false
meshes/create_shadow_meshes=true
meshes/light_baking=1
animation/import=false
gltf/naming_version=2
gltf/embedded_image_handling=1
```

### Full recommended `[params]` for low-poly FBX tiles (add to above)

```ini
fbx/importer=0
nodes/root_scale=0.5              # Quaternius FBX tiles are 2x at meter scale
```

### Texture settings for 3D model albedo PNGs

```ini
compress/mode=2                   # VRAM Compressed
mipmaps/generate=true             # Required for 3D
```

### Texture settings for 2D pixel art sprite PNGs

```ini
compress/mode=0                   # Lossless — VRAM Compressed ruins pixel art
mipmaps/generate=false            # Keep sharp pixels
```
