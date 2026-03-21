extends StaticBody3D
## NPC that triggers dialogue on interaction. Stateless — not in "saveable" group.

@export var dialogue_resource: DialogueResource
@export var dialogue_title: String = "start"
@export var npc_id: String = ""
@export var quest_resource: QuestData = null
@export var sprite_frames: SpriteFrames
@export var default_facing: String = "down"
@export var sprite_tint: Color = Color.WHITE

@onready var _sprite: AnimatedSprite3D = $AnimatedSprite3D as AnimatedSprite3D


func _ready() -> void:
	if _sprite and sprite_frames:
		_sprite.sprite_frames = sprite_frames
		_sprite.modulate = sprite_tint
		var dir: String = default_facing
		if dir == "left" or dir == "right":
			_sprite.flip_h = (dir == "right")
			dir = "side"
		else:
			_sprite.flip_h = false
		_sprite.play("idle_" + dir)


func interact(player: PlayerController) -> void:
	if not dialogue_resource:
		push_warning("NPC %s has no dialogue_resource assigned" % npc_id)
		return
	var quest_tracker: QuestTracker = player.get_quest_tracker()
	var inventory: Inventory = player.get_inventory()
	GameState.set_mode(GameState.GameMode.DIALOGUE)
	# Pass self so dialogue can access quest_resource property.
	# DM iterates extra_game_states to resolve method calls and property lookups.
	DialogueManager.call(
		"show_dialogue_balloon", dialogue_resource, dialogue_title, [quest_tracker, inventory, self]
	)
	await Signal(DialogueManager, "dialogue_ended")
	# Guard: NPC may have been freed during dialogue (scene transition, load game)
	if not is_instance_valid(self):
		return
	GameState.set_mode(GameState.GameMode.OVERWORLD)
