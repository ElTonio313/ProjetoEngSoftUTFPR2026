extends Control
## Tela de identificação do aluno com suporte a teclado físico E Teclado Virtual na tela
## (atendendo ao critério "Uso de Teclado virtual" e "Letras em caixa alta" — Jesus, 2019 / ASSARTE).

const MAX_NAME_LENGTH := 20
const BG_PATH := "res://assets/images/bg_pantanal.png"
const AUDIO_PROMPT := "res://assets/audio/narration/player_name/PlayerNameText.ogg"
const AUDIO_ERR_EMPTY := "res://assets/audio/narration/player_name/PlayerNameError.ogg"
const AUDIO_ERR_LETTERS := "res://assets/audio/narration/player_name/PlayerNameLetters.ogg"
const AUDIO_BACK_MENU := "res://assets/audio/narration/player_name/backMenuAudio.ogg"
const AUDIO_CONTINUE := "res://assets/audio/narration/phase2/intro/continueAudio.ogg"
const KEYBOARD_ROWS := [
	["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"],
	["A", "S", "D", "F", "G", "H", "J", "K", "L"],
	["Z", "X", "C", "V", "B", "N", "M"],
]

@onready var name_input: LineEdit = %NameImput
@onready var message_label: Label = %MessageLabel
@onready var virtual_keyboard: VBoxContainer = get_node_or_null("%VirtualKeyboard")
@onready var bg_texture: TextureRect = get_node_or_null("%BgTexture")

var _updating_uppercase: bool = false
var narrator := Narrator.new()


func _ready() -> void:
	if bg_texture != null:
		bg_texture.texture = _load_texture(BG_PATH)
	add_child(narrator)
	var guide_portrait: TextureRect = get_node_or_null("%GuidePortrait")
	if guide_portrait != null:
		guide_portrait.texture = GameState.get_guide_portrait()
	message_label.text = ""
	_build_virtual_keyboard()
	GameState.style_scene(self)
	var confirm_btn: Button = get_node_or_null("%ConfirmButton")
	if confirm_btn != null:
		GameState.style_primary_button(confirm_btn, true)
		confirm_btn.mouse_entered.connect(func() -> void: _hover_say(AUDIO_CONTINUE))
	var back_menu_btn: Button = get_node_or_null("%BackMenuButton")
	if back_menu_btn != null:
		back_menu_btn.mouse_entered.connect(func() -> void: _hover_say(AUDIO_BACK_MENU))
	var speak_btn: Button = get_node_or_null("%SpeakButton")
	if speak_btn != null:
		GameState.style_speak_button(speak_btn)
		speak_btn.pressed.connect(func() -> void: _speak_prompt(true))
	name_input.grab_focus()
	_speak_prompt(false)


func _speak_prompt(force_manual: bool) -> void:
	if not force_manual and not GameState.narration_enabled:
		return
	GameState.stop_speaking()
	var s := Narrator.load_audio(AUDIO_PROMPT)
	if s != null:
		narrator.say(s)
	else:
		GameState.speak("Olá! Eu sou o Guia do Pantanal. Qual é o seu nome? Clique nas letras na tela ou use o teclado, e depois clique em Continuar.", force_manual)


func _hover_say(path: String) -> void:
	if not GameState.narration_enabled:
		return
	var s := Narrator.load_audio(path)
	if s != null:
		narrator.say(s, Narrator.PRIORITY_HOVER)


