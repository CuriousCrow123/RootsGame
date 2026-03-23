class_name BTIdle
extends BTLeaf
## Idles for a configurable duration, then returns SUCCESS.

@export var duration: float = 2.0

var _elapsed: float = 0.0


func bt_enter(_blackboard: Dictionary) -> void:
	_elapsed = 0.0


func _tick(delta: float, _blackboard: Dictionary) -> Status:
	_elapsed += delta
	if _elapsed >= duration:
		return Status.SUCCESS
	return Status.RUNNING


func bt_get_state() -> Dictionary:
	return {"elapsed": _elapsed}


func bt_load_state(data: Dictionary) -> void:
	_elapsed = data.get("elapsed", 0.0) as float
