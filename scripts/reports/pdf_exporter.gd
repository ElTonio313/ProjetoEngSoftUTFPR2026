extends RefCounted
## Gerador nativo de arquivo PDF (100% offline, sem dependências externas) para o
## Relatório Pedagógico do jogo "Aventuras no Pantanal".

const PAGE_W := 595.0
const PAGE_H := 842.0
const MARGIN_X := 42.0


static func get_default_dir() -> String:
	var docs_dir := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if docs_dir != "" and DirAccess.dir_exists_absolute(docs_dir):
		return docs_dir
	var desk_dir := OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP)
	if desk_dir != "" and DirAccess.dir_exists_absolute(desk_dir):
		return desk_dir
	return ProjectSettings.globalize_path("user://")


static func get_default_filename() -> String:
	var stamp := Time.get_datetime_string_from_system(false, false).substr(0, 10)
	return "Relatorio_Aventuras_no_Pantanal_%s.pdf" % stamp


static func export_teacher_report_to_path(history: Array, target_path: String) -> String:
	var final_path := target_path
	if not final_path.to_lower().ends_with(".pdf"):
		final_path += ".pdf"

	var pages_cmds: Array[String] = _build_pages(history)
	var pdf_bytes := _assemble_pdf(pages_cmds)

	var file := FileAccess.open(final_path, FileAccess.WRITE)
	if file == null:
		return ""

	file.store_buffer(pdf_bytes)
	file.close()
	return final_path


static func export_teacher_report(history: Array) -> String:
	var out_path := get_default_dir().path_join(get_default_filename())
	return export_teacher_report_to_path(history, out_path)


