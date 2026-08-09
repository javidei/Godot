extends Node

const EXTRA_CHARACTER_IDS: Array[String] = ["carmen", "jony", "ana", "argentino"]

var main: Control


func _ready() -> void:
	# CharacterSelectManager construye la selección tras tres frames.
	# Esperamos un poco más para añadir cualquier slot que falte y ajustar las tarjetas.
	for _index in range(5):
		await get_tree().process_frame
	main = get_parent() as Control
	if main == null:
		return
	_ensure_extra_character_slots()
	_refresh_selection_portraits()


func _ensure_extra_character_slots() -> void:
	var slots: Dictionary = main.get("character_slots")
	for character_id in EXTRA_CHARACTER_IDS:
		if slots.has(character_id):
			continue
		main.call("_create_character", character_id, "center")
		slots = main.get("character_slots")
		var slot: Control = slots.get(character_id) as Control
		if slot != null:
			slot.visible = false


func _refresh_selection_portraits() -> void:
	var assets: Variant = main.get("asset_manager")
	if assets == null:
		return

	for character_id in EXTRA_CHARACTER_IDS:
		var card: Node = _find_named(main, "Character_" + character_id)
		if card == null:
			continue
		var portrait: TextureRect = _find_texture_rect(card)
		if portrait == null:
			continue
		var texture: Texture2D = assets.call("get_character", character_id, "neutral") as Texture2D
		if texture == null:
			continue
		var size: Vector2 = texture.get_size()
		if size.x <= 0.0 or size.y <= 0.0:
			portrait.texture = texture
			continue
		var cropped := AtlasTexture.new()
		cropped.atlas = texture
		cropped.region = Rect2(0.0, 0.0, size.x, size.y * 0.50)
		portrait.texture = cropped


func _find_named(node: Node, target_name: String) -> Node:
	if str(node.name) == target_name:
		return node
	for child in node.get_children():
		var found: Node = _find_named(child, target_name)
		if found != null:
			return found
	return null


func _find_texture_rect(node: Node) -> TextureRect:
	for child in node.get_children():
		if child is TextureRect:
			return child as TextureRect
		var found: TextureRect = _find_texture_rect(child)
		if found != null:
			return found
	return null
