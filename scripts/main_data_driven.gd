extends "res://scripts/main.gd"

const DataAccess = preload("res://scripts/data_access.gd")
const DataStory = preload("res://scripts/story.gd")
const RuntimeGameData = preload("res://scripts/game_data.gd")
const RuntimeAudioManager = preload("res://scripts/audio_manager.gd")


func _dm() -> Variant:
	return DataAccess.dm()


func _ready() -> void:
	var dm: Variant = _dm()
	if dm != null:
		dm.call("ensure_loaded")
	RuntimeGameData.refresh()
	DataStory.refresh()
	RuntimeAudioManager.refresh_configuration()
	super._ready()
	_sync_dynamic_character_slots()
	_apply_persisted_display_settings()


func _sync_dynamic_character_slots() -> void:
	var dm: Variant = _dm()
	if dm == null:
		return
	var ids: Array = dm.call("get_character_ids", true)
	for raw_id in ids:
		var character_id := str(raw_id)
		if character_slots.has(character_id):
			continue
		_create_character(character_id, "center")


func _fresh_state() -> Dictionary:
	var fresh := {
		"node_id": DataStory.START,
		"affinity": _empty_affinity(),
		"expressions": _neutral_expressions(),
		"history": [],
		"coins": 0,
		"claimed_rewards": {},
		"current_zone_id": "naranjal_del_rio"
	}
	var dm: Variant = _dm()
	if dm != null and dm.has_method("migrate_save_state"):
		return dm.call("migrate_save_state", fresh)
	return fresh


func _empty_affinity() -> Dictionary:
	var affinity := {}
	var dm: Variant = _dm()
	if dm == null:
		return affinity
	var ids: Array = dm.call("get_character_ids", false)
	for raw_id in ids:
		var character_id := str(raw_id)
		affinity[character_id] = int(dm.call("get_initial_friendship", character_id))
	return affinity


func _neutral_expressions() -> Dictionary:
	var expressions := {}
	var dm: Variant = _dm()
	if dm == null:
		return expressions
	var ids: Array = dm.call("get_character_ids", false)
	for raw_id in ids:
		expressions[str(raw_id)] = "neutral"
	return expressions


func _show_menu() -> void:
	super._show_menu()
	var dm: Variant = _dm()
	if continue_button != null and dm != null:
		continue_button.disabled = not bool(dm.call("has_save"))


func _save_game(show_message: bool) -> void:
	if state.is_empty():
		return
	var dm: Variant = _dm()
	if dm == null:
		if show_message:
			_show_toast("No se ha podido guardar")
		return
	if dm.has_method("migrate_save_state"):
		state = dm.call("migrate_save_state", state)
	state["save_version"] = str(ProjectSettings.get_setting("application/config/version", "0.6.0"))
	if not bool(dm.call("save_game", state)):
		if show_message:
			_show_toast("No se ha podido guardar")
		return
	if show_message:
		_show_toast("Partida guardada")


func _read_save() -> bool:
	var dm: Variant = _dm()
	if dm == null:
		return false
	var loaded: Dictionary = dm.call("load_game")
	if loaded.is_empty():
		return false
	state = loaded
	if dm.has_method("migrate_save_state"):
		state = dm.call("migrate_save_state", state)
	if not state.has("affinity") or typeof(state["affinity"]) != TYPE_DICTIONARY:
		state["affinity"] = _empty_affinity()
	if not state.has("expressions") or typeof(state["expressions"]) != TYPE_DICTIONARY:
		state["expressions"] = _neutral_expressions()
	if not state.has("history") or typeof(state["history"]) != TYPE_ARRAY:
		state["history"] = []
	var ids: Array = dm.call("get_character_ids", false)
	for raw_id in ids:
		var character_id := str(raw_id)
		if not state["affinity"].has(character_id):
			state["affinity"][character_id] = int(dm.call("get_initial_friendship", character_id))
		if not state["expressions"].has(character_id):
			state["expressions"][character_id] = "neutral"
	var saved_node := str(state.get("node_id", DataStory.START))
	if saved_node != "__END__":
		if DataStory.LEGACY_START_NODES.has(saved_node) or not DataStory.NODES.has(saved_node):
			saved_node = DataStory.start_for_player(_player_character_id())
		else:
			saved_node = DataStory.resolve_for_player(saved_node, _player_character_id())
		state["node_id"] = saved_node
	for character in state["expressions"].keys():
		_apply_expression(str(character), str(state["expressions"][character]))
	return true


