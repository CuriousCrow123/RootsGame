extends CanvasLayer
## HUD element showing active quest name and current step description.
## Connects to QuestTracker signals via the player group.

var _quest_tracker: QuestTracker = null

@onready var _quest_name_label: Label = $PanelContainer/VBoxContainer/QuestNameLabel
@onready var _step_label: Label = $PanelContainer/VBoxContainer/StepLabel
@onready var _panel: PanelContainer = $PanelContainer


func _ready() -> void:
	_panel.visible = false
	_connect_to_player.call_deferred()


func _connect_to_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var player: PlayerController = players[0] as PlayerController
	if not player:
		return
	_quest_tracker = player.get_quest_tracker()
	if not _quest_tracker:
		return
	_quest_tracker.quest_started.connect(_on_quest_started)
	_quest_tracker.quest_step_completed.connect(_on_quest_step_completed)
	_quest_tracker.quest_completed.connect(_on_quest_completed)


func _on_quest_started(quest_id: String) -> void:
	_panel.visible = true
	_update_display(quest_id)


func _on_quest_step_completed(quest_id: String, _step_id: String) -> void:
	_update_display(quest_id)


func _on_quest_completed(quest_id: String) -> void:
	_quest_name_label.text = _quest_tracker.get_display_name(quest_id)
	_step_label.text = "Complete!"
	# Hide after a delay
	var tween: Tween = create_tween()
	tween.tween_interval(3.0)
	tween.tween_callback(_panel.hide)


func _update_display(quest_id: String) -> void:
	if not _quest_tracker:
		return
	_quest_name_label.text = _quest_tracker.get_display_name(quest_id)
	_step_label.text = _quest_tracker.get_current_step_description(quest_id)
