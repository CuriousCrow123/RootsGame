extends Node
## Persists user preferences (audio, display, gameplay) to user://settings.cfg.
## Independent from save data — settings survive across save slots and new games.
## Does NOT emit signals in _ready() — consumers pull initial state via getters.

signal setting_changed(key: String, value: Variant)

const SETTINGS_PATH: String = "user://settings.cfg"

var _config: ConfigFile = ConfigFile.new()


func _ready() -> void:
	var err: Error = _config.load(SETTINGS_PATH)
	if err != OK:
		push_warning(
			(
				"SettingsManager: Could not load %s (error: %s), using defaults"
				% [SETTINGS_PATH, error_string(err)]
			)
		)
		_set_defaults()
		_config.save(SETTINGS_PATH)


func get_float(section: String, key: String, default: float = 0.0) -> float:
	@warning_ignore("unsafe_call_argument")
	var value: float = _config.get_value(section, key, default)
	return value


func get_bool(section: String, key: String, default: bool = false) -> bool:
	@warning_ignore("unsafe_call_argument")
	var value: bool = _config.get_value(section, key, default)
	return value


func get_string(section: String, key: String, default: String = "") -> String:
	@warning_ignore("unsafe_call_argument")
	var value: String = _config.get_value(section, key, default)
	return value


func set_value(section: String, key: String, value: Variant) -> void:
	_config.set_value(section, key, value)
	_config.save(SETTINGS_PATH)
	setting_changed.emit(section + "/" + key, value)


func _set_defaults() -> void:
	_config.set_value("audio", "master_volume", 1.0)
	_config.set_value("audio", "music_volume", 0.8)
	_config.set_value("audio", "sfx_volume", 1.0)
	_config.set_value("display", "fullscreen", false)
	_config.set_value("display", "vsync", true)
	_config.set_value("gameplay", "always_show_hp", false)
