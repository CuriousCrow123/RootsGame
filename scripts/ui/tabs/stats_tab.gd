extends CenterContainer
## Placeholder stats tab. Styled empty state until stat system exists.


func _ready() -> void:
	var label: Label = get_child(0) as Label
	if label:
		label.text = "Character stats coming soon"
		label.theme_type_variation = &"DimLabel"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func grab_initial_focus() -> void:
	pass