static func _build_pages(history: Array) -> Array[String]:
	var pages: Array[String] = []
	var cmds := ""
	var y := PAGE_H - 42.0

	# Cabeçalho institucional na primeira página
	cmds += _rect_fill(MARGIN_X, y - 58.0, PAGE_W - 2.0 * MARGIN_X, 58.0, 0.11, 0.37, 0.13)
	cmds += _text("AVENTURAS NO PANTANAL - RELATÓRIO PEDAGÓGICO", MARGIN_X + 16.0, y - 24.0, 15, true, 1.0, 1.0, 1.0)
	cmds += _text("UTFPR Ponta Grossa  |  Estudo de Caso ASSARTE  |  ODS 15 (Vida na Terra)", MARGIN_X + 16.0, y - 44.0, 10, false, 0.90, 0.96, 0.90)
	y -= 74.0

	var generated_at := Time.get_datetime_string_from_system(false, true)
	cmds += _text("Gerado em: " + _format_datetime(generated_at), MARGIN_X, y, 10, false, 0.30, 0.35, 0.30)
	y -= 20.0

	if history.is_empty():
		cmds += _rect_fill_stroke(MARGIN_X, y - 50.0, PAGE_W - 2.0 * MARGIN_X, 50.0, 0.96, 0.98, 0.96, 0.65, 0.80, 0.66)
		cmds += _text("Nenhuma partida concluída foi registrada até o momento.", MARGIN_X + 14.0, y - 28.0, 11, false, 0.15, 0.20, 0.15)
		pages.append(cmds)
		return pages

	var total_sessions := history.size()
	var sum_p1 := 0.0
	var sum_p2_err := 0
	for item in history:
		var entry: Dictionary = item
		var p1: Dictionary = entry.get("phase1_result", {})
		var p2: Dictionary = entry.get("phase2_result", {})
		sum_p1 += float(p1.get("percent", 0.0))
		sum_p2_err += int(p2.get("total_errors", 0))

	var avg_p1 := roundi(sum_p1 / total_sessions)
	var avg_p2 := ("%.1f" % (float(sum_p2_err) / total_sessions)).replace(".", ",")

	cmds += _rect_fill_stroke(MARGIN_X, y - 44.0, PAGE_W - 2.0 * MARGIN_X, 44.0, 0.92, 0.96, 0.92, 0.35, 0.62, 0.38)
	var summary_line := "RESUMO DA TURMA:  %d %s  |  Média Fase 1 (de 1a): %d%%  |  Média erros Fase 2: %s" % [
		total_sessions,
		"partida concluída" if total_sessions == 1 else "partidas concluídas",
		avg_p1,
		avg_p2
	]
	cmds += _text(summary_line, MARGIN_X + 12.0, y - 26.0, 9.5, true, 0.10, 0.35, 0.12)
	y -= 62.0

	for idx in range(total_sessions - 1, -1, -1):
		var card_h := 132.0
		if y - card_h < 48.0:
			pages.append(cmds)
			cmds = ""
			y = PAGE_H - 46.0
			cmds += _text("AVENTURAS NO PANTANAL - HISTÓRICO DE ALUNOS (CONTINUAÇÃO)", MARGIN_X, y, 11, true, 0.11, 0.37, 0.13)
			y -= 22.0

		var entry: Dictionary = history[idx]
		var s_name := str(entry.get("player_name", "Aluno")).to_upper()
		var s_date := _format_datetime(str(entry.get("timestamp", "")))
		var s_time := _format_time(float(entry.get("total_seconds", 0.0)))
		var p1: Dictionary = entry.get("phase1_result", {})
		var p2: Dictionary = entry.get("phase2_result", {})
		var tot_stars := _calc_p1_stars(p1) + _calc_p2_stars(p2)

		cmds += _rect_fill_stroke(MARGIN_X, y - card_h, PAGE_W - 2.0 * MARGIN_X, card_h, 0.99, 0.99, 0.98, 0.62, 0.78, 0.64)
		cmds += _rect_fill(MARGIN_X + 1.0, y - 24.0, PAGE_W - 2.0 * MARGIN_X - 2.0, 23.0, 0.88, 0.94, 0.89)

		var hdr := "[#%d] ALUNO: %s   |   DATA: %s   |   TEMPO: %s   |   ESTRELAS: %d/6" % [idx + 1, s_name, s_date, s_time, tot_stars]
		cmds += _text(hdr, MARGIN_X + 10.0, y - 16.0, 9.6, true, 0.09, 0.34, 0.12)

		var by_cat: Dictionary = p1.get("by_category", {})
		var cat_fauna := _cat_pair(by_cat, "fauna")
		var cat_flora := _cat_pair(by_cat, "flora")
		var cat_cons := _cat_pair(by_cat, "conservacao")

		var p1_l1 := "FASE 1 (QUIZ): %d de %d de primeira (%d%%)  |  Erros: %d  |  Dicas: %d  |  Tempo: %s" % [
			int(p1.get("hits", 0)), int(p1.get("total", 0)), int(p1.get("percent", 0)),
			int(p1.get("misses", 0)), int(p1.get("hints_used", 0)),
			_format_time(float(p1.get("time_seconds", 0.0)))
		]
		var p1_l2 := "   Categorias -> Fauna: %s  |  Flora: %s  |  Conservação (ODS 15): %s" % [cat_fauna, cat_flora, cat_cons]

		var p2_hints: int = int(p2.get("hints_used", 0))
		var p2_l1 := "FASE 2 (CLASSIFICAÇÃO): Total de erros: %d  |  Dicas usadas: %d" % [
			int(p2.get("total_errors", 0)), p2_hints
		]
		var p2_motor := "   Coordenação motora (periféricos) -> " + _format_motor_pdf(p2)

		var ex_items: Array[String] = []
		for ex_var in p2.get("exercises", []):
			var ex: Dictionary = ex_var
			var mode_str := str(ex.get("input_mode", ""))
			var mode_suffix := (", " + mode_str) if mode_str != "" else ""
			ex_items.append("%s (%s, %d %s%s)" % [
				str(ex.get("name", "")),
				_format_time(float(ex.get("time_seconds", 0.0))),
				int(ex.get("errors", 0)),
				"erro" if int(ex.get("errors", 0)) == 1 else "erros",
				mode_suffix
			])

		var p2_l2 := "   Animais -> Sem detalhes"
		var p2_l3 := ""
		if ex_items.size() > 3:
			p2_l2 = "   Animais -> " + ", ".join(ex_items.slice(0, 3))
			p2_l3 = "              " + ", ".join(ex_items.slice(3))
		elif not ex_items.is_empty():
			p2_l2 = "   Animais -> " + ", ".join(ex_items)

		cmds += _text(p1_l1, MARGIN_X + 10.0, y - 38.0, 9.2, true, 0.12, 0.16, 0.13)
		cmds += _text(p1_l2, MARGIN_X + 10.0, y - 51.0, 8.8, false, 0.22, 0.28, 0.23)
		cmds += _text(p2_l1, MARGIN_X + 10.0, y - 69.0, 9.2, true, 0.12, 0.16, 0.13)
		cmds += _text(p2_motor, MARGIN_X + 10.0, y - 82.0, 8.8, false, 0.11, 0.35, 0.14)
		cmds += _text(p2_l2, MARGIN_X + 10.0, y - 96.0, 8.3, false, 0.22, 0.28, 0.23)
		if p2_l3 != "":
			cmds += _text(p2_l3, MARGIN_X + 10.0, y - 109.0, 8.3, false, 0.22, 0.28, 0.23)

		y -= (card_h + 12.0)

	pages.append(cmds)
	return pages


