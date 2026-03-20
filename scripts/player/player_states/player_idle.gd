extends State
## Waits for movement input. Transitions to Walk when input detected.
## Transitions to Interact when GameState enters DIALOGUE mode.


func enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	var player: PlayerController = get_parent().get_parent() as PlayerController
	player.velocity = Vector3.ZERO
	GameState.game_state_changed.connect(_on_game_state_changed)


func exit() -> void:
	if GameState.game_state_changed.is_connected(_on_game_state_changed):
		GameState.game_state_changed.disconnect(_on_game_state_changed)


func handle_input(event: InputEvent) -> void:
	if GameState.current_mode != GameState.GameMode.OVERWORLD:
		return
	if event.is_action_pressed("interact"):
		var player: PlayerController = get_parent().get_parent() as PlayerController
		if player.get_nearest_interactable():
			player.interact_with_nearest()


func physics_update(_delta: float) -> void:
	if GameState.current_mode != GameState.GameMode.OVERWORLD:
		return
	var player: PlayerController = get_parent().get_parent() as PlayerController
	var direction: Vector3 = player.get_movement_input()
	if direction.length_squared() > 0.01:
		state_finished.emit("Walk", {})


func _on_game_state_changed(new_mode: GameState.GameMode) -> void:
	if new_mode == GameState.GameMode.DIALOGUE:
		state_finished.emit("Interact", {})
