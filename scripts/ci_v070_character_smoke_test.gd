extends SceneTree

const EXPECTED_IDS := ["javi", "sue", "smokey", "carmen", "jony", "ana", "argentino", "charlie"]
const Story = preload("res://scripts/story.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var dm := root.get_node_or_null("DataManager")
	if dm == null:
		_fail("DataManager no está disponible")
		return
	dm.call("reload_all")
	var errors: Array = dm.call("get_data_errors")
	if not errors.is_empty():
		_fail("Los datos contienen errores: " + str(errors))
		return
	var ids: Array = dm.call("get_all_character_ids", true) if dm.has_method("get_all_character_ids") else dm.call("get_character_ids", true)
	if ids != EXPECTED_IDS:
		_fail("El reparto activo no contiene los ocho miembros esperados: " + str(ids))
		return

	Story.refresh()
	if Story.game_title() != "Entre líneas: La novena silla":
		_fail("El título dinámico no refleja ocho miembros más el Invitado")
		return
	if Story.ENCOUNTER_ORDER.size() != 8 or not Story.ENCOUNTER_ORDER.has("charlie"):
		_fail("Charlie no está integrado en Story")
		return

	var charlie: Dictionary = dm.call("get_character", "charlie")
	if str(charlie.get("display_name", "")) != "Charlie" or bool(charlie.get("playable", true)):
		_fail("La ficha operativa de Charlie no está configurada como NPC")
		return
	var charlie_image := str(charlie.get("image", ""))
	if charlie_image != "res://assets/characters/charlie/charlie.png" or not ResourceLoader.exists(charlie_image):
		_fail("El retrato real de Charlie no está configurado o no es cargable")
		return
	var room: Dictionary = dm.call("get_room_for_character", "charlie")
	if str(room.get("id", "")) != "room_charlie" or bool(room.get("placeholder_background", true)):
		_fail("La habitación real de Charlie no está configurada")
		return
	var room_path := str(room.get("background_path", ""))
	if room_path != "res://assets/backgrounds/fondo-habitacion-charlie.jpg" or not ResourceLoader.exists(room_path):
		_fail("El fondo real de Charlie no es cargable")
		return

	for day_id in [1, 2, 3]:
		dm.call("set_runtime_narrative_day", day_id)
		var bundle: Dictionary = dm.call("get_question_bundle", "charlie")
		if (bundle.get("intro", []) as Array).is_empty() or (bundle.get("questions", []) as Array).is_empty():
			_fail("El arco de Charlie no tiene contenido para el Día %d" % day_id)
			return

	dm.call("set_runtime_narrative_day", 2)
	var argentino_bundle: Dictionary = dm.call("get_question_bundle", "argentino")
	var quote_found := false
	for raw_line in argentino_bundle.get("intro", []) as Array:
		if typeof(raw_line) == TYPE_DICTIONARY and str((raw_line as Dictionary).get("text", "")) == "Yo no he puesto una carita sonriente en mi vida.":
			quote_found = true
			break
	if not quote_found:
		_fail("No aparece la frase nueva del Argentino en el Día 2")
		return

	var migrated: Dictionary = dm.call("migrate_save_state", {
		"player": {"id": "custom", "display_name": "Invitado", "guest": true},
		"active_characters": ["javi", "sue", "smokey", "carmen", "jony", "ana", "argentino"],
		"affinity": {},
		"expressions": {},
		"history": []
	})
	if not (migrated.get("active_characters", []) as Array).has("charlie"):
		_fail("Una partida antigua no incorpora automáticamente a Charlie")
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(18):
		await process_frame
	var slots: Dictionary = main.get("character_slots")
	var views: Dictionary = main.get("character_views")
	if not slots.has("charlie") or not views.has("charlie"):
		_fail("La escena principal no crea el slot de Charlie")
		return
	var charlie_view := views.get("charlie") as TextureRect
	if charlie_view == null or charlie_view.texture == null:
		_fail("Charlie debe renderizar su retrato real")
		return

	print("SMOKE OK: ocho miembros, Invitado fijo, Charlie con retrato y habitación reales, arco y frase del Argentino validados.")
	quit(0)


func _fail(message: String) -> void:
	push_error("SMOKE FAIL: " + message)
	quit(1)
