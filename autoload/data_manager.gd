extends Node

const CONFIG_PATH := "res://data/game_config.json"
const CODEX_PATH := "res://data/detalles-juego.json"
const CHARACTERS_DIR := "res://data/characters"
const QUESTIONS_DIR := "res://data/questions"
const ROOMS_DIR := "res://data/rooms"

const DEFAULT_SAVE_PATH := "user://savegame.json"
const DEFAULT_SETTINGS_PATH := "user://settings.json"
const LEGACY_SAVE_PATH := "user://godot_otome_save.json"
const LEGACY_AUDIO_PATH := "user://audio_settings.cfg"
const LEGACY_TRACK_PATH := "user://music_track_settings.cfg"

var _loaded := false
var _revision := 0
var _game_config: Dictionary = {}
var _characters: Dictionary = {}
var _question_bundles: Dictionary = {}
var _rooms: Dictionary = {}
var _rooms_by_background: Dictionary = {}
var _rooms_by_music: Dictionary = {}
var _codex_data: Dictionary = {}
var _settings_cache: Dictionary = {}
var _errors: Array[String] = []


func _ready() -> void:
	ensure_loaded()


func ensure_loaded() -> void:
	if _loaded:
		return
	reload_all()


func reload_all() -> void:
	_loaded = false
	_errors.clear()
	_game_config = _load_json_object(CONFIG_PATH, {})
	_codex_data = _load_json_object(CODEX_PATH, {})
	_characters = _load_json_directory(CHARACTERS_DIR, "id")
	_question_bundles = _load_json_directory(QUESTIONS_DIR, "character")
	_rooms = _load_json_directory(ROOMS_DIR, "id")
	_rebuild_room_indexes()
	# Los getters públicos ya pueden usarse durante la validación sin recargar.
	_loaded = true
	_validate_data()
	_revision += 1
	_settings_cache = {}
	_migrate_legacy_save_if_needed()
	_migrate_legacy_settings_if_needed()


func get_revision() -> int:
	ensure_loaded()
	return _revision


func get_game_config() -> Dictionary:
	ensure_loaded()
	return _game_config.duplicate(true)


func get_audio_defaults() -> Dictionary:
	ensure_loaded()
	var audio: Variant = _game_config.get("audio", {})
	if typeof(audio) != TYPE_DICTIONARY:
		return {}
	return (audio as Dictionary).duplicate(true)


func get_menu_characters_path() -> String:
	ensure_loaded()
	var menu: Variant = _game_config.get("menu", {})
	if typeof(menu) != TYPE_DICTIONARY:
		return ""
	return str((menu as Dictionary).get("characters_image", ""))


func get_character_ids(enabled_only: bool = true) -> Array[String]:
	ensure_loaded()
	var result: Array[String] = []
	var configured: Variant = _game_config.get("character_order", [])
	if typeof(configured) == TYPE_ARRAY:
		for raw_id in configured as Array:
			var character_id := str(raw_id)
			if _characters.has(character_id) and _character_allowed(character_id, enabled_only):
				result.append(character_id)
	for raw_id in _characters.keys():
		var character_id := str(raw_id)
		if not result.has(character_id) and _character_allowed(character_id, enabled_only):
			result.append(character_id)
	return result


func get_character(character_id: String) -> Dictionary:
	ensure_loaded()
	var raw: Variant = _characters.get(character_id, {})
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var character: Dictionary = (raw as Dictionary).duplicate(true)
	character["id"] = character_id
	character["name"] = str(character.get("name", character_id.capitalize()))
	character["display_name"] = str(character.get("display_name", character["name"]))
	character["role"] = str(character.get("role", "principal"))
	character["summary"] = str(character.get("summary", ""))
	character["playable"] = bool(character.get("playable", true))
	character["enabled"] = bool(character.get("enabled", true))
	character["initial_friendship"] = int(character.get("initial_friendship", 0))
	var room := get_room(str(character.get("room", "")))
	if not character.has("music") or str(character.get("music", "")).is_empty():
		character["music"] = str(room.get("music_id", ""))
	var music_volume_type := typeof(character.get("music_volume", null))
	if music_volume_type != TYPE_FLOAT and music_volume_type != TYPE_INT:
		character["music_volume"] = float(room.get("music_volume", 1.0))
	if not character.has("image") or str(character.get("image", "")).is_empty():
		var poses: Variant = character.get("poses", {})
		if typeof(poses) == TYPE_DICTIONARY:
			character["image"] = str((poses as Dictionary).get("neutral", ""))
	return character


