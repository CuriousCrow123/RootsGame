extends Node
## Tracks global game mode. Used for input handling and system coordination.

signal game_state_changed(new_state: GameMode)

enum GameMode {
	OVERWORLD,
	BATTLE,
	MENU,
	DIALOGUE,
	CUTSCENE,
}

var current_mode: GameMode = GameMode.OVERWORLD


func set_mode(new_mode: GameMode) -> void:
	if current_mode != new_mode:
		current_mode = new_mode
		game_state_changed.emit(current_mode)
