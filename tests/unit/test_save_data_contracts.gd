extends GutTest
## Unit tests: save/load contract for all saveable classes.
## Each saveable must implement get_save_key(), get_save_data(), load_save_data().

var _inventory: Inventory
var _tracker: QuestTracker
var _chest_script: GDScript = preload("res://scripts/interactables/chest_interactable.gd")


func before_each() -> void:
	_inventory = Inventory.new()
	_tracker = QuestTracker.new()
	add_child_autofree(_inventory)
	add_child_autofree(_tracker)


# -- Inventory contract --


func test_inventory_save_key() -> void:
	assert_eq(_inventory.get_save_key(), "inventory")


func test_inventory_roundtrip() -> void:
	_inventory.add_item("sword", 1)
	_inventory.add_item("potion", 5)
	var saved: Dictionary = _inventory.get_save_data()

	var fresh: Inventory = Inventory.new()
	add_child_autofree(fresh)
	fresh.load_save_data(saved)

	assert_true(fresh.has_item("sword", 1))
	assert_true(fresh.has_item("potion", 5))
	assert_false(fresh.has_item("nonexistent"))


func test_inventory_empty_roundtrip() -> void:
	var saved: Dictionary = _inventory.get_save_data()
	var fresh: Inventory = Inventory.new()
	add_child_autofree(fresh)
	fresh.load_save_data(saved)
	assert_false(fresh.has_item("anything"))


# -- QuestTracker contract --


func test_quest_tracker_save_key() -> void:
	assert_eq(_tracker.get_save_key(), "quest_tracker")


func test_quest_tracker_roundtrip() -> void:
	var quest: QuestData = _create_test_quest()
	_tracker.start_quest(quest)
	_tracker.advance_quest("test_quest")
	var saved: Dictionary = _tracker.get_save_data()

	var fresh: QuestTracker = QuestTracker.new()
	add_child_autofree(fresh)
	# Must register quest data before loading save state
	fresh.start_quest(quest)
	fresh.load_save_data(saved)

	assert_true(fresh.is_quest_active("test_quest"))
	assert_eq(fresh.get_current_step_description("test_quest"), "Step two")


func test_quest_tracker_complete_roundtrip() -> void:
	var quest: QuestData = _create_test_quest()
	_tracker.start_quest(quest)
	_tracker.advance_quest("test_quest")
	_tracker.advance_quest("test_quest")
	assert_true(_tracker.is_quest_complete("test_quest"))

	var saved: Dictionary = _tracker.get_save_data()
	var fresh: QuestTracker = QuestTracker.new()
	add_child_autofree(fresh)
	fresh.start_quest(quest)
	fresh.load_save_data(saved)

	assert_true(fresh.is_quest_complete("test_quest"))


# -- ChestInteractable contract --


func test_chest_save_key() -> void:
	var chest: StaticBody3D = StaticBody3D.new()
	chest.set_script(_chest_script)
	add_child_autofree(chest)
	chest.chest_id = "test_chest"
	assert_eq(chest.get_save_key(), "test_chest")


func test_chest_roundtrip() -> void:
	var chest: StaticBody3D = StaticBody3D.new()
	chest.set_script(_chest_script)
	add_child_autofree(chest)
	chest.chest_id = "test_chest"

	# Simulate opening — set _is_opened directly since interact() needs a full player
	chest._is_opened = true
	var saved: Dictionary = chest.get_save_data()

	# Fresh chest
	var fresh: StaticBody3D = StaticBody3D.new()
	fresh.set_script(_chest_script)
	add_child_autofree(fresh)
	fresh.chest_id = "test_chest"
	assert_false(fresh._is_opened, "Fresh chest should be closed")

	fresh.load_save_data(saved)
	assert_true(fresh._is_opened, "Loaded chest should be opened")


# -- PlayerController contract --


func test_player_save_key() -> void:
	var player: PlayerController = PlayerController.new()
	add_child_autofree(player)
	assert_eq(player.get_save_key(), "player")


func test_player_position_roundtrip() -> void:
	var player: PlayerController = PlayerController.new()
	add_child_autofree(player)
	player.global_position = Vector3(10.0, 0.0, -5.0)
	player.rotation.y = 1.2
	var saved: Dictionary = player.get_save_data()

	var fresh: PlayerController = PlayerController.new()
	add_child_autofree(fresh)
	fresh.load_save_data(saved)

	assert_almost_eq(fresh.global_position.x, 10.0, 0.01)
	assert_almost_eq(fresh.global_position.z, -5.0, 0.01)
	assert_almost_eq(fresh.rotation.y, 1.2, 0.01)


# -- Helpers --


func _create_test_quest() -> QuestData:
	var step1: QuestStepData = QuestStepData.new()
	step1.step_id = "step_one"
	step1.description = "Step one"
	step1.next_step_id = "step_two"

	var step2: QuestStepData = QuestStepData.new()
	step2.step_id = "step_two"
	step2.description = "Step two"
	step2.next_step_id = ""

	var quest: QuestData = QuestData.new()
	quest.quest_id = "test_quest"
	quest.display_name = "Test Quest"
	quest.description = "A test quest."
	quest.steps = [step1, step2]
	return quest
