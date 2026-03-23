extends Node
## Manages scene transitions with fade overlay and persistent player.
## Registered as a .gd autoload — builds the overlay in _ready() so the
## parser knows the full type (no .tscn = no unsafe_method_access warnings).

signal scene_change_started
signal scene_change_completed
signal player_registered(player: PlayerController)

var _is_transitioning: bool = false
var _player: PlayerController = null
var _transition_overlay: ColorRect


func is_transitioning() -> bool:
	return _is_transitioning


func get_player() -> PlayerController:
	return _player


func _ready() -> void:
	var canvas: CanvasLayer = CanvasLayer.new()
	canvas.layer = 90  # Below HUD (100) so HUD stays visible during transitions
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
	player_registered.emit(_player)


func change_scene(target_scene_path: String, spawn_point_id: String = "") -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	GameState.set_mode(GameState.GameMode.TRANSITION)
	scene_change_started.emit()
	# Fade out (0.3s)
	var tween: Tween = create_tween()
	tween.tween_property(_transition_overlay, "color:a", 1.0, 0.3)
	await tween.finished
	if not _is_transitioning:
		return  # Cancelled
	# Snapshot interactable state before the old scene is freed
	WorldState.snapshot()
	# Load scene — change_scene_to_file is deferred (runs at end of frame)
	var err: Error = get_tree().change_scene_to_file(target_scene_path)
	if err != OK:
		push_error("Failed to change scene: %s" % error_string(err))
		_is_transitioning = false
		GameState.set_mode(GameState.GameMode.OVERWORLD)
		return
	# scene_changed fires after the new scene's _ready() completes (Godot 4.5+)
	await get_tree().scene_changed
	# Restore interactable state in the new scene (e.g., opened chests)
	WorldState.restore()
	# Position player at spawn point
	if spawn_point_id != "" and _player:
		print(
			(
				"SceneManager: current_scene = %s, player valid = %s"
				% [get_tree().current_scene, is_instance_valid(_player)]
			)
		)
		_place_player_at_spawn(spawn_point_id)
	# Fade in (0.3s)
	tween = create_tween()
	tween.tween_property(_transition_overlay, "color:a", 0.0, 0.3)
	await tween.finished
	_is_transitioning = false
	GameState.set_mode(GameState.GameMode.OVERWORLD)
	scene_change_completed.emit()


func _place_player_at_spawn(spawn_point_id: String) -> void:
	var scene: Node = get_tree().current_scene
	if not scene:
		push_warning("SceneManager: current_scene is null, cannot find spawn '%s'" % spawn_point_id)
		return
	var spawn_node: Node = scene.find_child(spawn_point_id)
	if not spawn_node:
		print(
			(
				"SceneManager: ERROR spawn point '%s' not found in '%s'. Children: %s"
				% [spawn_point_id, scene.name, _get_child_names(scene)]
			)
		)
		return
	var spawn: Marker3D = spawn_node as Marker3D
	if not spawn:
		print(
			(
				"SceneManager: ERROR '%s' is not a Marker3D (is %s)"
				% [spawn_point_id, spawn_node.get_class()]
			)
		)
		return
	if _player:
		_player.global_transform.origin = spawn.global_transform.origin
		_player.velocity = Vector3.ZERO
		print(
			(
				"SceneManager: placed player at spawn '%s' -> %s"
				% [spawn_point_id, spawn.global_position]
			)
		)


func _get_child_names(node: Node) -> Array[String]:
	var names: Array[String] = []
	for child: Node in node.get_children():
		names.append(child.name)
	return names
