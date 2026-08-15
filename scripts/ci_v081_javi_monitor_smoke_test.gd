extends SceneTree

const CLOSEUP_PATH := "res://assets/backgrounds/pantalla-javi-naranjal.png"
const EXPECTED_URL := "https://javidei.github.io/pixel-adventure/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not ResourceLoader.exists(CLOSEUP_PATH):
		_fail("No existe el fondo de primer plano de los monitores de Javi")
		return
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar la escena principal")
		return
	var main := packed.instantiate() as Control
	if main == null:
		_fail("No se puede instanciar Main")
		return
	get_root().add_child(main)
	for _i in range(32):
		await process_frame

	var manager := main.get_node_or_null("JaviMonitorCloseupManager")
	if manager == null:
		_fail("No está instalado JaviMonitorCloseupManager")
		return
	if not manager.has_method("get_pixel_adventure_url") or str(manager.call("get_pixel_adventure_url")) != EXPECTED_URL:
		_fail("La pantalla derecha no apunta a Pixel Adventure")
		return
	if not manager.has_method("get_closeup_background_path") or str(manager.call("get_closeup_background_path")) != CLOSEUP_PATH:
		_fail("El manager no usa pantalla-javi-naranjal.png")
		return

	var room_hotspot: Variant = manager.get("room_hotspot")
	var overlay: Variant = manager.get("closeup_overlay")
	var closeup_background: Variant = manager.get("closeup_background")
	var right_hotspot: Variant = manager.get("right_monitor_hotspot")
	var back_button: Variant = manager.get("back_button")
	if room_hotspot is not Control or overlay is not Control or closeup_background is not TextureRect or right_hotspot is not Control or back_button is not Button:
		_fail("Faltan controles de interacción de los monitores")
		return
	if (closeup_background as TextureRect).texture == null:
		_fail("El fondo del primer plano no se carga como textura")
		return

	var game_screen := main.get("game_screen") as Control
	if game_screen == null:
		_fail("No existe GameScreen")
		return
	game_screen.visible = true
	main.set("current_background", "habitacion_javi")
	manager.call("_apply_layout")
	await process_frame

	var room_polygon: PackedVector2Array = room_hotspot.call("get_hit_polygon")
	if room_polygon.size() < 8:
		_fail("La zona de los monitores de la habitación no es poligonal")
		return
	var room_inside := _average_point(room_polygon)
	if not bool(room_hotspot.call("contains_point", room_inside)):
		_fail("El área marcada de los monitores de la habitación no es clicable")
		return
	var room_outside := Vector2((room_hotspot as Control).size.x * 0.72, (room_hotspot as Control).size.y * 0.50)
	if bool(room_hotspot.call("contains_point", room_outside)):
		_fail("La habitación acepta clics fuera del área roja de los monitores")
		return

	manager.call("_open_closeup")
	await process_frame
	if not bool(manager.call("is_closeup_open")) or not (overlay as Control).visible:
		_fail("El primer plano no se abre")
		return

	var right_polygon: PackedVector2Array = right_hotspot.call("get_hit_polygon")
	if right_polygon.size() < 8:
		_fail("La pantalla derecha no usa un hotspot poligonal preciso")
		return
	var right_inside := _average_point(right_polygon)
	if not bool(right_hotspot.call("contains_point", right_inside)):
		_fail("La pantalla derecha marcada no es clicable")
		return
	var left_monitor_point := Vector2((right_hotspot as Control).size.x * 0.30, (right_hotspot as Control).size.y * 0.52)
	if bool(right_hotspot.call("contains_point", left_monitor_point)):
		_fail("El primer plano permite abrir Pixel Adventure fuera de la pantalla derecha")
		return

	var visible_buttons := 0
	for node in (overlay as Control).find_children("*", "Button", true, false):
		if node is Button and (node as Button).visible:
			visible_buttons += 1
	if visible_buttons != 1 or not (back_button as Button).visible:
		_fail("En el primer plano debe quedar un único botón visible: Volver")
		return

	manager.call("_close_closeup")
	await process_frame
	if bool(manager.call("is_closeup_open")) or (overlay as Control).visible:
		_fail("El botón Volver no cierra el primer plano")
		return

	# 0.8.3: el modo de pantalla completa debe estar activado como valor inicial.
	if int(ProjectSettings.get_setting("display/window/size/mode", -1)) != 3:
		_fail("El juego no arranca configurado en pantalla completa")
		return
	var runtime := main.get_node_or_null("Version083RuntimeDefaults")
	if runtime == null or not runtime.has_method("uses_default_fullscreen") or not bool(runtime.call("uses_default_fullscreen")):
		_fail("No está activo el controlador de pantalla completa por defecto")
		return

	# Reproduce el fallo observado: la habitación se mutea y AudioManager vuelve
	# a aplicar su configuración global durante el diálogo. El controlador 0.8.3
	# debe restaurar el mute específico de la pista en el siguiente refresco.
	var version040 := main.get_node_or_null("Version040Manager")
	var audio_manager: Variant = main.get("audio_manager")
	if version040 == null or audio_manager == null:
		_fail("No se puede validar el mute específico de habitación")
		return
	var test_track := "ci_room_mute"
	audio_manager.set("current_music_id", test_track)
	audio_manager.set("music_muted", false)
	audio_manager.set("music_suspended", false)
	var mutes: Dictionary = version040.get("track_mutes")
	var volumes: Dictionary = version040.get("track_volumes")
	mutes[test_track] = true
	volumes[test_track] = 1.0
	version040.set("track_mutes", mutes)
	version040.set("track_volumes", volumes)
	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus < 0:
		_fail("No existe el bus Music")
		return
	AudioServer.set_bus_mute(music_bus, false)
	runtime.call("enforce_room_audio_now")
	if not AudioServer.is_bus_mute(music_bus):
		_fail("El mute de habitación no se aplica")
		return
	audio_manager.call("_apply_audio_settings")
	if AudioServer.is_bus_mute(music_bus):
		_fail("El smoke no pudo reproducir el refresco global que quitaba el mute")
		return
	runtime.call("enforce_room_audio_now")
	if not AudioServer.is_bus_mute(music_bus):
		_fail("El mute de habitación se pierde al continuar el diálogo")
		return

	print("V081 JAVI MONITORS OK: zonas poligonales, fullscreen 0.8.3 y mute persistente validados.")
	quit(0)


func _average_point(points: PackedVector2Array) -> Vector2:
	var total := Vector2.ZERO
	for point in points:
		total += point
	return total / float(points.size())


func _fail(message: String) -> void:
	push_error("V081 JAVI MONITORS FAIL: " + message)
	quit(1)
