extends Control
## Tela da Fase 1 (quiz do Pantanal).
## Só cuida da interface: toda a lógica está no QuizManager.

const SOUND_RIGHT := "res://assets/sounds/correct.wav"
const SOUND_WRONG := "res://assets/sounds/wrong.wav"
const AUDIO_ABOUT_BTN := "res://assets/audio/narration/phase1/aboutAudio.ogg"
const AUDIO_ABOUT_TEXT := "res://assets/audio/narration/phase1/aboutTextAudio.ogg"
const AUDIO_HINT_BTN := "res://assets/audio/narration/phase1/hintAudioB.ogg"
const AUDIO_NEXT_BTN := "res://assets/audio/narration/phase1/nextQuestionAudio.ogg"
const AUDIO_RESTART_BTN := "res://assets/audio/narration/phase1/restartAudio.ogg"
const AUDIO_MENU_BTN := "res://assets/audio/narration/intro_phase1/menuAudio.ogg"
const AUDIO_RIGHT_VOICE := "res://assets/sounds/correctAudio.ogg"
const AUDIO_WRONG_VOICE := "res://assets/sounds/wrongAudio.ogg"
const BG_PATH := "res://assets/images/bg_pantanal.png"
const COLOR_TEXT := Color(0.0941176, 0.14902, 0.105882)
const COLOR_RIGHT := Color(0.1, 0.5, 0.2)
const COLOR_WRONG := Color(0.6901961, 0, 0.1254902)  # mesmo vermelho da tela de nome
const COLOR_HINT := Color(0.05, 0.25, 0.55)
const CATEGORY_NAMES := {
	"fauna": "Fauna",
	"flora": "Flora",
	"conservacao": "Conservação",
}
const PHASE1_REWARD_ITEMS := [
	{"label": "Tuiuiú", "path": "res://assets/images/tuiuiu.png"},
	{"label": "Onça-pintada", "path": "res://assets/images/onca.png"},
	{"label": "Tamanduá", "path": "res://assets/images/tamandua.png"},
	{"label": "Aguapé", "path": "res://assets/images/aguape.png"},
	{"label": "Pantanal Vivo", "path": "res://assets/images/proteger.png"},
]

@onready var progress_label: Label = %ProgressLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var question_label: Label = %QuestionLabel
@onready var options_grid: GridContainer = %OptionsGrid
@onready var result_label: Label = %ResultLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var hint_button: Button = %HintButton
@onready var next_button: Button = %NextButton
@onready var restart_button: Button = %RestartButton
@onready var about_button: Button = %AboutButton
@onready var about_overlay: Control = %AboutOverlay
@onready var close_about_button: Button = %CloseAboutButton
@onready var bg_texture: TextureRect = get_node_or_null("%BgTexture")
@onready var media_box: Control = get_node_or_null("%MediaBox")
@onready var question_video: VideoStreamPlayer = get_node_or_null("%QuestionVideo")
@onready var question_image: TextureRect = get_node_or_null("%QuestionImage")
@onready var reward_box: VBoxContainer = get_node_or_null("%RewardBox")

var quiz := QuizManager.new()
var narrator := Narrator.new()
var _question: Question = null
var _finished: bool = false
var _sfx_right: AudioStreamPlayer
var _sfx_wrong: AudioStreamPlayer
var _icon_right: ImageTexture   # símbolo de certo (✓) desenhado por código
var _icon_wrong: ImageTexture   # símbolo de errado (✗) desenhado por código
var _current_speech: String = ""
var _current_streams: Array[AudioStream] = []
const ABOUT_SPEECH := "Como funciona a Fase 1. Nesta etapa você responde a 5 perguntas sobre os animais, as plantas e a conservação do Pantanal brasileiro. Observe a imagem, ouça ou leia a pergunta e escolha uma das duas opções. Se precisar de ajuda, clique no botão Dica. Ao acertar, você conhece mais sobre a espécie e avança."


