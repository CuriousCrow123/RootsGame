extends GutTest
## Unit tests for GameState mode switching.

var _game_state: Node
var _received_mode: int = -1


func before_each() -> void:
	# Use a fresh instance, not the autoload, so tests are isolated
	var script: GDScript = load("res://scripts/autoloads/game_state.gd")
	_game_state = script.new()
	add_child_autofree(_game_state)
	_received_mode = -1


func test_initial_mode_is_overworld() -> void:
	var mode: int = _game_state.get("current_mode")
	assert_eq(mode, 0)


func test_set_mode_changes_current_mode() -> void:
	_game_state.call("set_mode", 3)  # DIALOGUE
	var mode: int = _game_state.get("current_mode")
	assert_eq(mode, 3)


func test_set_mode_emits_signal() -> void:
	watch_signals(_game_state)
	_game_state.call("set_mode", 3)  # DIALOGUE
	assert_signal_emitted(_game_state, "game_state_changed")


func test_set_same_mode_does_not_emit() -> void:
	watch_signals(_game_state)
	_game_state.call("set_mode", 0)  # OVERWORLD (same as initial)
	assert_signal_not_emitted(_game_state, "game_state_changed")


func test_mode_round_trip() -> void:
	_game_state.call("set_mode", 3)  # DIALOGUE
	_game_state.call("set_mode", 0)  # OVERWORLD
	var mode: int = _game_state.get("current_mode")
	assert_eq(mode, 0)
