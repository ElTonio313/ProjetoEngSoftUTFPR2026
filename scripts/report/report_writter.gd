class_name ReportWriter
extends RefCounted
## Gera o relatório do aluno em um arquivo .txt (um arquivo por aluno e partida).
## Pasta: Documentos/Relatorios_Jogo_Pantanal/
## Os dados vêm dos mesmos lugares que a tela final usa (GameState e GameData).

const FOLDER_NAME := "Relatorios_Jogo_Pantanal"
const CATEGORY_NAMES := {
	"fauna": "Fauna",
	"flora": "Flora",
	"conservacao": "Conservação",
}


## Salva o relatório da partida atual. Devolve o caminho do arquivo, ou "" se falhar.
## Nunca trava o jogo: em caso de erro, só avisa no painel de erros.
static func save_report() -> String:
	var now: Dictionary = Time.get_datetime_dict_from_system()
	var total_seconds: float = GameState.get_total_seconds() if GameState.has_total_time() else -1.0
	var text := build_text(GameState.player_name, now, total_seconds,
			GameData.phase1_result, GameData.phase2_result)

	var folder := _reports_folder()
	if folder == "":
		return ""
	var path := _unique_path(folder, GameState.player_name, now)
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("ReportWriter: não foi possível salvar %s (erro %d)." % [path, FileAccess.get_open_error()])
		return ""
	file.store_buffer(PackedByteArray([0xEF, 0xBB, 0xBF]))   # marca UTF-8: o Bloco de Notas mostra os acentos certos
	file.store_string(text)
	file.close()
	return path


## Monta o texto. Recebe os dados como argumentos (não lê nada global), então dá para testar sem gravar.
## total_seconds < 0 significa "tempo total não disponível".
static func build_text(player_name: String, now: Dictionary, total_seconds: float,
		p1: Dictionary, p2: Dictionary) -> String:
	var lines: Array[String] = []
	lines.append("RELATÓRIO DO ALUNO")
	lines.append("Nome: " + (player_name if player_name != "" else "(não informado)"))
	lines.append("Data: %02d/%02d/%04d, %02d:%02d" % [now["day"], now["month"], now["year"], now["hour"], now["minute"]])
	lines.append("Tempo total: " + (format_time(total_seconds) if total_seconds >= 0.0 else "não disponível"))
	lines.append("")

	lines.append("FASE 1: QUIZ")
	if p1.is_empty():
		lines.append("Resultado não disponível.")
	else:
		lines.append("Acertos de primeira: %d de %d (%d%%)" % [int(p1["hits"]), int(p1["total"]), int(p1["percent"])])
		lines.append("Tempo: " + format_time(float(p1["time_seconds"])))
		lines.append("Dicas usadas: %d" % int(p1.get("hints_used", 0)))
		var by_category: Dictionary = p1.get("by_category", {})
		for category in by_category:
			var data: Dictionary = by_category[category]
			var nice_name: String = CATEGORY_NAMES.get(category, str(category).capitalize())
			lines.append("  %s: %d de %d" % [nice_name, int(data["hits"]), int(data["total"])])
	lines.append("")

	lines.append("FASE 2: CLASSIFICAÇÃO")
	if p2.is_empty():
		lines.append("Resultado não disponível.")
	else:
		var exercises: Array = p2.get("exercises", [])
		lines.append("Animais classificados: %d de %d" % [exercises.size(), int(p2["total"])])
		lines.append("Erros: %d" % int(p2["total_errors"]))
		for item in exercises:
			var exercise: Dictionary = item
			lines.append("  %s: %s, %s" % [exercise["name"],
					format_time(float(exercise["time_seconds"])), _errors_text(int(exercise["errors"]))])

	return "\r\n".join(lines) + "\r\n"   # \r\n: quebra de linha que o Bloco de Notas de qualquer Windows entende


## Menos de 1 minuto: "4,3 s". A partir de 1 minuto: "1 min 05 s". (Mesma regra da tela final.)
static func format_time(seconds: float) -> String:
	if roundi(seconds * 10.0) < 600:
		return ("%.1f s" % seconds).replace(".", ",")
	var whole: int = roundi(seconds)
	var minutes: int = floori(whole / 60.0)
	return "%d min %02d s" % [minutes, whole - minutes * 60]


static func _errors_text(count: int) -> String:
	if count == 0:
		return "sem erros"
	if count == 1:
		return "1 erro"
	return "%d erros" % count


# Pasta "Documentos/Relatorios_Jogo_Pantanal". Cria se não existir.
static func _reports_folder() -> String:
	var base := OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
	if base == "":
		base = ProjectSettings.globalize_path("user://")   # plano B, se o Windows não informar Documentos
	var folder := base.path_join(FOLDER_NAME)
	if not DirAccess.dir_exists_absolute(folder):
		var error := DirAccess.make_dir_recursive_absolute(folder)
		if error != OK:
			push_error("ReportWriter: não foi possível criar a pasta %s (erro %d)." % [folder, error])
			return ""
	return folder


# Nome_AAAA-MM-DD_HH-MM-SS.txt. Se o arquivo já existir, acrescenta _2, _3... (nunca sobrescreve).
static func _unique_path(folder: String, player_name: String, now: Dictionary) -> String:
	var stamp := "%04d-%02d-%02d_%02d-%02d-%02d" % [now["year"], now["month"], now["day"],
			now["hour"], now["minute"], now["second"]]
	var base := "%s_%s" % [_safe_name(player_name), stamp]
	var path := folder.path_join(base + ".txt")
	var n := 2
	while FileAccess.file_exists(path):
		path = folder.path_join("%s_%d.txt" % [base, n])
		n += 1
	return path


# Tira os caracteres que o Windows não aceita em nome de arquivo.
static func _safe_name(raw: String) -> String:
	var result := raw.strip_edges()
	for bad in ["\\", "/", ":", "*", "?", "\"", "<", ">", "|"]:
		result = result.replace(bad, "")
	result = result.replace(" ", "_").rstrip(".")
	return result if result != "" else "aluno"
