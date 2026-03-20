extends Node
## Persistent HUD container. Instantiates UI scenes in _ready() so they
## survive scene transitions without reparenting. Connects to player via
## SceneManager.player_registered signal.
## Owns pause menu lifecycle: opens on "pause" input, manages GameState mode.

var _interaction_prompt: CanvasLayer = null
var _item_toast: CanvasLayer = null
var _quest_indicator: CanvasLayer = null
var _pause_menu: CanvasLayer = null
var _is_pause_menu_open: bool = false
var _mode_before_pause: GameState.GameMode = GameState.GameMode.OVERWORLD


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_interaction_prompt = preload("res://scenes/ui/interaction_prompt.tscn").instantiate()
	add_child(_interaction_prompt)
	_item_toast = preload("res://scenes/ui/item_toast.tscn").instantiate()
	add_child(_item_toast)
	_quest_indicator = preload("res://scenes/ui/quest_indicator.tscn").instantiate()
	add_child(_quest_indicator)
	_pause_menu = preload("res://scenes/ui/pause_menu.tscn").instantiate()
	add_child(_pause_menu)
	SceneManager.player_registered.connect(_on_player_registered)
	# Catch-up: if player was already registered before HUD._ready() ran
	var existing_player: PlayerController = SceneManager.get_player()
	if existing_player:
		_on_player_registered(existing_player)


func _input(event: InputEvent) -> void:
	# Use _input (not _unhandled_input) because Tab is consumed by
	# UI focus navigation before _unhandled_input sees it.
	if event.is_action_pressed("pause"):
		if _is_pause_menu_open:
			close_pause_menu()
		elif GameState.current_mode != GameState.GameMode.MENU:
			open_pause_menu()
		get_viewport().set_input_as_handled()


func open_pause_menu() -> void:
	if _is_pause_menu_open:
		return
	_is_pause_menu_open = true
	_mode_before_pause = GameState.current_mode
	var can_save_load: bool = _mode_before_pause == GameState.GameMode.OVERWORLD
	GameState.set_mode(GameState.GameMode.MENU)
	get_tree().paused = true
	_pause_menu.call("open_menu", can_save_load)


func close_pause_menu() -> void:
	if not _is_pause_menu_open:
		return
	_is_pause_menu_open = false
	get_tree().paused = false
	_pause_menu.call("close_menu")
	GameState.set_mode(_mode_before_pause)


func _on_player_registered(player: PlayerController) -> void:
	_interaction_prompt.call("connect_to_player", player)
	_item_toast.call("connect_to_player", player)
	_quest_indicator.call("connect_to_player", player)
