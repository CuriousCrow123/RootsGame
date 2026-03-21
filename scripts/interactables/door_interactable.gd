extends StaticBody3D
## Scene transition trigger. Interact to play open animation, then change scene.

const OPEN_DURATION: float = 0.4
const DOOR_OPEN_ANGLE: float = 90.0

@export_file("*.tscn") var target_scene_path: String = ""
@export var target_spawn_point: String = ""
@export var door_id: String = ""

var _is_opening: bool = false

@onready var _anim_player: AnimationPlayer = $AnimationPlayer as AnimationPlayer
@onready var _door_l: MeshInstance3D = $Doors_RoundArch_L as MeshInstance3D
@onready var _door_r: MeshInstance3D = $Doors_RoundArch_R as MeshInstance3D


func _ready() -> void:
	_build_open_animation()


func interact(_player: PlayerController) -> void:
	if _is_opening:
		return
	if target_scene_path == "":
		push_warning("Door %s has no target_scene_path assigned" % door_id)
		return
	_is_opening = true
	_anim_player.play(&"open")
	_anim_player.animation_finished.connect(_on_open_finished, CONNECT_ONE_SHOT)


func _on_open_finished(_anim_name: StringName) -> void:
	SceneManager.change_scene(target_scene_path, target_spawn_point)


func _build_open_animation() -> void:
	if not _anim_player or not _door_l or not _door_r:
		return
	var anim: Animation = Animation.new()
	anim.length = OPEN_DURATION

	# Left door swings open (negative Y rotation)
	var track_l: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_l, "Doors_RoundArch_L:rotation_degrees")
	var closed_l: Vector3 = _door_l.rotation_degrees
	var open_l: Vector3 = Vector3(closed_l.x, closed_l.y - DOOR_OPEN_ANGLE, closed_l.z)
	anim.track_insert_key(track_l, 0.0, closed_l)
	anim.track_insert_key(track_l, OPEN_DURATION, open_l)
	anim.track_set_interpolation_type(track_l, Animation.INTERPOLATION_CUBIC)

	# Right door swings open (positive Y rotation)
	var track_r: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_r, "Doors_RoundArch_R:rotation_degrees")
	var closed_r: Vector3 = _door_r.rotation_degrees
	var open_r: Vector3 = Vector3(closed_r.x, closed_r.y + DOOR_OPEN_ANGLE, closed_r.z)
	anim.track_insert_key(track_r, 0.0, closed_r)
	anim.track_insert_key(track_r, OPEN_DURATION, open_r)
	anim.track_set_interpolation_type(track_r, Animation.INTERPOLATION_CUBIC)

	var lib: AnimationLibrary = AnimationLibrary.new()
	lib.add_animation(&"open", anim)
	_anim_player.add_animation_library(&"", lib)
