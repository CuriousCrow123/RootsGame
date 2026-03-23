class_name BTRepeater
extends BTDecorator
## Repeats its child a fixed number of times, or forever if repeat_count is 0.
## Returns RUNNING while repeating. Returns FAILURE if child fails (aborts the loop).

## Number of times to repeat. 0 = repeat forever.
@export var repeat_count: int = 0

var _current_count: int = 0


func bt_enter(_blackboard: Dictionary) -> void:
	_current_count = 0


func _tick(delta: float, blackboard: Dictionary) -> Status:
	var child: BTNode = _get_bt_child()
	if child == null:
		return Status.FAILURE

	var result: Status = child.execute(delta, blackboard)

	if result == Status.RUNNING:
		return Status.RUNNING
	if result == Status.FAILURE:
		return Status.FAILURE

	# Child succeeded — count and check if done.
	_current_count += 1
	if repeat_count > 0 and _current_count >= repeat_count:
		return Status.SUCCESS

	return Status.RUNNING


func bt_get_state() -> Dictionary:
	return {"current_count": _current_count}


func bt_load_state(data: Dictionary) -> void:
	_current_count = data.get("current_count", 0) as int
