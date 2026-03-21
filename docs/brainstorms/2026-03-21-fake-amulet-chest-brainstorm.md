# Fake Amulet Chest — Brainstorm

**Date:** 2026-03-21
**Status:** Brainstorm complete

## What We're Building

A two-room fetch quest fake-out: room 1's chest contains a fake amulet, room 2's chest contains the real one. Nathan rejects the fake if brought to him, hinting to try the other room. Player can skip room 1 entirely if they already know.

**Flow:**
1. Nathan gives quest ("find my old amulet")
2. Player opens chest in room 1 → gets "Fake Amulet"
3. Player brings fake to Nathan → "That's not it, try looking elsewhere"
4. Player opens chest in room 2 → gets real "Old Amulet"
5. Player brings real amulet to Nathan → quest complete
6. (Shortcut: player can go straight to room 2 and skip steps 2-3)

## Why This Approach

**Dialogue-driven branching** — no new systems, no new code. The existing dialogue system already supports `has_item()` checks against the Inventory. All branching lives in the `.dialogue` file.

**Alternatives considered:**
- Quest step gating (extra steps like `reject_fake` → `return_real`): adds quest step complexity for no gameplay benefit. The dialogue file handles branching more naturally.
- Randomized chest placement: over-engineered for the current two-room layout. Static placement is simpler and the "puzzle" is the same — check both rooms.

## Key Decisions

1. **No randomization** — fake is always in room 1, real is always in room 2. Static `@export var item` on each chest.
2. **Dialogue-driven flow** — Nathan's dialogue checks `has_item("fake_amulet")` and `has_item("quest_amulet")` to branch responses. No code changes to quest_tracker or chest_interactable.
3. **Fake item is a new ItemData resource** — `resources/items/fake_amulet.tres` with `item_id = "fake_amulet"` and `display_name = "Fake Amulet"`.
4. **Player keeps both items** — the fake stays in inventory (Nathan doesn't take it). Could optionally be removed via `remove_item()` in dialogue.
5. **Room 1 chest has fake, room 2 chest has real** — set via scene property overrides on the existing chest instances.
6. **Player can skip room 1** — going straight to room 2 works. Nathan's dialogue checks for the real amulet first, so having both items still completes the quest.

## Changes Needed

- **New resource:** `resources/items/fake_amulet.tres` (ItemData with `item_id = "fake_amulet"`)
- **Scene override:** Room 1 chest's `item` export changed from `key_item.tres` to `fake_amulet.tres`
- **Dialogue update:** `resources/dialogue/npc_greeting.dialogue` — add branch for `has_item("fake_amulet")` before `has_item("quest_amulet")`
- **Quest steps:** No changes needed — existing two-step quest (`get_amulet` → `return_amulet`) works as-is

## Open Questions

None — all questions resolved during brainstorming.
