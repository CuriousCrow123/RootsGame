# RootsGame — Godot 4 + GDScript RPG

A Cassette Beasts-style RPG built with Godot 4 and GDScript. VS Code-primary development on macOS.

## Godot Constraints

- **Minimum Godot version:** 4.6 (project targets 4.6.1; `.uid` sidecars are stable)
- **Language:** GDScript only (no C#)
- **Static typing is mandatory.** Every variable, parameter, and return type must be explicitly typed. Set `UNTYPED_DECLARATION`, `UNSAFE_PROPERTY_ACCESS`, `UNSAFE_METHOD_ACCESS`, and `UNSAFE_CALL_ARGUMENT` to Error in Project Settings > Debug > GDScript.
- **Explicit casts after `is` checks.** GDScript's type checker does NOT narrow types after `if x is SomeType`. You must cast explicitly with `var typed: SomeType = x as SomeType` before accessing subtype members — otherwise strict typing flags it as an error.
- **Always register autoloads as `.gd` with explicit `res://` paths, never `.tscn` or `uid://`.** A `.tscn` autoload causes Godot's parser to infer the singleton as `Node`, breaking `unsafe_method_access` / `unsafe_property_access` checks across every call site ([godot#86300](https://github.com/godotengine/godot/issues/86300)). UID-based registration (`uid://...`) is fragile — if `.uid` sidecar files get out of sync the autoload silently becomes `null` at runtime. If an autoload needs child nodes (CanvasLayer, ColorRect, etc.), build them programmatically in `_ready()`.
- **Use `.call()` for duck-typed group methods.** `get_nodes_in_group()` returns `Array[Node]`. Even with a `has_method()` guard, calling `node.some_method()` directly fails strict typing because `Node` doesn't declare it. Use `node.call("some_method")` instead — same pattern as `interact()` on interactables.
- **Composition over inheritance.** Limit scene inheritance to one layer. Compose entities from single-purpose child nodes. Derive only from engine node types (CharacterBody2D, Area2D, etc.).
- **"Call down, signal up."** Parents call methods on children. Children emit signals. Siblings communicate through a shared parent. The Event Bus autoload is for genuinely cross-system events only (player death, quest completion).
- **Resource safety:**
  - Never use raw `mv` or `git mv` on resource files — always update all `res://` references across `.tscn`, `.tres`, `.gd`, `.cfg`, and `project.godot`.
  - Call `.duplicate()` on any `.tres` Resource that will be mutated at runtime — Godot shares loaded Resources by path.
  - Prefer `preload()` over dynamic `load()` with string concatenation.
- **`.tscn` edits: properties only, no structural changes.** Scene files have ordered sections (`ext_resource`, `sub_resource`, `node`, `connection`) with unique IDs. Safe edits: changing property values on existing nodes/sub_resources, removing properties (reverts to default), adding properties to existing entries. **Never:** add/remove `[ext_resource]`, `[sub_resource]`, `[node]`, or `[connection]` entries (ID uniqueness, parent path integrity, UID correctness). **Never:** edit base64-encoded `PackedByteArray` data or `unique_id`/`uid` values.
- **Use `await get_tree().scene_changed` after `change_scene_to_file()`** (Godot 4.5+). Do not count `process_frame` waits — frame timing is fragile and version-dependent. `scene_changed` fires after the new scene's `_ready()` completes.
- **`call_deferred()` required for tree mutations in `_ready()`.** The scene tree is locked during `_ready()` traversal. Use `call_deferred("remove_child", node)` / `call_deferred("add_child", node)` or `node.reparent.call_deferred(new_parent)`.
- **Persistent UI as autoloads, not reparented scene children.** The HUD autoload (`hud.gd`) instantiates UI scenes as children via `preload().instantiate()`. UI scripts must not reparent themselves — they live under HUD and persist naturally. HUD uses `preload().instantiate()` (not programmatic build) because UI children are non-trivial scene trees with editor-tweakable layout.
- **Saveable contracts (enforced via registrar):**
  - Disk persistence: call `SaveManager.register(self)` in `_ready()`. Validates `get_save_key()`, `get_save_data()`, `load_save_data()` exist — asserts immediately if any are missing.
  - Session state: call `WorldState.register(self)` in `_ready()`. Same contract, same validation, for `"interactable_saveable"` group.
  - `"saveable"` group members: Player, Inventory, QuestTracker, WorldState. `"interactable_saveable"`: chests, destructibles, etc.
  - `load_save_data()` must use "clear then rebuild": `.clear()` all state first, then rebuild from save data only. Never merge with existing state — save file is the single source of truth. An empty Dictionary must reset to defaults.

## GDScript Style

- **Naming:** snake_case for files/vars/functions, PascalCase for classes/nodes, UPPER_SNAKE_CASE for constants/enums, `_prefix` for pseudo-private, `is_`/`can_`/`has_` for booleans, past-tense for signals (`damage_taken`).
- **Member ordering:** class_name/extends/docstring → signals → enums → constants → @export → public vars → _private vars → @onready → virtual methods → signal callbacks → public methods → private methods → inner classes.

## Linting

Run gdtoolkit before commits:
```bash
gdformat --check .   # formatting
gdlint .             # style rules
```
Install: `pipx install "gdtoolkit==4.*"`

## MCP & Documentation

Use Context7 automatically for Godot API lookups — call `resolve-library-id` then `query-docs`.

## Godot Compound Plugin

The `godot-compound` plugin provides Godot-specific agents, skills, and commands via the `/gc:` namespace. Installed at `~/.claude/godot-compound/`.

- **Use `/gc:` commands** for Godot work: `/gc:plan`, `/gc:work`, `/gc:review`, `/gc:compound`, `/gc:brainstorm`
- **Use `/ce:` commands** for non-Godot side projects (CE stays installed separately)
- Agent dispatch is controlled by `compound-engineering.local.md` at the project root
- **Do NOT run `/gc:setup` or `/ce:setup`** — manually maintain `compound-engineering.local.md` instead
- Compound docs use the Godot schema (`skills/compound-docs/schema.yaml` in the plugin)
