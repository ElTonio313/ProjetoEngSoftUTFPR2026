extends Node

# Caminho das Cenas
const SCENE_MAIN_MENU := "res://scenes/menu/MainMenu.tscn"
const SCENE_PLAYER_NAME := "res://scenes/player_name/PlayerName.tscn"
const SCENE_PHASE1 := "res://scenes/intro/IntroScreen.tscn"
const SCENE_PHASE2 := "res://scenes/phase2/Phase2.tscn"
const SCENE_FINAL_REPORT := "res://scenes/final_reports/finalReport.tscn"
const GUIDE_PORTRAIT_PATH := "res://assets/images/guia_retrato.png"

# Nome do aluno informado na cena player_name
var player_name: String = ""

# Modo de acessibilidade: Letras em CAIXA ALTA (ativado por padrão, conforme Jesus 2019 / ASSARTE)
var uppercase_mode: bool = true

# Modo de acessibilidade: Narração por Voz em português (ativado por padrão — Querida Floresta / AliCharlie)
var narration_enabled: bool = true

# Se verdadeiro ao abrir FinalReport, abre diretamente na aba de Relatório do Professor
var open_teacher_report_directly: bool = false

# Relógio da atividade. -1 = ainda não marcado.
var _activity_start_msec: int = -1
var _activity_end_msec: int = -1

var _tts_voice_id: String = ""
var _tts_checked: bool = false
var _speaker_icon: ImageTexture = null
var _guide_portrait: Texture2D = null
var _star_filled_icon: ImageTexture = null
var _star_empty_icon: ImageTexture = null
var _medal_icon: ImageTexture = null


func _exit_tree() -> void:
	stop_speaking()


func go_to_main_menu() -> void:
	stop_speaking()
	open_teacher_report_directly = false
	get_tree().change_scene_to_file(SCENE_MAIN_MENU)


func go_to_player_name() -> void:
	stop_speaking()
	open_teacher_report_directly = false
	get_tree().change_scene_to_file(SCENE_PLAYER_NAME)


func go_to_phase1() -> void:
	stop_speaking()
	open_teacher_report_directly = false
	GameData.reset()
	start_activity()
	get_tree().change_scene_to_file(SCENE_PHASE1)


func go_to_phase2() -> void:
	stop_speaking()
	open_teacher_report_directly = false
	get_tree().change_scene_to_file(SCENE_PHASE2)


func go_to_final_report() -> void:
	stop_speaking()
	get_tree().change_scene_to_file(SCENE_FINAL_REPORT)


func go_to_teacher_report() -> void:
	stop_speaking()
	open_teacher_report_directly = true
	get_tree().change_scene_to_file(SCENE_FINAL_REPORT)


# Marca o início da atividade (chamado por go_to_phase1).
func start_activity() -> void:
	_activity_start_msec = Time.get_ticks_msec()
	_activity_end_msec = -1


# Marca o fim da atividade (a Fase 2 chamará ao concluir).
# Ignora se a atividade não começou ou se o fim já foi marcado.
func finish_activity() -> void:
	if _activity_start_msec < 0 or _activity_end_msec >= 0:
		return
	_activity_end_msec = Time.get_ticks_msec()


# Limpa o nome e relógio. Chamada quando o aluno volta ao menu.
func reset_session() -> void:
	player_name = ""
	_activity_start_msec = -1
	_activity_end_msec = -1
	open_teacher_report_directly = false


# Só há tempo total se a atividade começou E terminou.
func has_total_time() -> bool:
	return _activity_start_msec >= 0 and _activity_end_msec >= 0


# Duração total em segundos. Confira has_total_time() antes.
func get_total_seconds() -> float:
	if not has_total_time():
		return 0.0
	return (_activity_end_msec - _activity_start_msec) / 1000.0


# Formata textos respeitando o critério de Letras em Caixa Alta (Jesus, 2019).
func format_text(value: String) -> String:
	return value.to_upper() if uppercase_mode else value


