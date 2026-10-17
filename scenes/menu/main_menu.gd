extends Control

func _ready() -> void:
	print("nome antes: '", GameState.player_name, "'")
	GameState.player_name = "Teste"
	print("nome depois: '", GameState.player_name, "'")
