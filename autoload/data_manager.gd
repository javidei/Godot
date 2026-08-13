extends Node

const CONFIG_PATH := "res://data/game_config.json"
const CODEX_PATH := "res://data/detalles-juego.json"
const CHARACTERS_DIR := "res://data/characters"
const QUESTIONS_DIR := "res://data/questions"
const ROOMS_DIR := "res://data/rooms"
const WORLD_MAPS_PATH := "res://data/world_maps.json"
const ECONOMY_PATH := "res://data/economy.json"
const SHOP_CATALOG_PATH := "res://data/shop_catalog.json"
const ACHIEVEMENTS_PATH := "res://data/achievements.json"

const DEFAULT_SAVE_PATH := "user://savegame.json"
const DEFAULT_SETTINGS_PATH := "user://settings.json"
const DEFAULT_PROFILE_PATH := "user://profile.json"
const LEGACY_SAVE_PATH := "user://godot_otome_save.json"
const LEGACY_AUDIO_PATH := "user://audio_settings.cfg"
const LEGACY_TRACK_PATH := "user://music_track_settings.cfg"

const SAVE_SCHEMA_VERSION := 2
const PROFILE_SCHEMA_VERSION := 1
const DEFAULT_ZONE_ID := "naranjal_del_rio"

var _loaded := false
var _revision := 0
var _game_config: Dictionary = {}
var _characters: Dictionary = {}
var _question_bundles: Dictionary = {}
var _rooms: Dictionary = {}
var _rooms_by_background: Dictionary = {}
var _rooms_by_music: Dictionary = {}
var _codex_data: Dictionary = {}
var _world_maps: Dictionary = {}
var _economy: Dictionary = {}
var _shop_catalog: Dictionary = {}
var _achievements: Dictionary = {}
var _settings_cache: Dictionary = {}
var _profile_cache: Dictionary = {}
var _profile_loaded := false
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
	_world_maps = _load_json_object(WORLD_MAPS_PATH, {})
	_economy = _load_json_object(ECONOMY_PATH, {})
	_shop_catalog = _load_json_object(SHOP_CATALOG_PATH, {})
	_achievements = _load_json_object(ACHIEVEMENTS_PATH, {})
	_rebuild_room_indexes()
	# Los getters públicos ya pueden usarse durante la validación sin recargar.
	_loaded = true
	_validate_data()
	_revision += 1
	_settings_cache = {}
	_profile_cache = {}
	_profile_loaded = false
	_migrate_legacy_save_if_needed()
	_migrate_legacy_settings_if_needed()
	_ensure_profile_loaded()


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


func get_menu_music() -> Dictionary:
	ensure_loaded()
	var raw_menu: Variant = _game_config.get("menu", {})
	if typeof(raw_menu) != TYPE_DICTIONARY:
		return {}
	var menu := raw_menu as Dictionary
	var music_id := str(menu.get("music_id", "")).strip_edges()
	var music_path := str(menu.get("music_path", "")).strip_edges()
	if music_id.is_empty() or music_path.is_empty():
		return {}
	return {
		"id": music_id,
		"path": music_path,
		"volume": clampf(float(menu.get("music_volume", 0.35)), 0.0, 1.0),
		"fade_seconds": maxf(0.0, float(menu.get("music_fade_seconds", 4.0))),
		"loop": bool(menu.get("music_loop", true))
	}


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
	var menu_music := get_menu_music()
	if str(menu_music.get("id", "")) == music_id:
		return str(menu_music.get("path", ""))
	var room_id := str(_rooms_by_music.get(music_id, ""))
	return str(get_room(room_id).get("music_path", ""))


func get_music_default_volume(music_id: String, character_id: String = "") -> float:
	if not character_id.is_empty() and get_character_music_id(character_id) == music_id:
		return get_character_music_volume(character_id)
	ensure_loaded()
	var menu_music := get_menu_music()
	if str(menu_music.get("id", "")) == music_id:
		return float(menu_music.get("volume", 0.35))
	var room_id := str(_rooms_by_music.get(music_id, ""))
	return clampf(float(get_room(room_id).get("music_volume", 1.0)), 0.0, 1.0)


