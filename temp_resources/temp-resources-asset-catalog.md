# temp_resources Asset Catalog

Comprehensive inventory of all downloaded asset packs in `temp_resources/`. Assessed for compatibility with the Asset Integration Pipeline plan.

---

## Pack Summary

| # | Pack Name | Type | Format | License | Godot-Ready Format |
|---|-----------|------|--------|---------|-------------------|
| 1 | Ultimate Modular Ruins Pack | 3D environment tiles | FBX, OBJ, Blend | CC0 1.0 (public domain) | FBX imports natively in Godot 4.6 |
| 2 | Kenney Retro Urban Kit | 3D environment tiles | GLB, FBX, OBJ | CC0 1.0 (public domain) | GLB ready |
| 3 | Ultimate Animated Character Pack | 3D character models | glTF, FBX, OBJ, Blend | CC0 1.0 (public domain) | glTF ready |
| 4 | RPGMCharacter v1.0 | 2D sprite sheets | PNG (+ PSD sources) | Free — no resale | PNG ready |
| 5 | Pixel Gnome DEMO Pack | 2D sprite sheets | PNG | Free — no resale, no AI training | PNG ready |
| 6 | Shisu Character | 2D sprite sheet | PNG (+ Aseprite .ase) | Unknown (no license file) |PNG ready |
| 7 | td_char_freepack_spritesheet | 2D sprite sheet | PNG | Unknown (standalone file) | PNG ready |

---

## 1. Ultimate Modular Ruins Pack (Quaternius, Aug 2021)

**Author:** @Quaternius
**License:** CC0 1.0 — Public Domain
**Style:** Low-poly dungeon/ruins, colored materials (no textures needed except trees)

### Contents: 92 models

**Structural (walls, floors, arches):**
- Wall, Wall_Half, Wall_Broken, Wall_Double_Broken, Wall_Double_Hole, Wall_Hole, Wall_Overgrown
- Wall_ArchGothic, Wall_ArchRound, Wall_ArchRound_Broken, Wall_ArchRound_Overgrown, Wall_ArchRound_Overgrown_Broken
- Floor_Standard, Floor_Standard_Half, Floor_Diamond, Floor_Squares, Floor_SquareLarge, Floor_Tree
- Floor_Hole_Corner, Floor_Hole_Straight
- Curve_1, Curve_1_Overgrown, Curve_2, Curve_2_Overgrown
- Stairs, Stairs_2

**Arches & doorways:**
- Arch_Gothic, Arch_Gothic_RoundColumn, Arch_Round, Arch_Round_RoundColumn
- Doors_GothicArch, Doors_GothicArch_Covered, Doors_RoundArch, Doors_RoundArch_Covered

**Columns & supports:**
- Column_Round, Column_Round_Short, Column_Square, Column_BridgeSupport
- Support_Center, Support_Left, Support_Right, Support_Tall
- Rail_Corner, Rail_Divider, Rail_Straight

**Props & interactables:**
- Chest, Chest_Gold
- Barrel, Crate, Cart
- Bookcase_Empty, Bookcase_Full
- BearTrap_Closed, BearTrap_Open
- Pot1, Pot1_Broken, Pot2, Pot2_Broken, Pot3, Pot3_Broken
- Candles_1, Candles_2, Torch
- Skull, Trapdoor
- Flag_GothicArch, Flag_RoundArch, Flag_Wall, Flag_Wall2
- Statue_Fox, Statue_Stag
- BridgeSection

**Nature:**
- Tree_1, Tree_2, Tree_3, DeadTree_1, DeadTree_2, DeadTree_3
- Bush_1x1, Bush_2x1, Bush_2x2, Bush_Large, Bush_Round
- Grass, Brick, Bricks

**Windows:**
- Window_Bars, Window_Bars_Overgrown, Window_Bars_Double_Overgrown
- Window_Open, Window_Open_Double

### Formats Available
- **Blender** (.blend) — source files, 92 models
- **FBX** — 92 models
- **OBJ** (.obj + .mtl) — 92 models
- **No GLB** — would need Blender batch export for Godot-native import

