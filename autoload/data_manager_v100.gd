extends "res://autoload/data_manager_v099.gd"

const JAVI_PIRATE_DAY_ID_0100 := 3
const JAVI_DAY3_MONITOR_HINT_0100 := {
	"speaker": "Javi",
	"speaker_id": "javi",
	"expression": "happy",
	"text": "Por cierto, hoy sí puedes cotillear un poco la habitación. Si algo parece interactivo, prueba. Los monitores tienen sorpresa."
}

const JAVI_PIRATE_STORY_INTRO_0100 := [
	{
		"speaker": "Narrador",
		"speaker_id": "",
		"text": "Hace muchos años, un joven llegó a una isla con un sueño."
	},
	{
		"speaker": "Narrador",
		"speaker_id": "",
		"text": "No tenía barco, ni tripulación, ni demasiada idea de lo que estaba haciendo, pero estaba convencido de que allí empezaría su aventura."
	},
	{
		"speaker": "Narrador",
		"speaker_id": "",
		"text": "Recorrió caminos, siguió mapas, escuchó historias de taberna y terminó haciéndose con una espada. Porque, al parecer, si uno quería abrirse paso por aquellas tierras, tarde o temprano iba a necesitar una."
	},
	{
		"speaker": "Narrador",
		"speaker_id": "",
		"text": "También compró una pala."
	},
	{
		"speaker": "Narrador",
		"speaker_id": "",
		"text": "Nunca se sabe cuándo vas a necesitar una pala."
	},
	{
		"speaker": "Narrador",
		"speaker_id": "",
		"text": "Pero aquella isla tenía una costumbre bastante peculiar."
	},
	{
		"speaker": "Narrador",
		"speaker_id": "",
		"text": "Cuando dos espadachines se cruzaban en un camino no bastaba con blandir el acero. Podías ser rápido, fuerte o manejar la espada como nadie... daba igual."
	},
	{
		"speaker": "Narrador",
		"speaker_id": "",
		"text": "Allí las peleas se ganaban de otra forma."
	}
]


func get_question_bundle(character_id: String) -> Dictionary:
	if character_id != "javi" or _legacy_contract() or not _runtime_day_enabled:
		return super.get_question_bundle(character_id)

	# 0.10.0: el minijuego de insultos deja de sustituir las preguntas de Javi
	# en todas las jornadas. Los días 1 y 2 recuperan su diálogo data-driven.
	if _runtime_day_id != JAVI_PIRATE_DAY_ID_0100:
		return _day_specific_bundle_0100(character_id)

	# En el Día 3 conservamos la pregunta aleatoria del pool que prepara v0.9.7,
	# pero sustituimos el aviso tutorial por una introducción narrativa.
	var bundle := super.get_question_bundle(character_id)
	var intro: Array = []
	for raw_line in JAVI_PIRATE_STORY_INTRO_0100:
		intro.append((raw_line as Dictionary).duplicate(true))
	bundle["intro"] = intro

	# La pista de los monitores sigue existiendo, pero se cuenta después del duelo
	# para que la historia desemboque directamente en el primer insulto.
	var raw_questions: Variant = bundle.get("questions", [])
	if typeof(raw_questions) == TYPE_ARRAY and not (raw_questions as Array).is_empty():
		var questions := (raw_questions as Array).duplicate(true)
		var raw_question: Variant = questions[0]
		if typeof(raw_question) == TYPE_DICTIONARY:
			var question := (raw_question as Dictionary).duplicate(true)
			var after: Array = []
			var raw_after: Variant = question.get("after", [])
			if typeof(raw_after) == TYPE_ARRAY:
				after = (raw_after as Array).duplicate(true)
			after.append(JAVI_DAY3_MONITOR_HINT_0100.duplicate(true))
			question["after"] = after
			questions[0] = question
			bundle["questions"] = questions
	return bundle


func _day_specific_bundle_0100(character_id: String) -> Dictionary:
	var raw_days: Variant = _day_dialogues.get("days", {})
	if typeof(raw_days) != TYPE_DICTIONARY:
		return super.get_question_bundle(character_id)
	var raw_day: Variant = (raw_days as Dictionary).get(str(_runtime_day_id), {})
	if typeof(raw_day) != TYPE_DICTIONARY:
		return super.get_question_bundle(character_id)
	var raw_bundle: Variant = (raw_day as Dictionary).get(character_id, {})
	if typeof(raw_bundle) != TYPE_DICTIONARY:
		return super.get_question_bundle(character_id)
	var bundle := (raw_bundle as Dictionary).duplicate(true)
	bundle["character"] = character_id
	if typeof(bundle.get("intro", [])) != TYPE_ARRAY:
		bundle["intro"] = []
	if typeof(bundle.get("questions", [])) != TYPE_ARRAY:
		bundle["questions"] = []
	return bundle
