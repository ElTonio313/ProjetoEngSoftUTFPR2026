extends Control

const COLOR_RIGHT := Color(0.1, 0.5, 0.2)
const COLOR_WRONG := Color(0.6901961, 0, 0.1254902)
const COLOR_HINT := Color(0.05, 0.25, 0.55)
const COLOR_TEXT := Color(0.0941176, 0.14902, 0.105882)
const SOUND_RIGHT := "res://assets/sounds/correct.wav"
const SOUND_WRONG := "res://assets/sounds/wrong.wav"
const NARRATION_DIR := "res://assets/audio/narration/phase2/"
const AUDIO_INTRO_TITLE := "res://assets/audio/narration/phase2/intro/IntroLabel.ogg"
const AUDIO_INTRO_MAMMALS := "res://assets/audio/narration/phase2/intro/MammalsText.ogg"
const AUDIO_INTRO_REPTILES := "res://assets/audio/narration/phase2/intro/ReptilesText.ogg"
const AUDIO_INTRO_BIRDS := "res://assets/audio/narration/phase2/intro/BirdsText.ogg"
const AUDIO_CONTINUE := "res://assets/audio/narration/phase2/intro/continueAudio.ogg"
const AUDIO_INSTRUCTION := "res://assets/audio/narration/phase2/Instruction.ogg"
const AUDIO_CORRECT := "res://assets/audio/narration/phase2/feedback_correct.ogg"
const AUDIO_WRONG := "res://assets/audio/narration/phase2/feedback_wrong.ogg"
const AUDIO_ZONE_MAMMALS := "res://assets/audio/narration/phase2/mammalsZoneAudio.ogg"
const AUDIO_ZONE_REPTILES := "res://assets/audio/narration/phase2/reptilesZoneAudio.ogg"
const AUDIO_ZONE_BIRDS := "res://assets/audio/narration/phase2/birdsZoneAudio.ogg"
const AUDIO_NEXT_ANIMAL := "res://assets/audio/narration/phase2/nextAnimalAudio.ogg"
const AUDIO_REVIEW_GROUPS := "res://assets/audio/narration/phase2/reviewGroupsAudio.ogg"
const AUDIO_HINT_BTN := "res://assets/audio/narration/phase1/hintAudioB.ogg"
const AUDIO_MENU_BTN := "res://assets/audio/narration/intro_phase1/menuAudio.ogg"
const BG_PATH := "res://assets/images/bg_pantanal.png"
const IMG_MAMMAL := "res://assets/images/capivara.png"
const IMG_REPTILE := "res://assets/images/jacare.png"
const IMG_BIRD := "res://assets/images/arara_azul.png"

@onready var intro_panel: Control = %IntroPanel
@onready var continue_button: Button = %ContinueButton
@onready var progress_label: Label = %ProgressLabel
@onready var progress_bar: ProgressBar = %ProgressBar
@onready var animal_card: AnimalCard = %AnimalCard
@onready var feedback_card: Control = %FeedbackCard
@onready var feedback_icon: TextureRect = %FeedbackIcon
@onready var feedback_label: Label = %FeedbackLabel
@onready var next_button: Button = %NextButton
@onready var hint_button: Button = get_node_or_null("%HintButton")
@onready var mammals_zone: DropZone = %MammalsZone
@onready var reptiles_zone: DropZone = %ReptilesZone
@onready var birds_zone: DropZone = %BirdsZone
@onready var bg_texture: TextureRect = get_node_or_null("%BgTexture")
@onready var intro_bg_texture: TextureRect = get_node_or_null("%IntroBgTexture")
@onready var mammals_example_img: TextureRect = get_node_or_null("%MammalsExampleImg")
@onready var reptiles_example_img: TextureRect = get_node_or_null("%ReptilesExampleImg")
@onready var birds_example_img: TextureRect = get_node_or_null("%BirdsExampleImg")

