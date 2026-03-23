class_name BTWait
extends BTLeaf
## Waits for a random duration between min_duration and max_duration, then returns SUCCESS.

@export var min_duration: float = 1.0
@export var max_duration: float = 3.0

var _target_duration: float = 0.0
var _elapsed: float = 0.0


func bt_enter(_blackboard: Dictionary) -> void:
	_elapsed = 0.0
	_target_duration = randf_range(min_duration, max_duration)


func _tick(delta: float, _blackboard: Dictionary) -> Status:
	_elapsed += delta
	if _elapsed >= _target_duration:
		return Status.SUCCESS
	return Status.RUNNING
