extends Node
## Teste do Narrator. Rode com F6 e leia a aba "Saída".
## Usa os efeitos do Gabriel (assets/sounds) como áudio de teste.

var _falhas: int = 0
var _first_result = null   # guarda o resultado de uma fala que não foi aguardada


func _ready() -> void:
	var narrator := Narrator.new()
	add_child(narrator)
	var a: AudioStream = load("res://assets/sounds/correct.wav")
	var b: AudioStream = load("res://assets/sounds/wrong.wav")
	print("=== TESTE DO NARRATOR ===")

	var r1: bool = await narrator.say(a)
	_check(r1 == true, "áudio que termina sozinho devolve true")
	_check(not narrator.is_playing(), "depois de terminar, o narrador está livre")

	var r2: bool = await narrator.say(null)
	_check(r2 == true, "sem áudio devolve true (a sequência pode seguir)")

	_say_first(narrator, a)                      # começa a tocar, sem aguardar
	var r3: bool = await narrator.say(b)         # interrompe a anterior
	_check(_first_result == false, "um novo say() interrompe o anterior (devolve false)")
	_check(r3 == true, "a fala que interrompeu termina normalmente")

	_first_result = null
	_say_first(narrator, a)
	narrator.stop()
	_check(_first_result == false and not narrator.is_playing(), "stop() interrompe e libera o narrador")

	print("=== RESULTADO FINAL: %s ===" % ("TUDO CERTO" if _falhas == 0 else "%d FALHA(S)" % _falhas))


func _say_first(narrator: Narrator, stream: AudioStream) -> void:
	_first_result = await narrator.say(stream)


func _check(condicao: bool, descricao: String) -> void:
	if condicao:
		print("  OK     ", descricao)
	else:
		print("  FALHOU ", descricao)
		_falhas += 1