### Textures
- `Bark_Texture.jpg` — tree bark
- `Leaf_Texture.png` — tree leaves
- All other models use vertex colors / material colors (no UV textures)

### Grid System
- Uses a 1x1 modular grid
- Walls require 180-degree vertical rotation on 90-degree turns for edges to fit
- Curves handle the rotation automatically (span 2 wall units)

### Relevance to Plan
- **Phase 1 (tiles):** Excellent fit — Floor_Standard, Wall, arches, stairs can build a MeshLibrary. Dungeon/ruins aesthetic.
- **Phase 3 (interactables):** Chest, Chest_Gold, Doors models are directly usable.
- **Import:** FBX files import natively in Godot 4.6 via ufbx — no conversion needed. Vertex colors preserved.

---

## 2. Kenney Retro Urban Kit (v2.0, Jan 2025)

**Author:** Kenney (kenney.nl)
**License:** CC0 1.0 — Public Domain
**Style:** Low-poly retro urban/post-apocalyptic, textured

### Contents: 124 models (+ 1 Textures folder)

**Walls (building A style — painted/unpainted variants):**
- wall-a, wall-a-painted, wall-a-flat, wall-a-flat-painted, wall-a-flat-window, wall-a-flat-garage
- wall-a-column, wall-a-column-painted, wall-a-corner, wall-a-corner-painted
- wall-a-detail, wall-a-detail-painted, wall-a-diagonal, wall-a-painted-diagonal
- wall-a-door, wall-a-garage, wall-a-low, wall-a-low-painted, wall-a-open, wall-a-window
- wall-a-roof, wall-a-roof-detailed, wall-a-roof-slant, wall-a-roof-slant-detailed

**Walls (building B style):**
- wall-b, wall-b-column, wall-b-corner, wall-b-detail-painted, wall-b-diagonal
- wall-b-door, wall-b-flat, wall-b-flat-window, wall-b-flat-garage, wall-b-garage
- wall-b-low, wall-b-open, wall-b-window
- wall-b-roof, wall-b-roof-detailed, wall-b-roof-slant, wall-b-roof-slant-detailed

**Walls (misc):**
- wall-c-flat, wall-c-flat-low, wall-fence
- wall-broken-type-a, wall-broken-type-b
- wall-type-a, wall-type-b
- wall-steps-type-a, wall-steps-type-b

**Roads (asphalt + dirt variants):**
- road-asphalt-center, road-asphalt-corner, road-asphalt-corner-inner, road-asphalt-corner-outer
- road-asphalt-damaged, road-asphalt-pavement, road-asphalt-side, road-asphalt-straight
- road-dirt-center, road-dirt-corner, road-dirt-corner-inner, road-dirt-corner-outer
- road-dirt-damaged, road-dirt-pavement, road-dirt-side, road-dirt-straight, road-dirt-tile

**Terrain:**
- grass, grass-corner, grass-corner-inner, grass-hill
- cliff-corner, cliff-side

**Details & props:**
- detail-awning-small, detail-awning-wide
- detail-barrier-type-a, detail-barrier-type-b, detail-barrier-strong-type-a, detail-barrier-strong-type-b, detail-barrier-strong-damaged
- detail-beam, detail-bench, detail-block, detail-bricks-type-a, detail-bricks-type-b
- detail-cables-type-a, detail-cables-type-b
- detail-dumpster-closed, detail-dumpster-open
- detail-light-single, detail-light-double, detail-light-traffic

**Doors & windows:**
- door-type-a, door-type-b
- window-small-type-a, window-small-type-b
- window-wide-type-a, window-wide-type-b, window-wide-type-c, window-wide-type-d

**Structures:**
- balcony-type-a, balcony-ladder-bottom, balcony-ladder-top
- roof-metal-type-a, roof-metal-type-b, roof-metal-poles
- scaffolding-floor, scaffolding-poles, scaffolding-structure
- pallet, pallet-small, planks