func _ready() -> void:
	if bg_texture != null:
		bg_texture.texture = _load_texture(BG_PATH)
	var guide_portrait: TextureRect = get_node_or_null("%GuidePortrait")
	if guide_portrait != null:
		guide_portrait.texture = GameState.get_guide_portrait()
	if question_video != null:
		question_video.finished.connect(_on_question_video_finished)

	add_child(quiz)
	add_child(narrator)
	_sfx_right = _make_sfx(SOUND_RIGHT)
	_sfx_wrong = _make_sfx(SOUND_WRONG)
	_icon_right = _make_symbol(true)
	_icon_wrong = _make_symbol(false)

	quiz.question_ready.connect(_on_question_ready)
	quiz.wrong_answer.connect(_on_wrong_answer)
	quiz.hint_shown.connect(_on_hint_shown)
	quiz.answer_checked.connect(_on_answer_checked)
	quiz.quiz_finished.connect(_on_quiz_finished)

	hint_button.pressed.connect(quiz.use_hint)
	hint_button.mouse_entered.connect(func() -> void: _hover_say(AUDIO_HINT_BTN))
	next_button.pressed.connect(_on_next_pressed)
	next_button.mouse_entered.connect(func() -> void: _hover_say(AUDIO_NEXT_BTN))
	restart_button.pressed.connect(_on_restart_pressed)
	restart_button.mouse_entered.connect(func() -> void: _hover_say(AUDIO_RESTART_BTN))
	about_button.pressed.connect(_open_about)
	about_button.mouse_entered.connect(func() -> void: _hover_say(AUDIO_ABOUT_BTN))
	close_about_button.pressed.connect(_close_about)
	GameState.style_compact_button(about_button)
	var menu_btn: Button = get_node_or_null("%MenuButton")
	if menu_btn != null:
		GameState.style_compact_button(menu_btn)
		menu_btn.mouse_entered.connect(func() -> void: _hover_say(AUDIO_MENU_BTN))
		menu_btn.pressed.connect(func() -> void:
			narrator.stop()
			GameState.reset_session()
			GameState.go_to_main_menu()
		)
	var speak_btn: Button = get_node_or_null("%SpeakButton")
	if speak_btn != null:
		GameState.style_speak_button(speak_btn)
		speak_btn.pressed.connect(func() -> void: _on_speak_pressed())
	var about_speak_btn: Button = get_node_or_null("%AboutSpeakButton")
	if about_speak_btn != null:
		GameState.style_speak_button(about_speak_btn, false)
		about_speak_btn.pressed.connect(func() -> void: _play_about_audio(true))
	GameState.style_scene(self)
	GameState.style_primary_button(next_button, true)
	GameState.style_primary_button(close_about_button, true)
	_start()


func _unhandled_input(event: InputEvent) -> void:
	if about_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_about()
		get_viewport().set_input_as_handled()


func _on_restart_pressed() -> void:
	GameState.start_activity()
	_start()


func _start() -> void:
	_finished = false
	if not quiz.start_quiz():
		_clear_options()
		_hide_media()
		progress_label.text = ""
		question_label.text = GameState.format_text("Não foi possível carregar as perguntas.")
		result_label.text = ""
		feedback_label.text = ""
		hint_button.hide()
		next_button.hide()
		restart_button.hide()


# ---------------------------------------------------------------- Sobre

func _open_about() -> void:
	about_overlay.show()
	close_about_button.grab_focus()
	_play_about_audio(false)


func _close_about() -> void:
	narrator.stop()
	GameState.stop_speaking()
	about_overlay.hide()
	about_button.grab_focus()


func _play_about_audio(force_manual: bool) -> void:
	if not force_manual and not GameState.narration_enabled:
		return
	GameState.stop_speaking()
	var s := Narrator.load_audio(AUDIO_ABOUT_TEXT)
	if s != null:
		narrator.say(s)
	else:
		GameState.speak(ABOUT_SPEECH, force_manual)


func _on_speak_pressed() -> void:
	if about_overlay.visible:
		_play_about_audio(true)
	elif not _current_streams.is_empty():
		GameState.stop_speaking()
		narrator.say_all(_current_streams)
	elif _current_speech != "":
		narrator.stop()
		GameState.speak(_current_speech, true)


