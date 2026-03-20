extends Node
## Persistent HUD container. Instantiates UI scenes in _ready() so they
## survive scene transitions without reparenting. Connects to player via
## SceneManager.player_registered signal.

var _interaction_prompt: CanvasLayer = null
var _item_toast: CanvasLayer = null
var _quest_indicator: CanvasLayer = null


func _ready() -> void:
	_interaction_prompt = preload("res://scenes/ui/interaction_prompt.tscn").instantiate()
	add_child(_interaction_prompt)
	_item_toast = preload("res://scenes/ui/item_toast.tscn").instantiate()
	add_child(_item_toast)
	_quest_indicator = preload("res://scenes/ui/quest_indicator.tscn").instantiate()
	add_child(_quest_indicator)
	SceneManager.player_registered.connect(_on_player_registered)
	# Catch-up: if player was already registered before HUD._ready() ran
	var existing_player: PlayerController = SceneManager.get_player()
	if existing_player:
		_on_player_registered(existing_player)


func _on_player_registered(player: PlayerController) -> void:
	_interaction_prompt.call("connect_to_player", player)
	_item_toast.call("connect_to_player", player)
	_quest_indicator.call("connect_to_player", player)