func get_all_music_ids() -> Array[String]:
	ensure_loaded()
	var result: Array[String] = []
	var menu_music_id := str(get_menu_music().get("id", ""))
	if not menu_music_id.is_empty():
		result.append(menu_music_id)
	for raw_id in _rooms_by_music.keys():
		var music_id := str(raw_id)
		if not result.has(music_id):
			result.append(music_id)
	return result


func get_locations() -> Dictionary:
	ensure_loaded()
	var locations: Variant = _game_config.get("locations", {})
	if typeof(locations) != TYPE_DICTIONARY:
		return {}
	return (locations as Dictionary).duplicate(true)


func get_world_maps() -> Dictionary:
	ensure_loaded()
	return _world_maps.duplicate(true)


func get_world_data() -> Dictionary:
	return get_world_maps()


func get_default_zone_id() -> String:
	ensure_loaded()
	return str(_world_maps.get("default_zone_id", DEFAULT_ZONE_ID))


func get_world_map(zone_id: String) -> Dictionary:
	ensure_loaded()
	var zones: Variant = _world_maps.get("zones", {})
	if typeof(zones) != TYPE_DICTIONARY:
		return {}
	var raw: Variant = (zones as Dictionary).get(zone_id, {})
	return (raw as Dictionary).duplicate(true) if typeof(raw) == TYPE_DICTIONARY else {}


func get_zone(zone_id: String) -> Dictionary:
	return get_world_map(zone_id)


func get_missing_map_excuses() -> Array[String]:
	ensure_loaded()
	var result: Array[String] = []
	var raw: Variant = _world_maps.get("missing_map_excuses", [])
	if typeof(raw) == TYPE_ARRAY:
		for item in raw as Array:
			var value := str(item).strip_edges()
			if not value.is_empty():
				result.append(value)
	return result


func get_economy_config() -> Dictionary:
	ensure_loaded()
	return _economy.duplicate(true)


func get_reward_rules(event_type: String = "") -> Array:
	ensure_loaded()
	var result: Array = []
	var raw: Variant = _economy.get("rewards", [])
	if typeof(raw) != TYPE_ARRAY:
		return result
	for item in raw as Array:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var rule := item as Dictionary
		if event_type.is_empty() or str(rule.get("event", "")) == event_type:
			result.append(rule.duplicate(true))
	return result


func get_shop_catalog() -> Dictionary:
	ensure_loaded()
	return _shop_catalog.duplicate(true)


func get_shop_items(enabled_only: bool = false) -> Array:
	ensure_loaded()
	var result: Array = []
	var raw: Variant = _shop_catalog.get("items", [])
	if typeof(raw) != TYPE_ARRAY:
		return result
	for item in raw as Array:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var entry := item as Dictionary
		if enabled_only and not bool(entry.get("enabled", true)):
			continue
		result.append(entry.duplicate(true))
	return result


func get_shop_item(item_id: String) -> Dictionary:
	for item in get_shop_items(false):
		if str(item.get("id", "")) == item_id:
			return (item as Dictionary).duplicate(true)
	return {}


func get_achievements_config() -> Dictionary:
	ensure_loaded()
	return _achievements.duplicate(true)


func get_achievements(enabled_only: bool = false) -> Array:
	ensure_loaded()
	var result: Array = []
	var raw: Variant = _achievements.get("achievements", [])
	if typeof(raw) != TYPE_ARRAY:
		return result
	for item in raw as Array:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var entry := item as Dictionary
		if enabled_only and not bool(entry.get("enabled", true)):
			continue
		result.append(entry.duplicate(true))
	return result


func get_achievement(achievement_id: String) -> Dictionary:
	for achievement in get_achievements(false):
		if str(achievement.get("id", "")) == achievement_id:
			return (achievement as Dictionary).duplicate(true)
	return {}


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


func get_profile_path() -> String:
	ensure_loaded()
	var save_section: Variant = _game_config.get("save", {})
	if typeof(save_section) == TYPE_DICTIONARY:
		return str((save_section as Dictionary).get("profile", DEFAULT_PROFILE_PATH))
	return DEFAULT_PROFILE_PATH