**Vehicles:**
- truck-flat, truck-green, truck-green-cargo, truck-grey, truck-grey-cargo

**Trees:**
- tree-large, tree-small, tree-park-large, tree-park-pine-large, tree-pine-large, tree-pine-small, tree-shrub

### Formats Available
- **GLB** — 124 models (Godot-native, preferred)
- **FBX** — 124 models
- **OBJ** — 124 models

### Textures (20 PNGs)
asphalt, bars, concrete, dirt, doors, grass, metal, metal_wall, planks, rock, roof, roof_plates, signs, tiles, treeA, treeB, truck, truck_alien, windows, wood

### Relevance to Plan
- **Phase 1 (tiles):** Viable alternative aesthetic — urban/post-apocalyptic instead of dungeon. Walls, roads, and terrain tiles are modular and GLB-ready.
- **Phase 3 (interactables):** door-type-a/b models usable. No chest model — would need to pair with Ruins pack chest.
- **Advantage:** GLB format already available, no conversion needed.

---

## 3. Ultimate Animated Character Pack (Quaternius, Nov 2019)

**Author:** @Quaternius
**License:** CC0 1.0 — Public Domain
**Style:** Low-poly 3D chibi characters, vertex-colored

### Contents: 50+ character models

**Human characters (male/female pairs):**
- Casual, Casual2, Casual3, Casual_Bald (male only)
- Suit_Male, Suit_Female
- OldClassy_Male, OldClassy_Female
- Worker_Male, Worker_Female
- Chef_Male, Chef_Female (+ Chef_Hat accessory)
- Doctor_Male_Young, Doctor_Male_Old, Doctor_Female_Young, Doctor_Female_Old

**Fantasy/RPG characters:**
- Knight_Male, Knight_Golden_Male, Knight_Golden_Female
- Wizard, Witch, Elf
- Ninja_Male, Ninja_Female, Ninja_Male_Hair, Ninja_Sand, Ninja_Sand_Female
- Viking_Male, Viking_Female (+ VikingHelmet accessory)
- Pirate_Male, Pirate_Female
- Cowboy_Male, Cowboy_Female (+ Cowboy_Hair accessory)
- Kimono_Male, Kimono_Female
- Soldier_Male, Soldier_Female, BlueSoldier_Male, BlueSoldier_Female

**Non-human:**
- Goblin_Male, Goblin_Female
- Zombie_Male, Zombie_Female
- Cow, Pug

**Base:**
- BaseCharacter — unclothed base mesh for customization

### Formats Available
- **glTF** (.gltf) — 52 files (Godot-importable)
- **FBX** — 50 files
- **OBJ** (.obj + .mtl) — 50+ files
- **Blender** (.blend) — 50 files

### Animations
- Pack is titled "Animated" — models include rigged armatures
- Animations are baked into the model files (idle, walk, etc. — varies by format)

### Relevance to Plan
- **Not directly usable for Phase 2 as-is.** The plan specifies AnimatedSprite3D with 2D sprite sheets, not 3D character models. These are 3D meshes.
- **Alternative approach:** Could be used as 3D characters instead of sprites (would require a different rendering strategy than the plan describes — MeshInstance3D + AnimationPlayer instead of AnimatedSprite3D).
- **NPC variety:** Excellent selection for populating a world with diverse NPCs if using 3D characters.

---

## 4. RPGMCharacter v1.0 (Szadi Art)

**Author:** Szadi Art
**License:** Free for commercial/personal use, modification allowed, no resale of assets
**Style:** Isometric pixel art, ~3/4 top-down view

### Contents: 10 sprite sheets (+ PSD sources)

