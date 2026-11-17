class_name Animal
extends RefCounted

const VALID_CATEGORIES := ["mamifero", "reptil", "ave"]

var id: String = ""
var display_name: String = ""   # texto mostrado ao aluno
var category: String = ""       # um item de VALID_CATEGORIES
var hint: String = ""           # dica mostrada quando o aluno erra
var image_path: String = ""     # vazio = a tela mostra só o nome

## Cria um Animal a partir de um Dictionary (um item do JSON).
## Devolve null se os dados forem inválidos (e explica o motivo no painel de erros).
static func from_dict(data: Dictionary) -> Animal:
	for key in ["id", "name", "category", "hint"]:
		if not data.has(key) or str(data[key]).strip_edges().is_empty():
			push_error("Animal inválido: falta o campo '%s'." % key)
			return null

	var category_value := str(data["category"])
	if not VALID_CATEGORIES.has(category_value):
		push_error("Animal '%s' inválido: categoria '%s' não existe (use %s)." % [
			data["id"], category_value, ", ".join(VALID_CATEGORIES)
		])
		return null

	var animal := Animal.new()
	animal.id = str(data["id"])
	animal.display_name = str(data["name"])
	animal.category = category_value
	animal.hint = str(data["hint"])
	animal.image_path = str(data.get("image_path", ""))
	return animal

## Lê o arquivo JSON e devolve a lista de animais válidos, na ordem do arquivo.
static func load_from_file(path: String) -> Array[Animal]:
	var result: Array[Animal] = []

	if not FileAccess.file_exists(path):
		push_error("Arquivo de animais não encontrado: %s" % path)
		return result

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("Não foi possível abrir %s (erro %d)." % [path, FileAccess.get_open_error()])
		return result

	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or not parsed.has("animals"):
		push_error("JSON inválido em %s: esperado { \"animals\": [...] }." % path)
		return result

	for item in parsed["animals"]:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var animal := from_dict(item)
		if animal != null:
			result.append(animal)
	return result
