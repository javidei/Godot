extends "res://scripts/version_044_visit_transitions.gd"

const DataAccess = preload("res://scripts/data_access.gd")
const DataStory = preload("res://scripts/story.gd")


func _dm() -> Variant:
	return DataAccess.dm()


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


func _prepare_text(character_id: String, message: String) -> void:
	var dm: Variant = _dm()
	var data: Dictionary = dm.call("get_character", character_id) if dm != null else {}
	var display_name := str(data.get("display_name", data.get("name", character_id.capitalize())))
	name_label.text = display_name.to_upper()
	message_label.text = message
