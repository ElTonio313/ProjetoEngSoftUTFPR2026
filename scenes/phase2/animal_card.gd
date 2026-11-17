class_name AnimalCard
extends PanelContainer

var can_drag: bool = true
@onready var name_label: Label = $NameLabel

func set_animal_name(value: String) -> void:
	name_label.text = value

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not can_drag:
		return null
	
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
