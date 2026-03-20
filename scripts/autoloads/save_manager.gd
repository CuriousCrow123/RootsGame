extends Node
## Serializes/deserializes all saveable node state to JSON.
## Saveable nodes call SaveManager.register(self) in _ready().
## Registration validates the three-method contract and adds to "saveable" group.

const SAVE_DIR: String = "user://saves/"
const SAVE_FILE: String = "save_001.json"
const SAVE_VERSION: int = 1


func register(node: Node) -> void:
	assert(
		node.has_method("get_save_key"),
		"%s registered as saveable but missing get_save_key()" % node.name,
	)
	assert(
		node.has_method("get_save_data"),
		"%s registered as saveable but missing get_save_data()" % node.name,
	)
	assert(
		node.has_method("load_save_data"),
		"%s registered as saveable but missing load_save_data()" % node.name,
	)
	node.add_to_group("saveable")


func save_game() -> void:
	if SceneManager.is_transitioning():
		push_warning("Cannot save during scene transition")
		return
	var save_data: Dictionary = _collect_save_data()
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	# Atomic write: write to .tmp then rename — partial file on crash is safe
	var tmp_path: String = SAVE_DIR + SAVE_FILE + ".tmp"
	var final_path: String = SAVE_DIR + SAVE_FILE
	var file: FileAccess = FileAccess.open(tmp_path, FileAccess.WRITE)
	if not file:
		push_error(
			(
				"Failed to open temp save file at %s (error: %d)"
				% [tmp_path, FileAccess.get_open_error()]
			)
		)
		return
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	var rename_err: Error = DirAccess.rename_absolute(tmp_path, final_path)
	if rename_err != OK:
		push_error("Failed to rename temp save (error: %d)" % rename_err)
		return
	print("Game saved to %s" % final_path)


func load_game() -> void:
	var path: String = SAVE_DIR + SAVE_FILE
	if not FileAccess.file_exists(path):
		push_warning("No save file found at %s" % path)
		return
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open save file at %s" % path)
		return
	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(file.get_as_text())
	file.close()
	if parse_result != OK:
		push_error("Failed to parse save file: %s" % json.get_error_message())
		return
	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("Save file root is not a Dictionary (got type %d)" % typeof(json.data))
		return
	var save_data: Dictionary = json.data
	var file_version: int = save_data.get("version", 0)
	if file_version != SAVE_VERSION:
		push_error("Incompatible save version: expected %d, got %d" % [SAVE_VERSION, file_version])
		return
	await _restore_save_data(save_data)
	print("Game loaded from %s" % path)


func _collect_save_data() -> Dictionary:
	var data: Dictionary = {
		"version": SAVE_VERSION,
		"scene_path": get_tree().current_scene.scene_file_path,
		"timestamp": Time.get_unix_time_from_system(),
	}
	for node: Node in get_tree().get_nodes_in_group("saveable"):
		if node.has_method("get_save_key") and node.has_method("get_save_data"):
			var key: String = node.call("get_save_key")
			data[key] = node.call("get_save_data")
	return data


func _restore_save_data(data: Dictionary) -> void:
	# Always reload scene — guarantees clean slate for all scene-local state
	# (interactables, spawn points, etc.) even when loading in the same room.
	var scene_path: String = data.get("scene_path", "")
	if scene_path != "":
		SceneManager.change_scene(scene_path)
		await SceneManager.scene_change_completed
	# AFTER scene change: overwrite WorldState with save file data.
	# This must happen after change_scene's snapshot()/restore() cycle,
	# otherwise snapshot() clobbers the loaded data.
	var world_data: Dictionary = data.get("world_state", {})
	WorldState.load_save_data(world_data)
	WorldState.restore()
	# Restore remaining saveables (Player, Inventory, QuestTracker).
	# Skip WorldState — already restored above.
	for node: Node in get_tree().get_nodes_in_group("saveable"):
		if node == WorldState:
			continue
		if node.has_method("get_save_key") and node.has_method("load_save_data"):
			var key: String = node.call("get_save_key")
			# Always call load_save_data — empty dict triggers "clear then rebuild"
			# to reset state that didn't exist at save time (e.g., quest started after save)
			node.call("load_save_data", data.get(key, {}))
