extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var project_version := str(ProjectSettings.get_setting("application/config/version", ""))
	if not project_version.begins_with("0.4."):
		_fail("La prueba requiere una versión 0.4.x")
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(22):
		await process_frame

	var patch := main.get_node_or_null("Version045InteractionMenuPatch")
	var menu_content := main.get("menu_content") as VBoxContainer
	if patch == null or menu_content == null:
		_fail("No está disponible el parche de interacción/menú 0.4.x")
		return

	var audio_row := menu_content.find_child("AudioCombinedControls040", true, false) as HBoxContainer
	var primary := menu_content.find_child("MenuPrimaryActions045", true, false) as HBoxContainer
	var secondary := menu_content.find_child("MenuSecondaryActions045", true, false) as HBoxContainer
	if audio_row == null or primary == null or secondary == null:
		_fail("No se han creado los tres bloques del menú")
		return
	if primary.get_child_count() != 2 or secondary.get_child_count() != 2:
		_fail("Nueva/Continuar y Pantalla completa/Salir no están organizados en parejas")
		return
	if audio_row.get_index() > primary.get_index() or primary.get_index() > secondary.get_index():
		_fail("El orden del menú no es audio, acciones principales y acciones secundarias")
		return

	var primary_texts: Array[String] = []
	for child in primary.get_children():
		if child is Button:
			var button := child as Button
			primary_texts.append(button.text)
			if button.custom_minimum_size.y > 43.0:
				_fail("Nueva partida/Continuar siguen siendo demasiado altos")
				return
	if not primary_texts.has("Nueva partida") or not primary_texts.has("Continuar"):
		_fail("La primera pareja no contiene Nueva partida y Continuar")
		return

	var secondary_texts: Array[String] = []
	for child in secondary.get_children():
		if child is Button:
			var button := child as Button
			secondary_texts.append(button.text)
			if button.custom_minimum_size.y > 41.0:
				_fail("Pantalla completa/Salir siguen siendo demasiado altos")
				return
	if not secondary_texts.has("Pantalla completa") or not secondary_texts.has("Salir"):
		_fail("La segunda pareja no contiene Pantalla completa y Salir")
		return

	var menu_width_ratio := menu_content.anchor_right - menu_content.anchor_left
	if root.get_visible_rect().size.x >= root.get_visible_rect().size.y:
		if menu_width_ratio < 0.45 or menu_width_ratio > 0.50:
			_fail("El menú no tiene la anchura compacta prevista para botones más anchos sin tapar al personaje")
			return

	# Simula una escena válida y dos clics en una zona libre del propio GameScreen:
	# el primero completa el tipeado y el segundo avanza al siguiente tramo.
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

	print("V045 OK: menú más ancho/menos alto y avance por clic directo sobre GameScreen validados.")
	quit(0)


func _fail(message: String) -> void:
	push_error("V045 FAIL: " + message)
	quit(1)
