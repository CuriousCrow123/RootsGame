class_name AnimationController
extends Node
## Picks cardinal animation + facing from velocity. Supports facing lock for dialogue.
## Called by parent NPC controller via update_animation() — does NOT poll owner.

const VELOCITY_THRESHOLD_SQ: float = 0.01

@export var sprite_tint: Color = Color.WHITE
@export var side_faces_right: bool = false

var _facing: String = "down"
var _facing_locked: bool = false
var _locked_facing: String = ""
var _lock_timer: float = 0.0
var _sprite: AnimatedSprite3D = null


func _ready() -> void:
	# Find sibling sprite via owner.
	var owner_node: Node = owner
	if owner_node:
		_sprite = owner_node.get_node_or_null("%AnimatedSprite3D") as AnimatedSprite3D


func _process(delta: float) -> void:
	# Only used for lock timer countdown.
	if _facing_locked and _lock_timer > 0.0:
		_lock_timer -= delta
		if _lock_timer <= 0.0:
			_facing_locked = false
			_lock_timer = 0.0


## Called by npc_controller in _physics_process after move_and_slide().
func update_animation(current_velocity: Vector3) -> void:
	if _facing_locked:
		_apply_facing(_locked_facing, false)
		return
	var xz_speed_sq: float = (
		current_velocity.x * current_velocity.x + current_velocity.z * current_velocity.z
	)
	if xz_speed_sq < VELOCITY_THRESHOLD_SQ:
		_apply_facing(_facing, false)
		return
	# Project velocity onto screen-space for correct isometric cardinal direction.
	_facing = _world_dir_to_cardinal(current_velocity)
	_apply_facing(_facing, true)


## Set facing without velocity (used for initial setup).
func set_facing(direction: String) -> void:
	_facing = direction
	_apply_facing(_facing, false)


## Lock facing to a direction. Duration 0.0 = lock until unlock_facing().
func lock_facing(direction: String, duration: float = 0.0) -> void:
	_facing_locked = true
	_locked_facing = direction
	_lock_timer = duration
	_apply_facing(direction, false)


func unlock_facing() -> void:
	_facing_locked = false
	_lock_timer = 0.0


func get_current_facing() -> String:
	return _locked_facing if _facing_locked else _facing


func _world_dir_to_cardinal(world_dir: Vector3) -> String:
	var owner_3d: Node3D = owner as Node3D
	if not owner_3d:
		return "down"
	var cam: Camera3D = owner_3d.get_viewport().get_camera_3d()
	if cam:
		var pos: Vector3 = owner_3d.global_position
		var origin: Vector2 = cam.unproject_position(pos)
		var target: Vector2 = cam.unproject_position(pos + world_dir)
		var screen_dir: Vector2 = (target - origin).normalized()
		if absf(screen_dir.x) >= absf(screen_dir.y):
			return "right" if screen_dir.x > 0.0 else "left"
		return "down" if screen_dir.y > 0.0 else "up"
	if absf(world_dir.x) > absf(world_dir.z):
		return "right" if world_dir.x > 0.0 else "left"
	return "down" if world_dir.z > 0.0 else "up"


func _apply_facing(direction: String, is_moving: bool) -> void:
	if not _sprite:
		return
	var anim_dir: String = direction
	var flip: bool = false
	if direction == "left" or direction == "right":
		var flip_dir: String = "right" if side_faces_right else "left"
		flip = (direction != flip_dir)
		anim_dir = "side"
	_sprite.flip_h = flip
	var prefix: String = "walk_" if is_moving else "idle_"
	var anim_name: String = prefix + anim_dir
	if _sprite.sprite_frames and _sprite.sprite_frames.has_animation(anim_name):
		if _sprite.animation != anim_name:
			_sprite.play(anim_name)
	elif _sprite.sprite_frames and _sprite.sprite_frames.has_animation("idle_" + anim_dir):
		# Fallback to idle if walk animation doesn't exist.
		var fallback: String = "idle_" + anim_dir
		if _sprite.animation != fallback:
			_sprite.play(fallback)
