# gdlint: ignore=max-public-methods
extends GutTest
## Unit tests for the behavior tree framework.

var _blackboard: Dictionary


func before_each() -> void:
	_blackboard = {}


# ---------------------------------------------------------------------------
# Helper leaf nodes for testing
# ---------------------------------------------------------------------------


class SuccessLeaf:
	extends BTLeaf

	func _tick(_delta: float, _blackboard: Dictionary) -> Status:
		return Status.SUCCESS


class FailureLeaf:
	extends BTLeaf

	func _tick(_delta: float, _blackboard: Dictionary) -> Status:
		return Status.FAILURE


class RunningLeaf:
	extends BTLeaf
	var tick_count: int = 0
	var finish_after: int = -1  # -1 = never finish

	func _tick(_delta: float, _blackboard: Dictionary) -> Status:
		tick_count += 1
		if finish_after > 0 and tick_count >= finish_after:
			return Status.SUCCESS
		return Status.RUNNING


class TrackingLeaf:
	extends BTLeaf
	## Tracks enter/exit/tick calls for verifying lifecycle.
	var entered: bool = false
	var exited: bool = false
	var tick_count: int = 0
	var result_to_return: BTNode.Status = BTNode.Status.SUCCESS

	func bt_enter(_blackboard: Dictionary) -> void:
		entered = true

	func bt_exit(_blackboard: Dictionary) -> void:
		exited = true

	func _tick(_delta: float, _blackboard: Dictionary) -> Status:
		tick_count += 1
		return result_to_return


class StatefulLeaf:
	extends BTLeaf
	## Leaf that saves and restores state for serialization tests.
	var counter: int = 0

	func _tick(_delta: float, _blackboard: Dictionary) -> Status:
		counter += 1
		return Status.SUCCESS

	func bt_get_state() -> Dictionary:
		return {"counter": counter}

	func bt_load_state(data: Dictionary) -> void:
		counter = data.get("counter", 0) as int


# ---------------------------------------------------------------------------
# BTNode base tests
# ---------------------------------------------------------------------------


func test_node_default_status_is_failure() -> void:
	var node: BTNode = BTNode.new()
	add_child_autofree(node)
	assert_eq(node.status, BTNode.Status.FAILURE)


func test_node_execute_calls_enter_on_first_tick() -> void:
	var leaf: TrackingLeaf = TrackingLeaf.new()
	add_child_autofree(leaf)
	leaf.execute(0.1, _blackboard)
	assert_true(leaf.entered)


func test_node_execute_calls_exit_on_success() -> void:
	var leaf: TrackingLeaf = TrackingLeaf.new()
	add_child_autofree(leaf)
	leaf.result_to_return = BTNode.Status.SUCCESS
	leaf.execute(0.1, _blackboard)
	assert_true(leaf.exited)


func test_node_execute_does_not_call_exit_on_running() -> void:
	var leaf: TrackingLeaf = TrackingLeaf.new()
	add_child_autofree(leaf)
	leaf.result_to_return = BTNode.Status.RUNNING
	leaf.execute(0.1, _blackboard)
	assert_false(leaf.exited)


func test_node_execute_does_not_reenter_while_running() -> void:
	var leaf: TrackingLeaf = TrackingLeaf.new()
	add_child_autofree(leaf)
	leaf.result_to_return = BTNode.Status.RUNNING
	leaf.execute(0.1, _blackboard)
	leaf.entered = false  # Reset to detect re-entry.
	leaf.execute(0.1, _blackboard)
	assert_false(leaf.entered, "bt_enter should not be called again while RUNNING")


func test_node_abort_calls_exit_on_running_node() -> void:
	var leaf: TrackingLeaf = TrackingLeaf.new()
	add_child_autofree(leaf)
	leaf.result_to_return = BTNode.Status.RUNNING
	leaf.execute(0.1, _blackboard)
	leaf.abort(_blackboard)
	assert_true(leaf.exited)
	assert_eq(leaf.status, BTNode.Status.FAILURE)


func test_node_abort_propagates_to_children() -> void:
	var parent: BTNode = BTNode.new()
	var child: TrackingLeaf = TrackingLeaf.new()
	child.result_to_return = BTNode.Status.RUNNING
	parent.add_child(child)
	add_child_autofree(parent)

	child.execute(0.1, _blackboard)
	parent.abort(_blackboard)
	assert_true(child.exited)


# ---------------------------------------------------------------------------
# BTSelector tests (reactive)
# ---------------------------------------------------------------------------


func test_selector_returns_failure_when_empty() -> void:
	var selector: BTSelector = BTSelector.new()
	add_child_autofree(selector)
	var result: BTNode.Status = selector.execute(0.1, _blackboard)
	assert_eq(result, BTNode.Status.FAILURE)


