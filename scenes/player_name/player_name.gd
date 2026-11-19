extends Control


const MAX_NAME_LENGTH:= 20

@onready var name_input: LineEdit = %NameImput
@onready var message_label: Label = %MessageLabel
@export var prompt_audio: AudioStream
@export var error_empty_audio: AudioStream
@export var error_letters_audio: AudioStream

var narrator := Narrator.new() 

func _ready() -> void:
	message_label.text = ""
	name_input.grab_focus()
	add_child(narrator)
	narrator.say(prompt_audio)
	
func _confirm_name() -> void:
	var clean_name := name_input.text.strip_edges()
	if clean_name.is_empty():
		_show_error("digite seu nome para continuar.", error_empty_audio)
		return
	if clean_name.length() > MAX_NAME_LENGTH:
		_show_error("use no máximo %d letras." % MAX_NAME_LENGTH, error_letters_audio)
		return
	GameState.player_name = clean_name
	GameState.go_to_phase1()


func _show_error(text: String, audio: AudioStream) -> void:
	message_label.text = text   # o texto muda...
	narrator.say(audio)         # ...e a voz diz o mesmo texto
func _on_confirm_button_pressed() -> void:
	_confirm_name()


func _on_name_imput_text_submitted(new_text: String) -> void:
		_confirm_name()
