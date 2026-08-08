extends RefCounted

const MAX_CACHED_TEXTURES := 12
const MENU_CHARACTERS := "res://assets/ui/menu-lineup.png"

const BACKGROUNDS := {
	"forest": "res://assets/backgrounds/fondo-bosque.png",
	"cafeteria": "res://assets/backgrounds/fondo-cafeteria.png",
	"asturias_home": "res://assets/backgrounds/fondo-casa-asturias.png"
}

const CHARACTER_POSES := {
	"javi": {
		"neutral": "res://assets/characters/javi/javi_a.png",
		"happy": "res://assets/characters/javi/javi_a.png",
		"laugh": "res://assets/characters/javi/javi_a.png",
		"thoughtful": "res://assets/characters/javi/javi_c.png",
		"jagermeister": "res://assets/characters/javi/javi_b.png",
		"expressive": "res://assets/characters/javi/javi_b.png",
		"embarrassed": "res://assets/characters/javi/javi_b.png",
		"annoyed": "res://assets/characters/javi/javi_b.png",
		"teasing": "res://assets/characters/javi/javi_b.png"
	},
	"sue": {
		"neutral": "res://assets/characters/sue/sue_a.png",
		"happy": "res://assets/characters/sue/sue_b.png",
		"laugh": "res://assets/characters/sue/sue_b.png",
		"thoughtful": "res://assets/characters/sue/sue_c.png",
		"chocolate": "res://assets/characters/sue/sue_b.png",
		"expressive": "res://assets/characters/sue/sue_b.png",
		"embarrassed": "res://assets/characters/sue/sue_c.png",
		"annoyed": "res://assets/characters/sue/sue_b.png",
		"teasing": "res://assets/characters/sue/sue_c.png"
	},
	"smokey": {
		"neutral": "res://assets/characters/smokey/smokey_a.png",
		"confident": "res://assets/characters/smokey/smokey_a.png",
		"happy": "res://assets/characters/smokey/smokey_a.png",
		"laugh": "res://assets/characters/smokey/smokey_a.png",
		"thoughtful": "res://assets/characters/smokey/smokey_b.png",
		"vaping": "res://assets/characters/smokey/smokey_b.png",
		"expressive": "res://assets/characters/smokey/smokey_a.png",
		"embarrassed": "res://assets/characters/smokey/smokey_b.png",
		"annoyed": "res://assets/characters/smokey/smokey_a.png",
		"teasing": "res://assets/characters/smokey/smokey_b.png"
	}
}

var _cache: Dictionary = {}
var _cache_order: Array[String] = []


func get_menu_characters() -> Texture2D:
	return _load_texture(MENU_CHARACTERS)


func get_background(background_id: String) -> Texture2D:
	var path := str(BACKGROUNDS.get(background_id, ""))
	return _load_texture(path)


func get_character(character: String, pose: String) -> Texture2D:
	var poses: Dictionary = CHARACTER_POSES.get(character, {})
	if poses.is_empty():
		push_warning("Personaje sin recursos registrados: " + character)
		return null
	var path := str(poses.get(pose, poses.get("neutral", "")))
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

	var texture := ResourceLoader.load(path) as Texture2D
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
