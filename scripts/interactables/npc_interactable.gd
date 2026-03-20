extends StaticBody3D
## NPC that triggers dialogue on interaction. Stateless — not in "saveable" group.

@export var dialogue_resource: DialogueResource
@export var dialogue_title: String = "start"
@export var npc_id: String = ""


func interact(player: PlayerController) -> void:
	if not dialogue_resource:
		push_warning("NPC %s has no dialogue_resource assigned" % npc_id)
		return
	var quest_tracker: QuestTracker = player.get_quest_tracker()
	var inventory: Inventory = player.get_inventory()
	GameState.set_mode(GameState.GameMode.DIALOGUE)
	DialogueManager.show_dialogue_balloon(
		dialogue_resource, dialogue_title, [quest_tracker, inventory]
	)
	await DialogueManager.dialogue_ended
	# Guard: NPC may have been freed during dialogue (scene transition, load game)
	if not is_instance_valid(self):
		return
	GameState.set_mode(GameState.GameMode.OVERWORLD)
