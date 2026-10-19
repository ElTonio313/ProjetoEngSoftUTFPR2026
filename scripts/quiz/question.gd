class_name Question
extends RefCounted
## Modelo de UMA pergunta do quiz.
## Também sabe carregar a lista de perguntas a partir do arquivo JSON
## (o colega da Fase 2 pode reaproveitar: Question.load_from_file(caminho)).

var text: String = ""
var options: Array[String] = []   # de 2 a 4 alternativas (palavras únicas)
var correct_index: int = 0        # posição da alternativa correta em "options"
var feedback: String = ""         # explicação mostrada depois da resposta
var category: String = ""         # "fauna", "flora", "conservacao"...
var video_path: String = ""       # vídeo-tutorial (res://assets/videos/...)
var image_path: String = ""       # imagem da pergunta (res://assets/images/...)


## Cria uma Question a partir de um Dictionary (um item do JSON).
## Retorna null se os dados forem inválidos (e mostra o motivo no painel de erros).
static func from_dict(data: Dictionary) -> Question:
	for key in ["text", "options", "correct_index", "feedback", "category"]:
		if not data.has(key):
			push_error("Pergunta inválida: falta o campo '%s'." % key)
			return null

	var raw_options = data["options"]
	if typeof(raw_options) != TYPE_ARRAY or raw_options.size() < 2 or raw_options.size() > 4:
		push_error("Pergunta inválida: 'options' deve ter de 2 a 4 alternativas.")
		return null

	var index := int(data["correct_index"])
	if index < 0 or index >= raw_options.size():
		push_error("Pergunta inválida: 'correct_index' fora do intervalo.")
		return null

	var q := Question.new()
	q.text = str(data["text"])
	for option in raw_options:
		q.options.append(str(option))
	q.correct_index = index
	q.feedback = str(data["feedback"])
	q.category = str(data["category"])
	q.video_path = str(data.get("video_path", ""))
	q.image_path = str(data.get("image_path", ""))
	return q


## Lê o arquivo JSON e devolve a lista de perguntas válidas.
static func load_from_file(path: String) -> Array[Question]:
	var result: Array[Question] = []

	if not FileAccess.file_exists(path):
		push_error("Arquivo de perguntas não encontrado: %s" % path)
		return result

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Não foi possível abrir %s (erro %d)." % [path, FileAccess.get_open_error()])
		return result

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("questions"):
		push_error("JSON inválido em %s: esperado { \"questions\": [...] }." % path)
		return result

	for item in parsed["questions"]:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var q := from_dict(item)
		if q != null:
			result.append(q)
	return result


## Embaralha a ordem das alternativas, sem perder qual é a correta.
func shuffle_options() -> void:
	var correct_text := options[correct_index]
	options.shuffle()
	correct_index = options.find(correct_text)
