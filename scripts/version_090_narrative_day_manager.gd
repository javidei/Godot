extends "res://scripts/version_080_narrative_day_manager.gd"

const DataAccess090 = preload("res://scripts/data_access.gd")

var next_day_button: Button
var _runtime_signature := ""


func _process(_delta: float) -> void:
	var project_version := str(ProjectSettings.get_setting("application/config/version", ""))
	if project_version.begins_with("0.6."):
		return
	if main == null or data_manager == null:
		return
	var state := _state()
	if state.is_empty() or _player_id(state).is_empty():
		return
	_sync_runtime_story()
	_ensure_current_state(false)
	_refresh_ui(false)
	if _busy or journal_overlay == null or journal_overlay.visible:
		return
	if world_map_manager == null or not world_map_manager.has_method("is_open") or not bool(world_map_manager.call("is_open")):
		return
	if _transition_active():
		return
	var day_state := _current_day_state(_state())
	if not bool(day_state.get("intro_seen", false)):
		_begin_day_intro()


func _build_journal() -> void:
	super()
	if journal_close == null:
		return
	var root := journal_close.get_parent()
	if root == null:
		return
	next_day_button = main.call("_make_button", "PASAR AL DÍA SIGUIENTE", true) as Button
	next_day_button.name = "NarrativeNextDayButton090"
	next_day_button.custom_minimum_size = Vector2(0, 50)
	next_day_button.pressed.connect(_on_next_day_pressed)
	root.add_child(next_day_button)
	root.move_child(next_day_button, journal_close.get_index())
	var audio: Variant = main.get("audio_manager")
	if audio != null and audio.has_method("bind_click"):
		audio.call("bind_click", next_day_button)


func _refresh_ui(force: bool) -> void:
	super(force)
	_refresh_next_day_button()


func _refresh_journal() -> void:
	super()
	_refresh_next_day_button()


func _refresh_next_day_button() -> void:
	if next_day_button == null:
		return
	if is_arc_complete():
		next_day_button.visible = false
		return
	next_day_button.visible = true
	var day_id := get_current_day_id()
	var ready := bool(_current_day_state(_state()).get("ready_to_finish", false))
	var next_day := _next_day(day_id)
	next_day_button.disabled = not ready
	next_day_button.text = "FINALIZAR DÍA %d" % day_id if next_day <= 0 else "PASAR AL DÍA %d" % next_day
	next_day_button.tooltip_text = "Completa los objetivos del día para continuar" if not ready else ("Cerrar el arco actual" if next_day <= 0 else "Avanzar manualmente al siguiente día")


func _on_next_day_pressed() -> void:
	var state := _state()
	if state.is_empty():
		return
	var day_state := _current_day_state(state)
	if not bool(day_state.get("ready_to_finish", false)):
		if main != null:
			main.call("_show_toast", "Todavía quedan objetivos del día")
		return
	close_journal()
	if _is_last_day(get_current_day_id()):
		_begin_arc_completion()
	else:
		_begin_day_completion()


func _active_ids(state: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var raw: Variant = state.get("active_characters", [])
	if typeof(raw) == TYPE_ARRAY:
		for raw_id in raw as Array:
			var character_id := str(raw_id)
			if not character_id.is_empty() and not result.has(character_id):
				result.append(character_id)
	if not result.is_empty():
		return result
	var dm: Variant = DataAccess090.dm()
	if dm != null and dm.has_method("get_runtime_active_characters"):
		var runtime: Variant = dm.call("get_runtime_active_characters")
		if typeof(runtime) == TYPE_ARRAY:
			for raw_id in runtime as Array:
				var character_id := str(raw_id)
				if not character_id.is_empty() and not result.has(character_id):
					result.append(character_id)
	return result


func _required_visits(day: Dictionary, state: Dictionary) -> Array[String]:
	var base := super(day, state)
	var active := _active_ids(state)
	if active.is_empty():
		return base
	var result: Array[String] = []
	for character_id in base:
		if active.has(character_id):
			result.append(character_id)
	return result


func get_puzzle_clue_targets() -> Dictionary:
	var day := get_current_day_definition()
	var puzzle := _puzzle_definition(day)
	var result: Dictionary = {}
	if puzzle.is_empty():
		return result
	var state := _state()
	var player_id := _player_id(state)
	var active := _active_ids(state)
	var used: Array[String] = []
	var raw_groups: Variant = puzzle.get("clue_groups", [])
	if typeof(raw_groups) != TYPE_ARRAY:
		return result
	for raw_group in raw_groups as Array:
		if typeof(raw_group) != TYPE_DICTIONARY:
			continue
		var group := raw_group as Dictionary
		var clue_id := str(group.get("id", ""))
		var raw_candidates: Variant = group.get("characters", [])
		if clue_id.is_empty() or typeof(raw_candidates) != TYPE_ARRAY:
			continue
		var selected := ""
		for raw_character in raw_candidates as Array:
			var character_id := str(raw_character)
			if (active.is_empty() or active.has(character_id)) and character_id != player_id and not used.has(character_id):
				selected = character_id
				break
		if selected.is_empty():
			for raw_character in raw_candidates as Array:
				var character_id := str(raw_character)
				if (active.is_empty() or active.has(character_id)) and character_id != player_id:
					selected = character_id
					break
		if not selected.is_empty():
			result[clue_id] = selected
			if not used.has(selected):
				used.append(selected)
	return result


func _requirements_met(day: Dictionary, day_state: Dictionary, state: Dictionary) -> bool:
	var completed_visits: Array = day_state.get("completed_visits", []) if typeof(day_state.get("completed_visits", [])) == TYPE_ARRAY else []
	for character_id in _required_visits(day, state):
		if not completed_visits.has(character_id):
			return false
	var puzzle := _puzzle_definition(day)
	if not puzzle.is_empty():
		var targets := get_puzzle_clue_targets()
		if targets.is_empty():
			return true
		return bool(_puzzle_state(day_state).get("solved", false))
	return true


func _commit_day_advance(day_id: int, next_day: int) -> void:
	super(day_id, next_day)
	var state := _state()
	state["conversation_checkpoints"] = {}
	state["visit_order"] = []
	_save_state(state)
	_runtime_signature = ""
	_sync_runtime_story()
	call_deferred("_refresh_open_map_status")


func _begin_arc_completion() -> void:
	super()
	_refresh_next_day_button()


func _sync_runtime_story() -> void:
	var state := _state()
	if state.is_empty():
		return
	var active := _active_ids(state)
	var day_id := get_current_day_id()
	var signature := "%d|%s" % [day_id, ",".join(PackedStringArray(active))]
	if signature == _runtime_signature:
		return
	_runtime_signature = signature
	var runtime := main.get_node_or_null("StoryRuntimeManager") if main != null else null
	if runtime != null and runtime.has_method("apply_story_runtime"):
		runtime.call("apply_story_runtime", active, day_id, true)
		return
	var dm: Variant = DataAccess090.dm()
	if dm != null:
		if dm.has_method("set_runtime_active_characters"):
			dm.call("set_runtime_active_characters", active)
		if dm.has_method("set_runtime_narrative_day"):
			dm.call("set_runtime_narrative_day", day_id)
