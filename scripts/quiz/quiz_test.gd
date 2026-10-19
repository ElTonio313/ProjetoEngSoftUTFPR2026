extends Node
## Teste automático da lógica da Fase 1, SEM interface.
## Rode a cena res://tests/quiz_test.tscn (tecla F6) e leia o painel "Output".
## Simula um jogador que acerta as perguntas 1, 3 e 5 e erra a 2 e a 4.

var _falhas: int = 0


func _ready() -> void:
	var quiz := QuizManager.new()
	add_child(quiz)

	quiz.question_ready.connect(_on_question_ready)
	quiz.answer_checked.connect(_on_answer_checked)
	quiz.quiz_finished.connect(_on_quiz_finished)

	print("=== TESTE DA FASE 1 ===")
	_check(quiz.start_quiz(), "start_quiz() carregou as perguntas")
	_check(quiz.get_total() == 5, "o quiz tem 5 perguntas")

	var passo := 0
	while quiz.is_running():
		var q := quiz.get_current_question()
		var escolha := q.correct_index
		if passo % 2 == 1:
			escolha = (q.correct_index + 1) % q.options.size()  # alternativa errada
		quiz.answer(escolha)
		if passo == 0:
			var acertos_antes := quiz.hits
			quiz.answer(escolha)  # resposta repetida deve ser ignorada
			_check(quiz.hits == acertos_antes, "resposta repetida é ignorada")
		quiz.next_question()
		passo += 1

	var r := quiz.get_result()
	_check(r["hits"] == 3, "3 acertos (veio %s)" % r["hits"])
	_check(r["misses"] == 2, "2 erros (veio %s)" % r["misses"])
	_check(r["percent"] == 60, "60%% de aproveitamento (veio %s)" % r["percent"])
	_check(r["by_category"].has("fauna"), "resultado tem a categoria fauna")

	var game_data = get_node_or_null("/root/GameData")
	_check(game_data != null, "autoload GameData está cadastrado")
	if game_data != null:
		_check(game_data.has_phase1_result(), "GameData guardou o resultado da Fase 1")
		_check(FileAccess.file_exists(game_data.SAVE_PATH), "arquivo de save foi criado")

	print("=== RESULTADO FINAL: %s ===" % ("TUDO CERTO" if _falhas == 0 else "%d FALHA(S)" % _falhas))


func _check(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  OK     ", descricao)
	else:
		print("  FALHOU ", descricao)
		_falhas += 1


func _on_question_ready(question: Question, number: int, total: int) -> void:
	print("[%d/%d] %s  %s" % [number, total, question.text, question.options])


func _on_answer_checked(is_correct: bool, _correct_index: int, feedback: String) -> void:
	print("       ", "ACERTOU" if is_correct else "ERROU", " -> ", feedback)


func _on_quiz_finished(result: Dictionary) -> void:
	print("Fim do quiz: ", result)