var manager := ClassificationManager.new()
var narrator := Narrator.new()
var _animal_name_audio: AudioStream = null
var _current_streams: Array[AudioStream] = []
var _feedback_tween: Tween
var _sfx_right: AudioStreamPlayer
var _sfx_wrong: AudioStreamPlayer
var _badge_ok: ImageTexture
var _badge_err: ImageTexture
var _hints_used: int = 0
var _hint_counted_current: bool = false
var _current_speech: String = ""
var _last_attempt_mode: String = "clique"
var _modes_by_exercise: Array[String] = []
var _drag_count: int = 0
var _click_count: int = 0
var _key_count: int = 0
const GROUPS_INTRO_SPEECH := "Fase 2: Conheça os três grupos de animais. Mamíferos: têm o corpo coberto por pelos e as mães alimentam os filhotes com leite, como a capivara e a onça. Répteis: têm a pele seca coberta por escamas e a maioria põe ovos, como o jacaré e a sucuri. Aves: têm o corpo coberto por penas, possuem bico e põem ovos, como a arara-azul e o tuiuiú."


func _ready() -> void:
	var bg := _load_texture(BG_PATH)
	if bg_texture != null:
		bg_texture.texture = bg
	if intro_bg_texture != null:
		intro_bg_texture.texture = bg
	if mammals_example_img != null:
		mammals_example_img.texture = _load_texture(IMG_MAMMAL)
	if reptiles_example_img != null:
		reptiles_example_img.texture = _load_texture(IMG_REPTILE)
	if birds_example_img != null:
		birds_example_img.texture = _load_texture(IMG_BIRD)
	var portrait := GameState.get_guide_portrait()
	var guide_portrait: TextureRect = get_node_or_null("%GuidePortrait")
	if guide_portrait != null:
		guide_portrait.texture = portrait
	var intro_guide_portrait: TextureRect = get_node_or_null("%IntroGuidePortrait")
	if intro_guide_portrait != null:
		intro_guide_portrait.texture = portrait

	_badge_ok = _make_badge(true, COLOR_RIGHT)
	_badge_err = _make_badge(false, COLOR_WRONG)
	_sfx_right = _make_sfx(SOUND_RIGHT)
	_sfx_wrong = _make_sfx(SOUND_WRONG)

	manager.name = "ClassificationManager"
	add_child(manager)
	add_child(narrator)
	manager.exercise_ready.connect(_on_exercise_ready)
	manager.answer_checked.connect(_on_answer_checked)
	manager.phase_finished.connect(_on_phase_finished)

	animal_card.mouse_entered.connect(_on_animal_card_hover)
	mammals_zone.mouse_entered.connect(func() -> void: _hover_say(AUDIO_ZONE_MAMMALS))
	reptiles_zone.mouse_entered.connect(func() -> void: _hover_say(AUDIO_ZONE_REPTILES))
	birds_zone.mouse_entered.connect(func() -> void: _hover_say(AUDIO_ZONE_BIRDS))
	next_button.mouse_entered.connect(func() -> void: _hover_say(AUDIO_NEXT_ANIMAL))
	continue_button.mouse_entered.connect(func() -> void: _hover_say(AUDIO_CONTINUE))

	for zone in [mammals_zone, reptiles_zone, birds_zone]:
		zone.animal_classified.connect(_on_animal_classified)

	feedback_card.show()
	feedback_icon.hide()
	next_button.hide()
	intro_panel.show()
	GameState.style_scene(self)
	GameState.style_primary_button(continue_button, true)
	GameState.style_primary_button(next_button, true)
	var menu_btn: Button = get_node_or_null("%MenuButton")
	if menu_btn != null:
		GameState.style_compact_button(menu_btn)
		menu_btn.mouse_entered.connect(func() -> void: _hover_say(AUDIO_MENU_BTN))
	var review_btn: Button = get_node_or_null("%ReviewGroupsButton")
	if review_btn != null:
		GameState.style_compact_button(review_btn)
		review_btn.mouse_entered.connect(func() -> void: _hover_say(AUDIO_REVIEW_GROUPS))
	if hint_button != null:
		GameState.style_compact_button(hint_button)
		hint_button.mouse_entered.connect(func() -> void: _hover_say(AUDIO_HINT_BTN))
	var speak_btn: Button = get_node_or_null("%SpeakButton")
	if speak_btn != null:
		GameState.style_speak_button(speak_btn)
		speak_btn.pressed.connect(_on_speak_button_pressed)
	var intro_speak_btn: Button = get_node_or_null("%IntroSpeakButton")
	if intro_speak_btn != null:
		GameState.style_speak_button(intro_speak_btn, false)
		intro_speak_btn.pressed.connect(func() -> void: _play_intro_narration(true))
	continue_button.grab_focus()

	if manager.start_phase():
		_hints_used = 0
		_modes_by_exercise.clear()
		_drag_count = 0
		_click_count = 0
		_key_count = 0
		_update_progress()
		_play_intro_narration(false)
	else:
		continue_button.disabled = true
		continue_button.text = GameState.format_text("Não foi possível carregar os animais")