func get_character_visual(character_id: String) -> Dictionary:
	var character := get_character(character_id)
	var visual: Variant = character.get("visual", {})
	if typeof(visual) != TYPE_DICTIONARY:
		return {}
	return (visual as Dictionary).duplicate(true)


func get_character_image_path(character_id: String, pose: String = "neutral") -> String:
	var character := get_character(character_id)
	if character.is_empty():
		return ""
	var poses: Variant = character.get("poses", {})
	if typeof(poses) == TYPE_DICTIONARY:
		var pose_map := poses as Dictionary
		var path := str(pose_map.get(pose, pose_map.get("neutral", "")))
		if not path.is_empty():
			return path
	return str(character.get("image", ""))


func get_initial_friendship(character_id: String) -> int:
	return int(get_character(character_id).get("initial_friendship", 0))


func get_character_room_id(character_id: String) -> String:
	return str(get_character(character_id).get("room", ""))


func get_room_for_character(character_id: String) -> Dictionary:
	return get_room(get_character_room_id(character_id))


func get_character_background_id(character_id: String) -> String:
	return str(get_room_for_character(character_id).get("background_id", ""))


func get_character_music_id(character_id: String) -> String:
	var character := get_character(character_id)
	var music_id := str(character.get("music", ""))
	if not music_id.is_empty():
		return music_id
	return str(get_room_for_character(character_id).get("music_id", ""))


func get_character_music_volume(character_id: String) -> float:
	var character := get_character(character_id)
	var value: Variant = character.get("music_volume", null)
	var value_type := typeof(value)
	if value_type == TYPE_FLOAT or value_type == TYPE_INT:
		return clampf(float(value), 0.0, 1.0)
	return clampf(float(get_room_for_character(character_id).get("music_volume", 1.0)), 0.0, 1.0)


func get_transition_text(character_id: String, kind: String) -> String:
	var character := get_character(character_id)
	return str(character.get("transition_" + kind, ""))


func get_question_bundle(character_id: String) -> Dictionary:
	ensure_loaded()
	var raw: Variant = _question_bundles.get(character_id, {})
	if typeof(raw) != TYPE_DICTIONARY:
		return {"character": character_id, "intro": [], "questions": []}
	var bundle: Dictionary = (raw as Dictionary).duplicate(true)
	if typeof(bundle.get("intro", [])) != TYPE_ARRAY:
		bundle["intro"] = []
	if typeof(bundle.get("questions", [])) != TYPE_ARRAY:
		bundle["questions"] = []
	return bundle


func get_questions(character_id: String) -> Array:
	var bundle := get_question_bundle(character_id)
	return (bundle.get("questions", []) as Array).duplicate(true)


func get_intro(character_id: String) -> Array:
	var bundle := get_question_bundle(character_id)
	return (bundle.get("intro", []) as Array).duplicate(true)


func get_room(room_id: String) -> Dictionary:
	ensure_loaded()
	var raw: Variant = _rooms.get(room_id, {})
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	return (raw as Dictionary).duplicate(true)


func get_background_path(background_id: String) -> String:
	ensure_loaded()
	var room_id := str(_rooms_by_background.get(background_id, ""))
	return str(get_room(room_id).get("background_path", ""))


func get_music_for_background(background_id: String) -> String:
	ensure_loaded()
	var room_id := str(_rooms_by_background.get(background_id, ""))
	return str(get_room(room_id).get("music_id", ""))


func get_music_path(music_id: String) -> String:
	ensure_loaded()
	var room_id := str(_rooms_by_music.get(music_id, ""))
	return str(get_room(room_id).get("music_path", ""))


func get_music_default_volume(music_id: String, character_id: String = "") -> float:
	if not character_id.is_empty() and get_character_music_id(character_id) == music_id:
		return get_character_music_volume(character_id)
	ensure_loaded()
	var room_id := str(_rooms_by_music.get(music_id, ""))
	return clampf(float(get_room(room_id).get("music_volume", 1.0)), 0.0, 1.0)


func get_all_music_ids() -> Array[String]:
	ensure_loaded()
	var result: Array[String] = []
	for raw_id in _rooms_by_music.keys():
		result.append(str(raw_id))
	return result


func get_locations() -> Dictionary:
	ensure_loaded()
	var locations: Variant = _game_config.get("locations", {})
	if typeof(locations) != TYPE_DICTIONARY:
		return {}
	return (locations as Dictionary).duplicate(true)


