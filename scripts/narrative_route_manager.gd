extends Node

const ROUTES_PATH := "res://data/narrative_routes.json"
const ROUTE_SCHEMA_VERSION := 1

var main: Control
var route_data: Dictionary = {}
var _last_signature := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(10):
		await get_tree().process_frame
	main = get_parent() as Control
	_load_route_data()
	_sync_state(false)


func _process(_delta: float) -> void:
	if main == null or route_data.is_empty():
		return
	var state := _state()
	if state.is_empty() or typeof(state.get("player", null)) != TYPE_DICTIONARY:
		return
	var signature := "%s|%s|%s" % [
		str(_current_day(state)),
		str(state.get("node_id", "")),
		str((state.get("narrative_routes", {}) as Dictionary).get("event_serial", 0)) if typeof(state.get("narrative_routes", {})) == TYPE_DICTIONARY else "0"
	]
	if signature == _last_signature:
		return
	_last_signature = signature
	_sync_state(false)


func record_visit(character_id: String) -> void:
	if character_id.is_empty():
		return
	record_event("visit:" + character_id, true)


func record_puzzle_solved(puzzle_id: String) -> void:
	if puzzle_id.is_empty():
		return
	record_event("puzzle:" + puzzle_id, false)


func record_scene_event(event_id: String) -> void:
	if event_id.is_empty():
		return
	record_event("scene:" + event_id, false)


func record_choice(node_id: String, label: String, event_id: String = "") -> void:
	var state := _state()
	if state.is_empty():
		return
	var progress := _ensure_progress(state)
	var decisions: Array = progress.get("decisions", []) if typeof(progress.get("decisions", [])) == TYPE_ARRAY else []
	decisions.append({
		"day": _current_day(state),
		"node": node_id,
		"label": label,
		"event": event_id
	})
	progress["decisions"] = decisions
	state["narrative_routes"] = progress
	_store_state(state, false)
	if not event_id.is_empty():
		record_event("choice:" + event_id, false)


func record_easter_egg(easter_egg_id: String) -> void:
	if easter_egg_id.is_empty():
		return
	var state := _state()
	if state.is_empty():
		return
	var progress := _ensure_progress(state)
	var seen: Array = progress.get("easter_eggs_seen", []) if typeof(progress.get("easter_eggs_seen", [])) == TYPE_ARRAY else []
	if seen.has(easter_egg_id):
		return
	seen.append(easter_egg_id)
	progress["easter_eggs_seen"] = seen
	state["narrative_routes"] = progress
	_store_state(state, false)


func record_event(token: String, allow_repeat: bool = true) -> void:
	if token.is_empty():
		return
	var state := _state()
	if state.is_empty():
		return
	var progress := _ensure_progress(state)
	var events: Dictionary = progress.get("events", {}) if typeof(progress.get("events", {})) == TYPE_DICTIONARY else {}
	if not allow_repeat and events.has(token):
		return
	var serial := int(progress.get("event_serial", 0)) + 1
	progress["event_serial"] = serial
	events[token] = serial
	progress["events"] = events
	state["narrative_routes"] = progress
	var messages := _evaluate_routes(state)
	_store_state(state, true)
	for message in messages:
		if main != null and not str(message).is_empty():
			main.call("_show_toast", str(message))


func has_required_route(day_id: int) -> bool:
	for route in _routes_for_day(day_id):
		if bool(route.get("required_for_day", false)):
			return true
	return false


func is_day_ready(day_id: int) -> bool:
	var state := _state()
	if state.is_empty():
		return false
	var progress := _ensure_progress(state)
	var found_required := false
	for route in _routes_for_day(day_id):
		if not bool(route.get("required_for_day", false)):
			continue
		found_required = true
		var route_state := _route_state(progress, str(route.get("id", "")))
		if not bool(route_state.get("completed", false)):
			return false
	return true if found_required else true