func _build_virtual_keyboard() -> void:
	if virtual_keyboard == null:
		return
	for child in virtual_keyboard.get_children():
		child.queue_free()

	for row_index in KEYBOARD_ROWS.size():
		var row := HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 8)
		for letter in KEYBOARD_ROWS[row_index]:
			var btn := Button.new()
			btn.text = letter
			btn.custom_minimum_size = Vector2(68, 58)
			btn.focus_mode = Control.FOCUS_NONE
			btn.add_theme_font_size_override("font_size", 28)
			btn.pressed.connect(_on_virtual_key_pressed.bind(letter))
			row.add_child(btn)

		if row_index == KEYBOARD_ROWS.size() - 1:
			var space_btn := Button.new()
			space_btn.text = "ESPAÇO"
			space_btn.custom_minimum_size = Vector2(150, 58)
			space_btn.focus_mode = Control.FOCUS_NONE
			space_btn.add_theme_font_size_override("font_size", 24)
			space_btn.pressed.connect(_on_virtual_key_pressed.bind(" "))
			row.add_child(space_btn)

			var back_btn := Button.new()
			back_btn.text = "APAGAR"
			back_btn.custom_minimum_size = Vector2(165, 58)
			back_btn.focus_mode = Control.FOCUS_NONE
			back_btn.add_theme_font_size_override("font_size", 24)
			back_btn.pressed.connect(_on_virtual_backspace_pressed)
			row.add_child(back_btn)

		virtual_keyboard.add_child(row)


func _on_virtual_key_pressed(ch: String) -> void:
	message_label.text = ""
	if name_input.text.length() >= MAX_NAME_LENGTH:
		message_label.text = GameState.format_text("⚠ Use no máximo %d letras." % MAX_NAME_LENGTH)
		if GameState.narration_enabled:
			var s_max := Narrator.load_audio(AUDIO_ERR_LETTERS)
			if s_max != null:
				narrator.say(s_max)
		return
	name_input.text += ch.to_upper() if GameState.uppercase_mode else ch
	name_input.caret_column = name_input.text.length()


func _on_virtual_backspace_pressed() -> void:
	message_label.text = ""
	if name_input.text.length() > 0:
		name_input.text = name_input.text.left(name_input.text.length() - 1)
		name_input.caret_column = name_input.text.length()


func _on_name_imput_text_changed(new_text: String) -> void:
	if _updating_uppercase:
		return
	message_label.text = ""
	if GameState.uppercase_mode and new_text != new_text.to_upper():
		_updating_uppercase = true
		var col := name_input.caret_column
		name_input.text = new_text.to_upper()
		name_input.caret_column = col
		_updating_uppercase = false


func _validate_name(raw_name: String) -> String:
	var clean_name := raw_name.strip_edges()
	if clean_name.is_empty():
		return GameState.format_text("⚠ Digite seu nome para continuar.")
	if clean_name.length() > MAX_NAME_LENGTH:
		return GameState.format_text("⚠ Use no máximo %d letras." % MAX_NAME_LENGTH)
	return ""


func _confirm_name() -> void:
	var clean_name := name_input.text.strip_edges()
	if clean_name.is_empty():
		message_label.text = GameState.format_text("⚠ Digite seu nome para continuar.")
		if GameState.narration_enabled:
			var s_emp := Narrator.load_audio(AUDIO_ERR_EMPTY)
			if s_emp != null:
				narrator.say(s_emp)
			else:
				GameState.speak("Digite seu nome para continuar.", false)
		return
	if clean_name.length() > MAX_NAME_LENGTH:
		message_label.text = GameState.format_text("⚠ Use no máximo %d letras." % MAX_NAME_LENGTH)
		if GameState.narration_enabled:
			var s_len := Narrator.load_audio(AUDIO_ERR_LETTERS)
			if s_len != null:
				narrator.say(s_len)
		return
	GameState.player_name = clean_name
	GameState.go_to_phase1()


func _on_confirm_button_pressed() -> void:
	_confirm_name()


func _on_back_menu_button_pressed() -> void:
	GameState.go_to_main_menu()


func _on_name_imput_text_submitted(_new_text: String) -> void:
	_confirm_name()


func _load_texture(path: String) -> Texture2D:
	if path == "":
		return null
	var abs_path := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img != null and not img.is_empty():
			return ImageTexture.create_from_image(img)
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	return null
