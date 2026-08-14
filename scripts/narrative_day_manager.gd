extends Node

const STATUS_CHECK_ICON := "res://assets/ui/icons/status-check.svg"
const STATUS_PENDING_ICON := "res://assets/ui/icons/status-pending.svg"
const DAY_BUTTON_WIDTH := 250.0

var main: Control
var data_manager: Node
var transition_manager: Node
var world_map_manager: Node
var progress_manager: Node

var day_button: Button
var journal_overlay: Control
var journal_panel: PanelContainer
var journal_title: Label
var journal_subtitle: Label
var journal_scroll: ScrollContainer
var journal_body: VBoxContainer
var puzzle_input: LineEdit
var puzzle_submit: Button
var journal_close: Button

var _busy := false
var _last_ui_signature := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for _i in range(14):
		await get_tree().process_frame
	main = get_parent() as Control
	if main == null:
		return
	data_manager = get_node_or_null("/root/DataManager")
	transition_manager = main.get_node_or_null("Version044VisitTransitions")
	world_map_manager = main.get_node_or_null("WorldMapManager")
	progress_manager = main.get_node_or_null("ProgressManager")
	if data_manager == null:
		return
	data_manager.call("ensure_loaded")
	_build_day_button()
	_build_journal()
	get_viewport().size_changed.connect(_apply_layout)
	_apply_layout()
	_ensure_current_state(true)
	_refresh_ui(true)


func _process(_delta: float) -> void:
	if main == null or data_manager == null:
		return
	var state := _state()
	if state.is_empty() or _player_id(state).is_empty():
		return
	_ensure_current_state(false)
	_refresh_ui(false)
	if _busy or journal_overlay == null or journal_overlay.visible:
		return
	if world_map_manager == null or not world_map_manager.has_method("is_open") or not bool(world_map_manager.call("is_open")):
		return
	if _transition_active():
		return
	var day_state := _current_day_state(state)
	if bool(day_state.get("ready_to_finish", false)):
		if _is_last_day(get_current_day_id()):
			if not is_arc_complete():
				_begin_arc_completion()
		else:
			_begin_day_completion()
		return
	if not bool(day_state.get("intro_seen", false)):
		_begin_day_intro()


func get_current_day_id() -> int:
	var state := _state()
	var progress := _progress_from_state(state)
	return int(progress.get("current_day", _default_day()))


func get_current_day_definition() -> Dictionary:
	if data_manager == null:
		return {}
	return data_manager.call("get_narrative_day", get_current_day_id()) as Dictionary


func get_current_day_progress() -> Dictionary:
	var state := _state()
	var day := get_current_day_definition()
	if state.is_empty() or day.is_empty():
		return {"completed": 0, "total": 0, "ready": false}
	var day_state := _current_day_state(state)
	var required := _required_visits(day, state)
	var completed_visits: Array = day_state.get("completed_visits", []) if typeof(day_state.get("completed_visits", [])) == TYPE_ARRAY else []
	var completed := 0
	var total := required.size()
	for character_id in required:
		if completed_visits.has(character_id):
			completed += 1
	var puzzle := _puzzle_definition(day)
	if not puzzle.is_empty():
		var targets := get_puzzle_clue_targets()
		var puzzle_state := _puzzle_state(day_state)
		var collected: Array = puzzle_state.get("collected_clues", [])
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
	return {
		"completed": mini(completed, total),
		"total": total,
		"ready": bool(day_state.get("ready_to_finish", false))
	}


func get_character_day_status(character_id: String) -> String:
	if character_id.is_empty():
		return "optional"
	var state := _state()
	var day := get_current_day_definition()
	if state.is_empty() or day.is_empty():
		return "optional"
	var day_state := _current_day_state(state)
	var completed_visits: Array = day_state.get("completed_visits", []) if typeof(day_state.get("completed_visits", [])) == TYPE_ARRAY else []
	if _required_visits(day, state).has(character_id):
		return "required_complete" if completed_visits.has(character_id) else "required_pending"
	var targets := get_puzzle_clue_targets()
	var puzzle_state := _puzzle_state(day_state)
	var collected: Array = puzzle_state.get("collected_clues", [])
	for clue_id in targets.keys():
		if str(targets[clue_id]) == character_id:
			return "clue_complete" if collected.has(str(clue_id)) else "clue_pending"
	return "optional"


