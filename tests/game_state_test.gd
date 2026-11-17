extends Node
## Teste do relógio da atividade no GameState (sem interface).
## Rode esta cena com F6 e leia a aba "Saída".

var _falhas: int = 0


func _ready() -> void:
	print("=== TESTE DO RELÓGIO (GameState) ===")

	_check(not GameState.has_total_time(), "antes de começar, não há tempo total")

	GameState.finish_activity()
	_check(not GameState.has_total_time(), "finalizar sem ter começado é ignorado")

	GameState.start_activity()
	_check(not GameState.has_total_time(), "com a atividade em andamento, ainda não há tempo total")

	await get_tree().create_timer(0.3).timeout
	GameState.finish_activity()
	_check(GameState.has_total_time(), "depois de finalizar, há tempo total")

	var total : float = GameState.get_total_seconds()
	_check(total >= 0.25 and total < 1.0, "o tempo medido é coerente (veio %.2f s)" % total)

	await get_tree().create_timer(0.2).timeout
	GameState.finish_activity()
	_check(is_equal_approx(GameState.get_total_seconds(), total), "finalizar de novo não altera o tempo")

	GameState.start_activity()
	_check(not GameState.has_total_time(), "um novo início zera a medição")

	GameState.player_name = "Teste"
	GameState.start_activity()
	GameState.finish_activity()
	GameState.reset_session()
	_check(GameState.player_name == "" and not GameState.has_total_time(), "reset_session limpa o nome e o relógio")
	print("=== RESULTADO FINAL: %s ===" % ("TUDO CERTO" if _falhas == 0 else "%d FALHA(S)" % _falhas))


func _check(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  OK     ", descricao)
	else:
		print("  FALHOU ", descricao)
		_falhas += 1
