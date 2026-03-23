extends PanelContainer
## Expandable quest entry for the quest tab accordion.
## Click or press ui_accept to toggle expand/collapse.

signal track_requested(quest_id: String)

var _quest_id: String = ""
var _is_expanded: bool = false
var _is_completed: bool = false
var _expand_tween: Tween = null

@onready var _quest_name: Label = %QuestName
@onready var _status_badge: Label = %StatusBadge
@onready var _details: VBoxContainer = %DetailsContainer
@onready var _step_label: Label = %StepLabel


func setup(quest_data: Dictionary, expanded: bool = false) -> void:
	_quest_id = str(quest_data["quest_id"])
	_is_completed = quest_data["state"] == QuestTracker.QuestState.COMPLETE
	if is_node_ready():
		_apply_data(quest_data, expanded)
	else:
		ready.connect(_apply_data.bind(quest_data, expanded), CONNECT_ONE_SHOT)


func get_quest_id() -> String:
	return _quest_id


func is_expanded() -> bool:
	return _is_expanded


func _apply_data(quest_data: Dictionary, expanded: bool) -> void:
	_quest_name.text = str(quest_data["display_name"])
	if _is_completed:
		_status_badge.text = "Complete"
		_quest_name.theme_type_variation = &"DimLabel"
		_status_badge.theme_type_variation = &"DimLabel"
	else:
		_status_badge.text = "Active"
	var step_desc: String = str(quest_data["step_description"])
	_step_label.text = step_desc if step_desc != "" else "No current objective."
	if expanded:
		_is_expanded = true
		_details.visible = true


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	gui_input.connect(_on_gui_input)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_toggle_expand()
			accept_event()
	elif event.is_action_pressed("ui_accept"):
		_toggle_expand()
		accept_event()


func _toggle_expand() -> void:
	_is_expanded = not _is_expanded
	_details.visible = _is_expanded


func _on_mouse_entered() -> void:
	if not _is_completed:
		modulate = Color(1.1, 1.1, 1.1, 1.0)


func _on_mouse_exited() -> void:
	modulate = Color(1.0, 1.0, 1.0, 1.0)


func _exit_tree() -> void:
	if _expand_tween and _expand_tween.is_valid():
		_expand_tween.kill()
