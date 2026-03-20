extends CanvasLayer
## Shows/hides "Press E" prompt when player is near an interactable.
## Finds the player via "player" group and connects to nearest_interactable_changed.

@onready var _label: Label = $PanelContainer/Label


func _ready() -> void:
	visible = false


func connect_to_player(player: PlayerController) -> void:
	player.nearest_interactable_changed.connect(_on_nearest_interactable_changed)


func show_prompt(text: String = "Press E") -> void:
	_label.text = text
	visible = true


func hide_prompt() -> void:
	visible = false


func _on_nearest_interactable_changed(interactable: Node3D) -> void:
	if interactable:
		show_prompt()
	else:
		hide_prompt()
