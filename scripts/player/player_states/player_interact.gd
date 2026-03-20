extends State
## Blocks movement during NPC dialogue. Exits when GameState returns to OVERWORLD.


func enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	var player: PlayerController = owner as PlayerController
	player.velocity = Vector3.ZERO
	GameState.game_state_changed.connect(_on_game_state_changed)
	# Disable state machine processing during interaction
	var sm: StateMachine = get_parent() as StateMachine
	sm.set_active(false)
	# Re-enable just enough for this state to receive the callback
	sm.set_process(true)


func exit() -> void:
	if GameState.game_state_changed.is_connected(_on_game_state_changed):
		GameState.game_state_changed.disconnect(_on_game_state_changed)
	var sm: StateMachine = get_parent() as StateMachine
	sm.set_active(true)


func _on_game_state_changed(new_mode: GameState.GameMode) -> void:
	if new_mode == GameState.GameMode.OVERWORLD:
		state_finished.emit("Idle", {})
