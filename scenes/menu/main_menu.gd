extends Control

# Ordem da narração.
@export var title_audio: AudioStream
@export var play_audio: AudioStream
@export var credits_audio: AudioStream
@export var quit_audio: AudioStream

var narrator := Narrator.new()

func _ready() -> void:
	add_child(narrator)
	_narrate_menu()

# toca um de cada vez e na ordem
func _narrate_menu() -> void:
	var sequence: Array[AudioStream] = [title_audio, play_audio, credits_audio, quit_audio]
	for audio: AudioStream in sequence:
		var completed: bool = await narrator.say(audio)
		if not completed:
			return

#muda para a cena de informar o nome
func _on_play_button_pressed() -> void:
	GameState.go_to_player_name()


func _on_quit_button_pressed() -> void:
	get_tree().quit()
