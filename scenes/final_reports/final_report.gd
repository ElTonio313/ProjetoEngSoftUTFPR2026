extends Control
## Tela de Relatórios:
## - Visão do Aluno: simplificada, visual e acolhedora (sem excesso de números ou tempos).
## - Visão do Professor: indicadores da turma, cartões individuais por sessão e Exportação nativa em PDF.

const BG_PATH := "res://assets/images/bg_pantanal.png"
const PdfExporterScript := preload("res://scripts/reports/pdf_exporter.gd")
const CATEGORY_LABELS := {
	"fauna": "Fauna (Animais)",
	"flora": "Flora (Plantas)",
	"conservacao": "Conservação (ODS 15)",
}
const CATEGORY_THUMBS := {
	"fauna": ["res://assets/images/tuiuiu.png"],
	"flora": ["res://assets/images/aguape.png"],
	"conservacao": ["res://assets/images/proteger.png"],
}

@onready var title_label: Label = %TitleLabel
@onready var subtitle_label: Label = %SubtitleLabel
@onready var phase1_banner_title: Label = %Phase1BannerTitle
@onready var phase1_banner_sub: Label = %Phase1BannerSub
@onready var phase1_items: VBoxContainer = %Phase1Items
@onready var phase2_banner_title: Label = %Phase2BannerTitle
@onready var phase2_banner_sub: Label = %Phase2BannerSub
@onready var phase2_items: VBoxContainer = %Phase2Items

@onready var student_tab_button: Button = %StudentTabButton
@onready var teacher_tab_button: Button = %TeacherTabButton
@onready var student_view: Control = %StudentView
@onready var teacher_view: Control = %TeacherView
@onready var kpi_sessions_val: Label = %KpiSessionsVal
@onready var kpi_p1_val: Label = %KpiP1Val
@onready var kpi_p2_val: Label = %KpiP2Val
@onready var export_status_label: Label = %ExportStatusLabel
@onready var session_cards_vbox: VBoxContainer = %SessionCardsVBox

@onready var export_pdf_button: Button = %ExportPdfButton
@onready var clear_history_button: Button = %ClearHistoryButton
@onready var back_button: Button = %BackButton
@onready var speak_report_button: Button = get_node_or_null("%SpeakReportButton")
@onready var confirm_clear_overlay: Control = %ConfirmClearOverlay
@onready var cancel_clear_button: Button = %CancelClearButton
@onready var confirm_delete_button: Button = %ConfirmDeleteButton
@onready var bg_texture: TextureRect = get_node_or_null("%BgTexture")

var _check_badge: ImageTexture
var _save_dialog: FileDialog
var _student_speech: String = ""
var _student_audio_path: String = ""
var narrator := Narrator.new()


func _ready() -> void:
	add_child(narrator)
	if bg_texture != null:
		bg_texture.texture = _load_texture(BG_PATH)
	var guide_portrait: TextureRect = get_node_or_null("%GuidePortrait")
	if guide_portrait != null:
		guide_portrait.texture = GameState.get_guide_portrait()
	var medal_tex := GameState.get_medal_icon()
	for node_name in ["%GrandMedalIcon", "%Phase1MedalIcon", "%Phase2MedalIcon"]:
		var tr: TextureRect = get_node_or_null(node_name)
		if tr != null:
			tr.texture = medal_tex
	_check_badge = _make_check_badge()

	var player_name: String = GameState.player_name if GameState.player_name != "" else GameData.last_player_name
	if player_name != "":
		title_label.text = "Parabéns, %s! Você concluiu a aventura pelo Pantanal!" % player_name
	else:
		title_label.text = "Resumo da Aventura pelo Pantanal"

	_populate_student_phase1(GameData.phase1_result)
	_populate_student_phase2(GameData.phase2_result)
	_populate_student_stars(GameData.phase1_result, GameData.phase2_result)
	_refresh_teacher_report()

	student_tab_button.pressed.connect(_show_student_tab)
	teacher_tab_button.pressed.connect(_show_teacher_tab)
	export_pdf_button.pressed.connect(_on_export_pdf_pressed)
	clear_history_button.pressed.connect(_open_confirm_clear)
	cancel_clear_button.pressed.connect(_close_confirm_clear)
	confirm_delete_button.pressed.connect(_on_confirm_delete_pressed)
	back_button.pressed.connect(_on_back_pressed)
	if speak_report_button != null:
		GameState.style_speak_button(speak_report_button, false)
		speak_report_button.pressed.connect(func() -> void: _play_student_summary(true))

	_build_student_speech(player_name)
	GameState.style_scene(self)
	GameState.style_primary_button(export_pdf_button, true)
	GameState.style_primary_button(cancel_clear_button, true)

	if GameState.open_teacher_report_directly:
		_show_teacher_tab()
	else:
		_show_student_tab()
		if not GameData.phase1_result.is_empty() or not GameData.phase2_result.is_empty():
			_play_student_summary(false)
	back_button.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if confirm_clear_overlay.visible and event.is_action_pressed("ui_cancel"):
		_close_confirm_clear()
		get_viewport().set_input_as_handled()


