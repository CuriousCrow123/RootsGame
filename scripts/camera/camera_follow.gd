extends Camera3D
## Follows a target node with lerp smoothing. Attached to room-level Camera3D.
## Keeps the camera's own rotation fixed — only position tracks the target.

@export var follow_speed: float = 5.0
@export var offset: Vector3 = Vector3(0.0, 0.0, 0.0)

var _target: Node3D = null


func _ready() -> void:
	_find_player()


func _process(delta: float) -> void:
	if not _target:
		_find_player()
		if not _target:
			return
	var target_pos: Vector3 = _target.global_position + offset
	# Only lerp the XZ position; keep camera Y fixed for orthographic stability
	global_position.x = lerpf(global_position.x, target_pos.x, follow_speed * delta)
	global_position.z = lerpf(global_position.z, target_pos.z, follow_speed * delta)


func _find_player() -> void:
	# Look for PlayerController in the scene tree
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_target = players[0] as Node3D
