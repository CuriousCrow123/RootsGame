extends CanvasLayer
## Brief notification when an item is acquired. Connects to player's Inventory signal.

var _tween: Tween = null

@onready var _label: Label = $PanelContainer/Label
@onready var _panel: PanelContainer = $PanelContainer


func _ready() -> void:
	_panel.modulate.a = 0.0
	_connect_to_player.call_deferred()


func show_toast(item_id: String, quantity: int) -> void:
	var text: String = "Acquired: %s" % item_id
	if quantity > 1:
		text += " x%d" % quantity
	_label.text = text
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(_panel, "modulate:a", 1.0, 0.2)
	_tween.tween_interval(2.0)
	_tween.tween_property(_panel, "modulate:a", 0.0, 0.3)


func _connect_to_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var player: PlayerController = players[0] as PlayerController
		if player:
			var inventory: Inventory = player.get_inventory()
			if inventory:
				inventory.item_added.connect(show_toast)
