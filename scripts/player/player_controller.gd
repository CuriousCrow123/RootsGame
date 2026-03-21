class_name PlayerController
extends CharacterBody3D
## Player character with movement, interaction detection, and state management.

signal nearest_interactable_changed(interactable: Node3D)

# Fixed camera angle — hardcoded for consistent isometric feel.
# Avoids reading camera basis each frame and floating-point drift.
const ISO_ANGLE: float = -0.7854  # deg_to_rad(-45.0)

@export var move_speed: float = 5.0

var _nearest_interactable: Node3D = null
var _facing_direction: String = "down"

@onready var _interaction_area: Area3D = $InteractionArea
@onready var _inventory: Inventory = $Inventory
@onready var _sprite: AnimatedSprite3D = $AnimatedSprite3D as AnimatedSprite3D


func _ready() -> void:
	add_to_group("player")
	SaveManager.register(self)
	if _interaction_area:
		_interaction_area.body_entered.connect(_on_interactable_entered)
		_interaction_area.body_exited.connect(_on_interactable_exited)
	# Reparent to root so player persists across scene changes
	SceneManager.register_player(self)


# -- Public accessors (interactables call these, not get_node) --


func get_inventory() -> Inventory:
	return _inventory


func get_quest_tracker() -> QuestTracker:
	return $QuestTracker as QuestTracker


func get_movement_input() -> Vector3:
	var input_dir: Vector2 = Input.get_vector(
		"move_left", "move_right", "move_forward", "move_back"
	)
	# Rotate input by fixed camera angle for camera-relative movement
	var rotated: Vector2 = input_dir.rotated(ISO_ANGLE)
	return Vector3(rotated.x, 0.0, rotated.y).normalized()


func get_facing_direction() -> String:
	return _facing_direction


func get_nearest_interactable() -> Node3D:
	return _nearest_interactable


func interact_with_nearest() -> void:
	if _nearest_interactable and _nearest_interactable.has_method("interact"):
		_nearest_interactable.call("interact", self)


func update_facing(input_direction: Vector2) -> void:
	if input_direction.is_zero_approx():
		return
	if absf(input_direction.x) >= absf(input_direction.y):
		_facing_direction = "right" if input_direction.x > 0.0 else "left"
	else:
		_facing_direction = "down" if input_direction.y > 0.0 else "up"


func play_animation(action: String) -> void:
	if not _sprite:
		return
	var dir: String = _facing_direction
	if dir == "left" or dir == "right":
		_sprite.flip_h = (dir == "right")
		dir = "side"
	else:
		_sprite.flip_h = false
	_sprite.play(action + "_" + dir)


func get_save_key() -> String:
	return "player"


func get_save_data() -> Dictionary:
	return {
		"position":
		{
			"x": global_position.x,
			"y": global_position.y,
			"z": global_position.z,
		},
		"facing_direction": _facing_direction,
	}


func load_save_data(data: Dictionary) -> void:
	# Deserialization from JSON — Dictionary.get() returns Variant by design.
	@warning_ignore("unsafe_call_argument")
	var pos: Dictionary = data.get("position", {})
	@warning_ignore("unsafe_call_argument")
	global_position = Vector3(pos.get("x", 0.0), pos.get("y", 0.0), pos.get("z", 0.0))
	@warning_ignore("unsafe_call_argument")
	_facing_direction = data.get("facing_direction", "down")
	play_animation("idle")


# -- Private --


func _on_interactable_entered(body: Node3D) -> void:
	if not body.has_method("interact"):
		return
	_update_nearest_interactable()


func _on_interactable_exited(body: Node3D) -> void:
	if not body.has_method("interact"):
		return
	_update_nearest_interactable()


func _update_nearest_interactable() -> void:
	var bodies: Array[Node3D] = _interaction_area.get_overlapping_bodies()
	var closest: Node3D = null
	var closest_dist: float = INF
	for body: Node3D in bodies:
		if not body.has_method("interact"):
			continue
		var dist: float = global_position.distance_squared_to(body.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = body
	var changed: bool = closest != _nearest_interactable
	_nearest_interactable = closest
	if changed:
		nearest_interactable_changed.emit(_nearest_interactable)
