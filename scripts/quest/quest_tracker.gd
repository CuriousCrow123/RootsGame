class_name QuestTracker
extends Node
## Tracks active quests and their current step. Dialogue files drive all
## condition logic — this class only manages state transitions.
## Accessed by Dialogue Manager via extra_game_states.

signal quest_started(quest_id: String)
signal quest_step_completed(quest_id: String, step_id: String)
signal quest_completed(quest_id: String)

enum QuestState { INACTIVE, ACTIVE, COMPLETE }

# { quest_id: { "state": QuestState, "current_step_id": String, "data": QuestData } }
var _quests: Dictionary = {}


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
		save[qid] = {
			"state": _quests[qid]["state"],
			"current_step_id": _quests[qid]["current_step_id"],
		}
	return save


func load_save_data(data: Dictionary) -> void:
	for qid: String in data:
		if _quests.has(qid):
			@warning_ignore("unsafe_cast")
			var entry: Dictionary = data[qid] as Dictionary
			@warning_ignore("unsafe_call_argument")
			_quests[qid]["state"] = entry.get("state", QuestState.INACTIVE)
			@warning_ignore("unsafe_call_argument")
			_quests[qid]["current_step_id"] = entry.get("current_step_id", "")


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
