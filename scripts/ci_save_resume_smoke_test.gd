extends SceneTree

var dm: Node
var created_slot := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
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
		_cleanup()
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(40):
		await process_frame

	var new_game_manager := main.get_node_or_null("CharacterSelectManager")
	var menu_screen := main.get("menu_screen") as Control
	var continue_button := main.get("continue_button") as Button
	if new_game_manager == null or not new_game_manager.has_method("_start_guest_game") or menu_screen == null or continue_button == null:
		main.queue_free()
		_cleanup()
		_fail("Faltan componentes del flujo de partida")
		return

	if not bool(dm.call("set_active_save_slot", created_slot)):
		main.queue_free()
		_cleanup()
		_fail("No se puede activar el slot de prueba")
		return
	main.set("state", {})
	new_game_manager.call("_start_guest_game")
	for _i in range(8):
		await process_frame

	if not bool(dm.call("save_slot_exists", created_slot)):
		main.queue_free()
		_cleanup()
		_fail("Empezar la partida no crea el archivo del slot")
		return
	var first_loaded: Dictionary = dm.call("load_save_slot", created_slot)
	var player: Dictionary = first_loaded.get("player", {})
	if str(player.get("id", "")) != "custom" or not bool(player.get("guest", false)):
		main.queue_free()
		_cleanup()
		_fail("El guardado no usa al Invitado fijo")
		return
	var active: Array = first_loaded.get("active_characters", [])
	if active.size() != 8 or not active.has("charlie"):
		main.queue_free()
		_cleanup()
		_fail("El guardado no conserva los ocho NPC")
		return

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
		_fail("Volver desde el HUD no muestra el menú")
		return
	if not bool(dm.call("has_save")) or continue_button.disabled:
		main.queue_free()
		_cleanup()
		_fail("Continuar no queda disponible tras guardar")
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
		_fail("Volver al menú no persiste el último estado")
		return

	main.queue_free()
	_cleanup()
	print("SAVE RESUME OK: Invitado fijo, ocho NPC, guardado al volver al menú y Continuar validados.")
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
	push_error("SAVE RESUME FAIL: " + message)
	quit(1)
