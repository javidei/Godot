extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var project_version := str(ProjectSettings.get_setting("application/config/version", ""))
	if not (project_version.begins_with("0.5.") or project_version.begins_with("0.6.")):
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
		_fail("Extras no ha cargado sus datos")
		return
	var characters: Array = characters_value
	if characters.size() != 7:
		_fail("El códice no carga los siete personajes")
		return

	var extras_button := menu_content.find_child("ExtrasButton050", true, false) as Button
	var exit_button := menu_content.find_child("ExitGameButton", true, false) as Button
	var secondary := menu_content.find_child("MenuSecondaryActions045", true, false) as HBoxContainer
	var exit_spacer := menu_content.find_child("ExitSpacer050", true, false) as Control
	if extras_button == null or exit_button == null or secondary == null or exit_spacer == null:
		_fail("El menú principal no contiene Extras y Salir en su estructura esperada")
		return
	if exit_button.get_parent() != menu_content or exit_button.get_index() <= secondary.get_index():
		_fail("Salir no está abajo del resto de opciones")
		return

	extras.call("_open_extras")
	for _i in range(2):
		await process_frame
	var extras_screen := main.find_child("ExtrasScreen050", true, false) as Control
	var codex_panel := main.find_child("CodexPanel050", true, false) as PanelContainer
	var back_button := main.find_child("ExtrasBackButton050", true, false) as Button
	if extras_screen == null or codex_panel == null or back_button == null or not extras_screen.visible or menu_screen.visible:
		_fail("Extras no sustituye correctamente al menú principal")
		return
	if back_button.text != "Volver" or back_button.icon == null:
		_fail("Volver debe usar texto limpio e icono SVG real")
		return
	var options_grid := extras_screen.find_child("ExtrasOptionsGrid050", true, false) as GridContainer
	if options_grid == null or options_grid.get_child_count() != 7:
		_fail("La portada de Extras no muestra Personajes, Información, Lugares y Créditos")
		return
	for option_name in ["CharactersOption050", "GameInfoOption050", "PlacesOption050", "AchievementsOption060", "StatisticsOption060", "CollectionOption060", "CreditsOption050"]:
		if options_grid.get_node_or_null(option_name) == null:
			_fail("Falta una categoria obligatoria en Extras: " + option_name)
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
	for _i in range(5):
		await process_frame
	var portrait_detail := extras_screen.find_child("CharacterPortrait050", true, false) as TextureRect
	var details := extras_screen.find_child("CharacterDetails050", true, false) as VBoxContainer
	var detail_layout := extras_screen.find_child("CharacterDetailLayout052", true, false) as VBoxContainer
	if portrait_detail == null or portrait_detail.texture == null or details == null or detail_layout == null:
		_fail("La ficha individual no muestra retrato, detalles y layout ajustado")
		return
	if details.get_child_count() < 12:
		_fail("La ficha de Sue no está renderizando los bloques dinámicos")
		return
	if not _tree_contains_text(details, "PERSONALIDAD") or not _tree_contains_text(details, "GUSTOS"):
		_fail("La ficha individual no muestra sus secciones de datos")
		return

	var previous := _find_button_by_text(detail_layout, "Anterior")
	var next := _find_button_by_text(detail_layout, "Siguiente")
	if previous == null or next == null or previous.icon == null or next.icon == null:
		_fail("Anterior y Siguiente deben usar iconos SVG reales")
		return
	var nav := previous.get_parent() as Control
	if nav == null or nav.get_global_rect().end.y > codex_panel.get_global_rect().end.y + 2.0:
		_fail("La navegación de personaje se sale por la parte inferior del panel")
		return

	extras.call("_show_places")
	for _i in range(4):
		await process_frame
	var page_host := extras.get("page_host") as MarginContainer
	var room_list := extras_screen.find_child("RoomCodexList052", true, false) as VBoxContainer
	if page_host == null or room_list == null or room_list.get_child_count() != 6:
		_fail("Lugares debe mostrar las seis habitaciones activas de personajes")
		return
	for child in room_list.get_children():
		var card := child as PanelContainer
		if card == null:
			_fail("Una entrada de Lugares no es una tarjeta")
			return
		var room_image := card.find_child("RoomImage052", true, false) as TextureRect
		var room_description := card.find_child("RoomDescription052", true, false) as VBoxContainer
		if room_image == null or room_image.texture == null or room_description == null:
			_fail("Cada habitación debe mostrar imagen y descripción")
			return
	if not _tree_contains_text(room_list, "Monkey Island") or not _tree_contains_text(room_list, "Astarion"):
		_fail("Las descripciones de habitaciones no se están leyendo desde los JSON")
		return
	if _tree_contains_text(room_list, "BAR / CAFETERÍA") or _tree_contains_text(room_list, "DISCORD / VIDEOJUEGOS"):
		_fail("Lugares sigue mostrando escenarios antiguos que no son habitaciones activas")
		return

	var first_card := room_list.get_child(0) as PanelContainer
	var second_card := room_list.get_child(1) as PanelContainer
	if first_card == null or second_card == null:
		_fail("No hay suficientes habitaciones para validar la alternancia")
		return
	var first_margin := first_card.get_child(0) as MarginContainer
	var second_margin := second_card.get_child(0) as MarginContainer
	var first_row := first_margin.get_child(0) as BoxContainer if first_margin != null else null
	var second_row := second_margin.get_child(0) as BoxContainer if second_margin != null else null
	if first_row == null or second_row == null:
		_fail("Las habitaciones no tienen layout de imagen y texto")
		return
	if first_row.get_child(0).name != "RoomImagePanel052" or second_row.get_child(0).name != "RoomDescription052":
		_fail("Las habitaciones no alternan imagen izquierda/derecha")
		return

	extras.call("_show_credits")
	for _i in range(3):
		await process_frame
	if not _tree_contains_text(page_host, "Javi Díaz"):
		_fail("Créditos no reconoce al creador")
		return

	extras.call("_show_game_info")
	for _i in range(3):
		await process_frame
	if not _tree_contains_text(page_host, "NOVELA VISUAL / AVENTURA NARRATIVA") and not _tree_contains_text(page_host, "Novela visual / aventura narrativa"):
		_fail("Información del juego no muestra el género")
		return

	print("V050 OK: Extras, navegación SVG, ficha contenida y galería alterna de habitaciones validados.")
	quit(0)


func _find_button_by_text(node: Node, expected: String) -> Button:
	if node is Button and (node as Button).text == expected:
		return node as Button
	for child in node.get_children():
		var result := _find_button_by_text(child, expected)
		if result != null:
			return result
	return null


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
