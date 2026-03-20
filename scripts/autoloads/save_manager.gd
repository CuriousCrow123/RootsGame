extends Node
## Serializes/deserializes all saveable node state to JSON.
## Saveable nodes: add to "saveable" group, implement get_save_key(),
## get_save_data(), load_save_data().

const SAVE_DIR: String = "user://saves/"
const SAVE_FILE: String = "save_001.json"
const SAVE_VERSION: int = 1


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_save"):
		save_game()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("debug_load"):
		load_game()
		get_viewport().set_input_as_handled()


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
	var scene_path: String = data.get("scene_path", "")
	if scene_path != "" and scene_path != get_tree().current_scene.scene_file_path:
		SceneManager.change_scene(scene_path)
		await SceneManager.scene_change_completed
	# AFTER scene change: overwrite WorldState with save file data.
	# This must happen after change_scene's snapshot()/restore() cycle,
	# otherwise snapshot() clobbers the loaded data.
	if data.has("world_state"):
		var world_data: Dictionary = data["world_state"]
		WorldState.load_save_data(world_data)
		WorldState.restore()
	# Restore remaining saveables (Player, Inventory, QuestTracker).
	# Skip WorldState — already restored above.
	for node: Node in get_tree().get_nodes_in_group("saveable"):
		if node == WorldState:
			continue
		if node.has_method("get_save_key") and node.has_method("load_save_data"):
			var key: String = node.call("get_save_key")
			if data.has(key):
				node.call("load_save_data", data[key])