func _hover_say(path: String) -> void:
	if not GameState.narration_enabled or about_overlay.visible:
		return
	var s := Narrator.load_audio(path)
	if s != null:
		narrator.say(s, Narrator.PRIORITY_HOVER)


func _on_option_hover(index: int) -> void:
	if not GameState.narration_enabled or about_overlay.visible or _question == null:
		return
	if index >= 0 and index < _question.options.size():
		var s := Narrator.load_audio(QuizAudio.option_path(_question, _question.options[index]))
		if s != null:
			narrator.say(s, Narrator.PRIORITY_HOVER)


func _narrate_streams_or_tts(streams: Array[AudioStream], fallback_text: String) -> void:
	_current_streams = streams
	_current_speech = fallback_text
	if not GameState.narration_enabled:
		return
	GameState.stop_speaking()
	if not streams.is_empty():
		narrator.say_all(streams)
	else:
		GameState.speak(fallback_text, false)


# ------------------------------------------------------- Sinais do quiz

func _on_question_ready(question: Question, number: int, total: int) -> void:
	_question = question
	if reward_box != null:
		reward_box.hide()
	question_label.show()
	progress_label.text = GameState.format_text("Pergunta %d de %d" % [number, total])
	progress_bar.max_value = total
	progress_bar.value = number - 1
	question_label.text = GameState.format_text(question.text)
	result_label.text = GameState.format_text("Guia do Pantanal")
	result_label.add_theme_color_override("font_color", COLOR_RIGHT)
	_set_feedback("Observe a imagem e escolha uma opção. Se precisar de ajuda, clique em Dica!", COLOR_TEXT)
	_show_question_media(question.video_path, question.image_path)

	hint_button.visible = question.hint != ""   # sem dica cadastrada, o botão não aparece
	hint_button.disabled = false
	next_button.hide()
	restart_button.hide()

	_clear_options()
	var streams: Array[AudioStream] = []
	var q_stream := Narrator.load_audio(QuizAudio.question_path(question))
	if q_stream != null:
		streams.append(q_stream)

	for i in question.options.size():
		var button := Button.new()
		button.text = GameState.format_text(question.options[i])
		button.custom_minimum_size = Vector2(340, 68)
		button.add_theme_font_size_override("font_size", 32)
		button.pressed.connect(_on_option_pressed.bind(i))
		button.mouse_entered.connect(_on_option_hover.bind(i))
		options_grid.add_child(button)
		GameState.setup_button_animation(button)
		var opt_stream := Narrator.load_audio(QuizAudio.option_path(question, question.options[i]))
		if opt_stream != null:
			streams.append(opt_stream)

	if options_grid.get_child_count() > 0:
		(options_grid.get_child(0) as Button).grab_focus()

	var opts_str := " ou ".join(question.options)
	_narrate_streams_or_tts(streams, "Pergunta %d de %d. %s Opções: %s." % [number, total, question.text, opts_str])


func _on_option_pressed(index: int) -> void:
	quiz.answer(index)


## Errou: pinta e trava só essa alternativa, mostra a dica e deixa tentar de novo.
func _on_wrong_answer(wrong_index: int, hint: String) -> void:
	_paint_button(options_grid.get_child(wrong_index) as Button, COLOR_WRONG, _icon_wrong)
	result_label.text = GameState.format_text("Não foi dessa vez. Tente de novo.")
	result_label.add_theme_color_override("font_color", COLOR_WRONG)
	var streams: Array[AudioStream] = []
	var w_voice := Narrator.load_audio(AUDIO_WRONG_VOICE)
	if w_voice != null:
		streams.append(w_voice)
	if hint != "":
		_display_hint(hint)
		if _question != null:
			var h_stream := Narrator.load_audio(QuizAudio.hint_path(_question))
			if h_stream != null:
				streams.append(h_stream)
		_narrate_streams_or_tts(streams, "Não foi dessa vez. Tente de novo! Dica: %s" % hint)
	else:
		_narrate_streams_or_tts(streams, "Não foi dessa vez. Tente de novo!")
	_play(_sfx_wrong)