func get_day_progress(day_id: int) -> Dictionary:
	var state := _state()
	if state.is_empty():
		return {"completed": 0, "total": 0, "ready": false}
	var progress := _ensure_progress(state)
	var completed := 0
	var total := 0
	var found_required := false
	for route in _routes_for_day(day_id):
		if not bool(route.get("required_for_day", false)):
			continue
		found_required = true
		var stages: Array = route.get("stages", []) if typeof(route.get("stages", [])) == TYPE_ARRAY else []
		total += stages.size()
		var route_state := _route_state(progress, str(route.get("id", "")))
		var completed_stages: Array = route_state.get("completed_stages", []) if typeof(route_state.get("completed_stages", [])) == TYPE_ARRAY else []
		completed += mini(completed_stages.size(), stages.size())
	if not found_required:
		return {"completed": 0, "total": 0, "ready": true}
	return {"completed": completed, "total": total, "ready": is_day_ready(day_id)}


func get_current_required_characters(day_id: int) -> Array[String]:
	var result: Array[String] = []
	var state := _state()
	if state.is_empty():
		return result
	var progress := _ensure_progress(state)
	for route in _routes_for_day(day_id):
		if not bool(route.get("required_for_day", false)):
			continue
		var route_id := str(route.get("id", ""))
		var route_state := _route_state(progress, route_id)
		if bool(route_state.get("completed", false)):
			continue
		var stage := _current_stage(route, route_state)
		for target in _visit_targets(stage):
			if not result.has(target):
				result.append(target)
	return result


func get_character_status(day_id: int, character_id: String) -> String:
	if character_id.is_empty():
		return "optional"
	var state := _state()
	if state.is_empty():
		return "optional"
	var progress := _ensure_progress(state)
	var completed_target := false
	for route in _routes_for_day(day_id):
		if not bool(route.get("required_for_day", false)):
			continue
		var route_state := _route_state(progress, str(route.get("id", "")))
		var stages: Array = route.get("stages", []) if typeof(route.get("stages", [])) == TYPE_ARRAY else []
		var completed_stages: Array = route_state.get("completed_stages", []) if typeof(route_state.get("completed_stages", [])) == TYPE_ARRAY else []
		for raw_stage in stages:
			if typeof(raw_stage) != TYPE_DICTIONARY:
				continue
			var stage := raw_stage as Dictionary
			if completed_stages.has(str(stage.get("id", ""))) and _visit_targets(stage).has(character_id):
				completed_target = true
		if not bool(route_state.get("completed", false)):
			var current_stage := _current_stage(route, route_state)
			if _visit_targets(current_stage).has(character_id):
				return "required_pending"
	return "required_complete" if completed_target else "optional"


func get_day_override(day_id: int) -> Dictionary:
	var raw: Variant = route_data.get("day_overrides", {})
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var override: Variant = (raw as Dictionary).get(str(day_id), {})
	return (override as Dictionary).duplicate(true) if typeof(override) == TYPE_DICTIONARY else {}


