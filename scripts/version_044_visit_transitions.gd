extends Node

const Story = preload("res://scripts/story.gd")
const GameData = preload("res://scripts/game_data.gd")

const RELEASE_VERSION := "0.4.4"
const VISIT_NODE := "__VISIT_SELECT__"
const OUTRO_SUFFIX := "_outro_044"

const CHARACTER_BACKGROUNDS := {
	"javi": "habitacion_javi",
	"sue": "habitacion_sue",
	"smokey": "habitacion_fran",
	"carmen": "habitacion_fran",
	"jony": "habitacion_jony",
	"ana": "habitacion_ana",
	"argentino": "habitacion_argentino"
}

const INTRO_TEXTS := {
	"javi": "Javi te recibe entre pantallas, guitarras y proyectos que nunca terminan de quedarse quietos.",
	"sue": "Sue te abre la puerta a un rincón tranquilo entre plantas, fantasía y algo dulce esperando cerca.",
	"smokey": "Smokey te espera en una habitación llena de color, música y recuerdos que siempre acaban en anécdota.",
	"carmen": "Carmen aparece entre colores vivos, humor y una energía difícil de ignorar.",
	"jony": "Jony te recibe entre videojuegos, libros y estanterías donde siempre hay algo nuevo que comentar.",
	"ana": "Ana te invita a pasar a un rincón oscuro y acogedor, entre música, fantasía y un toque vampírico.",
	"argentino": "El Argentino te recibe entre rock, humo y objetos que parecen guardar una historia propia."
}

const OUTRO_TEXTS := {
	"javi": "Javi sonríe y vuelve la vista a sus pantallas. «Nos vemos en la siguiente idea.»",
	"sue": "Sue te despide con una sonrisa tranquila. «La próxima vez trae algo dulce.»",
	"smokey": "Smokey se ríe antes de despedirte. «La próxima charla tiene que acabar en otra historia memorable.»",
	"carmen": "Carmen se despide todavía riéndose. «Venga, no tardes tanto la próxima vez.»",
	"jony": "Jony levanta el libro a modo de despedida. «La próxima vez seguimos por donde lo hemos dejado.»",
	"ana": "Ana sonríe de lado al despedirse. «Puedes volver... si te atreves.»",
	"argentino": "El Argentino se despide con calma. «Nos vemos, che. La próxima ronda queda pendiente.»"
}

var main: Control
var version_manager: Node
var overlay: Control
var shade: ColorRect
var text_box: VBoxContainer
var name_label: Label
var message_label: Label
var transition_active := false
var pending_outro := ""
var fast_mode := false


func _ready() -> void:
	for _i in range(8):
		await get_tree().process_frame
	main = get_parent() as Control
	if main == null:
		return
	version_manager = main.get_node_or_null("Version040Manager")
	if version_manager == null:
		return
	_build_overlay()
	_ensure_story_patches()
	_ensure_transition_state(true)


func _process(_delta: float) -> void:
	if main == null or version_manager == null:
		return
	_ensure_story_patches()
	_rewire_visit_cards()
	_ensure_transition_state(false)
	_detect_outro_node()


func set_fast_mode(enabled: bool) -> void:
	fast_mode = enabled


func _build_overlay() -> void:
	overlay = Control.new()
	overlay.name = "VisitNarrativeTransition044"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 600
	overlay.visible = false
	main.add_child(overlay)

	shade = ColorRect.new()
	shade.name = "TransitionBlack"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color.BLACK
	shade.modulate.a = 0.0
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(shade)

	var center := CenterContainer.new()
	center.name = "TransitionCenter"
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)

	text_box = VBoxContainer.new()
	text_box.name = "TransitionText"
	text_box.custom_minimum_size = Vector2(760, 0)
	text_box.add_theme_constant_override("separation", 18)
	text_box.modulate.a = 0.0
	text_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(text_box)

	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color("f2c97e"))
	name_label.add_theme_font_size_override("font_size", 27)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(name_label)

	message_label = Label.new()
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.add_theme_color_override("font_color", Color("f7ead8"))
	message_label.add_theme_font_size_override("font_size", 22)
	message_label.add_theme_constant_override("line_spacing", 6)
	message_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text_box.add_child(message_label)


func _ensure_story_patches() -> void:
	for character_id in Story.ENCOUNTER_ORDER:
		var outro_id := _outro_node_id(character_id)
		Story.NODES[outro_id] = {
			"speaker": "",
			"text": "",
			"background": str(CHARACTER_BACKGROUNDS.get(character_id, "casa_asturias")),
			"show": [character_id],
			"focus": character_id,
			"chapter": "DESPEDIDA"
		}
		for result in ["correct", "wrong"]:
			var feedback_id := "%s_q3_%s" % [character_id, result]
			if Story.NODES.has(feedback_id):
				Story.NODES[feedback_id]["next"] = outro_id


func _rewire_visit_cards() -> void:
	for node in main.find_children("VisitCard_*", "Button", true, false):
		var card := node as Button
		if card == null or bool(card.get_meta("transition_044_bound", false)):
			continue
		var character_id := str(card.get_meta("character_id", ""))
		if character_id.is_empty():
			continue
		for connection in card.get_signal_connection_list("pressed"):
			var callable: Callable = connection.get("callable")
			if callable.is_valid() and card.pressed.is_connected(callable):
				card.pressed.disconnect(callable)
		card.pressed.connect(_on_visit_selected.bind(character_id))
		card.set_meta("transition_044_bound", true)


