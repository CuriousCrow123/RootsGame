extends CanvasLayer
## Tabbed in-game menu with Quest, Inventory, Stats, and Pause tabs.
## Opened/closed by HUD. Tab switching handled explicitly via _input().

const THEME_RES: Theme = preload("res://resources/themes/main_theme.tres")

var _last_tab_index: int = 0

@onready var _panel: PanelContainer = $PanelContainer
@onready var _tab_container: TabContainer = $PanelContainer/TabContainer


func _ready() -> void:
	visible = false
	layer = 110
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.theme = THEME_RES
	_tab_container.get_tab_bar().focus_mode = Control.FOCUS_NONE
	_tab_container.tab_changed.connect(_on_tab_container_tab_changed)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_prev_tab"):
		_tab_container.current_tab = wrapi(
			_tab_container.current_tab - 1, 0, _tab_container.get_tab_count()
		)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("ui_next_tab"):
		_tab_container.current_tab = wrapi(
			_tab_container.current_tab + 1, 0, _tab_container.get_tab_count()
		)
		get_viewport().set_input_as_handled()


func open_menu(can_save_load: bool) -> void:
	visible = true
	_tab_container.current_tab = _last_tab_index
	var pause_tab: Control = _tab_container.get_tab_control(3)
	if pause_tab.has_method("set_save_load_enabled"):
		pause_tab.call("set_save_load_enabled", can_save_load)
	_set_tab_focus.call_deferred(_last_tab_index)


func close_menu() -> void:
	_last_tab_index = _tab_container.current_tab
	visible = false


func connect_to_player(player: PlayerController) -> void:
	for i: int in range(_tab_container.get_tab_count()):
		var tab: Control = _tab_container.get_tab_control(i)
		if tab.has_method("connect_to_player"):
			tab.call("connect_to_player", player)


func _on_tab_container_tab_changed(tab: int) -> void:
	_last_tab_index = tab
	_set_tab_focus.call_deferred(tab)


func _set_tab_focus(tab: int) -> void:
	var tab_control: Control = _tab_container.get_tab_control(tab)
	if tab_control.has_method("grab_initial_focus"):
		tab_control.call("grab_initial_focus")