func get_codex_data() -> Dictionary:
	ensure_loaded()
	var result := _codex_data.duplicate(true)
	var source_people: Variant = result.get("personajes", [])
	var by_id: Dictionary = {}
	var extras: Array = []
	if typeof(source_people) == TYPE_ARRAY:
		for item in source_people as Array:
			if typeof(item) != TYPE_DICTIONARY:
				continue
			var person: Dictionary = (item as Dictionary).duplicate(true)
			var person_id := str(person.get("id", ""))
			if person_id.is_empty():
				extras.append(person)
			else:
				by_id[person_id] = person
	var merged: Array = []
	for character_id in get_character_ids(false):
		var character := get_character(character_id)
		var person: Dictionary = by_id.get(character_id, {"id": character_id}).duplicate(true)
		person["nombre"] = str(character.get("name", character_id))
		person["apodo"] = str(character.get("display_name", character.get("name", character_id)))
		person["rol"] = str(character.get("role", "principal"))
		person["jugable"] = bool(character.get("playable", true))
		person["habilitado"] = bool(character.get("enabled", true))
		person["habitacion"] = str(character.get("room", ""))
		person["musica"] = str(character.get("music", ""))
		person["volumen_musica"] = float(character.get("music_volume", 1.0))
		person["imagen_por_defecto"] = str(character.get("image", ""))
		merged.append(person)
	for extra in extras:
		merged.append(extra)
	result["personajes"] = merged
	return result


func get_data_errors() -> Array[String]:
	ensure_loaded()
	return _errors.duplicate()


func get_save_path() -> String:
	ensure_loaded()
	var save_section: Variant = _game_config.get("save", {})
	if typeof(save_section) == TYPE_DICTIONARY:
		return str((save_section as Dictionary).get("savegame", DEFAULT_SAVE_PATH))
	return DEFAULT_SAVE_PATH


func get_settings_path() -> String:
	ensure_loaded()
	var save_section: Variant = _game_config.get("save", {})
	if typeof(save_section) == TYPE_DICTIONARY:
		return str((save_section as Dictionary).get("settings", DEFAULT_SETTINGS_PATH))
	return DEFAULT_SETTINGS_PATH


func has_save() -> bool:
	ensure_loaded()
	return FileAccess.file_exists(get_save_path()) or FileAccess.file_exists(_legacy_path("legacy_savegame", LEGACY_SAVE_PATH))


func save_game(state: Dictionary) -> bool:
	ensure_loaded()
	return _write_json(get_save_path(), state)


func load_game() -> Dictionary:
	ensure_loaded()
	_migrate_legacy_save_if_needed()
	return _load_json_object(get_save_path(), {})


func get_settings() -> Dictionary:
	ensure_loaded()
	if _settings_cache.is_empty():
		_migrate_legacy_settings_if_needed()
		var loaded := _load_json_object(get_settings_path(), {})
		_settings_cache = _deep_merge(_default_settings(), loaded)
	return _settings_cache.duplicate(true)


func save_settings(settings: Dictionary) -> bool:
	ensure_loaded()
	_settings_cache = _deep_merge(_default_settings(), settings)
	return _write_json(get_settings_path(), _settings_cache)


func update_audio_settings(patch: Dictionary) -> bool:
	var settings := get_settings()
	var audio: Dictionary = settings.get("audio", {})
	for key in patch.keys():
		audio[key] = patch[key]
	settings["audio"] = audio
	return save_settings(settings)


func get_track_settings() -> Dictionary:
	var settings := get_settings()
	var audio: Dictionary = settings.get("audio", {})
	var tracks: Variant = audio.get("tracks", {})
	if typeof(tracks) != TYPE_DICTIONARY:
		return {}
	return (tracks as Dictionary).duplicate(true)


func set_track_settings(volumes: Dictionary, mutes: Dictionary) -> bool:
	var settings := get_settings()
	var audio: Dictionary = settings.get("audio", {})
	var tracks: Dictionary = audio.get("tracks", {})
	var ids: Array = []
	for key in volumes.keys():
		if not ids.has(key):
			ids.append(key)
	for key in mutes.keys():
		if not ids.has(key):
			ids.append(key)
	for raw_id in ids:
		var music_id := str(raw_id)
		var entry: Dictionary = tracks.get(music_id, {})
		if volumes.has(raw_id):
			entry["volume"] = clampf(float(volumes[raw_id]), 0.0, 1.0)
		elif volumes.has(music_id):
			entry["volume"] = clampf(float(volumes[music_id]), 0.0, 1.0)
		if mutes.has(raw_id):
			entry["muted"] = bool(mutes[raw_id])
		elif mutes.has(music_id):
			entry["muted"] = bool(mutes[music_id])
		tracks[music_id] = entry
	audio["tracks"] = tracks
	settings["audio"] = audio
	return save_settings(settings)