# Aplica Caixa Alta e animação suave de hover/foco em todos os controles da cena.
func style_scene(root: Node) -> void:
	_walk_and_style(root)


func _walk_and_style(node: Node) -> void:
	if node is Label:
		var lbl := node as Label
		lbl.uppercase = uppercase_mode
	elif node is Button:
		var btn := node as Button
		if uppercase_mode:
			btn.text = btn.text.to_upper()
		setup_button_animation(btn)
	elif node is LineEdit:
		var le := node as LineEdit
		if uppercase_mode:
			le.placeholder_text = le.placeholder_text.to_upper()

	for child in node.get_children():
		_walk_and_style(child)


# Animação suave nos botões para chamar atenção sem poluir a interface (Jesus, 2019).
func setup_button_animation(btn: Button) -> void:
	if btn.has_meta("anim_connected"):
		return
	btn.set_meta("anim_connected", true)
	btn.resized.connect(func() -> void: btn.pivot_offset = btn.size * 0.5)
	btn.pivot_offset = btn.size * 0.5
	btn.mouse_entered.connect(func() -> void: _animate_scale(btn, Vector2(1.03, 1.03)))
	btn.mouse_exited.connect(func() -> void: _animate_scale(btn, Vector2.ONE))
	btn.focus_entered.connect(func() -> void: _animate_scale(btn, Vector2(1.03, 1.03)))
	btn.focus_exited.connect(func() -> void: _animate_scale(btn, Vector2.ONE))


func _animate_scale(ctrl: Control, target: Vector2) -> void:
	if not is_instance_valid(ctrl):
		return
	ctrl.pivot_offset = ctrl.size * 0.5
	var tw := ctrl.create_tween()
	tw.tween_property(ctrl, "scale", target, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


# Aplica estilo de botão primário (verde-escuro com texto branco) ou secundário (padrão do tema).
func style_primary_button(btn: Button, is_primary: bool = true) -> void:
	if btn == null:
		return
	if not is_primary:
		for st in ["normal", "hover", "pressed"]:
			btn.remove_theme_stylebox_override(st)
		for cl in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			btn.remove_theme_color_override(cl)
		return

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.149, 0.451, 0.188, 1.0)
	normal.border_color = Color(0.094, 0.322, 0.125, 1.0)
	normal.set_border_width_all(3)
	normal.border_width_bottom = 5
	normal.set_corner_radius_all(14)
	normal.content_margin_left = 22.0
	normal.content_margin_right = 22.0
	normal.content_margin_top = 10.0
	normal.content_margin_bottom = 10.0

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.184, 0.525, 0.227, 1.0)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.114, 0.369, 0.145, 1.0)
	pressed.border_width_bottom = 3

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color.WHITE)
	btn.add_theme_color_override("font_focus_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_pressed_color", Color.WHITE)


# Estiliza botões compactos de barra superior/auxiliar, evitando excesso de largura em 1280x720.
func style_compact_button(btn: Button) -> void:
	if btn == null:
		return
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		var base_sb := btn.get_theme_stylebox(state_name, "Button")
		if base_sb is StyleBoxFlat:
			var sb := (base_sb as StyleBoxFlat).duplicate() as StyleBoxFlat
			sb.content_margin_left = 14.0
			sb.content_margin_right = 14.0
			sb.content_margin_top = 8.0
			sb.content_margin_bottom = 8.0
			btn.add_theme_stylebox_override(state_name, sb)


# Estiliza botões de leitura em voz ("Ouvir") com ícone vetorial desenhado por código.
func style_speak_button(btn: Button, compact: bool = true) -> void:
	if btn == null:
		return
	if compact:
		style_compact_button(btn)
	btn.icon = get_speaker_icon()
	btn.add_theme_constant_override("h_separation", 8)


