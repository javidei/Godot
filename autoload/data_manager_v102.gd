extends "res://autoload/data_manager_v101.gd"

const CHARLIE_ARC_PATH_102 := "res://data/charlie_arc.json"
const ARGENTINO_QUOTE_102 := "Yo no he puesto una carita sonriente en mi vida."

var _charlie_arc_102: Dictionary = {}


func reload_all() -> void:
	super()
	_charlie_arc_102 = _load_json_object(CHARLIE_ARC_PATH_102, {})


# Charlie entra al reparto antes de disponer de arte definitivo. Conservamos
# todas las validaciones de datos, salvo exigirle una imagen neutral mientras
# su ficha declare explícitamente image_optional=true.
func _validate_data() -> void:
	if _game_config.is_empty():
		_record_error("game_config.json está vacío o no se ha podido leer")
	_validate_menu_music()
	for raw_character_id in _characters.keys():
		var character_id := str(raw_character_id)
		var character: Dictionary = _characters[raw_character_id]
		var room_id := str(character.get("room", ""))
		if room_id.is_empty() or not _rooms.has(room_id):
			_record_error("El personaje '%s' referencia una habitación inexistente: %s" % [character_id, room_id])
		if not _question_bundles.has(character_id):
			_record_error("El personaje '%s' no tiene archivo de preguntas" % character_id)
		var image_path := get_character_image_path(character_id, "neutral")
		var image_optional := bool(character.get("image_optional", false))
		if not image_optional and (image_path.is_empty() or not ResourceLoader.exists(image_path)):
			_record_error("El personaje '%s' no tiene una imagen neutral válida: %s" % [character_id, image_path])
		_validate_question_bundle(character_id)
	for raw_room_id in _rooms.keys():
		var room_id := str(raw_room_id)
		var room: Dictionary = _rooms[raw_room_id]
		var background_path := str(room.get("background_path", ""))
		var music_path := str(room.get("music_path", ""))
		if background_path.is_empty() or not ResourceLoader.exists(background_path):
			_record_error("La habitación '%s' no tiene un fondo válido: %s" % [room_id, background_path])
		if not music_path.is_empty() and not ResourceLoader.exists(music_path):
			if bool(room.get("music_optional", false)):
				push_warning("DataManager: optional music is missing in '%s': %s" % [room_id, music_path])
			else:
				_record_error("Room '%s' has no valid music: %s" % [room_id, music_path])
	_validate_world_maps()
	_validate_economy()
	_validate_shop_catalog()
	_validate_achievements()


func migrate_save_state(state: Dictionary) -> Dictionary:
	var result := super(state)
	var active: Array = result.get("active_characters", []) if typeof(result.get("active_characters", [])) == TYPE_ARRAY else []
	if get_all_character_ids(true).has("charlie") and not active.has("charlie"):
		active.append("charlie")
	result["active_characters"] = active

	var affinity: Dictionary = result.get("affinity", {}) if typeof(result.get("affinity", {})) == TYPE_DICTIONARY else {}
	if not affinity.has("charlie"):
		affinity["charlie"] = get_initial_friendship("charlie")
	result["affinity"] = affinity

	var expressions: Dictionary = result.get("expressions", {}) if typeof(result.get("expressions", {})) == TYPE_DICTIONARY else {}
	if not expressions.has("charlie"):
		expressions["charlie"] = "neutral"
	result["expressions"] = expressions
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
