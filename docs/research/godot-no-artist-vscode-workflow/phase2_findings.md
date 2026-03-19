# Phase 2: Merged Research Findings

**Total unique sources:** ~60 (after deduplication across facets)
**Per-facet confidence:** All high except AI_ART_TOOLS_GAMEDEV (medium)
**Blocked sources:** None reported

## Coverage Summary

| Facet | Confidence | Source Count | Key Gaps |
|-------|-----------|-------------|----------|
| FREE_GAME_ASSETS | High | 12 | Art asset packs in Godot Asset Library vs tools/plugins |
| GODOT_ASSET_LIBRARY | High | 9 | Moderation turnaround, Featured criteria |
| PROCEDURAL_PROGRAMMATIC_ART | High | 9 | Performance benchmarks, L-systems |
| VSCODE_GODOT_WORKFLOW | High | 9 | Large project performance, headless LSP details |
| GODOT_IDE_REQUIREMENTS | High | 12 | Lightmap/NavMesh baking headless, remote debugger |
| SOLO_DEV_NO_ARTIST_STRATEGIES | High | 9 | Completion rates with pre-made assets |
| AI_ART_TOOLS_GAMEDEV | Medium | 9 | Godot-specific AI import workflows, long-term consistency |

---

## FACET: FREE_GAME_ASSETS

### Summary
Solo developers have access to an extensive ecosystem of free game assets. The most reliable sources combine zero-cost access with CC0 licensing for commercial use. The landscape covers every asset type.

### Key Findings
- **Kenney.nl**: 60,000+ CC0 assets (2D, 3D, UI, audio). Individual packs free; all-in-one bundle $19.95.
- **OpenGameArt.org**: Largest open-source game asset repository. CC0, CC-BY, CC-BY-SA licenses. Quality varies.
- **itch.io**: 45,000+ free game assets, filterable by engine/license/genre.
- **Quaternius**: 70+ CC0 low-poly 3D packs with 2,500+ rigged/animated models.
- **Poly Haven**: CC0 HDRIs, 8K PBR textures, 3D models. No sign-up.
- **AmbientCG**: 1,000+ CC0 PBR materials and HDRIs. 1M+ monthly downloads.
- **Mixamo (Adobe)**: Free character animations and 3D characters with free Adobe ID. Commercial use OK.
- **CraftPix.net**: 281+ pages of free 2D assets with commercial use permission.
- **Game-icons.net**: 4,000+ SVG icons under CC BY 3.0.
- **Sketchfab**: 800,000+ CC-licensed 3D models in GLTF/OBJ/FBX.
- **Google Fonts**: Open-source fonts including pixel/retro game fonts.
- **CC-BY-SA pitfall**: ShareAlike can require all derivative content share the same license.

### Tensions
- CC-BY commercial viability debated; all agree CC0 safest
- Kenney individual packs free but all-in-one is paid
- OpenGameArt quality inconsistent vs curated sites

---

## FACET: GODOT_ASSET_LIBRARY

### Summary
The official library hosts ~4,800 assets (mostly tools/scripts, not art). A beta Asset Store launched June 2025 with plans for paid content and better UX.

### Key Findings
- 4,796 items: 2D Tools (416), 3D Tools (655), Tools (1,662), Scripts (831), Shaders (157), Templates (121), etc.
- Top plugins: Dialogic (100K+ downloads), Aseprite Wizard (50K+), Phantom Camera (25K+), Godot-SQLite (20K+)
- Plugin install: AssetLib tab → Download → enable in Project Settings → Plugins
- New Asset Store beta at store-beta.godotengine.org (June 2025), ~50 assets, plans for paid content
- Current library lacks ratings, reviews, trending — team won't improve it since Store is replacement
- awesome-godot GitHub list curates 100+ notable plugins beyond the library browser
- godotshaders.com used instead of official library for shaders
- Third-party: godotmarketplace.com, Fab.com (multi-engine, Godot support in development)

---

## FACET: PROCEDURAL_PROGRAMMATIC_ART

### Summary
Godot provides extensive built-in support for generating visuals through code: shaders, procedural meshes, noise-based generation, particles, custom 2D drawing, and procedural sky — all without artist-created files.

### Key Findings
- Five shader types: Spatial, Canvas Item, Particles, Sky, Fog — all generate visuals mathematically
- GDShader language (GLSL-like) for GPU procedural textures. One dev: "My current project uses procedural texturing almost exclusively"
- CanvasItem _draw() API: draw_line(), draw_circle(), draw_polygon(), draw_rect() etc. for fully programmatic 2D
- FastNoiseLite built-in: Perlin, Simplex, Cellular, Value noise for terrain/tilemap/biome generation
- Procedural 3D meshes: ArrayMesh, SurfaceTool, MeshDataTool, ImmediateMesh
- GPUParticles2D/3D with ShaderMaterial overrides for custom particle visuals
- godotshaders.com: dozens of ready-to-use procedural shaders (fire, fog, rain, materials)
- ProceduralSkyMaterial: full sky without HDR skybox
- Visual Shaders: node-graph interface for shaders without GLSL. ShaderV plugin adds 50+ effects
- SDF (Signed Distance Fields) for resolution-independent shapes
- GDQuest open-source PCG demos (MIT): Random Walker, noise worlds, biome maps, procedural weapons
- Tween system animates any property through code

---

## FACET: VSCODE_GODOT_WORKFLOW

### Summary
VS Code works well with the official "godot-tools" extension (597K+ installs). Provides GDScript syntax highlighting, LSP autocompletion, debugging. Godot editor must remain open or use headless LSP mode.