func _unhandled_input(event: InputEvent) -> void:
	if intro_panel.visible and manager.current_index >= 0 and event.is_action_pressed("ui_cancel"):
		narrator.stop()
		GameState.stop_speaking()
		intro_panel.hide()
		get_viewport().set_input_as_handled()


func _on_menu_button_pressed() -> void:
	narrator.stop()
	GameState.reset_session()
	GameState.go_to_main_menu()


func _on_continue_button_pressed() -> void:
	narrator.stop()
	GameState.stop_speaking()
	intro_panel.hide()
	if manager.current_index < 0:
		manager.next_exercise()
	elif GameState.narration_enabled:
		if not _current_streams.is_empty():
			narrator.say_all(_current_streams)
		else:
			GameState.speak(_current_speech, false)


func _on_review_groups_button_pressed() -> void:
	intro_panel.show()
	continue_button.grab_focus()
	_play_intro_narration(false)


func _play_intro_narration(force_manual: bool) -> void:
	if not force_manual and not GameState.narration_enabled:
		return
	GameState.stop_speaking()
	var streams: Array[AudioStream] = []
	for p in [AUDIO_INTRO_TITLE, AUDIO_INTRO_MAMMALS, AUDIO_INTRO_REPTILES, AUDIO_INTRO_BIRDS]:
		var s := Narrator.load_audio(p)
		if s != null:
			streams.append(s)
	if not streams.is_empty():
		narrator.say_all(streams)
	else:
		GameState.speak(GROUPS_INTRO_SPEECH, force_manual)


func _on_speak_button_pressed() -> void:
	if intro_panel.visible:
		_play_intro_narration(true)
	elif not _current_streams.is_empty():
		GameState.stop_speaking()
		narrator.say_all(_current_streams)
	elif _current_speech != "":
		narrator.stop()
		GameState.speak(_current_speech, true)


func _hover_say(path: String) -> void:
	if not GameState.narration_enabled:
		return
	var s := Narrator.load_audio(path)
	if s != null:
		narrator.say(s, Narrator.PRIORITY_HOVER)


func _on_animal_card_hover() -> void:
	if not GameState.narration_enabled or intro_panel.visible or _animal_name_audio == null:
		return
	narrator.say(_animal_name_audio, Narrator.PRIORITY_HOVER)


func _load_animal_audio(folder: String, animal_id: String) -> AudioStream:
	var primary := "%s%s/%s.ogg" % [NARRATION_DIR, folder, animal_id]
	var s := Narrator.load_audio(primary)
	if s != null:
		return s
	if animal_id == "onca" and folder == "hints":
		return Narrator.load_audio("%shints/onca-pintada.ogg" % NARRATION_DIR)
	return null


