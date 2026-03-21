class_name TestHelpers
extends RefCounted
## Shared helpers for GUT tests.


static func create_player() -> PlayerController:
	## Build a PlayerController with the child nodes its @onready vars expect.
	## Use this instead of PlayerController.new() in tests.
	var player: PlayerController = PlayerController.new()
	var area: Area3D = Area3D.new()
	area.name = "InteractionArea"
	player.add_child(area)
	var inv: Inventory = Inventory.new()
	inv.name = "Inventory"
	player.add_child(inv)
	var qt: QuestTracker = QuestTracker.new()
	qt.name = "QuestTracker"
	player.add_child(qt)
	var sprite: AnimatedSprite3D = AnimatedSprite3D.new()
	sprite.name = "AnimatedSprite3D"
	var frames: SpriteFrames = SpriteFrames.new()
	for anim_name: String in [
		"idle_down", "idle_up", "idle_side", "walk_down", "walk_up", "walk_side"
	]:
		frames.add_animation(anim_name)
	sprite.sprite_frames = frames
	player.add_child(sprite)
	return player
