# Test Suite Status Report

**Date:** 2026-03-21
**Branch:** `feat/asset-integration`
**Runner:** GUT 9.6.0, Godot 4.6.1, headless CLI

## Summary

| Metric | Value |
|--------|-------|
| **Total scripts** | 9 |
| **Total tests** | 60 |
| **Passing** | 46 |
| **Failing** | 14 |
| **Pass rate** | 77% |

## Results by File

| File | Pass/Total | Status |
|------|-----------|--------|
| `tests/unit/test_example.gd` | 1/1 | All pass |
| `tests/unit/test_game_state.gd` | 5/5 | All pass |
| `tests/unit/test_inventory.gd` | 10/10 | All pass |
| `tests/unit/test_quest_tracker.gd` | 13/14 | 1 failing |
| `tests/unit/test_player_controller.gd` | 0/3 | All failing |
| `tests/unit/test_save_data_contracts.gd` | 10/14 | 4 failing |
| `tests/integration/test_quest_loop.gd` | 2/3 | 1 failing |
| `tests/integration/test_save_load_cycle.gd` | 1/4 | 3 failing |
| `tests/integration/test_scene_transition.gd` | 4/6 | 2 failing |

## Fixes Applied (this session)

These were **parse-time failures** — tests could not even load before. Now they load and most pass:

1. **Strict typing on duck-typed calls** — `node.get_save_key()` on `Node` type fails strict typing. Fixed by using `.call("get_save_key")` pattern per CLAUDE.md conventions.
2. **Variant subtype in assertions** — `assert_eq(dict.get("key"), value)` fails because `.get()` returns `Variant`. Fixed by assigning to a typed intermediate variable first.
3. **`load().new()` typing** — `load("script.gd").new()` infers `Resource`, not the script type. Fixed via intermediate `GDScript` variable.
4. **Stale save format** — Tests referenced `rotation_y` in player save data, which was replaced by `facing_direction` in Phase 2. Updated tests to match.
5. **Chest child nodes** — Phase 3 added `AnimationPlayer` and `Chest_Top` dependencies to chest script. Added helper to create test chests with required children.
6. **PlayerController null guard** — Added null check on `_interaction_area` in `_ready()` so bare `.new()` instances don't crash on signal connection.

## Remaining Failures

All 14 remaining failures share **two root causes**:

### Root Cause 1: `PlayerController.new()` lacks scene children (9 tests)

**Affected tests:**
- `test_player_controller.gd` — all 3 tests
- `test_save_data_contracts.gd` — `test_player_save_key`, `test_player_position_roundtrip`
- `test_save_load_cycle.gd` — `test_full_save_load_cycle`, `test_save_load_with_empty_state`, `test_save_data_is_json_serializable`
- `test_scene_transition.gd` — `test_inventory_persists_on_player`, `test_quest_tracker_persists_on_player`

**Problem:** `PlayerController.new()` creates the script without the scene tree. The script expects `@onready` children (`$Inventory`, `$QuestTracker`, `$InteractionArea`, `$AnimatedSprite3D`) that only exist when instantiated from `player.tscn`.

**Fix:** Replace `PlayerController.new()` with `preload("res://scenes/player/player.tscn").instantiate()` in test setup. This requires verifying that the full scene works in headless GUT (autoload dependencies like `SaveManager.register()` and `SceneManager.register_player()` may need stubbing or null guards).

### Root Cause 2: QuestTracker.load_save_data() needs on-disk resources (5 tests)

**Affected tests:**
- `test_quest_tracker.gd` — `test_save_load_roundtrip`
- `test_save_data_contracts.gd` — `test_quest_tracker_roundtrip`, `test_quest_tracker_complete_roundtrip`
- `test_quest_loop.gd` — `test_save_load_mid_quest_preserves_state`
- `test_save_load_cycle.gd` — `test_full_save_load_cycle` (also affected by Root Cause 1)

**Problem:** `QuestTracker.load_save_data()` calls `load(resource_path)` to reconstruct QuestData from disk. Tests create QuestData with `.new()` — no `resource_path` exists. The save data contains `"resource_path": ""`, so `load_save_data()` skips the quest with a warning.

**Fix:** Either:
- (a) Create test `.tres` QuestData resources on disk that tests can reference, or
- (b) Modify `load_save_data()` to accept an optional in-memory registry of QuestData for testing

## Recommended Next Steps

1. **Create a `_create_player()` test helper** that uses `preload("res://scenes/player/player.tscn").instantiate()` — this fixes 9 of 14 failures in one change. May need null guards on autoload calls in `_ready()` for headless compatibility.
2. **Create test quest `.tres` files** in `tests/fixtures/` — this fixes the remaining 5 failures.
3. **Consider a `.gutconfig.json`** with `dirs = ["res://tests/"]` and `prefix = "test_"` to avoid passing CLI flags every run.