func get_puzzle_clue_targets() -> Dictionary:
	var day := get_current_day_definition()
	var puzzle := _puzzle_definition(day)
	var result: Dictionary = {}
	if puzzle.is_empty():
		return result
	var player_id := _player_id(_state())
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
			if character_id != player_id and not used.has(character_id):
				selected = character_id
				break
		if selected.is_empty():
			for raw_character in raw_candidates as Array:
				var character_id := str(raw_character)
				if character_id != player_id:
					selected = character_id
					break
		if not selected.is_empty():
			result[clue_id] = selected
			if not used.has(selected):
				used.append(selected)
	return result


func is_arc_complete() -> bool:
	return bool(_progress_from_state(_state()).get("arc_complete", false))


func on_character_visit_completed(character_id: String) -> void:
	if main == null or data_manager == null or character_id.is_empty():
		return
	var state := _state()
	if state.is_empty():
		return
	_ensure_current_state(false)
	state = _state()
	var progress := _progress_from_state(state)
	var day_id := int(progress.get("current_day", _default_day()))
	var day := _day(day_id)
	if day.is_empty():
		return
	var day_states: Dictionary = progress.get("day_states", {})
	var key := str(day_id)
	var day_state: Dictionary = day_states.get(key, {}) if typeof(day_states.get(key, {})) == TYPE_DICTIONARY else {}
	var completed_visits: Array = day_state.get("completed_visits", []) if typeof(day_state.get("completed_visits", [])) == TYPE_ARRAY else []
	if not completed_visits.has(character_id):
		completed_visits.append(character_id)
	day_state["completed_visits"] = completed_visits

	var found_clue := ""
	var puzzle := _puzzle_definition(day)
	if not puzzle.is_empty():
		var targets := get_puzzle_clue_targets()
		var puzzle_state := _puzzle_state(day_state)
		var collected: Array = puzzle_state.get("collected_clues", [])
		for clue_id in targets.keys():
			if str(targets[clue_id]) == character_id and not collected.has(str(clue_id)):
				collected.append(str(clue_id))
				found_clue = str(clue_id)
				break
		puzzle_state["collected_clues"] = collected
		day_state["puzzle"] = puzzle_state

	day_state["ready_to_finish"] = _requirements_met(day, day_state, state)
	day_states[key] = day_state
	progress["day_states"] = day_states
	state["narrative_progress"] = progress
	_save_state(state)
	if not found_clue.is_empty():
		var group := _clue_group(puzzle, found_clue)
		var fragment := str(group.get("fragment", ""))
		var toast := "Pista encontrada"
		if not fragment.is_empty():
			toast += " · cifra " + fragment
		main.call("_show_toast", toast)
	_refresh_ui(true)
	if journal_overlay != null and journal_overlay.visible:
		_refresh_journal()


func submit_puzzle_solution(value: String) -> bool:
	var state := _state()
	var day := get_current_day_definition()
	var puzzle := _puzzle_definition(day)
	if state.is_empty() or puzzle.is_empty():
		return false
	var day_state := _current_day_state(state)
	var puzzle_state := _puzzle_state(day_state)
	if bool(puzzle_state.get("solved", false)):
		return true
	var targets := get_puzzle_clue_targets()
	var collected: Array = puzzle_state.get("collected_clues", [])
	if collected.size() < targets.size():
		if main != null:
			main.call("_show_toast", "Todavía faltan pistas por encontrar")
		return false
	puzzle_state["attempts"] = maxi(0, int(puzzle_state.get("attempts", 0))) + 1
	var normalized := value.strip_edges()
	var solved := normalized == str(puzzle.get("solution", ""))
	puzzle_state["solved"] = solved
	day_state["puzzle"] = puzzle_state
	day_state["ready_to_finish"] = _requirements_met(day, day_state, state)
	_set_current_day_state(state, day_state)
	_save_state(state)
	_refresh_ui(true)
	_refresh_journal()
	if solved:
		if progress_manager != null and progress_manager.has_method("record_event"):
			progress_manager.call("record_event", "special_event", {"event_id": str(puzzle.get("id", "narrative_puzzle"))}, state)
		if journal_overlay != null:
			journal_overlay.visible = false
		if transition_manager != null and transition_manager.has_method("play_generic_transition"):
			transition_manager.call("play_generic_transition", "CÓDIGO CORRECTO", str(puzzle.get("success_message", "El puzle está resuelto.")), 0.0, Callable())
		elif main != null:
			main.call("_show_toast", "Puzle resuelto")
		return true
	if main != null:
		main.call("_show_toast", str(puzzle.get("failure_message", "El código no encaja.")))
	return false


