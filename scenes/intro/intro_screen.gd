extends Control
## Tela de introdução da Fase 1: explica, em poucas páginas, o assunto das perguntas.
## Só cuida da interface. Os textos ficam em res://data/intro.json (cada página pode ter
## video_path e image_path; se o arquivo não existir, a mídia simplesmente não aparece).
## "Começar o quiz" abre o quiz.

const DATA_PATH := "res://data/intro.json"
const NEXT_SCENE := "res://scenes/quiz/QuizScreen.tscn"

@onready var title_label: Label = %TitleLabel
@onready var page_label: Label = %PageLabel
@onready var page_title: Label = %PageTitle
@onready var page_text: Label = %PageText
@onready var media_box: Control = %MediaBox
@onready var video: VideoStreamPlayer = %Video
@onready var picture: TextureRect = %Picture
@onready var back_button: Button = %BackButton
@onready var next_button: Button = %NextButton

const BACK_AUDIO := "res://assets/audio/narration/intro_phase1/backAudio.ogg"        # "Voltar"
const CONTINUE_AUDIO := "res://assets/audio/narration/phase2/intro/continueAudio.ogg"  # "Continuar"
var narrator := Narrator.new()
var _title_audio_path: String = ""
var _pages: Array = []
var _index: int = 0
var _start_text: String = "Continuar"


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	next_button.pressed.connect(_on_next_pressed)
	add_child(narrator)
	back_button.mouse_entered.connect(_on_back_hover)
	next_button.mouse_entered.connect(_on_next_hover)
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
	title_label.text = str(parsed.get("title", "Antes de começar"))
	_start_text = str(parsed.get("start_text", "Continuar"))
	_title_audio_path = str(parsed.get("title_audio", ""))
	return true


func _show_page() -> void:
	var page: Dictionary = _pages[_index]
	page_label.text = "Página %d de %d" % [_index + 1, _pages.size()]
	page_title.text = str(page.get("title", ""))
	page_text.text = str(page.get("text", ""))
	_show_media(str(page.get("video_path", "")), str(page.get("image_path", "")))

	back_button.visible = _index > 0
	var is_last := _index == _pages.size() - 1
	next_button.text = _start_text if is_last else "Continuar"
	next_button.grab_focus()   # Enter ou Espaço avançam
	
	var parts: Array[AudioStream] = []
	if _index == 0 and _title_audio_path != "":
		parts.append(Narrator.load_audio(_title_audio_path))   # o título só na primeira página
	var page_audio := str(page.get("audio_path", ""))
	if page_audio != "":
		parts.append(Narrator.load_audio(page_audio))
	narrator.say_all(parts)


func _show_media(video_path: String, image_path: String) -> void:
	video.stop()
	video.stream = null
	picture.texture = null
	video.hide()
	picture.hide()
	if video_path != "" and ResourceLoader.exists(video_path):
		video.stream = load(video_path)
		video.show()
		video.play()
	elif image_path != "" and ResourceLoader.exists(image_path):
		picture.texture = load(image_path)
		picture.show()
	media_box.visible = video.visible or picture.visible   # sem mídia, o texto ocupa a tela


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
	get_tree().change_scene_to_file(NEXT_SCENE)

func _on_back_hover() -> void:
	narrator.say(Narrator.load_audio(BACK_AUDIO), Narrator.PRIORITY_HOVER)


# Na última página o botão diz "Começar o quiz" (sem áudio), então só vale nas outras.
func _on_next_hover() -> void:
	if _index < _pages.size() - 1:
		narrator.say(Narrator.load_audio(CONTINUE_AUDIO), Narrator.PRIORITY_HOVER)
