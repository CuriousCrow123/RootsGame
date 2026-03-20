extends Node
## Manages scene transitions with fade overlay and persistent player.
## Registered as autoload from a .tscn scene (needs CanvasLayer + ColorRect child).

signal scene_change_started
signal scene_change_completed

var _is_transitioning: bool = false
var _player: PlayerController = null

@onready var _transition_overlay: ColorRect = %TransitionOverlay


func register_player(player: PlayerController) -> void:
	_player = player
	# Reparent player to root so it persists across scene changes
	player.get_parent().remove_child(player)
	get_tree().root.add_child(player)


func change_scene(target_scene_path: String, spawn_point_id: String = "") -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	scene_change_started.emit()
	# Fade out (0.3s)
	var tween: Tween = create_tween()
	tween.tween_property(_transition_overlay, "color:a", 1.0, 0.3)
	await tween.finished
	if not _is_transitioning:
		return  # Cancelled
	# Load scene — change_scene_to_file is deferred
	var err: Error = get_tree().change_scene_to_file(target_scene_path)
	if err != OK:
		push_error("Failed to change scene: %s" % error_string(err))
		_is_transitioning = false
		return
	# Wait for the new scene to be fully ready (tree_changed fires too early)
	await get_tree().process_frame
	# Position player at spawn point
	if spawn_point_id != "" and _player:
		_place_player_at_spawn(spawn_point_id)
	# Fade in (0.3s)
	tween = create_tween()
	tween.tween_property(_transition_overlay, "color:a", 0.0, 0.3)
	await tween.finished
	_is_transitioning = false
	scene_change_completed.emit()


func _place_player_at_spawn(spawn_point_id: String) -> void:
	var spawn: Marker3D = get_tree().current_scene.find_child(spawn_point_id) as Marker3D
	if spawn and _player:
		_player.global_position = spawn.global_position
