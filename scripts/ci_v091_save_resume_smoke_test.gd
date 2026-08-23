extends SceneTree

const RuntimeGameData = preload("res://scripts/game_data.gd")

var dm: Node
var created_slot := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	if not version.begins_with("0.9.") and not version.begins_with("0.10."):
		_fail("La prueba requiere la rama 0.9.x o 0.10.x")
		return

	dm = root.get_node_or_null("DataManager")
	if dm == null:
		_fail("DataManager no está disponible")
		return
	dm.call("reload_all")
	created_slot = _first_empty_slot()
	if created_slot <= 0:
		_fail("No hay un slot vacío para la prueba")
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	# Reproduce el primer momento en que el gestor de slots ya está listo.
	for _i in range(36):
		await process_frame

	var save_manager := main.get_node_or_null("SaveSlotsManager")
	var character_select := main.get_node_or_null("CharacterSelectManager")
	var menu_screen := main.get("menu_screen") as Control
	var continue_button := main.get("continue_button") as Button
	if save_manager == null or character_select == null or menu_screen == null or continue_button == null:
		main.queue_free()
		_cleanup()
		_fail("Faltan componentes del flujo real de partida")
		return

	# Seleccionar un slot vacío debe conservarlo durante la selección de protagonista.
	save_manager.call("_start_new_game_in_slot", created_slot)
	await process_frame
	if int(dm.call("get_active_save_slot")) != created_slot:
		main.queue_free()
		_cleanup()
		_fail("El slot elegido se pierde antes de seleccionar protagonista")
		return

	# Saltamos únicamente la animación de introducción; el resto del arranque es el real.
	character_select.call("open_selection")
	character_select.set("pending_profile", RuntimeGameData.character_profile("javi"))
	character_select.call("_start_game")
	for _i in range(10):
		await process_frame

	if not bool(dm.call("save_slot_exists", created_slot)):
		main.queue_free()
		_cleanup()
		_fail("Empezar la partida no crea el archivo del slot")
		return
	var first_loaded: Dictionary = dm.call("load_save_slot", created_slot)
	if str((first_loaded.get("player", {}) as Dictionary).get("id", "")) != "javi":
		main.queue_free()
		_cleanup()
		_fail("El primer guardado no conserva al protagonista")
		return

	# El botón Menú del HUD llama directamente a main._show_menu(). Antes de 0.9.1
	# esa ruta no forzaba un guardado: comprobamos que el estado inmediatamente
	# anterior a volver al menú queda persistido y que Continuar se reactiva.
	var state: Dictionary = main.get("state")
	state["coins"] = 321
	state["current_zone_id"] = "naranjal_del_rio"
	main.set("state", state)
	main.call("_show_menu")
	for _i in range(4):
		await process_frame

	if not menu_screen.visible:
		main.queue_free()
		_cleanup()
		_fail("El botón del HUD no muestra el menú")
		return
	if not bool(dm.call("has_save")):
		main.queue_free()
		_cleanup()
		_fail("El guardado desaparece al volver al menú")
		return
	if continue_button.disabled:
		main.queue_free()
		_cleanup()
		_fail("Continuar queda deshabilitado aunque el slot exista")
		return
	if int(dm.call("get_last_used_save_slot")) != created_slot:
		main.queue_free()
		_cleanup()
		_fail("El slot iniciado no queda como última partida utilizada")
		return
	var returned_state: Dictionary = dm.call("load_save_slot", created_slot)
	if int(returned_state.get("coins", -1)) != 321:
		main.queue_free()
		_cleanup()
		_fail("Volver al menú desde el HUD no persiste el último estado de la partida")
		return

	main.queue_free()
	_cleanup()
	print("V091 SAVE RESUME OK: slot inmediato, guardado al volver desde HUD y botón Continuar validados.")
	quit(0)


func _first_empty_slot() -> int:
	var summaries: Array = dm.call("list_save_slots")
	for raw_summary in summaries:
		if typeof(raw_summary) != TYPE_DICTIONARY:
			continue
		var summary := raw_summary as Dictionary
		if not bool(summary.get("occupied", false)):
			return int(summary.get("slot_id", 0))
	return 0


func _cleanup() -> void:
	if dm == null:
		return
	if created_slot > 0 and bool(dm.call("save_slot_exists", created_slot)):
		dm.call("delete_save_slot", created_slot)
	dm.call("clear_active_save_slot")
	created_slot = 0


func _fail(message: String) -> void:
	push_error("V091 SAVE RESUME FAIL: " + message)
	quit(1)