func test_selector_returns_first_success() -> void:
	var selector: BTSelector = BTSelector.new()
	selector.add_child(FailureLeaf.new())
	selector.add_child(SuccessLeaf.new())
	selector.add_child(FailureLeaf.new())
	add_child_autofree(selector)

	var result: BTNode.Status = selector.execute(0.1, _blackboard)
	assert_eq(result, BTNode.Status.SUCCESS)


func test_selector_returns_failure_when_all_fail() -> void:
	var selector: BTSelector = BTSelector.new()
	selector.add_child(FailureLeaf.new())
	selector.add_child(FailureLeaf.new())
	add_child_autofree(selector)

	var result: BTNode.Status = selector.execute(0.1, _blackboard)
	assert_eq(result, BTNode.Status.FAILURE)


func test_selector_returns_running_from_child() -> void:
	var selector: BTSelector = BTSelector.new()
	selector.add_child(FailureLeaf.new())
	selector.add_child(RunningLeaf.new())
	add_child_autofree(selector)

	var result: BTNode.Status = selector.execute(0.1, _blackboard)
	assert_eq(result, BTNode.Status.RUNNING)


func test_selector_reactive_aborts_lower_priority_running_child() -> void:
	# Child 0: fails first tick, succeeds second tick (simulates condition becoming true).
	# Child 1: returns RUNNING.
	var selector: BTSelector = BTSelector.new()
	var high_priority: TrackingLeaf = TrackingLeaf.new()
	high_priority.result_to_return = BTNode.Status.FAILURE
	var low_priority: TrackingLeaf = TrackingLeaf.new()
	low_priority.result_to_return = BTNode.Status.RUNNING
	selector.add_child(high_priority)
	selector.add_child(low_priority)
	add_child_autofree(selector)

	# Tick 1: child 0 fails, child 1 runs.
	selector.execute(0.1, _blackboard)
	assert_eq(selector.status, BTNode.Status.RUNNING)
	assert_false(low_priority.exited, "Low priority should still be running")

	# Tick 2: child 0 now succeeds — should abort child 1.
	high_priority.result_to_return = BTNode.Status.SUCCESS
	high_priority.exited = false  # Reset to detect new exit call.
	low_priority.exited = false
	selector.execute(0.1, _blackboard)
	assert_eq(selector.status, BTNode.Status.SUCCESS)
	assert_true(low_priority.exited, "Low priority should have been aborted")


# ---------------------------------------------------------------------------
# BTSequence tests (resumptive)
# ---------------------------------------------------------------------------


func test_sequence_returns_success_when_empty() -> void:
	var seq: BTSequence = BTSequence.new()
	add_child_autofree(seq)
	var result: BTNode.Status = seq.execute(0.1, _blackboard)
	assert_eq(result, BTNode.Status.SUCCESS)


func test_sequence_returns_success_when_all_succeed() -> void:
	var seq: BTSequence = BTSequence.new()
	seq.add_child(SuccessLeaf.new())
	seq.add_child(SuccessLeaf.new())
	add_child_autofree(seq)

	var result: BTNode.Status = seq.execute(0.1, _blackboard)
	assert_eq(result, BTNode.Status.SUCCESS)


func test_sequence_returns_failure_on_first_failure() -> void:
	var seq: BTSequence = BTSequence.new()
	seq.add_child(SuccessLeaf.new())
	seq.add_child(FailureLeaf.new())
	seq.add_child(SuccessLeaf.new())
	add_child_autofree(seq)

	var result: BTNode.Status = seq.execute(0.1, _blackboard)
	assert_eq(result, BTNode.Status.FAILURE)


func test_sequence_resumes_from_running_child() -> void:
	var seq: BTSequence = BTSequence.new()
	var first: TrackingLeaf = TrackingLeaf.new()
	first.result_to_return = BTNode.Status.SUCCESS
	var second: RunningLeaf = RunningLeaf.new()
	second.finish_after = 2
	seq.add_child(first)
	seq.add_child(second)
	add_child_autofree(seq)

	# Tick 1: first succeeds, second returns RUNNING.
	seq.execute(0.1, _blackboard)
	assert_eq(seq.status, BTNode.Status.RUNNING)

	# Tick 2: sequence resumes from second (skips first).
	first.tick_count = 0
	seq.execute(0.1, _blackboard)
	assert_eq(first.tick_count, 0, "First child should not be re-ticked on resume")
	assert_eq(seq.status, BTNode.Status.SUCCESS)


# ---------------------------------------------------------------------------
# BTRepeater tests
# ---------------------------------------------------------------------------


func test_repeater_repeats_n_times() -> void:
	var repeater: BTRepeater = BTRepeater.new()
	repeater.repeat_count = 3
	var leaf: TrackingLeaf = TrackingLeaf.new()
	leaf.result_to_return = BTNode.Status.SUCCESS
	repeater.add_child(leaf)
	add_child_autofree(repeater)

	# Tick 1 and 2: still running (count 1 and 2).
	repeater.execute(0.1, _blackboard)
	assert_eq(repeater.status, BTNode.Status.RUNNING)
	repeater.execute(0.1, _blackboard)
	assert_eq(repeater.status, BTNode.Status.RUNNING)

	# Tick 3: count reaches 3, returns SUCCESS.
	repeater.execute(0.1, _blackboard)
	assert_eq(repeater.status, BTNode.Status.SUCCESS)


