extends StaticBody3D
## Item container that gives its contents on first interaction.

signal chest_opened(item: ItemData)

@export var item: ItemData = null
@export var item_quantity: int = 1
@export var chest_id: String = ""

var _is_opened: bool = false


func _ready() -> void:
	add_to_group("saveable")


func interact(player: PlayerController) -> void:
	if _is_opened:
		return
	if not item:
		push_warning("Chest %s has no item assigned" % chest_id)
		return
	var inventory: Inventory = player.get_inventory()
	if not inventory:
		return
	inventory.add_item(item.item_id, item_quantity)
	_is_opened = true  # Set AFTER successful add — never consume chest without giving item
	chest_opened.emit(item)


func get_save_key() -> String:
	return chest_id


func get_save_data() -> Dictionary:
	return {"is_opened": _is_opened}


func load_save_data(data: Dictionary) -> void:
	@warning_ignore("unsafe_call_argument")
	_is_opened = data.get("is_opened", false)
