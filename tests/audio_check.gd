@tool
extends EditorScript
## Lista os áudios que faltam. Com este script aberto: Arquivo > Executar (Ctrl+Shift+X).

func _run() -> void:
	var total := 0
	var missing := 0

	for q in Question.load_from_file("res://data/questions.json"):
		var paths: Array[String] = [QuizAudio.question_path(q), QuizAudio.feedback_path(q)]
		if q.hint != "":
			paths.append(QuizAudio.hint_path(q))
		for option in q.options:
			paths.append(QuizAudio.option_path(q, option))
		for path in paths:
			total += 1
			if not ResourceLoader.exists(path):
				missing += 1
				print("FALTA: ", path)

	var intro = JSON.parse_string(FileAccess.get_file_as_string("res://data/intro.json"))
	var intro_paths: Array[String] = [str(intro.get("title_audio", ""))]
	for page in intro["pages"]:
		intro_paths.append(str(page.get("audio_path", "")))
	for path in intro_paths:
		total += 1
		if not ResourceLoader.exists(path):
			missing += 1
			print("FALTA: ", path)

	print("Fase 1 e introdução: %d de %d áudios encontrados." % [total - missing, total])
