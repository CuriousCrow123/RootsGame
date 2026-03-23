extends VBoxContainer
## Pause tab with Resume, Save, Load, Quit buttons.
## Quit and Load trigger confirmation dialogs via HUD.

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
	HUD.show_notification("Game saved", &"save")
	HUD.close_game_menu()


func _on_load_pressed() -> void:
	var dialog: CanvasLayer = HUD.show_confirmation("Load Game", "Unsaved progress will be lost.")
	dialog.connect("confirmed", _do_load, CONNECT_ONE_SHOT)


func _on_quit_pressed() -> void:
	var dialog: CanvasLayer = HUD.show_confirmation("Quit Game", "Unsaved progress will be lost.")
	dialog.connect("confirmed", _do_quit, CONNECT_ONE_SHOT)


func _do_load() -> void:
	HUD.close_game_menu()
	SaveManager.load_game()


func _do_quit() -> void:
	get_tree().quit()