func _go_to(node_id: String, add_to_history: bool = true) -> void:
	super._go_to(node_id, add_to_history)
	if state.is_empty() or not bool(state.get("visit_mode", false)):
		return
	var resolved_node_id := str(state.get("node_id", ""))
	var scene_id := str(current_node.get("scene_id", ""))
	# Cada introducción de habitación es una escena real y estable que el juego
	# ya puede detectar. Los futuros nodos pueden declarar `scene_id` de forma
	# explícita sin ampliar esta lógica.
	if scene_id.is_empty() and resolved_node_id.ends_with("_intro_01"):
		scene_id = resolved_node_id
	if scene_id.is_empty():
		return
	var progress := get_node_or_null("ProgressManager")
	if progress != null and progress.has_method("record_event"):
		progress.call("record_event", "scene_discovered", {
			"scene_id": scene_id,
			"node_id": resolved_node_id
		}, state)


func _chapter_for_node(node_id: String, node: Dictionary) -> String:
	var character_id: String = DataStory.character_for_node(node_id)
	var encounter_order: Array[String] = DataStory.encounter_order_for_player(_player_character_id())
	var encounter_index := encounter_order.find(character_id)
	if encounter_index < 0:
		return str(node.get("chapter", "ENCUENTRO"))
	var encounter: Dictionary = DataStory.ENCOUNTERS.get(character_id, {})
	var display_name := str(encounter.get("name", character_id))
	var chapter := "ENCUENTRO %d/%d · %s" % [encounter_index + 1, encounter_order.size(), display_name.to_upper()]
	if node.has("question_number"):
		chapter += " · PREGUNTA %d/%d" % [int(node["question_number"]), maxi(1, DataStory.question_count(character_id))]
	return chapter


func _render_choices(choices: Array) -> void:
	_clear_choices()
	var minimum_height := 112.0 if portrait_layout else 94.0
	for choice in choices:
		var button := _make_button(str(choice.get("label", "Elegir")), false)
		button.custom_minimum_size = Vector2(0, minimum_height)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.clip_text = true
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_constant_override("line_spacing", 2)
		button.pressed.connect(_choose.bind(choice))
		choices_box.add_child(button)
	choices_box.visible = true


func _choose(choice: Dictionary) -> void:
	var dm: Variant = _dm()
	var affinity: Dictionary = choice.get("affinity", {})
	for character in affinity.keys():
		var amount := int(affinity[character])
		var initial := int(dm.call("get_initial_friendship", str(character))) if dm != null else 0
		state["affinity"][character] = int(state["affinity"].get(character, initial)) + amount
		var encounter: Dictionary = DataStory.ENCOUNTERS.get(str(character), {})
		var display_name := str(encounter.get("name", str(character)))
		var prefix := "+" if amount >= 0 else ""
		_show_toast(display_name + " " + prefix + str(amount) + " afinidad")
	var choice_label := str(choice.get("label", ""))
	state["history"].append({"choice": choice_label})
	var progress := get_node_or_null("ProgressManager")
	if progress != null and progress.has_method("record_event"):
		progress.call("record_event", "decision_taken", {
			"choice": choice_label,
			"node_id": str(state.get("node_id", ""))
		}, state)
	_go_to(str(choice.get("next", "__END__")))


func _finish_demo() -> void:
	_save_game(false)
	game_screen.visible = false
	menu_screen.visible = false
	ending_screen.visible = true
	var dm: Variant = _dm()
	var affinity: Dictionary = state.get("affinity", {})
	var encounter_order: Array[String] = DataStory.encounter_order_for_player(_player_character_id())
	var result_lines := PackedStringArray()
	var total := 0
	var total_max := 0
	for character_id in encounter_order:
		var maximum := maxi(0, DataStory.max_affinity_for_character(character_id))
		var initial := int(dm.call("get_initial_friendship", character_id)) if dm != null else 0
		var value := int(affinity.get(character_id, initial))
		value = clampi(value, 0, maximum) if maximum > 0 else maxi(0, value)
		total += value
		total_max += maximum
		var encounter: Dictionary = DataStory.ENCOUNTERS.get(character_id, {})
		var display_name := str(encounter.get("name", character_id))
		result_lines.append("%s  %d/%d · %s" % [display_name, value, maximum, _friendship_level_for(value, maximum)])
	result_lines.append("")
	result_lines.append("TOTAL  %d/%d" % [total, total_max])
	ending_affinity.text = "\n".join(result_lines)


func _friendship_level_for(value: int, maximum: int) -> String:
	if value <= 0 or maximum <= 0:
		return "Aún os estáis conociendo"
	var ratio := float(value) / float(maximum)
	if ratio <= 0.34:
		return "Primer punto de conexión"
	if ratio <= 0.67:
		return "Buena amistad"
	return "Amistad muy fuerte"


func _toggle_fullscreen() -> void:
	super._toggle_fullscreen()
	var dm: Variant = _dm()
	if dm == null:
		return
	var mode := DisplayServer.window_get_mode()
	var enabled := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	dm.call("set_fullscreen", enabled)


func _apply_persisted_display_settings() -> void:
	if OS.has_feature("web"):
		return
	var dm: Variant = _dm()
	if dm != null and bool(dm.call("get_fullscreen")):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
