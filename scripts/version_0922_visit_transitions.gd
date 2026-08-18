extends "res://scripts/version_0919_visit_transitions.gd"

const NewGamePrelude0922 = preload("res://scripts/new_game_prelude_0922.gd")
const DataStory0932 = preload("res://scripts/story.gd")

var _next_generic_starts_black_0922 := false
var _javi_day3_entry_node_0930 := ""


# Las revisitas ya no muestran la frase de reencuentro sobre una pantalla negra.
# Entramos primero en la habitación y la frase se presenta como un nodo normal de
# diálogo inferior; al pulsarlo se continúa exactamente en el checkpoint previo.
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
	state["save_version"] = _release_version()
	main.set("state", state)
	main.call("_save_game", false)

	var dm: Variant = _dm()
	var character: Dictionary = dm.call("get_character", character_id) if dm != null else {}
	var display_name := str(character.get("display_name", character.get("name", character_id.capitalize())))
	var background_id := str(dm.call("get_character_background_id", character_id)) if dm != null else ""
	var resume_node_id := "%s_resume_bubble_0932" % character_id
	var resume_message := _pick_room_resume_message()

	DataStory0932.NODES[resume_node_id] = {
		"speaker": display_name,
		"text": resume_message,
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


# El mapa entra por begin_character_visit() de la cadena 0.9.8. Ese método
# llama virtualmente a _prepare_random_javi_visit(); aquí interceptamos solo el
# Día 3 para que no ejecute el reroll/aviso heredado y prepare la batalla nueva.
func _prepare_random_javi_visit() -> void:
	var state := _state()
	if _is_javi_day3_state_0930(state):
		if version_manager == null and main != null:
			version_manager = main.get_node_or_null("Version040Manager")
		if version_manager != null and version_manager.has_method("prepare_javi_battle_for_transition"):
			_javi_day3_entry_node_0930 = str(version_manager.call("prepare_javi_battle_for_transition", state))
			if not _javi_day3_entry_node_0930.is_empty():
				return
	_javi_day3_entry_node_0930 = ""
	super()


# version_098_visit_transitions llama después a este método. Para el Día 3 de
# Javi conservamos la transición existente, pero el destino lo decide la batalla:
# prólogo narrativo, pregunta de reanudación o batalla completada.
func _on_visit_selected(character_id: String) -> void:
	var state := _state()
	if character_id == "javi" and _javi_day3_entry_node_0930.is_empty() and _is_javi_day3_state_0930(state):
		# También cubre selectores antiguos que llaman aquí directamente y no pasan
		# primero por begin_character_visit().
		_prepare_random_javi_visit()
	if character_id != "javi" or _javi_day3_entry_node_0930.is_empty():
		super(character_id)
		return
	if transition_active:
		return
	if state.is_empty():
		_javi_day3_entry_node_0930 = ""
		return

	_ensure_transition_arrays(state)
	var order: Array = state.get("visit_order", [])
	if not order.has(character_id):
		order.append(character_id)
	state["visit_order"] = order
	state["save_version"] = _release_version()
	main.set("state", state)
	main.call("_save_game", false)

	var entry_node := _javi_day3_entry_node_0930
	_javi_day3_entry_node_0930 = ""
	var intros: Array = state.get("intro_transitions_seen", [])
	if entry_node == "javi_intro_01" and not intros.has(character_id):
		_play_intro(character_id)
		return

	if version_manager != null:
		version_manager.call("_hide_selector")
	main.call("_go_to", entry_node, false)


func _is_javi_day3_state_0930(state: Dictionary) -> bool:
	if state.is_empty():
		return false
	var progress: Variant = state.get("narrative_progress", {})
	return typeof(progress) == TYPE_DICTIONARY and int((progress as Dictionary).get("current_day", 1)) == 3


# El primer texto narrativo posterior a Naranjal debe heredar el negro total del
# preludio. Así no hacemos un nuevo fundido 0 -> 1 que deje ver el mapa debajo.
func prime_next_generic_from_black() -> void:
	_next_generic_starts_black_0922 = true


func play_new_game_intro(on_finished: Callable = Callable()) -> void:
	if main == null:
		main = get_parent() as Control
	if main == null:
		if on_finished.is_valid():
			on_finished.call()
		return
	if _new_game_prelude_0917 != null and is_instance_valid(_new_game_prelude_0917):
		return

	var prelude := NewGamePrelude0922.new() as Control
	if prelude == null:
		if on_finished.is_valid():
			on_finished.call()
		return
	# Conservamos el nombre histórico del nodo porque varios smoke tests lo usan
	# solo como identificador estable; la implementación real es la 0.9.22.
	prelude.name = "NewGamePrelude0917"
	prelude.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	prelude.connect("prelude_finished", Callable(self, "_on_new_game_prelude_finished").bind(on_finished), CONNECT_ONE_SHOT)
	_new_game_prelude_0917 = prelude
	main.add_child(prelude)


func play_generic_transition(
	title: String,
	message: String,
	auto_continue_seconds: float = 0.0,
	on_midpoint: Callable = Callable()
) -> void:
	if not _next_generic_starts_black_0922:
		await super(title, message, auto_continue_seconds, on_midpoint)
		return
	if transition_active:
		return

	_next_generic_starts_black_0922 = false
	_ensure_runtime_overlay()
	if overlay == null:
		if on_midpoint.is_valid():
			on_midpoint.call()
		return

	transition_active = true
	continue_requested = false
	_prepare_generic_text(title, message)
	overlay.visible = true
	# El negro ya está al 100 % antes de que el preludio de Naranjal se retire.
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
