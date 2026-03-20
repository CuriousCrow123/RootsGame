# Brainstorm: Incorporating Best Practices into Context

**Date:** 2026-03-20
**Origin:** 23 conventions extracted from `docs/plans/2026-03-20-refactor-pre-phase4-cleanup-plan.md`
**Status:** All three destinations complete.

## What We're Building

A structured placement strategy for 23 best practices discovered during the pre-Phase 4 cleanup plan. The goal is to make these conventions reliably available to Claude without bloating CLAUDE.md or diluting its instruction budget.

## Why This Approach

Research shows CLAUDE.md has a ~100 line effective budget before instruction dilution. The project was at 47 lines before this work. Rather than dumping all 23 patterns into CLAUDE.md, we split by scope and delivery mechanism:

- **CLAUDE.md** — 4 Godot-universal additions (per the plan's Phase 5) — **DONE**
- **godot-patterns skill references** — ~8 Godot-universal patterns that enhance the plugin for all projects — **DONE**
- **`.claude/rules/`** — ~8 project-specific patterns, auto-injected when touching relevant files — **DONE**

## Key Decisions

### 1. Three-destination split

| Destination | Scope | Loaded when | Count |
|---|---|---|---|
| CLAUDE.md | Godot-universal, always relevant | Every session | 4 additions |
| godot-patterns references | Godot-universal, domain-specific | On-demand via skill | ~8 patterns |
| `.claude/rules/` | RootsGame-specific | Auto, when touching matching files | ~8 patterns |

### 2. CLAUDE.md gets the plan's 4 additions as-is — DONE

Implemented in refactor commit `7d64be1`. All 4 additions landed:
- `await get_tree().scene_changed` over `process_frame` counting (Godot 4.5+)
- `call_deferred()` required for tree mutations in `_ready()`
- Persistent UI as autoloads, not reparented scene children
- Saveable group contracts (`"saveable"` for disk, `"interactable_saveable"` for session state)

CLAUDE.md is now at ~57 lines — well within budget.

### 3. godot-patterns reference updates (Godot-universal) — DONE

These patterns improve the plugin for any Godot 4 project:

**timing-async.md additions:**
- `scene_changed` signal fires after all new scene `_ready()` callbacks (source: `scene_tree.cpp`)
- `scene_changed` does NOT fire for manual `remove_child`/`add_child` scene swaps
- Old scene is already freed when `scene_changed` fires
- `add_child()` in autoload `_ready()` triggers child `_ready()` synchronously
- `preload()` in autoloads is safe for `.tscn` files (no circular dep risk)
- Catch-up pattern: after connecting to a signal in `_ready()`, check if the event already happened

**scene-architecture.md additions:**
- Persistent UI belongs in autoloads (not reparented children) to survive scene transitions
- HUD autoload extends Node, not CanvasLayer, when children already are CanvasLayers
- `_input()` reverse autoload order — last in project.godot receives input first

**resource-system.md additions:**
- Defensive `.duplicate(true)` when passing Dictionaries between systems (not just Resources)

### 4. `.claude/rules/` files (RootsGame-specific, 3 files) — DONE

Created with corrected `paths:` frontmatter (not `globs:` — see Assumptions section). Also added the `Variant` → `Dictionary` cast pattern to autoload-patterns.md.

**`.claude/rules/autoload-patterns.md`** (paths: `scripts/autoloads/**`)
- Autoload order: EventBus → GameState → DialogueManager → WorldState → SceneManager → SaveManager → HUD
- WorldState restore must happen AFTER `scene_change_completed` (snapshot() clobber risk)
- Identity checks (`node == WorldState`) over string comparison for saveable skip logic
- `player_registered` signal lives on SceneManager (owns lifecycle), not EventBus
- `load_save_data()` replaces entire state, not merge (avoids stale data)
- Intermediate typed variable for untyped Dictionary values before passing to typed parameters

**`.claude/rules/ui-patterns.md`** (paths: `scripts/ui/**`, `scenes/ui/**`)
- UI scripts expose `connect_to_player(player)` — called by HUD, not self-connected
- No reparenting in `_ready()` — HUD autoload owns instantiation
- `.call()` for duck-typed `connect_to_player()` from HUD (strict typing compliance)

**`.claude/rules/interactable-patterns.md`** (paths: `scripts/interactables/**`, `scenes/interactables/**`)
- Two-tier groups: `"saveable"` (disk, SaveManager iterates) vs `"interactable_saveable"` (session, WorldState iterates)
- Same three-method duck-typed contract: `get_save_key()`, `get_save_data()`, `load_save_data()`
- Defensive `.duplicate(true)` when WorldState passes data to interactables
- Chests call `WorldState.set_state()` immediately on interaction for session state

### 5. `.claude/rules/` format — CORRECTED

The actual Claude Code format uses `paths:` (not `globs:` or `description:`):

```markdown
---
paths:
  - "scripts/autoloads/**"
---

# Autoload Patterns

- Rule 1
- Rule 2
```

Rules without `paths:` load unconditionally. Rules with `paths:` only load when Claude reads files matching those patterns.

## Implementation Notes (from refactor session)

- **CLAUDE.md additions landed cleanly** — no instruction conflicts, budget still healthy
- **Additional pattern discovered:** When extracting values from untyped `Dictionary` (e.g. `data["world_state"]`), strict typing requires an intermediate typed variable (`var world_data: Dictionary = data["world_state"]`) before passing to a typed parameter. This is a candidate for `.claude/rules/autoload-patterns.md` or a general strict-typing rule.
- **`project.godot` autoload registration** was done by editing the file directly (not in editor). Godot accepted the changes. The `.uid` sidecar files were auto-generated on next engine run.

## Assumptions — Resolved

- **`.claude/rules/` frontmatter format**: VERIFIED. Uses `paths:` (YAML list), not `globs:`. No `description:` field. Rules without `paths:` load unconditionally. Corrected in all created files.
- **godot-patterns reference budget**: Still applies when this work is done. Current files are ~100 lines each. Additions should keep each file under ~130 lines.
- **godot-patterns updates are strictly additive**: Still applies. Do not refactor existing content while adding new patterns.