| File | Dimensions | Frame Size | Frames | Rows |
|------|-----------|------------|--------|------|
| `_down idle.png` | 256x128 | 64x64 | 4+1 | 2 rows (4 top, 1 bottom-left) |
| `_down walk.png` | 256x128 | 64x64 | 4+2 | 2 rows (4 top, 2 bottom) |
| `_down attack.png` | 128x128 | 64x64 | 2+1 | 2 rows |
| `_up idle.png` | 256x128 | 64x64 | 4+1 | 2 rows |
| `_up walk.png` | 256x128 | 64x64 | 4+2 | 2 rows |
| `_up attack.png` | 128x128 | 64x64 | 2+1 | 2 rows |
| `_side idle.png` | 256x128 | 64x64 | 4+1 | 2 rows |
| `_side walk.png` | 256x128 | 64x64 | 4+2 | 2 rows |
| `_side attack.png` | 128x128 | 64x64 | 2+1 | 2 rows |
| `_pick up.png` | — | 64x64 | — | — |

### Frame Grid
- **Cell size:** 64x64 pixels per frame
- **Character height:** ~50px within the 64px cell (rest is padding/shadow)
- **Perspective:** Isometric / 3/4 view (NOT pure top-down)
- **Directions:** 3 (down, up, side) — side sprites need horizontal flip for left/right

### Animations Available
- idle (down, up, side) — ~5 frames each
- walk (down, up, side) — ~6 frames each
- attack (down, up, side) — ~3 frames each
- pick up — dedicated action

### Visual Style
- Stocky character with hat/helmet, red-brown clothing
- Clean pixel art with anti-aliased edges
- Includes drop shadow in sprites

### Relevance to Plan
- **Phase 2 (characters):** Good fit for AnimatedSprite3D. Has all required directions and animations.
- **Consideration:** Only 3 directions (need horizontal flip for left/right), which is standard for pixel art. The plan's `FacingDirection` enum supports this via mirroring.
- **Single character only** — would need additional packs for NPC variety.

---

## 5. Pixel Gnome DEMO Pack

**Author:** Pixel Gnome (itch.io creator)
**License:** Free for commercial/personal — no resale, no redistribution, no AI training
**Style:** Cute pixel art, front-facing (not isometric)

### Contents: 3 animations (normal + 1000% upscaled versions)

| File | Dimensions | Frame Layout |
|------|-----------|-------------|
| `Idle - Still.png` | 80x192 | 1 column x 3 rows (3 facing directions) |
| `Walk.png` | 320x192 | 4 columns x 3 rows (4 walk frames x 3 directions) |
| `Pickaxe.png` | 480x192 | 6 columns x 3 rows (6 pickaxe frames x 3 directions) |

### Frame Grid
- **Cell size:** ~80x64 pixels per frame (80 wide, 64 tall per direction row)
- **Character height:** ~50px within frame
- **3 directions:** down (row 1), side (row 2), back/up (row 3)
- **Side needs horizontal flip** for left vs right

### Animations Available
- idle (still frame only — no animation cycle)
- walk (4 frames)
- pickaxe/attack (6 frames)

### Visual Style
- Cute girl character with orange pigtails, blue outfit
- Clean pixel art, larger sprites than RPGMCharacter
- Front-facing perspective (not isometric)

### Relevance to Plan
- **Phase 2 (characters):** Usable but limited — demo pack only has 3 animations. Idle is a single frame (no cycle). No dedicated idle animation loop.
- **Style mismatch concern:** Front-facing perspective vs RPGMCharacter's isometric view — these two packs would look inconsistent together.

---

## 6. Shisu Character

**Author:** Unknown
**License:** No license file found — use with caution
**Style:** Tiny pixel art character, side-view

### Contents

| File | Dimensions | Notes |
|------|-----------|-------|
| `Shisu_Model-Sheet.png` | 288x96 | Sprite sheet |
| `Shisu_Model.ase` | — | Aseprite source file |

### Frame Grid
- **Cell size:** ~24x32 pixels per frame (estimated from 288x96 with ~12 frames)
- **2 rows:** 7 frames top row, 5 frames bottom row
- **Character height:** Very small (~20px)

### Visual Style
- Tiny blue character with hat, side-scrolling style
- Very small resolution — designed for pixel-perfect 2D, not 3D billboard

