extends VBoxContainer
## Quest tab with expandable accordion entries and active/completed filters.
## Uses QuestTracker public API. Tracked quest appears at top, expanded.

enum FilterMode { ALL, ACTIVE, COMPLETED }

const ENTRY_SCENE: PackedScene = preload("res://scenes/ui/components/quest_entry.tscn")

var _quest_tracker: QuestTracker = null
var _filter_mode: FilterMode = FilterMode.ALL
var _tracked_quest_id: String = ""

@onready var _quest_list: VBoxContainer = $ScrollContainer/QuestList
@onready var _empty_label: Label = $EmptyLabel
@onready var _scroll: ScrollContainer = $ScrollContainer


func _ready() -> void:
	_scroll.follow_focus = true


func connect_to_player(player: PlayerController) -> void:
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


func set_filter(mode: FilterMode) -> void:
	_filter_mode = mode
	_refresh_list()


func _on_quests_changed() -> void:
	_refresh_list()


func _refresh_list() -> void:
	for child: Node in _quest_list.get_children():
		_quest_list.remove_child(child)
		child.queue_free()
	if not _quest_tracker:
		_empty_label.visible = true
		return
	var active: Array[Dictionary] = _quest_tracker.get_active_quests()
	var completed: Array[Dictionary] = _quest_tracker.get_completed_quests()
	var show_active: bool = _filter_mode != FilterMode.COMPLETED
	var show_completed: bool = _filter_mode != FilterMode.ACTIVE
	var has_entries: bool = false
	# Tracked quest first (if active and filter allows)
	if show_active and _tracked_quest_id != "":
		for i: int in range(active.size()):
			if str(active[i]["quest_id"]) == _tracked_quest_id:
				_add_entry(active[i], true)
				active.remove_at(i)
				has_entries = true
				break
	# Remaining active quests
	if show_active:
		for quest: Dictionary in active:
			_add_entry(quest, false)
			has_entries = true
	# Completed quests
	if show_completed and not completed.is_empty():
		for quest: Dictionary in completed:
			_add_entry(quest, false)
			has_entries = true
	_empty_label.visible = not has_entries


func _add_entry(quest_data: Dictionary, expanded: bool) -> void:
	var entry: PanelContainer = ENTRY_SCENE.instantiate()
	_quest_list.add_child(entry)
	entry.call("setup", quest_data, expanded)


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