func _on_visit_selected(character_id: String) -> void:
	if transition_active:
		return
	var state := _state()
	if state.is_empty():
		return
	_ensure_transition_arrays(state)
	var order: Array = state.get("visit_order", [])
	if not order.has(character_id):
		order.append(character_id)
	state["visit_order"] = order
	state["save_version"] = RELEASE_VERSION
	main.set("state", state)
	main.call("_save_game", false)

	var intros: Array = state.get("intro_transitions_seen", [])
	if intros.has(character_id):
		version_manager.call("_hide_selector")
		main.call("_go_to", character_id + "_intro_01", false)
		return
	_play_intro(character_id)


func _play_intro(character_id: String) -> void:
	transition_active = true
	_prepare_text(character_id, str(INTRO_TEXTS.get(character_id, "Una nueva visita está a punto de comenzar.")))
	overlay.visible = true
	shade.modulate.a = 0.0
	text_box.modulate.a = 0.0

	await _fade(shade, 1.0, 0.55)
	await _fade(text_box, 1.0, 0.22)
	await _pause(2.15)
	await _fade(text_box, 0.0, 0.18)

	_mark_intro_seen(character_id)
	version_manager.call("_hide_selector")
	main.call("_go_to", character_id + "_intro_01", false)
	await get_tree().process_frame
	await get_tree().process_frame
	await _fade(shade, 0.0, 0.55)

	overlay.visible = false
	transition_active = false


func _detect_outro_node() -> void:
	if transition_active:
		return
	var state := _state()
	if state.is_empty():
		return
	var node_id := str(state.get("node_id", ""))
	if not node_id.ends_with(OUTRO_SUFFIX):
		pending_outro = ""
		return
	if pending_outro == node_id:
		return
	pending_outro = node_id
	var character_id := node_id.left(node_id.length() - OUTRO_SUFFIX.length())
	call_deferred("_play_outro", character_id)


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

	_prepare_text(character_id, str(OUTRO_TEXTS.get(character_id, "La visita termina por ahora.")))
	overlay.visible = true
	shade.modulate.a = 0.0
	text_box.modulate.a = 0.0

	await _fade(shade, 1.0, 0.55)
	await _fade(text_box, 1.0, 0.22)
	await _pause(2.15)
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
	var data: Dictionary = GameData.CHARACTERS.get(character_id, {})
	var display_name := str(data.get("alias", data.get("name", character_id.capitalize())))
	name_label.text = display_name.to_upper()
	message_label.text = message


func _mark_intro_seen(character_id: String) -> void:
	var state := _state()
	_ensure_transition_arrays(state)
	var intros: Array = state.get("intro_transitions_seen", [])
	if not intros.has(character_id):
		intros.append(character_id)
	state["intro_transitions_seen"] = intros
	state["save_version"] = RELEASE_VERSION
	main.set("state", state)
	main.call("_save_game", false)


func _complete_visit(character_id: String) -> void:
	var state := _state()
	_ensure_transition_arrays(state)
	var completed: Array = state.get("completed_characters", [])
	var outros: Array = state.get("outro_transitions_seen", [])
	var intros: Array = state.get("intro_transitions_seen", [])
	if not completed.has(character_id):
		completed.append(character_id)
	if not outros.has(character_id):
		outros.append(character_id)
	if not intros.has(character_id):
		intros.append(character_id)
	state["completed_characters"] = completed
	state["outro_transitions_seen"] = outros
	state["intro_transitions_seen"] = intros
	state["save_version"] = RELEASE_VERSION
	main.set("state", state)
	main.call("_save_game", false)


func _ensure_transition_state(save_if_changed: bool) -> void:
	var state := _state()
	if state.is_empty() or not bool(state.get("visit_mode", false)):
		return
	var changed := _ensure_transition_arrays(state)
	var completed: Array = state.get("completed_characters", [])
	var intros: Array = state.get("intro_transitions_seen", [])
	var outros: Array = state.get("outro_transitions_seen", [])
	for character_id in completed:
		if not intros.has(character_id):
			intros.append(character_id)
			changed = true
		if not outros.has(character_id):
			outros.append(character_id)
			changed = true

	var node_id := str(state.get("node_id", ""))
	var current_character := Story.character_for_node(node_id)
	if not current_character.is_empty() and not node_id.ends_with(OUTRO_SUFFIX) and not intros.has(current_character):
		intros.append(current_character)
		changed = true

	state["intro_transitions_seen"] = intros
	state["outro_transitions_seen"] = outros
	state["save_version"] = RELEASE_VERSION
	main.set("state", state)
	if changed and save_if_changed:
		main.call("_save_game", false)


func _ensure_transition_arrays(state: Dictionary) -> bool:
	var changed := false
	if typeof(state.get("intro_transitions_seen", [])) != TYPE_ARRAY:
		state["intro_transitions_seen"] = []
		changed = true
	elif not state.has("intro_transitions_seen"):
		state["intro_transitions_seen"] = []
		changed = true
	if typeof(state.get("outro_transitions_seen", [])) != TYPE_ARRAY:
		state["outro_transitions_seen"] = []
		changed = true
	elif not state.has("outro_transitions_seen"):
		state["outro_transitions_seen"] = []
		changed = true
	return changed


func _state() -> Dictionary:
	var value: Variant = main.get("state")
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	return value


func _outro_node_id(character_id: String) -> String:
	return character_id + OUTRO_SUFFIX


func _fade(target: CanvasItem, alpha: float, seconds: float) -> void:
	if fast_mode:
		target.modulate.a = alpha
		await get_tree().process_frame
		return
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(target, "modulate:a", alpha, seconds)
	await tween.finished


func _pause(seconds: float) -> void:
	if fast_mode:
		await get_tree().process_frame
		return
	await get_tree().create_timer(seconds).timeout
