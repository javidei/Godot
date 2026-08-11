extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var project_version := str(ProjectSettings.get_setting("application/config/version", ""))
	if not (project_version.begins_with("0.4.") or project_version.begins_with("0.5.")):
		_fail("La prueba requiere una versión compatible de Entre líneas")
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(30):
		await process_frame

	var patch := main.get_node_or_null("Version045InteractionMenuPatch")
	var extras_patch := main.get_node_or_null("Version050ExtrasCodex")
	var menu_content := main.get("menu_content") as VBoxContainer
	if patch == null or menu_content == null:
		_fail("No está disponible el parche de interacción/menú")
		return

	var audio_row := menu_content.find_child("AudioCombinedControls040", true, false) as HBoxContainer
	var primary := menu_content.find_child("MenuPrimaryActions045", true, false) as HBoxContainer
	var secondary := menu_content.find_child("MenuSecondaryActions045", true, false) as HBoxContainer
	if audio_row == null or primary == null or secondary == null:
		_fail("No se han creado los bloques principales del menú")
		return
	if primary.get_child_count() != 2:
		_fail("Nueva partida y Continuar no están organizados en pareja")
		return

	var primary_texts: Array[String] = []
	for child in primary.get_children():
		if child is Button:
			var button := child as Button
			primary_texts.append(button.text)
			if button.custom_minimum_size.y < 55.0:
				_fail("Nueva partida/Continuar no tienen la altura prevista")
				return
	if not primary_texts.has("Nueva partida") or not primary_texts.has("Continuar"):
		_fail("La primera pareja no contiene Nueva partida y Continuar")
		return

	if extras_patch != null:
		if secondary.get_child_count() != 2:
			_fail("Pantalla completa y Extras no están organizados en pareja")
			return
		var secondary_texts: Array[String] = []
		for child in secondary.get_children():
			if child is Button:
				secondary_texts.append((child as Button).text)
		if not secondary_texts.has("Pantalla completa") or not secondary_texts.has("Extras"):
			_fail("La segunda pareja no contiene Pantalla completa y Extras")
			return

		var exit_button := menu_content.find_child("ExitGameButton", true, false) as Button
		var exit_spacer := menu_content.find_child("ExitSpacer050", true, false) as Control
		var version_label := menu_content.find_child("VersionLabel", true, false) as Label
		if exit_button == null or exit_spacer == null:
			_fail("Salir no está separado al final del menú")
			return
		if exit_button.get_parent() != menu_content:
			_fail("Salir sigue dentro de una fila compartida")
			return
		if exit_button.get_index() <= secondary.get_index() or exit_spacer.get_index() >= exit_button.get_index():
			_fail("Salir no queda después del resto de opciones")
			return
		if version_label != null and version_label.get_index() < exit_button.get_index():
			_fail("La información de versión interfiere con la posición final de Salir")
			return
	else:
		if secondary.get_child_count() != 2:
			_fail("Pantalla completa/Salir no están organizados en pareja")
			return

	var menu_width_ratio := menu_content.anchor_right - menu_content.anchor_left
	if root.get_visible_rect().size.x >= root.get_visible_rect().size.y:
		if menu_width_ratio < 0.34 or menu_width_ratio > 0.42:
			_fail("El menú no conserva la anchura compacta prevista")
			return

	var state: Dictionary = main.call("_fresh_state")
	state["player"] = {"id": "sue", "name": "Sue"}
	state["visit_mode"] = true
	state["completed_characters"] = []
	state["visit_order"] = ["javi"]
	state["save_version"] = project_version
	main.set("state", state)
	var game_screen := main.get("game_screen") as Control
	var menu_screen := main.get("menu_screen") as Control
	game_screen.visible = true
	menu_screen.visible = false

	var callback := Callable(patch, "_on_game_screen_input")
	if not game_screen.gui_input.is_connected(callback):
		_fail("GameScreen no escucha los clics de las zonas libres")
		return

	main.call("_go_to", "javi_intro_01", false)
	await process_frame
	var current: Dictionary = main.get("current_node")
	var expected_next := str(current.get("next", ""))
	if expected_next.is_empty():
		_fail("La escena usada para probar el avance no tiene siguiente diálogo")
		return

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(640, 260)
	patch.call("_on_game_screen_input", click)
	await process_frame
	patch.call("_on_game_screen_input", click)
	await process_frame
	state = main.get("state")
	if str(state.get("node_id", "")) != expected_next:
		_fail("Pulsar en una zona libre de la pantalla no avanza al siguiente diálogo")
		return

	print("V045 OK: distribución, Extras/Salir y avance por clic directo validados.")
	quit(0)


func _fail(message: String) -> void:
	push_error("V045 FAIL: " + message)
	quit(1)
