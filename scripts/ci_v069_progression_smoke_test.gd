extends "res://scripts/ci_v060_progression_smoke_test.gd"

# El smoke completo nació en 0.6 y conserva una guard clause histórica que
# exige 0.6.x. Presentamos 0.6.9 solo durante esta prueba para mantener los
# contratos heredados que todavía se validan en el resto del archivo.
func _initialize() -> void:
	var current_version := str(ProjectSettings.get_setting("application/config/version", ""))
	if current_version.begins_with("0.7.") or current_version.begins_with("0.8.") or current_version.begins_with("0.9."):
		ProjectSettings.set_setting("application/config/version", "0.6.9")
	super()


# El reparto actual añade a Charlie en Naranjal. Mantenemos aquí los contratos
# esenciales del mapa sin fijar de nuevo la antigua lista de siete personajes.
func _validate_world_data() -> bool:
	if not FileAccess.file_exists(MAP_PATH) or not ResourceLoader.exists(MAP_PATH):
		_fail("El PNG original de Naranjal no está incorporado/importado")
		return false
	var map_texture := load(MAP_PATH) as Texture2D
	if map_texture == null or map_texture.get_width() != 1672 or map_texture.get_height() != 941:
		_fail("El PNG de Naranjal no conserva sus dimensiones 1672x941")
		return false
	if not ResourceLoader.exists(COIN_ICON_PATH):
		_fail("No existe el icono original de MONEDAS")
		return false
	var world: Dictionary = data_manager.call("get_world_maps")
	var zones: Dictionary = world.get("zones", {})
	for zone_id in ["naranjal_del_rio", "triana", "monte_del_toro"]:
		if not zones.has(zone_id):
			_fail("Falta la localidad " + zone_id)
			return false
	var naranjal: Dictionary = zones.get("naranjal_del_rio", {})
	var triana: Dictionary = zones.get("triana", {})
	var monte: Dictionary = zones.get("monte_del_toro", {})
	if (naranjal.get("residents", []) as Array) != ["javi", "sue", "smokey", "argentino", "charlie"]:
		_fail("Naranjal no contiene el reparto actual, incluido Charlie")
		return false
	if (triana.get("residents", []) as Array) != ["ana", "jony"] or (monte.get("residents", []) as Array) != ["carmen"]:
		_fail("Triana o Monte del Toro han perdido sus residentes")
		return false
	var found_charlie := false
	for raw_location in naranjal.get("locations", []) as Array:
		if typeof(raw_location) != TYPE_DICTIONARY:
			continue
		var location := raw_location as Dictionary
		var position: Dictionary = location.get("position", {})
		var x := float(position.get("x", -1.0))
		var y := float(position.get("y", -1.0))
		if x < 0.0 or x > 1.0 or y < 0.0 or y > 1.0:
			_fail("Una localización no usa coordenadas normalizadas")
			return false
		if str(location.get("character_id", "")) == "charlie":
			found_charlie = true
	if not found_charlie:
		_fail("Charlie no tiene marcador propio en Naranjal")
		return false
	if (data_manager.call("get_missing_map_excuses") as Array).size() != 10:
		_fail("No se cargan las diez excusas configurables")
		return false
	if (data_manager.call("get_achievements", true) as Array).size() < 10 or (data_manager.call("get_shop_items", true) as Array).size() < 2:
		_fail("Logros o catálogo inicial no están cargados desde datos")
		return false
	return true


# Desde 0.9.38 el protagonista ya no se selecciona. El flujo correcto es
# slot -> Invitado -> preludio -> historia, conservando a todo el grupo como NPC.
func _validate_new_game_intro(main: Control, transitions: Node) -> bool:
	var new_game := _find_button_with_text(main, "Nueva partida")
	var continue_game := _find_button_with_text(main, "Continuar")
	if new_game == null or not _button_has_callback(new_game, "open_new_game_slots"):
		_fail("Nueva partida no está enlazada al selector de slots")
		return false
	if continue_game == null or not _button_has_callback(continue_game, "continue_last_slot"):
		_fail("Continuar no está enlazado al último slot utilizado")
		return false
	var character_select := main.get_node_or_null("CharacterSelectManager")
	if character_select == null:
		_fail("No está disponible el gestor del Invitado")
		return false

	var menu_screen := main.get("menu_screen") as Control
	var game_screen := main.get("game_screen") as Control
	var ending_screen := main.get("ending_screen") as Control
	var menu_was_visible := menu_screen != null and menu_screen.visible
	var game_was_visible := game_screen != null and game_screen.visible
	var ending_was_visible := ending_screen != null and ending_screen.visible

	character_select.call("_begin_new_game")
	for _i in range(3):
		await process_frame
	var state: Dictionary = main.get("state")
	var player: Dictionary = state.get("player", {}) if typeof(state.get("player", {})) == TYPE_DICTIONARY else {}
	if str(player.get("display_name", "")) != "Invitado" or not bool(player.get("guest", false)):
		_fail("Nueva partida no entra directamente como Invitado")
		return false
	var flow_screen := character_select.get("flow_screen") as Control
	if flow_screen != null and flow_screen.visible:
		_fail("Ha reaparecido la selección de protagonista")
		return false
	var active: Array = state.get("active_characters", []) if typeof(state.get("active_characters", [])) == TYPE_ARRAY else []
	if active.size() != 8 or not active.has("charlie"):
		_fail("La run del Invitado no conserva a los ocho NPC")
		return false

	var cinematic := main.get_node_or_null("NewGamePrelude0917")
	if cinematic == null:
		_fail("No se crea el preludio de Nueva partida al confirmar al Invitado")
		return false
	cinematic.emit_signal("prelude_finished")
	cinematic.queue_free()
	await process_frame
	await process_frame
	if bool(transitions.get("waiting_for_continue")) or bool(transitions.get("transition_active")):
		_fail("El preludio deja una transición bloqueada")
		return false

	if menu_screen != null:
		menu_screen.visible = menu_was_visible
	if game_screen != null:
		game_screen.visible = game_was_visible
	if ending_screen != null:
		ending_screen.visible = ending_was_visible
	return true


# La 0.6.9 mantiene el smoke completo de progreso 0.6, pero el retorno desde
# las localidades temporales ahora es direccional: Triana vuelve por la derecha
# y Monte del Toro por la izquierda.
func _button_at_panel_bottom_right(panel: Control, button: Button) -> bool:
	var panel_rect := panel.get_global_rect()
	var button_rect := button.get_global_rect()
	var at_bottom := panel_rect.encloses(button_rect) \
		and button_rect.get_center().y > panel_rect.get_center().y \
		and panel_rect.end.y - button_rect.end.y <= 40.0
	if not at_bottom or button.icon == null:
		return false
	if button.icon_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		return panel_rect.end.x - button_rect.end.x <= 40.0
	if button.icon_alignment == HORIZONTAL_ALIGNMENT_LEFT:
		return button_rect.position.x - panel_rect.position.x <= 40.0
	return false
