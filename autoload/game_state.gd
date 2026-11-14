extends Node

#Caminho das Cenas
const SCENE_MAIN_MENU := "res://scenes/menu/MainMenu.tscn"                      
const SCENE_PLAYER_NAME := "res://scenes/player_name/PlayerName.tscn"
const SCENE_PHASE1 := "res://scenes/quiz/QuizScreen.tscn"
const SCENE_PHASE2 := "res://scenes/phase2/Phase2.tscn"
const SCENE_FINAL_REPORT := "res://scenes/final_reports/FinalReport.tscn"        

#nome do aluno informado na cena player_name
var player_name: String = ""

# relógio da atividade. -1 = ainda não marcado.
var _activity_start_msec: int = -1
var _activity_end_msec: int = -1


func go_to_main_menu() -> void:                                                 
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)

func go_to_player_name() -> void:
	get_tree().change_scene_to_file(SCENE_PLAYER_NAME)

func go_to_phase1() -> void:
	start_activity()                                                            
	get_tree().change_scene_to_file(SCENE_PHASE1)

func go_to_phase2() -> void:
	get_tree().change_scene_to_file(SCENE_PHASE2)

func go_to_final_report() -> void:                                              
	get_tree().change_scene_to_file(SCENE_FINAL_REPORT)


# marca o início da atividade (chamado por go_to_phase1).
func start_activity() -> void:
	_activity_start_msec = Time.get_ticks_msec()
	_activity_end_msec = -1


# marca o fim da atividade (a Fase 2 chamará ao concluir).
# Ignora se a atividade não começou ou se o fim já foi marcado.
func finish_activity() -> void:
	if _activity_start_msec < 0 or _activity_end_msec >= 0:
		return
	_activity_end_msec = Time.get_ticks_msec()


# só há tempo total se a atividade começou E terminou.
func has_total_time() -> bool:
	return _activity_start_msec >= 0 and _activity_end_msec >= 0


#duração total em segundos. Confira has_total_time() antes.
func get_total_seconds() -> float:
	if not has_total_time():
		return 0.0
	return (_activity_end_msec - _activity_start_msec) / 1000.0
