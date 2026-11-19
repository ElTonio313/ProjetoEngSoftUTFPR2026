class_name Narrator
extends Node
## Toca narrações, UMA POR VEZ. Crie com Narrator.new() e adicione à cena
## com add_child(): ele vive e morre junto com a cena, então trocar de tela
## corta a fala sozinho.
##
##   var terminou: bool = await narrator.say(audio)
##     true  = a fala terminou (ou não havia áudio): a sequência pode seguir
##     false = outra fala ou stop() interrompeu esta: a sequência deve parar

## Emitido quando a fala atual acaba ou é interrompida.
signal _ended(completed: bool)

var _player := AudioStreamPlayer.new()
var _busy: bool = false   # há uma fala em andamento?


func _ready() -> void:
	_player.bus = &"Master"   # o mudo e o volume do AudioControls valem para a narração
	add_child(_player)
	_player.finished.connect(_on_player_finished)


## Toca o áudio, interrompendo qualquer fala em andamento.
func say(stream: AudioStream) -> bool:
	if not is_inside_tree():
		push_warning("Narrator: use add_child() antes de chamar say().")
		return false

	_interrupt()

	if stream == null:
		push_warning("Narrator: nenhum áudio definido.")
		return true   # sem áudio, a sequência segue normalmente

	_busy = true
	_player.stream = stream
	_player.play()
	var completed: bool = await _ended
	return completed


## Interrompe a fala atual (se houver).
func stop() -> void:
	_interrupt()


func is_playing() -> bool:
	return _busy


func _interrupt() -> void:
	if _busy:
		_busy = false
		_player.stop()
		_ended.emit(false)   # avisa quem estava esperando


func _on_player_finished() -> void:
	if _busy:
		_busy = false
		_ended.emit(true)
