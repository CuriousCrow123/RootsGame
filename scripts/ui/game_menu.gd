extends CanvasLayer
## Tabbed in-game menu with Quest, Inventory, Stats, and Pause tabs.
## Opened/closed by HUD. Tab switching handled explicitly via _input().
## Open/close has slide+fade transition (0.2s).

const THEME_RES: Theme = preload("res://resources/themes/main_theme.tres")
const TRANSITION_DURATION: float = 0.2
const SLIDE_OFFSET: float = 80.0

var _last_tab_index: int = 0
var _menu_tween: Tween = null

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
	if _menu_tween and _menu_tween.is_valid():
		get_viewport().set_input_as_handled()
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


func is_animating() -> bool:
	return _menu_tween != null and _menu_tween.is_valid()


func open_menu(can_save_load: bool) -> void:
	visible = true
	_tab_container.current_tab = _last_tab_index
	# Find the pause tab by checking for set_save_load_enabled (last tab)
	var last_idx: int = _tab_container.get_tab_count() - 1
	var pause_tab: Control = _tab_container.get_tab_control(last_idx)
	if pause_tab.has_method("set_save_load_enabled"):
		pause_tab.call("set_save_load_enabled", can_save_load)
	# Slide in from right + fade
	_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_panel.position.x = SLIDE_OFFSET
	if _menu_tween and _menu_tween.is_valid():
		_menu_tween.kill()
	_menu_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_menu_tween.set_parallel(true)
	_menu_tween.tween_property(_panel, "modulate:a", 1.0, TRANSITION_DURATION).set_ease(
		Tween.EASE_OUT
	)
	(
		_menu_tween
		. tween_property(_panel, "position:x", 0.0, TRANSITION_DURATION)
		. set_ease(Tween.EASE_OUT)
		. set_trans(Tween.TRANS_CUBIC)
	)
	_menu_tween.chain().tween_callback(_set_tab_focus.bind(_last_tab_index))


func close_menu() -> void:
	_last_tab_index = _tab_container.current_tab
	if _menu_tween and _menu_tween.is_valid():
		_menu_tween.kill()
	_menu_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_menu_tween.set_parallel(true)
	_menu_tween.tween_property(_panel, "modulate:a", 0.0, TRANSITION_DURATION).set_ease(
		Tween.EASE_IN
	)
	(
		_menu_tween
		. tween_property(_panel, "position:x", SLIDE_OFFSET, TRANSITION_DURATION)
		. set_ease(Tween.EASE_IN)
		. set_trans(Tween.TRANS_CUBIC)
	)
	_menu_tween.chain().tween_callback(_on_close_complete)


func connect_to_player(player: PlayerController) -> void:
	for i: int in range(_tab_container.get_tab_count()):
		var tab: Control = _tab_container.get_tab_control(i)
		if tab.has_method("connect_to_player"):
			tab.call("connect_to_player", player)


func _on_close_complete() -> void:
	visible = false
	_panel.position.x = 0.0


func _on_tab_container_tab_changed(tab: int) -> void:
	_last_tab_index = tab
	_set_tab_focus.call_deferred(tab)


func _set_tab_focus(tab: int) -> void:
	var tab_control: Control = _tab_container.get_tab_control(tab)
	if tab_control.has_method("grab_initial_focus"):
		tab_control.call("grab_initial_focus")
