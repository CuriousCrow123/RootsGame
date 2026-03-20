class_name QuestStepData
extends Resource
## A single step in a quest. Dialogue files handle condition logic via if/do.

@export var step_id: String = ""
@export var description: String = ""
@export var next_step_id: String = ""  # Empty string = terminal step
