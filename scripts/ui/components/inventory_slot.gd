extends PanelContainer
## Single inventory item card. Shows icon placeholder, name, and quantity.
## Instanced by inventory_tab.gd for each item.

signal selected(item_id: String)

var _item_id: String = ""
var _hover_tween: Tween = null

@onready var _icon_rect: TextureRect = %IconRect
@onready var _name_label: Label = %NameLabel
@onready var _quantity_label: Label = %QuantityLabel


func setup(item_id: String, display_name: String, quantity: int) -> void:
	_item_id = item_id
	if is_node_ready():
		_apply_data(display_name, quantity)
	else:
		ready.connect(_apply_data.bind(display_name, quantity), CONNECT_ONE_SHOT)


func get_item_id() -> String:
	return _item_id


func _apply_data(display_name: String, quantity: int) -> void:
	_name_label.text = display_name
	_quantity_label.text = "x%d" % quantity if quantity > 1 else ""


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_entered)
	focus_exited.connect(_on_focus_exited)
	gui_input.connect(_on_gui_input)


func _on_gui_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		selected.emit(_item_id)
		accept_event()


func _on_mouse_entered() -> void:
	_animate_hover(true)


func _on_mouse_exited() -> void:
	_animate_hover(false)


func _on_focus_entered() -> void:
	_animate_hover(true)


func _on_focus_exited() -> void:
	_animate_hover(false)


func _animate_hover(is_hovered: bool) -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
	_hover_tween = create_tween()
	var target_scale: float = 1.02 if is_hovered else 1.0
	var target_mod: float = 1.1 if is_hovered else 1.0
	_hover_tween.set_parallel(true)
	_hover_tween.tween_property(self, "scale", Vector2(target_scale, target_scale), 0.1)
	_hover_tween.tween_property(self, "modulate:r", target_mod, 0.1)
	_hover_tween.tween_property(self, "modulate:g", target_mod, 0.1)
	_hover_tween.tween_property(self, "modulate:b", target_mod, 0.1)


func _exit_tree() -> void:
	if _hover_tween and _hover_tween.is_valid():
		_hover_tween.kill()
