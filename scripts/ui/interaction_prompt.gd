extends CanvasLayer
## Shows/hides "Press E" prompt when player is near an interactable.
## Finds the player via "player" group and connects to nearest_interactable_changed.

@onready var _label: Label = $PanelContainer/Label


func _ready() -> void:
	visible = false
	# Deferred so player is ready first
	_connect_to_player.call_deferred()


func show_prompt(text: String = "Press E") -> void:
	_label.text = text
	visible = true


func hide_prompt() -> void:
	visible = false


func _connect_to_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player: PlayerController = players[0] as PlayerController
		if player:
			player.nearest_interactable_changed.connect(_on_nearest_interactable_changed)


func _on_nearest_interactable_changed(interactable: Node3D) -> void:
	if interactable:
		show_prompt()
	else:
		hide_prompt()
