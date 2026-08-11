extends SceneTree

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate()
	root.add_child(main)
	for _index in range(10):
		await process_frame

	var state: Dictionary = main.call("_fresh_state")
	state["player"] = {"id": "custom", "display_name": "Prueba", "custom": true}
	state["visit_mode"] = true
	state["completed_characters"] = []
	state["visit_order"] = ["javi"]
	main.set("state", state)
	(main.get("menu_screen") as Control).visible = false
	(main.get("game_screen") as Control).visible = true
	main.call("_go_to", "javi_intro_01", false)
	await process_frame

	var audio: Node = main.get("audio_manager") as Node
	if audio == null:
		_fail("AudioManager no está disponible")
		return
	var player: AudioStreamPlayer = audio.get("music_player") as AudioStreamPlayer
	if player == null or player.stream == null or str(audio.get("current_music_id")).is_empty():
		_fail("La habitación de Javi no ha iniciado su canción")
		return

	var music_id := str(audio.get("current_music_id"))
	var original_stream := player.stream
	var position_before_menu := player.get_playback_position()
	main.call("_save_game", false)

	main.call("_show_menu")
	await create_timer(0.15).timeout
	if str(audio.get("current_music_id")) != music_id or player.stream != original_stream or not player.playing:
		_fail("La canción se detiene o se sustituye al volver al menú")
		return
	if not bool(audio.call("is_music_suspended")):
		_fail("La canción no queda suspendida en el menú")
		return
	var music_bus := AudioServer.get_bus_index("Music")
	if music_bus < 0 or not AudioServer.is_bus_mute(music_bus):
		_fail("La canción sigue siendo audible en el menú")
		return
	var position_in_menu := player.get_playback_position()
	if position_in_menu <= position_before_menu:
		_fail("La canción no sigue avanzando silenciosamente en el menú")
		return
	var character_select := main.get_node_or_null("CharacterSelectManager")
	if character_select == null:
		_fail("No se encuentra el controlador del botón Continuar")
		return
	character_select.call("_continue_with_migration")
	await process_frame

	if bool(audio.call("is_music_suspended")) or AudioServer.is_bus_mute(music_bus):
		_fail("La canción no recupera el volumen al continuar")
		return
	if str(audio.get("current_music_id")) != music_id or player.stream != original_stream or player.get_playback_position() < position_in_menu:
		_fail("Continuar reinicia la canción en vez de mantenerla sonando")
		return

	print("MUSIC RESUME OK: la canción sigue avanzando en silencio y recupera el volumen.")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