func set_fullscreen(enabled: bool) -> bool:
	var settings := get_settings()
	var display: Dictionary = settings.get("display", {})
	display["fullscreen"] = enabled
	settings["display"] = display
	return save_settings(settings)


func get_fullscreen() -> bool:
	var settings := get_settings()
	var display: Dictionary = settings.get("display", {})
	return bool(display.get("fullscreen", false))


func _character_allowed(character_id: String, enabled_only: bool) -> bool:
	var raw: Variant = _characters.get(character_id, {})
	if typeof(raw) != TYPE_DICTIONARY:
		return false
	if not enabled_only:
		return true
	return bool((raw as Dictionary).get("enabled", true))


func _rebuild_room_indexes() -> void:
	_rooms_by_background.clear()
	_rooms_by_music.clear()
	for raw_id in _rooms.keys():
		var room_id := str(raw_id)
		var raw: Variant = _rooms[raw_id]
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var room := raw as Dictionary
		var background_id := str(room.get("background_id", ""))
		var music_id := str(room.get("music_id", ""))
		if not background_id.is_empty():
			_rooms_by_background[background_id] = room_id
		if not music_id.is_empty():
			_rooms_by_music[music_id] = room_id


func _validate_data() -> void:
	if _game_config.is_empty():
		_record_error("game_config.json está vacío o no se ha podido leer")
	for raw_character_id in _characters.keys():
		var character_id := str(raw_character_id)
		var character: Dictionary = _characters[raw_character_id]
		var room_id := str(character.get("room", ""))
		if room_id.is_empty() or not _rooms.has(room_id):
			_record_error("El personaje '%s' referencia una habitación inexistente: %s" % [character_id, room_id])
		if not _question_bundles.has(character_id):
			_record_error("El personaje '%s' no tiene archivo de preguntas" % character_id)
		var image_path := get_character_image_path(character_id, "neutral")
		if image_path.is_empty() or not ResourceLoader.exists(image_path):
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
			_record_error("La habitación '%s' no tiene una canción válida: %s" % [room_id, music_path])


func _validate_question_bundle(character_id: String) -> void:
	var bundle := get_question_bundle(character_id)
	var questions: Array = bundle.get("questions", [])
	for index in range(questions.size()):
		var raw_question: Variant = questions[index]
		if typeof(raw_question) != TYPE_DICTIONARY:
			_record_error("Pregunta %d de '%s' no es un objeto JSON" % [index + 1, character_id])
			continue
		var question := raw_question as Dictionary
		var answers: Variant = question.get("answers", [])
		if typeof(answers) != TYPE_ARRAY or (answers as Array).size() != 4:
			_record_error("Pregunta %d de '%s' debe tener exactamente cuatro respuestas" % [index + 1, character_id])


func _record_error(message: String) -> void:
	_errors.append(message)
	push_error("DataManager: " + message)


func _load_json_directory(directory_path: String, id_key: String) -> Dictionary:
	var result: Dictionary = {}
	var dir := DirAccess.open(directory_path)
	if dir == null:
		_record_error("No se puede abrir el directorio de datos: " + directory_path)
		return result
	for file_name in dir.get_files():
		if not str(file_name).to_lower().ends_with(".json"):
			continue
		var path := directory_path.path_join(str(file_name))
		var document := _load_json_object(path, {})
		if document.is_empty():
			continue
		var fallback_id := str(file_name).get_basename()
		var document_id := str(document.get(id_key, fallback_id))
		if document_id.is_empty():
			_record_error("El archivo '%s' no define '%s'" % [path, id_key])
			continue
		if result.has(document_id):
			_record_error("Identificador de datos duplicado '%s' en %s" % [document_id, path])
			continue
		result[document_id] = document
	return result