func has_save() -> bool:
	ensure_loaded()
	return FileAccess.file_exists(get_save_path()) or FileAccess.file_exists(_legacy_path("legacy_savegame", LEGACY_SAVE_PATH))


func save_game(state: Dictionary) -> bool:
	ensure_loaded()
	var migrated := migrate_save_state(state)
	state.clear()
	state.merge(migrated, true)
	return _write_json(get_save_path(), state)


func load_game() -> Dictionary:
	ensure_loaded()
	_migrate_legacy_save_if_needed()
	var loaded := _load_json_object(get_save_path(), {})
	if loaded.is_empty():
		return {}
	var migrated := migrate_save_state(loaded)
	if JSON.stringify(loaded) != JSON.stringify(migrated):
		_write_json(get_save_path(), migrated)
	return migrated


func migrate_save_state(state: Dictionary) -> Dictionary:
	var result := state.duplicate(true)
	result["schema_version"] = maxi(int(result.get("schema_version", 0)), SAVE_SCHEMA_VERSION)
	result["coins"] = maxi(0, int(result.get("coins", 0)))

	var raw_claimed: Variant = result.get("claimed_rewards", {})
	var claimed: Dictionary = {}
	if typeof(raw_claimed) == TYPE_DICTIONARY:
		claimed = (raw_claimed as Dictionary).duplicate(true)
	elif typeof(raw_claimed) == TYPE_ARRAY:
		for raw_id in raw_claimed as Array:
			var reward_id := str(raw_id).strip_edges()
			if not reward_id.is_empty():
				claimed[reward_id] = true
	result["claimed_rewards"] = claimed

	var zone_id := str(result.get("current_zone_id", get_default_zone_id())).strip_edges()
	result["current_zone_id"] = get_default_zone_id() if zone_id.is_empty() else zone_id
	return result


func get_profile() -> Dictionary:
	ensure_loaded()
	_ensure_profile_loaded()
	return _profile_cache.duplicate(true)


func save_profile(profile: Dictionary) -> bool:
	ensure_loaded()
	var migrated := migrate_profile(profile)
	if not _write_json(get_profile_path(), migrated):
		return false
	_profile_cache = migrated
	_profile_loaded = true
	return true


func update_profile(patch: Dictionary) -> bool:
	var profile := get_profile()
	return save_profile(_deep_merge(profile, patch))


func migrate_profile(profile: Dictionary) -> Dictionary:
	var result := _deep_merge(_default_profile(), profile)
	result["schema_version"] = maxi(int(result.get("schema_version", 0)), PROFILE_SCHEMA_VERSION)
	result["unlocked_collectibles"] = _normalize_string_array(result.get("unlocked_collectibles", []))
	result["unlocked_cosmetics"] = _normalize_string_array(result.get("unlocked_cosmetics", []))

	var raw_achievements: Variant = result.get("unlocked_achievements", {})
	var unlocked_achievements: Dictionary = {}
	if typeof(raw_achievements) == TYPE_DICTIONARY:
		unlocked_achievements = (raw_achievements as Dictionary).duplicate(true)
	elif typeof(raw_achievements) == TYPE_ARRAY:
		for raw_id in raw_achievements as Array:
			var achievement_id := str(raw_id).strip_edges()
			if not achievement_id.is_empty():
				unlocked_achievements[achievement_id] = true
	result["unlocked_achievements"] = unlocked_achievements

	var raw_statistics: Variant = result.get("statistics", {})
	var statistics := _default_statistics()
	if typeof(raw_statistics) == TYPE_DICTIONARY:
		statistics = _deep_merge(statistics, raw_statistics as Dictionary)
	_normalize_statistics(statistics)
	result["statistics"] = statistics
	return result