# Retorna o retrato do Guarda-Parque (Narrador Visual do Pantanal).
func get_guide_portrait() -> Texture2D:
	if _guide_portrait != null:
		return _guide_portrait
	var abs_path := ProjectSettings.globalize_path(GUIDE_PORTRAIT_PATH)
	if FileAccess.file_exists(abs_path):
		var img := Image.load_from_file(abs_path)
		if img != null and not img.is_empty():
			_guide_portrait = ImageTexture.create_from_image(img)
			return _guide_portrait
	if ResourceLoader.exists(GUIDE_PORTRAIT_PATH):
		var res = load(GUIDE_PORTRAIT_PATH)
		if res is Texture2D:
			_guide_portrait = res
	return _guide_portrait


# Síntese de voz nativa offline (Windows SAPI / DisplayServer TTS) em português do Brasil.
# force_manual = true quando o usuário clica explicitamente no botão "Ouvir".
func speak(raw_text: String, force_manual: bool = false) -> void:
	if not force_manual and not narration_enabled:
		return
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return

	var bus := AudioServer.get_bus_index("Master")
	if bus >= 0 and AudioServer.is_bus_mute(bus):
		stop_speaking()
		return

	var linear_vol := 1.0
	if bus >= 0:
		linear_vol = clampf(db_to_linear(AudioServer.get_bus_volume_db(bus)), 0.0, 1.0)
	var tts_vol := roundi(linear_vol * 100.0)
	if tts_vol <= 0:
		stop_speaking()
		return

	var clean := _prepare_speech_text(raw_text)
	if clean.is_empty():
		return

	var voice_id := _ensure_tts_voice()
	if voice_id.is_empty():
		return

	DisplayServer.tts_stop()
	# Velocidade 0.97: clara e natural sem artefato metálico do sintetizador SAPI5.
	DisplayServer.tts_speak(clean, voice_id, tts_vol, 1.0, 0.97, 0, true)


func stop_speaking() -> void:
	if DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		DisplayServer.tts_stop()


func _ensure_tts_voice() -> String:
	if _tts_checked:
		return _tts_voice_id
	_tts_checked = true
	if not DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH):
		return ""

	var voices: Array[Dictionary] = DisplayServer.tts_get_voices()
	# 1ª prioridade: Português do Brasil (pt-BR / pt_BR)
	for v_dict in voices:
		var lang: String = str(v_dict.get("language", "")).to_lower()
		if lang.begins_with("pt-br") or lang.begins_with("pt_br"):
			_tts_voice_id = str(v_dict.get("id", ""))
			return _tts_voice_id

	# 2ª prioridade: Qualquer variante de Português ou voz conhecida em PT
	for v_dict in voices:
		var lang: String = str(v_dict.get("language", "")).to_lower()
		var v_name: String = str(v_dict.get("name", "")).to_lower()
		if lang.begins_with("pt") or v_name.contains("portug") or v_name.contains("maria") or v_name.contains("daniel"):
			_tts_voice_id = str(v_dict.get("id", ""))
			return _tts_voice_id

	# 3ª prioridade: Consulta direta por idioma "pt"
	var pt_ids: PackedStringArray = DisplayServer.tts_get_voices_for_language("pt")
	if not pt_ids.is_empty():
		_tts_voice_id = pt_ids[0]
		return _tts_voice_id

	# 4ª prioridade: Primeira voz disponível no sistema
	if not voices.is_empty():
		_tts_voice_id = str(voices[0].get("id", ""))
	return _tts_voice_id


# Converte nomes em CAIXA ALTA ("JUAN SILVA") para "Juan Silva" antes de enviar ao sintetizador de voz,
# evitando que o Windows soletre nomes curtos como se fossem siglas.
func format_name_for_speech(raw_name: String) -> String:
	var parts := raw_name.strip_edges().split(" ", false)
	var out: Array[String] = []
	for p in parts:
		out.append(p.left(1).to_upper() + p.substr(1).to_lower())
	return " ".join(out)


