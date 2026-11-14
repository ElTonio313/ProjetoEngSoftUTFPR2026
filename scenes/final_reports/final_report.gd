extends Control
## Relatório final: le os dados do GameState e GameData.

const CATEGORY_NAMES := {
	"fauna": "Fauna",
	"flora": "Flora",
	"conservacao": "Conservação",
}

@onready var title_label: Label = %TitleLabel
@onready var total_time_label: Label = %TotalTimeLabel
@onready var phase1_summary: Label = %Phase1Summary
@onready var phase1_time: Label = %Phase1Time
@onready var phase1_categories: Label = %Phase1Categories
@onready var phase2_summary: Label = %Phase2Summary
@onready var phase2_errors: Label = %Phase2Errors
@onready var phase2_exercises: Label = %Phase2Exercises
@onready var back_button: Button = %BackButton


func _ready() -> void:
	var player_name: String = GameState.player_name
	title_label.text = "Parabéns, %s!" % player_name if player_name != "" else "Parabéns!"

	if GameState.has_total_time():
		var total: float = GameState.get_total_seconds()
		total_time_label.text = "Tempo total: " + _format_time(total)
	else:
		total_time_label.text = "Tempo total: não disponível"

	_show_phase1(GameData.phase1_result)
	_show_phase2(GameData.phase2_result)

	back_button.pressed.connect(_on_back_pressed)
	back_button.grab_focus()


func _on_back_pressed() -> void:
	GameState.go_to_main_menu()


func _show_phase1(result: Dictionary) -> void:
	if result.is_empty():
		phase1_summary.text = "Resultado não disponível."
		phase1_time.text = ""
		phase1_categories.text = ""
		return

	phase1_summary.text = "Acertos: %d de %d" % [int(result["hits"]), int(result["total"])]
	phase1_time.text = "Tempo: " + _format_time(float(result["time_seconds"]))

	var lines: Array[String] = []
	var by_category: Dictionary = result.get("by_category", {})
	for category in by_category:
		var data: Dictionary = by_category[category]
		var nice_name: String = CATEGORY_NAMES.get(category, str(category).capitalize())
		lines.append("%s: %d de %d" % [nice_name, int(data["hits"]), int(data["total"])])
	phase1_categories.text = "\n".join(lines)


func _show_phase2(result: Dictionary) -> void:
	if result.is_empty():
		phase2_summary.text = "Resultado não disponível."
		phase2_errors.text = ""
		phase2_exercises.text = ""
		return

	var exercises: Array = result.get("exercises", [])
	phase2_summary.text = "Animais classificados: %d de %d" % [exercises.size(), int(result["total"])]
	phase2_errors.text = "Erros: %d" % int(result["total_errors"])

	var lines: Array[String] = []
	for item in exercises:
		var exercise: Dictionary = item
		var errors: int = int(exercise["errors"])
		var mark: String = "✔" if errors == 0 else "•"
		var time_text: String = _format_time(float(exercise["time_seconds"]))
		lines.append("%s %s: %s, %s" % [mark, exercise["name"], time_text, _errors_text(errors)])
	phase2_exercises.text = "\n".join(lines)


func _errors_text(count: int) -> String:
	if count == 0:
		return "sem erros"
	if count == 1:
		return "1 erro"
	return "%d erros" % count


## Menos de 1 minuto: "4,3 s". A partir de 1 minuto: "1 min 05 s".
func _format_time(seconds: float) -> String:
	if roundi(seconds * 10.0) < 600:
		return ("%.1f s" % seconds).replace(".", ",")
	var whole: int = roundi(seconds)
	var minutes: int = floori(whole / 60.0)
	return "%d min %02d s" % [minutes, whole - minutes * 60]
