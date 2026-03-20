extends CanvasLayer
## Pause menu with Resume, Save, Load, Quit buttons.
## Opened/closed by HUD via toggle_menu(). Blocks game input while open.

@onready var _resume_button: Button = $PanelContainer/VBoxContainer/ResumeButton
@onready var _save_button: Button = $PanelContainer/VBoxContainer/SaveButton
@onready var _load_button: Button = $PanelContainer/VBoxContainer/LoadButton
@onready var _quit_button: Button = $PanelContainer/VBoxContainer/QuitButton


func _ready() -> void:
	visible = false
	layer = 90  # Below SceneManager fade (100), above game UI
	_resume_button.pressed.connect(_on_resume_pressed)
	_save_button.pressed.connect(_on_save_pressed)
	_load_button.pressed.connect(_on_load_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)


func open_menu() -> void:
	visible = true
	_resume_button.grab_focus()


func close_menu() -> void:
	visible = false


func _on_resume_pressed() -> void:
	HUD.close_pause_menu()


func _on_save_pressed() -> void:
	SaveManager.save_game()
	HUD.close_pause_menu()


func _on_load_pressed() -> void:
	HUD.close_pause_menu()
	# Load after closing so GameState returns to OVERWORLD before restore
	SaveManager.load_game()


func _on_quit_pressed() -> void:
	get_tree().quit()
