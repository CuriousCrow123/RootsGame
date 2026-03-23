extends CanvasLayer
## Manages stacked notifications with slide-in/out animations.
## Instantiated by HUD autoload. Survives scene transitions.
## Queues notifications during non-OVERWORLD game modes.
## Uses manual positioning (not VBoxContainer) to avoid tween conflicts.

const THEME_RES: Theme = preload("res://resources/themes/main_theme.tres")
const TOAST_SCENE: PackedScene = preload("res://scenes/ui/components/notification_toast.tscn")

const MAX_VISIBLE: int = 3
const TOAST_GAP: float = 8.0
const SLIDE_IN_DURATION: float = 0.3
const DISPLAY_DURATION: float = 3.0
const SLIDE_OUT_DURATION: float = 0.3
const SLIDE_OFFSET: float = 400.0
const FLUSH_STAGGER: float = 0.4

var _active_toasts: Array[Control] = []
var _queue: Array[Dictionary] = []
var _anchor: Control = null
var _offset_node: Control = null
var _inventory: Inventory = null
var _quest_tracker: QuestTracker = null


func _ready() -> void:
	layer = 100
	_anchor = Control.new()
	_anchor.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_anchor.offset_left = -340.0
	_anchor.offset_top = 16.0
	_anchor.theme = THEME_RES
	add_child(_anchor)
	GameState.game_state_changed.connect(_on_game_state_changed)


## Set a Control to position notifications below. Anchor tracks its
## bottom edge so notifications never overlap it.
func set_offset_node(node: Control) -> void:
	_offset_node = node
	_update_anchor_top()
	if not node.visibility_changed.is_connected(_update_anchor_top):
		node.visibility_changed.connect(_update_anchor_top)
		node.resized.connect(_update_anchor_top)


func _update_anchor_top() -> void:
	if _offset_node and _offset_node.visible:
		_anchor.offset_top = _offset_node.global_position.y + _offset_node.size.y + TOAST_GAP * 3.0
	else:
		_anchor.offset_top = 16.0


func connect_to_player(player: PlayerController) -> void:
	_disconnect_signals()
	_inventory = player.get_inventory()
	_quest_tracker = player.get_quest_tracker()
	if _inventory:
		_inventory.item_added.connect(_on_item_added)
	if _quest_tracker:
		_quest_tracker.quest_started.connect(_on_quest_started)
		_quest_tracker.quest_completed.connect(_on_quest_completed)


func show_notification(text: String, type: StringName = &"info") -> void:
	var data: Dictionary = {"text": text, "type": type}
	if GameState.current_mode != GameState.GameMode.OVERWORLD:
		_queue.append(data)
		return
	if _active_toasts.size() >= MAX_VISIBLE:
		_queue.append(data)
		return
	_spawn_toast(data)


func clear_all() -> void:
	for toast: Control in _active_toasts:
		if is_instance_valid(toast):
			toast.queue_free()
	_active_toasts.clear()
	_queue.clear()


func _spawn_toast(data: Dictionary) -> void:
	var toast: PanelContainer = TOAST_SCENE.instantiate()
	_anchor.add_child(toast)
	toast.call("set_content", str(data["text"]), data["type"])
	var target_y: float = _get_stack_bottom()
	toast.position = Vector2(SLIDE_OFFSET, target_y)
	_active_toasts.append(toast)
	var tween: Tween = create_tween()
	(
		tween
		. tween_property(toast, "position:x", 0.0, SLIDE_IN_DURATION)
		. set_trans(Tween.TRANS_CUBIC)
		. set_ease(Tween.EASE_OUT)
	)
	tween.tween_interval(DISPLAY_DURATION)
	tween.tween_callback(_dismiss_toast.bind(toast))


func _dismiss_toast(toast: Control) -> void:
	if not is_instance_valid(toast):
		return
	if toast not in _active_toasts:
		return
	var tween: Tween = create_tween().set_parallel(true)
	(
		tween
		. tween_property(toast, "position:x", SLIDE_OFFSET, SLIDE_OUT_DURATION)
		. set_trans(Tween.TRANS_CUBIC)
		. set_ease(Tween.EASE_IN)
	)
	tween.tween_property(toast, "modulate:a", 0.0, SLIDE_OUT_DURATION)
	tween.chain().tween_callback(_remove_toast.bind(toast))


func _remove_toast(toast: Control) -> void:
	if not is_instance_valid(toast):
		return
	_active_toasts.erase(toast)
	toast.queue_free()
	_reposition_active()
	_flush_one()


func _reposition_active() -> void:
	var y_offset: float = 0.0
	for i: int in range(_active_toasts.size()):
		var toast: Control = _active_toasts[i]
		if not is_instance_valid(toast):
			continue
		var tween: Tween = create_tween()
		(
			tween
			. tween_property(toast, "position:y", y_offset, 0.2)
			. set_trans(Tween.TRANS_CUBIC)
			. set_ease(Tween.EASE_OUT)
		)
		y_offset += toast.size.y + TOAST_GAP


func _get_stack_bottom() -> float:
	var y_offset: float = 0.0
	for toast: Control in _active_toasts:
		if is_instance_valid(toast):
			y_offset += toast.size.y + TOAST_GAP
	return y_offset


func _flush_one() -> void:
	if _queue.is_empty():
		return
	if _active_toasts.size() >= MAX_VISIBLE:
		return
	if GameState.current_mode != GameState.GameMode.OVERWORLD:
		return
	var data: Dictionary = _queue.pop_front()
	_spawn_toast(data)


func _flush_staggered() -> void:
	if _queue.is_empty() or _active_toasts.size() >= MAX_VISIBLE:
		return
	if GameState.current_mode != GameState.GameMode.OVERWORLD:
		return
	var data: Dictionary = _queue.pop_front()
	_spawn_toast(data)
	if not _queue.is_empty() and _active_toasts.size() < MAX_VISIBLE:
		var timer: SceneTreeTimer = get_tree().create_timer(FLUSH_STAGGER)
		timer.timeout.connect(_flush_staggered)


func _on_game_state_changed(_new_state: GameState.GameMode) -> void:
	_flush_staggered()


func _on_item_added(item_id: String, _quantity: int) -> void:
	var display: String = _inventory.get_display_name(item_id)
	show_notification("Acquired: %s" % display, &"item")


func _on_quest_started(quest_id: String) -> void:
	var display: String = _quest_tracker.get_display_name(quest_id)
	show_notification("Quest started: %s" % display, &"quest")


func _on_quest_completed(quest_id: String) -> void:
	var display: String = _quest_tracker.get_display_name(quest_id)
	show_notification("Quest complete: %s" % display, &"quest")


func _disconnect_signals() -> void:
	if _inventory and _inventory.item_added.is_connected(_on_item_added):
		_inventory.item_added.disconnect(_on_item_added)
	if _quest_tracker:
		if _quest_tracker.quest_started.is_connected(_on_quest_started):
			_quest_tracker.quest_started.disconnect(_on_quest_started)
		if _quest_tracker.quest_completed.is_connected(_on_quest_completed):
			_quest_tracker.quest_completed.disconnect(_on_quest_completed)


func _exit_tree() -> void:
	_disconnect_signals()
