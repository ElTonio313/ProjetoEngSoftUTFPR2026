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

var _pages: Array = []
var _index: int = 0
var _start_text: String = "Começar o quiz"


func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	next_button.pressed.connect(_on_next_pressed)
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
	_start_text = str(parsed.get("start_text", "Começar o quiz"))
	return true


func _show_page() -> void:
	var page: Dictionary = _pages[_index]
	page_label.text = "Página %d de %d" % [_index + 1, _pages.size()]
	page_title.text = str(page.get("title", ""))
	page_text.text = str(page.get("text", ""))
	_show_media(str(page.get("video_path", "")), str(page.get("image_path", "")))

	back_button.visible = _index > 0
	var is_last := _index == _pages.size() - 1
	next_button.text = _start_text if is_last else "Próxima"
	next_button.grab_focus()   # Enter ou Espaço avançam


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
