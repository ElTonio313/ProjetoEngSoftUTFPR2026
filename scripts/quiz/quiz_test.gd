extends Node
## Teste automático da lógica da Fase 1, SEM interface.
## Rode a cena res://tests/quiz_test.tscn (tecla F6) e leia a aba "Saída".
##
## Simula um jogador que:
##   pergunta 1: acerta de primeira
##   pergunta 2: erra, vê a dica e depois acerta (conta como erro)
##   pergunta 3: usa o botão Dica (duas vezes) e acerta de primeira
##   pergunta 4: erra (duas vezes a mesma alternativa) e depois acerta
##   pergunta 5: acerta de primeira

var _falhas: int = 0
var _resolvidas: int = 0
var _ultima_dica_erro: String = ""
var _ultima_dica_botao: String = ""
var _erros_emitidos: int = 0
var _primeira_tentativa: Array[bool] = []


func _ready() -> void:
	var quiz := QuizManager.new()
	add_child(quiz)

	quiz.question_ready.connect(_on_question_ready)
	quiz.wrong_answer.connect(_on_wrong_answer)
	quiz.hint_shown.connect(_on_hint_shown)
	quiz.answer_checked.connect(_on_answer_checked)
	quiz.quiz_finished.connect(_on_quiz_finished)

	print("=== TESTE DA FASE 1 ===")
	_check(quiz.start_quiz(), "start_quiz() carregou as perguntas")
	_check(quiz.get_total() == 5, "o quiz tem 5 perguntas")

	var passo := 0
	while quiz.is_running():
		var q := quiz.get_current_question()
		var indice_antes := quiz.current_index
		var errada := (q.correct_index + 1) % q.options.size()

		if passo == 1 or passo == 3:
			quiz.answer(errada)
			_check(quiz.current_index == indice_antes and _resolvidas == passo,
				"pergunta %d: depois de errar a pergunta continua aberta" % (passo + 1))
			_check(_ultima_dica_erro != "", "pergunta %d: ao errar vem uma dica" % (passo + 1))
			quiz.answer(errada)  # a mesma alternativa errada de novo
			_check(_erros_emitidos == (1 if passo == 1 else 2),
				"pergunta %d: errar a mesma alternativa de novo é ignorado" % (passo + 1))
			_check(quiz.misses == (1 if passo == 1 else 2),
				"pergunta %d: conta como erro uma única vez" % (passo + 1))

		if passo == 2:
			quiz.use_hint()
			quiz.use_hint()
			_check(_ultima_dica_botao == q.hint, "pergunta 3: botão Dica devolve a dica da pergunta")
			_check(quiz.hints_used == 1, "pergunta 3: pedir a dica duas vezes conta uma só")

		quiz.answer(q.correct_index)
		_check(_resolvidas == passo + 1, "pergunta %d: alternativa certa resolve a pergunta" % (passo + 1))
		if passo == 0:
			var acertos_antes := quiz.hits
			quiz.answer(q.correct_index)  # resposta repetida depois de resolvida
			_check(quiz.hits == acertos_antes, "resposta repetida depois de acertar é ignorada")
		quiz.next_question()
		passo += 1

	_check(_primeira_tentativa == [true, false, true, false, true],
		"first_try correto em cada pergunta (%s)" % [_primeira_tentativa])

	var r := quiz.get_result()
	_check(r["hits"] == 3, "3 acertos de primeira (veio %s)" % r["hits"])
	_check(r["misses"] == 2, "2 perguntas com erro (veio %s)" % r["misses"])
	_check(r["hits"] + r["misses"] == r["total"], "acertos + erros = total de perguntas")
	_check(r["percent"] == 60, "60%% de aproveitamento (veio %s)" % r["percent"])
	_check(r["hints_used"] == 1, "1 uso do botão Dica (veio %s)" % r["hints_used"])
	_check(r["by_category"].has("fauna"), "resultado tem a categoria fauna")
	_check(r["by_category"]["fauna"]["hits"] == 2, "fauna: 2 acertos (perguntas 1 e 3)")

	var game_data = get_node_or_null("/root/GameData")
	if game_data == null:
		# O GameData é do grupo (autoload/game_data.gd). Sem ele, só esta parte é pulada.
		print("  PULADO autoload GameData não está cadastrado (resultado não salvo)")
	else:
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
	_ultima_dica_erro = ""
	_ultima_dica_botao = ""
	print("[%d/%d] %s  %s" % [number, total, question.text, question.options])


func _on_wrong_answer(_wrong_index: int, hint: String) -> void:
	_erros_emitidos += 1
	_ultima_dica_erro = hint
	print("       ERROU  -> dica: ", hint)


func _on_hint_shown(hint: String) -> void:
	_ultima_dica_botao = hint
	print("       DICA   -> ", hint)


func _on_answer_checked(first_try: bool, _correct_index: int, feedback: String) -> void:
	_resolvidas += 1
	_primeira_tentativa.append(first_try)
	print("       ", "ACERTOU DE PRIMEIRA" if first_try else "ACERTOU (depois de errar)", " -> ", feedback)


func _on_quiz_finished(result: Dictionary) -> void:
	print("Fim do quiz: ", result)
