---
title: "feat: Fake Amulet Chest Fake-Out"
type: feat
status: completed
date: 2026-03-21
origin: docs/brainstorms/2026-03-21-fake-amulet-chest-brainstorm.md
---

# Fake Amulet Chest Fake-Out

Room 1 chest gives a fake amulet, room 2 gives the real one. Nathan rejects the fake and hints to look elsewhere. Player can skip room 1 entirely.

## Acceptance Criteria

- [x] Room 1 chest gives "Fake Amulet" (`fake_amulet`) instead of the real amulet
- [x] Room 2 chest gives "Old Amulet" (`quest_amulet`) — unchanged
- [x] Nathan recognizes the fake: "That's not the right one" + hint to look elsewhere
- [x] Nathan recognizes the real amulet: existing quest completion flow works
- [x] Player can skip room 1 and go straight to room 2 — quest still completes
- [x] Player with both items: real amulet check takes priority, quest completes
- [x] Fake amulet removed from inventory when Nathan rejects it (optional: keep it)
- [x] Label3D prompt on room 1 chest still works (display_name may need updating)

## Context

The existing fetch quest has two steps: `get_amulet` → `return_amulet`. The dialogue file (`npc_greeting.dialogue`) already checks `has_item("quest_amulet")` to advance. We just need to add a `has_item("fake_amulet")` branch **before** the real check so Nathan can reject it.

No code changes needed. All changes are in resources and dialogue.

## Changes

### 1. New resource: `resources/items/fake_amulet.tres`

```tres
# Duplicate of key_item.tres with different item_id and display_name
[gd_resource type="Resource" script_class="ItemData" format=3]

[ext_resource type="Script" path="res://resources/items/item_data.gd" id="1"]

[resource]
script = ExtResource("1")
item_id = "fake_amulet"
display_name = "Fake Amulet"
description = "A cheap imitation. It doesn't hum at all."
```

### 2. Scene override: `scenes/world/test_room.tscn`

Change the chest instance's `item` property from `key_item.tres` to `fake_amulet.tres`.

### 3. Dialogue update: `resources/dialogue/npc_greeting.dialogue`

Add fake amulet rejection branch inside the `is_quest_active` block, **before** the real amulet check:

```dialogue
~ start

if is_quest_complete("fetch_amulet")
	Nathan: Thank you for the amulet! You're a true hero.
elif is_quest_active("fetch_amulet")
	if has_item("quest_amulet")
		Nathan: You found it! Wonderful!
		do advance_quest("fetch_amulet")
		do advance_quest("fetch_amulet")
		do remove_item("quest_amulet")
		Nathan: I can't thank you enough. This amulet means everything to me.
	elif has_item("fake_amulet")
		Nathan: Hmm... that's not the right one. This is a fake!
		do remove_item("fake_amulet")
		Nathan: The real amulet should be in the other room. Try looking there.
	else
		Nathan: Have you found the amulet yet? It should be in one of the chests nearby.
else
	Nathan: Welcome, traveler! I've been waiting for someone brave enough to help.
	Nathan: There's an old amulet I lost somewhere. Could you bring it to me?
	- I'll help you.
		do start_quest(quest_resource)
		Nathan: Wonderful! Check the chests in both rooms.
	- Not right now.
		Nathan: Take your time. I'm not going anywhere.
```

**Key ordering:** Check `quest_amulet` before `fake_amulet` so a player with both items completes the quest immediately.

### 4. No changes needed

- `chest_interactable.gd` — no code changes
- `quest_tracker.gd` — no code changes
- `fetch_quest.tres` — quest steps unchanged
- `inventory.gd` — no code changes
- Room 2 chest — already has `key_item.tres` (real amulet)

## Sources

- **Origin brainstorm:** [docs/brainstorms/2026-03-21-fake-amulet-chest-brainstorm.md](docs/brainstorms/2026-03-21-fake-amulet-chest-brainstorm.md) — key decisions: static placement (no randomization), dialogue-driven branching, fake item in room 1
- Existing dialogue: `resources/dialogue/npc_greeting.dialogue`
- Item resource pattern: `resources/items/key_item.tres`
- Chest implementation: `scripts/interactables/chest_interactable.gd`
