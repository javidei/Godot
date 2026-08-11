extends "res://scripts/main.gd"

const DataStory = preload("res://scripts/story.gd")
const RuntimeGameData = preload("res://scripts/game_data.gd")
const RuntimeAudioManager = preload("res://scripts/audio_manager.gd")


func _ready() -> void:
	DataManager.ensure_loaded()
	RuntimeGameData.refresh()
	DataStory.refresh()
	RuntimeAudioManager.refresh_configuration()
	super._ready()
	_sync_dynamic_character_slots()
	_apply_persisted_display_settings()


func _sync_dynamic_character_slots() -> void:
	for character_id in DataManager.get_character_ids(true):
		if character_slots.has(character_id):
			continue
		_create_character(character_id, "center")


func _fresh_state() -> Dictionary:
	return {
		"node_id": DataStory.START,
		"affinity": _empty_affinity(),
		"expressions": _neutral_expressions(),
		"history": []
	}


func _empty_affinity() -> Dictionary:
	var affinity := {}
	for character_id in DataManager.get_character_ids(false):
		affinity[character_id] = DataManager.get_initial_friendship(character_id)
	return affinity


func _neutral_expressions() -> Dictionary:
	var expressions := {}
	for character_id in DataManager.get_character_ids(false):
		expressions[character_id] = "neutral"
	return expressions


func _show_menu() -> void:
	super._show_menu()
	if continue_button != null:
		continue_button.disabled = not DataManager.has_save()


func _save_game(show_message: bool) -> void:
	if state.is_empty():
		return
	state["save_version"] = str(ProjectSettings.get_setting("application/config/version", "0.5.1"))
	if not DataManager.save_game(state):
		if show_message:
			_show_toast("No se ha podido guardar")
		return
	if show_message:
		_show_toast("Partida guardada")


func _read_save() -> bool:
	var loaded := DataManager.load_game()
	if loaded.is_empty():
		return false
	state = loaded
	if not state.has("affinity") or typeof(state["affinity"]) != TYPE_DICTIONARY:
		state["affinity"] = _empty_affinity()
	if not state.has("expressions") or typeof(state["expressions"]) != TYPE_DICTIONARY:
		state["expressions"] = _neutral_expressions()
	if not state.has("history") or typeof(state["history"]) != TYPE_ARRAY:
		state["history"] = []
	for character_id in DataManager.get_character_ids(false):
		if not state["affinity"].has(character_id):
			state["affinity"][character_id] = DataManager.get_initial_friendship(character_id)
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


func _chapter_for_node(node_id: String, node: Dictionary) -> String:
	var character_id: String = DataStory.character_for_node(node_id)
	var encounter_order: Array[String] = DataStory.encounter_order_for_player(_player_character_id())
	var encounter_index := encounter_order.find(character_id)
	if encounter_index < 0:
		return str(node.get("chapter", "ENCUENTRO"))
	var encounter: Dictionary = DataStory.ENCOUNTERS.get(character_id, {})
	var display_name := str(encounter.get("name", character_id))
	var chapter := "ENCUENTRO %d/%d · %s" % [
		encounter_index + 1,
		encounter_order.size(),
		display_name.to_upper()
	]
	if node.has("question_number"):
		chapter += " · PREGUNTA %d/%d" % [int(node["question_number"]), maxi(1, DataStory.question_count(character_id))]
	return chapter


func _choose(choice: Dictionary) -> void:
	var affinity: Dictionary = choice.get("affinity", {})
	for character in affinity.keys():
		var amount := int(affinity[character])
		state["affinity"][character] = int(state["affinity"].get(character, DataManager.get_initial_friendship(str(character)))) + amount
		var encounter: Dictionary = DataStory.ENCOUNTERS.get(str(character), {})
		var display_name := str(encounter.get("name", str(character)))
		var prefix := "+" if amount >= 0 else ""
		_show_toast(display_name + " " + prefix + str(amount) + " afinidad")
	state["history"].append({"choice": str(choice.get("label", ""))})
	_go_to(str(choice.get("next", "__END__")))


func _finish_demo() -> void:
	_save_game(false)
	game_screen.visible = false
	menu_screen.visible = false
	ending_screen.visible = true
	var affinity: Dictionary = state.get("affinity", {})
	var encounter_order: Array[String] = DataStory.encounter_order_for_player(_player_character_id())
	var result_lines := PackedStringArray()
	var total := 0
	var total_max := 0
	for character_id in encounter_order:
		var maximum := maxi(0, DataStory.max_affinity_for_character(character_id))
		var value := int(affinity.get(character_id, DataManager.get_initial_friendship(character_id)))
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
	var mode := DisplayServer.window_get_mode()
	var enabled := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	DataManager.set_fullscreen(enabled)


func _apply_persisted_display_settings() -> void:
	if OS.has_feature("web"):
		return
	if DataManager.get_fullscreen():
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
