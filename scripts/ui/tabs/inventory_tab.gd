extends VBoxContainer
## Item list from Inventory. Shows item name and quantity.
## Uses Inventory public API (never accesses private members).

var _inventory: Inventory = null

@onready var _item_list: VBoxContainer = $ScrollContainer/ItemList
@onready var _empty_label: Label = $EmptyLabel


func connect_to_player(player: PlayerController) -> void:
	# Disconnect old connections if reconnecting (e.g., after load_game)
	if _inventory:
		if _inventory.item_added.is_connected(_on_item_added):
			_inventory.item_added.disconnect(_on_item_added)
		if _inventory.item_removed.is_connected(_on_item_removed):
			_inventory.item_removed.disconnect(_on_item_removed)
	_inventory = player.get_inventory()
	if _inventory:
		_inventory.item_added.connect(_on_item_added)
		_inventory.item_removed.connect(_on_item_removed)
		_refresh_list()


func _exit_tree() -> void:
	if _inventory:
		if _inventory.item_added.is_connected(_on_item_added):
			_inventory.item_added.disconnect(_on_item_added)
		if _inventory.item_removed.is_connected(_on_item_removed):
			_inventory.item_removed.disconnect(_on_item_removed)


func grab_initial_focus() -> void:
	if _item_list.get_child_count() > 0:
		var first: Control = _item_list.get_child(0) as Control
		if first:
			first.grab_focus()


func _on_item_added(_item_id: String, _quantity: int) -> void:
	_refresh_list()


func _on_item_removed(_item_id: String, _quantity: int) -> void:
	_refresh_list()


func _refresh_list() -> void:
	# remove_child + queue_free prevents zombie children for one frame
	for child: Node in _item_list.get_children():
		_item_list.remove_child(child)
		child.queue_free()
	if not _inventory:
		_empty_label.visible = true
		return
	var items: Array[Dictionary] = _inventory.get_items()
	_empty_label.visible = items.is_empty()
	for entry: Dictionary in items:
		var label: Label = Label.new()
		var item_id: String = entry["item_id"]
		var quantity: int = entry["quantity"]
		var display: String = _inventory.get_display_name(item_id)
		label.text = "%s x%d" % [display, quantity]
		label.focus_mode = Control.FOCUS_ALL
		_item_list.add_child(label)
