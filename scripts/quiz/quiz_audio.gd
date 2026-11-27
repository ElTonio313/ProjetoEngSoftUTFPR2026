class_name QuizAudio
extends RefCounted
## Caminhos dos áudios da Fase 1 (convenção: pasta = id da pergunta).

const DIR := "res://assets/audio/narration/phase1/"
const ACCENTS := {
	"á": "a", "à": "a", "â": "a", "ã": "a", "ä": "a",
	"é": "e", "è": "e", "ê": "e", "ë": "e",
	"í": "i", "ì": "i", "î": "i", "ï": "i",
	"ó": "o", "ò": "o", "ô": "o", "õ": "o", "ö": "o",
	"ú": "u", "ù": "u", "û": "u", "ü": "u",
	"ç": "c",
}


static func question_path(q: Question) -> String:
	return "%s%s/%s.ogg" % [DIR, q.id, q.id]


static func feedback_path(q: Question) -> String:
	return "%s%s/%sFeedback.ogg" % [DIR, q.id, q.id]


static func hint_path(q: Question) -> String:
	return "%s%s/%sHint.ogg" % [DIR, q.id, q.id]


## "Tuiuiú" -> .../opt Tuiuiu.ogg (sem acento, 1ª letra maiúscula). Use alternativas de uma palavra.
static func option_path(q: Question, option_text: String) -> String:
	var word := option_text.strip_edges().to_lower()
	for accented in ACCENTS:
		word = word.replace(accented, ACCENTS[accented])
	return "%s%s/opt%s.ogg" % [DIR, q.id, word.substr(0, 1).to_upper() + word.substr(1)]
