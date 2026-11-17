extends Node
## Teste automático da lógica da Fase 2, SEM interface.
## Rode a cena res://tests/classification_test.tscn (F6) e leia a aba "Saída".
## Simula um aluno que erra 0, 2, 0, 1, 0 e 0 vezes nos seis animais.

const ERRORS_PLAN := [0, 2, 0, 1, 0, 0]

var _falhas: int = 0
var _ready_ids: Array[String] = []
var _answer_count: int = 0
var _last_is_correct: bool = false
var _last_hint: String = ""
var _finished_count: int = 0
var _result: Dictionary = {}


func _ready() -> void:
	var manager := ClassificationManager.new()
	add_child(manager)
	manager.exercise_ready.connect(_on_exercise_ready)
	manager.answer_checked.connect(_on_answer_checked)
	manager.phase_finished.connect(_on_phase_finished)

	print("=== TESTE DA FASE 2 ===")
	_check(manager.start_phase(), "start_phase() carregou os animais")
	_check(manager.get_total() == 6, "a fase tem 6 animais (veio %d)" % manager.get_total())
	_check_composition(manager)

	var expected_ids: Array[String] = []
	for a in Animal.load_from_file(ClassificationManager.ANIMALS_PATH):
		expected_ids.append(a.id)

	_check(_ready_ids.is_empty(), "nenhum exercício começa antes de next_exercise()")
	manager.submit_answer("mamifero")
	_check(_answer_count == 0, "resposta antes do primeiro exercício é ignorada")

	var progress_ok := true
	var errors_ok := true
	var hint_ok := true
	var repeat_ok := true

	for i in ERRORS_PLAN.size():
		manager.next_exercise()
		var animal := manager.get_current_animal()
		await get_tree().create_timer(0.1).timeout

		if i == 0:
			manager.next_exercise()  # deve ser ignorado (gera um aviso amarelo)
			_check(manager.get_current_animal() == animal, "não avança sem acertar o animal atual")
			var errors_before_unknown := manager.total_errors
			var answers_before_unknown := _answer_count
			manager.submit_answer("peixe")  # categoria inexistente (gera um aviso amarelo)
			_check(manager.total_errors == errors_before_unknown and _answer_count == answers_before_unknown,
				"categoria desconhecida é ignorada e não conta erro")

		var wrong := _wrong_category_for(animal)
		for n in range(ERRORS_PLAN[i]):
			var errors_before := manager.total_errors
			var done_before := manager.completed_count
			manager.submit_answer(wrong)
			if _last_is_correct or manager.total_errors != errors_before + 1:
				errors_ok = false
			if manager.completed_count != done_before:
				progress_ok = false
			if _last_hint != animal.hint or _last_hint.is_empty():
				hint_ok = false
			await get_tree().create_timer(0.1).timeout

		manager.submit_answer(animal.category)
		if not _last_is_correct or manager.completed_count != i + 1:
			progress_ok = false

		# Respostas depois do acerto não podem mudar nada.
		var errors_after := manager.total_errors
		var answers_after := _answer_count
		manager.submit_answer(animal.category)
		manager.submit_answer(wrong)
		if manager.completed_count != i + 1 or manager.total_errors != errors_after \
				or _answer_count != answers_after:
			repeat_ok = false

	_check(progress_ok, "o progresso só avança no acerto (uma vez por animal)")
	_check(errors_ok, "cada erro soma exatamente 1 ao total")
	_check(hint_ok, "o erro devolve a dica do animal")
	_check(repeat_ok, "respostas depois do acerto são ignoradas")
	_check(_ready_ids == expected_ids, "os animais vieram na ordem fixa do arquivo")
	_check(manager.completed_count == 6, "6 animais concluídos")
	_check(_finished_count == 0, "a fase só termina no next_exercise() depois do último acerto")

	manager.next_exercise()
	_check(_finished_count == 1, "phase_finished foi emitido uma vez")
	_check(not manager.is_running(), "a fase não está mais em andamento")
	manager.submit_answer("ave")
	_check(_answer_count == _expected_answers(), "resposta depois do fim é ignorada")

	var exercises: Array = _result["exercises"]
	_check(exercises.size() == 6, "o resultado traz 6 exercícios")
	_check(_result["total_errors"] == 3, "3 erros no total (veio %s)" % _result["total_errors"])
	_check(exercises[0]["errors"] == 0 and exercises[1]["errors"] == 2 and exercises[3]["errors"] == 1,
		"erros por exercício corretos")
	var sum := 0
	for e in exercises:
		sum += int(e["errors"])
	_check(sum == _result["total_errors"], "a soma dos erros por exercício é o total")
	_check(float(exercises[1]["time_seconds"]) > 0.25,
		"o tempo continua contando durante os erros (veio %.2f s)" % exercises[1]["time_seconds"])
	_check(float(exercises[0]["time_seconds"]) < 0.25 and float(exercises[5]["time_seconds"]) < 0.25,
		"cada exercício mede só o seu tempo (não é cumulativo)")

	_check(manager.start_phase(), "start_phase() pode ser chamado de novo")
	_check(manager.total_errors == 0 and manager.completed_count == 0 and manager.is_running()
		and manager.get_current_animal() == null, "reiniciar zera o estado")
	manager.next_exercise()
	_check(manager.get_current_animal().id == expected_ids[0], "depois de reiniciar, volta ao primeiro animal")

	print("=== RESULTADO FINAL: %s ===" % ("TUDO CERTO" if _falhas == 0 else "%d FALHA(S)" % _falhas))


func _wrong_category_for(animal: Animal) -> String:
	for category in Animal.VALID_CATEGORIES:
		if category != animal.category:
			return str(category)
	return ""


func _check_composition(manager: ClassificationManager) -> void:
	var counts := {}
	for animal in manager.animals:
		counts[animal.category] = int(counts.get(animal.category, 0)) + 1
	var ok := true
	for category in Animal.VALID_CATEGORIES:
		if int(counts.get(category, 0)) != 2:
			ok = false
	_check(ok, "2 mamíferos, 2 répteis e 2 aves (veio %s)" % [str(counts)])


func _expected_answers() -> int:
	# Respostas registradas no teste: 6 acertos + 3 erros.
	return 9


func _check(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  OK     ", descricao)
	else:
		print("  FALHOU ", descricao)
		_falhas += 1


func _on_exercise_ready(animal: Animal, number: int, total: int) -> void:
	_ready_ids.append(animal.id)
	print("[%d/%d] %s  (%s)" % [number, total, animal.display_name, animal.category])


func _on_answer_checked(is_correct: bool, hint: String) -> void:
	_answer_count += 1
	_last_is_correct = is_correct
	_last_hint = hint
	print("       ", "ACERTOU" if is_correct else "ERROU -> " + hint)


func _on_phase_finished(result: Dictionary) -> void:
	_finished_count += 1
	_result = result
	print("Fim da fase: ", result)
