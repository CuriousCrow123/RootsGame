extends GutTest
## Unit tests: save/load contract for all saveable classes.
## Each saveable must implement get_save_key(), get_save_data(), load_save_data().

var _inventory: Inventory
var _tracker: QuestTracker
var _chest_script: GDScript = preload("res://scripts/interactables/chest_interactable.gd")
var _world_state_script: GDScript = preload("res://scripts/autoloads/world_state.gd")
var _quest_data: QuestData = preload("res://resources/quests/fetch_quest.tres")


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
	_tracker.start_quest(_quest_data)
	_tracker.advance_quest("fetch_amulet")
	var saved: Dictionary = _tracker.get_save_data()

	var fresh: QuestTracker = QuestTracker.new()
	add_child_autofree(fresh)
	fresh.load_save_data(saved)

	assert_true(fresh.is_quest_active("fetch_amulet"))
	assert_eq(fresh.get_current_step_description("fetch_amulet"), "Return the amulet to Nathan")


func test_quest_tracker_complete_roundtrip() -> void:
	_tracker.start_quest(_quest_data)
	_tracker.advance_quest("fetch_amulet")
	_tracker.advance_quest("fetch_amulet")
	assert_true(_tracker.is_quest_complete("fetch_amulet"))

	var saved: Dictionary = _tracker.get_save_data()
	var fresh: QuestTracker = QuestTracker.new()
	add_child_autofree(fresh)
	fresh.load_save_data(saved)

	assert_true(fresh.is_quest_complete("fetch_amulet"))


# -- ChestInteractable contract --


func _create_test_chest() -> StaticBody3D:
	var chest: StaticBody3D = StaticBody3D.new()
	# Add child nodes the script expects via @onready
	var anim_player: AnimationPlayer = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	chest.add_child(anim_player)
	var chest_top: MeshInstance3D = MeshInstance3D.new()
	chest_top.name = "Chest_Top"
	chest.add_child(chest_top)
	chest.set_script(_chest_script)
	return chest


func test_chest_save_key() -> void:
	var chest: StaticBody3D = _create_test_chest()
	add_child_autofree(chest)
	chest.set("chest_id", "test_chest")
	var key: String = chest.call("get_save_key")
	assert_eq(key, "test_chest")


func test_chest_in_interactable_saveable_group() -> void:
	var chest: StaticBody3D = _create_test_chest()
	add_child_autofree(chest)
	assert_true(
		chest.is_in_group("interactable_saveable"), "Chest should be in interactable_saveable group"
	)
	assert_false(chest.is_in_group("saveable"), "Chest should NOT be in saveable group")


func test_chest_roundtrip() -> void:
	var chest: StaticBody3D = _create_test_chest()
	add_child_autofree(chest)
	chest.set("chest_id", "test_chest")

	# Simulate opening — set _is_opened directly since interact() needs a full player
	chest.set("_is_opened", true)
	var saved: Dictionary = chest.call("get_save_data")

	# Fresh chest
	var fresh: StaticBody3D = _create_test_chest()
	add_child_autofree(fresh)
	fresh.set("chest_id", "test_chest")
	var is_closed: bool = fresh.get("_is_opened")
	assert_false(is_closed, "Fresh chest should be closed")

	fresh.call("load_save_data", saved)
	var is_opened: bool = fresh.get("_is_opened")
	assert_true(is_opened, "Loaded chest should be opened")


# -- WorldState contract --


func test_world_state_save_key() -> void:
	var ws: Node = _world_state_script.new()
	add_child_autofree(ws)
	var key: String = ws.call("get_save_key")
	assert_eq(key, "world_state")


func test_world_state_roundtrip() -> void:
	var ws: Node = _world_state_script.new()
	add_child_autofree(ws)
	ws.call("set_state", "chest_a", {"is_opened": true})
	ws.call("set_state", "chest_b", {"is_opened": false})
	var saved: Dictionary = ws.call("get_save_data")

	var fresh: Node = _world_state_script.new()
	add_child_autofree(fresh)
	fresh.call("load_save_data", saved)

	var state_a: Dictionary = fresh.call("get_state", "chest_a")
	var state_b: Dictionary = fresh.call("get_state", "chest_b")
	var a_opened: bool = state_a.get("is_opened")
	var b_opened: bool = state_b.get("is_opened")
	assert_eq(a_opened, true, "chest_a should be opened")
	assert_eq(b_opened, false, "chest_b should be closed")


func test_world_state_defensive_copy() -> void:
	var ws: Node = _world_state_script.new()
	add_child_autofree(ws)
	ws.call("set_state", "chest_a", {"is_opened": true})
	var saved: Dictionary = ws.call("get_save_data")

	# Mutate the returned data — should not affect internal state
	saved["chest_a"]["is_opened"] = false

	var internal: Dictionary = ws.call("get_state", "chest_a")
	var still_opened: bool = internal.get("is_opened")
	assert_eq(
		still_opened, true, "Internal state should not be mutated by external changes to save data"
	)


# -- PlayerController contract --


func test_player_save_key() -> void:
	var player: PlayerController = TestHelpers.create_player()
	add_child_autofree(player)
	assert_eq(player.get_save_key(), "player")


func test_player_position_roundtrip() -> void:
	var player: PlayerController = TestHelpers.create_player()
	add_child_autofree(player)
	player.global_position = Vector3(10.0, 0.0, -5.0)
	var saved: Dictionary = player.get_save_data()

	var fresh: PlayerController = TestHelpers.create_player()
	add_child_autofree(fresh)
	fresh.load_save_data(saved)

	assert_almost_eq(float(fresh.global_position.x), 10.0, 0.01)
	assert_almost_eq(float(fresh.global_position.z), -5.0, 0.01)