func _on_hint_button_pressed() -> void:
	var current_animal := manager.get_current_animal()
	if current_animal != null and animal_card.can_drag:
		if not _hint_counted_current:
			_hint_counted_current = true
			_hints_used += 1
		if hint_button != null:
			hint_button.hide()
		_show_feedback("Dica do Guia: " + current_animal.hint, COLOR_HINT, null)
		_current_speech = "%s. Dica do Guia: %s" % [current_animal.display_name, current_animal.hint]
		var h_audio := _load_animal_audio("hints", current_animal.id)
		_current_streams.clear()
		if h_audio != null:
			_current_streams.append(h_audio)
		if GameState.narration_enabled:
			GameState.stop_speaking()
			if not _current_streams.is_empty():
				narrator.say_all(_current_streams)
			else:
				GameState.speak("Dica do Guia: " + current_animal.hint, false)


func _on_next_button_pressed() -> void:
	next_button.hide()
	manager.next_exercise()


func _on_exercise_ready(animal: Animal, _number: int, _total: int) -> void:
	_hint_counted_current = false
	animal_card.set_animal(GameState.format_text(animal.display_name), animal.image_path)
	_set_animal_draggable(true)
	if hint_button != null:
		hint_button.visible = animal.hint != ""
		hint_button.disabled = false
	feedback_icon.hide()
	feedback_label.text = GameState.format_text("Guia: Arraste o cartão ou clique no grupo certo abaixo!")
	feedback_label.add_theme_color_override("font_color", COLOR_TEXT)
	feedback_card.show()
	next_button.hide()
	_update_progress()
	animal_card.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(animal_card, "modulate:a", 1.0, 0.22)

	_current_speech = "Qual é o grupo deste animal: %s? Arraste ou clique em Mamíferos, Répteis ou Aves." % animal.display_name
	_animal_name_audio = _load_animal_audio("animals", animal.id)
	var instr_audio := Narrator.load_audio(AUDIO_INSTRUCTION)
	var full_streams: Array[AudioStream] = []
	if instr_audio != null:
		full_streams.append(instr_audio)
	if _animal_name_audio != null:
		full_streams.append(_animal_name_audio)
	_current_streams = full_streams

	if GameState.narration_enabled:
		GameState.stop_speaking()
		var auto_streams: Array[AudioStream] = []
		if manager.current_index == 0 and instr_audio != null:
			auto_streams.append(instr_audio)
		if _animal_name_audio != null:
			auto_streams.append(_animal_name_audio)
		if not auto_streams.is_empty():
			narrator.say_all(auto_streams)
		else:
			GameState.speak(_current_speech, false)


func _on_animal_classified(category: String, input_mode: String) -> void:
	_last_attempt_mode = input_mode
	manager.submit_answer(category)


func _on_animal_dropped(category: String) -> void:
	manager.submit_answer(category)


func _on_answer_checked(is_correct: bool, hint: String) -> void:
	if is_correct:
		_modes_by_exercise.append(_last_attempt_mode)
		if _last_attempt_mode == "arraste":
			_drag_count += 1
		elif _last_attempt_mode == "teclado":
			_key_count += 1
		else:
			_click_count += 1
		_show_feedback("Acertou! Muito bem!", COLOR_RIGHT, _badge_ok)
		_play(_sfx_right)
		_set_animal_draggable(false)
		if hint_button != null:
			hint_button.hide()
		_update_progress()
		var is_last := manager.current_index + 1 >= manager.get_total()
		next_button.text = GameState.format_text("Concluir" if is_last else "Próximo animal")
		next_button.show()
		next_button.grab_focus()
		_current_speech = "Acertou! Muito bem!"
		var ok_audio := Narrator.load_audio(AUDIO_CORRECT)
		_current_streams.clear()
		if ok_audio != null:
			_current_streams.append(ok_audio)
		if GameState.narration_enabled:
			GameState.stop_speaking()
			if ok_audio != null:
				narrator.say(ok_audio)
			else:
				GameState.speak(_current_speech, false)
	else:
		if hint_button != null:
			hint_button.hide()
		_show_feedback("Não foi dessa vez. Tente de novo!  Dica: " + hint, COLOR_WRONG, _badge_err)
		_play(_sfx_wrong)
		_current_speech = "Não foi dessa vez. Tente de novo! Dica: " + hint
		var err_streams: Array[AudioStream] = []
		var w_audio := Narrator.load_audio(AUDIO_WRONG)
		if w_audio != null:
			err_streams.append(w_audio)
		var cur := manager.get_current_animal()
		if cur != null:
			var h_audio := _load_animal_audio("hints", cur.id)
			if h_audio != null:
				err_streams.append(h_audio)
		_current_streams = err_streams
		if GameState.narration_enabled:
			GameState.stop_speaking()
			if not err_streams.is_empty():
				narrator.say_all(err_streams)
			else:
				GameState.speak(_current_speech, false)