func open_journal() -> void:
	if journal_overlay == null:
		return
	_refresh_journal()
	journal_overlay.visible = true
	if puzzle_input != null:
		puzzle_input.release_focus()


func close_journal() -> void:
	if journal_overlay != null:
		journal_overlay.visible = false


func _ensure_current_state(save_if_changed: bool) -> void:
	var state := _state()
	if state.is_empty() or _player_id(state).is_empty() or data_manager == null:
		return
	var before := JSON.stringify(state)
	if data_manager.has_method("migrate_save_state"):
		var migrated: Variant = data_manager.call("migrate_save_state", state)
		if typeof(migrated) == TYPE_DICTIONARY:
			state = migrated as Dictionary
	var day := _day(int(_progress_from_state(state).get("current_day", _default_day())))
	if not day.is_empty():
		var day_state := _current_day_state(state)
		day_state["ready_to_finish"] = _requirements_met(day, day_state, state)
		_set_current_day_state(state, day_state)
	main.set("state", state)
	if save_if_changed and before != JSON.stringify(state):
		main.call("_save_game", false)


func _requirements_met(day: Dictionary, day_state: Dictionary, state: Dictionary) -> bool:
	var completed_visits: Array = day_state.get("completed_visits", []) if typeof(day_state.get("completed_visits", [])) == TYPE_ARRAY else []
	for character_id in _required_visits(day, state):
		if not completed_visits.has(character_id):
			return false
	var puzzle := _puzzle_definition(day)
	if not puzzle.is_empty():
		return bool(_puzzle_state(day_state).get("solved", false))
	return true


func _begin_day_intro() -> void:
	var state := _state()
	var day := get_current_day_definition()
	if state.is_empty() or day.is_empty():
		return
	var day_state := _current_day_state(state)
	day_state["intro_seen"] = true
	_set_current_day_state(state, day_state)
	_save_state(state)
	var opening: Dictionary = day.get("opening", {}) if typeof(day.get("opening", {})) == TYPE_DICTIONARY else {}
	var title := str(opening.get("title", "DÍA %d" % get_current_day_id()))
	var message := str(opening.get("message", day.get("subtitle", "")))
	_play_transition(title, message, Callable())


func _begin_day_completion() -> void:
	var day_id := get_current_day_id()
	var day := get_current_day_definition()
	var next_day := _next_day(day_id)
	if next_day <= 0:
		_begin_arc_completion()
		return
	var title := "FIN DEL DÍA %d" % day_id
	var message := str(day.get("completion_message", "La jornada ha terminado."))
	_play_transition(title, message, Callable(self, "_commit_day_advance").bind(day_id, next_day))


func _commit_day_advance(day_id: int, next_day: int) -> void:
	var state := _state()
	var progress := _progress_from_state(state)
	var day_states: Dictionary = progress.get("day_states", {})
	var key := str(day_id)
	var day_state: Dictionary = day_states.get(key, {}) if typeof(day_states.get(key, {})) == TYPE_DICTIONARY else {}
	day_state["completed"] = true
	day_state["ready_to_finish"] = false
	day_states[key] = day_state
	progress["day_states"] = day_states
	progress["current_day"] = next_day
	state["narrative_progress"] = progress
	_save_state(state)
	_refresh_ui(true)


func _begin_arc_completion() -> void:
	var state := _state()
	if state.is_empty() or is_arc_complete():
		return
	var progress := _progress_from_state(state)
	var day_id := int(progress.get("current_day", _default_day()))
	var day_states: Dictionary = progress.get("day_states", {})
	var key := str(day_id)
	var day_state: Dictionary = day_states.get(key, {}) if typeof(day_states.get(key, {})) == TYPE_DICTIONARY else {}
	day_state["completed"] = true
	day_state["ready_to_finish"] = false
	day_states[key] = day_state
	progress["day_states"] = day_states
	progress["arc_complete"] = true
	state["narrative_progress"] = progress
	_save_state(state)
	_refresh_ui(true)
	var config: Dictionary = data_manager.call("get_narrative_days") if data_manager != null else {}
	var ending: Dictionary = config.get("arc_complete", {}) if typeof(config.get("arc_complete", {})) == TYPE_DICTIONARY else {}
	_play_transition(str(ending.get("title", "PRIMER ARCO COMPLETADO")), str(ending.get("message", "Has completado los días disponibles.")), Callable())


