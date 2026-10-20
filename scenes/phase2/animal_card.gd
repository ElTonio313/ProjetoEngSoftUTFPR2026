extends PanelContainer

@onready var name_label: Label = $NameLabel

func _get_drag_data(_at_position: Vector2) -> Variant:
	# Cópia visual que acompanha o cursor durante o arraste.
	var preview := duplicate() as Control
	preview.size = size
	preview.modulate = Color(1, 1, 1, 0.85)

	# Um Control "embrulha" a cópia para centralizá-la no cursor.
	var holder := Control.new()
	holder.add_child(preview)
	preview.position = -0.5 * size
	set_drag_preview(holder)

	return {"animal_name": name_label.text}
