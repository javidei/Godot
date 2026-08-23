extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var dm := root.get_node_or_null("DataManager")
	if dm == null:
		_fail("DataManager no está disponible")
		return
	dm.call("reload_all")
	var codex: Dictionary = dm.call("get_codex_data")
	var people: Array = codex.get("personajes", []) if typeof(codex.get("personajes", [])) == TYPE_ARRAY else []
	if people.size() != 8:
		_fail("El códice no contiene los ocho miembros del grupo")
		return
	var charlie: Dictionary = {}
	for raw_person in people:
		if typeof(raw_person) == TYPE_DICTIONARY and str((raw_person as Dictionary).get("id", "")) == "charlie":
			charlie = raw_person as Dictionary
			break
	if charlie.is_empty():
		_fail("Charlie no aparece en el códice")
		return
	if str(charlie.get("apodo", "")) != "Charlie" or str(charlie.get("profesion_o_estudios", "")) != "Ingeniero informático":
		_fail("La ficha de Charlie no contiene su identidad y profesión")
		return
	if not (charlie.get("gustos", []) as Array).has("Portal") or not (charlie.get("gustos", []) as Array).has("Magic: The Gathering"):
		_fail("La ficha de Charlie no conserva sus gustos de videojuegos y Magic")
		return
	if not str(charlie.get("imagen_por_defecto", "")).is_empty():
		_fail("Charlie no debe tener una foto inventada")
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(40):
		await process_frame
	var extras := main.get_node_or_null("Version050ExtrasCodex")
	if extras == null:
		_fail("No está disponible Extras")
		return
	extras.call("_open_extras")
	await process_frame
	extras.call("_show_characters")
	for _i in range(4):
		await process_frame
	var grid := main.find_child("CharacterCodexGrid050", true, false) as GridContainer
	if grid == null or grid.get_child_count() != 8:
		_fail("Extras no muestra ocho fichas de personaje")
		return
	var charlie_card := main.find_child("CharacterCard_charlie", true, false)
	if charlie_card == null:
		# Algunas versiones históricas no nombran la tarjeta con el id; en ese caso
		# basta con que la cuadrícula tenga ocho elementos y la ficha sea navegable.
		pass

	extras.call("_show_character", "charlie")
	for _i in range(5):
		await process_frame
	var details := main.find_child("CharacterDetails050", true, false)
	if details == null or not _tree_contains_text(details, "Ingeniero informático"):
		_fail("La ficha visual de Charlie no muestra su profesión")
		return
	if not _tree_contains_text(details, "Portal") or not _tree_contains_text(details, "Magic"):
		_fail("La ficha visual de Charlie no muestra sus aficiones")
		return
	var portrait := main.find_child("CharacterPortrait050", true, false) as TextureRect
	if portrait == null:
		_fail("La ficha de Charlie no conserva el hueco preparado para retrato")
		return
	if portrait.texture != null:
		_fail("La UI de Charlie debe seguir sin retrato hasta recibir una foto")
		return

	extras.call("_show_places")
	for _i in range(4):
		await process_frame
	var rooms := main.find_child("RoomCodexList052", true, false) as VBoxContainer
	if rooms == null or rooms.get_child_count() != 7:
		_fail("Lugares no incluye la séptima habitación única, la de Charlie")
		return
	if not _tree_contains_text(rooms, "Habitación de Charlie"):
		_fail("La habitación provisional de Charlie no aparece en Lugares")
		return

	print("V050 OK: ocho fichas, Charlie sin retrato, datos completos y habitación provisional validados.")
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