func get_journal_routes(day_id: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var state := _state()
	if state.is_empty():
		return result
	var progress := _ensure_progress(state)
	for route in _routes_for_day(day_id):
		var route_state := _route_state(progress, str(route.get("id", "")))
		var completed_stages: Array = route_state.get("completed_stages", []) if typeof(route_state.get("completed_stages", [])) == TYPE_ARRAY else []
		var stages_out: Array[Dictionary] = []
		var stage_index := int(route_state.get("stage_index", 0))
		var stages: Array = route.get("stages", []) if typeof(route.get("stages", [])) == TYPE_ARRAY else []
		for i in range(stages.size()):
			if typeof(stages[i]) != TYPE_DICTIONARY:
				continue
			var stage := stages[i] as Dictionary
			stages_out.append({
				"id": str(stage.get("id", "")),
				"text": str(stage.get("objective_text", "Sigue investigando.")),
				"done": completed_stages.has(str(stage.get("id", ""))),
				"current": not bool(route_state.get("completed", false)) and i == stage_index,
				"locked": not bool(route_state.get("completed", false)) and i > stage_index
			})
		result.append({
			"id": str(route.get("id", "")),
			"title": str(route.get("title", "Ruta")),
			"description": str(route.get("description", "")),
			"required": bool(route.get("required_for_day", false)),
			"completed": bool(route_state.get("completed", false)),
			"stages": stages_out
		})
	return result


func get_discovered_clues() -> Array[String]:
	var progress := _ensure_progress(_state())
	var raw: Variant = progress.get("clues", [])
	var result: Array[String] = []
	if typeof(raw) == TYPE_ARRAY:
		for item in raw as Array:
			var clue := str(item)
			if not clue.is_empty():
				result.append(clue)
	return result


func get_unlocked_locations() -> Array[String]:
	var progress := _ensure_progress(_state())
	var raw: Variant = progress.get("unlocked_locations", [])
	var result: Array[String] = []
	if typeof(raw) == TYPE_ARRAY:
		for item in raw as Array:
			var value := str(item)
			if not value.is_empty():
				result.append(value)
	return result


func get_unlocked_arcs() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var progress := _ensure_progress(_state())
	var unlocked: Array = progress.get("unlocked_arcs", []) if typeof(progress.get("unlocked_arcs", [])) == TYPE_ARRAY else []
	var raw_arcs: Variant = route_data.get("arcs", [])
	if typeof(raw_arcs) != TYPE_ARRAY:
		return result
	for raw_arc in raw_arcs as Array:
		if typeof(raw_arc) != TYPE_DICTIONARY:
			continue
		var arc := raw_arc as Dictionary
		if unlocked.has(str(arc.get("id", ""))):
			result.append(arc.duplicate(true))
	return result


func _sync_state(save_if_changed: bool) -> void:
	var state := _state()
	if state.is_empty():
		return
	var before := JSON.stringify(state.get("narrative_routes", {}))
	var progress := _ensure_progress(state)
	_migrate_completed_days(state, progress)
	state["narrative_routes"] = progress
	var after := JSON.stringify(progress)
	if before != after:
		_store_state(state, save_if_changed)


func _ensure_progress(state: Dictionary) -> Dictionary:
	if state.is_empty():
		return {}
	var raw: Variant = state.get("narrative_routes", {})
	var progress: Dictionary = (raw as Dictionary).duplicate(true) if typeof(raw) == TYPE_DICTIONARY else {}
	progress["schema_version"] = ROUTE_SCHEMA_VERSION
	progress["event_serial"] = maxi(0, int(progress.get("event_serial", 0)))
	if typeof(progress.get("events", {})) != TYPE_DICTIONARY:
		progress["events"] = {}
	for key in ["flags", "clues", "unlocked_locations", "unlocked_arcs", "easter_eggs_seen", "decisions"]:
		if typeof(progress.get(key, [])) != TYPE_ARRAY:
			progress[key] = []
	if typeof(progress.get("routes", {})) != TYPE_DICTIONARY:
		progress["routes"] = {}
	var routes_state := progress.get("routes", {}) as Dictionary
	for route in _all_routes():
		var route_id := str(route.get("id", ""))
		if route_id.is_empty():
			continue
		var source: Variant = routes_state.get(route_id, {})
		var route_state: Dictionary = (source as Dictionary).duplicate(true) if typeof(source) == TYPE_DICTIONARY else {}
		route_state["stage_index"] = maxi(0, int(route_state.get("stage_index", 0)))
		route_state["stage_started_serial"] = maxi(0, int(route_state.get("stage_started_serial", 0)))
		if typeof(route_state.get("completed_stages", [])) != TYPE_ARRAY:
			route_state["completed_stages"] = []
		route_state["completed"] = bool(route_state.get("completed", false))
		routes_state[route_id] = route_state
	progress["routes"] = routes_state
	state["narrative_routes"] = progress
	return progress


func _evaluate_routes(state: Dictionary) -> Array[String]:
	var messages: Array[String] = []
	var progress := _ensure_progress(state)
	var routes_state := progress.get("routes", {}) as Dictionary
	var day_id := _current_day(state)
	for route in _routes_for_day(day_id):
		var route_id := str(route.get("id", ""))
		if route_id.is_empty():
			continue
		var route_state := _route_state(progress, route_id)
		var guard := 0
		while not bool(route_state.get("completed", false)) and guard < 16:
			guard += 1
			var stage := _current_stage(route, route_state)
			if stage.is_empty() or not _stage_satisfied(stage, route_state, progress):
				break
			var completed_stages: Array = route_state.get("completed_stages", []) if typeof(route_state.get("completed_stages", [])) == TYPE_ARRAY else []
			var stage_id := str(stage.get("id", ""))
			if not stage_id.is_empty() and not completed_stages.has(stage_id):
				completed_stages.append(stage_id)
			route_state["completed_stages"] = completed_stages
			var action_message := _apply_actions(progress, stage.get("on_complete", {}))
			if not action_message.is_empty():
				messages.append(action_message)
			var next_index := int(route_state.get("stage_index", 0)) + 1
			route_state["stage_index"] = next_index
			route_state["stage_started_serial"] = int(progress.get("event_serial", 0))
			var stages: Array = route.get("stages", []) if typeof(route.get("stages", [])) == TYPE_ARRAY else []
			if next_index >= stages.size():
				route_state["completed"] = true
		routes_state[route_id] = route_state
	progress["routes"] = routes_state
	state["narrative_routes"] = progress
	return messages


func _stage_satisfied(stage: Dictionary, route_state: Dictionary, progress: Dictionary) -> bool:
	var raw_objectives: Variant = stage.get("objectives", [])
	if typeof(raw_objectives) != TYPE_ARRAY:
		return false
	var objectives := raw_objectives as Array
	if objectives.is_empty():
		return true
	for raw_objective in objectives:
		if typeof(raw_objective) != TYPE_DICTIONARY:
			return false
		if not _objective_satisfied(raw_objective as Dictionary, route_state, progress):
			return false
	return true


func _objective_satisfied(objective: Dictionary, route_state: Dictionary, progress: Dictionary) -> bool:
	var kind := str(objective.get("type", ""))
	var events: Dictionary = progress.get("events", {}) if typeof(progress.get("events", {})) == TYPE_DICTIONARY else {}
	var start_serial := int(route_state.get("stage_started_serial", 0))
	var fresh := bool(objective.get("fresh", true))
	match kind:
		"visit":
			var serial := int(events.get("visit:" + str(objective.get("target", "")), 0))
			return serial > start_serial if fresh else serial > 0
		"visit_all":
			var raw_targets: Variant = objective.get("targets", [])
			if typeof(raw_targets) != TYPE_ARRAY:
				return false
			for raw_target in raw_targets as Array:
				var serial := int(events.get("visit:" + str(raw_target), 0))
				if (serial <= start_serial) if fresh else (serial <= 0):
					return false
			return true
		"event":
			var event_serial := int(events.get(str(objective.get("event", "")), 0))
			return event_serial > start_serial if fresh else event_serial > 0
		"flag":
			var flags: Array = progress.get("flags", []) if typeof(progress.get("flags", [])) == TYPE_ARRAY else []
			return flags.has(str(objective.get("flag", "")))
		"clue":
			var clues: Array = progress.get("clues", []) if typeof(progress.get("clues", [])) == TYPE_ARRAY else []
			return clues.has(str(objective.get("clue", "")))
		_:
			return false


func _apply_actions(progress: Dictionary, raw_actions: Variant) -> String:
	if typeof(raw_actions) != TYPE_DICTIONARY:
		return ""
	var actions := raw_actions as Dictionary
	_append_unique_values(progress, "flags", actions.get("flags", []))
	_append_unique_values(progress, "clues", actions.get("clues", []))
	_append_unique_values(progress, "unlocked_locations", actions.get("locations", []))
	_append_unique_values(progress, "unlocked_arcs", actions.get("arcs", []))
	return str(actions.get("toast", ""))


func _append_unique_values(progress: Dictionary, key: String, raw_values: Variant) -> void:
	if typeof(raw_values) != TYPE_ARRAY:
		return
	var values: Array = progress.get(key, []) if typeof(progress.get(key, [])) == TYPE_ARRAY else []
	for raw_value in raw_values as Array:
		var value := str(raw_value)
		if not value.is_empty() and not values.has(value):
			values.append(value)
	progress[key] = values


func _migrate_completed_days(state: Dictionary, progress: Dictionary) -> void:
	var narrative: Variant = state.get("narrative_progress", {})
	if typeof(narrative) != TYPE_DICTIONARY:
		return
	var day_states: Variant = (narrative as Dictionary).get("day_states", {})
	if typeof(day_states) != TYPE_DICTIONARY:
		return
	var routes_state := progress.get("routes", {}) as Dictionary
	for route in _all_routes():
		var day_id := int(route.get("day", 0))
		var day_state: Variant = (day_states as Dictionary).get(str(day_id), {})
		if typeof(day_state) != TYPE_DICTIONARY or not bool((day_state as Dictionary).get("completed", false)):
			continue
		var route_id := str(route.get("id", ""))
		var route_state := _route_state(progress, route_id)
		if bool(route_state.get("completed", false)):
			continue
		var completed_stages: Array = []
		var stages: Array = route.get("stages", []) if typeof(route.get("stages", [])) == TYPE_ARRAY else []
		for raw_stage in stages:
			if typeof(raw_stage) != TYPE_DICTIONARY:
				continue
			var stage := raw_stage as Dictionary
			completed_stages.append(str(stage.get("id", "")))
			_apply_actions(progress, stage.get("on_complete", {}))
		route_state["completed_stages"] = completed_stages
		route_state["stage_index"] = stages.size()
		route_state["completed"] = true
		routes_state[route_id] = route_state
	progress["routes"] = routes_state


func _current_stage(route: Dictionary, route_state: Dictionary) -> Dictionary:
	var stages: Variant = route.get("stages", [])
	if typeof(stages) != TYPE_ARRAY:
		return {}
	var index := int(route_state.get("stage_index", 0))
	if index < 0 or index >= (stages as Array).size():
		return {}
	var raw: Variant = (stages as Array)[index]
	return raw as Dictionary if typeof(raw) == TYPE_DICTIONARY else {}


func _visit_targets(stage: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var raw_objectives: Variant = stage.get("objectives", [])
	if typeof(raw_objectives) != TYPE_ARRAY:
		return result
	for raw_objective in raw_objectives as Array:
		if typeof(raw_objective) != TYPE_DICTIONARY:
			continue
		var objective := raw_objective as Dictionary
		match str(objective.get("type", "")):
			"visit":
				var target := str(objective.get("target", ""))
				if not target.is_empty() and not result.has(target):
					result.append(target)
			"visit_all":
				var raw_targets: Variant = objective.get("targets", [])
				if typeof(raw_targets) == TYPE_ARRAY:
					for raw_target in raw_targets as Array:
						var target := str(raw_target)
						if not target.is_empty() and not result.has(target):
							result.append(target)
	return result


func _route_state(progress: Dictionary, route_id: String) -> Dictionary:
	var routes_state: Dictionary = progress.get("routes", {}) if typeof(progress.get("routes", {})) == TYPE_DICTIONARY else {}
	var raw: Variant = routes_state.get(route_id, {})
	return (raw as Dictionary).duplicate(true) if typeof(raw) == TYPE_DICTIONARY else {
		"stage_index": 0,
		"stage_started_serial": 0,
		"completed_stages": [],
		"completed": false
	}


func _routes_for_day(day_id: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for route in _all_routes():
		if int(route.get("day", 0)) == day_id:
			result.append(route)
	return result


func _all_routes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var raw: Variant = route_data.get("routes", [])
	if typeof(raw) != TYPE_ARRAY:
		return result
	for raw_route in raw as Array:
		if typeof(raw_route) == TYPE_DICTIONARY:
			result.append((raw_route as Dictionary).duplicate(true))
	return result


func _current_day(state: Dictionary) -> int:
	var narrative: Variant = state.get("narrative_progress", {})
	if typeof(narrative) == TYPE_DICTIONARY:
		return int((narrative as Dictionary).get("current_day", 1))
	return 1


func _state() -> Dictionary:
	if main == null:
		return {}
	var raw: Variant = main.get("state")
	return raw as Dictionary if typeof(raw) == TYPE_DICTIONARY else {}


func _store_state(state: Dictionary, save: bool) -> void:
	if main == null:
		return
	main.set("state", state)
	if save:
		main.call("_save_game", false)


func _load_route_data() -> void:
	route_data = {}
	if not FileAccess.file_exists(ROUTES_PATH):
		return
	var file := FileAccess.open(ROUTES_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		route_data = (parsed as Dictionary).duplicate(true)
