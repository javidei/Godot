extends SceneTree

const VISIT_NODE := "__VISIT_SELECT__"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var dm := root.get_node_or_null("DataManager")
	if dm == null:
		_fail("DataManager no está disponible")
		return
	dm.call("reload_all")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(24):
		await process_frame

	var transition := main.get_node_or_null("Version044VisitTransitions")
	var world_map := main.get_node_or_null("WorldMapManager")
	if transition == null or world_map == null:
		_fail("No están disponibles transición y mapa")
		return
	if not transition.has_method("request_continue") or not transition.has_method("begin_character_visit"):
		_fail("El gestor de transiciones ha perdido su API de entrada manual")
		return

	var active: Array = dm.call("get_all_character_ids", true) if dm.has_method("get_all_character_ids") else dm.call("get_character_ids", true)
	if dm.has_method("set_runtime_active_characters"):
		dm.call("set_runtime_active_characters", active)
	if dm.has_method("set_runtime_narrative_day"):
		dm.call("set_runtime_narrative_day", 1)
	var state: Dictionary = dm.call("migrate_save_state", {
		"node_id": VISIT_NODE,
		"player": {"id": "custom", "display_name": "Invitado", "guest": true},
		"active_characters": active,
		"affinity": {}, "expressions": {}, "history": [],
		"visit_mode": true, "completed_characters": [], "visit_order": [],
		"current_zone_id": "triana", "conversation_checkpoints": {}
	})
	main.set("state", state)
	world_map.call("open_selector", state)
	world_map.call("show_zone", "triana", false)
	for _i in range(4):
		await process_frame
	if main.find_child("MapCharacter_ana", true, false) == null:
		_fail("No se encuentra a Ana para validar la transición")
		return

	transition.call("set_fast_mode", true)
	transition.call("begin_character_visit", "ana")
	var waited := 0
	while bool(transition.get("transition_active")) and waited < 90:
		await process_frame
		waited += 1
	state = main.get("state")
	if str(state.get("node_id", "")) != "ana_intro_01":
		_fail("La transición de entrada no termina en la habitación de Ana")
		return

	main.call("_go_to", "ana_q2", false)
	for _i in range(3):
		await process_frame
	state = main.get("state")
	var checkpoints: Dictionary = state.get("conversation_checkpoints", {})
	if str(checkpoints.get("ana", "")) != "ana_q2":
		_fail("No se guarda el checkpoint de una conversación a medias")
		return
	world_map.call("return_to_map_from_room")
	for _i in range(8):
		await process_frame
	if str((main.get("state") as Dictionary).get("node_id", "")) != VISIT_NODE or not bool(world_map.call("is_open")):
		_fail("Salir de una habitación no vuelve al mapa")
		return

	transition.call("set_fast_mode", true)
	transition.call("begin_character_visit", "ana")
	var resume_node_id := "ana_resume_bubble_0932"
	waited = 0
	while str((main.get("state") as Dictionary).get("node_id", "")) != resume_node_id and waited < 90:
		await process_frame
		waited += 1
	if str((main.get("state") as Dictionary).get("node_id", "")) != resume_node_id:
		_fail("La revisita no muestra el bocadillo de reencuentro")
		return
	var current_node: Dictionary = main.get("current_node")
	if not bool(current_node.get("transient_resume", false)) or str(current_node.get("resume_target", "")) != "ana_q2":
		_fail("El reencuentro no conserva el checkpoint exacto")
		return

	print("V044 OK: entrada, salida al mapa y reanudación exacta funcionan con el Invitado.")
	quit(0)


func _fail(message: String) -> void:
	push_error("V044 FAIL: " + message)
	quit(1)
