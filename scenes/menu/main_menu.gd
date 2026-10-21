extends Control

#muda para a cena de informar o nome
func _on_play_button_pressed() -> void:
	GameState.go_to_player_name()
	



func _on_quit_button_pressed() -> void:
	get_tree().quit()
