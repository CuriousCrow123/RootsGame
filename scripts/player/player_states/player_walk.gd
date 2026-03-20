extends State
## Applies movement from player input. Transitions to Idle when input stops.
## Transitions to Interact when GameState enters DIALOGUE mode.


func enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	GameState.game_state_changed.connect(_on_game_state_changed)


func exit() -> void:
	if GameState.game_state_changed.is_connected(_on_game_state_changed):
		GameState.game_state_changed.disconnect(_on_game_state_changed)


func physics_update(_delta: float) -> void:
	if GameState.current_mode != GameState.GameMode.OVERWORLD:
		state_finished.emit("Idle", {})
		return
	var player: PlayerController = owner as PlayerController
	var direction: Vector3 = player.get_movement_input()
	if direction.length_squared() < 0.01:
		state_finished.emit("Idle", {})
		return
	player.velocity = direction * player.move_speed
	player.move_and_slide()
	# Face movement direction
	player.rotation.y = atan2(-direction.x, -direction.z)


func _on_game_state_changed(new_mode: GameState.GameMode) -> void:
	if new_mode == GameState.GameMode.DIALOGUE:
		state_finished.emit("Interact", {})
