extends RefCounted

const MAX_CACHED_TEXTURES := 12

const BACKGROUNDS := {
	"forest": "res://assets/backgrounds/fondo-bosque.png",
	"cafeteria": "res://assets/backgrounds/fondo-cafeteria.png",
	"asturias_home": "res://assets/backgrounds/fondo-casa-asturias.png"
}

const CHARACTER_POSES := {
	"javi": {
		"neutral": "res://assets/characters/javi/javi-01-neutro.png",
		"happy": "res://assets/characters/javi/javi-02-sonriendo.png",
		"laugh": "res://assets/characters/javi/javi-02-sonriendo.png",
		"thoughtful": "res://assets/characters/javi/javi-03-pensativo.png",
		"jagermeister": "res://assets/characters/javi/javi-04-jagermeister.png",
		"expressive": "res://assets/characters/javi/javi-05-expresivo.png",
		"embarrassed": "res://assets/characters/javi/javi-05-expresivo.png",
		"annoyed": "res://assets/characters/javi/javi-05-expresivo.png",
		"teasing": "res://assets/characters/javi/javi-05-expresivo.png"
	},
	"sue": {
		"neutral": "res://assets/characters/sue/sue-01-neutra.png",
		"happy": "res://assets/characters/sue/sue-02-sonriendo.png",
		"laugh": "res://assets/characters/sue/sue-02-sonriendo.png",
		"thoughtful": "res://assets/characters/sue/sue-03-pensativa.png",
		"chocolate": "res://assets/characters/sue/sue-04-chocolate.png",
		"expressive": "res://assets/characters/sue/sue-05-expresiva.png",
		"embarrassed": "res://assets/characters/sue/sue-05-expresiva.png",
		"annoyed": "res://assets/characters/sue/sue-05-expresiva.png",
		"teasing": "res://assets/characters/sue/sue-05-expresiva.png"
	},
	"smokey": {
		"neutral": "res://assets/characters/smokey/smokey_01_confidente.png",
		"confident": "res://assets/characters/smokey/smokey_01_confidente.png",
		"happy": "res://assets/characters/smokey/smokey_02_sonrisa.png",
		"laugh": "res://assets/characters/smokey/smokey_02_sonrisa.png",
		"thoughtful": "res://assets/characters/smokey/smokey_03_pensativo.png",
		"vaping": "res://assets/characters/smokey/smokey_04_vapeando.png",
		"expressive": "res://assets/characters/smokey/smokey_05_expresivo.png",
		"embarrassed": "res://assets/characters/smokey/smokey_05_expresivo.png",
		"annoyed": "res://assets/characters/smokey/smokey_05_expresivo.png",
		"teasing": "res://assets/characters/smokey/smokey_05_expresivo.png"
	}
}

var _cache: Dictionary = {}
var _cache_order: Array[String] = []


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
		var oldest := _cache_order.pop_front()
		_cache.erase(oldest)

