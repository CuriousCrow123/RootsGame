class_name BTFaceTarget
extends BTLeaf
## Faces the NPC toward a target (player or blackboard position). Returns SUCCESS immediately.

enum TargetMode { PLAYER, BLACKBOARD_KEY }

@export var target_mode: TargetMode = TargetMode.PLAYER
## Blackboard key containing a Vector3 position (only used if target_mode is BLACKBOARD_KEY).
@export var position_key: StringName = &"nav_target"


func _tick(_delta: float, blackboard: Dictionary) -> Status:
	var npc: Node3D = blackboard.get(BTKeys.NPC) as Node3D
	if not is_instance_valid(npc):
		return Status.FAILURE

	var target_pos: Vector3 = Vector3.ZERO
	match target_mode:
		TargetMode.PLAYER:
			var player: Node3D = blackboard.get(BTKeys.PLAYER) as Node3D
			if not is_instance_valid(player):
				return Status.FAILURE
			target_pos = player.global_position
		TargetMode.BLACKBOARD_KEY:
			var pos: Variant = blackboard.get(position_key)
			if pos == null or not (pos is Vector3):
				return Status.FAILURE
			target_pos = pos as Vector3

	var direction: Vector3 = npc.global_position.direction_to(target_pos)
	var npc_ctrl: NPCController = npc as NPCController
	if npc_ctrl and npc_ctrl._animation_controller:
		var facing: String = npc_ctrl._cardinal_from_direction(direction)
		npc_ctrl._animation_controller.set_facing(facing)
	return Status.SUCCESS