func _display_hint(hint: String) -> void:
	_set_feedback("Dica do Guia: %s" % hint, COLOR_HINT)
	hint_button.hide()


func _on_hint_shown(hint: String) -> void:
	result_label.text = GameState.format_text("Guia do Pantanal — Dica")
	result_label.add_theme_color_override("font_color", COLOR_HINT)
	_display_hint(hint)
	var streams: Array[AudioStream] = []
	if _question != null:
		var h_stream := Narrator.load_audio(QuizAudio.hint_path(_question))
		if h_stream != null:
			streams.append(h_stream)
	_narrate_streams_or_tts(streams, "Dica do Guia: %s" % hint)


## Acertou: trava tudo, mostra a explicação e o botão "Próxima".
func _on_answer_checked(first_try: bool, correct_index: int, feedback: String) -> void:
	for button in options_grid.get_children():
		(button as Button).disabled = true
	_paint_button(options_grid.get_child(correct_index) as Button, COLOR_RIGHT, _icon_right)

	var praise := "Acertou! Muito bem!" if first_try else "Agora você acertou!"
	result_label.text = GameState.format_text(praise)
	result_label.add_theme_color_override("font_color", COLOR_RIGHT)
	_set_feedback(feedback, COLOR_TEXT)
	_play(_sfx_right)

	var streams: Array[AudioStream] = []
	var r_voice := Narrator.load_audio(AUDIO_RIGHT_VOICE)
	if r_voice != null:
		streams.append(r_voice)
	if _question != null:
		var fb_stream := Narrator.load_audio(QuizAudio.feedback_path(_question))
		if fb_stream != null:
			streams.append(fb_stream)
	_narrate_streams_or_tts(streams, "%s %s" % [praise, feedback])

	hint_button.hide()
	progress_bar.value = quiz.current_index + 1
	var is_last := quiz.current_index + 1 >= quiz.get_total()
	next_button.text = GameState.format_text("Ver resultado" if is_last else "Próxima")
	next_button.show()
	next_button.grab_focus()   # Enter ou Espaço avançam


func _on_next_pressed() -> void:
	if _finished:
		_leave_phase()
	else:
		quiz.next_question()


func _leave_phase() -> void:
	narrator.stop()
	if GameState.has_method("go_to_phase2"):
		GameState.go_to_phase2()
	else:
		push_warning("GameState.go_to_phase2() ainda não existe: ligação com a Fase 2 pendente.")


func _on_quiz_finished(result: Dictionary) -> void:
	_finished = true
	narrator.stop()
	_current_streams.clear()
	_clear_options()
	_hide_media()
	hint_button.hide()
	progress_label.text = GameState.format_text("Fase 1 concluída")
	progress_bar.value = progress_bar.max_value

	var player_name: String = GameState.player_name
	var hits := int(result["hits"])
	var total := int(result["total"])
	var stars := GameState.calc_phase1_stars(result)

	question_label.hide()
	_populate_phase1_rewards(hits, total, stars)

	result_label.text = GameState.format_text("Parabéns, %s!" % player_name if player_name != "" else "Parabéns!")
	result_label.add_theme_color_override("font_color", COLOR_RIGHT)

	var lines: Array[String] = []
	for category in result["by_category"]:
		var data: Dictionary = result["by_category"][category]
		var nice_name: String = CATEGORY_NAMES.get(category, str(category).capitalize())
		lines.append("%s: %d/%d" % [nice_name, int(data["hits"]), int(data["total"])])
	_set_feedback("  •  ".join(lines) + "  —  Avance para a Fase 2!", COLOR_TEXT)

	next_button.text = GameState.format_text("Continuar")
	next_button.show()
	restart_button.show()
	next_button.grab_focus()
	var spoken_name := GameState.format_name_for_speech(player_name)
	var who := (", " + spoken_name) if spoken_name != "" else ""
	var star_word := "estrela" if stars == 1 else "estrelas"
	var finish_fb := "Parabéns%s! Fase 1 concluída! Você conquistou %d %s e desbloqueou a medalha Explorador da Flora e Fauna! Clique em Continuar para ir à Fase 2." % [
		who, stars, star_word
	]
	var fin_audio := Narrator.load_audio("res://assets/audio/narration/phase1/finish_stars_%d.ogg" % clampi(stars, 1, 3))
	var fin_streams: Array[AudioStream] = []
	if fin_audio != null:
		fin_streams.append(fin_audio)
	_narrate_streams_or_tts(fin_streams, finish_fb)


