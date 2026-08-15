extends "res://autoload/data_manager_v080.gd"

const DAY_DIALOGUES_PATH := "res://data/day_dialogues.json"
const SAVE_STATE_ROSTER_SCHEMA_VERSION := 6

var _day_dialogues: Dictionary = {}
var _runtime_day_id := 1
var _runtime_day_enabled := false
var _runtime_roster_enabled := false
var _runtime_active_characters: Array[String] = []


func reload_all() -> void:
	_day_dialogues = _load_json_object(DAY_DIALOGUES_PATH, {})
	super()


func _legacy_contract() -> bool:
	return str(ProjectSettings.get_setting("application/config/version", "")).begins_with("0.6.")


func get_all_character_ids(enabled_only: bool = true) -> Array[String]:
	return super.get_character_ids(enabled_only)


func get_character_ids(enabled_only: bool = true) -> Array[String]:
	var all_ids := super.get_character_ids(enabled_only)
	if _legacy_contract() or not _runtime_roster_enabled:
		return all_ids
	var result: Array[String] = []
	for character_id in all_ids:
		if _runtime_active_characters.has(character_id):
			result.append(character_id)
	return result


func set_runtime_active_characters(character_ids: Array) -> void:
	var all_ids := super.get_character_ids(true)
	var filtered: Array[String] = []
	for raw_id in character_ids:
		var character_id := str(raw_id)
		if all_ids.has(character_id) and not filtered.has(character_id):
			filtered.append(character_id)
	if filtered.is_empty():
		filtered = all_ids.duplicate()
	_runtime_active_characters = filtered
	_runtime_roster_enabled = true


func get_runtime_active_characters() -> Array[String]:
	if not _runtime_roster_enabled:
		return super.get_character_ids(true)
	return _runtime_active_characters.duplicate()


func set_runtime_narrative_day(day_id: int) -> void:
	if _legacy_contract():
		_runtime_day_enabled = false
		return
	var valid_day := day_id
	if get_narrative_day(valid_day).is_empty():
		valid_day = get_default_narrative_day()
	_runtime_day_id = valid_day
	_runtime_day_enabled = true


func get_runtime_narrative_day() -> int:
	return _runtime_day_id if _runtime_day_enabled else get_default_narrative_day()


func get_question_bundle(character_id: String) -> Dictionary:
	if _legacy_contract() or not _runtime_day_enabled:
		return super.get_question_bundle(character_id)
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


func migrate_save_state(state: Dictionary) -> Dictionary:
	var result := super(state)
	result["schema_version"] = maxi(int(result.get("schema_version", 0)), SAVE_STATE_ROSTER_SCHEMA_VERSION)
	var all_ids := super.get_character_ids(true)
	var active: Array[String] = []
	var raw_active: Variant = result.get("active_characters", [])
	if typeof(raw_active) == TYPE_ARRAY:
		for raw_id in raw_active as Array:
			var character_id := str(raw_id)
			if all_ids.has(character_id) and not active.has(character_id):
				active.append(character_id)
	if active.is_empty():
		active = all_ids.duplicate()
	var player_id := _state_player_id(result)
	if not player_id.is_empty() and player_id != "custom" and all_ids.has(player_id) and not active.has(player_id):
		active.append(player_id)
	result["active_characters"] = active
	return result


func _state_active_characters(state: Dictionary) -> Array[String]:
	var all_ids := super.get_character_ids(true)
	var result: Array[String] = []
	var raw: Variant = state.get("active_characters", [])
	if typeof(raw) == TYPE_ARRAY:
		for raw_id in raw as Array:
			var character_id := str(raw_id)
			if all_ids.has(character_id) and not result.has(character_id):
				result.append(character_id)
	return result if not result.is_empty() else all_ids


func _required_visits_for_state(day: Dictionary, state: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var player_id := _state_player_id(state)
	var active := _state_active_characters(state)
	var raw_required: Variant = day.get("required_visits", [])
	if typeof(raw_required) == TYPE_STRING and str(raw_required) == "all_available":
		for character_id in active:
			if not bool(day.get("exclude_player", true)) or character_id != player_id:
				result.append(character_id)
	elif typeof(raw_required) == TYPE_ARRAY:
		for raw_id in raw_required as Array:
			var character_id := str(raw_id)
			if not active.has(character_id):
				continue
			if character_id.is_empty() or (bool(day.get("exclude_player", true)) and character_id == player_id):
				continue
			if not result.has(character_id):
				result.append(character_id)
	return result


func _resolved_clue_targets_for_state(day: Dictionary, state: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var used: Array[String] = []
	var player_id := _state_player_id(state)
	var active := _state_active_characters(state)
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
			if active.has(character_id) and character_id != player_id and not used.has(character_id):
				selected = character_id
				break
		if selected.is_empty():
			for raw_character in candidates as Array:
				var character_id := str(raw_character)
				if active.has(character_id) and character_id != player_id:
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
	var required := _required_visits_for_state(day, state)
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
		var targets := _resolved_clue_targets_for_state(day, state)
		var puzzle_state: Dictionary = day_state.get("puzzle", {}) if typeof(day_state.get("puzzle", {})) == TYPE_DICTIONARY else {}
		var collected: Array = puzzle_state.get("collected_clues", []) if typeof(puzzle_state.get("collected_clues", [])) == TYPE_ARRAY else []
		if not targets.is_empty():
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
