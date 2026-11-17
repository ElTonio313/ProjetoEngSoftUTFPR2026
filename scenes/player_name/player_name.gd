extends Control


const MAX_NAME_LENGTH:= 20

@onready var name_input: LineEdit = %NameImput
@onready var message_label: Label = %MessageLabel

func _ready() -> void:
	message_label.text = ""
	name_input.grab_focus()
	
func _validate_name(raw_name: String) -> String:
	var clean_name := raw_name.strip_edges()
	if clean_name.is_empty():
		return "digite seu nome para continuar."
	if clean_name.length() > MAX_NAME_LENGTH:
		return "use no máximo %d letras." % MAX_NAME_LENGTH
	return ""

func _confirm_name() -> void:
	var error := _validate_name(name_input.text)
	if error != "":
		message_label.text = error
		return
	GameState.player_name = name_input.text.strip_edges()
	GameState.go_to_phase1()

func _on_confirm_button_pressed() -> void:
	_confirm_name()


func _on_name_imput_text_submitted(new_text: String) -> void:
	_confirm_name()
