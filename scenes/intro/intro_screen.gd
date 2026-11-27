extends Control
## Tela de introdução da Fase 1: explica, em poucas páginas, o assunto das perguntas.
## Só cuida da interface. Os textos ficam em res://data/intro.json (cada página pode ter
## video_path e image_path; se o arquivo não existir, a mídia simplesmente não aparece).
## "Começar o quiz" abre o quiz.

const DATA_PATH := "res://data/intro.json"
const NEXT_SCENE := "res://scenes/quiz/QuizScreen.tscn"
const BG_PATH := "res://assets/images/bg_pantanal.png"
const BACK_AUDIO := "res://assets/audio/narration/intro_phase1/backAudio.ogg"
const CONTINUE_AUDIO := "res://assets/audio/narration/phase2/intro/continueAudio.ogg"
const START_QUIZ_AUDIO := "res://assets/audio/narration/intro_phase1/startQuizAudio.ogg"
const MENU_AUDIO := "res://assets/audio/narration/intro_phase1/menuAudio.ogg"

@onready var title_label: Label = %TitleLabel
@onready var page_label: Label = %PageLabel
@onready var page_title: Label = %PageTitle
@onready var page_text: Label = %PageText
@onready var media_box: Control = %MediaBox
@onready var video: VideoStreamPlayer = %Video
@onready var picture: TextureRect = %Picture
@onready var back_button: Button = %BackButton
@onready var next_button: Button = %NextButton
@onready var bg_texture: TextureRect = get_node_or_null("%BgTexture")

var _pages: Array = []
var _index: int = 0
var _start_text: String = "Começar o quiz"
var _title_audio_path: String = ""
var narrator := Narrator.new()


func _ready() -> void:
	if bg_texture != null:
		bg_texture.texture = _load_texture(BG_PATH)
	add_child(narrator)
	var guide_portrait: TextureRect = get_node_or_null("%GuidePortrait")
	if guide_portrait != null:
		guide_portrait.texture = GameState.get_guide_portrait()
	back_button.pressed.connect(_on_back_pressed)
	next_button.pressed.connect(_on_next_pressed)
	back_button.mouse_entered.connect(_on_back_hover)
	next_button.mouse_entered.connect(_on_next_hover)
	var menu_btn: Button = get_node_or_null("%MenuButton")
	if menu_btn != null:
		GameState.style_compact_button(menu_btn)
		menu_btn.mouse_entered.connect(func() -> void:
			if GameState.narration_enabled:
				var ms := Narrator.load_audio(MENU_AUDIO)
				if ms != null:
					narrator.say(ms, Narrator.PRIORITY_HOVER)
		)
		menu_btn.pressed.connect(func() -> void:
			narrator.stop()
			GameState.reset_session()
			GameState.go_to_main_menu()
		)
	var speak_btn: Button = get_node_or_null("%SpeakButton")
	if speak_btn != null:
		GameState.style_speak_button(speak_btn)
		speak_btn.pressed.connect(func() -> void: _speak_current_page(true))
	video.finished.connect(_on_video_finished)
	GameState.style_scene(self)
	GameState.style_primary_button(next_button, true)
	if not _load_data():
		# Sem o arquivo de textos, não trava o jogo: vai direto para o quiz.
		push_warning("Introdução não encontrada em %s; indo direto ao quiz." % DATA_PATH)
		_go_to_quiz.call_deferred()
		return
	_show_page()


func _load_data() -> bool:
	if not FileAccess.file_exists(DATA_PATH):
		return false
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("pages") or parsed["pages"].is_empty():
		return false
	_pages = parsed["pages"]
	title_label.text = GameState.format_text(str(parsed.get("title", "Antes de começar")))
	_start_text = str(parsed.get("start_text", "Começar o quiz"))
	_title_audio_path = str(parsed.get("title_audio", ""))
	return true


func _show_page() -> void:
	var page: Dictionary = _pages[_index]
	page_label.text = GameState.format_text("Página %d de %d" % [_index + 1, _pages.size()])
	page_title.text = GameState.format_text(str(page.get("title", "")))
	page_text.text = GameState.format_text(str(page.get("text", "")))
	_show_media(str(page.get("video_path", "")), str(page.get("image_path", "")))

	back_button.visible = _index > 0
	var is_last := _index == _pages.size() - 1
	next_button.text = GameState.format_text(_start_text if is_last else "Próxima")
	next_button.grab_focus()   # Enter ou Espaço avançam
	_speak_current_page(false)


func _speak_current_page(force_manual: bool) -> void:
	if not force_manual and not GameState.narration_enabled:
		return
	if _pages.is_empty() or _index < 0 or _index >= _pages.size():
		return
	GameState.stop_speaking()
	var page: Dictionary = _pages[_index]
	var parts: Array[AudioStream] = []
	if _index == 0 and not force_manual and _title_audio_path != "":
		var t_stream := Narrator.load_audio(_title_audio_path)
		if t_stream != null:
			parts.append(t_stream)
	var page_audio := str(page.get("audio_path", ""))
	if page_audio != "":
		var p_stream := Narrator.load_audio(page_audio)
		if p_stream != null:
			parts.append(p_stream)
	if not parts.is_empty():
		narrator.say_all(parts)
	else:
		var speech := "%s. %s" % [str(page.get("title", "")), str(page.get("text", ""))]
		GameState.speak(speech, force_manual)


func _on_back_hover() -> void:
	if GameState.narration_enabled:
		var s := Narrator.load_audio(BACK_AUDIO)
		if s != null:
			narrator.say(s, Narrator.PRIORITY_HOVER)


func _on_next_hover() -> void:
	if not GameState.narration_enabled:
		return
	var target_audio := START_QUIZ_AUDIO if _index >= _pages.size() - 1 else CONTINUE_AUDIO
	var s := Narrator.load_audio(target_audio)
	if s != null:
		narrator.say(s, Narrator.PRIORITY_HOVER)


func _show_media(video_path: String, image_path: String) -> void:
	video.stop()
	video.stream = null
	picture.texture = null
	video.hide()
	picture.hide()
	if video_path != "" and ResourceLoader.exists(video_path):
		var stream = load(video_path)
		if stream != null:
			video.stream = stream
			video.show()
			video.play()
	if not video.visible and image_path != "":
		var tex := _load_texture(image_path)
		if tex != null:
			picture.texture = tex
			picture.show()
	media_box.visible = video.visible or picture.visible   # sem mídia, o texto ocupa a tela
	if media_box.visible:
		media_box.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(media_box, "modulate:a", 1.0, 0.22)


func _on_video_finished() -> void:
	if video.visible and video.stream != null:
		video.play()


func _on_back_pressed() -> void:
	_index = maxi(_index - 1, 0)
	_show_page()


func _on_next_pressed() -> void:
	if _index >= _pages.size() - 1:
		_go_to_quiz()
	else:
		_index += 1
		_show_page()


func _go_to_quiz() -> void:
	narrator.stop()
	GameState.stop_speaking()
	get_tree().change_scene_to_file(NEXT_SCENE)


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
