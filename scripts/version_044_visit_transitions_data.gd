extends "res://scripts/version_044_visit_transitions.gd"

const DataAccess = preload("res://scripts/data_access.gd")
const DataStory = preload("res://scripts/story.gd")

const NEW_GAME_INTRO_TITLE := "2026"
const NEW_GAME_INTRO_TEXT := "Los hechos acontecieron desde 2026."

var last_missing_map_excuse := ""


func _dm() -> Variant:
	return DataAccess.dm()


func _ready() -> void:
	# La implementación histórica esperaba ocho frames. La capa genérica se usa
	# también antes de seleccionar protagonista, así que la preparamos en cuanto
	# Main ha terminado de construir la interfaz.
	for _i in range(3):
		await get_tree().process_frame
	main = get_parent() as Control
	if main == null:
		return
	version_manager = main.get_node_or_null("Version040Manager")
	audio_manager = main.get("audio_manager") as Node
	if overlay == null:
		_build_overlay()
	_apply_transition_layout()
	if not get_viewport().size_changed.is_connected(_apply_transition_layout):
		get_viewport().size_changed.connect(_apply_transition_layout)
	_ensure_story_patches()
	_ensure_transition_state(true)


func _ensure_story_patches() -> void:
	var dm: Variant = _dm()
	for character_id in DataStory.ENCOUNTER_ORDER:
		var outro_id := _outro_node_id(character_id)
		var background_id := str(dm.call("get_character_background_id", character_id)) if dm != null else ""
		DataStory.NODES[outro_id] = {
			"speaker": "",
			"text": "",
			"background": "casa_asturias" if background_id.is_empty() else background_id,
			"show": [character_id],
			"focus": character_id,
			"chapter": "DESPEDIDA"
		}
		for feedback_id in DataStory.final_feedback_ids(character_id):
			if DataStory.NODES.has(feedback_id):
				DataStory.NODES[feedback_id]["next"] = outro_id


func begin_character_visit(character_id: String) -> void:
	if character_id.is_empty() or transition_active:
		return
	_on_visit_selected(character_id)


func play_new_game_intro(on_finished: Callable = Callable()) -> void:
	play_generic_transition(
		NEW_GAME_INTRO_TITLE,
		NEW_GAME_INTRO_TEXT,
		4.0,
		on_finished
	)


func play_missing_map_transition(
	_zone_id: String,
	zone_name: String,
	on_midpoint: Callable = Callable()
) -> void:
	var excuse := _pick_missing_map_excuse()
	play_generic_transition(zone_name.to_upper(), excuse, 4.5, on_midpoint)


func play_generic_transition(
	title: String,
	message: String,
	auto_continue_seconds: float = 0.0,
	on_midpoint: Callable = Callable()
) -> void:
	if transition_active:
		return
	_ensure_runtime_overlay()
	if overlay == null:
		if on_midpoint.is_valid():
			on_midpoint.call()
		return
	transition_active = true
	_prepare_generic_text(title, message)
	overlay.visible = true
	shade.modulate.a = 0.0
	text_box.modulate.a = 0.0
	await _fade(shade, 1.0, 0.42)
	await _fade(text_box, 1.0, 0.20)
	await _wait_for_continue_or_timeout(auto_continue_seconds)
	await _fade(text_box, 0.0, 0.16)
	if on_midpoint.is_valid():
		on_midpoint.call()
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade(shade, 0.0, 0.42)
	overlay.visible = false
	transition_active = false


func _ensure_runtime_overlay() -> void:
	if main == null:
		main = get_parent() as Control
	if main == null:
		return
	if version_manager == null:
		version_manager = main.get_node_or_null("Version040Manager")
	if audio_manager == null:
		audio_manager = main.get("audio_manager") as Node
	if overlay == null:
		_build_overlay()


func _prepare_generic_text(title: String, message: String) -> void:
	name_label.text = title
	message_label.text = message
	hint_label.text = "Pulsa o haz clic para continuar"


func _apply_transition_layout() -> void:
	if text_box == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	text_box.custom_minimum_size.x = clampf(viewport_size.x - 48.0, 280.0, 760.0)
	if message_label != null:
		message_label.add_theme_font_size_override("font_size", 18 if viewport_size.x < 720.0 else 22)
	if name_label != null:
		name_label.add_theme_font_size_override("font_size", 23 if viewport_size.x < 720.0 else 27)


func _wait_for_continue_or_timeout(seconds: float) -> void:
	if fast_mode:
		await get_tree().process_frame
		return
	continue_requested = false
	waiting_for_continue = true
	var started_at := Time.get_ticks_msec()
	while not continue_requested:
		if seconds > 0.0 and float(Time.get_ticks_msec() - started_at) >= seconds * 1000.0:
			break
		await get_tree().process_frame
	waiting_for_continue = false
	continue_requested = false


