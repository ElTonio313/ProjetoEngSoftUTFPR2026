extends Control
## Tela da Fase 1 (quiz do Pantanal).
## Só cuida da interface: toda a lógica está no QuizManager.
##
## Fluxo de uma pergunta:
##   - O jogador escolhe uma alternativa.
##   - Se errar: o botão fica vermelho e travado, aparece a dica e ele tenta de novo.
##   - Se acertar: aparece a explicação e o botão "Próxima".
##   - O botão "Dica" mostra a dica a qualquer momento.
##   - No fim, "Continuar" leva à Fase 2 (GameState.go_to_phase2()).
## Barra de cima: "Sobre" (explica a fase) e controles de som (scenes/ui/AudioControls).

const SOUND_RIGHT := "res://assets/sounds/correctAudio.ogg"
const SOUND_WRONG := "res://assets/sounds/wrongAudio.ogg"
const COLOR_TEXT := Color(0.101960786, 0.101960786, 0.101960786)
const COLOR_RIGHT := Color(0.1, 0.5, 0.2)
const COLOR_WRONG := Color(0.6901961, 0, 0.1254902)  # mesmo vermelho da tela de nome
const COLOR_HINT := Color(0.05, 0.25, 0.55)
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
@onready var hint_button: Button = %HintButton
@onready var next_button: Button = %NextButton
@onready var restart_button: Button = %RestartButton
@onready var about_button: Button = %AboutButton
@onready var about_overlay: Control = %AboutOverlay
@onready var close_about_button: Button = %CloseAboutButton
@export var about_audio: AudioStream
@export var hint_audio: AudioStream
@export var about_text_audio: AudioStream

var quiz := QuizManager.new()
var _finished: bool = false
var _sfx_right: AudioStreamPlayer
var _sfx_wrong: AudioStreamPlayer
var _icon_right: ImageTexture   # símbolo de certo (✓) desenhado por código
var _icon_wrong: ImageTexture   # símbolo de errado (✗) desenhado por código

# Frases fixas, reaproveitadas da Fase 2. O texto da tela precisa ser igual ao áudio.
const AUDIO_CORRECT := "res://assets/audio/narration/phase2/feedback_correct.ogg"  # "Acertou! Muito bem!"
const AUDIO_WRONG := "res://assets/audio/narration/phase2/feedback_wrong.ogg"      # "Não foi dessa vez. Tente de novo."
const AUDIO_FINISH := "res://assets/audio/narration/phase1/finish.ogg"             # "Fase 1 concluída. Parabéns!" (a gravar)
var narrator := Narrator.new()
var _question: Question   # pergunta atual, para achar os áudios dela

func _ready() -> void:
	add_child(quiz)
	add_child(narrator)
	_sfx_right = _make_sfx(SOUND_RIGHT)
	_sfx_wrong = _make_sfx(SOUND_WRONG)
	_icon_right = _make_symbol(true)
	_icon_wrong = _make_symbol(false)

	quiz.question_ready.connect(_on_question_ready)
	quiz.wrong_answer.connect(_on_wrong_answer)
	quiz.hint_shown.connect(_on_hint_shown)
	quiz.answer_checked.connect(_on_answer_checked)
	quiz.quiz_finished.connect(_on_quiz_finished)

	hint_button.pressed.connect(quiz.use_hint)
	next_button.pressed.connect(_on_next_pressed)
	restart_button.pressed.connect(_start)
	about_button.pressed.connect(_open_about)
	close_about_button.pressed.connect(_close_about)
	_start()


func _unhandled_input(event: InputEvent) -> void:
	if about_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_about()
		get_viewport().set_input_as_handled()


func _start() -> void:
	_finished = false
	if not quiz.start_quiz():
		_clear_options()
		progress_label.text = ""
		question_label.text = "Não foi possível carregar as perguntas."
		result_label.text = ""
		feedback_label.text = ""
		hint_button.hide()
		next_button.hide()
		restart_button.hide()


# ---------------------------------------------------------------- Sobre

func _open_about() -> void:
	about_overlay.show()
	close_about_button.grab_focus()