func _show_student_tab() -> void:
	student_view.show()
	teacher_view.hide()
	export_pdf_button.hide()
	clear_history_button.hide()
	export_status_label.hide()
	if speak_report_button != null:
		speak_report_button.show()
	GameState.style_primary_button(student_tab_button, true)
	GameState.style_primary_button(teacher_tab_button, false)
	GameState.style_primary_button(back_button, true)


func _show_teacher_tab() -> void:
	narrator.stop()
	GameState.stop_speaking()
	_refresh_teacher_report()
	student_view.hide()
	teacher_view.show()
	export_pdf_button.show()
	if speak_report_button != null:
		speak_report_button.hide()
	clear_history_button.visible = not GameData.history.is_empty()
	GameState.style_primary_button(student_tab_button, false)
	GameState.style_primary_button(teacher_tab_button, true)
	GameState.style_primary_button(export_pdf_button, true)
	GameState.style_primary_button(back_button, false)


func _build_student_speech(player_name: String) -> void:
	var spoken_name := GameState.format_name_for_speech(player_name)
	var who := (", " + spoken_name) if spoken_name != "" else ""
	if GameData.phase1_result.is_empty() and GameData.phase2_result.is_empty():
		_student_audio_path = "res://assets/audio/narration/report/empty.ogg"
		_student_speech = "Resumo da aventura pelo Pantanal. Jogue uma partida para desbloquear suas medalhas e estrelas."
		return
	var p1_stars := GameState.calc_phase1_stars(GameData.phase1_result)
	var p2_stars := GameState.calc_phase2_stars(GameData.phase2_result)
	var total_stars := clampi(p1_stars + p2_stars, 2, 6)
	_student_audio_path = "res://assets/audio/narration/report/stars_%d.ogg" % total_stars
	_student_speech = "Parabéns%s! Você concluiu a aventura pelo Pantanal! Você conquistou %d de 6 estrelas e desbloqueou as medalhas Explorador do Pantanal, Amigo da Fauna e Guardião do Pantanal!" % [
		who, total_stars
	]


func _play_student_summary(force_manual: bool) -> void:
	if not force_manual and not GameState.narration_enabled:
		return
	GameState.stop_speaking()
	var s := Narrator.load_audio(_student_audio_path)
	if s != null:
		narrator.say(s)
	else:
		GameState.speak(_student_speech, force_manual)


func _on_export_pdf_pressed() -> void:
	if _save_dialog == null:
		_save_dialog = FileDialog.new()
		_save_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		_save_dialog.access = FileDialog.ACCESS_FILESYSTEM
		_save_dialog.use_native_dialog = true
		_save_dialog.title = "Salvar Relatório em PDF"
		_save_dialog.filters = PackedStringArray(["*.pdf ; Documento PDF"])
		_save_dialog.file_selected.connect(_on_pdf_save_path_selected)
		add_child(_save_dialog)

	_save_dialog.current_dir = PdfExporterScript.get_default_dir()
	_save_dialog.current_file = PdfExporterScript.get_default_filename()
	_save_dialog.popup_centered(Vector2i(800, 540))


