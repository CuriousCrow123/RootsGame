class_name StateMachine
extends Node
## Generic state machine. Add State nodes as children. Set initial_state in inspector.

@export var initial_state: State

var current_state: State


func _ready() -> void:
	for child: Node in get_children():
		if child is State:
			var state: State = child as State
			state.state_finished.connect(_on_state_finished)
	if initial_state:
		current_state = initial_state
		current_state.enter("")


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func _on_state_finished(next_state_path: String, data: Dictionary) -> void:
	transition_to(next_state_path, data)


func transition_to(target_state_path: String, data: Dictionary = {}) -> void:
	if not has_node(target_state_path):
		push_warning("State not found: %s" % target_state_path)
		return
	var previous_state_path: String = ""
	if current_state:
		previous_state_path = current_state.name
		current_state.exit()
	current_state = get_node(target_state_path) as State
	current_state.enter(previous_state_path, data)


func set_active(active: bool) -> void:
	set_process(active)
	set_physics_process(active)
	set_process_unhandled_input(active)