func _play_transition(title: String, message: String, midpoint: Callable) -> void:
	if _busy:
		return
	_busy = true
	if transition_manager != null and transition_manager.has_method("play_generic_transition"):
		transition_manager.call("play_generic_transition", title, message, 0.0, midpoint)
		call_deferred("_wait_transition_finish")
		return
	if midpoint.is_valid():
		midpoint.call()
	_busy = false


func _wait_transition_finish() -> void:
	await get_tree().process_frame
	while _transition_active():
		await get_tree().process_frame
	_busy = false
	_refresh_ui(true)


func _transition_active() -> bool:
	return transition_manager != null and bool(transition_manager.get("transition_active"))


func _build_day_button() -> void:
	if world_map_manager == null or day_button != null:
		return
	var overlay_value: Variant = world_map_manager.get("overlay")
	if overlay_value is not Control:
		return
	var map_overlay := overlay_value as Control
	day_button = main.call("_make_button", "DÍA", false) as Button
	day_button.name = "NarrativeDayButton080"
	day_button.anchor_left = 0.5
	day_button.anchor_top = 0.0
	day_button.anchor_right = 0.5
	day_button.anchor_bottom = 0.0
	day_button.offset_left = -DAY_BUTTON_WIDTH * 0.5
	day_button.offset_top = 88.0
	day_button.offset_right = DAY_BUTTON_WIDTH * 0.5
	day_button.offset_bottom = 132.0
	day_button.custom_minimum_size = Vector2(DAY_BUTTON_WIDTH, 44)
	day_button.z_index = 20
	day_button.add_theme_font_size_override("font_size", 13)
	day_button.pressed.connect(open_journal)
	map_overlay.add_child(day_button)


