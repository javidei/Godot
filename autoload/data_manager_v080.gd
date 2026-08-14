extends "res://autoload/data_manager_runtime.gd"

const NARRATIVE_DAYS_PATH := "res://data/narrative_days.json"
const SAVE_STATE_NARRATIVE_SCHEMA_VERSION := 5

var _narrative_days: Dictionary = {}


func reload_all() -> void:
	# Cargar primero permite que los resúmenes de slots, que se reconstruyen
	# durante el reload del runtime 0.7, ya puedan calcular el progreso 0.8.
	_narrative_days = _load_json_object(NARRATIVE_DAYS_PATH, {})
	super()


func get_narrative_days() -> Dictionary:
	ensure_loaded()
	return _narrative_days.duplicate(true)


func get_narrative_day_ids() -> Array[int]:
	ensure_loaded()
	var result: Array[int] = []
	var raw_days: Variant = _narrative_days.get("days", [])
	if typeof(raw_days) != TYPE_ARRAY:
		return result
	for raw_day in raw_days as Array:
		if typeof(raw_day) != TYPE_DICTIONARY:
			continue
		var day_id := int((raw_day as Dictionary).get("id", 0))
		if day_id > 0 and not result.has(day_id):
			result.append(day_id)
	result.sort()
	return result


func get_narrative_day(day_id: int) -> Dictionary:
	ensure_loaded()
	var raw_days: Variant = _narrative_days.get("days", [])
	if typeof(raw_days) != TYPE_ARRAY:
		return {}
	for raw_day in raw_days as Array:
		if typeof(raw_day) == TYPE_DICTIONARY and int((raw_day as Dictionary).get("id", 0)) == day_id:
			return (raw_day as Dictionary).duplicate(true)
	return {}


func get_default_narrative_day() -> int:
	ensure_loaded()
	var configured := int(_narrative_days.get("default_day", 1))
	return configured if not get_narrative_day(configured).is_empty() else (get_narrative_day_ids()[0] if not get_narrative_day_ids().is_empty() else 1)


func migrate_save_state(state: Dictionary) -> Dictionary:
	var result: Dictionary = super(state)
	result["schema_version"] = maxi(int(result.get("schema_version", 0)), SAVE_STATE_NARRATIVE_SCHEMA_VERSION)
	_migrate_narrative_progress(result)
	return result


func get_save_slot_summary(slot_id: int) -> Dictionary:
	var summary := super(slot_id)
	if not bool(summary.get("occupied", false)):
		summary["current_day"] = 0
		summary["day_title"] = ""
		summary["day_objectives_completed"] = 0
		summary["day_objectives_total"] = 0
		return summary
	var path := get_save_slot_path(slot_id)
	var state := _load_json_object(path, {}) if not path.is_empty() and FileAccess.file_exists(path) else {}
	if state.is_empty():
		return summary
	state = migrate_save_state(state)
	var day_id := _state_current_day(state)
	var day := get_narrative_day(day_id)
	var day_progress := _day_progress_units(state, day_id)
	summary["current_day"] = day_id
	summary["day_title"] = str(day.get("title", ""))
	summary["day_objectives_completed"] = int(day_progress.get("completed", 0))
	summary["day_objectives_total"] = int(day_progress.get("total", 0))
	summary["arc_complete"] = _state_arc_complete(state)
	return summary


func _story_progress(state: Dictionary, player_id: String) -> Dictionary:
	if typeof(state.get("narrative_progress", null)) != TYPE_DICTIONARY or get_narrative_day_ids().is_empty():
		return super(state, player_id)
	var total_units := 0
	var completed_units := 0
	for day_id in get_narrative_day_ids():
		var progress := _day_progress_units(state, day_id)
		total_units += int(progress.get("total", 0))
		completed_units += int(progress.get("completed", 0))
	if total_units <= 0:
		return super(state, player_id)
	if _state_arc_complete(state):
		completed_units = total_units
	return {
		"percent": roundi(clampf(float(completed_units) / float(total_units), 0.0, 1.0) * 100.0),
		"completed": completed_units,
		"total": total_units
	}


