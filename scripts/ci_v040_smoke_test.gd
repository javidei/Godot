extends SceneTree

const Story = preload("res://scripts/story.gd")
const VISIT_NODE := "__VISIT_SELECT__"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var project_version := str(ProjectSettings.get_setting("application/config/version", ""))
	if not project_version.begins_with("0.4."):
		_fail("La versión del proyecto no pertenece a la rama 0.4.x")
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
		_fail("No están disponibles los gestores de selección y versión 0.4.x")
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
	if not bool(state.get("visit_mode", false)) or str(state.get("save_version", "")) != project_version:
		_fail("La partida nueva no queda marcada con la versión actual del flujo 0.4.x")
		return

	var overlay := manager.get("visit_overlay") as Control
	var visit_center := manager.get("visit_center") as CenterContainer
	var visit_panel := manager.get("visit_panel") as PanelContainer
	var visit_grid := manager.get("visit_grid") as GridContainer
	if overlay == null or not overlay.visible or visit_grid == null or visit_grid.get_child_count() != 6:
		_fail("El selector no muestra las seis visitas disponibles al elegir a Javi")
		return
	if visit_center == null or visit_panel == null or visit_panel.get_parent() != visit_center:
		_fail("El selector de visitas no está centrado mediante su contenedor")
		return

	for child in visit_grid.get_children():
		var card := child as Button
		if card == null:
			_fail("Una visita no se representa mediante una tarjeta clicable")
			return
		var preview_background := card.find_child("PreviewBackground", true, false) as TextureRect
		var preview_character := card.find_child("PreviewCharacter", true, false) as TextureRect
		var preview_name := card.find_child("PreviewName", true, false) as Label
		if preview_background == null or preview_background.texture == null:
			_fail("Una tarjeta de visita no muestra el fondo de su habitación")
			return
		if preview_character == null or preview_character.texture == null:
			_fail("Una tarjeta de visita no muestra el cuerpo del personaje")
			return
		if preview_name == null or preview_name.text.is_empty():
			_fail("Una tarjeta de visita no muestra el nombre del personaje")
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
	var room_music_icon := manager.get("room_music_icon") as TextureRect
	var room_label := manager.get("room_label") as Label
	if room_panel == null or not room_panel.visible:
		_fail("La habitación no muestra el regulador individual de canción")
		return
	if room_music_icon == null or room_music_icon.texture == null or room_label == null or room_label.text.contains("♫"):
		_fail("El control de música de habitación sigue dependiendo de un glifo roto")
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
	if fullscreen == null or not fullscreen.text.is_empty() or fullscreen.icon == null:
		_fail("Pantalla completa no usa el SVG real sin glifo Unicode")
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

	print("V040 OK: visitas visuales centradas, fondos y personajes, iconos SVG, progreso, audio por habitación y salida al menú validados.")
	quit(0)


func _fail(message: String) -> void:
	push_error("V040 FAIL: " + message)
	quit(1)
