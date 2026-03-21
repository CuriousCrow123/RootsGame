extends VBoxContainer
## Read-only quest list from QuestTracker. Active quests first, completed below.

var _quest_tracker: QuestTracker = null

@onready var _quest_list: VBoxContainer = $ScrollContainer/QuestList
@onready var _empty_label: Label = $EmptyLabel


func connect_to_player(player: PlayerController) -> void:
	_quest_tracker = player.get_quest_tracker()
	if _quest_tracker:
		_quest_tracker.quest_started.connect(_on_quests_changed.unbind(1))
		_quest_tracker.quest_step_completed.connect(_on_quests_changed.unbind(2))
		_quest_tracker.quest_completed.connect(_on_quests_changed.unbind(1))
		_quest_tracker.quests_reset.connect(_on_quests_changed)


func grab_initial_focus() -> void:
	if _quest_list.get_child_count() > 0:
		var first: Control = _quest_list.get_child(0) as Control
		if first:
			first.grab_focus()


func _on_quests_changed() -> void:
	_refresh_list()


func _refresh_list() -> void:
	for child: Node in _quest_list.get_children():
		child.queue_free()
	if not _quest_tracker:
		_empty_label.visible = true
		return
	var quests: Dictionary = _quest_tracker._quests
	var active_ids: Array[String] = []
	var complete_ids: Array[String] = []
	for qid: String in quests:
		var state: int = quests[qid]["state"]
		if state == QuestTracker.QuestState.ACTIVE:
			active_ids.append(qid)
		elif state == QuestTracker.QuestState.COMPLETE:
			complete_ids.append(qid)
	_empty_label.visible = active_ids.is_empty() and complete_ids.is_empty()
	for qid: String in active_ids:
		var label: Label = Label.new()
		var display: String = _quest_tracker.get_display_name(qid)
		var step_desc: String = _quest_tracker.get_current_step_description(qid)
		label.text = "%s — %s" % [display, step_desc] if step_desc != "" else display
		label.focus_mode = Control.FOCUS_ALL
		_quest_list.add_child(label)
	if not complete_ids.is_empty():
		var header: Label = Label.new()
		header.text = "— Completed —"
		header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_quest_list.add_child(header)
		for qid: String in complete_ids:
			var label: Label = Label.new()
			label.text = _quest_tracker.get_display_name(qid)
			label.modulate = Color(1.0, 1.0, 1.0, 0.5)
			label.focus_mode = Control.FOCUS_ALL
			_quest_list.add_child(label)
