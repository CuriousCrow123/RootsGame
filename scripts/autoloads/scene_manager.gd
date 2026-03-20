extends Node
## Manages scene transitions with fade overlay and persistent player.
## Registered as a .gd autoload — builds the overlay in _ready() so the
## parser knows the full type (no .tscn = no unsafe_method_access warnings).

signal scene_change_started
signal scene_change_completed

var _is_transitioning: bool = false
var _player: PlayerController = null
var _transition_overlay: ColorRect


func _ready() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 100  # Above all game UI
	add_child(canvas)
	_transition_overlay = ColorRect.new()
	_transition_overlay.color = Color(0.0, 0.0, 0.0, 0.0)
	_transition_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_transition_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(_transition_overlay)


func register_player(player: PlayerController) -> void:
	if _player and is_instance_valid(_player):
		# A persistent player already exists — this is a scene-instanced duplicate
		# (e.g., returning to Room 1 which has Player in the .tscn). Free the new one.
		player.queue_free()
		return
	_player = player
	# Reparent player to root so it persists across scene changes.
	# Must be deferred — _ready() fires while the tree is still building children.
	player.get_parent().call_deferred("remove_child", player)
	get_tree().root.call_deferred("add_child", player)


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
	# Load scene — change_scene_to_file is deferred (runs at end of frame)
	var err: Error = get_tree().change_scene_to_file(target_scene_path)
	if err != OK:
		push_error("Failed to change scene: %s" % error_string(err))
		_is_transitioning = false
		return
	# change_scene_to_file is deferred, so we need two frames:
	# frame 1: the deferred call executes, old scene freed, new scene added
	# frame 2: new scene's _ready() has run, current_scene is set
	await get_tree().process_frame
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
	var scene: Node = get_tree().current_scene
	if not scene:
		push_warning("SceneManager: current_scene is null, cannot find spawn '%s'" % spawn_point_id)
		return
	var spawn: Marker3D = scene.find_child(spawn_point_id) as Marker3D
	if not spawn:
		push_warning(
			"SceneManager: spawn point '%s' not found in '%s'" % [spawn_point_id, scene.name]
		)
		return
	if _player:
		_player.global_position = spawn.global_position
		print(
			(
				"SceneManager: placed player at spawn '%s' -> %s"
				% [spawn_point_id, spawn.global_position]
			)
		)
