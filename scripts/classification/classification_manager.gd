class_name ClassificationManager
extends Node

## Lógica da Fase 2.

## CONTRATO COM A INTERFACE (proposta provisória, a combinar com o grupo)
##   Funções:  start_phase()  |  next_exercise()  |  submit_answer(categoria)
##   Sinais:   exercise_ready(animal, numero, total)
##             answer_checked(is_correct, hint)
##             phase_finished(result)

#mostra o animal e inicia o cronometro
signal exercise_ready(animal: Animal, number: int, total: int)
#resultado da tentativa, hint só vem quando erra
signal answer_checked(is_correct: bool, hint: String)
signal phase_finished(result: Dictionary)

const ANIMALS_PATH := "res://data/animals.json"

var animals: Array[Animal] = []
var current_index: int = -1      # posição do animal atual na lista
var completed_count: int = 0     # quantos animais já foram acertados
var total_errors: int = 0        # todas as tentativas incorretas

var _running: bool = false
var _exercise_active: bool = false   # há um animal esperando resposta?
var _exercise_start_msec: int = 0
var _errors_by_exercise: Array[int] = []
var _times_msec: Array[int] = []     # um valor por exercício concluído

## Prepara a fase: carrega os animais e zera tudo. NÃO inicia o cronômetro.
## Devolve false se não conseguiu carregar nenhum animal.
func start_phase() -> bool:
	animals = Animal.load_from_file(ANIMALS_PATH)
	if animals.is_empty():
		push_error("Fase 2 não iniciada: nenhum animal foi carregado.")
		_running = false
		return false

	current_index = -1
	completed_count = 0
	total_errors = 0
	_errors_by_exercise.clear()
	_times_msec.clear()
	_exercise_active = false
	_running = true
	return true

## Apresenta o próximo animal (e inicia o cronômetro dele), ou encerra a fase
## se os animais acabaram. Só funciona depois que o animal atual foi acertado.
func next_exercise() -> void:
	if not _running:
		push_warning("next_exercise(): a fase não está em andamento.")
		return
	if _exercise_active:
		push_warning("next_exercise(): acerte o animal atual antes de avançar.")
		return

	current_index += 1
	if current_index >= animals.size():
		_finish()
		return

	_errors_by_exercise.append(0)
	_exercise_active = true
	_exercise_start_msec = Time.get_ticks_msec()
	exercise_ready.emit(animals[current_index], current_index + 1, animals.size())

## Registra uma tentativa (categoria em que o animal foi solto).
## Respostas sem exercício ativo (antes de começar, ou depois do acerto) são ignoradas.
func submit_answer(category: String) -> void:
	if not _running or not _exercise_active:
		return
	if not Animal.VALID_CATEGORIES.has(category):
		push_warning("submit_answer(): categoria desconhecida '%s'." % category)
		return

	var animal := animals[current_index]
	if category == animal.category:
		# Mede o tempo ANTES de emitir o sinal, para o feedback não entrar na conta.
		_times_msec.append(Time.get_ticks_msec() - _exercise_start_msec)
		_exercise_active = false
		completed_count += 1
		answer_checked.emit(true, "")
	else:
		total_errors += 1
		_errors_by_exercise[current_index] += 1
		answer_checked.emit(false, animal.hint)


## Resumo da fase. Os tempos são guardados sem arredondar.
func get_result() -> Dictionary:
	var exercises: Array[Dictionary] = []
	for i in _times_msec.size():
		exercises.append({
			"id": animals[i].id,
			"name": animals[i].display_name,
			"time_seconds": _times_msec[i] / 1000.0,
			"errors": _errors_by_exercise[i],
		})
	return {
		"total": animals.size(),
		"total_errors": total_errors,
		"exercises": exercises,
	}


func is_running() -> bool:
	return _running


func get_total() -> int:
	return animals.size()


func get_current_animal() -> Animal:
	if current_index < 0 or current_index >= animals.size():
		return null
	return animals[current_index]


func _finish() -> void:
	_running = false
	phase_finished.emit(get_result())
