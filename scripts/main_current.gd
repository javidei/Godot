extends "res://scripts/main_data_driven.gd"

const StoryCurrent = preload("res://scripts/story.gd")
const JAVI_BATTLE_STORY_INTRO_COMPLETED_FLAG := "javi_battle_story_intro_completed_0931"


func _show_menu() -> void:
	var has_player := not state.is_empty() and typeof(state.get("player", null)) == TYPE_DICTIONARY
	if has_player:
		_save_game(false)
	super()
	var save_slots := get_node_or_null("SaveSlotsManager")
	if save_slots != null and save_slots.has_method("_refresh_continue_state"):
		save_slots.call("_refresh_continue_state")


func _save_game(show_message: bool) -> void:
	# Los nodos de reencuentro son transitorios: se persiste el checkpoint real.
	if bool(current_node.get("transient_resume", false)):
		var target := str(current_node.get("resume_target", ""))
		var runtime_node := str(state.get("node_id", ""))
		if not target.is_empty():
			state["node_id"] = target
			super(show_message)
			state["node_id"] = runtime_node
			return
	super(show_message)


func _go_to(node_id: String, add_to_history: bool = true) -> void:
	# La introducción narrativa de la batalla se consume únicamente al llegar al
	# primer insulto; salir antes conserva el prólogo como checkpoint.
	if _finishes_javi_story_intro(node_id):
		state[JAVI_BATTLE_STORY_INTRO_COMPLETED_FLAG] = true
		var dm: Variant = _dm()
		if dm != null and dm.has_method("mark_javi_insult_battle_entered"):
			dm.call("mark_javi_insult_battle_entered", state)

	super(node_id, add_to_history)

	var routes := get_node_or_null("NarrativeRouteManager")
	if routes == null or current_node.is_empty():
		return
	var route_event := str(current_node.get("route_event", ""))
	if not route_event.is_empty() and routes.has_method("record_scene_event"):
		routes.call("record_scene_event", route_event)
	var easter_egg_id := str(current_node.get("easter_egg_id", ""))
	if not easter_egg_id.is_empty() and routes.has_method("record_easter_egg"):
		routes.call("record_easter_egg", easter_egg_id)


func _choose(choice: Dictionary) -> void:
	var routes := get_node_or_null("NarrativeRouteManager")
	if routes != null and routes.has_method("record_choice"):
		routes.call(
			"record_choice",
			str(state.get("node_id", "")),
			str(choice.get("label", "")),
			str(choice.get("route_event", ""))
		)

	if _is_javi_battle_question():
		var dm: Variant = _dm()
		if dm != null and dm.has_method("record_javi_insult_answer"):
			dm.call("record_javi_insult_answer", state, int(current_node.get("question_number", 0)))

	super(choice)


func _read_save() -> bool:
	# Guardamos el nodo del slot antes de que Story se reconstruya para poder
	# migrar partidas antiguas que estaban dentro de la batalla de Javi.
	var dm: Variant = _dm()
	var saved_node := ""
	var saved_day := 0
	if dm != null:
		var preview: Dictionary = dm.call("load_game")
		if not preview.is_empty():
			saved_node = str(preview.get("node_id", ""))
			saved_day = _state_day(preview)

	if not super():
		return false

	if saved_day != 3 or not saved_node.begins_with("javi_"):
		return true

	var battle_manager := get_node_or_null("Version040Manager")
	if battle_manager == null or not battle_manager.has_method("prepare_javi_battle_resume_from_save"):
		return true
	var resume_node := str(battle_manager.call("prepare_javi_battle_resume_from_save", state))
	if not resume_node.is_empty():
		state["node_id"] = resume_node
	return true


func _chapter_for_node(node_id: String, node: Dictionary) -> String:
	var character_id: String = StoryCurrent.character_for_node(node_id)
	var encounter_order: Array[String] = StoryCurrent.encounter_order_for_player(_player_character_id())
	var encounter_index := encounter_order.find(character_id)
	if encounter_index < 0:
		return str(node.get("chapter", "ENCUENTRO"))
	var chapter := "ENCUENTRO %d/%d · %s" % [
		encounter_index + 1,
		encounter_order.size(),
		_character_display_name(character_id).to_upper()
	]
	if node.has("question_number"):
		chapter += " · PREGUNTA %d/%d" % [
			int(node.get("question_number", 1)),
			maxi(1, int(node.get("question_count", 1)))
		]
	return chapter


func _character_display_name(character_id: String) -> String:
	var dm: Variant = _dm()
	if dm != null and dm.has_method("get_character"):
		var data: Variant = dm.call("get_character", character_id)
		if typeof(data) == TYPE_DICTIONARY:
			var display_name := str((data as Dictionary).get("display_name", ""))
			if not display_name.is_empty():
				return display_name
	return character_id.capitalize()


func _finishes_javi_story_intro(next_node_id: String) -> bool:
	if state.is_empty() or _state_day(state) != 3:
		return false
	var current_id := str(state.get("node_id", ""))
	if not current_id.begins_with("javi_intro_") or not next_node_id.begins_with("javi_q"):
		return false
	return str(current_node.get("next", "")) == next_node_id


func _is_javi_battle_question() -> bool:
	if state.is_empty() or _state_day(state) != 3:
		return false
	if not str(state.get("node_id", "")).begins_with("javi_q"):
		return false
	return str(current_node.get("question_character", "")) == "javi" and int(current_node.get("question_number", 0)) > 0


func _state_day(source: Dictionary) -> int:
	var progress: Variant = source.get("narrative_progress", {})
	return int((progress as Dictionary).get("current_day", 1)) if typeof(progress) == TYPE_DICTIONARY else 1
