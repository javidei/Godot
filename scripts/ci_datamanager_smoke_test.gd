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

	print("DATAMANAGER STEP 3: validar personajes/preguntas/habitaciones")
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

	print("DATAMANAGER STEP 4: validar user://")
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

	print("DATAMANAGER STEP 5: instanciar escena")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(36):
		await process_frame
	var room_video_manager := main.get_node_or_null("RoomScreenVideoManager")
	if room_video_manager == null:
		_fail("No está disponible el gestor de vídeo integrado en habitaciones")
		return
	main.call("_set_background", "habitacion_javi")
	for _i in range(4):
		await process_frame
	var room_video := room_video_manager.get("video_player") as VideoStreamPlayer
	var room_video_glow := room_video_manager.get("screen_glow") as Sprite2D
	var room_video_backdrop := room_video_manager.get("screen_backdrop") as Polygon2D
	var room_video_surface := room_video_manager.get("video_surface") as Polygon2D
	if room_video == null or room_video.stream == null or not room_video.visible:
		_fail("El vídeo del monitor de Javi no se carga ni se muestra")
		return
	if room_video_glow == null or room_video_backdrop == null or room_video_surface == null or not room_video_glow.visible or not room_video_surface.visible:
		_fail("La superficie ajustada al monitor de Javi no se muestra")
		return
	if room_video_backdrop.visible:
		_fail("Una capa intermedia oculta el fondo verde bajo el vídeo")
		return
	if not room_video.loop or not is_zero_approx(room_video.volume):
		_fail("El vídeo del monitor no conserva bucle y silencio")
		return
	if room_video_backdrop.polygon.size() != 4 or room_video_surface.polygon.size() != 4:
		_fail("El vídeo del monitor no conserva sus cuatro puntos de perspectiva")
		return
	var screen_quad := room_video_backdrop.polygon
	var is_axis_aligned := (
		is_equal_approx(screen_quad[0].y, screen_quad[1].y)
		and is_equal_approx(screen_quad[3].y, screen_quad[2].y)
		and is_equal_approx(screen_quad[0].x, screen_quad[3].x)
		and is_equal_approx(screen_quad[1].x, screen_quad[2].x)
	)
	if is_axis_aligned:
		_fail("La superficie del vídeo no sigue la inclinación del monitor")
		return
	if not room_video_surface.polygon[0].is_equal_approx(room_video_backdrop.polygon[0]) or not room_video_surface.uv[0].is_equal_approx(Vector2.ZERO):
		_fail("El vídeo no rellena el monitor mostrando el fotograma completo")
		return
	var screen_material := room_video_surface.material as ShaderMaterial
	if screen_material == null or float(screen_material.get_shader_parameter("brightness")) >= 1.0 or room_video_glow.modulate.a <= 0.0:
		_fail("El vídeo no aplica la integración de luz y color de la habitación")
		return
	var uv_min: Vector2 = screen_material.get_shader_parameter("uv_min")
	var uv_max: Vector2 = screen_material.get_shader_parameter("uv_max")
	var homography_row: Vector3 = screen_material.get_shader_parameter("homography_row_2")
	if not uv_min.is_equal_approx(Vector2.ZERO) or not uv_max.is_equal_approx(Vector2.ONE) or homography_row.is_equal_approx(Vector3(0.0, 0.0, 1.0)):
		_fail("El vídeo no aplica la transformación proyectiva completa")
		return
	var homography_rows: PackedVector3Array = room_video_manager.call("_get_inverse_homography", screen_quad)
	var expected_uvs := PackedVector2Array([Vector2.ZERO, Vector2(1.0, 0.0), Vector2.ONE, Vector2(0.0, 1.0)])
	for index in range(4):
		var point := Vector3(screen_quad[index].x, screen_quad[index].y, 1.0)
		var projected := Vector3(
			homography_rows[0].dot(point),
			homography_rows[1].dot(point),
			homography_rows[2].dot(point)
		)
		var projected_uv := Vector2(projected.x, projected.y) / projected.z
		if not projected_uv.is_equal_approx(expected_uvs[index]):
			_fail("La homografía no proyecta correctamente la esquina %d del monitor" % index)
			return
	var green_background := Image.load_from_file(ProjectSettings.globalize_path("res://assets/backgrounds/fondo-habitacion-javi.png"))
	if green_background == null or green_background.is_empty() or not green_background.get_pixel(350, 400).is_equal_approx(Color(0.0, 1.0, 0.0, 1.0)):
		_fail("El fondo de Javi no conserva la pantalla verde de calibración")
		return
	main.call("_set_background", "habitacion_sue")
	for _i in range(2):
		await process_frame
	if room_video.visible or room_video_glow.visible or room_video_backdrop.visible or room_video_surface.visible:
		_fail("El vídeo del monitor sigue visible fuera de la habitación de Javi")
		return

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

	var selection := main.get_node_or_null("CharacterSelectManager")
	var visits := main.get_node_or_null("Version040Manager")
	var transitions := main.get_node_or_null("Version044VisitTransitions")
	var extras := main.get_node_or_null("Version050ExtrasCodex")
	if selection == null or visits == null or transitions == null or extras == null:
		_fail("Falta una capa de compatibilidad de la escena principal")
		return

	print("DATAMANAGER STEP 7: validar selección")
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
