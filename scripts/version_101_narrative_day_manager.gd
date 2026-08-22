extends "res://scripts/version_090_narrative_day_manager.gd"


func _route_manager() -> Node:
	return main.get_node_or_null("NarrativeRouteManager") if main != null else null


func get_current_day_definition() -> Dictionary:
	var day := super()
	var routes := _route_manager()
	if routes == null or not routes.has_method("get_day_override"):
		return day
	var override: Variant = routes.call("get_day_override", int(day.get("id", get_current_day_id())))
	if typeof(override) != TYPE_DICTIONARY:
		return day
	var result := day.duplicate(true)
	for key in (override as Dictionary).keys():
		result[key] = (override as Dictionary)[key]
	return result


func on_character_visit_completed(character_id: String) -> void:
	var routes := _route_manager()
	# La ruta se actualiza antes que el checklist heredado. Si Jony abre el camino
	# a Carmen, la comprobación de final de jornada ya ve a Carmen como objetivo
	# actual y no marca el día como terminado durante un frame intermedio.
	if routes != null and routes.has_method("record_visit"):
		routes.call("record_visit", character_id)
	super(character_id)
	_ensure_current_state(true)
	_refresh_ui(true)
	call_deferred("_refresh_open_map_status")


func get_current_day_progress() -> Dictionary:
	var routes := _route_manager()
	var day_id := get_current_day_id()
	if routes != null and routes.has_method("has_required_route") and bool(routes.call("has_required_route", day_id)):
		var route_progress: Variant = routes.call("get_day_progress", day_id)
		if typeof(route_progress) == TYPE_DICTIONARY:
			var result := (route_progress as Dictionary).duplicate(true)
			var day_state := _current_day_state(_state())
			result["ready"] = bool(day_state.get("ready_to_finish", false)) and bool(result.get("ready", false))
			return result
	return super()


func get_character_day_status(character_id: String) -> String:
	var routes := _route_manager()
	var day_id := get_current_day_id()
	if routes != null and routes.has_method("has_required_route") and bool(routes.call("has_required_route", day_id)):
		if routes.has_method("get_character_status"):
			return str(routes.call("get_character_status", day_id, character_id))
	return super(character_id)


func _required_visits(day: Dictionary, state: Dictionary) -> Array[String]:
	var routes := _route_manager()
	var day_id := int(day.get("id", get_current_day_id()))
	if routes != null and routes.has_method("has_required_route") and bool(routes.call("has_required_route", day_id)):
		var raw: Variant = routes.call("get_current_required_characters", day_id)
		var result: Array[String] = []
		if typeof(raw) == TYPE_ARRAY:
			for raw_id in raw as Array:
				var character_id := str(raw_id)
				if not character_id.is_empty() and not result.has(character_id):
					result.append(character_id)
		return result
	return super(day, state)


func _requirements_met(day: Dictionary, day_state: Dictionary, state: Dictionary) -> bool:
	var routes := _route_manager()
	var day_id := int(day.get("id", get_current_day_id()))
	if routes != null and routes.has_method("has_required_route") and bool(routes.call("has_required_route", day_id)):
		return bool(routes.call("is_day_ready", day_id))
	return super(day, day_state, state)


func submit_puzzle_solution(value: String) -> bool:
	var day := get_current_day_definition()
	var puzzle := _puzzle_definition(day)
	var puzzle_id := str(puzzle.get("id", ""))
	var state_before := _state()
	var was_solved := false
	if not state_before.is_empty():
		was_solved = bool(_puzzle_state(_current_day_state(state_before)).get("solved", false))
	var solved := await super(value)
	if solved and not was_solved:
		var routes := _route_manager()
		if routes != null and routes.has_method("record_puzzle_solved"):
			routes.call("record_puzzle_solved", puzzle_id)
		_refresh_ui(true)
		call_deferred("_refresh_open_map_status")
	return solved


func _refresh_journal() -> void:
	super()
	var routes := _route_manager()
	if routes == null or journal_body == null or not routes.has_method("get_journal_routes"):
		return
	var raw_routes: Variant = routes.call("get_journal_routes", get_current_day_id())
	if typeof(raw_routes) == TYPE_ARRAY:
		for raw_route in raw_routes as Array:
			if typeof(raw_route) != TYPE_DICTIONARY:
				continue
			var route := raw_route as Dictionary
			_add_section_title("RUTA · " + str(route.get("title", "HILO NARRATIVO")).to_upper())
			if not str(route.get("description", "")).is_empty():
				_add_plain_text(str(route.get("description", "")))
			var raw_stages: Variant = route.get("stages", [])
			if typeof(raw_stages) == TYPE_ARRAY:
				for raw_stage in raw_stages as Array:
					if typeof(raw_stage) != TYPE_DICTIONARY:
						continue
					var stage := raw_stage as Dictionary
					if bool(stage.get("locked", false)):
						continue
					var text := str(stage.get("text", "Sigue investigando."))
					if bool(stage.get("current", false)) and not bool(stage.get("done", false)):
						text = "Ahora: " + text
					_add_status_row(bool(stage.get("done", false)), text)

	if routes.has_method("get_unlocked_locations"):
		var raw_locations: Variant = routes.call("get_unlocked_locations")
		if typeof(raw_locations) == TYPE_ARRAY and not (raw_locations as Array).is_empty():
			_add_section_title("LUGARES DESCUBIERTOS")
			for raw_location in raw_locations as Array:
				var location_id := str(raw_location)
				var display_name := "Instituto del GPS" if location_id == "instituto_gps" else location_id.replace("_", " ").capitalize()
				_add_status_row(true, display_name)

	if routes.has_method("get_unlocked_arcs"):
		var raw_arcs: Variant = routes.call("get_unlocked_arcs")
		if typeof(raw_arcs) == TYPE_ARRAY and not (raw_arcs as Array).is_empty():
			_add_section_title("HILOS ABIERTOS")
			for raw_arc in raw_arcs as Array:
				if typeof(raw_arc) != TYPE_DICTIONARY:
					continue
				var arc := raw_arc as Dictionary
				_add_status_row(true, str(arc.get("title", "Nuevo arco")) + " · " + str(arc.get("description", "")))
	call_deferred("_relax_journal_scroll")
