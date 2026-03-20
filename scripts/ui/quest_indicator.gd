extends CanvasLayer
## HUD element showing active quest name and current step description.
## Connects to QuestTracker signals via connect_to_player().

var _quest_tracker: QuestTracker = null

@onready var _quest_name_label: Label = $PanelContainer/VBoxContainer/QuestNameLabel
@onready var _step_label: Label = $PanelContainer/VBoxContainer/StepLabel
@onready var _panel: PanelContainer = $PanelContainer


func _ready() -> void:
	_panel.visible = false


func connect_to_player(player: PlayerController) -> void:
	_quest_tracker = player.get_quest_tracker()
	if not _quest_tracker:
		return
	_quest_tracker.quest_started.connect(_on_quest_started)
	_quest_tracker.quest_step_completed.connect(_on_quest_step_completed)
	_quest_tracker.quest_completed.connect(_on_quest_completed)
	_quest_tracker.quests_reset.connect(_on_quests_reset)


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


func _on_quests_reset() -> void:
	_panel.visible = false


func _update_display(quest_id: String) -> void:
	if not _quest_tracker:
		return
	_quest_name_label.text = _quest_tracker.get_display_name(quest_id)
	_step_label.text = _quest_tracker.get_current_step_description(quest_id)