### Key Findings
- Official "godot-tools" extension by Godot org, v2.6.1, supports Godot 3.2+ and 4.x
- LSP over TCP (port 6005 default). Port mismatch is common setup failure
- Headless LSP mode (Godot 4.2+): windowless Godot instance serves LSP without full editor
- Static typing recommended for best IntelliSense results
- Debugger rewritten in v2.0.0: breakpoints, step-in/out/over, variable inspection, scene tree
- **CRITICAL**: Never move/rename files in VS Code — must be done in Godot to update resource refs
- .gdshader files cannot be redirected to external editor (GitHub proposal #1466 open)
- Godot can overwrite VS Code edits on script errors; mitigate with "Debug With External Editor"
- Godot Launcher can automate VS Code setup
- Function signature changes require Godot restart for LSP update
- VS Code advantages: Copilot, git integration, renaming support, extension ecosystem

---

## FACET: GODOT_IDE_REQUIREMENTS

### Summary
The editor is required for: TileSet authoring, export template installation, and visual asset import configuration. Nearly everything else has programmatic workarounds — scenes, animations, shaders, settings can all be done in code.

### Key Findings
- Scene composition: can be replicated in code via Node.new(), add_child(), property assignment
- TileSet creation/configuration: requires editor in practice. TileMap placement doable via set_cell()
- AnimationPlayer timeline: GUI-only but animations can be authored via AnimationLibrary API in code
- Asset importing: triggered by editor; .import files can be hand-edited but impractical
- **Export template installation: requires editor GUI.** No stable CLI flag. GitHub proposal #1277 open
- Export builds CAN be headless: `godot --headless --export-release "platform" /path`
- Visual Shader editor optional: .gdshader files are plain text, writable in any editor
- project.godot: plain INI format, fully hand-editable
- .tscn/.tres: human-readable text, hand-editable (but editor strips manual comments)
- @tool annotation: GDScript runs in editor, enabling plugin-based automation
- Addon installation: CLI alternatives exist (GodotEnv, godam, gd-plug)
- Godot CLI: create projects, run scenes, run scripts via command line

### Things that REQUIRE the Godot editor:
1. TileSet visual authoring (collision shapes, terrain sets)
2. Export template installation (no CLI option)
3. Asset import settings configuration (practical requirement)
4. Visual AnimationPlayer timeline (code alternative exists but complex)
5. Plugin installation from Asset Library (CLI alternatives exist)

### Things that DON'T require the editor:
1. All GDScript/C# code editing
2. Scene tree composition (via code)
3. Shader authoring (.gdshader text files)
4. Project settings (project.godot INI)
5. Scene/resource files (.tscn/.tres text editing)
6. Export builds (headless CLI)
7. Animation creation (via AnimationLibrary API)
8. Running/testing scenes (CLI)

---

## FACET: SOLO_DEV_NO_ARTIST_STRATEGIES

### Summary
Five main approaches: minimalist art styles, free CC0 asset libraries, AI art tools, designing around limited skills, and prioritizing mechanics over visuals. Intentionality and visual cohesion are key.

### Key Findings
- Pixel art in 25%+ of indie Steam games; fast iteration, cheap tools (Aseprite ~$20)
- Bass Monkey postmortem: zero-experience dev shipped in 18 months using itch.io CC0 assets
- AI tools: Leonardo AI (150 free daily tokens), PixelLab (animated sprite sheets), DeepMotion (webcam mocap)
- 73% of studios use AI tools; 88% plan to; ~40% report 20%+ productivity gains
- Minimalist styles succeed with limited palettes, geometric shapes, negative space (Thomas Was Alone, Limbo, Superhot)
- "Programmer art as prototype" recommended: prevents wasted time on cut mechanics
- Non-artist workflows: photographing objects, neural network style transfer, voxel editors (MagicaVoxel free)
- "Asset flip" label: strong negative reputation on Steam. Key distinction is original creative vision
- Midjourney paid = full commercial rights; free tier = CC BY-NC 4.0 (no commercial)
- AI outputs not copyrightable under US law unless substantially human-modified

---

## FACET: AI_ART_TOOLS_GAMEDEV

### Summary
Purpose-built platforms exist for game art generation. 2D tools (PixelLab, Leonardo.ai) are more production-ready than 3D tools (~10% of 3D outputs are client-ready without rework). Copyright concerns remain unresolved.

### Key Findings
- **PixelLab**: pixel sprite sheets, 4/8-direction rotations, animations; $9-22/month, free tier; Aseprite plugin
- **Leonardo.ai**: 150 free daily tokens, custom LoRA training for style consistency
- **Scenario**: fine-tunes Stable Diffusion on your art bible for consistent generation; $15/month+
- **Stable Diffusion**: open source, free, unlimited local generation; Fooocus for easy setup
- **Tripo AI**: best for game 3D; clean quad/triangle topology, auto-rigging, polycount controls; GLB/FBX export
- **Meshy**: best for 3D texturing but "frequently featured broken geometry" per SimInsights testing
- **SimInsights finding**: "roughly 1 in 10 [3D] generations are client-ready without rework"
- **PBR textures**: Scenario, AITextured, GenPBR generate full map sets (albedo, normal, roughness, etc.)
- **Adobe Firefly**: only major tool trained on licensed content; IP indemnification for enterprise
- **US Copyright Office (Jan 2025)**: purely AI-generated works lack copyright protection
- ~8,000 Steam games disclosed AI tool use as of mid-2025
- Studios report 60-80% reduction in art production costs
- Recommended pipeline: concepts in Leonardo/Midjourney → refine in Krita → animate with PixelLab → export
