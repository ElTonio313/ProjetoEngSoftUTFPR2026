class_name QuizManager
extends Node
## Lógica completa da Fase 1 (quiz do Pantanal).
## Este script NÃO conhece botões, textos ou telas: o front-end só chama as
## funções públicas e escuta os sinais abaixo.
##
## CONTRATO COM O FRONT-END
##   Funções:  start_quiz()  |  answer(indice)  |  next_question()
##   Sinais:   question_ready(question, numero, total)
##             answer_checked(is_correct, correct_index, feedback)
##             quiz_finished(result)

## Emitido quando uma pergunta deve ser mostrada (vídeo-tutorial + pergunta).
signal question_ready(question: Question, number: int, total: int)
## Emitido depois que o jogador responde (mostrar acerto/erro + explicação).
signal answer_checked(is_correct: bool, correct_index: int, feedback: String)
## Emitido depois da última pergunta (ir para a tela de resultado).
signal quiz_finished(result: Dictionary)

const QUESTIONS_PATH := "res://data/questions.json"

## Se verdadeiro, a ordem das alternativas muda a cada partida.
@export var shuffle_options: bool = true

var questions: Array[Question] = []
var current_index: int = -1
var hits: int = 0
var misses: int = 0

var _running: bool = false
var _answered: bool = false
var _start_msec: int = 0
var _by_category: Dictionary = {}


## Começa (ou reinicia) a fase. Devolve false se não conseguiu carregar as perguntas.
func start_quiz() -> bool:
	questions = Question.load_from_file(QUESTIONS_PATH)
	if questions.is_empty():
		push_error("Quiz não iniciado: nenhuma pergunta foi carregada.")
		return false

	if shuffle_options:
		for q in questions:
			q.shuffle_options()

	current_index = -1
	hits = 0
	misses = 0
	_by_category = {}
	for q in questions:
		if not _by_category.has(q.category):
			_by_category[q.category] = {"hits": 0, "total": 0}
		_by_category[q.category]["total"] += 1

	_running = true
	_answered = false
	_start_msec = Time.get_ticks_msec()
	next_question()
	return true


## Registra a resposta do jogador (posição da alternativa escolhida: 0, 1, ...).
## Respostas repetidas na mesma pergunta são ignoradas.
func answer(option_index: int) -> void:
	if not _running or _answered:
		return

	var q := questions[current_index]
	if option_index < 0 or option_index >= q.options.size():
		push_warning("answer(): índice de alternativa inválido (%d)." % option_index)
		return

	_answered = true
	var is_correct := (option_index == q.correct_index)
	if is_correct:
		hits += 1
		_by_category[q.category]["hits"] += 1
	else:
		misses += 1

	answer_checked.emit(is_correct, q.correct_index, q.feedback)


## Avança para a próxima pergunta, ou encerra a fase se acabaram.
## Só funciona depois que a pergunta atual foi respondida.
func next_question() -> void:
	if not _running:
		push_warning("next_question(): o quiz não está em andamento.")
		return
	if current_index >= 0 and not _answered:
		push_warning("next_question(): responda a pergunta atual antes de avançar.")
		return

	current_index += 1
	if current_index >= questions.size():
		_finish()
		return

	_answered = false
	question_ready.emit(questions[current_index], current_index + 1, questions.size())


## Resumo da partida (também é o que fica salvo no GameData).
func get_result() -> Dictionary:
	var total := questions.size()
	var elapsed := (Time.get_ticks_msec() - _start_msec) / 1000.0
	return {
		"hits": hits,
		"misses": misses,
		"total": total,
		"percent": roundi(100.0 * hits / total) if total > 0 else 0,
		"time_seconds": snappedf(elapsed, 0.1),
		"by_category": _by_category.duplicate(true),
	}


func is_running() -> bool:
	return _running


func get_total() -> int:
	return questions.size()


func get_current_question() -> Question:
	if current_index < 0 or current_index >= questions.size():
		return null
	return questions[current_index]


func _finish() -> void:
	_running = false
	var result := get_result()

	# Salva no GameData (autoload) para a Fase 2 e o Relatório lerem depois.
	var game_data = get_node_or_null("/root/GameData")
	if game_data != null:
		game_data.set_phase1_result(result)
	else:
		push_warning("Autoload GameData não encontrado: o resultado não foi salvo.")

	quiz_finished.emit(result)
