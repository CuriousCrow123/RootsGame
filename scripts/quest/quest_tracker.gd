class_name QuestTracker
extends Node
## Tracks active quests and their current step. Dialogue files drive all
## condition logic — this class only manages state transitions.
## Accessed by Dialogue Manager via extra_game_states.

signal quest_started(quest_id: String)
signal quest_step_completed(quest_id: String, step_id: String)
signal quest_completed(quest_id: String)
signal quests_reset

enum QuestState { INACTIVE, ACTIVE, COMPLETE }

# { quest_id: { "state": QuestState, "current_step_id": String, "data": QuestData } }
var _quests: Dictionary = {}


func _ready() -> void:
	SaveManager.register(self)


func start_quest(quest_data: QuestData) -> void:
	var qid: String = quest_data.quest_id
	if _quests.has(qid):
		return
	var first_step_id: String = ""
	if quest_data.steps.size() > 0:
		first_step_id = quest_data.steps[0].step_id
	_quests[qid] = {
		"state": QuestState.ACTIVE,
		"current_step_id": first_step_id,
		"data": quest_data,
	}
	quest_started.emit(qid)


func advance_quest(quest_id: String) -> void:
	if not _quests.has(quest_id):
		return
	var quest_info: Dictionary = _quests[quest_id]
	var step: QuestStepData = _get_current_step(quest_id)
	if not step:
		return
	quest_step_completed.emit(quest_id, step.step_id)
	if step.next_step_id == "":
		quest_info["state"] = QuestState.COMPLETE
		quest_info["current_step_id"] = ""
		quest_completed.emit(quest_id)
	else:
		quest_info["current_step_id"] = step.next_step_id


func get_quest_state(quest_id: String) -> QuestState:
	if not _quests.has(quest_id):
		return QuestState.INACTIVE
	@warning_ignore("unsafe_call_argument")
	var state: QuestState = _quests[quest_id]["state"]
	return state


func is_quest_active(quest_id: String) -> bool:
	return get_quest_state(quest_id) == QuestState.ACTIVE


func is_quest_complete(quest_id: String) -> bool:
	return get_quest_state(quest_id) == QuestState.COMPLETE


func get_display_name(quest_id: String) -> String:
	if not _quests.has(quest_id):
		return quest_id
	@warning_ignore("unsafe_cast")
	var quest_data: QuestData = _quests[quest_id]["data"] as QuestData
	if quest_data:
		return quest_data.display_name
	return quest_id


func get_current_step_description(quest_id: String) -> String:
	var step: QuestStepData = _get_current_step(quest_id)
	if step:
		return step.description
	return ""


func get_save_key() -> String:
	return "quest_tracker"


func get_save_data() -> Dictionary:
	var save: Dictionary = {}
	for qid: String in _quests:
		@warning_ignore("unsafe_cast")
		var quest_data: QuestData = _quests[qid]["data"] as QuestData
		save[qid] = {
			"state": _quests[qid]["state"],
			"current_step_id": _quests[qid]["current_step_id"],
			"resource_path": quest_data.resource_path if quest_data else "",
		}
	return save


func load_save_data(data: Dictionary) -> void:
	# Clear then rebuild — save file is the single source of truth
	_quests.clear()
	for qid: String in data:
		@warning_ignore("unsafe_cast")
		var entry: Dictionary = data[qid] as Dictionary
		var res_path: String = entry.get("resource_path", "")
		if res_path == "":
			push_warning("Quest '%s' has no resource_path in save data, skipping" % qid)
			continue
		@warning_ignore("unsafe_cast")
		var quest_data: QuestData = load(res_path) as QuestData
		if not quest_data:
			push_warning("Failed to load QuestData at '%s' for quest '%s'" % [res_path, qid])
			continue
		_quests[qid] = {
			"state": entry.get("state", QuestState.INACTIVE),
			"current_step_id": entry.get("current_step_id", ""),
			"data": quest_data,
		}
	quests_reset.emit()


# -- Private --


func _get_current_step(quest_id: String) -> QuestStepData:
	if not _quests.has(quest_id):
		return null
	var quest_info: Dictionary = _quests[quest_id]
	@warning_ignore("unsafe_cast")
	var quest_data: QuestData = quest_info["data"] as QuestData
	if not quest_data:
		return null
	for step: QuestStepData in quest_data.steps:
		if step.step_id == quest_info["current_step_id"]:
			return step
	return null
