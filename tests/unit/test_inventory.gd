extends GutTest
## Unit tests for Inventory node.

var _inventory: Inventory


func before_each() -> void:
	_inventory = Inventory.new()
	add_child_autofree(_inventory)


func test_add_item() -> void:
	_inventory.add_item("sword")
	assert_true(_inventory.has_item("sword"), "Should have sword after adding")


func test_add_item_emits_signal() -> void:
	watch_signals(_inventory)
	_inventory.add_item("sword", 2)
	assert_signal_emitted_with_parameters(_inventory, "item_added", ["sword", 2])


func test_remove_item() -> void:
	_inventory.add_item("sword")
	var removed: bool = _inventory.remove_item("sword")
	assert_true(removed, "Should return true when item removed")
	assert_false(_inventory.has_item("sword"), "Should not have sword after removal")


func test_remove_item_not_found() -> void:
	var removed: bool = _inventory.remove_item("nonexistent")
	assert_false(removed, "Should return false when item not found")


func test_remove_item_emits_signal() -> void:
	_inventory.add_item("sword")
	watch_signals(_inventory)
	_inventory.remove_item("sword")
	assert_signal_emitted_with_parameters(_inventory, "item_removed", ["sword", 1])


func test_add_stackable() -> void:
	_inventory.add_item("potion", 3)
	_inventory.add_item("potion", 2)
	assert_true(
		_inventory.has_item("potion", 5),
		"Should have 5 potions after adding 3 + 2",
	)


func test_has_item_quantity_threshold() -> void:
	_inventory.add_item("potion", 3)
	assert_true(_inventory.has_item("potion", 3), "Should have exactly 3")
	assert_false(_inventory.has_item("potion", 4), "Should not have 4")


func test_partial_remove() -> void:
	_inventory.add_item("potion", 5)
	_inventory.remove_item("potion", 2)
	assert_true(
		_inventory.has_item("potion", 3),
		"Should have 3 potions after removing 2 from 5",
	)


func test_save_load_roundtrip() -> void:
	_inventory.add_item("sword", 1)
	_inventory.add_item("potion", 5)
	var save_data: Dictionary = _inventory.get_save_data()

	# Create fresh inventory and load
	var new_inventory: Inventory = Inventory.new()
	add_child_autofree(new_inventory)
	new_inventory.load_save_data(save_data)

	assert_true(new_inventory.has_item("sword", 1), "Loaded inventory should have sword")
	assert_true(new_inventory.has_item("potion", 5), "Loaded inventory should have 5 potions")


func test_save_key() -> void:
	assert_eq(_inventory.get_save_key(), "inventory")