### Relevance to Plan
- **Phase 2:** Poor fit — only side-view, no directional variants, very small sprite, side-scroller style. Not suitable for a top-down/isometric RPG.

---

## 7. td_char_freepack_spritesheet.png (standalone)

**Author:** Unknown (filename suggests "top-down character free pack")
**License:** Unknown — no license file
**Style:** Top-down pixel art, multiple characters

### Specifications
- **Dimensions:** 320x448 pixels
- **Grid:** 5 columns x 7 rows = 35 frames
- **Cell size:** 64x64 pixels per frame
- **Contains:** 2 different characters (top 3 rows = character 1 dark outfit, bottom 4 rows = character 2 blue outfit)

### Frame Layout (visual analysis)
- **Row 1-2:** Character 1 — facing down (idle/walk frames, 4-5 frames)
- **Row 3:** Character 1 — facing up/side variations
- **Row 4-5:** Character 2 — facing down (idle/walk frames)
- **Row 6:** Character 2 — facing up/side + casting animation
- **Row 7:** Character 2 — additional animations (possibly attack/cast)

### Visual Style
- Top-down / 3/4 view pixel art
- Two distinct characters with different outfits
- Clean style, moderate detail
- Drop shadows present

### Relevance to Plan
- **Phase 2 (characters):** Potentially usable — top-down perspective matches. Would need to slice into individual SpriteFrames.
- **Concern:** No license information. Multiple characters in one sheet need careful frame slicing.

---

## Import Pipeline: No Conversion Needed

**Key finding: Godot 4.6 natively imports FBX, OBJ, glTF/GLB, and .blend files.** The ufbx importer (added in Godot 4.3) handles FBX directly with vertex colors, animations, and skeletons. This eliminates the need for any external conversion tools.

### What this means for each pack

| Pack | Format to Use | Action |
|------|--------------|--------|
| **Ruins Pack** | FBX (native import) | Copy FBX files directly into project — Godot auto-imports |
| **Kenney Urban** | GLB (native import) | Copy GLB files directly — already Godot-preferred format |
| **Quaternius Characters** | glTF (native import) | Copy glTF files directly — Godot imports natively |
| **2D Sprite Packs** | PNG (native import) | Copy PNGs directly — standard texture import |

### Why NOT to use external CLI converters

The original plan specified ".glb preferred" but that was written without considering Godot 4.6's native FBX import. Research into CLI conversion tools found significant problems:

| Tool | Status | Critical Issue |
|------|--------|---------------|
| **FBX2glTF** (Meta) | Abandoned (last release 2019). Godot fork also abandoned. | Loses vertex colors — **breaks Quaternius packs** |
| **obj2gltf** (Cesium) | Vertex color bug open since 2017, never fixed | Models turn grey/white — **breaks Quaternius packs** |
| **assimp** | Active but unreliable materials | GLB output often has broken texture references |
| **gltf-pipeline** (Cesium) | Only repackages glTF/GLB, not a converter | Draco compression not supported by Godot |
| **trimesh** (Python) | No FBX support, no animation support | Wrong tool for gamedev |

**The vertex color constraint is critical.** Quaternius packs (Ruins + Characters) use vertex colors instead of texture atlases. Most CLI converters either drop or corrupt vertex colors. Godot's native ufbx importer handles them correctly (sRGB/linear color space issue was fixed in Godot PR #82994).

### If you ever DO need GLB conversion

**Blender CLI headless** (`blender --background --python script.py`) is the community-consensus tool. It's heavy (~500MB) but handles every edge case the lightweight tools miss — vertex colors, animations, materials, PBR. All community threads (Reddit r/godot, Godot forums) converge on this as the answer.

**gltfpack** (meshoptimizer) is useful as a post-import optimization step — mesh simplification, vertex cache optimization — but is not a format converter.

### Recommended import workflow

```
1. Copy source files into assets/ directory (FBX, GLB, glTF, or PNG)
2. Godot auto-imports on next editor open
3. Configure import settings in Godot's Import dock if needed:
   - Vertex colors: enable "Colors" checkbox (for Quaternius FBX)
   - Texture filter: Nearest (for pixel art sprites)
   - Scale: verify 1:1 with GridMap cell size
4. Done — no external tools required
```

