class_name PortraitData
extends RefCounted
## Static portrait lookup. Maps character names to portrait textures.
## Add entries to PORTRAITS as portrait art becomes available.
## Expression support: pass "Character:expression" to get_portrait().

const PORTRAITS: Dictionary = {
# "Nathan": preload("res://resources/portraits/nathan.png"),
}


## Look up a portrait by character name. Supports "Name:expression" format.
## Returns null if no portrait exists for the character.
static func get_portrait(character_key: String) -> Texture2D:
	# Try exact key first (supports "Name:expression")
	if PORTRAITS.has(character_key):
		return PORTRAITS[character_key] as Texture2D
	# Fall back to base name without expression
	var base_name: String = character_key.get_slice(":", 0)
	if PORTRAITS.has(base_name):
		return PORTRAITS[base_name] as Texture2D
	return null
