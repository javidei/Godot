extends RefCounted

const DataAccess = preload("res://scripts/data_access.gd")
const MAX_CACHED_TEXTURES := 24

var _cache: Dictionary = {}
var _cache_order: Array[String] = []


func get_menu_characters() -> Texture2D:
	var dm: Variant = DataAccess.dm()
	return _load_texture(str(dm.call("get_menu_characters_path"))) if dm != null else null


func get_background(background_id: String) -> Texture2D:
	var dm: Variant = DataAccess.dm()
	var path := str(dm.call("get_background_path", background_id)) if dm != null else ""
	if path.is_empty():
		push_warning("Fondo sin ruta registrada en DataManager: " + background_id)
	return _load_texture(path)


func get_character(character: String, pose: String) -> Texture2D:
	var dm: Variant = DataAccess.dm()
	var path := str(dm.call("get_character_image_path", character, pose)) if dm != null else ""
	if path.is_empty():
		push_warning("Personaje/pose sin recurso registrado: %s / %s" % [character, pose])
	return _load_texture(path)


func warm_scene(node: Dictionary) -> void:
	if node.has("background"):
		get_background(str(node["background"]))
	var expressions: Dictionary = node.get("expressions", {})
	for character in expressions.keys():
		get_character(str(character), str(expressions[character]))


func _load_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if _cache.has(path):
		_touch(path)
		return _cache[path] as Texture2D
	if not ResourceLoader.exists(path):
		push_warning("No existe el recurso local: " + path)
		return null
	var texture: Texture2D = ResourceLoader.load(path) as Texture2D
	if texture == null:
		push_warning("No se ha podido cargar la textura: " + path)
		return null
	_cache[path] = texture
	_cache_order.append(path)
	_trim_cache()
	return texture


func _touch(path: String) -> void:
	_cache_order.erase(path)
	_cache_order.append(path)


func _trim_cache() -> void:
	while _cache_order.size() > MAX_CACHED_TEXTURES:
		var oldest: String = str(_cache_order.pop_front())
		_cache.erase(oldest)
