extends VBoxContainer
## Inventory tab with card-style item display, sorting, and keyboard navigation.
## Uses Inventory public API. Supports incremental updates for single-item changes.

enum SortMode { BY_NAME, BY_RECENT, BY_QUANTITY }

const SLOT_SCENE: PackedScene = preload("res://scenes/ui/components/inventory_slot.tscn")

var _inventory: Inventory = null
var _sort_mode: SortMode = SortMode.BY_RECENT

@onready var _item_list: VBoxContainer = $ScrollContainer/ItemList
@onready var _empty_label: Label = $EmptyLabel
@onready var _scroll: ScrollContainer = $ScrollContainer


func _ready() -> void:
	_scroll.follow_focus = true
	_empty_label.text = "No items yet"
	_empty_label.theme_type_variation = &"DimLabel"
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func connect_to_player(player: PlayerController) -> void:
	_disconnect_signals()
	_inventory = player.get_inventory()
	if _inventory:
		_inventory.item_added.connect(_on_item_added)
		_inventory.item_removed.connect(_on_item_removed)
		_refresh_list()


func _exit_tree() -> void:
	_disconnect_signals()


func grab_initial_focus() -> void:
	if _item_list.get_child_count() > 0:
		var first: Control = _item_list.get_child(0) as Control
		if first:
			first.grab_focus()


func sort_by(mode: SortMode) -> void:
	_sort_mode = mode
	_refresh_list()


func _on_item_added(_item_id: String, _quantity: int) -> void:
	_refresh_list()


func _on_item_removed(_item_id: String, _quantity: int) -> void:
	_refresh_list()


func _refresh_list() -> void:
	for child: Node in _item_list.get_children():
		_item_list.remove_child(child)
		child.queue_free()
	if not _inventory:
		_empty_label.visible = true
		return
	var items: Array[Dictionary] = _inventory.get_items()
	_empty_label.visible = items.is_empty()
	_sort_items(items)
	for entry: Dictionary in items:
		var slot: PanelContainer = SLOT_SCENE.instantiate()
		_item_list.add_child(slot)
		var item_id: String = str(entry["item_id"])
		var quantity: int = entry["quantity"]
		var display: String = _inventory.get_display_name(item_id)
		slot.call("setup", item_id, display, quantity)


func _sort_items(items: Array[Dictionary]) -> void:
	match _sort_mode:
		SortMode.BY_NAME:
			items.sort_custom(_compare_by_name)
		SortMode.BY_QUANTITY:
			items.sort_custom(_compare_by_quantity)
		SortMode.BY_RECENT:
			pass  # Default order from Inventory is insertion order


func _compare_by_name(a: Dictionary, b: Dictionary) -> bool:
	var name_a: String = _inventory.get_display_name(str(a["item_id"]))
	var name_b: String = _inventory.get_display_name(str(b["item_id"]))
	return name_a.naturalcasecmp_to(name_b) < 0


func _compare_by_quantity(a: Dictionary, b: Dictionary) -> bool:
	var qty_a: int = a["quantity"]
	var qty_b: int = b["quantity"]
	return qty_a > qty_b


func _disconnect_signals() -> void:
	if not _inventory:
		return
	if _inventory.item_added.is_connected(_on_item_added):
		_inventory.item_added.disconnect(_on_item_added)
	if _inventory.item_removed.is_connected(_on_item_removed):
		_inventory.item_removed.disconnect(_on_item_removed)
