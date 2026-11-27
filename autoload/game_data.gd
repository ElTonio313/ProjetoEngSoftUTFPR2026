extends Node
## Autoload "GameData": guarda os resultados do jogo entre as telas e salva em
## arquivo, para a Fase 2 e os Relatórios (Aluno e Professor) lerem depois.
##
## Observação: ao carregar do arquivo, números voltam como float (3.0).
## No front-end, use int(valor) antes de mostrar na tela.

signal data_changed

const SAVE_PATH := "user://game_data.json"

## Nome do aluno e tempo total da última sessão concluída.
var last_player_name: String = ""
var last_total_seconds: float = 0.0

## Resultado da Fase 1. Formato:
## { hits, misses, total, percent, hints_used, time_seconds, by_category: { fauna: {hits, total}, ... } }
var phase1_result: Dictionary = {}

## Resultado da Fase 2. Formato:
## { total, total_errors, exercises: [ {id, name, time_seconds, errors}, ... ] }
var phase2_result: Dictionary = {}

## Histórico de sessões concluídas para o Relatório do Professor.
var history: Array = []


func _ready() -> void:
	load_data()


func set_phase1_result(result: Dictionary) -> void:
	phase1_result = result
	save_data()
	data_changed.emit()


func set_phase2_result(result: Dictionary) -> void:
	phase2_result = result
	save_data()
	data_changed.emit()


func has_phase1_result() -> bool:
	return not phase1_result.is_empty()


func has_phase2_result() -> bool:
	return not phase2_result.is_empty()


## Registra a conclusão da atividade completa (Fase 1 + Fase 2) no histórico do professor.
func record_completed_session(student_name: String, total_seconds: float) -> void:
	last_player_name = student_name
	last_total_seconds = total_seconds
	var entry := {
		"player_name": student_name if student_name != "" else "Aluno",
		"timestamp": Time.get_datetime_string_from_system(false, true),
		"total_seconds": snappedf(total_seconds, 0.1),
		"phase1_result": phase1_result.duplicate(true),
		"phase2_result": phase2_result.duplicate(true),
	}
	history.append(entry)
	save_data()
	data_changed.emit()


## Apaga os resultados da sessão atual (ao iniciar nova partida), preservando o histórico do professor.
func reset() -> void:
	phase1_result = {}
	phase2_result = {}
	last_player_name = ""
	last_total_seconds = 0.0
	save_data()
	data_changed.emit()


## Apaga o histórico completo do Relatório do Professor.
func clear_history() -> void:
	history.clear()
	save_data()
	data_changed.emit()


func save_data() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Não foi possível salvar em %s (erro %d)." % [SAVE_PATH, FileAccess.get_open_error()])
		return false
	var data := {
		"last_player_name": last_player_name,
		"last_total_seconds": last_total_seconds,
		"phase1_result": phase1_result,
		"phase2_result": phase2_result,
		"history": history,
	}
	file.store_string(JSON.stringify(data, "\t"))
	return true


func load_data() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Arquivo de save corrompido; começando do zero.")
		return false
	last_player_name = str(parsed.get("last_player_name", ""))
	last_total_seconds = float(parsed.get("last_total_seconds", 0.0))
	phase1_result = parsed.get("phase1_result", {})
	phase2_result = parsed.get("phase2_result", {})
	var raw_history = parsed.get("history", [])
	if typeof(raw_history) == TYPE_ARRAY:
		history = raw_history
	else:
		history = []
	data_changed.emit()
	return true
