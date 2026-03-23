class_name BTInverter
extends BTDecorator
## Inverts the result of its child: SUCCESS becomes FAILURE, FAILURE becomes SUCCESS.
## RUNNING passes through unchanged.


func _tick(delta: float, blackboard: Dictionary) -> Status:
	var child: BTNode = _get_bt_child()
	if child == null:
		return Status.FAILURE

	var result: Status = child.execute(delta, blackboard)

	match result:
		Status.SUCCESS:
			return Status.FAILURE
		Status.FAILURE:
			return Status.SUCCESS
		_:
			return Status.RUNNING
