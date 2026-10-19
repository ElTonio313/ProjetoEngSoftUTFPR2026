extends Node

#Caminho das Cenas
const SCENE_PLAYER_NAME := "res://scenes/player_name/PlayerName.tscn"
const SCENE_PHASE1 := "res://scenes/quiz/QuizScreen.tscn"
const SCENE_PHASE2 := "res://scenes/phase2/Phase2.tscn"

#nome do aluno informado na cena player_name
var player_name: String = ""

func go_to_player_name() -> void:
	get_tree().change_scene_to_file(SCENE_PLAYER_NAME)

func go_to_phase1() -> void:
	get_tree().change_scene_to_file(SCENE_PHASE1)

func go_to_phase2() -> void:
	get_tree().change_scene_to_file(SCENE_PHASE2)
