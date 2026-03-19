# RootsGame — Godot 4 + GDScript RPG

A Cassette Beasts-style RPG built with Godot 4 and GDScript. VS Code-primary development on macOS.

## Godot Constraints

- **Minimum Godot version:** 4.6 (project targets 4.6.1; `.uid` sidecars are stable)
- **Language:** GDScript only (no C#)
- **Static typing is mandatory.** Every variable, parameter, and return type must be explicitly typed. Set `UNTYPED_DECLARATION`, `UNSAFE_PROPERTY_ACCESS`, `UNSAFE_METHOD_ACCESS`, and `UNSAFE_CALL_ARGUMENT` to Error in Project Settings > Debug > GDScript.
- **Composition over inheritance.** Limit scene inheritance to one layer. Compose entities from single-purpose child nodes. Derive only from engine node types (CharacterBody2D, Area2D, etc.).
- **"Call down, signal up."** Parents call methods on children. Children emit signals. Siblings communicate through a shared parent. The Event Bus autoload is for genuinely cross-system events only (player death, quest completion).
- **Resource safety:**
  - Never use raw `mv` or `git mv` on resource files — always update all `res://` references across `.tscn`, `.tres`, `.gd`, `.cfg`, and `project.godot`.
  - Call `.duplicate()` on any `.tres` Resource that will be mutated at runtime — Godot shares loaded Resources by path.
  - Prefer `preload()` over dynamic `load()` with string concatenation.
- **`.tscn` files are read-only for agents.** Scene files have strict structure (five ordered sections, unique ext_resource IDs). Naive edits corrupt scenes. Agents must never edit `.tscn` files directly.

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