func _migrate_narrative_progress(state: Dictionary) -> void:
	var progress: Dictionary = {}
	var raw_progress: Variant = state.get("narrative_progress", {})
	if typeof(raw_progress) == TYPE_DICTIONARY:
		progress = (raw_progress as Dictionary).duplicate(true)
	var day_ids := get_narrative_day_ids()
	if day_ids.is_empty():
		return
	var current_day := int(progress.get("current_day", get_default_narrative_day()))
	if not day_ids.has(current_day):
		current_day = get_default_narrative_day()
	progress["schema_version"] = 1
	progress["current_day"] = current_day
	progress["arc_complete"] = bool(progress.get("arc_complete", false))
	var day_states: Dictionary = {}
	var raw_states: Variant = progress.get("day_states", {})
	if typeof(raw_states) == TYPE_DICTIONARY:
		day_states = (raw_states as Dictionary).duplicate(true)
	var player_id := _state_player_id(state)
	for day_id in day_ids:
		var key := str(day_id)
		var existed := typeof(day_states.get(key, null)) == TYPE_DICTIONARY
		var day_state: Dictionary = (day_states.get(key, {}) as Dictionary).duplicate(true) if existed else {}
		day_state["intro_seen"] = bool(day_state.get("intro_seen", false))
		day_state["completed"] = bool(day_state.get("completed", false))
		day_state["ready_to_finish"] = bool(day_state.get("ready_to_finish", false))
		var completed_visits: Array = []
		var raw_visits: Variant = day_state.get("completed_visits", [])
		if typeof(raw_visits) == TYPE_ARRAY:
			completed_visits = (raw_visits as Array).duplicate()
		# Una partida 0.7 ya avanzada se convierte en Día 1 sin obligar a repetir
		# las visitas que el jugador había terminado antes de esta actualización.
		if day_id == get_default_narrative_day() and not existed:
			var legacy_completed: Variant = state.get("completed_characters", [])
			if typeof(legacy_completed) == TYPE_ARRAY:
				for raw_character in legacy_completed as Array:
					var character_id := str(raw_character)
					if character_id != player_id and not completed_visits.has(character_id):
						completed_visits.append(character_id)
		day_state["completed_visits"] = completed_visits
		var puzzle_state: Dictionary = {}
		var raw_puzzle: Variant = day_state.get("puzzle", {})
		if typeof(raw_puzzle) == TYPE_DICTIONARY:
			puzzle_state = (raw_puzzle as Dictionary).duplicate(true)
		puzzle_state["collected_clues"] = (puzzle_state.get("collected_clues", []) as Array).duplicate() if typeof(puzzle_state.get("collected_clues", [])) == TYPE_ARRAY else []
		puzzle_state["attempts"] = maxi(0, int(puzzle_state.get("attempts", 0)))
		puzzle_state["solved"] = bool(puzzle_state.get("solved", false))
		day_state["puzzle"] = puzzle_state
		day_states[key] = day_state
	progress["day_states"] = day_states
	state["narrative_progress"] = progress


func _state_player_id(state: Dictionary) -> String:
	var raw_player: Variant = state.get("player", {})
	return str((raw_player as Dictionary).get("id", "")) if typeof(raw_player) == TYPE_DICTIONARY else ""


func _state_current_day(state: Dictionary) -> int:
	var raw: Variant = state.get("narrative_progress", {})
	if typeof(raw) != TYPE_DICTIONARY:
		return get_default_narrative_day()
	return int((raw as Dictionary).get("current_day", get_default_narrative_day()))


func _state_arc_complete(state: Dictionary) -> bool:
	var raw: Variant = state.get("narrative_progress", {})
	return bool((raw as Dictionary).get("arc_complete", false)) if typeof(raw) == TYPE_DICTIONARY else false


