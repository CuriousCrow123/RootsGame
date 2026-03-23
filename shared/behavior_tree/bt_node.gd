class_name BTNode
extends Node
## Base class for all behavior tree nodes. Subclasses override _tick().
## The execute() wrapper manages the bt_enter/bt_exit lifecycle automatically.
## Never use await inside _tick() — return RUNNING and poll on subsequent ticks.

enum Status { SUCCESS, FAILURE, RUNNING }

## Exposed for debugging in the Remote inspector.
var status: Status = Status.FAILURE
var _debug_tick_count: int = 0
var _debug_last_tick_usec: int = 0


func execute(delta: float, blackboard: Dictionary) -> Status:
	if status != Status.RUNNING:
		bt_enter(blackboard)
	var start: int = Time.get_ticks_usec() if OS.is_debug_build() else 0
	status = _tick(delta, blackboard)
	if OS.is_debug_build():
		_debug_tick_count += 1
		_debug_last_tick_usec = Time.get_ticks_usec() - start
	if status != Status.RUNNING:
		bt_exit(blackboard)
	return status


## Recursively aborts this node and all RUNNING descendants.
## MUST be called when a parent interrupts a RUNNING child.
func abort(blackboard: Dictionary) -> void:
	if status == Status.RUNNING:
		bt_exit(blackboard)
		status = Status.FAILURE
	for child: Node in get_children():
		if child is BTNode:
			var bt_child: BTNode = child as BTNode
			bt_child.abort(blackboard)


## Override in subclasses. Return SUCCESS, FAILURE, or RUNNING.
func _tick(_delta: float, _blackboard: Dictionary) -> Status:
	return Status.FAILURE


## Called once when transitioning from non-RUNNING to active.
func bt_enter(_blackboard: Dictionary) -> void:
	pass


## Called when node completes (SUCCESS/FAILURE) or is aborted.
func bt_exit(_blackboard: Dictionary) -> void:
	pass


## Override in leaf nodes to persist behavior-specific state.
func bt_get_state() -> Dictionary:
	return {}


## Override in leaf nodes to restore behavior-specific state.
func bt_load_state(_data: Dictionary) -> void:
	pass