func _build_journal() -> void:
	journal_overlay = Control.new()
	journal_overlay.name = "NarrativeJournal080"
	journal_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	journal_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	journal_overlay.z_index = 860
	journal_overlay.visible = false
	main.add_child(journal_overlay)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.008, 0.007, 0.006, 0.92)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	journal_overlay.add_child(shade)

	journal_panel = PanelContainer.new()
	journal_panel.name = "NarrativeJournalPanel080"
	journal_panel.anchor_left = 0.10
	journal_panel.anchor_top = 0.07
	journal_panel.anchor_right = 0.90
	journal_panel.anchor_bottom = 0.93
	journal_panel.add_theme_stylebox_override("panel", main.call("_panel_style", Color(0.035, 0.025, 0.020, 0.99), Color("d6a85f"), 2, 16))
	journal_overlay.add_child(journal_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	journal_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	journal_title = Label.new()
	journal_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	journal_title.add_theme_color_override("font_color", Color("f2c97e"))
	journal_title.add_theme_font_size_override("font_size", 27)
	root.add_child(journal_title)

	journal_subtitle = Label.new()
	journal_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	journal_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	journal_subtitle.add_theme_color_override("font_color", Color("d8c8b2"))
	journal_subtitle.add_theme_font_size_override("font_size", 14)
	root.add_child(journal_subtitle)

	journal_scroll = ScrollContainer.new()
	journal_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journal_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	journal_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	journal_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	journal_scroll.scroll_deadzone = 0
	journal_scroll.mouse_force_pass_scroll_events = true
	root.add_child(journal_scroll)

	journal_body = VBoxContainer.new()
	journal_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	journal_body.add_theme_constant_override("separation", 8)
	journal_scroll.add_child(journal_body)

	var puzzle_row := HBoxContainer.new()
	puzzle_row.name = "NarrativePuzzleInputRow080"
	puzzle_row.add_theme_constant_override("separation", 8)
	root.add_child(puzzle_row)

	puzzle_input = LineEdit.new()
	puzzle_input.name = "NarrativePuzzleInput080"
	puzzle_input.placeholder_text = "Introduce el código"
	puzzle_input.max_length = 12
	puzzle_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	puzzle_input.custom_minimum_size = Vector2(0, 48)
	puzzle_input.add_theme_font_size_override("font_size", 18)
	puzzle_input.text_submitted.connect(_on_puzzle_text_submitted)
	puzzle_row.add_child(puzzle_input)

	puzzle_submit = main.call("_make_button", "Resolver", true) as Button
	puzzle_submit.name = "NarrativePuzzleSubmit080"
	puzzle_submit.custom_minimum_size = Vector2(150, 48)
	puzzle_submit.pressed.connect(_submit_from_ui)
	puzzle_row.add_child(puzzle_submit)

	journal_close = main.call("_make_button", "Cerrar diario", false) as Button
	journal_close.name = "NarrativeJournalClose080"
	journal_close.custom_minimum_size = Vector2(0, 48)
	journal_close.pressed.connect(close_journal)
	root.add_child(journal_close)


func _refresh_ui(force: bool) -> void:
	var state := _state()
	if state.is_empty() or _player_id(state).is_empty():
		return
	var day := get_current_day_definition()
	var day_progress := get_current_day_progress()
	var signature := "%d|%d|%d|%s|%s" % [
		get_current_day_id(),
		int(day_progress.get("completed", 0)),
		int(day_progress.get("total", 0)),
		str(day_progress.get("ready", false)),
		str(is_arc_complete())
	]
	if not force and signature == _last_ui_signature:
		return
	_last_ui_signature = signature
	if day_button != null:
		if is_arc_complete():
			day_button.text = "ARCO 1 COMPLETADO"
			day_button.tooltip_text = "Abrir diario narrativo"
		else:
			day_button.text = "DÍA %d · %d/%d" % [get_current_day_id(), int(day_progress.get("completed", 0)), int(day_progress.get("total", 0))]
			day_button.tooltip_text = str(day.get("title", "Abrir diario narrativo"))
	if journal_overlay != null and journal_overlay.visible:
		_refresh_journal()
	if world_map_manager != null and world_map_manager.has_method("show_zone") and world_map_manager.has_method("is_open") and bool(world_map_manager.call("is_open")):
		# No rerenderizamos el mapa completo aquí; los iconos se actualizan al
		# regresar de cada habitación y el Diario refleja el cambio al instante.
		pass


func _refresh_journal() -> void:
	if journal_body == null:
		return
	for child in journal_body.get_children():
		journal_body.remove_child(child)
		child.queue_free()
	var state := _state()
	var day := get_current_day_definition()
	var day_state := _current_day_state(state)
	var day_progress := get_current_day_progress()
	journal_title.text = "DÍA %d · %s" % [get_current_day_id(), str(day.get("title", "JORNADA")).to_upper()]
	journal_subtitle.text = "%s · Progreso del día: %d/%d" % [str(day.get("subtitle", "")), int(day_progress.get("completed", 0)), int(day_progress.get("total", 0))]
	_add_section_title("OBJETIVOS")
	var required := _required_visits(day, state)
	var completed_visits: Array = day_state.get("completed_visits", []) if typeof(day_state.get("completed_visits", [])) == TYPE_ARRAY else []
	if required.is_empty():
		_add_plain_text("No hay visitas obligatorias generales en esta jornada.")
	else:
		for character_id in required:
			_add_status_row(completed_visits.has(character_id), "Hablar con " + _character_name(character_id))

	var puzzle := _puzzle_definition(day)
	var puzzle_available := not puzzle.is_empty()
	var can_submit := false
	if puzzle_available:
		_add_section_title("PUZLE · " + str(puzzle.get("title", "PISTAS")).to_upper())
		_add_plain_text(str(puzzle.get("description", "")))
		var puzzle_state := _puzzle_state(day_state)
		var collected: Array = puzzle_state.get("collected_clues", [])
		var targets := get_puzzle_clue_targets()
		var raw_groups: Variant = puzzle.get("clue_groups", [])
		if typeof(raw_groups) == TYPE_ARRAY:
			for raw_group in raw_groups as Array:
				if typeof(raw_group) != TYPE_DICTIONARY:
					continue
				var group := raw_group as Dictionary
				var clue_id := str(group.get("id", ""))
				if not targets.has(clue_id):
					continue
				var target := str(targets[clue_id])
				var found := collected.has(clue_id)
				var text := ""
				if found:
					text = str(group.get("reveal", "Pista encontrada."))
				else:
					var hints: Dictionary = group.get("destination_hints", {}) if typeof(group.get("destination_hints", {})) == TYPE_DICTIONARY else {}
					text = str(hints.get(target, "Busca a " + _character_name(target) + "."))
				_add_status_row(found, text)
		can_submit = collected.size() >= targets.size() and not bool(puzzle_state.get("solved", false))
		if bool(puzzle_state.get("solved", false)):
			_add_status_row(true, "Código resuelto: " + str(puzzle.get("solution", "")))
		elif int(puzzle_state.get("attempts", 0)) > 0:
			_add_plain_text("Intentos realizados: %d" % int(puzzle_state.get("attempts", 0)))

	if puzzle_input != null:
		puzzle_input.visible = puzzle_available and not bool(_puzzle_state(day_state).get("solved", false))
		puzzle_input.editable = can_submit
		if not puzzle_input.editable:
			puzzle_input.placeholder_text = "Reúne todas las pistas" if puzzle_available else ""
		else:
			puzzle_input.placeholder_text = "Introduce el código"
	if puzzle_submit != null:
		puzzle_submit.visible = puzzle_available and not bool(_puzzle_state(day_state).get("solved", false))
		puzzle_submit.disabled = not can_submit

	if is_arc_complete():
		_add_section_title("ESTADO")
		_add_status_row(true, "Primer arco narrativo completado. Puedes seguir explorando y revisitando al grupo.")
	call_deferred("_relax_journal_scroll")


func _add_section_title(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color("f2c97e"))
	label.add_theme_font_size_override("font_size", 16)
	journal_body.add_child(label)


func _add_plain_text(text: String) -> void:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color("cdbda8"))
	label.add_theme_font_size_override("font_size", 14)
	journal_body.add_child(label)


