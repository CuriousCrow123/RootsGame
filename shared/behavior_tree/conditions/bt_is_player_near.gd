class_name BTIsPlayerNear
extends BTLeaf
## Succeeds if the player is within radius of the NPC. Fails otherwise.

@export var radius: float = 5.0

var _radius_sq: float = 0.0


func bt_enter(_blackboard: Dictionary) -> void:
	_radius_sq = radius * radius


func _tick(_delta: float, blackboard: Dictionary) -> Status:
	var player: Node3D = blackboard.get(BTKeys.PLAYER) as Node3D
	if not is_instance_valid(player):
		return Status.FAILURE
	var npc: Node3D = blackboard.get(BTKeys.NPC) as Node3D
	if not is_instance_valid(npc):
		return Status.FAILURE
	if npc.global_position.distance_squared_to(player.global_position) <= _radius_sq:
		return Status.SUCCESS
	return Status.FAILURE
