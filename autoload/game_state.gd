extends Node

#Caminho das Cenas
const SCENE_PLAYER_NAME := "res://scenes/player_name/PlayerName.tscn"

#nome do aluno informado na cena player_name
var player_name: String = ""

func go_to_player_name() -> void:
	get_tree().change_scene_to_file(SCENE_PLAYER_NAME)