func _close_about() -> void:
	about_overlay.hide()
	about_button.grab_focus()


# ------------------------------------------------------- Sinais do quiz

func _on_question_ready(question: Question, number: int, total: int) -> void:
	_question = question
	progress_label.text = "Pergunta %d de %d" % [number, total]
	progress_bar.max_value = total
	progress_bar.value = number - 1
	question_label.text = question.text
	result_label.text = ""
	_set_feedback("", COLOR_TEXT)

	hint_button.visible = question.hint != ""   # sem dica cadastrada, o botão não aparece
	hint_button.disabled = false
	next_button.hide()
	restart_button.hide()

	_clear_options()
	var parts: Array[AudioStream] = [Narrator.load_audio(QuizAudio.question_path(question))]
	for i in question.options.size():
		var button := Button.new()
		button.text = question.options[i]
		button.custom_minimum_size = Vector2(360, 80)
		button.add_theme_font_size_override("font_size", 36)
		button.pressed.connect(_on_option_pressed.bind(i))
		button.mouse_entered.connect(_on_option_hover.bind(i))
		options_grid.add_child(button)
		parts.append(Narrator.load_audio(QuizAudio.option_path(question, question.options[i])))
	narrator.say_all(parts)   # pergunta e depois cada alternativa, na ordem da tela

# Passar o mouse numa alternativa repete o nome dela (prioridade baixa: não corta a narração principal).
func _on_option_hover(index: int) -> void:
	var audio := Narrator.load_audio(QuizAudio.option_path(_question, _question.options[index]))
	narrator.say(audio, Narrator.PRIORITY_HOVER)


func _on_option_pressed(index: int) -> void:
	quiz.answer(index)


## Errou: pinta e trava só essa alternativa, mostra a dica e deixa tentar de novo.
func _on_wrong_answer(wrong_index: int, hint: String) -> void:
	_paint_button(options_grid.get_child(wrong_index) as Button, COLOR_WRONG, _icon_wrong)
	result_label.text = "Não foi dessa vez. Tente de novo."   # igual ao áudio
	result_label.add_theme_color_override("font_color", COLOR_WRONG)
	if hint != "":
		_show_hint(hint)
	# o efeito sonoro entra na própria fila da narração: nada toca ao mesmo tempo
	var parts: Array[AudioStream] = [_sfx_wrong.stream]
	if hint != "":
		parts.append(Narrator.load_audio(QuizAudio.hint_path(_question)))
	narrator.say_all(parts)

func _on_hint_shown(hint: String) -> void:
	_show_hint(hint)
	narrator.say(Narrator.load_audio(QuizAudio.hint_path(_question)))
	
func _show_hint(hint: String) -> void:
	_set_feedback("Dica: %s" % hint, COLOR_HINT)
	hint_button.disabled = true

## Acertou: trava tudo, mostra a explicação e o botão "Próxima".
func _on_answer_checked(first_try: bool, correct_index: int, feedback: String) -> void:
	for button in options_grid.get_children():
		(button as Button).disabled = true
	_paint_button(options_grid.get_child(correct_index) as Button, COLOR_RIGHT, _icon_right)

	result_label.text = "Acertou! Muito bem!"   # igual ao áudio (vale para acerto de primeira ou não)
	result_label.add_theme_color_override("font_color", COLOR_RIGHT)
	_set_feedback(feedback, COLOR_TEXT)
	var parts: Array[AudioStream] = [_sfx_right.stream,
			Narrator.load_audio(QuizAudio.feedback_path(_question))]
	narrator.say_all(parts)
	_play(_sfx_right)

	hint_button.hide()
	progress_bar.value = quiz.current_index + 1
	var is_last := quiz.current_index + 1 >= quiz.get_total()
	next_button.text = "Ver resultado" if is_last else "Próxima"
	next_button.show()
	next_button.grab_focus()   # Enter ou Espaço avançam


func _on_next_pressed() -> void:
	if _finished:
		_leave_phase()
	else:
		quiz.next_question()


