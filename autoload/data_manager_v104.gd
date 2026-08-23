extends "res://autoload/data_manager_v103.gd"

const DEFAULT_ACTIVE_CHARACTERS_KEY_104 := "default_active_characters"


# 0.10.0: el reparto completo sigue existiendo en datos, pero una run nueva
# puede arrancar con un subconjunto predeterminado declarado en game_config.json.
func get_default_active_characters() -> Array[String]:
	ensure_loaded()
	var all_ids: Array[String] = []
	for raw_id in get_all_character_ids(true):
		all_ids.append(str(raw_id))

	var configured: Variant = _game_config.get(DEFAULT_ACTIVE_CHARACTERS_KEY_104, [])
	var result: Array[String] = []
	if typeof(configured) == TYPE_ARRAY:
		for raw_id in configured as Array:
			var character_id := str(raw_id)
			if all_ids.has(character_id) and not result.has(character_id):
				result.append(character_id)
	return result if not result.is_empty() else all_ids


func get_runtime_active_characters() -> Array[String]:
	if _runtime_roster_enabled:
		return super()
	return get_default_active_characters()


func migrate_save_state(state: Dictionary) -> Dictionary:
	# Los slots que ya tienen un reparto explícito lo conservan. Una partida nueva
	# toma el reparto runtime actual: por defecto Javi + Smokey, o la selección
	# manual del usuario si la ha cambiado antes de empezar la run.
	var raw_active: Variant = state.get("active_characters", null)
	var had_explicit_roster := typeof(raw_active) == TYPE_ARRAY and not (raw_active as Array).is_empty()
	var requested: Array = (raw_active as Array).duplicate() if had_explicit_roster else []
	var result: Dictionary = super(state)

	if not had_explicit_roster:
		result["active_characters"] = get_runtime_active_characters()
		return result

	var all_ids: Array[String] = []
	for raw_id in get_all_character_ids(true):
		all_ids.append(str(raw_id))
	var filtered: Array[String] = []
	for raw_id in requested:
		var character_id := str(raw_id)
		if all_ids.has(character_id) and not filtered.has(character_id):
			filtered.append(character_id)

	if filtered.is_empty():
		result["active_characters"] = get_default_active_characters()
	else:
		result["active_characters"] = filtered
	return result
