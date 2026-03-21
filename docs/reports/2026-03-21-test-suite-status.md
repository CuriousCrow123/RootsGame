# Test Suite Status Report

**Date:** 2026-03-21
**Branch:** `feat/asset-integration`
**Runner:** GUT 9.6.0, Godot 4.6.1, headless CLI

## Summary

| Metric | Before | After |
|--------|--------|-------|
| **Total tests** | 60 | 60 |
| **Passing** | 0 (parse errors) | **60** |
| **Failing** | 60 | **0** |
| **Pass rate** | 0% | **100%** |

## Results by File

| File | Tests | Status |
|------|-------|--------|
| `tests/unit/test_example.gd` | 1 | All pass |
| `tests/unit/test_game_state.gd` | 5 | All pass |
| `tests/unit/test_inventory.gd` | 10 | All pass |
| `tests/unit/test_quest_tracker.gd` | 14 | All pass |
| `tests/unit/test_player_controller.gd` | 3 | All pass |
| `tests/unit/test_save_data_contracts.gd` | 14 | All pass |
| `tests/integration/test_quest_loop.gd` | 3 | All pass |
| `tests/integration/test_save_load_cycle.gd` | 4 | All pass |
| `tests/integration/test_scene_transition.gd` | 6 | All pass |

## Fixes Applied

### Parse-time errors (tests couldn't even load)

1. **Strict typing on duck-typed calls** — `node.get_save_key()` on `Node` type fails strict typing. Fixed with `.call()` pattern per CLAUDE.md conventions.
2. **Variant subtype in assertions** — `assert_eq(dict.get("key"), value)` fails because `.get()` returns `Variant`. Fixed with typed intermediate variables.
3. **`load().new()` typing** — `load("script.gd").new()` infers `Resource`. Fixed via intermediate `GDScript` variable.
4. **Stale save format** — Tests referenced `rotation_y` in player save data, replaced by `facing_direction` in Phase 2.

### Runtime errors (tests loaded but crashed or failed)

5. **PlayerController missing children** — `PlayerController.new()` has no scene children. Created `TestHelpers.create_player()` that builds required child nodes (InteractionArea, Inventory, QuestTracker, AnimatedSprite3D with stub SpriteFrames).
6. **AnimatedSprite3D with no frames** — `play_animation("idle")` errors without SpriteFrames. Added stub animations to the test helper.
7. **QuestTracker needs on-disk resources** — `load_save_data()` calls `load(resource_path)`. Switched tests from in-memory `QuestData.new()` to `preload("res://resources/quests/fetch_quest.tres")`.
8. **Null interaction area** — Added null guard on `_interaction_area` in `PlayerController._ready()` for headless/test compatibility.

### New test infrastructure

- `tests/fixtures/test_helpers.gd` — `TestHelpers.create_player()` static helper
- `tests/fixtures/test_quest.tres` — On-disk test quest resource (not currently used; tests use the real `fetch_quest.tres`)

## Run Command

```bash
/Applications/Godot.app/Contents/MacOS/Godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests/ -gprefix=test_ -gexit
```
