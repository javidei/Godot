extends "res://scripts/version_080_visit_transitions.gd"

const NewGamePrelude = preload("res://scripts/new_game_prelude_0922.gd")
const RuntimeStory = preload("res://scripts/story.gd")

var _new_game_prelude: Control
var _next_generic_starts_black := false
var _javi_day3_entry_node := ""


# Las revisitas entran primero en la habitación y muestran el reencuentro dentro
# del diálogo normal, enlazando después con el checkpoint exacto.
func _begin_resumed_visit(character_id: String, node_id: String) -> void:
	var state := _state()
	if state.is_empty() or main == null:
		super(character_id, node_id)
		return

	_ensure_transition_arrays(state)
	var order: Array = state.get("visit_order", [])
	if not order.has(character_id):
		order.append(character_id)
	state["visit_order"] = order
	state["save_version"] = str(ProjectSettings.get_setting("application/config/version", ""))
	main.set("state", state)
	main.call("_save_game", false)

	var dm: Variant = _dm()
	var character: Dictionary = dm.call("get_character", character_id) if dm != null else {}
	var display_name := str(character.get("display_name", character.get("name", character_id.capitalize())))
	var background_id := str(dm.call("get_character_background_id", character_id)) if dm != null else ""
	var resume_node_id := "%s_resume_bubble" % character_id
	RuntimeStory.NODES[resume_node_id] = {
		"speaker": display_name,
		"text": _pick_room_resume_message(),
		"background": background_id,
		"show": [character_id],
		"positions": {character_id: "center"},
		"focus": character_id,
		"chapter": "REENCUENTRO · " + display_name.to_upper(),
		"next": node_id,
		"resume_target": node_id,
		"transient_resume": true
	}

	_start_character_music(character_id)
	if version_manager != null:
		version_manager.call("_hide_selector")
	main.call("_go_to", resume_node_id, false)


func _on_visit_selected(character_id: String) -> void:
	var state := _state()
	if character_id == "javi" and _is_javi_day3_state(state):
		_prepare_javi_day3_entry(state)
	if character_id != "javi" or _javi_day3_entry_node.is_empty():
		super(character_id)
		return
	if transition_active:
		return
	if state.is_empty():
		_javi_day3_entry_node = ""
		return

	_ensure_transition_arrays(state)
	var order: Array = state.get("visit_order", [])
	if not order.has(character_id):
		order.append(character_id)
	state["visit_order"] = order
	state["save_version"] = str(ProjectSettings.get_setting("application/config/version", ""))
	main.set("state", state)
	main.call("_save_game", false)

	var entry_node := _javi_day3_entry_node
	_javi_day3_entry_node = ""
	var intros: Array = state.get("intro_transitions_seen", [])
	if entry_node == "javi_intro_01" and not intros.has(character_id):
		_play_intro(character_id)
		return

	if version_manager != null:
		version_manager.call("_hide_selector")
	main.call("_go_to", entry_node, false)


func _prepare_javi_day3_entry(state: Dictionary) -> void:
	_javi_day3_entry_node = ""
	if version_manager == null and main != null:
		version_manager = main.get_node_or_null("Version040Manager")
	if version_manager != null and version_manager.has_method("prepare_javi_battle_for_transition"):
		_javi_day3_entry_node = str(version_manager.call("prepare_javi_battle_for_transition", state))


func _is_javi_day3_state(state: Dictionary) -> bool:
	if state.is_empty():
		return false
	var progress: Variant = state.get("narrative_progress", {})
	return typeof(progress) == TYPE_DICTIONARY and int((progress as Dictionary).get("current_day", 1)) == 3


func prime_next_generic_from_black() -> void:
	_next_generic_starts_black = true


func play_new_game_intro(on_finished: Callable = Callable()) -> void:
	if main == null:
		main = get_parent() as Control
	if main == null:
		if on_finished.is_valid():
			on_finished.call()
		return
	if _new_game_prelude != null and is_instance_valid(_new_game_prelude):
		return

	var prelude := NewGamePrelude.new() as Control
	if prelude == null:
		if on_finished.is_valid():
			on_finished.call()
		return
	prelude.name = "NewGamePrelude"
	prelude.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prelude.connect("prelude_finished", Callable(self, "_on_new_game_prelude_finished").bind(on_finished), CONNECT_ONE_SHOT)
	_new_game_prelude = prelude
	main.add_child(prelude)


func _on_new_game_prelude_finished(on_finished: Callable) -> void:
	_new_game_prelude = null
	if on_finished.is_valid():
		on_finished.call()


func play_generic_transition(
	title: String,
	message: String,
	auto_continue_seconds: float = 0.0,
	on_midpoint: Callable = Callable()
) -> void:
	if not _next_generic_starts_black:
		await super(title, message, auto_continue_seconds, on_midpoint)
		return
	if transition_active:
		return

	_next_generic_starts_black = false
	_ensure_runtime_overlay()
	if overlay == null:
		if on_midpoint.is_valid():
			on_midpoint.call()
		return

	transition_active = true
	continue_requested = false
	_prepare_generic_text(title, message)
	overlay.visible = true
	shade.modulate.a = 1.0
	text_box.modulate.a = 0.0
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