func _add_status_row(done: bool, text: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	journal_body.add_child(row)
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(18, 18)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var path := STATUS_CHECK_ICON if done else STATUS_PENDING_ICON
	if ResourceLoader.exists(path):
		icon.texture = ResourceLoader.load(path) as Texture2D
	row.add_child(icon)
	var label := Label.new()
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color("f0dfc7") if done else Color("cbb9a1"))
	label.add_theme_font_size_override("font_size", 14)
	row.add_child(label)


func _submit_from_ui() -> void:
	if puzzle_input != null:
		submit_puzzle_solution(puzzle_input.text)
		if not is_arc_complete():
			puzzle_input.select_all()


func _on_puzzle_text_submitted(text: String) -> void:
	submit_puzzle_solution(text)


func _relax_journal_scroll() -> void:
	if journal_scroll == null:
		return
	for node in journal_scroll.find_children("*", "Control", true, false):
		if node is Control and node != journal_scroll:
			(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func _apply_layout() -> void:
	if journal_panel == null:
		return
	var viewport := get_viewport().get_visible_rect().size
	var compact := viewport.x < 760.0 or viewport.y > viewport.x
	journal_panel.anchor_left = 0.025 if compact else 0.10
	journal_panel.anchor_right = 0.975 if compact else 0.90
	journal_panel.anchor_top = 0.025 if compact else 0.07
	journal_panel.anchor_bottom = 0.975 if compact else 0.93
	if journal_title != null:
		journal_title.add_theme_font_size_override("font_size", 22 if compact else 27)
	if day_button != null:
		var width := 208.0 if compact else DAY_BUTTON_WIDTH
		day_button.offset_left = -width * 0.5
		day_button.offset_right = width * 0.5
		day_button.custom_minimum_size.x = width


func _required_visits(day: Dictionary, state: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var player_id := _player_id(state)
	var raw: Variant = day.get("required_visits", [])
	if typeof(raw) == TYPE_STRING and str(raw) == "all_available":
		var ids: Array = data_manager.call("get_character_ids", true)
		for raw_id in ids:
			var character_id := str(raw_id)
			if not bool(day.get("exclude_player", true)) or character_id != player_id:
				result.append(character_id)
	elif typeof(raw) == TYPE_ARRAY:
		for raw_id in raw as Array:
			var character_id := str(raw_id)
			if character_id.is_empty() or (bool(day.get("exclude_player", true)) and character_id == player_id):
				continue
			if not result.has(character_id):
				result.append(character_id)
	return result


func _puzzle_definition(day: Dictionary) -> Dictionary:
	var raw: Variant = day.get("puzzle", null)
	return (raw as Dictionary).duplicate(true) if typeof(raw) == TYPE_DICTIONARY else {}


func _puzzle_state(day_state: Dictionary) -> Dictionary:
	var raw: Variant = day_state.get("puzzle", {})
	if typeof(raw) != TYPE_DICTIONARY:
		return {"collected_clues": [], "attempts": 0, "solved": false}
	var result := (raw as Dictionary).duplicate(true)
	if typeof(result.get("collected_clues", [])) != TYPE_ARRAY:
		result["collected_clues"] = []
	result["attempts"] = maxi(0, int(result.get("attempts", 0)))
	result["solved"] = bool(result.get("solved", false))
	return result


func _clue_group(puzzle: Dictionary, clue_id: String) -> Dictionary:
	var raw: Variant = puzzle.get("clue_groups", [])
	if typeof(raw) != TYPE_ARRAY:
		return {}
	for item in raw as Array:
		if typeof(item) == TYPE_DICTIONARY and str((item as Dictionary).get("id", "")) == clue_id:
			return (item as Dictionary).duplicate(true)
	return {}


func _current_day_state(state: Dictionary) -> Dictionary:
	var progress := _progress_from_state(state)
	var day_states: Dictionary = progress.get("day_states", {}) if typeof(progress.get("day_states", {})) == TYPE_DICTIONARY else {}
	var key := str(int(progress.get("current_day", _default_day())))
	return (day_states.get(key, {}) as Dictionary).duplicate(true) if typeof(day_states.get(key, {})) == TYPE_DICTIONARY else {}


func _set_current_day_state(state: Dictionary, day_state: Dictionary) -> void:
	var progress := _progress_from_state(state)
	var day_states: Dictionary = progress.get("day_states", {}) if typeof(progress.get("day_states", {})) == TYPE_DICTIONARY else {}
	day_states[str(int(progress.get("current_day", _default_day())))] = day_state
	progress["day_states"] = day_states
	state["narrative_progress"] = progress


func _progress_from_state(state: Dictionary) -> Dictionary:
	var raw: Variant = state.get("narrative_progress", {})
	return (raw as Dictionary).duplicate(true) if typeof(raw) == TYPE_DICTIONARY else {"current_day": _default_day(), "day_states": {}, "arc_complete": false}


func _state() -> Dictionary:
	if main == null:
		return {}
	var raw: Variant = main.get("state")
	return raw as Dictionary if typeof(raw) == TYPE_DICTIONARY else {}


func _save_state(state: Dictionary) -> void:
	if main == null:
		return
	main.set("state", state)
	main.call("_save_game", false)


func _player_id(state: Dictionary) -> String:
	var raw: Variant = state.get("player", {})
	return str((raw as Dictionary).get("id", "")) if typeof(raw) == TYPE_DICTIONARY else ""


func _default_day() -> int:
	return int(data_manager.call("get_default_narrative_day")) if data_manager != null and data_manager.has_method("get_default_narrative_day") else 1


func _day(day_id: int) -> Dictionary:
	return data_manager.call("get_narrative_day", day_id) as Dictionary if data_manager != null and data_manager.has_method("get_narrative_day") else {}


func _day_ids() -> Array:
	return data_manager.call("get_narrative_day_ids") as Array if data_manager != null and data_manager.has_method("get_narrative_day_ids") else []


func _is_last_day(day_id: int) -> bool:
	var ids := _day_ids()
	return not ids.is_empty() and day_id == int(ids[ids.size() - 1])


func _next_day(day_id: int) -> int:
	var ids := _day_ids()
	var index := ids.find(day_id)
	return int(ids[index + 1]) if index >= 0 and index + 1 < ids.size() else 0


func _character_name(character_id: String) -> String:
	if data_manager == null:
		return character_id.capitalize()
	var character: Dictionary = data_manager.call("get_character", character_id)
	return str(character.get("display_name", character.get("name", character_id.capitalize())))