func test_repeater_stops_on_child_failure() -> void:
	var repeater: BTRepeater = BTRepeater.new()
	repeater.repeat_count = 5
	var leaf: TrackingLeaf = TrackingLeaf.new()
	leaf.result_to_return = BTNode.Status.FAILURE
	repeater.add_child(leaf)
	add_child_autofree(repeater)

	var result: BTNode.Status = repeater.execute(0.1, _blackboard)
	assert_eq(result, BTNode.Status.FAILURE)


func test_repeater_forever_returns_running() -> void:
	var repeater: BTRepeater = BTRepeater.new()
	repeater.repeat_count = 0  # forever
	var leaf: TrackingLeaf = TrackingLeaf.new()
	leaf.result_to_return = BTNode.Status.SUCCESS
	repeater.add_child(leaf)
	add_child_autofree(repeater)

	for i: int in 10:
		repeater.execute(0.1, _blackboard)
		assert_eq(repeater.status, BTNode.Status.RUNNING)


# ---------------------------------------------------------------------------
# BTInverter tests
# ---------------------------------------------------------------------------


func test_inverter_flips_success_to_failure() -> void:
	var inverter: BTInverter = BTInverter.new()
	inverter.add_child(SuccessLeaf.new())
	add_child_autofree(inverter)

	var result: BTNode.Status = inverter.execute(0.1, _blackboard)
	assert_eq(result, BTNode.Status.FAILURE)


func test_inverter_flips_failure_to_success() -> void:
	var inverter: BTInverter = BTInverter.new()
	inverter.add_child(FailureLeaf.new())
	add_child_autofree(inverter)

	var result: BTNode.Status = inverter.execute(0.1, _blackboard)
	assert_eq(result, BTNode.Status.SUCCESS)


func test_inverter_passes_running_through() -> void:
	var inverter: BTInverter = BTInverter.new()
	inverter.add_child(RunningLeaf.new())
	add_child_autofree(inverter)

	var result: BTNode.Status = inverter.execute(0.1, _blackboard)
	assert_eq(result, BTNode.Status.RUNNING)


# ---------------------------------------------------------------------------
# BT state serialization tests
# ---------------------------------------------------------------------------


func test_runner_serializes_leaf_state() -> void:
	var runner: BehaviorTreeRunner = BehaviorTreeRunner.new()
	add_child_autofree(runner)

	# Manually build a tree since we don't have a PackedScene.
	var selector: BTSelector = BTSelector.new()
	var leaf: StatefulLeaf = StatefulLeaf.new()
	leaf.name = "Counter"
	leaf.counter = 42
	selector.add_child(leaf)
	selector.name = "Root"
	runner.add_child(selector)
	runner._bt_root = selector

	var state: Dictionary = runner.get_bt_state()
	assert_true(state.has("/Counter"), "Should have leaf state keyed by path")
	var counter_val: int = state["/Counter"]["counter"] as int
	assert_eq(counter_val, 42)


func test_runner_restores_leaf_state() -> void:
	var runner: BehaviorTreeRunner = BehaviorTreeRunner.new()
	add_child_autofree(runner)

	var selector: BTSelector = BTSelector.new()
	var leaf: StatefulLeaf = StatefulLeaf.new()
	leaf.name = "Counter"
	selector.add_child(leaf)
	selector.name = "Root"
	runner.add_child(selector)
	runner._bt_root = selector

	var state: Dictionary = {"/Counter": {"counter": 99}}
	runner.load_bt_state(state)
	assert_eq(leaf.counter, 99)


# ---------------------------------------------------------------------------
# BehaviorTreeRunner interrupt/resume tests
# ---------------------------------------------------------------------------


func test_runner_interrupt_aborts_and_deactivates() -> void:
	var runner: BehaviorTreeRunner = BehaviorTreeRunner.new()
	add_child_autofree(runner)

	var leaf: TrackingLeaf = TrackingLeaf.new()
	leaf.result_to_return = BTNode.Status.RUNNING
	leaf.name = "Leaf"
	runner.add_child(leaf)
	runner._bt_root = leaf

	# Start the leaf running.
	leaf.execute(0.1, _blackboard)
	runner.blackboard = _blackboard
	runner.interrupt()
	assert_true(leaf.exited, "Interrupt should abort the running tree")
	assert_false(runner._is_active, "Runner should be deactivated after interrupt")


func test_runner_resume_reactivates() -> void:
	var runner: BehaviorTreeRunner = BehaviorTreeRunner.new()
	add_child_autofree(runner)

	runner._is_active = false
	runner.resume()
	assert_true(runner._is_active)
