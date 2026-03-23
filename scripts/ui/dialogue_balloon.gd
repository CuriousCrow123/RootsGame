extends CanvasLayer
## Custom dialogue balloon with Theme styling and portrait support.
## Implements the Dialogue Manager balloon interface (start, apply_dialogue_line, next).
## Replaces the addon's example balloon script.

const THEME_RES: Theme = preload("res://resources/themes/main_theme.tres")

## The dialogue resource
@export var dialogue_resource: DialogueResource

## Start from a given label when using balloon as a Node in a scene.
@export var start_from_label: String = ""

## If running as a Node in a scene then auto start the dialogue.
@export var auto_start: bool = false

## If all other input is blocked as long as dialogue is shown.
@export var will_block_other_input: bool = true

## The action to use for advancing the dialogue
@export var next_action: StringName = &"ui_accept"

## The action to use to skip typing the dialogue
@export var skip_action: StringName = &"ui_cancel"

## Temporary game states
var temporary_game_states: Array = []

## See if we are waiting for the player
var is_waiting_for_input: bool = false

## See if we are running a long mutation and should hide the balloon
var will_hide_balloon: bool = false

## A dictionary to store any ephemeral variables
var locals: Dictionary = {}

## The current line
var dialogue_line: DialogueLine:
	set(value):
		if value:
			dialogue_line = value
			apply_dialogue_line()
		else:
			if owner == null:
				queue_free()
			else:
				hide()
	get:
		return dialogue_line

## A cooldown timer for delaying the balloon hide when encountering a mutation.
var mutation_cooldown: Timer = Timer.new()

var _locale: String = TranslationServer.get_locale()

@onready var _balloon: Control = %Balloon
@onready var _character_label: RichTextLabel = %CharacterLabel
@onready var _dialogue_label: DialogueLabel = %DialogueLabel
@onready var _responses_menu: DialogueResponsesMenu = %ResponsesMenu
@onready var _progress: Polygon2D = %Progress
@onready var _audio_player: AudioStreamPlayer = %AudioStreamPlayer
@onready var _portrait_rect: TextureRect = get_node_or_null("%PortraitRect")


func _ready() -> void:
	_balloon.hide()
	_balloon.theme = THEME_RES
	var dm: Object = Engine.get_singleton("DialogueManager")
	dm.connect("mutated", _on_mutated)
	if _responses_menu.next_action.is_empty():
		_responses_menu.next_action = next_action
	mutation_cooldown.timeout.connect(_on_mutation_cooldown_timeout)
	add_child(mutation_cooldown)
	if auto_start:
		if not is_instance_valid(dialogue_resource):
			assert(
				false,
				DMConstants.get_error_message(DMConstants.ERR_MISSING_RESOURCE_FOR_AUTOSTART),
			)
		start()


func _process(_delta: float) -> void:
	if is_instance_valid(dialogue_line):
		_progress.visible = (
			not _dialogue_label.is_typing
			and dialogue_line.responses.size() == 0
			and not dialogue_line.has_tag("voice")
		)


func _unhandled_input(_event: InputEvent) -> void:
	if will_block_other_input:
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if (
		what == NOTIFICATION_TRANSLATION_CHANGED
		and _locale != TranslationServer.get_locale()
		and is_instance_valid(_dialogue_label)
	):
		_locale = TranslationServer.get_locale()
		var visible_ratio: float = _dialogue_label.visible_ratio
		dialogue_line = await dialogue_resource.get_next_dialogue_line(dialogue_line.id)
		if visible_ratio < 1:
			_dialogue_label.skip_typing()


## Start some dialogue
func start(
	with_dialogue_resource: DialogueResource = null,
	label: String = "",
	extra_game_states: Array = [],
) -> void:
	temporary_game_states = [self] + extra_game_states
	is_waiting_for_input = false
	if is_instance_valid(with_dialogue_resource):
		dialogue_resource = with_dialogue_resource
	if not label.is_empty():
		start_from_label = label
	dialogue_line = await dialogue_resource.get_next_dialogue_line(
		start_from_label, temporary_game_states
	)
	show()


## Apply any changes to the balloon given a new DialogueLine.
func apply_dialogue_line() -> void:
	mutation_cooldown.stop()
	_progress.hide()
	is_waiting_for_input = false
	_balloon.focus_mode = Control.FOCUS_ALL
	_balloon.grab_focus()

	# Character name
	_character_label.visible = not dialogue_line.character.is_empty()
	_character_label.text = tr(dialogue_line.character, "dialogue")

	# Portrait
	_update_portrait(dialogue_line.character)

	# Dialogue text
	_dialogue_label.hide()
	_dialogue_label.dialogue_line = dialogue_line

	# Responses
	_responses_menu.hide()
	_responses_menu.responses = dialogue_line.responses

	# Show balloon
	_balloon.show()
	will_hide_balloon = false

	_dialogue_label.show()
	if not dialogue_line.text.is_empty():
		_dialogue_label.type_out()
		await _dialogue_label.finished_typing

	# Wait for next line
	if dialogue_line.has_tag("voice"):
		_audio_player.stream = load(dialogue_line.get_tag_value("voice"))
		_audio_player.play()
		await _audio_player.finished
		next(dialogue_line.next_id)
	elif dialogue_line.responses.size() > 0:
		_balloon.focus_mode = Control.FOCUS_NONE
		_responses_menu.show()
	elif dialogue_line.time != "":
		var time: float = (
			dialogue_line.text.length() * 0.02
			if dialogue_line.time == "auto"
			else dialogue_line.time.to_float()
		)
		await get_tree().create_timer(time).timeout
		next(dialogue_line.next_id)
	else:
		is_waiting_for_input = true
		_balloon.focus_mode = Control.FOCUS_ALL
		_balloon.grab_focus()


## Go to the next line
func next(next_id: String) -> void:
	dialogue_line = await dialogue_resource.get_next_dialogue_line(next_id, temporary_game_states)


func _update_portrait(character_name: String) -> void:
	if not is_instance_valid(_portrait_rect):
		return
	if character_name.is_empty():
		_portrait_rect.visible = false
		return
	var portrait: Texture2D = PortraitData.get_portrait(character_name)
	if portrait:
		_portrait_rect.texture = portrait
		_portrait_rect.visible = true
	else:
		_portrait_rect.visible = false


#region Signals


func _on_mutation_cooldown_timeout() -> void:
	if will_hide_balloon:
		will_hide_balloon = false
		_balloon.hide()


func _on_mutated(mutation: Dictionary) -> void:
	if not mutation.is_inline:
		is_waiting_for_input = false
		will_hide_balloon = true
		mutation_cooldown.start(0.1)


func _on_balloon_gui_input(event: InputEvent) -> void:
	if _dialogue_label.is_typing:
		var mouse_was_clicked: bool = _is_left_click(event)
		var skip_button_was_pressed: bool = event.is_action_pressed(skip_action)
		if mouse_was_clicked or skip_button_was_pressed:
			get_viewport().set_input_as_handled()
			_dialogue_label.skip_typing()
			return
	if not is_waiting_for_input:
		return
	if dialogue_line.responses.size() > 0:
		return
	get_viewport().set_input_as_handled()
	if _is_left_click(event):
		next(dialogue_line.next_id)
	elif event.is_action_pressed(next_action) and get_viewport().gui_get_focus_owner() == _balloon:
		next(dialogue_line.next_id)


func _is_left_click(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		return mb.is_pressed() and mb.button_index == MOUSE_BUTTON_LEFT
	return false


func _on_responses_menu_response_selected(response: DialogueResponse) -> void:
	next(response.next_id)

#endregion
