class_name DropZone
extends PanelContainer
# Área de classificação acessível: aceita tanto um animal arrastado e solto sobre ela
# (drag-and-drop) quanto um clique direto ou tecla Enter/Espaço (acessibilidade motora).

signal animal_dropped(category: String)
signal animal_classified(category: String, input_mode: String)

# Identificador da categoria definido no inspetor
@export var category: String = ""

var _normal_style: StyleBoxFlat
var _hover_style: StyleBoxFlat


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var border_col := Color(0.180392, 0.490196, 0.196078, 1.0)
	var bg_tint := Color(0.980, 0.973, 0.949, 0.97)
	var hover_bg := Color(0.86, 0.95, 0.87, 1.0)
	if category == "mamifero":
		border_col = Color(0.58, 0.34, 0.12, 1.0)
		bg_tint = Color(0.992, 0.968, 0.935, 0.97)
		hover_bg = Color(0.98, 0.91, 0.80, 1.0)
	elif category == "ave":
		border_col = Color(0.10, 0.45, 0.68, 1.0)
		bg_tint = Color(0.945, 0.975, 0.995, 0.97)
		hover_bg = Color(0.84, 0.93, 0.99, 1.0)

	_normal_style = StyleBoxFlat.new()
	_normal_style.bg_color = bg_tint
	_normal_style.border_color = border_col
	_normal_style.set_border_width_all(4)
	_normal_style.border_width_bottom = 6
	_normal_style.set_corner_radius_all(16)
	_normal_style.set_content_margin_all(16)

	_hover_style = _normal_style.duplicate() as StyleBoxFlat
	_hover_style.bg_color = hover_bg
	_hover_style.set_border_width_all(5)

	add_theme_stylebox_override("panel", _normal_style)
	mouse_entered.connect(_apply_hover_style)
	mouse_exited.connect(_restore_style)
	focus_entered.connect(_apply_hover_style)
	focus_exited.connect(_restore_style)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			accept_event()
			animal_classified.emit(category, "clique")
			animal_dropped.emit(category)
	elif event.is_action_pressed("ui_accept"):
		accept_event()
		animal_classified.emit(category, "teclado")
		animal_dropped.emit(category)


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_restore_style()


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var ok: bool = typeof(data) == TYPE_DICTIONARY and data.has("animal_name")
	if ok:
		_apply_hover_style()
	return ok


func _drop_data(_at_position: Vector2, _data: Variant) -> void:
	_restore_style()
	animal_classified.emit(category, "arraste")
	animal_dropped.emit(category)


func _apply_hover_style() -> void:
	if _hover_style != null:
		add_theme_stylebox_override("panel", _hover_style)


func _restore_style() -> void:
	if _normal_style != null and not has_focus():
		add_theme_stylebox_override("panel", _normal_style)