func _pick_missing_map_excuse() -> String:
	var excuses := _missing_map_excuses()
	if excuses.is_empty():
		return "El mapa de esta zona todavía no está disponible. El cartógrafo promete que estaba trabajando en ello."
	var state := _state()
	var previous := str(state.get("last_missing_map_excuse", last_missing_map_excuse)) if not state.is_empty() else last_missing_map_excuse
	var candidates: Array[String] = []
	for excuse in excuses:
		if excuse != previous or excuses.size() == 1:
			candidates.append(excuse)
	var selected: String = str(candidates.pick_random()) if not candidates.is_empty() else str(excuses[0])
	last_missing_map_excuse = selected
	if not state.is_empty():
		state["last_missing_map_excuse"] = selected
		main.set("state", state)
		main.call("_save_game", false)
	return selected


func _missing_map_excuses() -> Array[String]:
	var result: Array[String] = []
	var dm: Variant = _dm()
	if dm == null or not dm.has_method("get_missing_map_excuses"):
		return result
	var raw: Variant = dm.call("get_missing_map_excuses")
	if typeof(raw) == TYPE_DICTIONARY:
		raw = (raw as Dictionary).get("excuses", [])
	if typeof(raw) != TYPE_ARRAY:
		return result
	for value in raw as Array:
		var text := str(value).strip_edges()
		if not text.is_empty():
			result.append(text)
	return result


func _play_intro(character_id: String) -> void:
	transition_active = true
	var dm: Variant = _dm()
	var message := str(dm.call("get_transition_text", character_id, "intro")) if dm != null else ""
	if message.is_empty():
		message = "Una nueva visita está a punto de comenzar."
	_prepare_text(character_id, message)
	overlay.visible = true
	shade.modulate.a = 0.0
	text_box.modulate.a = 0.0
	await _fade(shade, 1.0, 0.55)
	_start_character_music(character_id)
	await _fade(text_box, 1.0, 0.22)
	await _wait_for_continue()
	await _fade(text_box, 0.0, 0.18)
	_mark_intro_seen(character_id)
	version_manager.call("_hide_selector")
	main.call("_go_to", character_id + "_intro_01", false)
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade(shade, 0.0, 0.55)
	overlay.visible = false
	transition_active = false


func _start_character_music(character_id: String) -> void:
	if audio_manager == null:
		return
	var dm: Variant = _dm()
	var background_id := str(dm.call("get_character_background_id", character_id)) if dm != null else ""
	if background_id.is_empty():
		return
	audio_manager.call("play_background_music", background_id)


func _play_outro(character_id: String) -> void:
	if transition_active:
		return
	transition_active = true
	pending_outro = ""
	var state := _state()
	_ensure_transition_arrays(state)
	var outros: Array = state.get("outro_transitions_seen", [])
	if outros.has(character_id):
		_complete_visit(character_id)
		main.call("_go_to", VISIT_NODE, false)
		transition_active = false
		return
	var dm: Variant = _dm()
	var message := str(dm.call("get_transition_text", character_id, "outro")) if dm != null else ""
	if message.is_empty():
		message = "La visita termina por ahora."
	_prepare_text(character_id, message)
	overlay.visible = true
	shade.modulate.a = 0.0
	text_box.modulate.a = 0.0
	await _fade(shade, 1.0, 0.55)
	await _fade(text_box, 1.0, 0.22)
	await _wait_for_continue()
	await _fade(text_box, 0.0, 0.18)
	_complete_visit(character_id)
	main.call("_go_to", VISIT_NODE, false)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade(shade, 0.0, 0.55)
	overlay.visible = false
	transition_active = false


func _complete_visit(character_id: String) -> void:
	var before := _state()
	var previous_completed: Variant = before.get("completed_characters", [])
	var was_completed := typeof(previous_completed) == TYPE_ARRAY and (previous_completed as Array).has(character_id)
	super(character_id)
	var state := _state()
	var progress := main.get_node_or_null("ProgressManager") if main != null else null
	if progress == null:
		return
	if progress.has_method("record_event"):
		progress.call("record_event", "character_visited", {
			"character_id": character_id,
			"location_id": str(state.get("current_zone_id", "")),
			"first_visit": not was_completed
		}, state)
	main.set("state", state)
	main.call("_save_game", false)


func _prepare_text(character_id: String, message: String) -> void:
	var dm: Variant = _dm()
	var data: Dictionary = dm.call("get_character", character_id) if dm != null else {}
	var display_name := str(data.get("display_name", data.get("name", character_id.capitalize())))
	name_label.text = display_name.to_upper()
	message_label.text = message
