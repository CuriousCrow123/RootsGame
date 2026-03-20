extends Camera3D
## Follows a target node with lerp smoothing. Attached to room-level Camera3D.
## Keeps the camera's own rotation fixed — only position tracks the target.

@export var follow_speed: float = 5.0
@export var offset: Vector3 = Vector3(0.0, 0.0, 0.0)
@export var follow_distance: float = 20.0

var _target: Node3D = null


func _ready() -> void:
	_find_player()


func _process(delta: float) -> void:
	if not _target:
		_find_player()
		if not _target:
			return
	var target_pos: Vector3 = _target.global_position + offset
	# Position along the camera's backward axis so the target stays centered in ortho view
	var desired: Vector3 = target_pos + global_transform.basis.z.normalized() * follow_distance
	global_position = global_position.lerp(desired, follow_speed * delta)


func _find_player() -> void:
	# Look for PlayerController in the scene tree
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_target = players[0] as Node3D
