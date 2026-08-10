extends SceneTree

const Story = preload("res://scripts/story.gd")
const VISIT_NODE := "__VISIT_SELECT__"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if str(ProjectSettings.get_setting("application/config/version", "")) != "0.4.0":
		_fail("La versión del proyecto no es 0.4.0")
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(10):
		await process_frame

	var manager := main.get_node_or_null("Version040Manager")
	var selection_manager := main.get_node_or_null("CharacterSelectManager")
	if manager == null or selection_manager == null:
		_fail("No están disponibles los gestores de selección y versión 0.4.0")
		return

	selection_manager.call("open_selection")
	await process_frame
	selection_manager.call("_select_existing_character", "javi")
	for _i in range(3):
		await process_frame

	var state: Dictionary = main.get("state")
	var player: Dictionary = state.get("player", {})
	if str(player.get("id", "")) != "javi":
		_fail("La selección de protagonista no conserva a Javi")
		return
	if str(state.get("node_id", "")) != VISIT_NODE:
		_fail("Tras elegir protagonista no se abre el selector libre de visitas")
		return
	if not bool(state.get("visit_mode", false)) or str(state.get("save_version", "")) != "0.4.0":
		_fail("La partida nueva no queda marcada como flujo 0.4.0")
		return

	var overlay := manager.get("visit_overlay") as Control
	var visit_grid := manager.get("visit_grid") as GridContainer
	if overlay == null or not overlay.visible or visit_grid == null or visit_grid.get_child_count() != 6:
		_fail("El selector no muestra las seis visitas disponibles al elegir a Javi")
		return

	manager.call("_select_visit", "ana")
	for _i in range(2):
		await process_frame
	state = main.get("state")
	if str(state.get("node_id", "")) != "ana_intro_01":
		_fail("Elegir a Ana no abre su habitación")
		return
	var order: Array = state.get("visit_order", [])
	if order.size() != 1 or str(order[0]) != "ana":
		_fail("El orden libre de visitas no registra a Ana como primera visita")
		return

	var room_panel := manager.get("room_panel") as PanelContainer
	if room_panel == null or not room_panel.visible:
		_fail("La habitación no muestra el regulador individual de canción")
		return

	main.call("_go_to", "ana_q3_correct", false)
	await process_frame
	main.call("_go_to", VISIT_NODE, false)
	for _i in range(2):
		await process_frame
	state = main.get("state")
	var completed: Array = state.get("completed_characters", [])
	if not completed.has("ana"):
		_fail("Ana no se marca como visita completada tras su tercera pregunta")
		return
	if visit_grid.get_child_count() != 5:
		_fail("El selector vuelve a ofrecer un personaje ya completado")
		return

	var fullscreen := main.get("fullscreen_button") as Button
	if fullscreen == null or fullscreen.text != "⛶":
		_fail("Pantalla completa no usa el botón compacto de icono")
		return
	if main.find_child("AudioCombinedControls040", true, false) == null:
		_fail("Los ajustes de música y efectos no están en una misma fila")
		return

	manager.call("_leave_to_menu")
	await process_frame
	var menu_screen := main.get("menu_screen") as Control
	if menu_screen == null or not menu_screen.visible:
		_fail("No se puede salir al menú desde el selector de visitas")
		return

	print("V040 OK: protagonista, visitas libres, progreso, audio por habitación, controles compactos y salida al menú validados.")
	quit(0)


func _fail(message: String) -> void:
	push_error("V040 FAIL: " + message)
	quit(1)