func _on_phase_finished(result: Dictionary) -> void:
	narrator.stop()
	var enriched := result.duplicate(true)
	enriched["hints_used"] = _hints_used
	enriched["motor_summary"] = {
		"arraste": _drag_count,
		"clique": _click_count,
		"teclado": _key_count,
	}
	var exercises_arr: Array = enriched.get("exercises", [])
	for i in exercises_arr.size():
		if i < _modes_by_exercise.size() and typeof(exercises_arr[i]) == TYPE_DICTIONARY:
			var ex_dict: Dictionary = exercises_arr[i]
			ex_dict["input_mode"] = _modes_by_exercise[i]
	GameData.set_phase2_result(enriched)
	GameState.finish_activity()
	ReportWriter.save_report()
	GameData.record_completed_session(GameState.player_name, GameState.get_total_seconds())
	GameState.go_to_final_report()


func _update_progress() -> void:
	var total := manager.get_total()
	progress_bar.max_value = total
	progress_bar.value = manager.completed_count
	progress_label.text = GameState.format_text("%d de %d animais" % [manager.completed_count, total])


func _show_feedback(text: String, color: Color, badge: Texture2D) -> void:
	feedback_card.show()
	feedback_icon.texture = badge
	feedback_icon.visible = badge != null
	feedback_label.text = GameState.format_text(text)
	feedback_label.add_theme_color_override("font_color", color)
	if _feedback_tween != null:
		_feedback_tween.kill()
	feedback_card.modulate.a = 0.0
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(feedback_card, "modulate:a", 1.0, 0.22)


func _set_animal_draggable(value: bool) -> void:
	animal_card.can_drag = value
	animal_card.mouse_default_cursor_shape = \
		Control.CURSOR_POINTING_HAND if value else Control.CURSOR_ARROW


func _make_badge(is_check: bool, bg_col: Color) -> ImageTexture:
	var sz := 40
	var center := (sz - 1) / 2.0
	var radius := 18.0
	var segments: Array = []
	if is_check:
		segments = [[Vector2(11, 21), Vector2(18, 28)], [Vector2(18, 28), Vector2(30, 13)]]
	else:
		segments = [[Vector2(13, 13), Vector2(27, 27)], [Vector2(27, 13), Vector2(13, 27)]]

	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	for y in sz:
		for x in sz:
			var pt := Vector2(x + 0.5, y + 0.5)
			var dist_c := Vector2(x, y).distance_to(Vector2(center, center))
			var circle_a := clampf(radius + 0.5 - dist_c, 0.0, 1.0)
			if circle_a <= 0.0:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue
			var dist_seg := 999.0
			for seg in segments:
				var cl := Geometry2D.get_closest_point_to_segment(pt, seg[0], seg[1])
				dist_seg = minf(dist_seg, pt.distance_to(cl))
			var sym_a := clampf(2.4 - dist_seg, 0.0, 1.0)
			var col := bg_col.lerp(Color.WHITE, sym_a)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, circle_a))
	return ImageTexture.create_from_image(img)


func _make_sfx(path: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	if ResourceLoader.exists(path):
		player.stream = load(path)
	add_child(player)
	return player


func _play(player: AudioStreamPlayer) -> void:
	if player != null and player.stream != null:
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
