class_name BehaviorTreeRunner
extends Node
## Drives a behavior tree by ticking its root node at a configurable interval.
## Manages the blackboard and provides interrupt/resume/swap for NPC interaction.

const _STUCK_WARNING_THRESHOLD: float = 30.0

@export var behavior_tree_scene: PackedScene
## Tick interval in seconds. Default 0.15 (~7 ticks/sec). Set to 0.0 for every physics frame.
@export var tick_interval: float = 0.15

var blackboard: Dictionary = {}

var _bt_root: BTNode = null
var _tick_timer: float = 0.0
var _is_active: bool = true
var _stuck_timer: float = 0.0


func _ready() -> void:
	# Stagger initial timer so NPCs don't all tick on the same frame.
	_tick_timer = randf_range(0.0, tick_interval) if tick_interval > 0.0 else 0.0
	if behavior_tree_scene:
		_bt_root = behavior_tree_scene.instantiate() as BTNode
		if _bt_root:
			add_child(_bt_root)


func _physics_process(delta: float) -> void:
	if is_queued_for_deletion():
		return
	if not _is_active or _bt_root == null:
		return

	if tick_interval > 0.0:
		_tick_timer += delta
		if _tick_timer < tick_interval:
			return
		_tick_timer -= tick_interval

	var result: BTNode.Status = _bt_root.execute(delta, blackboard)

	# Stuck detection (debug builds only).
	if OS.is_debug_build():
		if result == BTNode.Status.RUNNING:
			_stuck_timer += delta
			if _stuck_timer > _STUCK_WARNING_THRESHOLD:
				push_warning(
					"BT stuck RUNNING for >%.0fs on %s" % [_STUCK_WARNING_THRESHOLD, str(owner)]
				)
				_stuck_timer = 0.0
		else:
			_stuck_timer = 0.0


## Abort the active branch and deactivate. Used when player initiates dialogue.
func interrupt() -> void:
	if _bt_root:
		_bt_root.abort(blackboard)
	_is_active = false


## Reactivate after interrupt. BT evaluates from root next tick (fresh start).
func resume() -> void:
	_is_active = true
	_stuck_timer = 0.0


## Replace the behavior tree scene at runtime (e.g., quest changes NPC behavior).
## Blackboard persists across swap — new tree reads existing state.
func swap_tree(new_scene: PackedScene) -> void:
	if _bt_root:
		_bt_root.abort(blackboard)
		_bt_root.queue_free()
		_bt_root = null
	_bt_root = new_scene.instantiate() as BTNode
	if _bt_root:
		add_child(_bt_root)


## Collect serializable state from leaf nodes only. Keyed by tree path.
func get_bt_state() -> Dictionary:
	var state: Dictionary = {}
	if _bt_root:
		_collect_leaf_state(_bt_root, "", state)
	return state


## Restore leaf state from a previously saved dictionary.
func load_bt_state(state: Dictionary) -> void:
	if _bt_root:
		_distribute_leaf_state(_bt_root, "", state)


func _collect_leaf_state(node: BTNode, path: String, state: Dictionary) -> void:
	if node is BTLeaf:
		var leaf_state: Dictionary = node.bt_get_state()
		if not leaf_state.is_empty():
			state[path] = leaf_state
	for i: int in node.get_child_count():
		var child: Node = node.get_child(i)
		if child is BTNode:
			var bt_child: BTNode = child as BTNode
			_collect_leaf_state(bt_child, path + "/" + bt_child.name, state)


func _distribute_leaf_state(node: BTNode, path: String, state: Dictionary) -> void:
	if node is BTLeaf and state.has(path):
		var leaf_state: Dictionary = state[path] as Dictionary
		node.bt_load_state(leaf_state)
	for i: int in node.get_child_count():
		var child: Node = node.get_child(i)
		if child is BTNode:
			var bt_child: BTNode = child as BTNode
			_distribute_leaf_state(bt_child, path + "/" + bt_child.name, state)
