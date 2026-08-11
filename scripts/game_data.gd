extends RefCounted
class_name GameData

const DataAccess = preload("res://scripts/data_access.gd")

# Fachada de compatibilidad: la fuente real está en DataManager/JSON.
static var CHARACTER_ORDER: Array[String] = _load_character_order()
static var CHARACTERS: Dictionary = _load_characters()
static var LOCATIONS: Dictionary = _load_locations()
static var LOCATION_ORDER: Array[String] = _load_location_order()


static func refresh() -> void:
	var dm: Variant = DataAccess.dm()
	if dm == null:
		return
	dm.call("ensure_loaded")
	CHARACTER_ORDER = _load_character_order()
	CHARACTERS = _load_characters()
	LOCATIONS = _load_locations()
	LOCATION_ORDER = _load_location_order()


static func character_profile(character_id: String) -> Dictionary:
	var dm: Variant = DataAccess.dm()
	if dm == null:
		return {}
	var data: Dictionary = dm.call("get_character", character_id)
	if data.is_empty():
		return {}
	return {
		"id": character_id,
		"name": str(data.get("real_name", data.get("name", character_id))),
		"display_name": str(data.get("display_name", data.get("name", character_id))),
		"gender": "",
		"appearance": "",
		"role": str(data.get("role", "principal")),
		"custom": false
	}


static func display_name(character_id: String) -> String:
	var dm: Variant = DataAccess.dm()
	if dm == null:
		return character_id.capitalize()
	var data: Dictionary = dm.call("get_character", character_id)
	if data.is_empty():
		return character_id.capitalize()
	return str(data.get("display_name", data.get("name", character_id.capitalize())))


static func location_name(location_id: String) -> String:
	var data: Dictionary = LOCATIONS.get(location_id, {})
	return str(data.get("name", location_id.capitalize()))


static func location_chapter(location_id: String) -> String:
	var data: Dictionary = LOCATIONS.get(location_id, {})
	return str(data.get("chapter", "PRÓLOGO"))


static func _load_character_order() -> Array[String]:
	var dm: Variant = DataAccess.dm()
	if dm == null:
		return []
	dm.call("ensure_loaded")
	var raw_ids: Array = dm.call("get_character_ids", true)
	var result: Array[String] = []
	for raw_id in raw_ids:
		result.append(str(raw_id))
	return result


static func _load_characters() -> Dictionary:
	var dm: Variant = DataAccess.dm()
	if dm == null:
		return {}
	dm.call("ensure_loaded")
	var result: Dictionary = {}
	var raw_ids: Array = dm.call("get_character_ids", false)
	for raw_id in raw_ids:
		var character_id := str(raw_id)
		var data: Dictionary = dm.call("get_character", character_id)
		result[character_id] = {
			"name": str(data.get("real_name", data.get("name", character_id.capitalize()))),
			"alias": str(data.get("display_name", data.get("name", character_id.capitalize()))),
			"role": str(data.get("role", "principal")),
			"summary": str(data.get("summary", "")),
			"enabled": bool(data.get("enabled", true)),
			"playable": bool(data.get("playable", true)),
			"room": str(data.get("room", "")),
			"initial_friendship": int(data.get("initial_friendship", 0))
		}
	return result


static func _load_locations() -> Dictionary:
	var dm: Variant = DataAccess.dm()
	if dm == null:
		return {}
	return dm.call("get_locations") as Dictionary


static func _load_location_order() -> Array[String]:
	var result: Array[String] = []
	for key in LOCATIONS.keys():
		result.append(str(key))
	return result