static func _assemble_pdf(pages_cmds: Array[String]) -> PackedByteArray:
	var num_pages := pages_cmds.size()
	var total_objs := 4 + num_pages * 2
	var offsets: Array[int] = []
	offsets.resize(total_objs + 1)

	var out := PackedByteArray()
	out.append_array("%PDF-1.4\n".to_ascii_buffer())

	offsets[1] = out.size()
	out.append_array("1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n".to_ascii_buffer())

	var kids: Array[String] = []
	for i in num_pages:
		kids.append("%d 0 R" % (5 + i * 2))
	offsets[2] = out.size()
	out.append_array(("2 0 obj\n<< /Type /Pages /Kids [%s] /Count %d >>\nendobj\n" % [" ".join(kids), num_pages]).to_ascii_buffer())

	offsets[3] = out.size()
	out.append_array("3 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>\nendobj\n".to_ascii_buffer())

	offsets[4] = out.size()
	out.append_array("4 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold /Encoding /WinAnsiEncoding >>\nendobj\n".to_ascii_buffer())

	for i in num_pages:
		var page_obj_id := 5 + i * 2
		var content_obj_id := 6 + i * 2
		var stream_bytes := _to_win_ansi_bytes(pages_cmds[i])

		offsets[page_obj_id] = out.size()
		var page_str := "%d 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Resources << /Font << /F1 3 0 R /F2 4 0 R >> >> /Contents %d 0 R >>\nendobj\n" % [
			page_obj_id, content_obj_id
		]
		out.append_array(page_str.to_ascii_buffer())

		offsets[content_obj_id] = out.size()
		out.append_array(("%d 0 obj\n<< /Length %d >>\nstream\n" % [content_obj_id, stream_bytes.size()]).to_ascii_buffer())
		out.append_array(stream_bytes)
		out.append_array("\nendstream\nendobj\n".to_ascii_buffer())

	var xref_pos := out.size()
	out.append_array(("xref\n0 %d\n0000000000 65535 f \n" % (total_objs + 1)).to_ascii_buffer())
	for obj_id in range(1, total_objs + 1):
		out.append_array(("%010d 00000 n \n" % offsets[obj_id]).to_ascii_buffer())

	out.append_array(("trailer\n<< /Size %d /Root 1 0 R >>\nstartxref\n%d\n%%%%EOF\n" % [total_objs + 1, xref_pos]).to_ascii_buffer())
	return out