func _populate_phase1_rewards(hits: int, total: int, stars: int) -> void:
	if reward_box == null:
		return
	for ch in reward_box.get_children():
		ch.queue_free()

	# 1) Faixa de Medalha + Estrelas Douradas
	var medal_panel := PanelContainer.new()
	var mst := StyleBoxFlat.new()
	mst.bg_color = Color(1.0, 0.973, 0.878, 1.0)
	mst.border_color = Color(0.84, 0.63, 0.16, 1.0)
	mst.set_border_width_all(3)
	mst.border_width_bottom = 4
	mst.set_corner_radius_all(14)
	mst.content_margin_left = 18.0
	mst.content_margin_right = 18.0
	mst.content_margin_top = 10.0
	mst.content_margin_bottom = 10.0
	medal_panel.add_theme_stylebox_override("panel", mst)

	var mrow := HBoxContainer.new()
	mrow.add_theme_constant_override("separation", 16)

	var medal_icon := TextureRect.new()
	medal_icon.texture = GameState.get_medal_icon()
	medal_icon.custom_minimum_size = Vector2(46, 46)
	medal_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	medal_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	medal_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mrow.add_child(medal_icon)

	var mcol := VBoxContainer.new()
	mcol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mcol.add_theme_constant_override("separation", 2)

	var mtitle := Label.new()
	mtitle.text = GameState.format_text("Medalha Desbloqueada: Explorador da Flora e Fauna!")
	mtitle.add_theme_font_size_override("font_size", 23)
	mtitle.add_theme_color_override("font_color", Color(0.45, 0.27, 0.02))
	mcol.add_child(mtitle)

	var msub := Label.new()
	msub.text = GameState.format_text("Você respondeu %d de %d perguntas (%d de primeira)" % [total, total, hits])
	msub.add_theme_font_size_override("font_size", 18)
	msub.add_theme_color_override("font_color", Color(0.24, 0.30, 0.22))
	mcol.add_child(msub)
	mrow.add_child(mcol)

	var stars_box := GameState.make_stars_hbox(stars, 3, 40, 6)
	stars_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	mrow.add_child(stars_box)

	medal_panel.add_child(mrow)
	reward_box.add_child(medal_panel)

	# 2) Galeria de Riquezas do Pantanal desbloqueadas na Fase 1 (Querida Floresta, Fig. 4)
	var gal_title := Label.new()
	gal_title.text = GameState.format_text("Figurinhas do Pantanal desbloqueadas nesta fase:")
	gal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	gal_title.add_theme_font_size_override("font_size", 18)
	gal_title.add_theme_color_override("font_color", Color(0.106, 0.369, 0.125))
	reward_box.add_child(gal_title)

	var gallery := HBoxContainer.new()
	gallery.alignment = BoxContainer.ALIGNMENT_CENTER
	gallery.add_theme_constant_override("separation", 12)

	for item_var in PHASE1_REWARD_ITEMS:
		var item: Dictionary = item_var
		var card := PanelContainer.new()
		var cst := StyleBoxFlat.new()
		cst.bg_color = Color.WHITE
		cst.border_color = Color(0.45, 0.72, 0.48)
		cst.set_border_width_all(2)
		cst.border_width_bottom = 3
		cst.set_corner_radius_all(10)
		cst.content_margin_left = 6.0
		cst.content_margin_right = 6.0
		cst.content_margin_top = 6.0
		cst.content_margin_bottom = 6.0
		card.add_theme_stylebox_override("panel", cst)

		var cv := VBoxContainer.new()
		cv.add_theme_constant_override("separation", 4)

		var pic := TextureRect.new()
		pic.texture = _load_texture(str(item.get("path", "")))
		pic.custom_minimum_size = Vector2(132, 74)
		pic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		cv.add_child(pic)

		var cap := Label.new()
		cap.text = GameState.format_text(str(item.get("label", "")))
		cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		cap.add_theme_font_size_override("font_size", 15)
		cap.add_theme_color_override("font_color", COLOR_TEXT)
		cv.add_child(cap)

		card.add_child(cv)
		gallery.add_child(card)

	reward_box.add_child(gallery)
	reward_box.show()
	reward_box.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(reward_box, "modulate:a", 1.0, 0.25)


