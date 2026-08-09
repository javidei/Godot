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

	main.call("_go_to", "group_01", false)
	await process_frame
	if not _all_visible(slots, ["carmen", "jony", "ana"]):
		_fail("Carmen, Jony y Ana no están visibles en group_01")
		return

	main.call("_go_to", "carmen_01", false)
	await process_frame
	if not _all_visible(slots, ["carmen", "jony", "ana"]):
		_fail("Los secundarios desaparecen al hablar Carmen")
		return

	main.call("_go_to", "jony_01", false)
	await process_frame
	if not _all_visible(slots, ["carmen", "jony", "ana"]):
		_fail("Los secundarios desaparecen al hablar Jony")
		return

	main.call("_go_to", "ana_01", false)
	await process_frame
	if not _all_visible(slots, ["carmen", "jony", "ana"]):
		_fail("Los secundarios desaparecen al hablar Ana")
		return

	main.call("_go_to", "argentino_01", false)
	await process_frame
	if not _all_visible(slots, ["jony", "argentino", "ana"]):
		_fail("El Argentino no aparece en argentino_01")
		return

	var calle: Texture2D = assets.call("get_background", "calle") as Texture2D
	var forest: Texture2D = assets.call("get_background", "forest") as Texture2D
	if calle == null or forest == null or calle.resource_path != forest.resource_path:
		_fail("Calle no está usando el fondo del bosque")
		return

	print("SMOKE OK: 7 personajes cargan; Carmen/Jony/Ana y El Argentino aparecen en escena; calle usa bosque.")
	quit(0)

func _all_visible(slots: Dictionary, ids: Array) -> bool:
	for character_id in ids:
		var slot: Control = slots.get(character_id) as Control
		if slot == null or not slot.visible:
			return false
	return true

func _fail(message: String) -> void:
	push_error("SMOKE FAIL: " + message)
	quit(1)
