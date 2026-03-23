class_name BTSequence
extends BTComposite
## Resumptive sequence: resumes from the last RUNNING child on subsequent ticks.
## Runs children left-to-right. Returns FAILURE on first child failure.
## Returns SUCCESS when all children succeed. Empty sequence returns SUCCESS.


func _tick(delta: float, blackboard: Dictionary) -> Status:
	var children: Array[BTNode] = _get_bt_children()
	if children.is_empty():
		return Status.SUCCESS

	var start_index: int = maxi(_running_child_index, 0)

	for i: int in range(start_index, children.size()):
		var child: BTNode = children[i]
		var result: Status = child.execute(delta, blackboard)

		if result == Status.RUNNING:
			_running_child_index = i
			return Status.RUNNING
		if result == Status.FAILURE:
			_running_child_index = -1
			return Status.FAILURE

	_running_child_index = -1
	return Status.SUCCESS