func _on_pdf_save_path_selected(selected_path: String) -> void:
	var saved_path: String = PdfExporterScript.export_teacher_report_to_path(GameData.history, selected_path)
	if saved_path != "":
		var win_path := saved_path.replace("/", "\\")
		var file_only := saved_path.get_file()
		export_status_label.text = GameState.format_text("PDF salvo com sucesso (" + file_only + ")")
		export_status_label.show()
		OS.shell_open(win_path)
	else:
		export_status_label.text = GameState.format_text("Não foi possível salvar no local escolhido (verifique se o arquivo já está aberto).")
		export_status_label.show()


func _open_confirm_clear() -> void:
	confirm_clear_overlay.show()
	cancel_clear_button.grab_focus()


func _close_confirm_clear() -> void:
	confirm_clear_overlay.hide()
	teacher_tab_button.grab_focus()


func _on_confirm_delete_pressed() -> void:
	confirm_clear_overlay.hide()
	GameData.clear_history()
	export_status_label.hide()
	_refresh_teacher_report()
	clear_history_button.hide()


func _on_back_pressed() -> void:
	GameState.reset_session()
	GameState.go_to_main_menu()


# ------------------------------------------------ Visão do Aluno (Simplificada + Gamificada)

func _populate_student_stars(p1_result: Dictionary, p2_result: Dictionary) -> void:
	var s1 := GameState.calc_phase1_stars(p1_result)
	var s2 := GameState.calc_phase2_stars(p2_result)

	var h1: HBoxContainer = get_node_or_null("%Phase1StarsHolder")
	if h1 != null:
		for ch in h1.get_children():
			ch.queue_free()
		h1.add_child(GameState.make_stars_hbox(s1, 3, 28, 4))

	var h2: HBoxContainer = get_node_or_null("%Phase2StarsHolder")
	if h2 != null:
		for ch in h2.get_children():
			ch.queue_free()
		h2.add_child(GameState.make_stars_hbox(s2, 3, 28, 4))

	var grand_lbl: Label = get_node_or_null("%GrandStarsLabel")
	var grand_panel: Control = get_node_or_null("%GrandBadgePanel")
	if grand_lbl != null:
		var tot := s1 + s2
		if tot > 0:
			grand_lbl.text = GameState.format_text("%d de 6 Estrelas" % tot)
			if grand_panel != null:
				grand_panel.show()
		else:
			grand_lbl.text = GameState.format_text("Jogue para ganhar!")


func _populate_student_phase1(result: Dictionary) -> void:
	for ch in phase1_items.get_children():
		ch.queue_free()

	if result.is_empty():
		phase1_banner_title.text = GameState.format_text("Medalha: Explorador do Pantanal")
		phase1_banner_sub.text = GameState.format_text("Jogue uma partida para desbloquear!")
		return

	var hits := int(result.get("hits", 0))
	var total := int(result.get("total", 5))
	phase1_banner_title.text = GameState.format_text("Medalha: Explorador do Pantanal")
	phase1_banner_sub.text = GameState.format_text("%d de %d respondidas  •  %d de primeira" % [total, total, hits])

	var by_cat: Dictionary = result.get("by_category", {})
	for key in ["fauna", "flora", "conservacao"]:
		if by_cat.has(key):
			var d: Dictionary = by_cat[key]
			var title: String = CATEGORY_LABELS.get(key, key.capitalize())
			var sub := "%d de %d de primeira" % [int(d.get("hits", 0)), int(d.get("total", 0))]
			var thumbs: Array = CATEGORY_THUMBS.get(key, [])
			phase1_items.add_child(_make_student_item_row(title, sub, Color(0.094, 0.149, 0.106), thumbs))


