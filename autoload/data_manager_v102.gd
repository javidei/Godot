extends "res://autoload/data_manager_v101.gd"

const CHARLIE_ARC_PATH_102 := "res://data/charlie_arc.json"
const ARGENTINO_QUOTE_102 := "Yo no he puesto una carita sonriente en mi vida."

var _charlie_arc_102: Dictionary = {}


func reload_all() -> void:
	super()
	_charlie_arc_102 = _load_json_object(CHARLIE_ARC_PATH_102, {})


func migrate_save_state(state: Dictionary) -> Dictionary:
	var result := super(state)
	var active: Array = result.get("active_characters", []) if typeof(result.get("active_characters", [])) == TYPE_ARRAY else []
	if get_all_character_ids(true).has("charlie") and not active.has("charlie"):
		active.append("charlie")
	result["active_characters"] = active
	if typeof(result.get("affinity", {})) == TYPE_DICTIONARY and not (result["affinity"] as Dictionary).has("charlie"):
		(result["affinity"] as Dictionary)["charlie"] = get_initial_friendship("charlie")
	if typeof(result.get("expressions", {})) == TYPE_DICTIONARY and not (result["expressions"] as Dictionary).has("charlie"):
		(result["expressions"] as Dictionary)["charlie"] = "neutral"
	return result


func get_question_bundle(character_id: String) -> Dictionary:
	var bundle := super(character_id)
	if _legacy_contract() or not _runtime_day_enabled:
		return bundle

	if character_id == "charlie":
		var days: Variant = _charlie_arc_102.get("days", {})
		if typeof(days) == TYPE_DICTIONARY:
			var raw_day: Variant = (days as Dictionary).get(str(_runtime_day_id), {})
			if typeof(raw_day) == TYPE_DICTIONARY:
				var result := (raw_day as Dictionary).duplicate(true)
				result["character"] = "charlie"
				if typeof(result.get("intro", [])) != TYPE_ARRAY:
					result["intro"] = []
				if typeof(result.get("questions", [])) != TYPE_ARRAY:
					result["questions"] = []
				return result

	if character_id == "argentino" and _runtime_day_id == 2:
		var result := bundle.duplicate(true)
		var intro: Array = result.get("intro", []) if typeof(result.get("intro", [])) == TYPE_ARRAY else []
		var already_present := false
		for raw_line in intro:
			if typeof(raw_line) == TYPE_DICTIONARY and str((raw_line as Dictionary).get("text", "")) == ARGENTINO_QUOTE_102:
				already_present = true
				break
		if not already_present:
			intro.append({
				"speaker": "Narrador",
				"speaker_id": "",
				"text": "La conversación deriva hacia las historias sentimentales del Argentino y la cantidad de conquistas que asegura haber acumulado."
			})
			intro.append({
				"speaker": "El Argentino",
				"speaker_id": "argentino",
				"expression": "happy",
				"text": ARGENTINO_QUOTE_102
			})
		result["intro"] = intro
		return result

	return bundle


func get_codex_data() -> Dictionary:
	var result := super()
	var charlie := get_character("charlie")
	if charlie.is_empty():
		return result
	var raw_people: Variant = result.get("personajes", [])
	if typeof(raw_people) != TYPE_ARRAY:
		return result
	var people := raw_people as Array
	for i in range(people.size()):
		if typeof(people[i]) != TYPE_DICTIONARY:
			continue
		var person := (people[i] as Dictionary).duplicate(true)
		if str(person.get("id", "")) != "charlie":
			continue
		for key in [
			"real_name", "nombres_alternativos", "apodos", "notas_apodos",
			"profesion_o_estudios", "estudios", "personalidad", "descripcion_personalidad",
			"gustos", "videojuegos", "aficiones", "comida", "forma_de_hablar", "relaciones",
			"apariencia", "historia_grupo", "easter_eggs", "current_residence", "residencia_actual"
		]:
			if charlie.has(key):
				person[key] = charlie[key]
		person["nombre"] = "Carlos"
		person["apodo"] = "Charlie"
		person["jugable"] = false
		person["imagen_por_defecto"] = ""
		people[i] = person
		break
	result["personajes"] = people
	return result
