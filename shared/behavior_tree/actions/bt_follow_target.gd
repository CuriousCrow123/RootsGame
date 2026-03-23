class_name BTFollowTarget
extends BTLeaf
## Follows a target node (player or other). Returns RUNNING while following.
## Returns FAILURE if target is lost.

const PATH_UPDATE_INTERVAL: float = 0.3
const STOP_DISTANCE_BUFFER: float = 0.3

@export var speed_multiplier: float = 1.0
## Minimum distance to maintain from target.
@export var stop_distance: float = 1.5
## Blackboard key for the target node. Defaults to player.
@export var target_key: StringName = BTKeys.PLAYER

var _path_update_timer: float = 0.0


func bt_enter(_blackboard: Dictionary) -> void:
	_path_update_timer = randf_range(0.0, PATH_UPDATE_INTERVAL)


func _tick(delta: float, blackboard: Dictionary) -> Status:
	var npc: NPCController = blackboard.get(BTKeys.NPC) as NPCController
	if not is_instance_valid(npc):
		return Status.FAILURE

	var target: Node3D = blackboard.get(target_key) as Node3D
	if not is_instance_valid(target):
		return Status.FAILURE

	var nav: NavigationAgent3D = blackboard.get(BTKeys.NAV_AGENT) as NavigationAgent3D
	if not nav:
		return Status.FAILURE
	if NavigationServer3D.map_get_iteration_id(nav.get_navigation_map()) == 0:
		return Status.RUNNING

	var dist_sq: float = npc.global_position.distance_squared_to(target.global_position)
	var stop_sq: float = stop_distance * stop_distance

	# Within stop distance — idle in place.
	if dist_sq <= stop_sq:
		npc.velocity = Vector3.ZERO
		return Status.RUNNING

	# Throttle path recalculation.
	_path_update_timer += delta
	if _path_update_timer >= PATH_UPDATE_INTERVAL:
		_path_update_timer -= PATH_UPDATE_INTERVAL
		npc.set_nav_target(target.global_position)

	npc.move_toward_nav_target(delta, speed_multiplier)
	return Status.RUNNING
