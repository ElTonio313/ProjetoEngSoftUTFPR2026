extends Control

const BG_PATH := "res://assets/images/bg_pantanal.png"
const AUDIO_TITLE := "res://assets/audio/narration/menu/titleOfficial.ogg"
const AUDIO_PLAY := "res://assets/audio/narration/menu/play.ogg"
const AUDIO_SETTINGS := "res://assets/audio/narration/menu/settings.ogg"
const AUDIO_CREDITS := "res://assets/audio/narration/menu/credits.ogg"
const AUDIO_QUIT := "res://assets/audio/narration/menu/quit.ogg"
const AUDIO_TEACHER := "res://assets/audio/narration/menu/teacher_area.ogg"
const AUDIO_NARRATION_ON := "res://assets/audio/narration/menu/narration_on.ogg"
const AUDIO_CREDITS_TEXT := "res://assets/audio/narration/menu/credits_text.ogg"

@onready var bg_texture: TextureRect = %BgTexture
@onready var play_button: Button = %PlayButton
@onready var settings_button: Button = %SettingsButton
@onready var credits_button: Button = %CreditsButton
@onready var quit_button: Button = %QuitButton
@onready var settings_overlay: Control = %SettingsOverlay
@onready var credits_overlay: Control = %CreditsOverlay
@onready var narration_button: Button = %NarrationButton
@onready var uppercase_button: Button = %UppercaseButton
@onready var close_settings_button: Button = %CloseSettingsButton
@onready var close_credits_button: Button = %CloseCreditsButton

var narrator := Narrator.new()


func _ready() -> void:
	bg_texture.texture = _load_texture(BG_PATH)
	add_child(narrator)
	narration_button.pressed.connect(_on_narration_button_pressed)
	play_button.mouse_entered.connect(func() -> void: _hover_say(AUDIO_PLAY))
	settings_button.mouse_entered.connect(func() -> void: _hover_say(AUDIO_SETTINGS))
	credits_button.mouse_entered.connect(func() -> void: _hover_say(AUDIO_CREDITS))
	quit_button.mouse_entered.connect(func() -> void: _hover_say(AUDIO_QUIT))
	var teacher_btn: Button = get_node_or_null("%TeacherReportButton")
	if teacher_btn != null:
		teacher_btn.mouse_entered.connect(func() -> void: _hover_say(AUDIO_TEACHER))
	_refresh_narration_button()
	_refresh_uppercase_button()
	GameState.style_scene(self)
	GameState.style_speak_button(narration_button, false)
	GameState.style_primary_button(play_button, true)
	GameState.style_primary_button(close_settings_button, true)
	GameState.style_primary_button(close_credits_button, true)
	play_button.grab_focus()
	if GameState.narration_enabled:
		_narrate_menu()


func _narrate_menu() -> void:
	var seq: Array[AudioStream] = []
	for p in [AUDIO_TITLE, AUDIO_PLAY, AUDIO_SETTINGS, AUDIO_CREDITS, AUDIO_QUIT]:
		var s := Narrator.load_audio(p)
		if s != null:
			seq.append(s)
	if not seq.is_empty():
		narrator.say_all(seq)


func _hover_say(path: String) -> void:
	if not GameState.narration_enabled or settings_overlay.visible or credits_overlay.visible:
		return
	var s := Narrator.load_audio(path)
	if s != null:
		narrator.say(s, Narrator.PRIORITY_HOVER)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if settings_overlay.visible:
			_on_close_settings_pressed()
			get_viewport().set_input_as_handled()
		elif credits_overlay.visible:
			_on_close_credits_pressed()
			get_viewport().set_input_as_handled()


func _on_play_button_pressed() -> void:
	GameState.go_to_player_name()


func _on_teacher_report_button_pressed() -> void:
	GameState.go_to_teacher_report()


func _on_settings_button_pressed() -> void:
	narrator.stop()
	_refresh_narration_button()
	_refresh_uppercase_button()
	settings_overlay.show()
	close_settings_button.grab_focus()


func _on_narration_button_pressed() -> void:
	GameState.narration_enabled = not GameState.narration_enabled
	_refresh_narration_button()
	if GameState.narration_enabled:
		var s := Narrator.load_audio(AUDIO_NARRATION_ON)
		if s != null:
			narrator.say(s)
		else:
			GameState.speak("Narração por voz ligada.", true)
	else:
		narrator.stop()
		GameState.stop_speaking()


func _refresh_narration_button() -> void:
	var status := "Ligado" if GameState.narration_enabled else "Desligado"
	narration_button.text = GameState.format_text("Narração por Voz: %s" % status)


func _on_uppercase_button_pressed() -> void:
	GameState.uppercase_mode = not GameState.uppercase_mode
	_refresh_narration_button()
	_refresh_uppercase_button()
	GameState.style_scene(self)


func _refresh_uppercase_button() -> void:
	var status := "LIGADO" if GameState.uppercase_mode else "Desligado"
	uppercase_button.text = GameState.format_text("Letras em Caixa Alta: %s" % status)


func _on_close_settings_pressed() -> void:
	settings_overlay.hide()
	settings_button.grab_focus()


func _on_credits_button_pressed() -> void:
	narrator.stop()
	credits_overlay.show()
	close_credits_button.grab_focus()
	if GameState.narration_enabled:
		var s := Narrator.load_audio(AUDIO_CREDITS_TEXT)
		if s != null:
			narrator.say(s)


func _on_close_credits_pressed() -> void:
	narrator.stop()
	credits_overlay.hide()
	credits_button.grab_focus()


func _on_quit_button_pressed() -> void:
	get_tree().quit()


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
