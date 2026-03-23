class_name NPCController
extends CharacterBody3D
## Moving NPC with behavior-tree-driven AI, NavigationAgent3D pathfinding,
## two-zone player awareness, and dialogue interaction support.

const PROMPT_LABEL_OFFSET: Vector3 = Vector3(0.0, 2.0, 0.0)
const PROMPT_PIXEL_SIZE: float = 0.005
const PROMPT_FONT_SIZE: int = 24
const ACTION_VERB: String = "Talk to"
const PATH_UPDATE_INTERVAL: float = 0.3

@export var npc_id: String = ""
@export var base_speed: float = 2.0
@export var behavior_tree_scene: PackedScene
@export var dialogue_resource: DialogueResource
@export var dialogue_title: String = "start"
@export var quest_resource: QuestData = null
@export var sprite_frames: SpriteFrames
@export var default_facing: String = "down"
@export var display_name: String = ""
@export var sprite_tint: Color = Color.WHITE
## If true, side sprite faces right (flip for left). If false, faces left.
@export var side_faces_right: bool = false

var _prompt_label: Label3D = null
var _path_update_timer: float = 0.0
var _is_dialogue_active: bool = false

@onready var _sprite: AnimatedSprite3D = %AnimatedSprite3D
@onready var _animation_controller: AnimationController = %AnimationController
@onready var _nav_agent: NavigationAgent3D = %NavigationAgent3D
@onready var _awareness_area: Area3D = %AwarenessArea
@onready var _interaction_area: Area3D = %InteractionArea
@onready var _bt_runner: BehaviorTreeRunner = %BehaviorTreeRunner


func _ready() -> void:
	if _sprite and sprite_frames:
		_sprite.sprite_frames = sprite_frames
		_sprite.modulate = sprite_tint
	if _animation_controller:
		_animation_controller.side_faces_right = side_faces_right
		_animation_controller.set_facing(default_facing)
	if _nav_agent:
		_nav_agent.velocity_computed.connect(_on_velocity_computed)
	if _awareness_area:
		_awareness_area.body_entered.connect(_on_awareness_body_entered)
		_awareness_area.body_exited.connect(_on_awareness_body_exited)
	if _interaction_area:
		_interaction_area.body_entered.connect(_on_interaction_body_entered)
		_interaction_area.body_exited.connect(_on_interaction_body_exited)
	# Stagger path update timer so NPCs don't all recalculate on the same frame.
	_path_update_timer = randf_range(0.0, PATH_UPDATE_INTERVAL)
	# Populate blackboard.
	if _bt_runner:
		_bt_runner.blackboard[BTKeys.NPC] = self
		_bt_runner.blackboard[BTKeys.NAV_AGENT] = _nav_agent
		_bt_runner.blackboard[BTKeys.BASE_SPEED] = base_speed
		_bt_runner.blackboard[BTKeys.HOME_POSITION] = global_position
		_bt_runner.blackboard[BTKeys.PLAYER] = null
	_create_prompt_label()


func _physics_process(_delta: float) -> void:
	if _is_dialogue_active:
		return
	# Call down to animation controller with current velocity.
	if _animation_controller:
		_animation_controller.update_animation(velocity)


# -- Navigation helpers (called by BT action nodes via blackboard) --


func set_nav_target(target_pos: Vector3) -> void:
	if _nav_agent:
		_nav_agent.set_target_position(target_pos)


func move_toward_nav_target(_delta: float, speed_multiplier: float = 1.0) -> void:
	if not _nav_agent:
		return
	# Guard: nav map not yet synced.
	if NavigationServer3D.map_get_iteration_id(_nav_agent.get_navigation_map()) == 0:
		return
	if _nav_agent.is_navigation_finished():
		velocity = Vector3.ZERO
		return
	var next_pos: Vector3 = _nav_agent.get_next_path_position()
	var direction: Vector3 = global_position.direction_to(next_pos)
	direction.y = 0.0
	var desired_velocity: Vector3 = direction * base_speed * speed_multiplier
	if _nav_agent.avoidance_enabled:
		_nav_agent.set_velocity(desired_velocity)
	else:
		_on_velocity_computed(desired_velocity)


func is_nav_finished() -> bool:
	if not _nav_agent:
		return true
	return _nav_agent.is_navigation_finished()


# -- Interaction protocol (duck-typed, matches npc_interactable.gd) --


func interact(player: PlayerController) -> void:
	if not dialogue_resource:
		push_warning("NPC %s has no dialogue_resource assigned" % npc_id)
		return
	_is_dialogue_active = true
	if _bt_runner:
		_bt_runner.interrupt()
	velocity = Vector3.ZERO
	# Face the player.
	if _animation_controller:
		var dir_to_player: Vector3 = global_position.direction_to(player.global_position)
		var facing: String = _cardinal_from_direction(dir_to_player)
		_animation_controller.lock_facing(facing)
	GameState.set_mode(GameState.GameMode.DIALOGUE)
	var quest_tracker: QuestTracker = player.get_quest_tracker()
	var inventory: Inventory = player.get_inventory()
	(
		DialogueManager
		. call(
			"show_dialogue_balloon",
			dialogue_resource,
			dialogue_title,
			[quest_tracker, inventory, self],
		)
	)
	await Signal(DialogueManager, "dialogue_ended")
	if not is_instance_valid(self):
		return
	# Post-dialogue facing hold.
	if _animation_controller:
		_animation_controller.lock_facing(_animation_controller.get_current_facing(), 0.4)
	GameState.set_mode(GameState.GameMode.OVERWORLD)
	if not is_instance_valid(self):
		return
	_is_dialogue_active = false
	if _bt_runner:
		_bt_runner.resume()


func get_prompt_text() -> String:
	var npc_name: String = display_name if display_name != "" else npc_id
	return "[E] %s %s" % [ACTION_VERB, npc_name]


func show_prompt() -> void:
	if _prompt_label:
		_prompt_label.visible = true


func hide_prompt() -> void:
	if _prompt_label:
		_prompt_label.visible = false


# -- Awareness area signals --


func _on_awareness_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and _bt_runner:
		_bt_runner.blackboard[BTKeys.PLAYER] = body


func _on_awareness_body_exited(body: Node3D) -> void:
	if body.is_in_group("player") and _bt_runner:
		_bt_runner.blackboard[BTKeys.PLAYER] = null


func _on_interaction_body_entered(_body: Node3D) -> void:
	pass


func _on_interaction_body_exited(_body: Node3D) -> void:
	pass


# -- Navigation avoidance callback --


func _on_velocity_computed(safe_velocity: Vector3) -> void:
	velocity = safe_velocity
	move_and_slide()


# -- Internal helpers --


func _cardinal_from_direction(dir: Vector3) -> String:
	if absf(dir.x) > absf(dir.z):
		return "right" if dir.x > 0.0 else "left"
	return "down" if dir.z > 0.0 else "up"


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
