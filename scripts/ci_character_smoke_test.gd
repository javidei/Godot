extends SceneTree

const CHARACTER_IDS: Array[String] = ["javi", "sue", "smokey", "carmen", "jony", "ana", "argentino"]
const EXTRA_IDS: Array[String] = ["carmen", "jony", "ana", "argentino"]
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

	var group_node: Dictionary = Story.NODES.get("group_01", {})
	var group_show: Array = group_node.get("show", [])
	for character_id in ["carmen", "jony", "ana"]:
		if not group_show.has(character_id):
			_fail("group_01 no muestra a: " + character_id)
			return
	var argentino_node: Dictionary = Story.NODES.get("argentino_01", {})
	if not (argentino_node.get("show", []) as Array).has("argentino"):
		_fail("argentino_01 no muestra a El Argentino")
		return

	var calle: Texture2D = assets.call("get_background", "calle") as Texture2D
	var forest: Texture2D = assets.call("get_background", "forest") as Texture2D
	if calle == null or forest == null or calle.resource_path != forest.resource_path:
		_fail("Calle no está usando el fondo del bosque")
		return

	print("SMOKE OK: 7 personajes con slot y textura; secundarios visibles en historia; calle usa bosque.")
	quit(0)

func _fail(message: String) -> void:
	push_error("SMOKE FAIL: " + message)
	quit(1)