func _populate_student_phase2(result: Dictionary) -> void:
	for ch in phase2_items.get_children():
		ch.queue_free()

	if result.is_empty():
		phase2_banner_title.text = GameState.format_text("Medalha: Amigo da Fauna (ODS 15)")
		phase2_banner_sub.text = GameState.format_text("Classifique os animais para desbloquear!")
	else:
		var total := int(result.get("total", 6))
		phase2_banner_title.text = GameState.format_text("Medalha: Amigo da Fauna (ODS 15)")
		phase2_banner_sub.text = GameState.format_text("%d de %d animais nos grupos certos!" % [total, total])

	# Mostra os 3 grupos aprendidos com as miniaturas desbloqueadas como reforço visual
	phase2_items.add_child(_make_student_item_row(
		"Mamíferos", "Capivara  •  Onça-pintada", Color(0.45, 0.24, 0.06),
		["res://assets/images/capivara.png", "res://assets/images/onca.png"]
	))
	phase2_items.add_child(_make_student_item_row(
		"Répteis", "Jacaré  •  Sucuri", Color(0.106, 0.369, 0.125),
		["res://assets/images/jacare.png", "res://assets/images/sucuri.png"]
	))
	phase2_items.add_child(_make_student_item_row(
		"Aves", "Tuiuiú  •  Arara-azul", Color(0.06, 0.32, 0.52),
		["res://assets/images/tuiuiu.png", "res://assets/images/arara_azul.png"]
	))


func _make_student_item_row(title: String, subtitle: String, title_col: Color, thumb_paths: Array = []) -> PanelContainer:
	var panel := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color.WHITE
	st.border_color = Color(0.70, 0.82, 0.71)
	st.set_border_width_all(2)
	st.set_corner_radius_all(10)
	st.content_margin_left = 12.0
	st.content_margin_right = 12.0
	st.content_margin_top = 6.0
	st.content_margin_bottom = 6.0
	panel.add_theme_stylebox_override("panel", st)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var icon := TextureRect.new()
	icon.texture = _check_badge
	icon.custom_minimum_size = Vector2(32, 32)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)

	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	col.add_theme_constant_override("separation", 1)

	var l_title := Label.new()
	l_title.text = GameState.format_text(title)
	l_title.add_theme_font_size_override("font_size", 19)
	l_title.add_theme_color_override("font_color", title_col)
	col.add_child(l_title)

	var l_sub := Label.new()
	l_sub.text = GameState.format_text(subtitle)
	l_sub.add_theme_font_size_override("font_size", 16)
	l_sub.add_theme_color_override("font_color", Color(0.24, 0.32, 0.26))
	col.add_child(l_sub)

	row.add_child(col)

	for p_var in thumb_paths:
		var p_str := str(p_var)
		var tex := _load_texture(p_str)
		if tex != null:
			var t_frame := PanelContainer.new()
			var tst := StyleBoxFlat.new()
			tst.bg_color = Color(0.95, 0.98, 0.95)
			tst.border_color = Color(0.55, 0.74, 0.58)
			tst.set_border_width_all(1)
			tst.set_corner_radius_all(6)
			tst.content_margin_left = 2.0
			tst.content_margin_right = 2.0
			tst.content_margin_top = 2.0
			tst.content_margin_bottom = 2.0
			t_frame.add_theme_stylebox_override("panel", tst)
			t_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER

			var tr := TextureRect.new()
			tr.texture = tex
			tr.custom_minimum_size = Vector2(54, 34)
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
			t_frame.add_child(tr)
			row.add_child(t_frame)

	panel.add_child(row)
	return panel


# ---------------------------------------------- Visão do Professor (Histórico)

