extends StaticBody3D
## Scene transition trigger. Interact to play open animation, then change scene.

const OPEN_DURATION: float = 0.4
const DOOR_OPEN_ANGLE: float = 90.0
const PROMPT_LABEL_OFFSET: Vector3 = Vector3(0.0, 2.5, 0.0)
const PROMPT_PIXEL_SIZE: float = 0.005
const PROMPT_FONT_SIZE: int = 24
const ACTION_VERB: String = "Enter"

@export_file("*.tscn") var target_scene_path: String = ""
@export var target_spawn_point: String = ""
@export var door_id: String = ""
@export var display_name: String = ""

var _is_opening: bool = false
var _prompt_label: Label3D = null

@onready var _anim_player: AnimationPlayer = $AnimationPlayer as AnimationPlayer
@onready var _door_l: MeshInstance3D = $Doors_RoundArch_L as MeshInstance3D
@onready var _door_r: MeshInstance3D = $Doors_RoundArch_R as MeshInstance3D


func _ready() -> void:
	_build_open_animation()
	_create_prompt_label()


func interact(_player: PlayerController) -> void:
	if _is_opening:
		return
	if target_scene_path == "":
		push_warning("Door %s has no target_scene_path assigned" % door_id)
		return
	_is_opening = true
	_anim_player.play(&"open")
	_anim_player.animation_finished.connect(_on_open_finished, CONNECT_ONE_SHOT)


func get_prompt_text() -> String:
	var name: String = display_name if display_name != "" else door_id
	return "[E] %s %s" % [ACTION_VERB, name]


func show_prompt() -> void:
	if _prompt_label:
		_prompt_label.visible = true


func hide_prompt() -> void:
	if _prompt_label:
		_prompt_label.visible = false


func _create_prompt_label() -> void:
	_prompt_label = Label3D.new()
	_prompt_label.text = get_prompt_text()
	_prompt_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_prompt_label.set_draw_flag(Label3D.FLAG_DISABLE_DEPTH_TEST, true)
	_prompt_label.render_priority = 10
	_prompt_label.pixel_size = PROMPT_PIXEL_SIZE
	_prompt_label.font_size = PROMPT_FONT_SIZE
	_prompt_label.outline_size = 8
	_prompt_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
	_prompt_label.position = PROMPT_LABEL_OFFSET
	_prompt_label.visible = false
	add_child.call_deferred(_prompt_label)


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
