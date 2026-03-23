extends CanvasLayer
## Modal confirmation dialog. CanvasLayer 120 with full-screen dimmer.
## Uses signals (confirmed/cancelled) with CONNECT_ONE_SHOT at call sites.
## Focus trapped within dialog. Cancel action dismisses.

signal confirmed
signal cancelled

const THEME_RES: Theme = preload("res://resources/themes/main_theme.tres")

@onready var _panel: PanelContainer = %PanelContainer
@onready var _title_label: Label = %TitleLabel
@onready var _message_label: Label = %MessageLabel
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel.theme = THEME_RES
	_title_label.theme_type_variation = &"HeaderLabel"
	_confirm_button.theme_type_variation = &"DangerButton"
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_cancel_button.pressed.connect(_on_cancel_pressed)
	# Focus neighbors loop between the two buttons
	_confirm_button.focus_neighbor_left = _confirm_button.get_path_to(_cancel_button)
	_confirm_button.focus_neighbor_right = _confirm_button.get_path_to(_cancel_button)
	_cancel_button.focus_neighbor_left = _cancel_button.get_path_to(_confirm_button)
	_cancel_button.focus_neighbor_right = _cancel_button.get_path_to(_confirm_button)


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed("ui_cancel"):
		_on_cancel_pressed()
		get_viewport().set_input_as_handled()
		return
	# Block all non-mouse input so nothing behind the dialog responds
	# (tab switching, pause, movement, etc). Mouse events must pass
	# through so the Confirm/Cancel buttons receive clicks.
	if not event is InputEventMouse:
		get_viewport().set_input_as_handled()


func show_dialog(title: String, message: String) -> void:
	_title_label.text = title
	_message_label.text = message
	visible = true
	_cancel_button.grab_focus.call_deferred()


func dismiss() -> void:
	visible = false


func _on_confirm_pressed() -> void:
	visible = false
	confirmed.emit()


func _on_cancel_pressed() -> void:
	visible = false
	cancelled.emit()
