class_name DropZone
extends PanelContainer
# Área de classificação, aceita um animal solto sobre ela e avisa 
# quem decide a lógica é a fase, não a área

signal animal_dropped(category: String)

# Indentificador da categoria definido no inspetor
@export var category: String = ""

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("animal_name")

func _drop_data(at_position: Vector2, data: Variant) -> void:
	animal_dropped.emit(category)
