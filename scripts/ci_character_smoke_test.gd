extends SceneTree

const CHARACTER_IDS: Array[String] = ["javi", "sue", "smokey", "carmen", "jony", "ana", "argentino"]
const Story = preload("res://scripts/story.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate()
	root.add_child(main)
	for _i in range(10):
		await process_frame

	var slots: Dictionary = main.get("character_slots")
	var views: Dictionary = main.get("character_views")
	var assets: Variant = main.get("asset_manager")
	if assets == null:
		_fail("AssetManager no está disponible")
		return

	var test_state := {"node_id": "group_01", "affinity": {}, "expressions": {}, "history": []}
	for character_id in CHARACTER_IDS:
		if not slots.has(character_id):
			_fail("Falta slot de personaje: " + character_id)
			return
		if not views.has(character_id):
			_fail("Falta vista de personaje: " + character_id)
			return
		var texture: Texture2D = assets.call("get_character", character_id, "neutral") as Texture2D
		if texture == null:
			_fail("No carga textura de: " + character_id)
			return
		var view := views[character_id] as TextureRect
		view.texture = texture
		if view.texture == null or view.texture.get_size().x <= 0.0 or view.texture.get_size().y <= 0.0:
			_fail("Textura inválida en vista: " + character_id)
			return
		test_state["affinity"][character_id] = 0
		test_state["expressions"][character_id] = "neutral"
	main.set("state", test_state)

	var selection_manager := main.get_node_or_null("CharacterSelectManager")
	if selection_manager == null:
		_fail("CharacterSelectManager no está disponible")
		return
	selection_manager.call("open_selection")
	await process_frame
	for character_id in CHARACTER_IDS:
		var card := _find_named(main, "Character_" + character_id)
		var portrait := _find_texture_rect(card)
		if portrait == null or portrait.texture == null:
			_fail("Retrato vacío en selección: " + character_id)
			return
		if not portrait.is_visible_in_tree():
			_fail("Retrato oculto en selección: " + character_id)
			return
	var flow_screen := selection_manager.get("flow_screen") as Control
	if flow_screen != null:
		flow_screen.visible = false
	selection_manager.call("_set_main_screens", false, true, false)

	main.call("_go_to", "group_01", false)
	await process_frame
	if not _all_rendered(slots, views, ["carmen", "jony", "ana"]):
		_fail("Carmen, Jony y Ana no están visibles en group_01")
		return

	main.call("_go_to", "carmen_01", false)
	await process_frame
	if not _all_rendered(slots, views, ["carmen", "jony", "ana"]):
		_fail("Los secundarios desaparecen al hablar Carmen")
		return

	main.call("_go_to", "jony_01", false)
	await process_frame
	if not _all_rendered(slots, views, ["carmen", "jony", "ana"]):
		_fail("Los secundarios desaparecen al hablar Jony")
		return

	main.call("_go_to", "ana_01", false)
	await process_frame
	if not _all_rendered(slots, views, ["carmen", "jony", "ana"]):
		_fail("Los secundarios desaparecen al hablar Ana")
		return

	main.call("_go_to", "argentino_01", false)
	await process_frame
	if not _all_rendered(slots, views, ["jony", "argentino", "ana"]):
		_fail("El Argentino no aparece en argentino_01")
		return

	main.call("_go_to", "bosque_01", false)
	await process_frame
	var bosque: Texture2D = assets.call("get_background", "bosque") as Texture2D
	var game_background := main.get("game_background") as TextureRect
	if bosque == null or game_background == null or game_background.texture == null:
		_fail("El fondo del bosque no carga")
		return
	if game_background.texture.resource_path != bosque.resource_path:
		_fail("Bosque no se muestra en la partida")
		return

	print("SMOKE OK: 7 retratos visibles en selección y escenas; Bosque carga correctamente.")
	quit(0)

func _all_rendered(slots: Dictionary, views: Dictionary, ids: Array) -> bool:
	for character_id in ids:
		var slot: Control = slots.get(character_id) as Control
		var view: TextureRect = views.get(character_id) as TextureRect
		if slot == null or not slot.is_visible_in_tree() or view == null or view.texture == null:
			return false
	return true

func _find_named(node: Node, target_name: String) -> Node:
	if node == null:
		return null
	if str(node.name) == target_name:
		return node
	for child in node.get_children():
		var found := _find_named(child, target_name)
		if found != null:
			return found
	return null

func _find_texture_rect(node: Node) -> TextureRect:
	if node == null:
		return null
	for child in node.get_children():
		if child is TextureRect:
			return child as TextureRect
		var found := _find_texture_rect(child)
		if found != null:
			return found
	return null

func _fail(message: String) -> void:
	push_error("SMOKE FAIL: " + message)
	quit(1)
