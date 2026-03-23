class_name BTPatrolRoute
extends BTLeaf
## Patrols between waypoints in sequence. Returns RUNNING while patrolling.
## Returns SUCCESS after completing one full loop (or RUNNING forever if loop is true).

## Waypoint positions in local space relative to the NPC's home position.
@export var waypoints: Array[Vector3] = []
@export var speed_multiplier: float = 1.0
## If true, loops forever. If false, returns SUCCESS after one pass.
@export var is_loop: bool = true

var _current_index: int = 0
var _has_set_target: bool = false


func bt_enter(_blackboard: Dictionary) -> void:
	_has_set_target = false


func _tick(delta: float, blackboard: Dictionary) -> Status:
	if waypoints.is_empty():
		return Status.FAILURE

	var npc: NPCController = blackboard.get(BTKeys.NPC) as NPCController
	if not is_instance_valid(npc):
		return Status.FAILURE

	# Guard: nav map not synced yet.
	var nav: NavigationAgent3D = blackboard.get(BTKeys.NAV_AGENT) as NavigationAgent3D
	if not nav:
		return Status.FAILURE
	if NavigationServer3D.map_get_iteration_id(nav.get_navigation_map()) == 0:
		return Status.RUNNING

	if not _has_set_target:
		var home: Vector3 = blackboard.get(BTKeys.HOME_POSITION, Vector3.ZERO) as Vector3
		npc.set_nav_target(home + waypoints[_current_index])
		_has_set_target = true

	npc.move_toward_nav_target(delta, speed_multiplier)

	if npc.is_nav_finished():
		_current_index += 1
		_has_set_target = false
		if _current_index >= waypoints.size():
			if is_loop:
				_current_index = 0
			else:
				_current_index = 0
				return Status.SUCCESS

	return Status.RUNNING


func bt_get_state() -> Dictionary:
	return {"current_index": _current_index}


func bt_load_state(data: Dictionary) -> void:
	_current_index = data.get("current_index", 0) as int
