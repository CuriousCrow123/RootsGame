extends StaticBody3D
## Item container that gives its contents on first interaction.

signal chest_opened(item: ItemData)

const OPEN_DURATION: float = 0.3
const LID_OPEN_ANGLE: float = -110.0
const PROMPT_LABEL_OFFSET: Vector3 = Vector3(0.0, 1.5, 0.0)
const ACTION_VERB: String = "Open"

@export var item: ItemData = null
@export var item_quantity: int = 1
@export var chest_id: String = ""
@export var display_name: String = "Chest"

var _is_opened: bool = false
var _closed_rotation: Vector3 = Vector3.ZERO
var _prompt_label: Label3D = null

@onready var _anim_player: AnimationPlayer = $AnimationPlayer as AnimationPlayer
@onready var _chest_top: MeshInstance3D = $Chest_Top as MeshInstance3D


func _ready() -> void:
	WorldState.register(self)
	if _chest_top:
		_closed_rotation = _chest_top.rotation_degrees
	_build_open_animation()
	_create_prompt_label()


func interact(player: PlayerController) -> void:
	if _is_opened:
		return
	if not item:
		push_warning("Chest %s has no item assigned" % chest_id)
		return
	var inventory: Inventory = player.get_inventory()
	if not inventory:
		return
	inventory.add_item(item.item_id, item_quantity, item.display_name)
	_is_opened = true
	WorldState.set_state(chest_id, {"is_opened": true})
	_play_open_animation()
	chest_opened.emit(item)


func get_save_key() -> String:
	return chest_id


func get_save_data() -> Dictionary:
	return {"is_opened": _is_opened}


func load_save_data(data: Dictionary) -> void:
	@warning_ignore("unsafe_call_argument")
	_is_opened = data.get("is_opened", false)
	_restore_visual_state()


func get_prompt_text() -> String:
	return "[E] %s %s" % [ACTION_VERB, display_name]


func show_prompt() -> void:
	if _prompt_label and not _is_opened:
		_prompt_label.visible = true


func hide_prompt() -> void:
	if _prompt_label:
		_prompt_label.visible = false


func _create_prompt_label() -> void:
	_prompt_label = PromptLabelFactory.create(get_prompt_text(), PROMPT_LABEL_OFFSET)
	add_child.call_deferred(_prompt_label)


func _build_open_animation() -> void:
	if not _anim_player or not _chest_top:
		return
	var anim: Animation = Animation.new()
	anim.length = OPEN_DURATION
	var track_idx: int = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(track_idx, "Chest_Top:rotation_degrees")
	var closed_rot: Vector3 = _chest_top.rotation_degrees
	var open_rot: Vector3 = Vector3(closed_rot.x + LID_OPEN_ANGLE, closed_rot.y, closed_rot.z)
	anim.track_insert_key(track_idx, 0.0, closed_rot)
	anim.track_insert_key(track_idx, OPEN_DURATION, open_rot)
	anim.track_set_interpolation_type(track_idx, Animation.INTERPOLATION_CUBIC)
	var lib: AnimationLibrary = AnimationLibrary.new()
	lib.add_animation(&"open", anim)
	_anim_player.add_animation_library(&"", lib)


func _play_open_animation() -> void:
	if not _anim_player:
		return
	_anim_player.play(&"open")


func _restore_visual_state() -> void:
	if not _anim_player:
		return
	if _is_opened:
		_anim_player.play(&"open")
		_anim_player.seek(OPEN_DURATION, true)
	elif _chest_top:
		_chest_top.rotation_degrees = _closed_rotation
