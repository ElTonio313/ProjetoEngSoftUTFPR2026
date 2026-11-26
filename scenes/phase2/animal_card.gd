class_name AnimalCard
extends PanelContainer

var can_drag: bool = true
@onready var name_label: Label = $CardBox/NameLabel
@onready var animal_image: TextureRect = $CardBox/AnimalImage


func set_animal_name(value: String) -> void:
	name_label.text = value


func set_animal(value: String, image_path: String = "") -> void:
	name_label.text = value
	var tex := _load_texture(image_path)
	animal_image.texture = tex
	animal_image.visible = tex != null


func _get_drag_data(_at_position: Vector2) -> Variant:
	if not can_drag:
		return null

	# Cópia visual que acompanha o cursor durante o arraste.
	var preview := duplicate() as Control
	preview.size = size
	preview.modulate = Color(1, 1, 1, 0.9)

	# Um Control "embrulha" a cópia para centralizá-la no cursor.
	var holder := Control.new()
	holder.add_child(preview)
	preview.position = -0.5 * size
	set_drag_preview(holder)

	return {"animal_name": name_label.text}


func _load_texture(path: String) -> Texture2D:
	if path == "":
		return null
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	return null
