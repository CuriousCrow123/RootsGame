# Resource-Oriented Data Design

## Core Principle

Resources hold data; Nodes hold behavior. Custom `Resource` classes (`.tres` files) hold all static game data — item definitions, stat blocks, ability configs, dialogue entries. Nodes exist only where scene-tree integration (physics, rendering, delta time) is required.

## Creating Custom Resources

```gdscript
class_name ItemResource
extends Resource

@export var name: String
@export var description: String
@export var icon: Texture2D
@export var damage: int
@export var rarity: int

## Optional: emit changed signal on modification
func set_damage(value: int) -> void:
    damage = value
    emit_changed()
```

Only `@export` properties serialize to disk and appear in the inspector.

## The Sharing Pitfall (Critical)

Godot caches Resources by path and returns the same in-memory object for every `load()` call. **Runtime mutations to a shared Resource affect ALL users.**

### Mitigation

```gdscript
# WRONG: modifying a shared resource
var item: ItemResource = load("res://resources/sword.tres")
item.damage += 5  # This changes it for EVERYONE

# RIGHT: duplicate for per-instance mutation
var item: ItemResource = load("res://resources/sword.tres").duplicate()
item.damage += 5  # Only this instance is affected
```

`resource_local_to_scene` in the inspector is unreliable — documented failures in arrays, inherited scenes, and dynamic instantiation. Use `.duplicate()` in code.

## Resource vs. Node vs. RefCounted

| Class | Use When | Memory | Serialization |
|-------|----------|--------|---------------|
| Resource | Data that varies per config, no scene-tree access | Lightweight (ref-counted) | Full (.tres/.res) |
| Node | Physics, rendering, delta, scene-tree signals | Heavier (tree overhead) | Via scene (.tscn) |
| RefCounted | Ephemeral logic objects, complex return types | Lightest auto-managed | None built-in |
| Object | Maximum control, manual memory management | Lightest | None built-in |

## File Formats

- `.tres` (text): human-readable, git-friendly — use during development
- `.res` (binary): smaller, faster — use for release builds

## Loading Patterns

```gdscript
# Compile-time (grep-findable, preferred)
const SWORD: ItemResource = preload("res://resources/sword.tres")

# Runtime
var item: ItemResource = load("res://resources/sword.tres")

# Async (large resources)
ResourceLoader.load_threaded_request("res://resources/big_thing.tres")

# Save files (prevent stale cache)
ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
```

**Never use dynamic `load()` with string concatenation** — invisible to grep, breaks on rename:
```gdscript
# BAD: can't be found by search tools, breaks on rename
var item: Resource = load("res://resources/" + item_name + ".tres")

# GOOD: use preload or a lookup dictionary
const ITEMS: Dictionary = {
    "sword": preload("res://resources/sword.tres"),
    "shield": preload("res://resources/shield.tres"),
}
```

## `res://` Reference Safety

- `res://` paths are scattered as plain strings across `.tscn`, `.tres`, `.gd`, `project.godot`, and `.cfg` files
- There is NO central registry — Godot resolves by scanning
- Godot 4.4+ adds UIDs (`uid://abc123`) as stable references alongside paths
- Binary `.res` files cannot be text-searched — use `.tres` format for safety
- After external file operations: delete `.godot/` cache and run `godot --headless --editor --quit`

### Safe Rename Procedure

1. Move the file
2. Move the `.uid` sidecar if present (4.4+)
3. Move the `.import` sidecar if present
4. Grep-replace old `res://` path with new across `.tscn`, `.tres`, `.gd`, `.cfg`, `project.godot`
5. Warn about dynamic `load()` calls near the old path
6. Delete `.godot/` cache, run `godot --headless --editor --quit`

## `.uid` Sidecar Files (Godot 4.4+)

- Stored alongside scripts/shaders (e.g., `player.gd.uid`)
- Godot resolves by UID first, falls back to path
- Always commit `.uid` files — missing UIDs break references after clone
- Godot 4.4 bug #104188: external renames can delete old `.uid` without creating new one (fixed in 4.5)

## Nested Resources

`@export var items: Array[ItemResource]` serializes fully in Godot 4. Resources must NOT hold references to PackedScenes or Nodes — circular dependencies break serialization.

## Security

`.tres` files can embed and execute GDScript. Never load untrusted user-supplied `.tres` files. For save data, use `FileAccess.store_var()` / `get_var()` instead.

## RPG Data Architecture (Three Layers)

1. **Resource** — holds data (stat blocks, item definitions)
2. **RefCounted** — holds logic (status effect calculations, modifiers)
3. **Node** — holds the manager that ticks and coordinates
