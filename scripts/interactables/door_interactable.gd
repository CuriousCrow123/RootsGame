extends StaticBody3D
## Scene transition trigger. Interact to move to target scene.

@export_file("*.tscn") var target_scene_path: String = ""
@export var target_spawn_point: String = ""
@export var door_id: String = ""


func interact(_player: PlayerController) -> void:
	if target_scene_path == "":
		push_warning("Door %s has no target_scene_path assigned" % door_id)
		return
	@warning_ignore("unsafe_method_access")
	SceneManager.change_scene(target_scene_path, target_spawn_point)
