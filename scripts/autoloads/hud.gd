extends Node
## Persistent HUD container. Instantiates UI scenes in _ready() so they
## survive scene transitions without reparenting. Connects to player via
## SceneManager.player_registered signal.
## Owns game menu lifecycle: opens on "pause" input, manages GameState mode.

var _notification_manager: CanvasLayer = null
var _quest_indicator: CanvasLayer = null
var _game_menu: CanvasLayer = null
var _is_menu_open: bool = false
var _mode_before_pause: GameState.GameMode = GameState.GameMode.OVERWORLD


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_notification_manager = preload("res://scenes/ui/notification_manager.tscn").instantiate()
	add_child(_notification_manager)
	_quest_indicator = preload("res://scenes/ui/quest_indicator.tscn").instantiate()
	add_child(_quest_indicator)
	_game_menu = preload("res://scenes/ui/game_menu.tscn").instantiate()
	add_child(_game_menu)
	# Wire notification anchor to sit below quest indicator panel
	var qi_panel: Control = _quest_indicator.get_node("PanelContainer")
	_notification_manager.call("set_offset_node", qi_panel)
	SceneManager.player_registered.connect(_on_player_registered)
	# Catch-up: if player was already registered before HUD._ready() ran
	var existing_player: PlayerController = SceneManager.get_player()
	if existing_player:
		_on_player_registered(existing_player)


func _input(event: InputEvent) -> void:
	# Use _input (not _unhandled_input) because Tab is consumed by
	# UI focus navigation before _unhandled_input sees it.
	if event.is_action_pressed("pause"):
		if _is_menu_open:
			close_game_menu()
		elif GameState.current_mode == GameState.GameMode.OVERWORLD:
			open_game_menu()
		get_viewport().set_input_as_handled()


func open_game_menu() -> void:
	if _is_menu_open:
		return
	_is_menu_open = true
	_mode_before_pause = GameState.current_mode
	var can_save_load: bool = _mode_before_pause == GameState.GameMode.OVERWORLD
	GameState.set_mode(GameState.GameMode.MENU)
	get_tree().paused = true
	_game_menu.call("open_menu", can_save_load)


func close_game_menu() -> void:
	if not _is_menu_open:
		return
	_is_menu_open = false
	get_tree().paused = false
	_game_menu.call("close_menu")
	GameState.set_mode(_mode_before_pause)


## Show a notification via the notification manager.
func show_notification(text: String, type: StringName = &"info") -> void:
	_notification_manager.call("show_notification", text, type)


func _on_player_registered(player: PlayerController) -> void:
	_notification_manager.call("connect_to_player", player)
	_quest_indicator.call("connect_to_player", player)
	_game_menu.call("connect_to_player", player)
