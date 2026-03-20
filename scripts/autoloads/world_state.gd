extends Node
## Tracks interactable state across scene transitions within a session.
## Implements the saveable contract so SaveManager can serialize/deserialize
## all interactable state as a single blob.

## All values are flat Dictionaries of primitives (e.g., {"is_opened": true}).
## If interactables begin storing nested Resources, manual duplication is needed.
var _state: Dictionary[String, Dictionary] = {}


func _ready() -> void:
	add_to_group("saveable")


func get_state(key: String) -> Dictionary:
	if _state.has(key):
		return _state[key]
	return {}


func set_state(key: String, data: Dictionary) -> void:
	_state[key] = data


func snapshot() -> void:
	## Called by SceneManager BEFORE old scene is freed.
	## Collects state from all interactables in the current scene.
	for node: Node in get_tree().get_nodes_in_group("interactable_saveable"):
		if node.has_method("get_save_key") and node.has_method("get_save_data"):
			var key: String = node.call("get_save_key")
			_state[key] = node.call("get_save_data")


func restore() -> void:
	## Called by SceneManager AFTER new scene is ready.
	## Pushes stored state to matching interactables.
	for node: Node in get_tree().get_nodes_in_group("interactable_saveable"):
		if node.has_method("get_save_key") and node.has_method("load_save_data"):
			var key: String = node.call("get_save_key")
			if _state.has(key):
				node.call("load_save_data", _state[key].duplicate(true))


# --- Saveable contract (for SaveManager disk persistence) ---


func get_save_key() -> String:
	return "world_state"


func get_save_data() -> Dictionary:
	return _state.duplicate(true)


func load_save_data(data: Dictionary) -> void:
	_state = {}
	for key: String in data:
		@warning_ignore("unsafe_cast")
		var entry: Dictionary = data[key] as Dictionary
		_state[key] = entry.duplicate(true)
