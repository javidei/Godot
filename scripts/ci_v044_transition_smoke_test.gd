extends SceneTree

const Story = preload("res://scripts/story.gd")
const VISIT_NODE := "__VISIT_SELECT__"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var project_version := str(ProjectSettings.get_setting("application/config/version", ""))
	if not (project_version.begins_with("0.4.") or project_version.begins_with("0.5.") or project_version.begins_with("0.6.")):
		_fail("La prueba de transiciones requiere una versión compatible")
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(18):
		await process_frame

	var transition := main.get_node_or_null("Version044VisitTransitions")
	var visit_manager := main.get_node_or_null("Version040Manager")
	var world_map := main.get_node_or_null("WorldMapManager")
	var selection_manager := main.get_node_or_null("CharacterSelectManager")
	var audio_manager := main.get("audio_manager") as Node
	if transition == null or visit_manager == null or world_map == null or selection_manager == null or audio_manager == null:
		_fail("No están disponibles los gestores necesarios para las transiciones")
		return

	var hint_label := transition.get("hint_label") as Label
	if hint_label == null or not hint_label.text.contains("clic"):
		_fail("El fundido no muestra la indicación para continuar manualmente")
		return
	if not transition.has_method("request_continue"):
		_fail("El fundido no dispone de continuación manual")
		return

	if not Story.NODES.has("ana_outro_044"):
		_fail("No se ha creado la escena técnica de despedida de Ana")
		return
	for result in ["correct", "wrong"]:
		var q3_id := "ana_q3_%s" % result
		if str(Story.NODES.get(q3_id, {}).get("next", "")) != "ana_outro_044":
			_fail("La tercera pregunta de Ana no desemboca en su despedida")
			return

	selection_manager.call("open_selection")
	await process_frame
	selection_manager.call("_select_existing_character", "javi")
	for _i in range(6):
		await process_frame

	world_map.call("show_zone", "triana", false)
	for _i in range(3):
		await process_frame
	var card := main.find_child("MapCharacter_ana", true, false) as Button
	if card == null:
		_fail("No se encuentra el marcador de Ana en el mapa temporal de Triana")
		return

	transition.call("set_fast_mode", false)
	card.emit_signal("pressed")
	var waited := 0
	while not bool(transition.get("waiting_for_continue")) and waited < 180:
		await process_frame
		waited += 1
	if not bool(transition.get("waiting_for_continue")):
		_fail("La presentación no llega al estado de espera sobre pantalla negra")
		return
	var state: Dictionary = main.get("state")
	if str(state.get("node_id", "")) != VISIT_NODE:
		_fail("La prueba ya ha entrado en la habitación antes de confirmar la pantalla negra")
		return
	if str(audio_manager.get("current_music_id")) != "ana_vampirica":
		_fail("La música de Ana no empieza durante su presentación en negro")
		return

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	transition.call("_on_transition_input", click)
	waited = 0
	while bool(transition.get("transition_active")) and waited < 180:
		await process_frame
		waited += 1
	if bool(transition.get("transition_active")):
		_fail("La presentación no termina después del clic")
		return

	state = main.get("state")
	if str(state.get("node_id", "")) != "ana_intro_01":
		_fail("El fundido de entrada no termina en la habitación de Ana")
		return
	var intros: Array = state.get("intro_transitions_seen", [])
	if not intros.has("ana"):
		_fail("La presentación de Ana no queda registrada como vista")
		return

	# Salir de una conversación no la reinicia: guarda el nodo por personaje,
	# vuelve al mapa y exige una nueva pulsación antes de retomar exactamente ahí.
	main.call("_go_to", "ana_q2", false)
	for _i in range(3):
		await process_frame
	state = main.get("state")
	var checkpoints: Dictionary = state.get("conversation_checkpoints", {})
	if str(checkpoints.get("ana", "")) != "ana_q2":
		_fail("El avance de Ana no queda guardado como punto de continuación")
		return
	world_map.call("return_to_map_from_room")
	for _i in range(8):
		await process_frame
	state = main.get("state")
	if str(state.get("node_id", "")) != VISIT_NODE or not bool(world_map.call("is_open")):
		_fail("Volver desde la habitación no abre el mapa")
		return
	transition.call("set_fast_mode", true)
	transition.call("begin_character_visit", "jony")
	waited = 0
	while bool(transition.get("transition_active")) and waited < 60:
		await process_frame
		waited += 1
	main.call("_go_to", "jony_q1", false)
	for _i in range(3):
		await process_frame
	state = main.get("state")
	checkpoints = state.get("conversation_checkpoints", {})
	if str(checkpoints.get("ana", "")) != "ana_q2" or str(checkpoints.get("jony", "")) != "jony_q1":
		_fail("Visitar otra habitación sobrescribe el progreso pendiente de un personaje")
		return
	world_map.call("return_to_map_from_room")
	for _i in range(8):
		await process_frame

	transition.call("set_fast_mode", false)
	transition.call("begin_character_visit", "ana")
	waited = 0
	while not bool(transition.get("waiting_for_continue")) and waited < 180:
		await process_frame
		waited += 1
	state = main.get("state")
	var resume_message := str((transition.get("message_label") as Label).text)
	if not bool(transition.get("waiting_for_continue")) or str(state.get("node_id", "")) != VISIT_NODE:
		_fail("El reencuentro avanza solo antes de que el jugador pulse")
		return
	var configured_messages: Array = root.get_node("DataManager").call("get_room_resume_messages")
	if not configured_messages.has(resume_message):
		_fail("El reencuentro no usa una frase configurable")
		return
	transition.call("_on_transition_input", click)
	waited = 0
	while bool(transition.get("transition_active")) and waited < 180:
		await process_frame
		waited += 1
	state = main.get("state")
	if str(state.get("node_id", "")) != "ana_q2":
		_fail("La visita retomada no continúa exactamente donde se dejó")
		return

	transition.call("set_fast_mode", true)
	main.call("_go_to", "ana_outro_044", false)
	for _i in range(18):
		await process_frame

	state = main.get("state")
	var completed: Array = state.get("completed_characters", [])
	var outros: Array = state.get("outro_transitions_seen", [])
	if str(state.get("node_id", "")) != VISIT_NODE:
		_fail("La despedida no vuelve al selector de visitas")
		return
	if not completed.has("ana") or not outros.has("ana"):
		_fail("La despedida de Ana no queda registrada como completada y vista")
		return
	checkpoints = state.get("conversation_checkpoints", {})
	if checkpoints.has("ana"):
		_fail("Una conversación completada conserva un punto de continuación obsoleto")
		return
	var save_version := str(state.get("save_version", ""))
	if not (save_version.begins_with("0.4.") or save_version.begins_with("0.5.") or save_version.begins_with("0.6.")):
		_fail("El guardado pierde el versionado compatible tras las transiciones")
		return

	var overlay := transition.get("overlay") as Control
	if overlay == null or overlay.visible:
		_fail("La capa negra no se oculta al terminar la transición")
		return

	print("V044 OK: fundidos manuales, salida al mapa, reencuentro, continuación exacta y despedida validados.")
	quit(0)


func _fail(message: String) -> void:
	push_error("V044 FAIL: " + message)
	quit(1)
