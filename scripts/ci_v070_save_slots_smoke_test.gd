extends SceneTree

var dm: Node
var created_slots: Array[int] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	dm = root.get_node_or_null("DataManager")
	if dm == null:
		_fail("DataManager no está disponible")
		return
	dm.call("reload_all")
	for method_name in [
		"get_max_save_slots", "list_save_slots", "get_save_slot_summary",
		"set_active_save_slot", "get_active_save_slot", "get_last_used_save_slot",
		"save_slot_exists", "load_save_slot", "delete_save_slot"
	]:
		if not dm.has_method(method_name):
			_fail("Falta API de slots: " + method_name)
			return
	if int(dm.call("get_max_save_slots")) != 10:
		_fail("El límite de partidas no es de 10 slots")
		return
	var summaries: Array = dm.call("list_save_slots")
	if summaries.size() != 10:
		_fail("La lista de partidas no devuelve exactamente 10 slots")
		return

	# La prueba nunca sobrescribe partidas existentes. En CI habrá huecos de sobra;
	# si se ejecuta localmente sobre un perfil lleno, omite la parte destructiva.
	var empty_slots: Array[int] = []
	for summary_value in summaries:
		if typeof(summary_value) != TYPE_DICTIONARY:
			continue
		var summary := summary_value as Dictionary
		if not bool(summary.get("occupied", false)):
			empty_slots.append(int(summary.get("slot_id", 0)))
	if empty_slots.size() >= 2:
		if not _exercise_two_independent_slots(empty_slots[0], empty_slots[1]):
			_cleanup()
			return
	else:
		print("SAVE SLOTS INFO: no hay dos slots vacíos; se omite escritura para proteger partidas locales.")

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_cleanup()
		_fail("No se puede cargar la escena principal")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(52):
		await process_frame
	var manager := main.get_node_or_null("SaveSlotsManager")
	var screen := main.find_child("SaveSlotsScreen070", true, false) as Control
	var grid := main.find_child("SaveSlotsGrid070", true, false) as GridContainer
	var manage_button := main.find_child("ManageSaveSlotsButton070", true, false) as Button
	if manager == null or screen == null or grid == null or manage_button == null:
		main.queue_free()
		_cleanup()
		_fail("La interfaz de gestión de partidas no está integrada en main.tscn")
		return
	manager.call("open_new_game_slots")
	for _i in range(3):
		await process_frame
	if not screen.visible or grid.get_child_count() != 10:
		main.queue_free()
		_cleanup()
		_fail("Nueva partida no abre los diez slots")
		return
	var new_button := _find_button_with_text(main, "Nueva partida")
	var continue_button := _find_button_with_text(main, "Continuar")
	if new_button == null or continue_button == null:
		main.queue_free()
		_cleanup()
		_fail("El menú principal ha perdido Nueva partida o Continuar")
		return
	if not _has_pressed_method(new_button, "open_new_game_slots") or not _has_pressed_method(continue_button, "continue_last_slot"):
		main.queue_free()
		_cleanup()
		_fail("Nueva partida/Continuar no están enlazados al gestor de slots")
		return
	manager.call("_close_slots")
	main.queue_free()
	_cleanup()
	print("SAVE SLOTS OK: 10 slots, Invitado fijo, separación de partidas, resumen, carga/borrado y UI validados.")
	quit(0)


func _guest_state(coins: int, zone_id: String, completed: Array, checkpoints: Dictionary, play_seconds: float) -> Dictionary:
	return dm.call("migrate_save_state", {
		"node_id": "__VISIT_SELECT__",
		"player": {"id": "custom", "name": "Invitado", "display_name": "Invitado", "guest": true},
		"affinity": {}, "expressions": {}, "history": [],
		"completed_characters": completed,
		"conversation_checkpoints": checkpoints,
		"current_zone_id": zone_id,
		"coins": coins,
		"claimed_rewards": {},
		"slot_play_seconds": play_seconds
	})


func _exercise_two_independent_slots(slot_a: int, slot_b: int) -> bool:
	var profile_path_before := str(dm.call("get_profile_path"))
	var state_a := _guest_state(77, "naranjal_del_rio", ["sue"], {}, 123.0)
	if not bool(dm.call("set_active_save_slot", slot_a)) or not bool(dm.call("save_game", state_a)):
		_fail("No se puede crear una partida en un slot vacío")
		return false
	created_slots.append(slot_a)
	var state_b := _guest_state(3, "triana", [], {"jony": "jony_intro_01"}, 20.0)
	if not bool(dm.call("set_active_save_slot", slot_b)) or not bool(dm.call("save_game", state_b)):
		_fail("No se puede crear una segunda partida independiente")
		return false
	created_slots.append(slot_b)
	var summary_a: Dictionary = dm.call("get_save_slot_summary", slot_a)
	var summary_b: Dictionary = dm.call("get_save_slot_summary", slot_b)
	if not bool(summary_a.get("occupied", false)) or not bool(summary_b.get("occupied", false)):
		_fail("Los slots creados no aparecen ocupados")
		return false
	if str(summary_a.get("protagonist_name", "")) != "Invitado" or int(summary_a.get("coins", -1)) != 77:
		_fail("El resumen del primer slot mezcla o pierde sus datos")
		return false
	if str(summary_b.get("protagonist_name", "")) != "Invitado" or int(summary_b.get("coins", -1)) != 3:
		_fail("El resumen del segundo slot mezcla o pierde sus datos")
		return false
	if int(summary_a.get("progress_percent", 0)) <= 0:
		_fail("El porcentaje narrativo no refleja las visitas completadas")
		return false
	var loaded_a: Dictionary = dm.call("load_save_slot", slot_a)
	var loaded_player: Dictionary = loaded_a.get("player", {}) if typeof(loaded_a.get("player", {})) == TYPE_DICTIONARY else {}
	if int(loaded_a.get("coins", -1)) != 77 or str(loaded_player.get("id", "")) != "custom" or not bool(loaded_player.get("guest", false)):
		_fail("Cargar un slot concreto devuelve datos de otra partida o pierde al Invitado")
		return false
	if int(dm.call("get_last_used_save_slot")) != slot_a:
		_fail("El slot cargado no pasa a ser la partida más reciente")
		return false
	if str(dm.call("get_profile_path")) != profile_path_before or profile_path_before != "user://profile.json":
		_fail("El perfil global se ha mezclado con los archivos por slot")
		return false
	if not bool(dm.call("delete_save_slot", slot_b)) or bool(dm.call("save_slot_exists", slot_b)):
		_fail("No se puede borrar una partida individual")
		return false
	created_slots.erase(slot_b)
	if not bool(dm.call("save_slot_exists", slot_a)):
		_fail("Borrar un slot elimina también otra partida")
		return false
	return true


func _cleanup() -> void:
	if dm == null:
		return
	for slot_id in created_slots.duplicate():
		if bool(dm.call("save_slot_exists", slot_id)):
			dm.call("delete_save_slot", slot_id)
	created_slots.clear()
	dm.call("clear_active_save_slot")


func _find_button_with_text(node: Node, expected: String) -> Button:
	if node is Button and (node as Button).text == expected:
		return node as Button
	for child in node.get_children():
		var found := _find_button_with_text(child, expected)
		if found != null:
			return found
	return null


func _has_pressed_method(button: Button, method_name: String) -> bool:
	for connection in button.pressed.get_connections():
		var callable: Callable = connection.get("callable", Callable())
		if callable.is_valid() and str(callable.get_method()) == method_name:
			return true
	return false


func _fail(message: String) -> void:
	push_error("SAVE SLOTS FAIL: " + message)
	quit(1)