func get_settings() -> Dictionary:
	ensure_loaded()
	if _settings_cache.is_empty():
		_migrate_legacy_settings_if_needed()
		var loaded := _load_json_object(get_settings_path(), {})
		var loaded_audio: Variant = loaded.get("audio", {})
		if typeof(loaded_audio) == TYPE_DICTIONARY:
			var audio_dict := loaded_audio as Dictionary
			if not audio_dict.has("click_sound") and audio_dict.has("click_sound_id"):
				audio_dict["click_sound"] = str(audio_dict.get("click_sound_id", "soft"))
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
			if bool(room.get("music_optional", false)):
				push_warning("DataManager: optional music is missing in '%s': %s" % [room_id, music_path])
			else:
				_record_error("Room '%s' has no valid music: %s" % [room_id, music_path])
	_validate_world_maps()
	_validate_economy()
	_validate_shop_catalog()
	_validate_achievements()


func _validate_menu_music() -> void:
	var menu_music := get_menu_music()
	if menu_music.is_empty():
		return
	var music_path := str(menu_music.get("path", ""))
	if not ResourceLoader.exists(music_path):
		_record_error("La música del menú no existe o no se ha importado: %s" % music_path)


func _validate_world_maps() -> void:
	var zones: Variant = _world_maps.get("zones", {})
	if typeof(zones) != TYPE_DICTIONARY or (zones as Dictionary).is_empty():
		_record_error("world_maps.json must define at least one zone")
		return
	var default_zone := str(_world_maps.get("default_zone_id", ""))
	if default_zone.is_empty() or not (zones as Dictionary).has(default_zone):
		_record_error("world_maps.json has no valid default zone")
	for raw_zone_id in (zones as Dictionary).keys():
		var zone_id := str(raw_zone_id)
		var raw_zone: Variant = (zones as Dictionary)[raw_zone_id]
		if typeof(raw_zone) != TYPE_DICTIONARY:
			_record_error("Zone '%s' is not a JSON object" % zone_id)
			continue
		var zone := raw_zone as Dictionary
		var map_asset := str(zone.get("map_asset", ""))
		if not map_asset.is_empty() and not ResourceLoader.exists(map_asset):
			_record_error("Zone '%s' points to a missing map: %s" % [zone_id, map_asset])
		var residents: Variant = zone.get("residents", [])
		if typeof(residents) != TYPE_ARRAY:
			_record_error("Zone '%s' must define residents as an array" % zone_id)
		else:
			for raw_character_id in residents as Array:
				var character_id := str(raw_character_id)
				if not _characters.has(character_id):
					_record_error("Zone '%s' points to an unknown resident: %s" % [zone_id, character_id])
		var locations: Variant = zone.get("locations", [])
		if typeof(locations) != TYPE_ARRAY:
			_record_error("Zone '%s' must define locations as an array" % zone_id)
			continue
		for raw_location in locations as Array:
			if typeof(raw_location) != TYPE_DICTIONARY:
				_record_error("Zone '%s' contains an invalid location" % zone_id)
				continue
			var location := raw_location as Dictionary
			if str(location.get("id", "")).is_empty():
				_record_error("Zone '%s' contains a location without id" % zone_id)
			var position: Variant = location.get("position", {})
			if typeof(position) == TYPE_DICTIONARY:
				var x := float((position as Dictionary).get("x", -1.0))
				var y := float((position as Dictionary).get("y", -1.0))
				if x < 0.0 or x > 1.0 or y < 0.0 or y > 1.0:
					_record_error("Location '%s' must use normalized coordinates" % str(location.get("id", "")))


func _validate_economy() -> void:
	var rewards: Variant = _economy.get("rewards", [])
	if typeof(rewards) != TYPE_ARRAY:
		_record_error("economy.json must define rewards as an array")
		return
	for raw_rule in rewards as Array:
		if typeof(raw_rule) != TYPE_DICTIONARY:
			_record_error("economy.json contains an invalid reward")
			continue
		var rule := raw_rule as Dictionary
		if str(rule.get("event", "")).is_empty() or str(rule.get("id_template", "")).is_empty():
			_record_error("Every reward must define event and id_template")


