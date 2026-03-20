extends StaticBody3D
## Item container that gives its contents on first interaction.

signal chest_opened(item: ItemData)

@export var item: ItemData = null
@export var item_quantity: int = 1
@export var chest_id: String = ""

var _is_opened: bool = false
var _closed_material: Material = null

@onready var _mesh: MeshInstance3D = $MeshInstance3D as MeshInstance3D


func _ready() -> void:
	WorldState.register(self)
	if _mesh:
		_closed_material = _mesh.get_surface_override_material(0)


func interact(player: PlayerController) -> void:
	if _is_opened:
		return
	if not item:
		push_warning("Chest %s has no item assigned" % chest_id)
		return
	var inventory: Inventory = player.get_inventory()
	if not inventory:
		return
	inventory.add_item(item.item_id, item_quantity, item.display_name)
	_is_opened = true  # Set AFTER successful add — never consume chest without giving item
	WorldState.set_state(chest_id, {"is_opened": true})
	_update_visual()
	chest_opened.emit(item)


func get_save_key() -> String:
	return chest_id


func get_save_data() -> Dictionary:
	return {"is_opened": _is_opened}


func load_save_data(data: Dictionary) -> void:
	@warning_ignore("unsafe_call_argument")
	_is_opened = data.get("is_opened", false)
	_update_visual()


func _update_visual() -> void:
	if not _mesh:
		return
	if _is_opened:
		var mat: StandardMaterial3D = StandardMaterial3D.new()
		mat.albedo_color = Color(0.35, 0.3, 0.2)
		_mesh.set_surface_override_material(0, mat)
	else:
		_mesh.set_surface_override_material(0, _closed_material)
