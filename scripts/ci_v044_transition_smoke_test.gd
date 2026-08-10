extends SceneTree

const Story = preload("res://scripts/story.gd")
const VISIT_NODE := "__VISIT_SELECT__"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var project_version := str(ProjectSettings.get_setting("application/config/version", ""))
	if project_version != "0.4.4":
		_fail("La prueba de transiciones requiere la versión 0.4.4")
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
	var selection_manager := main.get_node_or_null("CharacterSelectManager")
	if transition == null or visit_manager == null or selection_manager == null:
		_fail("No están disponibles los gestores necesarios para las transiciones 0.4.4")
		return
	transition.call("set_fast_mode", true)

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

	var card := main.find_child("VisitCard_ana", true, false) as Button
	if card == null:
		_fail("No se encuentra la tarjeta de Ana para probar la entrada")
		return
	if not bool(card.get_meta("transition_044_bound", false)):
		_fail("La tarjeta de visita no está conectada al nuevo fundido narrativo")
		return

	card.emit_signal("pressed")
	for _i in range(14):
		await process_frame

	var state: Dictionary = main.get("state")
	if str(state.get("node_id", "")) != "ana_intro_01":
		_fail("El fundido de entrada no termina en la habitación de Ana")
		return
	var intros: Array = state.get("intro_transitions_seen", [])
	if not intros.has("ana"):
		_fail("La presentación de Ana no queda registrada como vista")
		return

	main.call("_go_to", "ana_outro_044", false)
	for _i in range(16):
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
	if str(state.get("save_version", "")) != project_version:
		_fail("El guardado no conserva la versión 0.4.4 tras las transiciones")
		return

	var overlay := transition.get("overlay") as Control
	if overlay == null or overlay.visible:
		_fail("La capa negra no se oculta al terminar la transición")
		return

	print("V044 OK: presentación, fundido de entrada, despedida, fundido de salida y persistencia validados.")
	quit(0)


func _fail(message: String) -> void:
	push_error("V044 FAIL: " + message)
	quit(1)
