class_name BTRandomChance
extends BTLeaf
## Succeeds with the given probability (0.0–1.0). Evaluated once per activation.

@export_range(0.0, 1.0) var probability: float = 0.5

var _result: Status = Status.FAILURE


func bt_enter(_blackboard: Dictionary) -> void:
	_result = Status.SUCCESS if randf() <= probability else Status.FAILURE


func _tick(_delta: float, _blackboard: Dictionary) -> Status:
	return _result
