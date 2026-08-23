extends "res://autoload/data_manager_v100.gd"

const CHARLIE_ARC_PATH := "res://data/charlie_arc.json"
const DIALOGUE_OVERRIDES_ROOT := "res://data/dialogues"
const FIXED_GUEST_PROFILE := {
	"id": "custom",
	"name": "Invitado",
	"display_name": "Invitado",
	"gender": "No especificar",
	"appearance": "",
	"role": "invitado",
	"custom": true,
	"guest": true
}

var _charlie_arc: Dictionary = {}
var _dialogue_override_cache: Dictionary = {}


func reload_all() -> void:
	super()
	_charlie_arc = _load_json_object(CHARLIE_ARC_PATH, {})
	_dialogue_override_cache.clear()


func migrate_save_state(state: Dictionary) -> Dictionary:
	var result := super(state)
	result["player"] = FIXED_GUEST_PROFILE.duplicate(true)

	var active: Array = []
	for raw_id in get_all_character_ids(true):
		var character_id := str(raw_id)
		if not character_id.is_empty() and not active.has(character_id):
			active.append(character_id)
	result["active_characters"] = active

	var affinity: Dictionary = result.get("affinity", {}) if typeof(result.get("affinity", {})) == TYPE_DICTIONARY else {}
	var expressions: Dictionary = result.get("expressions", {}) if typeof(result.get("expressions", {})) == TYPE_DICTIONARY else {}
	for character_id in active:
		if not affinity.has(character_id):
			affinity[character_id] = get_initial_friendship(character_id)
		if not expressions.has(character_id):
			expressions[character_id] = "neutral"
	result["affinity"] = affinity
	result["expressions"] = expressions
	return result


func get_question_bundle(character_id: String) -> Dictionary:
	if _legacy_contract() or not _runtime_day_enabled:
		return super(character_id)

	if character_id == "charlie":
		var days: Variant = _charlie_arc.get("days", {})
		if typeof(days) == TYPE_DICTIONARY:
			var raw_day: Variant = (days as Dictionary).get(str(_runtime_day_id), {})
			if typeof(raw_day) == TYPE_DICTIONARY:
				return _normalise_bundle(character_id, raw_day as Dictionary)

	var override := _dialogue_override(character_id, _runtime_day_id)
	if not override.is_empty():
		return _normalise_bundle(character_id, override)

	return super(character_id)


# Al terminar los 16 insultos, una nueva visita reinicia el pool completo.
# Esta es lógica de juego actual, no una migración de versión.
func prepare_javi_insult_battle_visit(state: Dictionary) -> Dictionary:
	var battle := ensure_javi_insult_battle_state(state)
	if bool(battle.get("complete", false)):
		battle["completed"] = []
		battle["remaining"] = _javi_pool_ids_0927()
		battle["session_order"] = []
		battle["complete"] = false
		state["javi_insult_battle"] = battle
	return super(state)


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
		person["imagen_por_defecto"] = get_character_image_path("charlie", "neutral")
		people[i] = person
		break
	result["personajes"] = people
	return result


func _dialogue_override(character_id: String, day_id: int) -> Dictionary:
	if character_id.is_empty() or day_id <= 0:
		return {}
	var cache_key := "%s:%d" % [character_id, day_id]
	if _dialogue_override_cache.has(cache_key):
		var cached: Variant = _dialogue_override_cache[cache_key]
		return (cached as Dictionary).duplicate(true) if typeof(cached) == TYPE_DICTIONARY else {}
	var path := "%s/%s/day_%d.json" % [DIALOGUE_OVERRIDES_ROOT, character_id, day_id]
	var loaded: Dictionary = _load_json_object(path, {}) if FileAccess.file_exists(path) else {}
	_dialogue_override_cache[cache_key] = loaded
	return loaded.duplicate(true)


func _normalise_bundle(character_id: String, source: Dictionary) -> Dictionary:
	var result := source.duplicate(true)
	result["character"] = character_id
	if typeof(result.get("intro", [])) != TYPE_ARRAY:
		result["intro"] = []
	if typeof(result.get("questions", [])) != TYPE_ARRAY:
		result["questions"] = []
	return result
