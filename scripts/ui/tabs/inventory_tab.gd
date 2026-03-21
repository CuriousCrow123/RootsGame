extends VBoxContainer
## Read-only item list from Inventory. Shows item name and quantity.

var _inventory: Inventory = null

@onready var _item_list: VBoxContainer = $ScrollContainer/ItemList
@onready var _empty_label: Label = $EmptyLabel


func connect_to_player(player: PlayerController) -> void:
	_inventory = player.get_inventory()
	if _inventory:
		_inventory.item_added.connect(_on_items_changed.unbind(2))
		_inventory.item_removed.connect(_on_items_changed.unbind(2))


func grab_initial_focus() -> void:
	if _item_list.get_child_count() > 0:
		var first: Control = _item_list.get_child(0) as Control
		if first:
			first.grab_focus()


func _on_items_changed() -> void:
	_refresh_list()


func _refresh_list() -> void:
	for child: Node in _item_list.get_children():
		child.queue_free()
	if not _inventory:
		_empty_label.visible = true
		return
	var items: Array[Dictionary] = _inventory._items
	_empty_label.visible = items.is_empty()
	for entry: Dictionary in items:
		var label: Label = Label.new()
		var item_id: String = entry["item_id"]
		var quantity: int = entry["quantity"]
		var display: String = _inventory.get_display_name(item_id)
		label.text = "%s x%d" % [display, quantity]
		label.focus_mode = Control.FOCUS_ALL
		_item_list.add_child(label)