## Converte texto Unicode (incluindo acentos do português Á, É, Í, Ó, Ú, Ã, Õ, Ç, etc.)
## diretamente para bytes ISO-8859-1 / WinAnsi compatíveis com o padrão PDF 1.4.
static func _to_win_ansi_bytes(s: String) -> PackedByteArray:
	var clean := _sanitize_latin1(s)
	var buf := PackedByteArray()
	buf.resize(clean.length())
	for i in clean.length():
		var code := clean.unicode_at(i)
		buf[i] = code if code <= 255 else 63
	return buf


static func _rect_fill(x: float, y: float, w: float, h: float, r: float, g: float, b: float) -> String:
	return "q %.2f %.2f %.2f rg %.1f %.1f %.1f %.1f re f Q\n" % [r, g, b, x, y, w, h]


static func _rect_fill_stroke(x: float, y: float, w: float, h: float, fr: float, fg: float, fb: float, sr: float, sg: float, sb: float) -> String:
	return "q %.2f %.2f %.2f rg %.2f %.2f %.2f RG 1 w %.1f %.1f %.1f %.1f re B Q\n" % [fr, fg, fb, sr, sg, sb, x, y, w, h]


static func _text(txt: String, x: float, y: float, size: float, bold: bool, r: float, g: float, b: float) -> String:
	var font_tag := "/F2" if bold else "/F1"
	var escaped := _sanitize_latin1(txt).replace("\\", "\\\\").replace("(", "\\(").replace(")", "\\)")
	return "BT %s %.1f Tf %.2f %.2f %.2f rg %.1f %.1f Td (%s) Tj ET\n" % [font_tag, size, r, g, b, x, y, escaped]


static func _sanitize_latin1(s: String) -> String:
	return s.replace("—", "-").replace("–", "-").replace("•", "-").replace("✔", "[OK]").replace("✘", "[X]")


static func _cat_pair(by_cat: Dictionary, key: String) -> String:
	if not by_cat.has(key):
		return "--"
	var d: Dictionary = by_cat[key]
	return "%d/%d" % [int(d.get("hits", 0)), int(d.get("total", 0))]


static func _format_motor_pdf(p2: Dictionary) -> String:
	if not p2.has("motor_summary") or typeof(p2["motor_summary"]) != TYPE_DICTIONARY:
		return "não registrada (partida anterior)"
	var ms: Dictionary = p2["motor_summary"]
	var n_drag := int(ms.get("arraste", 0))
	var n_click := int(ms.get("clique", 0))
	var n_key := int(ms.get("teclado", 0))
	var parts: Array[String] = ["%d por arraste" % n_drag, "%d por clique" % n_click]
	if n_key > 0:
		parts.append("%d por teclado" % n_key)
	return ", ".join(parts)


static func _calc_p1_stars(p1: Dictionary) -> int:
	if p1.is_empty():
		return 0
	var pct := float(p1.get("percent", 0.0))
	if pct >= 80.0:
		return 3
	if pct >= 40.0:
		return 2
	return 1


static func _calc_p2_stars(p2: Dictionary) -> int:
	if p2.is_empty():
		return 0
	var errs := int(p2.get("total_errors", 0))
	if errs <= 1:
		return 3
	if errs <= 4:
		return 2
	return 1


static func _format_datetime(iso_str: String) -> String:
	if iso_str.length() >= 16 and iso_str.substr(4, 1) == "-":
		var yr := iso_str.substr(0, 4)
		var mo := iso_str.substr(5, 2)
		var dy := iso_str.substr(8, 2)
		var hm := iso_str.substr(11, 5)
		return "%s/%s/%s às %s" % [dy, mo, yr, hm]
	return iso_str


static func _format_time(seconds: float) -> String:
	if roundi(seconds * 10.0) < 600:
		return ("%.1f s" % seconds).replace(".", ",")
	var whole: int = roundi(seconds)
	var minutes: int = floori(whole / 60.0)
	return "%d min %02d s" % [minutes, whole - minutes * 60]