func _load_json_object(path: String, fallback: Dictionary) -> Dictionary:
	if not FileAccess.file_exists(path):
		if path.begins_with("res://"):
			_record_error("No existe el JSON: " + path)
		return fallback.duplicate(true)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_record_error("No se puede abrir el JSON: " + path)
		return fallback.duplicate(true)
	var parser := JSON.new()
	var status := parser.parse(file.get_as_text())
	if status != OK:
		_record_error("JSON mal formado en %s (línea %d): %s" % [path, parser.get_error_line(), parser.get_error_message()])
		return fallback.duplicate(true)
	var parsed: Variant = parser.data
	if typeof(parsed) != TYPE_DICTIONARY:
		_record_error("El JSON debe contener un objeto en la raíz: " + path)
		return fallback.duplicate(true)
	return (parsed as Dictionary).duplicate(true)


func _write_json(path: String, value: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("DataManager: no se puede escribir " + path)
		return false
	file.store_string(JSON.stringify(value))
	return true


func _default_settings() -> Dictionary:
	var audio_defaults := get_audio_defaults()
	return {
		"version": 1,
		"audio": {
			"music_volume": clampf(float(audio_defaults.get("default_music_volume", 0.3)), 0.0, 1.0),
			"effects_volume": clampf(float(audio_defaults.get("default_effects_volume", 1.0)), 0.0, 1.0),
			"music_muted": false,
			"effects_muted": false,
			"tracks": {}
		},
		"display": {
			"fullscreen": false
		}
	}


func _deep_merge(base: Dictionary, override: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for key in override.keys():
		var incoming: Variant = override[key]
		if result.has(key) and typeof(result[key]) == TYPE_DICTIONARY and typeof(incoming) == TYPE_DICTIONARY:
			result[key] = _deep_merge(result[key] as Dictionary, incoming as Dictionary)
		else:
			result[key] = incoming
	return result


func _legacy_path(key: String, fallback: String) -> String:
	var save_section: Variant = _game_config.get("save", {})
	if typeof(save_section) == TYPE_DICTIONARY:
		return str((save_section as Dictionary).get(key, fallback))
	return fallback


func _migrate_legacy_save_if_needed() -> void:
	var target := get_save_path() if _loaded else DEFAULT_SAVE_PATH
	if FileAccess.file_exists(target):
		return
	var legacy := _legacy_path("legacy_savegame", LEGACY_SAVE_PATH) if not _game_config.is_empty() else LEGACY_SAVE_PATH
	if not FileAccess.file_exists(legacy):
		return
	var old_state := _load_json_object(legacy, {})
	if not old_state.is_empty() and _write_json(target, old_state):
		print("DataManager: partida antigua migrada a " + target)


func _migrate_legacy_settings_if_needed() -> void:
	var target := get_settings_path() if _loaded else DEFAULT_SETTINGS_PATH
	if FileAccess.file_exists(target):
		return
	var settings := _default_settings()
	var audio: Dictionary = settings["audio"]
	var legacy_audio := _legacy_path("legacy_audio_settings", LEGACY_AUDIO_PATH) if not _game_config.is_empty() else LEGACY_AUDIO_PATH
	if FileAccess.file_exists(legacy_audio):
		var config := ConfigFile.new()
		if config.load(legacy_audio) == OK:
			var settings_version := int(config.get_value("audio", "settings_version", 1))
			if settings_version >= 2:
				audio["music_volume"] = clampf(float(config.get_value("audio", "music_volume", audio["music_volume"])), 0.0, 1.0)
			audio["effects_volume"] = clampf(float(config.get_value("audio", "effects_volume", audio["effects_volume"])), 0.0, 1.0)
			var legacy_muted := bool(config.get_value("audio", "muted", false))
			audio["music_muted"] = bool(config.get_value("audio", "music_muted", legacy_muted))
			audio["effects_muted"] = bool(config.get_value("audio", "effects_muted", legacy_muted))
	var tracks: Dictionary = {}
	var legacy_tracks := _legacy_path("legacy_track_settings", LEGACY_TRACK_PATH) if not _game_config.is_empty() else LEGACY_TRACK_PATH
	if FileAccess.file_exists(legacy_tracks):
		var track_config := ConfigFile.new()
		if track_config.load(legacy_tracks) == OK:
			for key in track_config.get_section_keys("volumes"):
				var music_id := str(key)
				var entry: Dictionary = tracks.get(music_id, {})
				entry["volume"] = clampf(float(track_config.get_value("volumes", key, 1.0)), 0.0, 1.0)
				tracks[music_id] = entry
			for key in track_config.get_section_keys("muted"):
				var music_id := str(key)
				var entry: Dictionary = tracks.get(music_id, {})
				entry["muted"] = bool(track_config.get_value("muted", key, false))
				tracks[music_id] = entry
	audio["tracks"] = tracks
	settings["audio"] = audio
	_write_json(target, settings)
