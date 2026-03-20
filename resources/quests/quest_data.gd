class_name QuestData
extends Resource
## Definition for a quest with ordered steps.

@export var quest_id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export var steps: Array[QuestStepData] = []
