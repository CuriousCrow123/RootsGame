extends State
## Applies movement from player input. Transitions to Idle when input stops.
## Transitions to Interact when GameState enters DIALOGUE mode.


func enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	GameState.game_state_changed.connect(_on_game_state_changed)
	var player: PlayerController = get_parent().get_parent() as PlayerController
	var raw_input: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)
	player.update_facing(raw_input)
	player.play_animation("walk")


func exit() -> void:
	if GameState.game_state_changed.is_connected(_on_game_state_changed):
		GameState.game_state_changed.disconnect(_on_game_state_changed)


func physics_update(_delta: float) -> void:
	if GameState.current_mode != GameState.GameMode.OVERWORLD:
		state_finished.emit("Idle", {})
		return
	var player: PlayerController = get_parent().get_parent() as PlayerController
	var direction: Vector3 = player.get_movement_input()
	if direction.length_squared() < 0.01:
		state_finished.emit("Idle", {})
		return
	var raw_input: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)
	var previous_facing: String = player.get_facing_direction()
	var old_facing_vec: Vector3 = player.get_facing_vector()
	player.update_facing(raw_input)
	player.set_last_movement_vector(direction)
	if player.get_facing_direction() != previous_facing:
		player.play_animation("walk")
	# Re-evaluate interactable selection on significant facing change
	if old_facing_vec.dot(player.get_facing_vector()) < PlayerController.FACING_CHANGE_THRESHOLD:
		player.reevaluate_nearest_interactable()
	player.velocity = direction * player.move_speed
	if not player.is_on_floor():
		player.velocity.y -= 9.8 * _delta
	player.move_and_slide()


func _on_game_state_changed(new_mode: GameState.GameMode) -> void:
	if new_mode == GameState.GameMode.DIALOGUE:
		state_finished.emit("Interact", {})
