extends Control
## Tela da Fase 1 (quiz do Pantanal).
## Só cuida da interface: toda a lógica está no QuizManager.


const COLOR_RIGHT := Color(0.1, 0.5, 0.2)
const COLOR_WRONG := Color(0.6901961, 0, 0.1254902)  # mesmo vermelho da tela de nome
const CATEGORY_NAMES := {
	"fauna": "Fauna",
	"flora": "Flora",
	"conservacao": "Conservação",
}

@onready var progress_label: Label = %ProgressLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var question_label: Label = %QuestionLabel
@onready var options_grid: GridContainer = %OptionsGrid
@onready var result_label: Label = %ResultLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var next_button: Button = %NextButton
@onready var restart_button: Button = %RestartButton

var quiz := QuizManager.new()
var _chosen_index: int = -1
var _finished: bool = false


func _ready() -> void:
	add_child(quiz)
	quiz.question_ready.connect(_on_question_ready)
	quiz.answer_checked.connect(_on_answer_checked)
	quiz.quiz_finished.connect(_on_quiz_finished)
	next_button.pressed.connect(_on_next_pressed)
	restart_button.pressed.connect(_start)
	_start()


func _start() -> void:
	_finished = false
	if not quiz.start_quiz():
		_clear_options()
		progress_label.text = ""
		question_label.text = "Não foi possível carregar as perguntas."
		result_label.text = ""
		feedback_label.text = ""
		next_button.hide()
		restart_button.hide()


func _on_question_ready(question: Question, number: int, total: int) -> void:
	_chosen_index = -1
	progress_label.text = "Pergunta %d de %d" % [number, total]
	progress_bar.max_value = total
	progress_bar.value = number - 1
	question_label.text = question.text
	result_label.text = ""
	feedback_label.text = ""
	next_button.hide()
	restart_button.hide()

	_clear_options()
	for i in question.options.size():
		var button := Button.new()
		button.text = question.options[i]
		button.custom_minimum_size = Vector2(360, 80)
		button.add_theme_font_size_override("font_size", 36)
		button.pressed.connect(_on_option_pressed.bind(i))
		options_grid.add_child(button)


func _on_option_pressed(index: int) -> void:
	_chosen_index = index
	for button in options_grid.get_children():
		(button as Button).disabled = true
	quiz.answer(index)


func _on_answer_checked(is_correct: bool, correct_index: int, feedback: String) -> void:
	var buttons := options_grid.get_children()
	_paint_button(buttons[correct_index] as Button, COLOR_RIGHT)
	if not is_correct and _chosen_index >= 0:
		_paint_button(buttons[_chosen_index] as Button, COLOR_WRONG)

	if is_correct:
		result_label.text = "Correto!"
		result_label.add_theme_color_override("font_color", COLOR_RIGHT)
	else:
		var right_answer := quiz.get_current_question().options[correct_index]
		result_label.text = "Errado. A resposta certa é: %s" % right_answer
		result_label.add_theme_color_override("font_color", COLOR_WRONG)

	feedback_label.text = feedback
	progress_bar.value = quiz.current_index + 1
	var is_last := quiz.current_index + 1 >= quiz.get_total()
	next_button.text = "Ver resultado" if is_last else "Próxima"
	next_button.show()


func _on_next_pressed() -> void:
	if _finished:
		GameState.go_to_phase2()
	else:
		quiz.next_question()


func _on_quiz_finished(result: Dictionary) -> void:
	_finished = true
	_clear_options()
	progress_label.text = "Fase 1 concluída"
	progress_bar.value = progress_bar.max_value

	var player_name: String = GameState.player_name
	question_label.text = "Você acertou %d de %d (%d%%)" % [
		int(result["hits"]), int(result["total"]), int(result["percent"])
	]
	result_label.text = "Parabéns, %s!" % player_name if player_name != "" else "Parabéns!"
	result_label.add_theme_color_override("font_color", COLOR_RIGHT)

	var lines: Array[String] = []
	for category in result["by_category"]:
		var data: Dictionary = result["by_category"][category]
		var nice_name: String = CATEGORY_NAMES.get(category, str(category).capitalize())
		lines.append("%s: %d de %d" % [nice_name, int(data["hits"]), int(data["total"])])
	feedback_label.text = "\n".join(lines)

	next_button.text = "Continuar"
	next_button.show()
	restart_button.show()


## Pinta um botão (já travado) com fundo colorido e texto branco, bem legível.
func _paint_button(button: Button, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("disabled", style)
	button.add_theme_color_override("font_disabled_color", Color.WHITE)


func _clear_options() -> void:
	for child in options_grid.get_children():
		options_grid.remove_child(child)
		child.queue_free()
