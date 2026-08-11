extends SceneTree

const Story = preload("res://scripts/story.gd")
const GameData = preload("res://scripts/game_data.gd")

var data_manager: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	data_manager = root.get_node_or_null("DataManager")
	if data_manager == null:
		_fail("El Autoload DataManager no está activo en /root/DataManager")
		return
	data_manager.call("reload_all")
	GameData.refresh()
	Story.refresh()

	var errors: Array = data_manager.call("get_data_errors")
	if not errors.is_empty():
		var error_texts := PackedStringArray()
		for item in errors:
			error_texts.append(str(item))
		_fail("DataManager ha detectado errores de datos: " + " | ".join(error_texts))
		return

	var character_ids: Array = data_manager.call("get_character_ids", true)
	if character_ids.size() != 7:
		_fail("Se esperaban siete personajes activos y hay %d" % character_ids.size())
		return
	for raw_character_id in character_ids:
		var character_id := str(raw_character_id)
		var character: Dictionary = data_manager.call("get_character", character_id)
		if character.is_empty() or str(character.get("room", "")).is_empty():
			_fail("Ficha incompleta para " + character_id)
			return
		var questions: Array = data_manager.call("get_questions", character_id)
		if questions.size() != 3:
			_fail("%s no conserva sus tres preguntas" % character_id)
			return
		var room: Dictionary = data_manager.call("get_room_for_character", character_id)
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

	if str(data_manager.call("get_save_path")) != "user://savegame.json":
		_fail("La partida no apunta a user://savegame.json")
		return
	if str(data_manager.call("get_settings_path")) != "user://settings.json":
		_fail("La configuración no apunta a user://settings.json")
		return

	var test_save := {
		"node_id": Story.START,
		"player": {"id": "javi", "display_name": "Javi"},
		"affinity": {"sue": 2},
		"expressions": {},
		"history": []
	}
	if not bool(data_manager.call("save_game", test_save)):
		_fail("DataManager no puede escribir una partida JSON")
		return
	var loaded_save: Dictionary = data_manager.call("load_game")
	if str(loaded_save.get("node_id", "")) != Story.START or int((loaded_save.get("affinity", {}) as Dictionary).get("sue", -1)) != 2:
		_fail("La partida JSON no se recupera correctamente")
		return

	var settings: Dictionary = data_manager.call("get_settings")
	var audio: Dictionary = settings.get("audio", {})
	if float(audio.get("music_volume", -1.0)) < 0.0 or float(audio.get("music_volume", 2.0)) > 1.0:
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
	for raw_character_id in character_ids:
		var character_id := str(raw_character_id)
		if assets.call("get_character", character_id, "neutral") == null:
			_fail("No carga la imagen de " + character_id)
			return
		var background_id := str(data_manager.call("get_character_background_id", character_id))
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
