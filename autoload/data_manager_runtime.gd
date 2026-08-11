extends "res://autoload/data_manager.gd"

# Mantiene registrados los tres mappings musicales históricos de casa/bar/bosque
# aunque esos OGG no existen actualmente en el repositorio. Así las APIs antiguas
# siguen devolviendo los mismos ids/rutas, mientras AudioManager continúa fallando
# de forma segura si se intenta reproducir un recurso opcional ausente.
func _validate_data() -> void:
	if _game_config.is_empty():
		_record_error("game_config.json está vacío o no se ha podido leer")
	for raw_character_id in _characters.keys():
		var character_id := str(raw_character_id)
		var character: Dictionary = _characters[raw_character_id]
		var room_id := str(character.get("room", ""))
		if room_id.is_empty() or not _rooms.has(room_id):
			_record_error("El personaje '%s' referencia una habitación inexistente: %s" % [character_id, room_id])
		if not _question_bundles.has(character_id):
			_record_error("El personaje '%s' no tiene archivo de preguntas" % character_id)
		var image_path := get_character_image_path(character_id, "neutral")
		if image_path.is_empty() or not ResourceLoader.exists(image_path):
			_record_error("El personaje '%s' no tiene una imagen neutral válida: %s" % [character_id, image_path])
		_validate_question_bundle(character_id)
	for raw_room_id in _rooms.keys():
		var room_id := str(raw_room_id)
		var room: Dictionary = _rooms[raw_room_id]
		var background_path := str(room.get("background_path", ""))
		var music_path := str(room.get("music_path", ""))
		if background_path.is_empty() or not ResourceLoader.exists(background_path):
			_record_error("La habitación '%s' no tiene un fondo válido: %s" % [room_id, background_path])
		if not music_path.is_empty() and not ResourceLoader.exists(music_path):
			if bool(room.get("music_optional", false)):
				push_warning("DataManager: canción opcional ausente en '%s': %s" % [room_id, music_path])
			else:
				_record_error("La habitación '%s' no tiene una canción válida: %s" % [room_id, music_path])