---

## Compatibility Matrix (vs. Asset Integration Pipeline Plan)

### Phase 1: Environment Tiles (GridMap MeshLibrary)

| Pack | Fit | Format | Notes |
|------|-----|--------|-------|
| **Ruins Pack** | Excellent | FBX (Godot imports natively) | Dungeon aesthetic, 92 modular pieces, 1x1 grid, has floors + walls + stairs + arches |
| **Kenney Urban** | Good | GLB (ready) | Urban aesthetic, 124 pieces, walls + roads + terrain. Different vibe. |

**Recommendation:** Ruins Pack is the better thematic fit for an RPG. Kenney works for exterior/town areas. Both import directly into Godot — no conversion needed.

### Phase 2: Character Sprites (AnimatedSprite3D)

| Pack | Fit | Directions | Animations | Notes |
|------|-----|-----------|------------|-------|
| **RPGMCharacter** | Best 2D fit | 3 (flip for 4th) | idle, walk, attack, pick up | 64x64 frames, isometric style |
| **td_char_freepack** | Decent | ~4 | idle, walk, cast | 64x64 frames, 2 characters, no license |
| **Pixel Gnome** | Limited | 3 | idle (1 frame), walk, pickaxe | Different perspective than RPGMCharacter |
| **Shisu** | Poor | Side only | Unknown | Too small, wrong perspective |
| **Quaternius Characters** | Alternative approach | N/A (3D) | Rigged + animated | Would require changing plan from AnimatedSprite3D to 3D character rendering |

**Recommendation:** RPGMCharacter is the strongest 2D option. Only provides 1 character though — need another source for NPCs. The Quaternius 3D character pack is a viable alternative if you pivot to 3D characters instead of 2D sprites (50+ character variety vs 1).

### Phase 3: Interactable Models

| Pack | Chest | Door | Other |
|------|-------|------|-------|
| **Ruins Pack** | Chest, Chest_Gold | Doors_GothicArch, Doors_RoundArch (+ covered variants) | Barrel, Crate, Bookcase, Cart, Pot, Trapdoor, BearTrap |
| **Kenney Urban** | None | door-type-a, door-type-b | dumpster, bench, barrier, pallet |

**Recommendation:** Ruins Pack covers both chest and door needs. Kenney supplements with urban props if needed.

---

## Format Compatibility Summary (Godot 4.6)

| Format | Godot 4.6 Import | Quality | Notes |
|--------|-----------------|---------|-------|
| .glb | Native, first-class | Best | Recommended by Godot docs. Self-contained binary. |
| .gltf | Native, first-class | Best | Same as GLB but text-based with external buffers. |
| .fbx | Native via ufbx (since 4.3) | Full | Vertex colors, animations, skeletons all supported. |
| .obj | Native, limited | Static only | No animations, skeletons, UV2, or PBR materials. Fine for static props. |
| .blend | Transparent via Blender | Full | Requires Blender installed. Godot exports to glTF in background. |
| .png | Native texture import | Standard | Standard for sprites. Configure filter/mipmap in Import dock. |
| .ase | Not supported | N/A | Export from Aseprite to PNG first. |
| .psd | Not supported | N/A | Source files only — not for import. |

---

## License Summary

| Pack | License | Commercial Use | Attribution Required |
|------|---------|---------------|---------------------|
| Ruins Pack | CC0 1.0 | Yes | No (appreciated) |
| Kenney Urban | CC0 1.0 | Yes | No (appreciated) |
| Quaternius Characters | CC0 1.0 | Yes | No (appreciated) |
| RPGMCharacter | Custom free | Yes | No (appreciated) |
| Pixel Gnome | Custom free | Yes | No (appreciated) |
| Shisu Character | **Unknown** | **Unclear** | **Unknown** |
| td_char_freepack | **Unknown** | **Unclear** | **Unknown** |
