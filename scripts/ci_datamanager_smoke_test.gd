extends SceneTree

const Story = preload("res://scripts/story.gd")
const GameData = preload("res://scripts/game_data.gd")

var data_manager: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("DATAMANAGER STEP 1: localizar Autoload")
	data_manager = root.get_node_or_null("DataManager")
	if data_manager == null:
		_fail("El Autoload DataManager no está activo en /root/DataManager")
		return
	print("DATAMANAGER STEP 2: recargar JSON")
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

	print("DATAMANAGER STEP 3: validar roster, diálogos y habitaciones")
	var character_ids: Array = data_manager.call("get_all_character_ids", true) if data_manager.has_method("get_all_character_ids") else data_manager.call("get_character_ids", true)
	if character_ids.size() < 8 or not character_ids.has("charlie"):
		_fail("El roster actual debe incluir al menos los ocho NPC activos, incluido Charlie")
		return
	if data_manager.has_method("set_runtime_active_characters"):
		data_manager.call("set_runtime_active_characters", character_ids)
	if data_manager.has_method("set_runtime_narrative_day"):
		data_manager.call("set_runtime_narrative_day", 1)
	GameData.refresh()
	Story.refresh()

	for raw_character_id in character_ids:
		var character_id := str(raw_character_id)
		var character: Dictionary = data_manager.call("get_character", character_id)
		if character.is_empty() or str(character.get("room", "")).is_empty():
			_fail("Ficha incompleta para " + character_id)
			return
		var bundle: Dictionary = data_manager.call("get_question_bundle", character_id)
		var questions: Array = bundle.get("questions", []) if typeof(bundle.get("questions", [])) == TYPE_ARRAY else []
		if questions.is_empty():
			_fail("%s no tiene conversación para el Día 1" % character_id)
			return
		for raw_question in questions:
			if typeof(raw_question) != TYPE_DICTIONARY:
				_fail("Pregunta inválida para " + character_id)
				return
			var answers: Variant = (raw_question as Dictionary).get("answers", [])
			if typeof(answers) != TYPE_ARRAY or (answers as Array).size() != 4:
				_fail("Las preguntas de %s deben generar cuatro respuestas" % character_id)
				return
		var room: Dictionary = data_manager.call("get_room_for_character", character_id)
		if room.is_empty() or str(room.get("background_path", "")).is_empty():
			_fail("Habitación incompleta para " + character_id)
			return
		if not Story.NODES.has(character_id + "_intro_01"):
			_fail("La historia no genera la introducción de " + character_id)
			return

	var menu_music: Dictionary = data_manager.call("get_menu_music")
	if str(menu_music.get("id", "")) != "menu" or str(menu_music.get("path", "")) != "res://assets/audio/music/menu.ogg":
		_fail("La música del menú no está registrada en DataManager")
		return
	if float(menu_music.get("volume", 1.0)) > 0.4 or float(menu_music.get("fade_seconds", 0.0)) < 3.0 or not bool(menu_music.get("loop", false)):
		_fail("La música del menú no conserva volumen bajo, fundido inicial y bucle")
		return

	print("DATAMANAGER STEP 4: validar user://")
	if str(data_manager.call("get_save_path")) != "user://savegame.json":
		_fail("La partida de compatibilidad no apunta a user://savegame.json")
		return
	if str(data_manager.call("get_settings_path")) != "user://settings.json":
		_fail("La configuración no apunta a user://settings.json")
		return

	var test_save := {
		"node_id": Story.START,
		"player": {"id": "custom", "display_name": "Invitado", "guest": true},
		"active_characters": character_ids.duplicate(),
		"affinity": {"sue": 2},
		"expressions": {},
		"history": []
	}
	if not bool(data_manager.call("save_game", test_save)):
		_fail("DataManager no puede escribir una partida JSON")
		return
	var loaded_save: Dictionary = data_manager.call("load_game")
	if int((loaded_save.get("affinity", {}) as Dictionary).get("sue", -1)) != 2:
		_fail("La partida JSON no se recupera correctamente")
		return

	var settings: Dictionary = data_manager.call("get_settings")
	var audio: Dictionary = settings.get("audio", {})
	if float(audio.get("music_volume", -1.0)) < 0.0 or float(audio.get("music_volume", 2.0)) > 1.0:
		_fail("settings.json no tiene una configuración de música válida")
		return

	print("DATAMANAGER STEP 5: instanciar escena")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(36):
		await process_frame

	print("DATAMANAGER STEP 6: validar managers/assets")
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

	var new_game := main.get_node_or_null("CharacterSelectManager")
	var visits := main.get_node_or_null("Version040Manager")
	var transitions := main.get_node_or_null("Version044VisitTransitions")
	var extras := main.get_node_or_null("Version050ExtrasCodex")
	if new_game == null or visits == null or transitions == null or extras == null:
		_fail("Falta un manager requerido en la escena principal")
		return
	if new_game.get_script() == null or not str(new_game.get_script().resource_path).ends_with("new_game_manager.gd"):
		_fail("Nueva partida sigue dependiendo del selector de protagonista heredado")
		return

	print("DATAMANAGER STEP 7: validar Invitado fijo")
	new_game.call("_start_guest_game")
	for _i in range(8):
		await process_frame
	var state: Dictionary = main.get("state")
	var player: Variant = state.get("player", {})
	if typeof(player) != TYPE_DICTIONARY or str((player as Dictionary).get("id", "")) != "custom" or not bool((player as Dictionary).get("guest", false)):
		_fail("Nueva partida no entra como Invitado fijo")
		return
	var active: Variant = state.get("active_characters", [])
	if typeof(active) != TYPE_ARRAY or (active as Array).size() < 8 or not (active as Array).has("charlie"):
		_fail("El Invitado no conserva disponibles los ocho NPC")
		return

	print("DATAMANAGER OK: datos, roster, Invitado, escena, diálogos, habitaciones, assets y user:// validados.")
	quit(0)


func _fail(message: String) -> void:
	push_error("DATAMANAGER FAIL: " + message)
	quit(1)
