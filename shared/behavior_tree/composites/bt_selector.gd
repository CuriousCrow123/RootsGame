class_name BTSelector
extends BTComposite
## Reactive selector: re-evaluates from child 0 every tick.
## Returns SUCCESS on first child that succeeds.
## If a higher-priority child preempts a RUNNING lower-priority child,
## the lower-priority child is aborted via abort().
## Returns FAILURE if all children fail. Empty selector returns FAILURE.


func _tick(delta: float, blackboard: Dictionary) -> Status:
	var children: Array[BTNode] = _get_bt_children()
	if children.is_empty():
		return Status.FAILURE

	for i: int in children.size():
		var child: BTNode = children[i]
		var result: Status = child.execute(delta, blackboard)

		if result == Status.RUNNING or result == Status.SUCCESS:
			# Abort the previously RUNNING child if it's a different one.
			if _running_child_index >= 0 and _running_child_index != i:
				children[_running_child_index].abort(blackboard)
			_running_child_index = i if result == Status.RUNNING else -1
			return result

	_running_child_index = -1
	return Status.FAILURE
