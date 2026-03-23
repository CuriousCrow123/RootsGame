extends VBoxContainer
## Pause tab with Resume, Save, Load, Quit buttons.
## Button callbacks call HUD.close_game_menu() directly (existing pattern).

@onready var _resume_button: Button = $ResumeButton
@onready var _save_button: Button = $SaveButton
@onready var _load_button: Button = $LoadButton
@onready var _quit_button: Button = $QuitButton


func _ready() -> void:
	_resume_button.theme_type_variation = &"AccentButton"
	_quit_button.theme_type_variation = &"DangerButton"
	_resume_button.pressed.connect(_on_resume_pressed)
	_save_button.pressed.connect(_on_save_pressed)
	_load_button.pressed.connect(_on_load_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func set_save_load_enabled(enabled: bool) -> void:
	_save_button.disabled = not enabled
	_load_button.disabled = not enabled


func grab_initial_focus() -> void:
	_resume_button.grab_focus()


func _on_resume_pressed() -> void:
	HUD.close_game_menu()


func _on_save_pressed() -> void:
	SaveManager.save_game()
	HUD.close_game_menu()


func _on_load_pressed() -> void:
	HUD.close_game_menu()
	SaveManager.load_game()


func _on_quit_pressed() -> void:
	get_tree().quit()
