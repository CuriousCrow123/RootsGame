extends GutTest
## Integration test: full save/load cycle across inventory, quest, and player.
## Tests the saveable contract end-to-end with real objects.

var _player: PlayerController
var _inventory: Inventory
var _tracker: QuestTracker
var _world_state: Node
var _world_state_script: GDScript = preload("res://scripts/autoloads/world_state.gd")


func before_each() -> void:
	_player = PlayerController.new()
	add_child_autofree(_player)
	_inventory = _player.get_inventory()
	_tracker = _player.get_quest_tracker()
	_world_state = _world_state_script.new()
	add_child_autofree(_world_state)


func test_full_save_load_cycle() -> void:
	# 1. Set up game state
	_player.global_position = Vector3(5.0, 0.0, 8.0)
	_player.rotation.y = 0.5
	_inventory.add_item("quest_amulet", 1)
	_inventory.add_item("potion", 3)
	var quest: QuestData = _create_test_quest()
	_tracker.start_quest(quest)
	_tracker.advance_quest("fetch_amulet")

	# 2. Collect save data from all saveables (simulating SaveManager._collect_save_data)
	var save_data: Dictionary = {}
	for node: Node in get_tree().get_nodes_in_group("saveable"):
		if node.has_method("get_save_key") and node.has_method("get_save_data"):
			save_data[node.get_save_key()] = node.get_save_data()

	# 3. Verify save data was collected
	assert_has(save_data, "player", "Should have player save data")
	assert_has(save_data, "inventory", "Should have inventory save data")
	assert_has(save_data, "quest_tracker", "Should have quest tracker save data")

	# 4. Modify state to prove load restores it
	_player.global_position = Vector3.ZERO
	_player.rotation.y = 0.0
	_inventory.remove_item("quest_amulet")
	_inventory.remove_item("potion", 3)

	# 5. Restore from save data
	for node: Node in get_tree().get_nodes_in_group("saveable"):
		if node.has_method("get_save_key") and node.has_method("load_save_data"):
			var key: String = node.get_save_key()
			if save_data.has(key):
				node.load_save_data(save_data[key])

	# 6. Verify everything restored
	assert_almost_eq(_player.global_position.x, 5.0, 0.01, "Player X should restore")
	assert_almost_eq(_player.global_position.z, 8.0, 0.01, "Player Z should restore")
	assert_almost_eq(_player.rotation.y, 0.5, 0.01, "Player rotation should restore")
	assert_true(_inventory.has_item("quest_amulet"), "Amulet should restore")
	assert_true(_inventory.has_item("potion", 3), "Potions should restore")
	assert_true(_tracker.is_quest_active("fetch_amulet"), "Quest should still be active")
	assert_eq(
		_tracker.get_current_step_description("fetch_amulet"),
		"Return the amulet to Nathan",
		"Quest step should restore to second step",
	)


func test_save_load_with_empty_state() -> void:
	# Collect save data with no items, no quests
	var save_data: Dictionary = {}
	for node: Node in get_tree().get_nodes_in_group("saveable"):
		if node.has_method("get_save_key") and node.has_method("get_save_data"):
			save_data[node.get_save_key()] = node.get_save_data()

	# Add some state
	_inventory.add_item("sword")

	# Restore — should clear the sword
	for node: Node in get_tree().get_nodes_in_group("saveable"):
		if node.has_method("get_save_key") and node.has_method("load_save_data"):
			var key: String = node.get_save_key()
			if save_data.has(key):
				node.load_save_data(save_data[key])

	assert_false(_inventory.has_item("sword"), "Sword should not exist after loading empty save")


func test_world_state_in_save_cycle() -> void:
	# WorldState should be collected as "world_state" key
	_world_state.call("set_state", "chest_room1", {"is_opened": true})

	var save_data: Dictionary = {}
	for node: Node in get_tree().get_nodes_in_group("saveable"):
		if node.has_method("get_save_key") and node.has_method("get_save_data"):
			save_data[node.get_save_key()] = node.get_save_data()

	assert_has(save_data, "world_state", "Should have world_state save data")
	var ws_data: Dictionary = save_data["world_state"]
	assert_has(ws_data, "chest_room1", "world_state should contain chest_room1")

	# Modify and restore
	_world_state.call("set_state", "chest_room1", {"is_opened": false})
	_world_state.call("load_save_data", ws_data)
	var restored: Dictionary = _world_state.call("get_state", "chest_room1")
	assert_eq(restored.get("is_opened"), true, "chest_room1 should be restored to opened")


func test_save_data_is_json_serializable() -> void:
	_player.global_position = Vector3(1.0, 2.0, 3.0)
	_inventory.add_item("gem", 10)
	var quest: QuestData = _create_test_quest()
	_tracker.start_quest(quest)

	var save_data: Dictionary = {}
	for node: Node in get_tree().get_nodes_in_group("saveable"):
		if node.has_method("get_save_key") and node.has_method("get_save_data"):
			save_data[node.get_save_key()] = node.get_save_data()

	# Round-trip through JSON
	var json_string: String = JSON.stringify(save_data)
	var json: JSON = JSON.new()
	var err: Error = json.parse(json_string)
	assert_eq(err, OK, "Save data should be valid JSON")

	# Verify parsed data is usable
	var parsed: Dictionary = json.data
	assert_has(parsed, "player")
	assert_has(parsed, "inventory")
	assert_has(parsed, "quest_tracker")
	assert_has(parsed, "world_state")


# -- Helpers --


func _create_test_quest() -> QuestData:
	var step1: QuestStepData = QuestStepData.new()
	step1.step_id = "get_amulet"
	step1.description = "Find the amulet in the chest"
	step1.next_step_id = "return_amulet"

	var step2: QuestStepData = QuestStepData.new()
	step2.step_id = "return_amulet"
	step2.description = "Return the amulet to Nathan"
	step2.next_step_id = ""

	var quest: QuestData = QuestData.new()
	quest.quest_id = "fetch_amulet"
	quest.display_name = "The Old Amulet"
	quest.description = "Retrieve the old amulet for Nathan."
	quest.steps = [step1, step2]
	return quest
