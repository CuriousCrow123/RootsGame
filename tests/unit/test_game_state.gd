extends GutTest
## Unit tests for GameState mode switching.

var _game_state: Node
var _received_mode: int = -1


func before_each() -> void:
	# Use a fresh instance, not the autoload, so tests are isolated
	_game_state = load("res://scripts/autoloads/game_state.gd").new()
	add_child_autofree(_game_state)
	_received_mode = -1


func test_initial_mode_is_overworld() -> void:
	assert_eq(_game_state.current_mode, _game_state.GameMode.OVERWORLD)


func test_set_mode_changes_current_mode() -> void:
	_game_state.set_mode(_game_state.GameMode.DIALOGUE)
	assert_eq(_game_state.current_mode, _game_state.GameMode.DIALOGUE)


func test_set_mode_emits_signal() -> void:
	watch_signals(_game_state)
	_game_state.set_mode(_game_state.GameMode.DIALOGUE)
	assert_signal_emitted_with_parameters(
		_game_state,
		"game_state_changed",
		[_game_state.GameMode.DIALOGUE],
	)


func test_set_same_mode_does_not_emit() -> void:
	watch_signals(_game_state)
	_game_state.set_mode(_game_state.GameMode.OVERWORLD)
	assert_signal_not_emitted(_game_state, "game_state_changed")


func test_mode_round_trip() -> void:
	_game_state.set_mode(_game_state.GameMode.DIALOGUE)
	_game_state.set_mode(_game_state.GameMode.OVERWORLD)
	assert_eq(_game_state.current_mode, _game_state.GameMode.OVERWORLD)