func _prepare_speech_text(raw_text: String) -> String:
	var txt := raw_text.strip_edges()
	if txt.is_empty():
		return ""
	txt = txt.replace("⚠", "")
	txt = txt.replace("•", ", ")
	txt = txt.replace("ODS 15", "O D S 15")
	txt = txt.replace("ods 15", "O D S 15")
	var lines := txt.split("\n", false)
	var joined_parts: Array[String] = []
	for line in lines:
		var part := line.strip_edges()
		if part.is_empty():
			continue
		var last_ch := part.right(1)
		if not [".", "!", "?", ":", ";", ","].has(last_ch):
			part += "."
		joined_parts.append(part)
	return " ".join(joined_parts)


func get_speaker_icon() -> ImageTexture:
	if _speaker_icon != null:
		return _speaker_icon

	var sz := 28
	var col := Color(0.106, 0.369, 0.125, 1.0)
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var poly := PackedVector2Array([
		Vector2(4, 10), Vector2(9, 10), Vector2(15, 5),
		Vector2(15, 23), Vector2(9, 18), Vector2(4, 18)
	])
	var center := Vector2(15.0, 14.0)

	for y in sz:
		for x in sz:
			var pt := Vector2(x + 0.5, y + 0.5)
			var alpha := 0.0
			if Geometry2D.is_point_in_polygon(pt, poly):
				alpha = 1.0
			else:
				# Ondas sonoras à direita do alto-falante
				var dx := pt.x - center.x
				var dy := pt.y - center.y
				if dx > 1.2 and absf(dy) <= dx * 0.92:
					var r := pt.distance_to(center)
					var w1 := clampf(1.35 - absf(r - 5.2), 0.0, 1.0)
					var w2 := clampf(1.35 - absf(r - 9.2), 0.0, 1.0)
					alpha = maxf(w1, w2)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, alpha))

	_speaker_icon = ImageTexture.create_from_image(img)
	return _speaker_icon


# Calcula de 1 a 3 estrelas para a Fase 1 (sempre positivo ao concluir).
func calc_phase1_stars(result: Dictionary) -> int:
	if result.is_empty():
		return 0
	var pct := float(result.get("percent", 0.0))
	if pct >= 80.0:
		return 3
	if pct >= 40.0:
		return 2
	return 1


# Calcula de 1 a 3 estrelas para a Fase 2 (sempre positivo ao concluir).
func calc_phase2_stars(result: Dictionary) -> int:
	if result.is_empty():
		return 0
	var errs := int(result.get("total_errors", 0))
	if errs <= 1:
		return 3
	if errs <= 4:
		return 2
	return 1


# Cria uma fileira horizontal de estrelas (preenchidas e vazias) pronta para uso na UI.
func make_stars_hbox(earned: int, total: int = 3, star_px: int = 34, sep: int = 6) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", sep)
	for i in total:
		var tr := TextureRect.new()
		tr.texture = get_star_icon(i < earned)
		tr.custom_minimum_size = Vector2(star_px, star_px)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		box.add_child(tr)
	return box