func _refresh_teacher_report() -> void:
	for ch in session_cards_vbox.get_children():
		ch.queue_free()

	var total_sessions := GameData.history.size()
	if total_sessions == 0:
		kpi_sessions_val.text = GameState.format_text("0 sessões")
		kpi_p1_val.text = "--"
		kpi_p2_val.text = "--"

		var empty_lbl := Label.new()
		empty_lbl.text = GameState.format_text(
			"Nenhuma partida concluída foi registrada ainda.\nQuando um aluno concluir as duas fases, o registro completo (nome, data, tempos, dicas usadas e erros por animal) aparecerá aqui e poderá ser exportado em PDF."
		)
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		empty_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_lbl.add_theme_font_size_override("font_size", 22)
		session_cards_vbox.add_child(empty_lbl)
		return

	var sum_p1_percent := 0.0
	var sum_p2_errors := 0
	for entry_var in GameData.history:
		var entry: Dictionary = entry_var
		var p1: Dictionary = entry.get("phase1_result", {})
		var p2: Dictionary = entry.get("phase2_result", {})
		sum_p1_percent += float(p1.get("percent", 0.0))
		sum_p2_errors += int(p2.get("total_errors", 0))

	var avg_p1 := roundi(sum_p1_percent / total_sessions)
	var avg_p2_str := ("%.1f" % (float(sum_p2_errors) / total_sessions)).replace(".", ",")

	kpi_sessions_val.text = GameState.format_text("%d %s" % [total_sessions, "sessão" if total_sessions == 1 else "sessões"])
	kpi_p1_val.text = GameState.format_text("%d%% de acerto" % avg_p1)
	kpi_p2_val.text = GameState.format_text("%s por partida" % avg_p2_str)

	for idx in range(total_sessions - 1, -1, -1):
		var entry: Dictionary = GameData.history[idx]
		session_cards_vbox.add_child(_make_session_card(idx + 1, entry))


