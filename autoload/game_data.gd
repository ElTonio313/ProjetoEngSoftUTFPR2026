extends Node
## Autoload "GameData": guarda os resultados do jogo entre as telas e salva em
## arquivo, para a Fase 2 e a seção de Relatório lerem depois.
## (Cadastre em Project > Project Settings > Globals > Autoload, com o nome GameData.)
##
## Observação: ao carregar do arquivo, números voltam como float (3.0).
## No front-end, use int(valor) antes de mostrar na tela.

signal data_changed

const SAVE_PATH := "user://game_data.json"

## Resultado da Fase 1. Formato:
## { hits, misses, total, percent, time_seconds, by_category: { fauna: {hits, total}, ... } }
var phase1_result: Dictionary = {}

## Resultado da Fase 2: formato livre, combinado com o colega responsável.
var phase2_result: Dictionary = {}


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


## Apaga todos os resultados (por exemplo, botão "Jogar de novo" ou "Limpar relatório").
func reset() -> void:
	phase1_result = {}
	phase2_result = {}
	save_data()
	data_changed.emit()


func save_data() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Não foi possível salvar em %s (erro %d)." % [SAVE_PATH, FileAccess.get_open_error()])
		return false
	var data := {
		"phase1_result": phase1_result,
		"phase2_result": phase2_result,
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
	phase1_result = parsed.get("phase1_result", {})
	phase2_result = parsed.get("phase2_result", {})
	data_changed.emit()
	return true
