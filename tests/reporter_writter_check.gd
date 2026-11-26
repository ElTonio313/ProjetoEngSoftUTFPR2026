@tool
extends EditorScript
## Mostra o relatório com dados de exemplo. Com este script aberto: Arquivo > Executar (Ctrl+Shift+X).

func _run() -> void:
	var now := {"year": 2026, "month": 11, "day": 25, "hour": 21, "minute": 40, "second": 12}
	var p1 := {"hits": 3, "misses": 2, "total": 5, "percent": 60, "hints_used": 1, "time_seconds": 125.0,
		"by_category": {"fauna": {"hits": 2, "total": 3}, "flora": {"hits": 0, "total": 1},
				"conservacao": {"hits": 1, "total": 1}}}
	var p2 := {"total": 2, "total_errors": 2, "exercises": [
		{"id": "capivara", "name": "Capivara", "time_seconds": 4.3, "errors": 0},
		{"id": "jacare", "name": "Jacaré", "time_seconds": 12.0, "errors": 2}]}
	print(ReportWriter.build_text("Ana", now, 372.0, p1, p2))
	print("Nome limpo: ", ReportWriter._safe_name("  A/n:a?  "))
	print("Tempos: ", ReportWriter.format_time(4.3), " | ", ReportWriter.format_time(59.96), " | ", ReportWriter.format_time(65.0))