func _make_session_card(num: int, entry: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	var st := StyleBoxFlat.new()
	st.bg_color = Color.WHITE
	st.border_color = Color(0.60, 0.76, 0.62)
	st.set_border_width_all(2)
	st.set_corner_radius_all(12)
	st.content_margin_left = 14.0
	st.content_margin_right = 14.0
	st.content_margin_top = 10.0
	st.content_margin_bottom = 12.0
	card.add_theme_stylebox_override("panel", st)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	# Faixa de cabeçalho da sessão
	var hdr_panel := PanelContainer.new()
	var hdr_st := StyleBoxFlat.new()
	hdr_st.bg_color = Color(0.886, 0.949, 0.894)
	hdr_st.set_corner_radius_all(8)
	hdr_st.content_margin_left = 12.0
	hdr_st.content_margin_right = 12.0
	hdr_st.content_margin_top = 6.0
	hdr_st.content_margin_bottom = 6.0
	hdr_panel.add_theme_stylebox_override("panel", hdr_st)

	var s_name := str(entry.get("player_name", "Aluno"))
	var s_date := _format_datetime(str(entry.get("timestamp", "")))
	var s_time := _format_time(float(entry.get("total_seconds", 0.0)))
	var p1_hdr: Dictionary = entry.get("phase1_result", {})
	var p2_hdr: Dictionary = entry.get("phase2_result", {})
	var tot_stars := GameState.calc_phase1_stars(p1_hdr) + GameState.calc_phase2_stars(p2_hdr)

	var hdr_lbl := Label.new()
	hdr_lbl.text = GameState.format_text("[#%d] Aluno: %s   |   Data: %s   |   Tempo: %s   |   Estrelas: %d/6" % [num, s_name, s_date, s_time, tot_stars])
	hdr_lbl.add_theme_font_size_override("font_size", 18)
	hdr_lbl.add_theme_color_override("font_color", Color(0.106, 0.369, 0.125))
	hdr_panel.add_child(hdr_lbl)
	vbox.add_child(hdr_panel)

	# Duas colunas lado a lado: Fase 1 e Fase 2
	var cols := HBoxContainer.new()
	cols.add_theme_constant_override("separation", 20)

	var p1: Dictionary = entry.get("phase1_result", {})
	var by_cat: Dictionary = p1.get("by_category", {})
	var col1_text := "Fase 1 (Quiz): %d de %d de primeira (%d%%)\nErros: %d  |  Dicas usadas: %d  |  Tempo: %s\nFauna: %s  •  Flora: %s  •  Conservação: %s" % [
		int(p1.get("hits", 0)), int(p1.get("total", 0)), int(p1.get("percent", 0)),
		int(p1.get("misses", 0)), int(p1.get("hints_used", 0)),
		_format_time(float(p1.get("time_seconds", 0.0))),
		_cat_pair(by_cat, "fauna"), _cat_pair(by_cat, "flora"), _cat_pair(by_cat, "conservacao")
	]
	var lbl1 := Label.new()
	lbl1.text = GameState.format_text(col1_text)
	lbl1.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl1.add_theme_font_size_override("font_size", 17)
	lbl1.add_theme_constant_override("line_spacing", 4)
	cols.add_child(lbl1)

	var p2: Dictionary = entry.get("phase2_result", {})
	var ex_parts: Array[String] = []
	for ex_var in p2.get("exercises", []):
		var ex: Dictionary = ex_var
		var errs := int(ex.get("errors", 0))
		var mode_str := str(ex.get("input_mode", ""))
		var mode_suffix := (", " + mode_str) if mode_str != "" else ""
		ex_parts.append("%s (%s, %d %s%s)" % [
			str(ex.get("name", "")),
			_format_time(float(ex.get("time_seconds", 0.0))),
			errs,
			"erro" if errs == 1 else "erros",
			mode_suffix
		])
	var p2_err_total := int(p2.get("total_errors", 0))
	var p2_hints := int(p2.get("hints_used", 0))
	var motor_line := _format_motor_summary(p2)
	var col2_text := "Fase 2 (Classificação): %d %s  |  %d %s\n%s\n%s" % [
		p2_err_total, "erro" if p2_err_total == 1 else "erros",
		p2_hints, "dica usada" if p2_hints == 1 else "dicas usadas",
		motor_line,
		" • ".join(ex_parts)
	]
	var lbl2 := Label.new()
	lbl2.text = GameState.format_text(col2_text)
	lbl2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl2.add_theme_font_size_override("font_size", 17)
	lbl2.add_theme_constant_override("line_spacing", 4)
	cols.add_child(lbl2)

	vbox.add_child(cols)
	card.add_child(vbox)
	return card


func _format_motor_summary(p2: Dictionary) -> String:
	if not p2.has("motor_summary") or typeof(p2["motor_summary"]) != TYPE_DICTIONARY:
		return "Coordenação motora: não registrada (partida anterior)"
	var ms: Dictionary = p2["motor_summary"]
	var n_drag := int(ms.get("arraste", 0))
	var n_click := int(ms.get("clique", 0))
	var n_key := int(ms.get("teclado", 0))
	var parts: Array[String] = ["%d por arraste" % n_drag, "%d por clique" % n_click]
	if n_key > 0:
		parts.append("%d por teclado" % n_key)
	return "Coordenação motora: " + ", ".join(parts)


func _cat_pair(by_cat: Dictionary, key: String) -> String:
	if not by_cat.has(key):
		return "--"
	var d: Dictionary = by_cat[key]
	return "%d/%d" % [int(d.get("hits", 0)), int(d.get("total", 0))]


func _format_datetime(iso_str: String) -> String:
	if iso_str.length() >= 16 and iso_str.substr(4, 1) == "-":
		return "%s/%s/%s às %s" % [iso_str.substr(8, 2), iso_str.substr(5, 2), iso_str.substr(0, 4), iso_str.substr(11, 5)]
	return iso_str


func _format_time(seconds: float) -> String:
	if roundi(seconds * 10.0) < 600:
		return ("%.1f s" % seconds).replace(".", ",")
	var whole: int = roundi(seconds)
	var minutes: int = floori(whole / 60.0)
	return "%d min %02d s" % [minutes, whole - minutes * 60]


func _make_check_badge() -> ImageTexture:
	var sz := 36
	var center := (sz - 1) / 2.0
	var radius := 16.5
	var bg_col := Color(0.180, 0.490, 0.196)
	var segments := [[Vector2(10, 19), Vector2(16, 25)], [Vector2(16, 25), Vector2(27, 12)]]

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
			var sym_a := clampf(2.2 - dist_seg, 0.0, 1.0)
			var col := bg_col.lerp(Color.WHITE, sym_a)
			img.set_pixel(x, y, Color(col.r, col.g, col.b, circle_a))
	return ImageTexture.create_from_image(img)


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