func _required_visits(day: Dictionary, player_id: String) -> Array[String]:
	var result: Array[String] = []
	var raw_required: Variant = day.get("required_visits", [])
	if typeof(raw_required) == TYPE_STRING and str(raw_required) == "all_available":
		for character_id in get_character_ids(true):
			if not bool(day.get("exclude_player", true)) or character_id != player_id:
				result.append(character_id)
	elif typeof(raw_required) == TYPE_ARRAY:
		for raw_id in raw_required as Array:
			var character_id := str(raw_id)
			if character_id.is_empty() or (bool(day.get("exclude_player", true)) and character_id == player_id):
				continue
			if not result.has(character_id):
				result.append(character_id)
	return result


func _resolved_clue_targets(day: Dictionary, player_id: String) -> Dictionary:
	var result: Dictionary = {}
	var used: Array[String] = []
	var raw_puzzle: Variant = day.get("puzzle", null)
	if typeof(raw_puzzle) != TYPE_DICTIONARY:
		return result
	var raw_groups: Variant = (raw_puzzle as Dictionary).get("clue_groups", [])
	if typeof(raw_groups) != TYPE_ARRAY:
		return result
	for raw_group in raw_groups as Array:
		if typeof(raw_group) != TYPE_DICTIONARY:
			continue
		var group := raw_group as Dictionary
		var clue_id := str(group.get("id", ""))
		var candidates: Variant = group.get("characters", [])
		if clue_id.is_empty() or typeof(candidates) != TYPE_ARRAY:
			continue
		var selected := ""
		for raw_character in candidates as Array:
			var character_id := str(raw_character)
			if character_id != player_id and not used.has(character_id):
				selected = character_id
				break
		if selected.is_empty():
			for raw_character in candidates as Array:
				var character_id := str(raw_character)
				if character_id != player_id:
					selected = character_id
					break
		if not selected.is_empty():
			result[clue_id] = selected
			if not used.has(selected):
				used.append(selected)
	return result


func _day_progress_units(state: Dictionary, day_id: int) -> Dictionary:
	var day := get_narrative_day(day_id)
	if day.is_empty():
		return {"completed": 0, "total": 0}
	var player_id := _state_player_id(state)
	var required := _required_visits(day, player_id)
	var progress: Dictionary = state.get("narrative_progress", {}) if typeof(state.get("narrative_progress", {})) == TYPE_DICTIONARY else {}
	var day_states: Dictionary = progress.get("day_states", {}) if typeof(progress.get("day_states", {})) == TYPE_DICTIONARY else {}
	var day_state: Dictionary = day_states.get(str(day_id), {}) if typeof(day_states.get(str(day_id), {})) == TYPE_DICTIONARY else {}
	var visits: Array = day_state.get("completed_visits", []) if typeof(day_state.get("completed_visits", [])) == TYPE_ARRAY else []
	var total := required.size()
	var completed := 0
	for character_id in required:
		if visits.has(character_id):
			completed += 1
	var raw_puzzle: Variant = day.get("puzzle", null)
	if typeof(raw_puzzle) == TYPE_DICTIONARY:
		var targets := _resolved_clue_targets(day, player_id)
		var puzzle_state: Dictionary = day_state.get("puzzle", {}) if typeof(day_state.get("puzzle", {})) == TYPE_DICTIONARY else {}
		var collected: Array = puzzle_state.get("collected_clues", []) if typeof(puzzle_state.get("collected_clues", [])) == TYPE_ARRAY else []
		total += targets.size() + 1
		for clue_id in targets.keys():
			if collected.has(str(clue_id)):
				completed += 1
		if bool(puzzle_state.get("solved", false)):
			completed += 1
	if total <= 0:
		total = 1
		completed = 1 if bool(day_state.get("completed", false)) else 0
	if bool(day_state.get("completed", false)):
		completed = total
	return {"completed": mini(completed, total), "total": total}
