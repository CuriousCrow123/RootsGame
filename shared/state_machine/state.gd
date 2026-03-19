class_name State
extends Node
## Base class for state machine states. Override virtual methods in subclasses.

signal state_finished(next_state_path: String, data: Dictionary)


func enter(_previous_state_path: String, _data: Dictionary = {}) -> void:
	pass


func exit() -> void:
	pass


func handle_input(_event: InputEvent) -> void:
	pass


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	pass
