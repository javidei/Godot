extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var project_version := str(ProjectSettings.get_setting("application/config/version", ""))
	if not project_version.begins_with("0.5."):
		_fail("La prueba de Extras requiere la rama 0.5.x")
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(34):
		await process_frame

	var extras := main.get_node_or_null("Version050ExtrasCodex")
	var menu_content := main.get("menu_content") as VBoxContainer
	var menu_screen := main.get("menu_screen") as Control
	if extras == null or menu_content == null or menu_screen == null:
		_fail("No está disponible el sistema de Extras")
		return

	var data_value: Variant = extras.get("data")
	var characters_value: Variant = extras.get("characters")
	if typeof(data_value) != TYPE_DICTIONARY or typeof(characters_value) != TYPE_ARRAY:
		_fail("Extras no ha cargado detalles-juego.json")
		return
	var data: Dictionary = data_value
	var characters: Array = characters_value
	if characters.size() != 7:
		_fail("El códice no carga los siete personajes del JSON")
		return
	if not data.has("juego") or not data.has("lugares") or not data.has("jugabilidad"):
		_fail("Faltan bloques principales del JSON en el códice")
		return

	var extras_button := menu_content.find_child("ExtrasButton050", true, false) as Button
	var exit_button := menu_content.find_child("ExitGameButton", true, false) as Button
	var secondary := menu_content.find_child("MenuSecondaryActions045", true, false) as HBoxContainer
	var exit_spacer := menu_content.find_child("ExitSpacer050", true, false) as Control
	if extras_button == null or exit_button == null or secondary == null or exit_spacer == null:
		_fail("El menú principal no contiene Extras y Salir en su nueva estructura")
		return
	if exit_button.get_parent() != menu_content or exit_button.get_index() <= secondary.get_index():
		_fail("Salir no está abajo del resto de opciones")
		return

	extras.call("_open_extras")
	await process_frame
	var extras_screen := main.find_child("ExtrasScreen050", true, false) as Control
	if extras_screen == null or not extras_screen.visible or menu_screen.visible:
		_fail("Extras no sustituye correctamente al menú principal")
		return
	var options_grid := extras_screen.find_child("ExtrasOptionsGrid050", true, false) as GridContainer
	if options_grid == null or options_grid.get_child_count() != 4:
		_fail("La portada de Extras no muestra Personajes, Información, Lugares y Créditos")
		return

	extras.call("_show_characters")
	for _i in range(3):
		await process_frame
	var character_grid := extras_screen.find_child("CharacterCodexGrid050", true, false) as GridContainer
	if character_grid == null or character_grid.get_child_count() != 7:
		_fail("La pantalla de Personajes no muestra las siete fichas")
		return
	for child in character_grid.get_children():
		var card := child as Button
		if card == null:
			_fail("Una ficha de personaje no es clicable")
			return
		var portrait := card.find_child("CharacterCardPortrait", true, false) as TextureRect
		if portrait == null or portrait.texture == null:
			_fail("Una ficha de personaje no tiene su imagen")
			return

	extras.call("_show_character", "sue")
	for _i in range(3):
		await process_frame
	var portrait_detail := extras_screen.find_child("CharacterPortrait050", true, false) as TextureRect
	var details := extras_screen.find_child("CharacterDetails050", true, false) as VBoxContainer
	if portrait_detail == null or portrait_detail.texture == null or details == null:
		_fail("La ficha individual no muestra retrato y detalles")
		return
	if details.get_child_count() < 12:
		_fail("La ficha de Sue no está renderizando los bloques dinámicos del JSON")
		return
	if not _tree_contains_text(details, "PERSONALIDAD") or not _tree_contains_text(details, "GUSTOS"):
		_fail("La ficha individual no muestra secciones propias del JSON")
		return

	extras.call("_show_places")
	for _i in range(3):
		await process_frame
	var page_host := extras.get("page_host") as MarginContainer
	if page_host == null or not _tree_contains_text(page_host, "BAR / CAFETERÍA") or not _tree_contains_text(page_host, "DISCORD / VIDEOJUEGOS"):
		_fail("La pantalla Lugares no refleja los escenarios del JSON")
		return

	extras.call("_show_credits")
	for _i in range(3):
		await process_frame
	if not _tree_contains_text(page_host, "Javi Díaz"):
		_fail("Créditos no reconoce a Javi Díaz como creador")
		return

	extras.call("_show_game_info")
	for _i in range(3):
		await process_frame
	if not _tree_contains_text(page_host, "NOVELA VISUAL / AVENTURA NARRATIVA") and not _tree_contains_text(page_host, "Novela visual / aventura narrativa"):
		_fail("Información del juego no muestra el género del JSON")
		return

	print("V050 OK: JSON, Extras, siete fichas, detalles dinámicos, lugares, créditos y Salir al final validados.")
	quit(0)


func _tree_contains_text(node: Node, expected: String) -> bool:
	if node is Label and (node as Label).text.contains(expected):
		return true
	if node is Button and (node as Button).text.contains(expected):
		return true
	for child in node.get_children():
		if _tree_contains_text(child, expected):
			return true
	return false


func _fail(message: String) -> void:
	push_error("V050 FAIL: " + message)
	quit(1)