func _validate_shop_catalog() -> void:
	var ids: Dictionary = {}
	for raw_item in get_shop_items(false):
		var item := raw_item as Dictionary
		var item_id := str(item.get("id", ""))
		if item_id.is_empty() or ids.has(item_id):
			_record_error("shop_catalog.json contains an empty or duplicate id: %s" % item_id)
			continue
		ids[item_id] = true
		if not ["collectible", "cosmetic"].has(str(item.get("category", ""))):
			_record_error("Shop item '%s' has an unsupported category" % item_id)
		if int(item.get("price", -1)) < 0:
			_record_error("Shop item '%s' has an invalid price" % item_id)


func _validate_achievements() -> void:
	var ids: Dictionary = {}
	for raw_achievement in get_achievements(false):
		var achievement := raw_achievement as Dictionary
		var achievement_id := str(achievement.get("id", ""))
		if achievement_id.is_empty() or ids.has(achievement_id):
			_record_error("achievements.json contains an empty or duplicate id: %s" % achievement_id)
			continue
		ids[achievement_id] = true
		if typeof(achievement.get("conditions", [])) != TYPE_ARRAY:
			_record_error("Achievement '%s' must define conditions as an array" % achievement_id)


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


func _ensure_profile_loaded() -> void:
	if _profile_loaded:
		return
	var path := get_profile_path()
	var loaded := _load_json_object(path, {})
	_profile_cache = migrate_profile(loaded)
	_profile_loaded = true
	if loaded.is_empty() or JSON.stringify(loaded) != JSON.stringify(_profile_cache):
		_write_json(path, _profile_cache)


func _default_profile() -> Dictionary:
	return {
		"schema_version": PROFILE_SCHEMA_VERSION,
		"unlocked_collectibles": [],
		"unlocked_cosmetics": [],
		"unlocked_achievements": {},
		"statistics": _default_statistics()
	}


func _default_statistics() -> Dictionary:
	return {
		"total_play_seconds": 0.0,
		"total_sessions": 0,
		"platforms": {},
		"touch_capable_seen": false,
		"character_visits": {},
		"location_visits": {},
		"protagonist_games": {},
		"conversations": 0,
		"decisions": 0,
		"unique_scenes": [],
		"unique_events": [],
		"coins_earned": 0,
		"coins_spent": 0
	}


func _normalize_statistics(statistics: Dictionary) -> void:
	statistics["total_play_seconds"] = maxf(0.0, float(statistics.get("total_play_seconds", 0.0)))
	for key in ["total_sessions", "conversations", "decisions", "coins_earned", "coins_spent"]:
		statistics[key] = maxi(0, int(statistics.get(key, 0)))
	statistics["touch_capable_seen"] = bool(statistics.get("touch_capable_seen", false))
	for key in ["platforms", "character_visits", "location_visits", "protagonist_games"]:
		var raw_counts: Variant = statistics.get(key, {})
		var counts: Dictionary = {}
		if typeof(raw_counts) == TYPE_DICTIONARY:
			for raw_id in (raw_counts as Dictionary).keys():
				counts[str(raw_id)] = maxi(0, int((raw_counts as Dictionary)[raw_id]))
		statistics[key] = counts
	statistics["unique_scenes"] = _normalize_string_array(statistics.get("unique_scenes", []))
	statistics["unique_events"] = _normalize_string_array(statistics.get("unique_events", []))


func _normalize_string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) == TYPE_ARRAY:
		for raw_item in value as Array:
			var item := str(raw_item).strip_edges()
			if not item.is_empty() and not result.has(item):
				result.append(item)
	elif typeof(value) == TYPE_DICTIONARY:
		for raw_item in (value as Dictionary).keys():
			if not bool((value as Dictionary)[raw_item]):
				continue
			var item := str(raw_item).strip_edges()
			if not item.is_empty() and not result.has(item):
				result.append(item)
	return result


func _default_settings() -> Dictionary:
	var audio_defaults := get_audio_defaults()
	return {
		"version": 1,
		"audio": {
			"music_volume": clampf(float(audio_defaults.get("default_music_volume", 0.3)), 0.0, 1.0),
			"effects_volume": clampf(float(audio_defaults.get("default_effects_volume", 1.0)), 0.0, 1.0),
			"music_muted": false,
			"effects_muted": false,
			"click_sound": str(audio_defaults.get("default_click_sound", "soft")),
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
