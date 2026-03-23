class_name PromptLabelFactory
extends RefCounted
## Creates a configured Label3D for interaction prompts ("[E] Talk to Nathan").
## Shared by all interactable types to avoid duplicating the same setup code.

const LABEL_OFFSET: Vector3 = Vector3(0.0, 2.0, 0.0)
const PIXEL_SIZE: float = 0.005
const FONT_SIZE: int = 24
const OUTLINE_SIZE: int = 8
const OUTLINE_COLOR: Color = Color(0.0, 0.0, 0.0, 0.8)
const RENDER_PRIORITY: int = 10


static func create(text: String, offset: Vector3 = LABEL_OFFSET) -> Label3D:
	var label: Label3D = Label3D.new()
	label.text = text
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.set_draw_flag(Label3D.FLAG_DISABLE_DEPTH_TEST, true)
	label.render_priority = RENDER_PRIORITY
	label.pixel_size = PIXEL_SIZE
	label.font_size = FONT_SIZE
	label.outline_size = OUTLINE_SIZE
	label.outline_modulate = OUTLINE_COLOR
	label.position = offset
	label.visible = false
	return label
