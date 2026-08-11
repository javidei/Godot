extends SceneTree

const Story = preload("res://scripts/story.gd")
const GameData = preload("res://scripts/game_data.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	DataManager.reload_all()
	GameData.refresh()
	Story.refresh()

	var errors := DataManager.get_data_errors()
	if not errors.is_empty():
		_fail("DataManager ha detectado errores de datos: " + " | ".join(errors))
		return

	var character_ids := DataManager.get_character_ids(true)
	if character_ids.size() != 7:
		_fail("Se esperaban siete personajes activos y hay %d" % character_ids.size())
		return
	for character_id in character_ids:
		var character := DataManager.get_character(character_id)
		if character.is_empty() or str(character.get("room", "")).is_empty():
			_fail("Ficha incompleta para " + character_id)
			return
		if DataManager.get_questions(character_id).size() != 3:
			_fail("%s no conserva sus tres preguntas" % character_id)
			return
		var room := DataManager.get_room_for_character(character_id)
		if room.is_empty() or str(room.get("background_path", "")).is_empty() or str(room.get("music_path", "")).is_empty():
			_fail("Habitación incompleta para " + character_id)
			return
		if not Story.NODES.has(character_id + "_intro_01"):
			_fail("La historia no genera la introducción de " + character_id)
			return
		for number in range(1, 4):
			var question_id := "%s_q%d" % [character_id, number]
			var node: Dictionary = Story.NODES.get(question_id, {})
			if node.is_empty() or (node.get("choices", []) as Array).size() != 4:
				_fail("La pregunta %s no genera cuatro respuestas" % question_id)
				return

	if DataManager.get_save_path() != "user://savegame.json":
		_fail("La partida no apunta a user://savegame.json")
		return
	if DataManager.get_settings_path() != "user://settings.json":
		_fail("La configuración no apunta a user://settings.json")
		return

	var test_save := {
		"node_id": Story.START,
		"player": {"id": "javi", "display_name": "Javi"},
		"affinity": {"sue": 2},
		"expressions": {},
		"history": []
	}
	if not DataManager.save_game(test_save):
		_fail("DataManager no puede escribir una partida JSON")
		return
	var loaded_save := DataManager.load_game()
	if str(loaded_save.get("node_id", "")) != Story.START or int((loaded_save.get("affinity", {}) as Dictionary).get("sue", -1)) != 2:
		_fail("La partida JSON no se recupera correctamente")
		return

	var settings := DataManager.get_settings()
	var audio: Dictionary = settings.get("audio", {})
	if not is_equal_approx(float(audio.get("music_volume", -1.0)), 0.3) and not FileAccess.file_exists(DataManager.LEGACY_AUDIO_PATH):
		_fail("settings.json no tiene una configuración de música válida")
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(36):
		await process_frame

	var assets: Variant = main.get("asset_manager")
	var audio_manager: Variant = main.get("audio_manager")
	if assets == null or audio_manager == null:
		_fail("Main no conserva AssetManager/AudioManager")
		return
	for character_id in character_ids:
		if assets.call("get_character", character_id, "neutral") == null:
			_fail("No carga la imagen de " + character_id)
			return
		var background_id := DataManager.get_character_background_id(character_id)
		if assets.call("get_background", background_id) == null:
			_fail("No carga el fondo de " + character_id)
			return

	var selection := main.get_node_or_null("CharacterSelectManager")
	var visits := main.get_node_or_null("Version040Manager")
	var transitions := main.get_node_or_null("Version044VisitTransitions")
	var extras := main.get_node_or_null("Version050ExtrasCodex")
	if selection == null or visits == null or transitions == null or extras == null:
		_fail("Falta una capa de compatibilidad de la escena principal")
		return

	selection.call("open_selection")
	await process_frame
	var cards: Array = selection.get("character_cards") as Array
	if cards.size() != 8:
		_fail("La selección no conserva siete personajes más el personalizado")
		return

	print("DATAMANAGER OK: JSON estáticos, escena, preguntas, habitaciones, assets y user:// validados.")
	quit(0)


func _fail(message: String) -> void:
	push_error("DATAMANAGER FAIL: " + message)
	quit(1)
