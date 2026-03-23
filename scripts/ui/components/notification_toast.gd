extends PanelContainer
## Individual notification toast. Content set by NotificationManager.

@onready var _icon_label: Label = %IconLabel
@onready var _message_label: Label = %MessageLabel


func set_content(text: String, type: StringName) -> void:
	if is_node_ready():
		_apply_content(text, type)
	else:
		ready.connect(_apply_content.bind(text, type), CONNECT_ONE_SHOT)


func _apply_content(text: String, type: StringName) -> void:
	_message_label.text = text
	match type:
		&"item":
			_icon_label.text = "+"
		&"quest":
			_icon_label.text = "!"
		&"save":
			_icon_label.text = "*"
		_:
			_icon_label.text = ">"
