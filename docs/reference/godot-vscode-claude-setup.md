# Godot + VS Code Development Reference

> Extracted from multi-agent setup plan and five supporting research reports.

## Project Context

RootsGame is a Cassette Beasts-style RPG built with Godot 4 and GDScript. Development is VS Code-primary (Godot editor used only when required), on macOS.

**Constraints:** Godot 4.2+ required (headless LSP support), Godot 4.4+ preferred (UID sidecar files). GDScript only (no C#).

---

## Godot Project Initialization

### Auto-generating project.godot

Use `godot --headless --path . --quit` to auto-generate `project.godot` with correct `format=3` header. This also creates the `.godot/` import cache. Hand-writing the file risks format errors.

### Folder Structure

```
scenes/        # .tscn scene files
scripts/       # .gd script files
resources/     # .tres/.res resource files
assets/        # imported art, audio, fonts
addons/        # third-party plugins
tests/         # GUT test scripts
```

### .gitignore

```
.godot/
.import/
*.import
export/
*.exe
*.app
.env
```

### .gitattributes

```
*.tscn merge=union
*.tres merge=union
```

`merge=union` is a simple strategy. For more robust handling, consider a custom merge driver (see Embla Flatlandsmo's blog post on `.tscn` merge conflicts).

### .uid Sidecar Files (Godot 4.4+)

Immediately commit any `.uid` files generated during project init. Missing `.uid` files break resource references after clone. Godot 4.4 has a bug ([#104188](https://github.com/godotengine/godot/issues/104188)) where external renames can delete the old `.uid` without creating a new one (fixed in 4.5).

---

## VS Code Configuration

### settings.json

```json
{
  "godotTools.lsp.serverPort": 6005,
  "godotTools.lsp.headless": true,
  "godotTools.debugger.port": 6007,
  "godotTools.lsp.smartResolve": true,
  "godotTools.lsp.showNativeSymbols": true,
  "[gdscript]": {
    "editor.defaultFormatter": "geequlim.godot-tools",
    "editor.formatOnSave": true,
    "editor.tabSize": 4,
    "editor.insertSpaces": true
  },
  "files.associations": {
    "*.gd": "gdscript",
    "*.tscn": "gdscene",
    "*.tres": "gdresource",
    "*.gdshader": "gdshader"
  },
  "search.exclude": {
    ".godot/": true,
    "**/.godot": true
  }
}
```

Note: `godotTools.lsp.smartResolve` and `godotTools.lsp.showNativeSymbols` setting names are inferred from research but not confirmed against the current extension version -- verify empirically.

### launch.json

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Launch Main Scene",
      "type": "godot",
      "request": "launch",
      "scene": "main"
    },
    {
      "name": "Launch Current Scene",
      "type": "godot",
      "request": "launch",
      "scene": "current"
    },
    {
      "name": "Attach to Running Instance",
      "type": "godot",
      "request": "launch",
      "address": "127.0.0.1",
      "port": 6007
    }
  ]
}
```

### extensions.json

```json
{
  "recommendations": [
    "geequlim.godot-tools",
    "alfish.godot-files"
  ]
}
```

### Quality-of-Life Features

- Ctrl+Click `res://` paths for resource preview
- Alt+O toggles `.gd` <-> `.tscn`
- VS Code Profiles: `code --profile Godot --folder-uri /path/to/project`

---

## Godot Editor Settings (Manual, One-Time)

These must be configured in the Godot editor GUI:

1. Editor > Editor Settings > Text Editor > External: "Use External Editor" = ON
2. Exec Path: `/Applications/Visual Studio Code.app/Contents/MacOS/Electron` (macOS)
3. Exec Flags: `{project} --goto {file}:{line}:{col}`
4. Network > Language Server > Remote Port: `6005` (must match VS Code setting)
5. Text Editor > Script: enable "Auto Reload Scripts on External Change"
6. Enable "Save on Focus Loss", "Import Resources When Unfocused"
7. Code Completion Delay: `0.01`, Idle Parse Delay: `0.1`
8. Debug > Script Editor: enable "Debug With External Editor" (prevents Godot clobbering VS Code edits)

### IntelliSense Quality (Godot Project Settings)

- Debug > GDScript > Untyped Declaration: `Error` (enforces static typing)
- Language Server: enable Smart Resolve, enable Show Native Symbols

---

## LSP & Debugging Troubleshooting

| Problem | Solution |
|---------|----------|
| LSP not connecting | Delete `.godot/` folder, restart Godot, reload VS Code window (Cmd+Shift+P -> "Developer: Reload Window") |
| Function signature changes not reflected | Restart Godot (LSP caches signatures) |
| File navigation goes to wrong VS Code window | Close ALL VS Code windows before opening files from Godot (multiple instances break navigation) |
| Debug address not working | Do NOT include `http://` prefix in debug address (removed since May 2024) |
| LSP connection breaks after Godot restart | No auto-recovery; reload VS Code window |
| Headless LSP + editor-plugin addons | EditorPlugin subclasses don't initialize; degraded completions for addon-defined types |

---

## Godot Resource Reference System

### How Godot Tracks References

- There is **no central registry**. `res://` paths are scattered as plain strings across `.tscn`, `.tres`, `.gd`, `project.godot`, and `.cfg` files.
- Godot 4.4+ adds **UIDs** (`uid://abc123`) stored alongside paths in `.tscn`/`.tres` headers and in `.uid` sidecar files for scripts/shaders. Godot resolves by UID first, falls back to path. But stale paths still produce warnings.
- `preload("res://path")` is grep-findable (compile-time constant). `load("res://dir/" + name)` is **not** -- dynamic paths break silently on rename.
- Binary `.res` files cannot be text-searched. Only `.tres` (text) format is safe for external reference updates.
- After any external file operation: delete `.godot/` cache and run `godot --headless --editor --quit` to trigger reimport.

### Safe Resource Renaming Procedure

Raw `mv`/`git mv` is forbidden for Godot resource files. The safe procedure:

1. Validate both paths are `res://`-relative and target file exists
2. Move the file to the new path
3. Move the `.uid` sidecar file if present (e.g., `old.gd.uid` -> `new.gd.uid`), preserving UID content
4. Move the `.import` sidecar if present, update `source_file=` inside it
5. Grep-replace the old `res://` path with the new path across all `.tscn`, `.tres`, `.gd`, `.cfg`, and `project.godot` files -- using **whole-path matching** (not substring) to avoid collisions like `player.gd` matching inside `player_helper.gd`
6. Warn if any `load()` calls in `.gd` files use string concatenation near the old path (dynamic paths that can't be auto-updated)
7. Delete `.godot/` cache directory
8. Run `godot --headless --editor --quit` to trigger reimport

**Known limitations:**
- Godot 4.4 bug [#104188](https://github.com/godotengine/godot/issues/104188): external renames can delete old `.uid` without creating new one (fixed in 4.5)
- Cannot handle: dynamic `load()` paths with string concatenation, binary `.res` files, relative paths in `.tscn` files (rare)

---

## Godot CLI Commands Reference

| Command | Purpose |
|---------|---------|
| `godot --path . res://scenes/main.tscn` | Run a scene |
| `godot --headless --export-release "macOS"` | Export (preset name is **case-sensitive**) |
| `godot --check-only` | Lint GDScript |
| `godot --headless -d -s addons/gut/gut_cmdln.gd -gexit` | Run GUT tests |
| `godot --import --quit-after 2` | Force reimport (always use `--quit-after 2`, not `1`) |
| `godot --headless --path . --quit` | Initialize/verify project |
| `godot --headless --editor --quit` | Trigger reimport after external changes |
| `godot --version` | Verify installation |

**macOS executable path:** `/Applications/Godot.app/Contents/MacOS/Godot`

---

## Critical Godot Rules

1. Never move/rename resource files with raw `mv`/`git mv` -- use a rename procedure that updates all `res://` references
2. Static typing mandatory (`var x: int`, never `var x`)
3. Commit `.uid` sidecar files (Godot 4.4+)
4. One VS Code window per project
5. LSP port must be 6005 on both sides
6. Export preset names are case-sensitive in CLI
7. Always use `--quit-after 2` in CI, not `--quit-after 1`
8. `.gdshader` files can't be redirected to VS Code from Godot
9. `res://` is read-only at runtime -- use `user://` for saves
10. `@tool` scripts freeze editor if they infinite-loop (recover by commenting out `@tool` in VS Code)

---

## File & Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Files | `snake_case.gd` | `player_controller.gd` |
| Classes | `PascalCase` | `PlayerController` |
| Functions/vars | `snake_case` | `take_damage()` |
| Constants | `UPPER_SNAKE_CASE` | `MAX_HEALTH` |
| Signals | `past_tense_verb` | `damage_taken`, `animation_finished` |
| Nodes/Enums | `PascalCase` | `Sprite2D` |
| Autoloads | `PascalCase` service names | `EventBus`, `SaveManager` |
| @export groups | `@export_group("GroupName")` | `@export_group("Movement")` |

### GDScript Patterns

- `@onready var sprite: Sprite2D = $Sprite2D`
- `@export` grouping: `@export_group("Movement")` before related exports
- Custom Resource: `class_name MyRes extends Resource` with `@export` vars (only @export vars are serialized)
- Documentation: `##` doc comments above functions and classes
- Node lifecycle order: `_init` -> `_enter_tree` -> `_ready` -> `_process`/`_physics_process` -> `_exit_tree`

---

## .tscn Scene File Format

### Five Ordered Sections

1. File descriptor (`[gd_scene ...]`)
2. `[ext_resource]` -- references to external files
3. `[sub_resource]` -- embedded data
4. `[node]` -- scene tree nodes
5. `[connection]` -- signal connections

### Key Concepts

- **Node paths:** root has no parent; children use `parent="."`
- **ext_resource** = external files; **sub_resource** = embedded data
- **`.owner` property:** must set `node.owner = scene_root` for ALL nodes before `PackedScene.pack()` or nodes won't be saved
- `.tres` (text, git-friendly) vs `.res` (binary, faster)

### Gotchas

- Default values are stripped on save
- Comments are stripped
- Godot may not detect external changes (delete `.godot/` cache to force)

### Scene Composition via Code

```gdscript
var scene = PackedScene.new()
scene.pack(root_node)
ResourceSaver.save(scene, "res://scenes/my-scene.tscn")
```

---

## Tasks Requiring Godot Editor GUI

These cannot be automated via code or CLI:

- TileSet visual authoring
- Export template installation
- LightmapGI baking
- OccluderInstance3D baking
- Asset import settings

**Workaround:** `@tool` scripts and `EditorScript._run()` for batch operations (Ctrl+Shift+X to trigger).

---

## @tool Script Patterns

- Always guard with `Engine.is_editor_hint()` to prevent editor freezes
- Infinite loops freeze the editor permanently (recover by commenting out `@tool` in VS Code)
- `queue_free()` crashes in editor context
- No undo support
- `EditorScript._run()` for one-shot batch operations

---

## .gdshader Files

- Five shader types: Spatial, Canvas Item, Particles, Sky, Fog
- Text files, authorable in any editor
- Cannot be redirected to VS Code from Godot (GitHub proposal #1466)

---

## Animation API

- `AnimationLibrary` + `Animation` API
- `add_track()`, `track_insert_key()`
- Loop modes: `LOOP_NONE`, `LOOP_LINEAR`, `LOOP_PINGPONG`

---

## Plugin Management

CLI alternatives for addon management:
- GodotEnv `addons.jsonc`
- godam
- gd-plug

---

## Testing with GUT

```bash
godot --headless -d -s addons/gut/gut_cmdln.gd -gconfig=.gutconfig.json -gexit
```

---

## GDScript Performance & Anti-Patterns

### Performance

- Avoid `_process` when signals suffice -- signals are event-driven, `_process` runs every frame
- Use typed arrays (`Array[Type]`) for better performance and type safety
- Object pooling for frequently created/destroyed objects
- Avoid string concatenation in hot paths

### Common Anti-Patterns

- Writing to `res://` at runtime (silently fails -- use `user://` for saves)
- Untyped variables (breaks IntelliSense, hides bugs)
- Missing `@export` on properties meant to be serialized in `.tres`
- Dynamic `load()` paths with string concatenation (fragile on rename, invisible to grep)
- API keys or hardcoded user directory paths in scripts

### Recommendations

- Prefer `preload("res://path")` (compile-time, grep-findable) over `load()` with dynamic strings
- Always set `Engine.is_editor_hint()` guards in `@tool` scripts
- Never call `queue_free()` in editor context (@tool scripts)

---

## MCP & LSP Bridge Tools

### godot-mcp (@coding-solo/godot-mcp)

Provides AI tools with bidirectional Godot project access. Configured in `.mcp.json` at project root. Set `GODOT_PATH` to macOS Godot executable. Requires `project.godot` to exist.

**Risk:** npm package could break or become unmaintained. Pin version. Document manual MCP-free workflow as fallback.

### claude-code-gdscript (LSP Bridge)

Provides GDScript diagnostics, go-to-definition, hover docs, and completions to AI tools. Configure `GODOT_EDITOR_PATH` if Godot is not on PATH. Requires full restart for changes.

**Risk:** Could be incompatible with current tool versions. Standard file reading still works without it, just loses LSP intelligence.

---

## AI-Assisted Development Notes

### Orchestrator-Worker Pattern

For game dev, multi-agent architectures work well because the domains are broad and distinct (GDScript coding, scene composition, game design analysis, code review). A single-agent approach risks context pollution across these domains.

### Domain Specialization

Effective game dev agents need domain-specific knowledge:
- **Coding agents** need: Godot 4 patterns (signals, @export, @onready, typed arrays, node lifecycle), static typing enforcement, Custom Resource patterns, @tool script safety, AnimationLibrary API, .gdshader authoring
- **Scene composition agents** need: .tscn format spec (five sections), node path syntax, ext_resource vs sub_resource, `.owner` property gotcha with `PackedScene.pack()`, .uid sidecar handling, resource reference system
- **Review agents** need: performance patterns (signal vs _process, typed arrays, object pooling), anti-patterns (res:// runtime writes, untyped vars), @tool safety, resource reference safety (flag raw moves, flag dynamic load paths)
- **Design agents** should be read-only to avoid accidental changes

### Key Pitfalls

- Vague agent descriptions lead to wrong delegation -- use specific trigger phrases ("Write GDScript" -> coding agent, "Create a scene" -> scene agent)
- Skills/context that exceed ~2% of context budget get silently excluded
- Agent-generated `.tscn` files can be subtly invalid -- always validate with Godot
- AI agents can hallucinate GDScript APIs -- cross-check with LSP diagnostics when available

---

## Known Edge Cases (by Severity)

### Critical

- **LSP port mismatch** (Godot 6005 vs extension different port): IntelliSense silently fails
- **No project.godot** when tools/LSP start: "no project found" errors
- **Raw `mv` on resource files**: all `res://` references break silently

### High

- **Godot not installed or wrong path**: MCP and LSP both fail
- **LSP breaks after Godot restart**: no auto-recovery; must reload VS Code window
- **@tool script infinite loop**: editor freezes permanently
- **.uid files not committed**: broken references after clone
- **`--quit-after 1` in CI**: import incomplete, non-deterministic failures
- **Dynamic `load()` paths missed during rename**: runtime errors

### Medium

- **Godot editor overwrites VS Code edits** on script error (fix: "Debug With External Editor" setting)
- **Function signature changes**: stale LSP completions until Godot restart
- **Headless LSP + addon plugins**: degraded completions for addon types (EditorPlugin subclasses don't initialize)
- **Multiple VS Code windows**: LSP connects to wrong instance
- **Externally edited .tscn files**: Godot may not detect changes (delete `.godot/` cache to force)
- **`.uid` sidecar lost during rename** (Godot 4.4 bug #104188, fixed in 4.5)
- **Binary `.res` references invisible to grep**: breaks on rename

### Low

- **`res://` write at runtime**: silent failure (use `user://`)

---

## Open Questions

1. **Godot version**: Confirm 4.2+ installed; 4.4+ strongly preferred for `.uid` support.
2. **Headless LSP with addons**: Behavior with GUT, Dialogic, Terrain3D is unknown -- needs empirical testing.
3. **VS Code settings accuracy**: The consolidated `settings.json` template is assembled from multiple sources and should be validated empirically.

---

## Source Research Reports

- `docs/research/godot-vscode-configuration.md` -- VS Code extension setup, LSP/DAP ports, debugging (31 sources)
- `docs/research/godot-no-artist-vscode-workflow.md` -- editor-free workflows, procedural art, asset pipelines (70 sources)
- `docs/research/claude-agents-on-godot.md` -- 12+ Claude+Godot integrations, MCP servers, LSP bridge (30+ sources)
- `docs/research/prompt-engineering-context-agents.md` -- agent orchestration patterns, context management, tool design (63 sources)
- `docs/research/godot-rpg-fundamentals.md` -- Godot RPG architecture patterns

## External References

- [godot-mcp](https://github.com/Coding-Solo/godot-mcp) -- Primary MCP server (2.5k stars)
- [claude-code-gdscript](https://github.com/twaananen/claude-code-gdscript) -- GDScript LSP bridge
