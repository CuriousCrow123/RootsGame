extends VBoxContainer
## Settings tab: audio volumes and display options.
## Reads initial state from SettingsManager on _ready(), saves on change.

@onready var _master_slider: HSlider = %MasterSlider
@onready var _music_slider: HSlider = %MusicSlider
@onready var _sfx_slider: HSlider = %SfxSlider
@onready var _fullscreen_check: CheckButton = %FullscreenCheck
@onready var _vsync_check: CheckButton = %VsyncCheck


func _ready() -> void:
	# Pull initial state from SettingsManager (no signal emission on startup)
	_master_slider.value = SettingsManager.get_float("audio", "master_volume", 1.0)
	_music_slider.value = SettingsManager.get_float("audio", "music_volume", 0.8)
	_sfx_slider.value = SettingsManager.get_float("audio", "sfx_volume", 1.0)
	_fullscreen_check.button_pressed = SettingsManager.get_bool("display", "fullscreen", false)
	_vsync_check.button_pressed = SettingsManager.get_bool("display", "vsync", true)
	# Connect change signals
	_master_slider.value_changed.connect(_on_master_changed)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	_vsync_check.toggled.connect(_on_vsync_toggled)


func grab_initial_focus() -> void:
	_master_slider.grab_focus()


func _on_master_changed(value: float) -> void:
	SettingsManager.set_value("audio", "master_volume", value)
	_apply_audio_bus("Master", value)


func _on_music_changed(value: float) -> void:
	SettingsManager.set_value("audio", "music_volume", value)
	_apply_audio_bus("Music", value)


func _on_sfx_changed(value: float) -> void:
	SettingsManager.set_value("audio", "sfx_volume", value)
	_apply_audio_bus("SFX", value)


func _on_fullscreen_toggled(pressed: bool) -> void:
	SettingsManager.set_value("display", "fullscreen", pressed)
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_vsync_toggled(pressed: bool) -> void:
	SettingsManager.set_value("display", "vsync", pressed)
	if pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)


func _apply_audio_bus(bus_name: String, volume: float) -> void:
	var bus_idx: int = AudioServer.get_bus_index(bus_name)
	if bus_idx < 0:
		return
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(volume))
