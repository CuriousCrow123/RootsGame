class_name Inventory
extends Node
## Stores items as {item_id: String, quantity: int} entries. Child of Player.

signal item_added(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)

# Array of { "item_id": String, "quantity": int }
var _items: Array[Dictionary] = []
# Maps item_id -> display_name for UI lookups
var _display_names: Dictionary = {}


func _ready() -> void:
	SaveManager.register(self)


func add_item(item_id: String, quantity: int = 1, display_name: String = "") -> void:
	if display_name != "":
		_display_names[item_id] = display_name
	for entry: Dictionary in _items:
		if entry["item_id"] == item_id:
			entry["quantity"] += quantity
			item_added.emit(item_id, quantity)
			return
	_items.append({"item_id": item_id, "quantity": quantity})
	item_added.emit(item_id, quantity)


func get_display_name(item_id: String) -> String:
	@warning_ignore("unsafe_call_argument")
	return _display_names.get(item_id, item_id)


func remove_item(item_id: String, quantity: int = 1) -> bool:
	for i: int in range(_items.size()):
		if _items[i]["item_id"] == item_id:
			_items[i]["quantity"] -= quantity
			if _items[i]["quantity"] <= 0:
				_items.remove_at(i)
			item_removed.emit(item_id, quantity)
			return true
	return false


func get_items() -> Array[Dictionary]:
	return _items.duplicate(true)


func get_item_count() -> int:
	return _items.size()


func has_item(item_id: String, quantity: int = 1) -> bool:
	for entry: Dictionary in _items:
		if entry["item_id"] == item_id and entry["quantity"] >= quantity:
			return true
	return false


func get_save_key() -> String:
	return "inventory"


func get_save_data() -> Dictionary:
	return {"items": _items.duplicate(true)}


func load_save_data(data: Dictionary) -> void:
	@warning_ignore("unsafe_call_argument")
	_items.assign(data.get("items", []))
