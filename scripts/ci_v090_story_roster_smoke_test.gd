extends SceneTree

const Story = preload("res://scripts/story.gd")

var dm: Node


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	if not version.begins_with("0.9.") and not version.begins_with("0.10."):
		_fail("La prueba requiere la rama 0.9.x o 0.10.x")
		return
	if not ResourceLoader.exists("res://assets/ui/icons/sound-on.svg") or not ResourceLoader.exists("res://assets/ui/icons/mute.svg"):
		_fail("Faltan los dos iconos de estado de audio")
		return

	dm = root.get_node_or_null("DataManager")
	if dm == null:
		_fail("DataManager no está disponible")
		return
	dm.call("reload_all")
	for method_name in ["get_all_character_ids", "set_runtime_active_characters", "get_runtime_active_characters", "set_runtime_narrative_day"]:
		if not dm.has_method(method_name):
			_fail("Falta API 0.9: " + method_name)
			return

	var default_ids: Array = dm.call("get_runtime_active_characters")
	if default_ids != ["javi", "smokey"]:
		_fail("El reparto predeterminado no es Javi + Smokey: %s" % [default_ids])
		return

	var default_state: Dictionary = dm.call("migrate_save_state", {
		"node_id": "javi_intro_01",
		"affinity": {}, "expressions": {}, "history": []
	})
	if default_state.get("active_characters", []) != ["javi", "smokey"]:
		_fail("Una partida nueva no hereda Javi + Smokey como roster")
		return

	var all_ids: Array = dm.call("get_all_character_ids", true)
	if all_ids.size() < 7:
		_fail("No se recupera el reparto completo")
		return
	var reduced := ["javi", "sue", "smokey"]
	dm.call("set_runtime_active_characters", reduced)
	var intros: Array[String] = []
	for day_id in [1, 2, 3]:
		dm.call("set_runtime_narrative_day", day_id)
		Story.refresh()
		if Story.ENCOUNTER_ORDER != reduced:
			_fail("El reparto reducido no se aplica al día %d" % day_id)
			return
		for character_id in reduced:
			if Story.question_count(character_id) != 1:
				_fail("%s no tiene exactamente una pregunta en el día %d" % [character_id, day_id])
				return
		var encounter: Dictionary = Story.ENCOUNTERS.get("javi", {})
		var intro: Array = encounter.get("intro", [])
		if intro.is_empty():
			_fail("Javi no tiene diálogo de entrada en el día %d" % day_id)
			return
		intros.append(JSON.stringify(intro))
	if intros[0] == intros[1] or intros[1] == intros[2] or intros[0] == intros[2]:
		_fail("Los tres días reutilizan el mismo diálogo")
		return
	if Story.game_title() != "Entre líneas: La cuarta silla":
		_fail("El título no se adapta a tres personajes")
		return
	if Story.title_for_character_count(1) != "Entre líneas: La segunda silla" or Story.title_for_character_count(7) != "Entre líneas: La octava silla" or Story.title_for_character_count(8) != "Entre líneas: La novena silla":
		_fail("La ordinal dinámica de la silla no cubre segunda/octava/novena")
		return

	var migrated: Dictionary = dm.call("migrate_save_state", {
		"player": {"id": "javi", "name": "Javi", "display_name": "Javi"},
		"active_characters": reduced.duplicate(),
		"node_id": "sue_intro_01",
		"affinity": {}, "expressions": {}, "history": []
	})
	if migrated.get("active_characters", []) != reduced:
		_fail("El reparto elegido no persiste en el estado de partida")
		return

	# Restauramos el reparto completo antes de montar la escena para comprobar la UI.
	dm.call("set_runtime_active_characters", all_ids)
	dm.call("set_runtime_narrative_day", 1)
	Story.refresh()
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(64):
		await process_frame

	var roster_button := main.find_child("StoryRosterButton090", true, false) as Button
	var roster_overlay := main.find_child("StoryRosterOverlay090", true, false) as Control
	var next_day := main.find_child("NarrativeNextDayButton090", true, false) as Button
	var master_mute := main.find_child("MasterMute084", true, false) as Button
	var room_mute := main.find_child("RoomMasterMute084", true, false) as Button
	if roster_button == null or roster_overlay == null:
		main.queue_free()
		_fail("El selector de personajes no está integrado en el menú")
		return
	var settings_screen := main.find_child("SettingsScreen060", true, false) as Control
	if settings_screen == null or not settings_screen.is_ancestor_of(roster_button) or not roster_button.visible:
		main.queue_free()
		_fail("El selector de personajes no está disponible dentro de Ajustes")
		return
	if next_day == null:
		main.queue_free()
		_fail("No existe el botón manual para pasar de día")
		return
	if master_mute == null or room_mute == null:
		main.queue_free()
		_fail("Faltan controles de mute general")
		return

	var audio: Node = main.get("audio_manager") as Node
	var audio_ui := main.get_node_or_null("Version040Manager")
	var audio_guard := main.get_node_or_null("Version096MuteVisualGuard")
	if audio == null or audio_ui == null or audio_guard == null:
		main.queue_free()
		_fail("No se puede validar el audio 0.9")
		return
	if bool(audio.call("is_muted")):
		audio.call("toggle_mute")
	audio_ui.call("_refresh_master_ui")
	audio_guard.call("refresh_now")
	if not _audio_visual_matches(master_mute, false) or not _audio_visual_matches(room_mute, false):
		main.queue_free()
		_fail("El estado de audio activo no usa exclusivamente sound-on.svg")
		return
	audio.call("toggle_mute")
	audio_ui.call("_refresh_master_ui")
	audio_guard.call("refresh_now")
	if not _audio_visual_matches(master_mute, true) or not _audio_visual_matches(room_mute, true):
		main.queue_free()
		_fail("El estado silenciado no usa exclusivamente mute.svg")
		return
	audio.call("toggle_mute")

	var runtime := main.get_node_or_null("StoryRuntimeManager")
	if runtime == null:
		main.queue_free()
		_fail("StoryRuntimeManager no está integrado")
		return
	runtime.call("apply_story_runtime", reduced, 1, true)
	await process_frame
	var title := main.find_child("GameTitle", true, false) as Label
	if title == null or not title.text.contains("cuarta"):
		main.queue_free()
		_fail("El título del menú no cambia con el reparto")
		return

	# El primer plano de Javi debe permanecer bloqueado antes del día 3.
	var javi_manager := main.get_node_or_null("JaviMonitorCloseupManager")
	var game_screen := main.get("game_screen") as Control
	if javi_manager == null or game_screen == null:
		main.queue_free()
		_fail("No se puede validar la interacción de Javi")
		return
	game_screen.visible = true
	main.set("current_background", "habitacion_javi")
	main.set("state", {"node_id": "javi_intro_01", "player": {"id": "sue"}, "active_characters": reduced, "narrative_progress": {"current_day": 2}})
	if bool(javi_manager.call("_is_javi_room_active")):
		main.queue_free()
		_fail("Los monitores de Javi se activan antes del día 3")
		return
	main.set("state", {"node_id": "javi_intro_01", "player": {"id": "sue"}, "active_characters": reduced, "narrative_progress": {"current_day": 3}})
	if not bool(javi_manager.call("_is_javi_room_active")):
		main.queue_free()
		_fail("Los monitores de Javi no se habilitan el día 3")
		return

	main.queue_free()
	print("V090 STORY ROSTER OK: reparto Javi + Smokey por defecto, diálogos por día, una pregunta, roster, título, cambio manual de día, mute dual y monitores del día 3 validados.")
	quit(0)


func _audio_visual_matches(button: Button, muted: bool) -> bool:
	if button == null or button.icon != null:
		return false
	var sound_on := button.get_node_or_null("MuteSoundOn096") as TextureRect
	var mute_off := button.get_node_or_null("MuteOff096") as TextureRect
	if sound_on == null or mute_off == null or sound_on.texture == null or mute_off.texture == null:
		return false
	if not sound_on.texture.resource_path.ends_with("sound-on.svg"):
		return false
	if not mute_off.texture.resource_path.ends_with("mute.svg"):
		return false
	if sound_on.visible != (not muted) or mute_off.visible != muted:
		return false
	return bool(button.get_meta("audio_muted_visual", not muted)) == muted


func _fail(message: String) -> void:
	push_error("V090 STORY ROSTER FAIL: " + message)
	quit(1)
