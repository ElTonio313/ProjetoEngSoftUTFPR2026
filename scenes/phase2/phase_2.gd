extends Control

const COLOR_RIGHT := Color(0.1, 0.5, 0.2)
const COLOR_WRONG := Color(0.6901961, 0, 0.1254902)  # mesmos tons do quiz da Fase 1

@onready var intro_panel: Control = %IntroPanel
@onready var continue_button: Button = %ContinueButton
@onready var animal_card: AnimalCard = %AnimalCard
@onready var feedback_label: Label = %FeedbackLabel
@onready var mammals_zone: DropZone = %MammalsZone
@onready var reptiles_zone: DropZone = %ReptilesZone
@onready var birds_zone: DropZone = %BirdsZone

var manager := ClassificationManager.new()
var _feedback_tween: Tween


func _ready() -> void:
	manager.name = "ClassificationManager"
	add_child(manager)
	manager.exercise_ready.connect(_on_exercise_ready)
	manager.answer_checked.connect(_on_answer_checked)

	for zone in [mammals_zone, reptiles_zone, birds_zone]:
		zone.animal_dropped.connect(_on_animal_dropped)

	feedback_label.text = ""
	intro_panel.show()
	continue_button.grab_focus()

	# Prepara a fase (carrega os animais). O cronômetro NÃO começa aqui.
	if not manager.start_phase():
		continue_button.disabled = true
		continue_button.text = "Não foi possível carregar os animais"


func _on_continue_button_pressed() -> void:
	intro_panel.hide()
	manager.next_exercise()  # apresenta o 1º animal e inicia o cronômetro dele


func _on_exercise_ready(animal: Animal, _number: int, _total: int) -> void:
	animal_card.set_animal_name(animal.display_name)
	_set_animal_draggable(true)
	feedback_label.text = ""


func _on_animal_dropped(category: String) -> void:
	manager.submit_answer(category)


func _on_answer_checked(is_correct: bool, hint: String) -> void:
	if is_correct:
		_show_feedback("✔ Acertou! Muito bem!", COLOR_RIGHT)
		_set_animal_draggable(false)
	else:
		_show_feedback("✘ Não foi dessa vez. Tente de novo.\nDica: " + hint, COLOR_WRONG)


func _show_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.add_theme_color_override("font_color", color)
	# O fade faz a mensagem "reaparecer" a cada tentativa, mesmo que o texto seja igual.
	if _feedback_tween != null:
		_feedback_tween.kill()
	feedback_label.modulate.a = 0.0
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(feedback_label, "modulate:a", 1.0, 0.25)


func _set_animal_draggable(value: bool) -> void:
	animal_card.can_drag = value
	animal_card.mouse_default_cursor_shape = \
		Control.CURSOR_POINTING_HAND if value else Control.CURSOR_ARROW
