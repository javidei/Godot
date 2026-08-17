extends "res://autoload/data_manager_v097.gd"

const CHARACTER_SKINS_PATH := "res://data/character_skins.json"
const APPEARANCE_PROFILE_SCHEMA_VERSION := 2

var _character_skins: Dictionary = {}


func reload_all() -> void:
	_character_skins = _load_json_object(CHARACTER_SKINS_PATH, {})
	super()


func get_character_skins(character_id: String) -> Array:
	ensure_loaded()
	var result: Array = []
	if character_id.is_empty() or super.get_character(character_id).is_empty():
		return result

	# El aspecto original siempre está disponible y usa las poses normales del personaje.
	result.append({
		"id": "default",
		"name": "Aspecto original",
		"description": "Diseño original del personaje.",
		"asset": super.get_character_image_path(character_id, "neutral"),
		"default": true
	})

	var raw_characters: Variant = _character_skins.get("characters", {})
	if typeof(raw_characters) != TYPE_DICTIONARY:
		return result
	var raw_skins: Variant = (raw_characters as Dictionary).get(character_id, [])
	if typeof(raw_skins) != TYPE_ARRAY:
		return result
	for raw_skin in raw_skins as Array:
		if typeof(raw_skin) != TYPE_DICTIONARY:
			continue
		var skin := (raw_skin as Dictionary).duplicate(true)
		var skin_id := str(skin.get("id", "")).strip_edges()
		if skin_id.is_empty() or skin_id == "default":
			continue
		skin["id"] = skin_id
		skin["name"] = str(skin.get("name", skin_id.replace("_", " ").capitalize()))
		skin["description"] = str(skin.get("description", ""))
		result.append(skin)
	return result


func get_character_skin(character_id: String, skin_id: String) -> Dictionary:
	for raw_skin in get_character_skins(character_id):
		var skin := raw_skin as Dictionary
		if str(skin.get("id", "")) == skin_id:
			return skin.duplicate(true)
	return {}


func get_selected_character_skin(character_id: String) -> String:
	if character_id.is_empty():
		return "default"
	var profile := get_profile()
	var raw_selected: Variant = profile.get("selected_character_skins", {})
	if typeof(raw_selected) != TYPE_DICTIONARY:
		return "default"
	var skin_id := str((raw_selected as Dictionary).get(character_id, "default"))
	return skin_id if not get_character_skin(character_id, skin_id).is_empty() else "default"


func set_selected_character_skin(character_id: String, skin_id: String) -> bool:
	if get_character_skin(character_id, skin_id).is_empty():
		return false
	var profile := get_profile()
	var raw_selected: Variant = profile.get("selected_character_skins", {})
	var selected: Dictionary = (raw_selected as Dictionary).duplicate(true) if typeof(raw_selected) == TYPE_DICTIONARY else {}
	if skin_id == "default":
		selected.erase(character_id)
	else:
		selected[character_id] = skin_id
	profile["selected_character_skins"] = selected
	return save_profile(profile)


func get_character_image_path(character_id: String, pose: String = "neutral") -> String:
	# Una skin sustituye el cuerpo completo en todas las expresiones. Si no hay
	# skin seleccionada se conserva exactamente el sistema de poses existente.
	var skin_id := get_selected_character_skin(character_id)
	if skin_id != "default":
		var skin := get_character_skin(character_id, skin_id)
		var asset := str(skin.get("asset", "")).strip_edges()
		if not asset.is_empty() and ResourceLoader.exists(asset):
			return asset
	return super.get_character_image_path(character_id, pose)


func migrate_profile(profile: Dictionary) -> Dictionary:
	var result: Dictionary = super(profile)
	result["schema_version"] = maxi(int(result.get("schema_version", 0)), APPEARANCE_PROFILE_SCHEMA_VERSION)
	var raw_selected: Variant = result.get("selected_character_skins", {})
	var selected: Dictionary = {}
	if typeof(raw_selected) == TYPE_DICTIONARY:
		for raw_character_id in (raw_selected as Dictionary).keys():
			var character_id := str(raw_character_id).strip_edges()
			var skin_id := str((raw_selected as Dictionary)[raw_character_id]).strip_edges()
			if character_id.is_empty() or skin_id.is_empty() or skin_id == "default":
				continue
			if not get_character_skin(character_id, skin_id).is_empty():
				selected[character_id] = skin_id
	result["selected_character_skins"] = selected
	return result