## Fim da fase: segue o fluxo do jogo (Fase 1 -> Fase 2) pelo GameState, que é quem
## conhece o caminho das cenas. Enquanto o GameState não tiver go_to_phase2(), o botão
## "Continuar" só avisa no painel de erros, sem travar o jogo.
func _leave_phase() -> void:
	if GameState.has_method("go_to_phase2"):
		GameState.go_to_phase2()
	else:
		push_warning("GameState.go_to_phase2() ainda não existe: ligação com a Fase 2 pendente.")


func _on_quiz_finished(result: Dictionary) -> void:
	_finished = true
	_clear_options()
	hint_button.hide()
	progress_label.text = "Fase 1 concluída"
	progress_bar.value = progress_bar.max_value

	var player_name: String = GameState.player_name
	question_label.text = "Você acertou %d de %d de primeira" % [int(result["hits"]), int(result["total"])]
	result_label.text = "Parabéns, %s!" % player_name if player_name != "" else "Parabéns!"
	result_label.add_theme_color_override("font_color", COLOR_RIGHT)

	var lines: Array[String] = []
	for category in result["by_category"]:
		var data: Dictionary = result["by_category"][category]
		var nice_name: String = CATEGORY_NAMES.get(category, str(category).capitalize())
		lines.append("%s: %d de %d" % [nice_name, int(data["hits"]), int(data["total"])])
	_set_feedback("\n".join(lines), COLOR_TEXT)

	next_button.text = "Continuar"
	next_button.show()
	restart_button.show()
	next_button.grab_focus()
	narrator.say(Narrator.load_audio(AUDIO_FINISH))


# ------------------------------------------------------------ Auxiliares

func _set_feedback(text: String, color: Color) -> void:
	feedback_label.text = text
	feedback_label.add_theme_color_override("font_color", color)


## Pinta um botão (já travado) com fundo colorido, texto branco e um símbolo (✓ ou ✗).
## O feedback não depende só da cor: tem texto e símbolo também.
func _paint_button(button: Button, color: Color, symbol: Texture2D) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(4)
	button.add_theme_stylebox_override("disabled", style)
	button.add_theme_color_override("font_disabled_color", Color.WHITE)
	button.add_theme_color_override("icon_disabled_color", Color.WHITE)
	button.add_theme_constant_override("h_separation", 14)
	button.icon = symbol
	button.disabled = true


## Desenha o símbolo ✓ (certo) ou ✗ (errado) em branco, sem depender de fonte ou arquivo de imagem.
func _make_symbol(is_check: bool) -> ImageTexture:
	var size := 40
	var half_width := 2.8
	var segments: Array = []
	if is_check:
		segments = [[Vector2(7, 21), Vector2(16, 30)], [Vector2(16, 30), Vector2(33, 10)]]
	else:
		segments = [[Vector2(9, 9), Vector2(31, 31)], [Vector2(31, 9), Vector2(9, 31)]]

	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var point := Vector2(x + 0.5, y + 0.5)
			var distance := 999.0
			for segment in segments:
				var closest := Geometry2D.get_closest_point_to_segment(point, segment[0], segment[1])
				distance = minf(distance, point.distance_to(closest))
			var alpha := clampf(half_width + 0.5 - distance, 0.0, 1.0)   # borda suave
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)


func _clear_options() -> void:
	for child in options_grid.get_children():
		options_grid.remove_child(child)
		child.queue_free()


func _make_sfx(path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	if ResourceLoader.exists(path):
		player.stream = load(path)
	else:
		push_warning("Som não encontrado: %s" % path)
	add_child(player)
	return player


func _play(player: AudioStreamPlayer) -> void:
	if player.stream != null:
		player.play()


func _on_about_button_mouse_entered() -> void:
	narrator.say(about_audio, Narrator.PRIORITY_HOVER)

func _on_hint_button_mouse_entered() -> void:
	narrator.say(hint_audio, Narrator.PRIORITY_HOVER)

func _on_about_button_pressed() -> void:
	narrator.say(about_text_audio, Narrator.PRIORITY_HOVER)