# Desenha estrela de 5 pontas suavizada (2x2 supersampling), sem depender de emojis do sistema.
func get_star_icon(filled: bool) -> ImageTexture:
	if filled and _star_filled_icon != null:
		return _star_filled_icon
	if not filled and _star_empty_icon != null:
		return _star_empty_icon

	var sz := 44
	var center := Vector2(sz * 0.5, sz * 0.52)
	var outer_r := sz * 0.44
	var inner_r := outer_r * 0.42
	var pts := _build_star_polygon(center, outer_r, inner_r)

	var fill_top := Color(1.0, 0.86, 0.24) if filled else Color(0.94, 0.93, 0.89)
	var fill_bot := Color(0.95, 0.68, 0.06) if filled else Color(0.89, 0.88, 0.83)
	var border_col := Color(0.72, 0.43, 0.02) if filled else Color(0.64, 0.61, 0.53)

	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var offsets: Array[Vector2] = [Vector2(0.25, 0.25), Vector2(0.75, 0.25), Vector2(0.25, 0.75), Vector2(0.75, 0.75)]
	for y in sz:
		for x in sz:
			var inside_cnt := 0
			var min_edge := 999.0
			for off in offsets:
				var sp: Vector2 = Vector2(x, y) + off
				if Geometry2D.is_point_in_polygon(sp, pts):
					inside_cnt += 1
				min_edge = minf(min_edge, _dist_to_poly_edges(sp, pts))

			if inside_cnt == 0 and min_edge > 1.4:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
				continue

			var t := clampf(float(y) / float(sz), 0.0, 1.0)
			var base_col := fill_top.lerp(fill_bot, t)
			var edge_mix := clampf(2.1 - min_edge, 0.0, 1.0)
			var final_col := base_col.lerp(border_col, edge_mix)
			var cov := float(inside_cnt) * 0.25
			var border_a := clampf(1.4 - min_edge, 0.0, 1.0)
			var alpha := maxf(cov, border_a)
			img.set_pixel(x, y, Color(final_col.r, final_col.g, final_col.b, alpha))

	var tex := ImageTexture.create_from_image(img)
	if filled:
		_star_filled_icon = tex
	else:
		_star_empty_icon = tex
	return tex


# Desenha medalha dourada com fita verde-floresta e estrela central.
func get_medal_icon() -> ImageTexture:
	if _medal_icon != null:
		return _medal_icon

	var sz := 46
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var ribbon_l := PackedVector2Array([Vector2(11, 2), Vector2(19, 2), Vector2(23, 18), Vector2(16, 18)])
	var ribbon_r := PackedVector2Array([Vector2(27, 2), Vector2(35, 2), Vector2(30, 18), Vector2(23, 18)])
	var medal_c := Vector2(23.0, 28.5)
	var medal_r := 14.5
	var star_pts := _build_star_polygon(medal_c, 8.2, 3.5)
	var ribbon_col := Color(0.149, 0.471, 0.188)
	var ribbon_dark := Color(0.094, 0.322, 0.125)
	var gold_light := Color(1.0, 0.87, 0.28)
	var gold_dark := Color(0.80, 0.50, 0.04)

	for y in sz:
		for x in sz:
			var pt := Vector2(x + 0.5, y + 0.5)
			var d_medal := pt.distance_to(medal_c)
			if d_medal <= medal_r + 0.8:
				var a := clampf(medal_r + 0.6 - d_medal, 0.0, 1.0)
				var col := gold_light.lerp(gold_dark, clampf((pt.y - 14.0) / 28.0, 0.0, 1.0))
				if d_medal > medal_r - 2.3 or absf(d_medal - (medal_r - 4.2)) < 0.8:
					col = gold_dark
				elif Geometry2D.is_point_in_polygon(pt, star_pts):
					col = Color(1.0, 0.98, 0.86)
				img.set_pixel(x, y, Color(col.r, col.g, col.b, a))
			elif Geometry2D.is_point_in_polygon(pt, ribbon_l):
				img.set_pixel(x, y, ribbon_col)
			elif Geometry2D.is_point_in_polygon(pt, ribbon_r):
				img.set_pixel(x, y, ribbon_dark)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	_medal_icon = ImageTexture.create_from_image(img)
	return _medal_icon


func _build_star_polygon(center: Vector2, outer_r: float, inner_r: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 10:
		var angle := -PI * 0.5 + float(i) * PI / 5.0
		var r := outer_r if (i % 2 == 0) else inner_r
		pts.append(center + Vector2(cos(angle), sin(angle)) * r)
	return pts


func _dist_to_poly_edges(pt: Vector2, pts: PackedVector2Array) -> float:
	var best := 999.0
	var n := pts.size()
	for i in n:
		var cl := Geometry2D.get_closest_point_to_segment(pt, pts[i], pts[(i + 1) % n])
		best = minf(best, pt.distance_to(cl))
	return best
