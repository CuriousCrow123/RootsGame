class_name BTWanderRadius
extends BTLeaf
## Picks a random point within wander_radius of home position, walks to it, returns SUCCESS.

@export var wander_radius: float = 3.0
@export var speed_multiplier: float = 0.7

var _has_target: bool = false


func bt_enter(_blackboard: Dictionary) -> void:
	_has_target = false


func _tick(delta: float, blackboard: Dictionary) -> Status:
	var npc: NPCController = blackboard.get(BTKeys.NPC) as NPCController
	if not is_instance_valid(npc):
		return Status.FAILURE

	var nav: NavigationAgent3D = blackboard.get(BTKeys.NAV_AGENT) as NavigationAgent3D
	if not nav:
		return Status.FAILURE
	if NavigationServer3D.map_get_iteration_id(nav.get_navigation_map()) == 0:
		return Status.RUNNING

	if not _has_target:
		var home: Vector3 = blackboard.get(BTKeys.HOME_POSITION, Vector3.ZERO) as Vector3
		var angle: float = randf() * TAU
		var dist: float = randf_range(0.5, wander_radius)
		var offset: Vector3 = Vector3(cos(angle), 0.0, sin(angle)) * dist
		var raw_target: Vector3 = home + offset
		# Snap to nearest walkable point.
		var map_rid: RID = npc.get_world_3d().get_navigation_map()
		var snapped: Vector3 = NavigationServer3D.map_get_closest_point(map_rid, raw_target)
		npc.set_nav_target(snapped)
		_has_target = true

	npc.move_toward_nav_target(delta, speed_multiplier)

	if npc.is_nav_finished():
		return Status.SUCCESS

	return Status.RUNNING
