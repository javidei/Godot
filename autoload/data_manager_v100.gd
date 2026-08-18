extends "res://autoload/data_manager_v099.gd"

const JAVI_PIRATE_DAY_ID_0927 := 3
const JAVI_DAY3_MONITOR_HINT_0927 := {
	"speaker": "Javi",
	"speaker_id": "javi",
	"expression": "happy",
	"text": "Por cierto, hoy sí puedes cotillear un poco la habitación. Si algo parece interactivo, prueba. Los monitores tienen sorpresa."
}

const JAVI_PIRATE_STORY_INTRO_0927 := [
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

var _runtime_javi_battle_configured_0927 := false
var _runtime_javi_battle_order_0927: Array[String] = []


func migrate_save_state(state: Dictionary) -> Dictionary:
	var result: Dictionary = super(state)
	if typeof(result.get("javi_insult_battle", null)) == TYPE_DICTIONARY:
		result["javi_insult_battle"] = _normalise_javi_battle_0927(result.get("javi_insult_battle", {}) as Dictionary)
	return result


func get_question_bundle(character_id: String) -> Dictionary:
	if character_id != "javi" or _legacy_contract() or not _runtime_day_enabled:
		return super.get_question_bundle(character_id)

	# El duelo especial se reserva al Día 3. Los días anteriores mantienen sus
	# preguntas normales de day_dialogues.json.
	if _runtime_day_id != JAVI_PIRATE_DAY_ID_0927:
		return _day_specific_bundle_0927(character_id)

	# Si un test histórico consulta el bundle sin preparar una visita, se conserva
	# el comportamiento anterior. En juego real el manager configura el orden antes
	# de reconstruir Story.
	if not _runtime_javi_battle_configured_0927:
		return super.get_question_bundle(character_id)

	var bundle := {
		"character": "javi",
		"intro": JAVI_PIRATE_STORY_INTRO_0927.duplicate(true),
		"questions": []
	}
	var ordered_questions: Array = []
	for question_id in _runtime_javi_battle_order_0927:
		var question := _javi_pool_question_by_id_0927(question_id)
		if not question.is_empty():
			ordered_questions.append(question)

	# El aviso de los monitores aparece al terminar el último insulto que quede en
	# esa sesión, no antes de la batalla.
	if not ordered_questions.is_empty():
		var last_index := ordered_questions.size() - 1
		var last_question := (ordered_questions[last_index] as Dictionary).duplicate(true)
		var after: Array = []
		var raw_after: Variant = last_question.get("after", [])
		if typeof(raw_after) == TYPE_ARRAY:
			after = (raw_after as Array).duplicate(true)
		after.append(JAVI_DAY3_MONITOR_HINT_0927.duplicate(true))
		last_question["after"] = after
		ordered_questions[last_index] = last_question
	bundle["questions"] = ordered_questions
	return bundle


func ensure_javi_insult_battle_state(state: Dictionary) -> Dictionary:
	var raw: Variant = state.get("javi_insult_battle", {})
	var battle: Dictionary = (raw as Dictionary).duplicate(true) if typeof(raw) == TYPE_DICTIONARY else {}
	battle = _normalise_javi_battle_0927(battle)
	state["javi_insult_battle"] = battle
	return battle


func prepare_javi_insult_battle_visit(state: Dictionary) -> Dictionary:
	var battle := ensure_javi_insult_battle_state(state)
	var remaining: Array = battle.get("remaining", []) if typeof(battle.get("remaining", [])) == TYPE_ARRAY else []
	var order: Array[String] = []
	for raw_id in remaining:
		order.append(str(raw_id))
	_shuffle_string_array_0927(order)
	battle["session_order"] = order
	battle["complete"] = order.is_empty()
	state["javi_insult_battle"] = battle
	_set_runtime_javi_battle_order_0927(order)
	return battle


func set_runtime_javi_insult_battle_state(state: Dictionary) -> Dictionary:
	var battle := ensure_javi_insult_battle_state(state)
	var order: Array[String] = []
	var raw_order: Variant = battle.get("session_order", [])
	if typeof(raw_order) == TYPE_ARRAY:
		for raw_id in raw_order as Array:
			var question_id := str(raw_id)
			if not question_id.is_empty() and not order.has(question_id):
				order.append(question_id)
	_set_runtime_javi_battle_order_0927(order)
	return battle


func mark_javi_insult_battle_entered(state: Dictionary) -> Dictionary:
	var battle := ensure_javi_insult_battle_state(state)
	battle["entered_once"] = true
	state["javi_insult_battle"] = battle
	return battle


func record_javi_insult_answer(state: Dictionary, question_number: int) -> Dictionary:
	var battle := ensure_javi_insult_battle_state(state)
	var raw_order: Variant = battle.get("session_order", [])
	var order: Array = raw_order as Array if typeof(raw_order) == TYPE_ARRAY else []
	var index := question_number - 1
	if index < 0 or index >= order.size():
		return battle
	var question_id := str(order[index])
	if question_id.is_empty():
		return battle

	var completed: Array = battle.get("completed", []) if typeof(battle.get("completed", [])) == TYPE_ARRAY else []
	if not completed.has(question_id):
		completed.append(question_id)
	battle["completed"] = completed
	battle = _normalise_javi_battle_0927(battle)
	# El orden de la sesión se conserva completo hasta salir de la habitación:
	# q2 debe seguir apuntando al segundo insulto aunque q1 ya esté completado.
	battle["session_order"] = order.duplicate()
	state["javi_insult_battle"] = battle
	return battle


func is_javi_insult_battle_complete(state: Dictionary) -> bool:
	return bool(ensure_javi_insult_battle_state(state).get("complete", false))


func _day_specific_bundle_0927(character_id: String) -> Dictionary:
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


func _normalise_javi_battle_0927(source: Dictionary) -> Dictionary:
	var all_ids := _javi_pool_ids_0927()
	var completed: Array[String] = []
	var raw_completed: Variant = source.get("completed", [])
	if typeof(raw_completed) == TYPE_ARRAY:
		for raw_id in raw_completed as Array:
			var question_id := str(raw_id)
			if all_ids.has(question_id) and not completed.has(question_id):
				completed.append(question_id)

	var remaining: Array[String] = []
	for question_id in all_ids:
		if not completed.has(question_id):
			remaining.append(question_id)

	var session_order: Array[String] = []
	var raw_order: Variant = source.get("session_order", [])
	if typeof(raw_order) == TYPE_ARRAY:
		for raw_id in raw_order as Array:
			var question_id := str(raw_id)
			if all_ids.has(question_id) and not session_order.has(question_id):
				session_order.append(question_id)

	return {
		"entered_once": bool(source.get("entered_once", false)),
		"completed": completed,
		"remaining": remaining,
		"session_order": session_order,
		"complete": not all_ids.is_empty() and remaining.is_empty(),
		"total": all_ids.size()
	}


func _javi_pool_ids_0927() -> Array[String]:
	var result: Array[String] = []
	var raw_questions: Variant = _javi_question_pool.get("questions", [])
	if typeof(raw_questions) != TYPE_ARRAY:
		return result
	for raw_question in raw_questions as Array:
		if typeof(raw_question) != TYPE_DICTIONARY:
			continue
		var question_id := str((raw_question as Dictionary).get("id", ""))
		if not question_id.is_empty() and not result.has(question_id):
			result.append(question_id)
	return result


func _javi_pool_question_by_id_0927(question_id: String) -> Dictionary:
	var raw_questions: Variant = _javi_question_pool.get("questions", [])
	if typeof(raw_questions) != TYPE_ARRAY:
		return {}
	for raw_question in raw_questions as Array:
		if typeof(raw_question) == TYPE_DICTIONARY and str((raw_question as Dictionary).get("id", "")) == question_id:
			return (raw_question as Dictionary).duplicate(true)
	return {}


func _shuffle_string_array_0927(values: Array[String]) -> void:
	if values.size() < 2:
		return
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		if i != j:
			var tmp := values[i]
			values[i] = values[j]
			values[j] = tmp


func _set_runtime_javi_battle_order_0927(order: Array[String]) -> void:
	_runtime_javi_battle_order_0927 = order.duplicate()
	_runtime_javi_battle_configured_0927 = true
