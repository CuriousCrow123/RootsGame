class_name BTIsAtPosition
extends BTLeaf
## Succeeds if the NPC is within tolerance of a target position stored in the blackboard.

## Blackboard key containing the target Vector3.
@export var target_key: StringName = &"nav_target"
@export var tolerance: float = 0.5

var _tolerance_sq: float = 0.0


func bt_enter(_blackboard: Dictionary) -> void:
	_tolerance_sq = tolerance * tolerance


func _tick(_delta: float, blackboard: Dictionary) -> Status:
	var npc: Node3D = blackboard.get(BTKeys.NPC) as Node3D
	if not is_instance_valid(npc):
		return Status.FAILURE
	var target: Variant = blackboard.get(target_key)
	if target == null or not (target is Vector3):
		return Status.FAILURE
	var target_pos: Vector3 = target as Vector3
	if npc.global_position.distance_squared_to(target_pos) <= _tolerance_sq:
		return Status.SUCCESS
	return Status.FAILURE
