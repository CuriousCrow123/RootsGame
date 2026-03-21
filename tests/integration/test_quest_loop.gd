extends GutTest
## Integration test: full quest loop with real QuestTracker and Inventory.
## Verifies signals fire in correct order across systems.

var _tracker: QuestTracker
var _inventory: Inventory
var _quest_data: QuestData = preload("res://resources/quests/fetch_quest.tres")


func before_each() -> void:
	_tracker = QuestTracker.new()
	_inventory = Inventory.new()
	add_child_autofree(_tracker)
	add_child_autofree(_inventory)


func test_full_quest_loop() -> void:
	watch_signals(_tracker)
	watch_signals(_inventory)

	# 1. Start quest via tracker
	_tracker.start_quest(_quest_data)
	assert_signal_emitted(_tracker, "quest_started")
	assert_true(_tracker.is_quest_active("fetch_amulet"))

	# 2. Simulate picking up item from chest
	_inventory.add_item("quest_amulet")
	assert_signal_emitted(_inventory, "item_added")
	assert_true(_inventory.has_item("quest_amulet"))

	# 3. Check quest condition (what dialogue would check)
	assert_true(
		_tracker.is_quest_active("fetch_amulet") and _inventory.has_item("quest_amulet"),
		"Quest active and item in inventory — NPC should recognize turn-in",
	)

	# 4. Advance quest (what dialogue do statement triggers)
	_tracker.advance_quest("fetch_amulet")
	assert_signal_emitted(_tracker, "quest_step_completed")

	# 5. Remove item (what dialogue do statement triggers alongside advance)
	_inventory.remove_item("quest_amulet")
	assert_signal_emitted(_inventory, "item_removed")
	assert_false(_inventory.has_item("quest_amulet"))

	# 6. Final advance — quest completes
	_tracker.advance_quest("fetch_amulet")
	assert_signal_emitted(_tracker, "quest_completed")
	assert_true(_tracker.is_quest_complete("fetch_amulet"))


func test_signal_order() -> void:
	var signal_log: Array[String] = []
	_tracker.quest_started.connect(func(_qid: String) -> void: signal_log.append("started"))
	_tracker.quest_step_completed.connect(
		func(_qid: String, _sid: String) -> void: signal_log.append("step_completed")
	)
	_tracker.quest_completed.connect(func(_qid: String) -> void: signal_log.append("completed"))

	_tracker.start_quest(_quest_data)
	_tracker.advance_quest("fetch_amulet")
	_tracker.advance_quest("fetch_amulet")

	assert_eq(
		signal_log,
		["started", "step_completed", "step_completed", "completed"],
		"Signals should fire in order: started, step_completed (x2), completed",
	)


func test_save_load_mid_quest_preserves_state() -> void:
	# Progress to mid-quest
	_tracker.start_quest(_quest_data)
	_inventory.add_item("quest_amulet")
	_tracker.advance_quest("fetch_amulet")

	# Save
	var tracker_save: Dictionary = _tracker.get_save_data()
	var inventory_save: Dictionary = _inventory.get_save_data()

	# Create fresh systems and load
	var new_tracker: QuestTracker = QuestTracker.new()
	var new_inventory: Inventory = Inventory.new()
	add_child_autofree(new_tracker)
	add_child_autofree(new_inventory)

	new_tracker.load_save_data(tracker_save)
	new_inventory.load_save_data(inventory_save)

	# Verify restored state
	assert_true(new_tracker.is_quest_active("fetch_amulet"))
	assert_eq(
		new_tracker.get_current_step_description("fetch_amulet"),
		"Return the amulet to Nathan",
	)
	assert_true(new_inventory.has_item("quest_amulet"))

	# Complete quest on loaded state
	new_tracker.advance_quest("fetch_amulet")
	assert_true(new_tracker.is_quest_complete("fetch_amulet"))
