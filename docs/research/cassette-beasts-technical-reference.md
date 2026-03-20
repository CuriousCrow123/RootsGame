# Cassette Beasts: Technical Reference

Comprehensive technical breakdown of how Cassette Beasts was built in Godot, sourced from official blog posts, developer interviews, modding documentation, wiki pages, and community analysis.

**Developer:** Bytten Studio (Jay Baylis - art/design, Tom Coxon - programming)
**Publisher:** Raw Fury
**Release:** PC April 26, 2023; Xbox/Switch May 25, 2023

---

## 1. Engine Version

- **Godot 3.5.1** (confirmed by modding documentation and Tom Coxon)
- Godot 3.5 branch; later 3.x versions untested, Godot 4.0 incompatible
- Development began well before Godot 4 existed
- **Custom engine binary**: the shipped game includes engine modifications for performance and stability. The decompiled/vanilla Godot 3.5.1 version has "odd bugs and crashes that aren't in the official builds"
- Reportedly the **first Godot game released on Xbox**

**Sources:**
- [Modding:Mod Developer Guide](https://wiki.cassettebeasts.com/wiki/Modding:Mod_Developer_Guide) ("Download Godot 3.5.1. Later 3.x versions are untested, and 4.0 is incompatible.")
- [Godot Showcase Interview](https://godotengine.org/article/godot-showcase-cassette-beasts/)
- [Tom Coxon Mastodon Thread](https://mastodon.gamedev.place/@tccoxon/111058979731909271) ("a 2.5D open world RPG that shipped this year on Steam, Switch and Xbox" using "Godot 3.5")

---

## 2. Rendering Pipeline

### Camera and Projection
- **Fixed camera angle** with a top-down-ish perspective
- 3D world (or "2.5D") -- the fixed camera and grid-based terrain mean "maps are mostly designed as if for a 2D top-down game"
- Likely **orthographic projection** (consistent with the pixel-art aesthetic and fixed scale, though not explicitly confirmed)

### Resolution and Viewport
- Supports flexible resolution settings; players can render at lower resolution and the game scales up to fill the screen
- Supports 16:10 aspect ratios
- "Lower CPU Usage" world streaming setting available for performance-constrained devices (Steam Deck runs well on High settings)

### Graphics API
- Godot 3.5 ships with both GLES3 and GLES2 renderers
- AMD GPU driver versions 25.10.2+ cause sprite rendering problems; shader cache stored at `%localappdata%\AMD\` (GLCache folder)
- Intel integrated GPU drivers known to crash in specific locations

### Visual Style
- Described as "GBA HD" -- a 3D reimagining of GBA-era RPGs, similar to how Octopath Traveller reimagines SNES RPGs
- "HD-2D aesthetic" combining Earthbound-like 2D sprites with 3D backgrounds
- Voxel-based 3D tiles provide a pixel-art-compatible look; seamless texturing when voxel tiles adjoin

**Sources:**
- [Technical Look: The Park](https://www.cassettebeasts.com/2021/08/09/technical-look-the-park/)
- [Troubleshooting Wiki](https://wiki.cassettebeasts.com/wiki/Troubleshooting)

---

## 3. Level/World Construction

### GridMap System
- Uses **Godot's GridMap** node -- "3-dimensional versions of tilemaps used in 2D games"
- GridMaps automatically **batch draw calls** for their meshes
- GridMaps make **physics setup easy** -- collision shapes come with the tile meshes
- **No autotiling** -- the developers "learned to live with" manual placement of corner tiles and transition tiles between themes (grass, snow, etc.)
- Tom Coxon **modified Godot's GridMap source code** to optimize for their open-world use case

### Chunk System
- Overworld split into a **16x8 grid of chunks**, each chunk containing **32x32 tiles**
- Total world size: roughly **twice the size of A Link to the Past's Hyrule**
- A **position-monitoring script** tracks the player and handles:
  - Loading chunks from disk
  - Instancing chunk scenes
  - Adding visible chunks to the scene tree
  - Unloading distant chunks
- The chunk system "partially works in the editor" -- developers can preview individual chunks with surrounding context visible
- "Lower CPU Usage" setting adjusts world streaming aggressiveness for low-end hardware

### Design Workflow
1. **High-level design first** -- low-detail overworld layouts to prevent cascading errors
2. Multiple review iterations on area sketches
3. **Flow network tracing** -- identifying routes through spaces; loops and one-way paths create perceived spaciousness despite compact dimensions
4. Build **GridMap geometry** first
5. Add **functional elements** (puzzles, chests, spawners)
6. Place **decorations** (grass, trees) last to minimize repositioning

### Elevation/Height
- GridMap is inherently 3D, so height variation is handled by placing tiles at different Y levels
- The fixed camera angle means elevation is perceived as vertical offset in the 2D-like view
- Specific elevation system details not publicly documented beyond standard GridMap Y-axis placement

**Sources:**
- [Technical Look: The Park](https://www.cassettebeasts.com/2021/08/09/technical-look-the-park/)
- [Godot Showcase Interview](https://godotengine.org/article/godot-showcase-cassette-beasts/)

---

## 4. Voxel Pipeline

### Authoring Tool
- **Qubicle** voxel editor for creating 3D tile models
- "Exports to Godot with little issue"

### Workflow
1. Create voxel models in Qubicle
2. Export (likely as `.obj` or scene format compatible with Godot 3.x)
3. Import into Godot as mesh resources
4. Assemble into a **MeshLibrary** for GridMap use
5. Place tiles in the GridMap editor

### Tile Characteristics
- Voxel art style matches pixel art characters -- consistent low-res aesthetic
- Tiles texture seamlessly when placed adjacent to each other
- Tiles include collision shapes for physics
- Specific voxel dimensions per tile not publicly documented

**Sources:**
- [Technical Look: The Park](https://www.cassettebeasts.com/2021/08/09/technical-look-the-park/)

---

## 5. Character Rendering (Overworld)

### 2D-in-3D Approach
- **2D pixel art sprites** rendered in the 3D world
- Almost certainly using **Sprite3D** nodes (Godot's built-in node for rendering 2D textures in 3D space)
- Billboard behavior keeps sprites facing the camera
- Characters described as "Earthbound-like 2D sprites"

### Animation
- Pixel art animations created in **Aseprite** (or LibreSprite as free alternative)
- Animations exported as **PNG sprite sheets + JSON metadata** files
- JSON contains animation tag data (tag names, frame ranges)
- Frame timing: **100ms per frame** (Aseprite default)
- Animation tags used: idle, walk, run, and directional variants

### Direction Handling
- Multiple directional sprites for overworld movement (likely 4 or 8 directions, standard for the genre)
- Specific direction count not documented, but sprite sheets on The Spriters Resource show multiple directional frames

**Sources:**
- [Monster Making Guide Part 1](https://wiki.cassettebeasts.com/wiki/Modding:Monster_Making_Guide_Part_1)
- [The Spriters Resource](https://www.spriters-resource.com/pc_computer/cassettebeasts/)

---

## 6. Monster/Battle Sprites

### Battle Sprite Format
- **PNG sprite sheet** paired with **JSON metadata file** (same filename, different extensions)
- Created in Aseprite/LibreSprite with animation tags
- Frame timing: 100ms per frame

### Required Battle Animations (via tags)
| Tag | Frames | Notes |
|-----|--------|-------|
| `idle` | 6-8 | Looping idle animation |
| `alt_idle` | varies | Alternate idle with extra action, ~25% chance to play |
| `windup` | 6-8 | Precedes attack animation |
| `attack` | varies | Returns to idle after |
| `hurt` | 3 | Dramatic reaction to damage |
| `sleep_idle` | varies | Can duplicate idle with closed eyes |
| `sleep_alt_idle` | varies | Can duplicate alt_idle with closed eyes |

### Sprite Guidelines
- Idle animation must be **centered** in the frame
- Floor-standing sprites aligned to **bottom pixels**
- Export with **merge duplicates** enabled
- Fixed column layout for "square-ish" sheets
- **1-pixel border/spacing** to prevent pixel bleeding
- Light assumed from **top-right** of sprite
- One level of shading with occasional highlights

### Fusion Sprite System
- Every monster is designed **twice**: once as a bespoke animated character, and again as a **modular character** with separate parts
- Each monster has a **fusion config file** -- a 2D Godot `.tscn` scene defining "parts" with coordinates
- **Mandatory parts**: Body, Head, HelmetFront, HelmetBack, Arm_Back, Arm_Front, Tail (optional), BackLeg_Front, BackLeg_Back, FrontLeg_Front (optional), FrontLeg_Back (optional)
- **Required coordinate nodes** (3): `attack` (emission point), `hit` (impact placement), `eye` (eye-targeting moves)
- **Fusion generation**: primary monster's config used as base, parts swapped with secondary monster's fusion config
- **Color palette**: 3-color palette system pulled from both fusion participants at runtime
- All fusion part animations are **6 frames** (except `hurt` at 3 frames) to maintain sync
- Result: **14,400+ unique fusions** from ~120 base monsters

**Sources:**
- [Monster Making Guide Part 1](https://wiki.cassettebeasts.com/wiki/Modding:Monster_Making_Guide_Part_1)
- [Monster Making Guide Part 2](https://wiki.cassettebeasts.com/wiki/Modding:Monster_Making_Guide_Part_2)

---

## 7. NPC System

### Overworld Encounters
- **No random encounters** -- all monsters are visible in the overworld
- Rangers (NPC trainers) have **line-of-sight triggers** -- walking into their "direction eyesight" auto-initiates battle
- Monster spawners placed as functional elements in the chunk design phase

### NPC Architecture
- NPCs exist as scene instances within chunks
- Specific NPC node structure not publicly documented
- Modders have created systems to populate the world with active NPCs that "simulate player behavior" (indicating the base system supports dynamic NPC behavior)

**Sources:**
- [Godot Showcase Interview](https://godotengine.org/article/godot-showcase-cassette-beasts/)

---

## 8. Lighting and Shaders

### Pixel Art Aesthetic
- The voxel-tile 3D world provides inherent pixel-art compatibility
- 2D sprites rendered via Sprite3D maintain their pixel-art look
- Specific custom shader details not publicly documented

### Overworld Shadows
- Configurable "Overworld Shadows" graphics setting (can be toggled off for performance)
- Implies a shadow-casting light in the overworld scene

### Post-Processing
- Specific post-processing pipeline not publicly documented
- Godot 3.5 provides built-in WorldEnvironment with Bloom, DOF, SSAO, and tone mapping
- The consistent visual style suggests some post-processing for color grading

**Sources:**
- [Troubleshooting Wiki](https://wiki.cassettebeasts.com/wiki/Troubleshooting)

---

## 9. Physics/Collision

- GridMap tiles include **built-in collision shapes** -- "makes setting up the physics of tiles super easy"
- Godot 3.5 uses **KinematicBody** for character movement (Godot 3.x equivalent of CharacterBody3D)
- Godot's built-in physics engine (GodotPhysics) used -- no evidence of third-party physics middleware
- The grid-based world simplifies collision; most collision is tile-aligned

**Sources:**
- [Technical Look: The Park](https://www.cassettebeasts.com/2021/08/09/technical-look-the-park/)

---

## 10. Scene Transitions / World Streaming

### Chunk Loading System
- Position-monitoring script handles dynamic chunk loading/unloading
- Chunks are loaded, instanced, and added to the scene tree as the player moves
- "Lower CPU Usage" world streaming mode reduces loading aggressiveness
- The system works "partially in the editor" for development preview

### Battle Transitions
- Battles triggered by line-of-sight (rangers) or overworld monster contact
- Specific transition implementation (screen effect, scene swap, viewport approach) not publicly documented

### Interior/Location Transitions
- The game has distinct locations (towns, caves, overworld areas)
- Likely uses standard Godot scene changes or additive loading
- Marshland Caves added as a "hidden location" in update 1.2

**Sources:**
- [Technical Look: The Park](https://www.cassettebeasts.com/2021/08/09/technical-look-the-park/)
- [Troubleshooting Wiki](https://wiki.cassettebeasts.com/wiki/Troubleshooting)

---

## 11. Save System

### File Format
- Save files use **`.json.gz.gcpf`** extension
- Underlying format is **compressed JSON** (gzip-compressed, with a custom container format)
- System creates `.bak` and `.tmp` backup files during saves for corruption recovery

### Save Locations
| Platform | Path |
|----------|------|
| Windows (Steam) | `C:\Users\<username>\AppData\Roaming\CassetteBeasts\` |
| Windows (MS Store/Game Pass) | `C:\Users\<username>\AppData\Local\Packages\RawFury.CassetteBeasts_9s0pnehqffj7t\SystemAppData\wgs\` |
| Linux | `~/.local/share/CassetteBeasts/` |

### Save State Architecture
- `SaveState.item_rand` tracks persistent RNG state across operations
- Mod metadata includes `Save File Format Tag` and `Save File Format Version` for compatibility tracking

**Sources:**
- [Troubleshooting Wiki](https://wiki.cassettebeasts.com/wiki/Troubleshooting)
- [RNG Exploration Gist](https://gist.github.com/Corvimae/9ab80702fda7671ddbb6d8de88b7f65d)
- [Mod Developer Guide](https://wiki.cassettebeasts.com/wiki/Modding:Mod_Developer_Guide)

---

## 12. Dialogue System

### Translation Key Approach
- Dialogue uses **translation keys** rather than inline text
- Keys follow `SCREAMING_SNAKE_CASE` format (e.g., `GO_CATCH_MONSTER`)
- In GDScript: `tr("GO_CATCH_MONSTER")` retrieves localized text
- Resources and nodes reference keys wherever user-facing text appears

### Translation File Format
- **CSV files** for translation tables
- First column: translation keys
- Subsequent columns: language translations (`en`, `fr`, etc.)
- Created in LibreOffice Calc, imported into Godot editor
- Added to `metadata.tres` file's `Translations` array

### Mod Namespacing
- Mod translation keys should include mod name prefixes to prevent conflicts across multiple installed mods

**Sources:**
- [Modding:Translations](https://wiki.cassettebeasts.com/wiki/Modding:Translations)
- [Mod Developer Guide](https://wiki.cassettebeasts.com/wiki/Modding:Mod_Developer_Guide)

---

## 13. Audio

### Soundtrack
- Composed by **Joel Baylis**, vocals by **Shelby Harvey**
- 74 tracks, 167 minutes total
- Style: "somewhere between a role-playing game soundtrack and an 80's synth rock album"

### Technical Implementation
- Uses **Godot's built-in audio system** (no evidence of FMOD or other middleware)
- Tom Coxon reported **thread-safety bugs in Godot's audio system** that required workarounds
- Audio-related engine bugs were among the stability issues requiring custom engine patches

### Known Issues
- Thread-safety issues with audio reported as a significant source of bugs
- Part of the reason the game ships with a custom engine binary

**Sources:**
- [Godot Showcase Interview](https://godotengine.org/article/godot-showcase-cassette-beasts/)
- [Tom Coxon Thread](https://threadreaderapp.com/thread/1702007493046526206.html)

---

## 14. Performance Optimizations

### Custom Engine Modifications
- Tom Coxon **patched Godot's source code** in multiple places
- "Cassette Beasts actually hit several of those poor-performance cases in Godot, and I had to patch engine code in a few places to claw back a few frames"
- GridMap code specifically optimized for their open-world use case
- Godot being open source was the key enabler: "Godot being open source gave them ways to address this that other engines don't"

### GridMap Optimizations
- Custom GridMap modifications to reduce unnecessary computation and memory footprint
- Standard GridMap is designed for general use; their modifications specialized it for streaming open-world chunks

### Draw Call Batching
- GridMap automatically batches draw calls for tile meshes -- this is a built-in Godot feature they leveraged

### Chunk-Based Streaming
- 16x8 grid of 32x32-tile chunks prevents loading the entire world at once
- Dynamic loading/unloading based on player position
- "Lower CPU Usage" setting for constrained hardware

### GDScript Performance
- "Pure scripting rarely became a performance bottleneck during development"
- **One performance-critical area required C++ implementation** rather than GDScript
- GDScript's reference counting avoids garbage collection pauses that affect C#-based engines

### Memory Management
- GDScript uses **reference counting + manual memory management** rather than garbage collection
- "Unity devs using C# jump through tons of hoops just to avoid garbage collection, whilst the reference counting and manual memory management options that GDScript has built-in completely side-step it"
- Chunk streaming manages memory by only holding nearby chunks in the scene tree

**Sources:**
- [Godot Showcase Interview](https://godotengine.org/article/godot-showcase-cassette-beasts/)
- [Tom Coxon Thread](https://threadreaderapp.com/thread/1702007493046526206.html)
- [Technical Look: The Park](https://www.cassettebeasts.com/2021/08/09/technical-look-the-park/)

---

## 15. Modding Support

### Mod Loading Architecture
- Uses **`ProjectSettings.load_resource_pack()`** to load mods as `.pck` files at startup
- Mods loaded before gameplay begins via `init_content` callback
- "It doesn't (and can't) know if two mods replace the same resource before irreversibly loading them both"

### Mod Package Structure
```
res://mods/<mod_name>/
  metadata.tres          # ContentInfo resource
  (mod resources, scripts, scenes)
```

### ContentInfo Metadata Fields
- ID, Name, Version Code/String, Author
- Save File Format Tag/Version
- Network Protocol Tag (for multiplayer compatibility)
- Modified Files & Modified Dirs lists
- Translations array

### Critical Constraints
- **`project.godot` conflicts**: only one mod at a time can modify it; the export tool does NOT pack project.godot changes
- **No `class_name`**: relies on project.godot paths, breaks when loaded as a mod
- **No autoloads**: same project.godot dependency
- **Resource redirection**: `Resource.take_over_path()` for overriding existing resources
- **Best practice**: "prefer alternatives to redirecting" to maintain mod compatibility

### Development Workflow
1. Download Godot 3.5.1
2. Use **Godot RE Tools** (GDRE) to decompile the game into a workspace
3. Create/modify resources in the Godot editor
4. Export mod as `.pck` file
5. Test via the editor or by placing `.pck` in the game's mod folder

### Platform Limitations
- Mods only work on **Windows and Linux**, not consoles

### Testing Tools (built into the game)
- `res://tools/custom_battle/CustomBattle.tscn` -- battle testing
- `res://tools/monster_preview/MonsterPreview.tscn` -- sprite preview
- `res://tools/battle_vfx_preview/BattleVfxPreview.tscn` -- animation/VFX testing

**Sources:**
- [Mod Developer Guide](https://wiki.cassettebeasts.com/wiki/Modding:Mod_Developer_Guide)
- [Mod User Guide](https://wiki.cassettebeasts.com/wiki/Modding:Mod_User_Guide)
- [Modding Best Practices Gist](https://gist.github.com/l4ssc/353928317a7f5342b8cd9864790894cc)

---

## 16. Battle System Architecture

### Type/Chemistry System
- **14 elemental types**: Beast, Fire, Ice, Lightning, Plant, Air, Water, Earth, Poison, Metal, Plastic, Astral, Glass, Glitter
- Type chart is a **lookup matrix** comparing attack type vs. defender type
- Four outcomes: Buff (green), Debuff (red), Transmutation (yellow), No effect (blank)
- **Typeless moves** (e.g., Smack, Spit) inherit typing from the attacking monster
- **Glitter special behavior**: attacks transmute defender to Glitter; Glitter defenders transmute to the attacker's type

### Data Organization
- Battle moves stored at `res://data/battle_moves/` as `.tres` resources
- Monster species identified by **filename** (not bestiary index number)
- Moves use array/dictionary-based resource pools for effects

### RNG System
- `Random.new(seed_value)` class with deterministic seeding
- Child seeds via `Random.child_seed(seed_value, key_string)`
- Hash-based: `var seed_final = key.hash() ^ seed_value`
- Loot tables as preloaded `.tres` resources (e.g., `chest_station.tres`)
- `SaveState.item_rand` for persistent RNG tracking
- Bootleg mechanics via `rand.rand_bool(bootleg_rate)`

### Character/Tape System
- Characters loaded from resource files with `tapes` array (monster roster)
- Stickers (moves) assigned via `assign_initial_stickers()`
- Grade/stat system with `stat_increments` and grade resets

**Sources:**
- [RNG Exploration Gist](https://gist.github.com/Corvimae/9ab80702fda7671ddbb6d8de88b7f65d)
- [Mod Developer Guide](https://wiki.cassettebeasts.com/wiki/Modding:Mod_Developer_Guide)

---

## 17. Console Porting

- **Pineapple Works** handled Switch and Xbox ports
- Ported to: Xbox One, Xbox Series S/X, Microsoft Store, Nintendo Switch
- Cassette Beasts is reportedly the **first Godot game on Xbox**
- Console porting acknowledged as "a significant challenge with Godot"
- Console versions required the custom engine binary with performance/stability patches

**Sources:**
- [Pineapple Works](https://pineapple.works/project/cassette-beasts/)
- [Godot Showcase Interview](https://godotengine.org/article/godot-showcase-cassette-beasts/)
- [Tom Coxon Thread](https://threadreaderapp.com/thread/1702007493046526206.html)

---

## 18. GDScript Patterns and Architecture

### Language Advantages (per Tom Coxon)
- **No garbage collector** -- reference counting + manual memory management
- **Native VM integration** with engine types, no translation layers
- **Syntactical sugar** for node retrieval by path
- Pure scripting "rarely became a performance bottleneck"
- Writing engine plugins is "super simple"

### Known Constraints
- `class_name` breaks in mod contexts (project.godot dependency)
- Autoloads similarly break in mods
- JSON-format animations can cause decompilation errors with GDRE tools
- One performance-critical system required dropping to C++

### Engine Stability Notes
- Thread-safety issues in resource loading and audio systems
- "Crashes reported over a year ago that haven't been fixed, in aspects that should have thread-safety"
- Godot described as "remarkably stable" overall for a community-driven project

**Sources:**
- [Tom Coxon Thread](https://threadreaderapp.com/thread/1702007493046526206.html)
- [Godot Showcase Interview](https://godotengine.org/article/godot-showcase-cassette-beasts/)

---

## 19. Art Production Pipeline

### Monster Art
- Jay Baylis handled primary art/design
- Sami Briggs and other freelance artists contributed specific character designs
- Jay used **Blender** for rough proxy rigs as animation reference (particularly for human figures)
- Monster pixel art follows consistent guidelines: top-right lighting, one level of shading, occasional highlights

### Overworld Tiles
- Created in **Qubicle** voxel editor
- Exported and imported into Godot as mesh resources
- Assembled into MeshLibrary for GridMap

### Animation Pipeline
- **Aseprite/LibreSprite** for pixel art animation
- Tagged animations exported as PNG + JSON
- 100ms per frame standard timing
- Specific tag names required by the engine (idle, attack, hurt, etc.)

**Sources:**
- [Jay Baylis Blog Posts](https://www.cassettebeasts.com/author/jaybaylis/)
- [Monster Making Guide Part 1](https://wiki.cassettebeasts.com/wiki/Modding:Monster_Making_Guide_Part_1)

---

## 20. Multiplayer

- Local co-op mode added in May 2024 update
- Second player controls the partner character
- Controller assignment via LB + RB during pause
- Network Protocol Tags in mod metadata determine multiplayer compatibility
- Mods that change battle systems, character cosmetics, or multiplayer modes must update their protocol tag

**Sources:**
- [Cassette Beasts Showcase](https://wiki.cassettebeasts.com/wiki/Cassette_Beasts_Showcase)
- [Mod Developer Guide](https://wiki.cassettebeasts.com/wiki/Modding:Mod_Developer_Guide)

---

## Summary of Gaps

These areas have limited or no public documentation:

- **Exact viewport resolution** (base resolution not confirmed, likely a low-res viewport scaled up)
- **Specific shader code** (no custom shaders have been publicly shared)
- **Dialogue node system** (translation keys documented, but the underlying dialogue tree/graph system is not)
- **Navigation/pathfinding** for NPCs (likely Godot built-in NavigationServer, but unconfirmed)
- **Battle transition implementation** (screen effect, scene management approach unknown)
- **Exact Qubicle export format** and MeshLibrary assembly steps
- **Tile dimensions in world units** (voxel-to-meter scale not documented)
- **Audio implementation details** beyond "Godot built-in with thread-safety workarounds"
- **Specific GridMap source code patches** (described but never shared publicly)
- **Camera projection type** (almost certainly orthographic, but never explicitly stated)
- **Post-processing pipeline** (likely exists but undocumented)

---

## Key Takeaways for RootsGame

1. **GridMap + Qubicle** is a proven pipeline for 2.5D open-world RPGs in Godot
2. **Chunk-based streaming** (16x8 grid of 32x32 tiles) handles large worlds on a 2-person team
3. **Sprite3D** for 2D characters in 3D worlds is the standard approach
4. **PNG + JSON** sprite sheet format with tagged animations works well for battle sprites
5. **Modular fusion parts** in 2D scenes enable procedural sprite generation at scale
6. **Custom engine patches** may be necessary for performance -- Godot's open source nature is the escape hatch
7. **GDScript reference counting** eliminates GC pauses that plague C# engines
8. **Translation keys** from day one prevent hardcoded string tech debt
9. **`.pck` mod loading** via `load_resource_pack()` is the Godot-native modding approach
10. **Compressed JSON** (`.json.gz`) is a practical save format