# ------------------------------------------------------------ Auxiliares

func _show_question_media(video_path: String, image_path: String) -> void:
	if media_box == null or question_video == null or question_image == null:
		return
	question_video.stop()
	question_video.stream = null
	question_image.texture = null
	question_video.hide()
	question_image.hide()
	if video_path != "" and ResourceLoader.exists(video_path):
		var stream = load(video_path)
		if stream != null:
			question_video.stream = stream
			question_video.show()
			question_video.play()
	if not question_video.visible and image_path != "":
		var tex := _load_texture(image_path)
		if tex != null:
			question_image.texture = tex
			question_image.show()
	media_box.visible = question_video.visible or question_image.visible
	if media_box.visible:
		media_box.modulate.a = 0.0
		var tw := create_tween()
		tw.tween_property(media_box, "modulate:a", 1.0, 0.22)


func _hide_media() -> void:
	if media_box == null:
		return
	if question_video != null:
		question_video.stop()
		question_video.hide()
	if question_image != null:
		question_image.hide()
	media_box.hide()


func _on_question_video_finished() -> void:
	if question_video != null and question_video.visible and question_video.stream != null:
		question_video.play()


func _set_feedback(text: String, color: Color) -> void:
	feedback_label.text = GameState.format_text(text)
	feedback_label.add_theme_color_override("font_color", color)


## Pinta um botão (já travado) com fundo colorido, texto branco e um símbolo (✓ ou ✗).
func _paint_button(button: Button, color: Color, symbol: Texture2D) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(12)
	style.content_margin_left = 20.0
	style.content_margin_right = 20.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	button.add_theme_stylebox_override("disabled", style)
	button.add_theme_color_override("font_disabled_color", Color.WHITE)
	button.add_theme_color_override("icon_disabled_color", Color.WHITE)
	button.add_theme_constant_override("h_separation", 14)
	button.icon = symbol
	button.disabled = true


func _make_symbol(is_check: bool) -> ImageTexture:
	var size := 40
	var half_width := 2.8
	var segments: Array = []
	if is_check:
		segments = [[Vector2(7, 21), Vector2(16, 30)], [Vector2(16, 30), Vector2(33, 10)]]
	else:
		segments = [[Vector2(9, 9), Vector2(31, 31)], [Vector2(31, 9), Vector2(9, 31)]]

	var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
	for y in size:
		for x in size:
			var point := Vector2(x + 0.5, y + 0.5)
			var distance := 999.0
			for segment in segments:
				var closest := Geometry2D.get_closest_point_to_segment(point, segment[0], segment[1])
				distance = minf(distance, point.distance_to(closest))
			var alpha := clampf(half_width + 0.5 - distance, 0.0, 1.0)   # borda suave
			image.set_pixel(x, y, Color(1, 1, 1, alpha))
	return ImageTexture.create_from_image(image)


func _clear_options() -> void:
	for child in options_grid.get_children():
		options_grid.remove_child(child)
		child.queue_free()


func _make_sfx(path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	if ResourceLoader.exists(path):
		player.stream = load(path)
	else:
		push_warning("Som não encontrado: %s" % path)
	add_child(player)
	return player


func _play(player: AudioStreamPlayer) -> void:
	if player.stream != null:
		player.play()


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
