extends VBoxContainer
## Quest list from QuestTracker. Active quests first, completed below.
## Uses QuestTracker public API (never accesses private members).

var _quest_tracker: QuestTracker = null

@onready var _quest_list: VBoxContainer = $ScrollContainer/QuestList
@onready var _empty_label: Label = $EmptyLabel


func connect_to_player(player: PlayerController) -> void:
	# Disconnect old connections if reconnecting (e.g., after load_game)
	_disconnect_signals()
	_quest_tracker = player.get_quest_tracker()
	if _quest_tracker:
		_quest_tracker.quest_started.connect(_on_quests_changed.unbind(1))
		_quest_tracker.quest_step_completed.connect(_on_quests_changed.unbind(2))
		_quest_tracker.quest_completed.connect(_on_quests_changed.unbind(1))
		_quest_tracker.quests_reset.connect(_on_quests_changed)
		_refresh_list()


func _exit_tree() -> void:
	_disconnect_signals()


func grab_initial_focus() -> void:
	if _quest_list.get_child_count() > 0:
		var first: Control = _quest_list.get_child(0) as Control
		if first:
			first.grab_focus()


func _on_quests_changed() -> void:
	_refresh_list()


func _refresh_list() -> void:
	# remove_child + queue_free prevents zombie children for one frame
	for child: Node in _quest_list.get_children():
		_quest_list.remove_child(child)
		child.queue_free()
	if not _quest_tracker:
		_empty_label.visible = true
		return
	var active: Array[Dictionary] = _quest_tracker.get_active_quests()
	var completed: Array[Dictionary] = _quest_tracker.get_completed_quests()
	_empty_label.visible = active.is_empty() and completed.is_empty()
	for quest: Dictionary in active:
		var label: Label = Label.new()
		var display: String = quest["display_name"]
		var step_desc: String = quest["step_description"]
		label.text = "%s — %s" % [display, step_desc] if step_desc != "" else display
		label.focus_mode = Control.FOCUS_ALL
		_quest_list.add_child(label)
	if not completed.is_empty():
		var header: Label = Label.new()
		header.text = "— Completed —"
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_quest_list.add_child(header)
		for quest: Dictionary in completed:
			var label: Label = Label.new()
			label.text = quest["display_name"]
			label.modulate = Color(1.0, 1.0, 1.0, 0.5)
			label.focus_mode = Control.FOCUS_ALL
			_quest_list.add_child(label)


func _disconnect_signals() -> void:
	if not _quest_tracker:
		return
	if _quest_tracker.quest_started.is_connected(_on_quests_changed.unbind(1)):
		_quest_tracker.quest_started.disconnect(_on_quests_changed.unbind(1))
	if _quest_tracker.quest_step_completed.is_connected(_on_quests_changed.unbind(2)):
		_quest_tracker.quest_step_completed.disconnect(_on_quests_changed.unbind(2))
	if _quest_tracker.quest_completed.is_connected(_on_quests_changed.unbind(1)):
		_quest_tracker.quest_completed.disconnect(_on_quests_changed.unbind(1))
	if _quest_tracker.quests_reset.is_connected(_on_quests_changed):
		_quest_tracker.quests_reset.disconnect(_on_quests_changed)
