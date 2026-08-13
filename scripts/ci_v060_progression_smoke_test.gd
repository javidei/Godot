extends SceneTree

const MAP_PATH := "res://assets/maps/naranjal_del_rio.png"
const COIN_ICON_PATH := "res://assets/ui/icons/coin.svg"
const GROUP_ART_ILLUSTRATED := "res://assets/collectibles/group_portrait_illustrated.png"
const GROUP_ART_PIXEL := "res://assets/collectibles/group_portrait_pixel.png"

var data_manager: Node
var intro_callback_called := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var project_version := str(ProjectSettings.get_setting("application/config/version", ""))
	if not project_version.begins_with("0.6."):
		_fail("La prueba requiere la rama 0.6.x")
		return
	data_manager = root.get_node_or_null("DataManager")
	if data_manager == null:
		_fail("DataManager no está disponible")
		return
	data_manager.call("reload_all")
	var data_errors: Array = data_manager.call("get_data_errors")
	if not data_errors.is_empty():
		var error_texts := PackedStringArray()
		for error_value in data_errors:
			error_texts.append(str(error_value))
		_fail("Los datos 0.6 contienen errores: " + " | ".join(error_texts))
		return

	if not _validate_world_data() or not _validate_migrations():
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar la escena principal")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(38):
		await process_frame

	var progress := main.get_node_or_null("ProgressManager")
	var world_map := main.get_node_or_null("WorldMapManager")
	var transitions := main.get_node_or_null("Version044VisitTransitions")
	var extras := main.get_node_or_null("Version050ExtrasCodex")
	var audio: Variant = main.get("audio_manager")
	if progress == null or world_map == null or transitions == null or extras == null or audio == null:
		_fail("Falta un manager de mapa, progreso, transiciones, Extras o audio")
		return
	if main.find_child("ProgressNotificationHost", true, false) == null:
		_fail("El progreso no crea la notificación visual no bloqueante")
		return

	var state: Dictionary = data_manager.call("migrate_save_state", {
		"node_id": "__VISIT_SELECT__",
		"player": {"id": "javi", "display_name": "Javi"},
		"affinity": {},
		"expressions": {},
		"history": [],
		"visit_mode": true,
		"completed_characters": ["sue"],
		"visit_order": ["sue"]
	})
	main.set("state", state)

	var first_result: Dictionary = progress.call("record_event", "character_visited", {
		"character_id": "jony", "location_id": "room_jony", "first_visit": true
	}, state)
	if not bool(first_result.get("success", false)) or int(state.get("coins", -1)) != 15:
		_fail("La primera visita no concede exactamente 15 MONEDAS")
		return
	var claimed: Dictionary = state.get("claimed_rewards", {})
	if not claimed.has("first_visit_jony"):
		_fail("La recompensa única no queda registrada por id")
		return
	progress.call("record_event", "character_visited", {
		"character_id": "jony", "location_id": "room_jony", "first_visit": true
	}, state)
	if int(state.get("coins", -1)) != 15:
		_fail("La recompensa única puede cobrarse dos veces")
		return
	progress.call("record_event", "scene_discovered", {"scene_id": "jony_intro_01"}, state)
	progress.call("record_event", "scene_discovered", {"scene_id": "jony_intro_01"}, state)
	if int(state.get("coins", -1)) != 35:
		_fail("La escena única no concede una sola recompensa de 20 MONEDAS")
		return

	var profile_before_purchase: Dictionary = progress.call("get_profile")
	var statistics: Dictionary = profile_before_purchase.get("statistics", {})
	var character_visits: Dictionary = statistics.get("character_visits", {})
	var unique_scenes: Array = statistics.get("unique_scenes", [])
	if int(character_visits.get("jony", 0)) != 2 or unique_scenes.count("jony_intro_01") != 1:
		_fail("Las estadísticas de visitas o escenas únicas no se acumulan correctamente")
		return
	var unlocked_achievements: Dictionary = profile_before_purchase.get("unlocked_achievements", {})
	if not unlocked_achievements.has("first_visit"):
		_fail("El logro data-driven de primera visita no se desbloquea")
		return

	var purchase_result: Dictionary = progress.call("purchase", "illustration_group", state)
	if not bool(purchase_result.get("success", false)) or int(state.get("coins", -1)) != 5:
		_fail("La tienda no descuenta el precio desde las MONEDAS de la partida")
		return
	if not bool(progress.call("is_item_unlocked", "illustration_group", "collectible")):
		_fail("La compra no queda desbloqueada globalmente")
		return
	var duplicate_purchase: Dictionary = progress.call("purchase", "illustration_group", state)
	if bool(duplicate_purchase.get("success", false)) or int(state.get("coins", -1)) != 5:
		_fail("La tienda permite recomprar un desbloqueo global")
		return
	var saved_state: Dictionary = data_manager.call("load_game")
	if int(saved_state.get("coins", -1)) != 5 or saved_state.has("unlocked_collectibles"):
		_fail("El save no conserva saldo por partida o mezcla el perfil global")
		return
	var persisted_profile: Dictionary = data_manager.call("get_profile")
	var collectibles: Array = persisted_profile.get("unlocked_collectibles", [])
	if not collectibles.has("illustration_group") or not FileAccess.file_exists(str(data_manager.call("get_profile_path"))):
		_fail("El perfil global no persiste en su fichero local independiente")
		return
	state["coins"] = 100
	var cosmetic_purchase: Dictionary = progress.call("purchase", "ana_skin_crimson_night", state)
	if not bool(cosmetic_purchase.get("success", false)) or not bool(progress.call("is_item_unlocked", "ana_skin_crimson_night", "cosmetic")):
		_fail("Una skin de personaje no se compra como desbloqueo cosmético global")
		return

	progress.set("_pending_play_seconds", 2.0)
	if not bool(progress.call("flush_active_time")):
		_fail("No se puede guardar el tiempo activo")
		return
	var timed_profile: Dictionary = progress.call("get_profile")
	var timed_stats: Dictionary = timed_profile.get("statistics", {})
	var platforms: Dictionary = timed_stats.get("platforms", {})
	if float(timed_stats.get("total_play_seconds", 0.0)) < 2.0 or int(timed_stats.get("total_sessions", 0)) < 1 or platforms.is_empty():
		_fail("Tiempo activo, sesiones o plataforma no se registran globalmente")
		return
	if not timed_stats.has("touch_capable_seen"):
		_fail("El perfil no conserva la detección fiable de touch")
		return

	if not _validate_click_settings(audio):
		return
	var intro_is_valid: bool = await _validate_new_game_intro(main, transitions)
	if not intro_is_valid:
		return
	var map_is_valid: bool = await _validate_map_ui(main, world_map, transitions, state)
	if not map_is_valid:
		return
	var extras_are_valid: bool = await _validate_extras(main, extras)
	if not extras_are_valid:
		return

	print("V060 OK: mapa, economía, tienda, cosméticos por personaje, perfil, Extras y clics validados.")
	quit(0)


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
	if str(naranjal.get("map_asset", "")) != MAP_PATH or bool(naranjal.get("temporary", true)):
		_fail("Naranjal no usa el PNG como mapa definitivo")
		return false
	if not bool(triana.get("temporary", false)) or not bool(monte.get("temporary", false)):
		_fail("Triana y Monte del Toro no usan la infraestructura temporal")
		return false
	if (naranjal.get("residents", []) as Array) != ["javi", "sue", "smokey", "argentino"] or (triana.get("residents", []) as Array) != ["ana", "jony"] or (monte.get("residents", []) as Array) != ["carmen"]:
		_fail("Las residencias actuales no coinciden con la especificación")
		return false
	for raw_location in naranjal.get("locations", []) as Array:
		var location: Dictionary = raw_location
		var position: Dictionary = location.get("position", {})
		var x := float(position.get("x", -1.0))
		var y := float(position.get("y", -1.0))
		if x < 0.0 or x > 1.0 or y < 0.0 or y > 1.0:
			_fail("Una localización no usa coordenadas normalizadas")
			return false
	var excuses: Array = data_manager.call("get_missing_map_excuses")
	if excuses.size() != 10:
		_fail("No se cargan las diez excusas configurables")
		return false
	var achievements: Array = data_manager.call("get_achievements", true)
	var shop_items: Array = data_manager.call("get_shop_items", true)
	if achievements.size() < 10 or shop_items.size() < 2:
		_fail("Logros o catálogo inicial no están cargados desde datos")
		return false
	for raw_item in shop_items:
		var item: Dictionary = raw_item
		if not ["collectible", "cosmetic"].has(str(item.get("category", ""))):
			_fail("La tienda contiene una categoría narrativa no permitida")
			return false
	var group_pack: Dictionary = {}
	for raw_item in shop_items:
		if str((raw_item as Dictionary).get("id", "")) == "illustration_group":
			group_pack = raw_item as Dictionary
			break
	var group_artworks: Array = group_pack.get("artworks", [])
	if group_artworks.size() != 2 or str(group_pack.get("asset", "")) != GROUP_ART_ILLUSTRATED:
		_fail("Retratos del grupo no desbloquea exactamente los dos diseños adjuntos")
		return false
	var expected_art_paths := [GROUP_ART_ILLUSTRATED, GROUP_ART_PIXEL]
	for path in expected_art_paths:
		if not FileAccess.file_exists(path) or not ResourceLoader.exists(path):
			_fail("Falta un diseño físico del Retrato del grupo: " + path)
			return false
	var illustrated := load(GROUP_ART_ILLUSTRATED) as Texture2D
	var pixel := load(GROUP_ART_PIXEL) as Texture2D
	if illustrated == null or illustrated.get_width() != 1672 or illustrated.get_height() != 941 or pixel == null or pixel.get_width() != 1536 or pixel.get_height() != 1024:
		_fail("Los dos diseños del grupo no conservan sus dimensiones originales")
		return false
	var ana_cosmetics: Array = data_manager.call("get_character_cosmetics", "ana", true)
	var jony_cosmetics: Array = data_manager.call("get_character_cosmetics", "jony", true)
	if ana_cosmetics.size() < 2 or jony_cosmetics.size() < 2:
		_fail("Ana y Jony no tienen skins/mascotas asociadas desde el catálogo")
		return false
	return true


func _validate_migrations() -> bool:
	var legacy := {
		"node_id": "ana_q2",
		"player": {"id": "sue"},
		"affinity": {"ana": 2},
		"expressions": {},
		"history": [{"choice": "legacy"}]
	}
	var migrated: Dictionary = data_manager.call("migrate_save_state", legacy)
	if int(migrated.get("coins", -1)) != 0 or typeof(migrated.get("claimed_rewards", null)) != TYPE_DICTIONARY:
		_fail("Una partida antigua no migra a 0 MONEDAS y recompensas vacías")
		return false
	if str(migrated.get("node_id", "")) != "ana_q2" or (migrated.get("history", []) as Array).size() != 1:
		_fail("La migración borra progreso narrativo anterior")
		return false
	if int(migrated.get("schema_version", 0)) < 2 or str(migrated.get("current_zone_id", "")) != "naranjal_del_rio":
		_fail("El save no recibe schema o localidad inicial")
		return false
	if int(migrated.get("schema_version", 0)) < 3 or typeof(migrated.get("conversation_checkpoints", null)) != TYPE_DICTIONARY:
		_fail("El save antiguo no migra los puntos de continuación por personaje")
		return false
	var profile: Dictionary = data_manager.call("migrate_profile", {})
	if int(profile.get("schema_version", 0)) < 1 or typeof(profile.get("statistics", null)) != TYPE_DICTIONARY:
		_fail("El perfil global ausente no se crea con schema y estadísticas")
		return false
	return true


func _validate_click_settings(audio: Variant) -> bool:
	var options: Array = audio.call("get_click_sound_options")
	if options.size() != 6:
		_fail("No hay cinco propuestas de clic más Desactivado")
		return false
	audio.call("set_click_sound", "digital", false)
	var settings: Dictionary = data_manager.call("get_settings")
	var audio_settings: Dictionary = settings.get("audio", {})
	if str(audio_settings.get("click_sound", "")) != "digital":
		_fail("La preferencia global de clic no se guarda")
		return false
	var ui_bus := AudioServer.get_bus_index("UI")
	var sfx_bus := AudioServer.get_bus_index("SFX")
	if ui_bus < 0 or sfx_bus < 0:
		_fail("No existen los buses centralizados UI/SFX")
		return false
	if not is_equal_approx(AudioServer.get_bus_volume_db(ui_bus), AudioServer.get_bus_volume_db(sfx_bus)) or AudioServer.is_bus_mute(ui_bus) != AudioServer.is_bus_mute(sfx_bus):
		_fail("Los clics no reutilizan volumen y silencio de Efectos")
		return false
	return true


func _validate_new_game_intro(main: Control, transitions: Node) -> bool:
	var new_game := _find_button_with_text(main, "Nueva partida")
	var continue_game := _find_button_with_text(main, "Continuar")
	if new_game == null or not _button_has_callback(new_game, "_begin_new_game"):
		_fail("Nueva partida no está enlazada a la introducción de 2026")
		return false
	if continue_game != null and _button_has_callback(continue_game, "_begin_new_game"):
		_fail("Continuar reproduce incorrectamente la introducción de nueva partida")
		return false
	intro_callback_called = false
	transitions.call("set_fast_mode", false)
	transitions.call("play_new_game_intro", Callable(self, "_on_intro_finished"))
	var waited := 0
	while not bool(transitions.get("waiting_for_continue")) and waited < 180:
		await process_frame
		waited += 1
	var name_label: Variant = transitions.get("name_label")
	var message_label: Variant = transitions.get("message_label")
	if intro_callback_called or not bool(transitions.get("waiting_for_continue")):
		_fail("La introducción de nueva partida avanza sin interacción")
		return false
	if name_label == null or message_label == null or name_label.visible or not str(name_label.text).is_empty() or str(message_label.text) != "Los hechos acontecieron desde 2026.":
		_fail("La introducción repite 2026 o no conserva la frase requerida")
		return false
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	transitions.call("_on_transition_input", click)
	waited = 0
	while not intro_callback_called and waited < 180:
		await process_frame
		waited += 1
	if not intro_callback_called:
		_fail("Un clic no permite continuar la introducción")
		return false
	waited = 0
	while bool(transitions.get("transition_active")) and waited < 180:
		await process_frame
		waited += 1
	if bool(transitions.get("transition_active")):
		_fail("La capa negra no termina de cerrarse después del clic")
		return false
	return true


func _on_intro_finished() -> void:
	intro_callback_called = true


func _validate_touch_transition(viewport: Viewport, transitions: Node) -> bool:
	# Se entrega un InputEventScreenTouch real al mismo handler conectado a
	# `gui_input`. Evitamos inyectarlo al DisplayServer headless de Windows, que
	# puede provocar una excepción nativa de Godot 4.7.1 al cerrar el proceso.
	transitions.set("continue_requested", false)
	transitions.set("waiting_for_continue", true)
	var touch := InputEventScreenTouch.new()
	touch.index = 0
	touch.position = viewport.get_visible_rect().size * 0.5
	touch.pressed = true
	transitions.call("_on_transition_input", touch)
	var accepted := bool(transitions.get("continue_requested"))
	transitions.set("waiting_for_continue", false)
	transitions.set("continue_requested", false)
	if not accepted:
		_fail("Un toque real no solicita cerrar la transición negra")
		return false
	return true


func _click_button(viewport: Viewport, button: Button) -> bool:
	if button == null:
		_fail("El control que se intenta pulsar no existe")
		return false
	if not button.is_visible_in_tree() or button.disabled:
		_fail("El control que se intenta pulsar no está disponible: %s visible=%s disabled=%s rect=%s" % [button.get_path(), button.is_visible_in_tree(), button.disabled, button.get_global_rect()])
		return false
	var rect := button.get_global_rect()
	if rect.size.x <= 1.0 or rect.size.y <= 1.0:
		_fail("El control interactivo no tiene un rectángulo válido")
		return false
	var point := rect.get_center()
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = point
		event.global_position = point
		event.pressed = pressed
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		viewport.push_input(event, true)
		await process_frame
	return true


func _find_button_with_text(node: Node, expected: String) -> Button:
	if node is Button and (node as Button).text.contains(expected):
		return node as Button
	for child in node.get_children():
		var found := _find_button_with_text(child, expected)
		if found != null:
			return found
	return null


func _button_has_callback(button: Button, method_name: String) -> bool:
	for connection in button.pressed.get_connections():
		var callable: Callable = connection.get("callable", Callable())
		if callable.is_valid() and str(callable.get_method()) == method_name:
			return true
	return false


func _validate_map_ui(main: Control, world_map: Node, transitions: Node, state: Dictionary) -> bool:
	var menu_screen: Control = main.get("menu_screen") as Control
	var game_screen: Control = main.get("game_screen") as Control
	var ending_screen: Control = main.get("ending_screen") as Control
	if menu_screen != null:
		menu_screen.visible = false
	if ending_screen != null:
		ending_screen.visible = false
	if game_screen != null:
		game_screen.visible = true
	world_map.call("open_selector", state)
	for _i in range(5):
		await process_frame
	var texture := main.find_child("WorldMapTexture", true, false) as TextureRect
	if texture == null or texture.texture == null or texture.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
		_fail("El mapa no conserva proporción en su renderer")
		return false
	if main.find_child("MapCharacter_javi", true, false) != null or main.find_child("MapCharacter_sue", true, false) == null:
		_fail("El mapa no respeta al protagonista o al resto de residentes")
		return false
	var sue_marker := main.find_child("MapCharacter_sue", true, false) as Button
	if sue_marker == null or not bool(sue_marker.get_meta("visited", false)):
		_fail("El marcador no conserva el estado visitado")
		return false
	var left := main.find_child("WorldConnection_triana", true, false) as Button
	var right := main.find_child("WorldConnection_monte_del_toro", true, false) as Button
	if left == null or right == null or left.anchor_left != 0.0 or right.anchor_left != 1.0:
		_fail("Triana no está a la izquierda o Monte del Toro a la derecha")
		return false
	if main.find_child("MapShopMarker", true, false) == null:
		_fail("La tienda no aparece como localización del mapa")
		return false

	# Hit-test real: una capa transparente posterior no debe interceptar los
	# controles del mapa situados detrás.
	var shop_marker := main.find_child("MapShopMarker", true, false) as Button
	if not await _click_button(main.get_viewport(), shop_marker):
		return false
	if main.find_child("WorldShopPanel", true, false) == null:
		_fail("Un clic real sobre la tienda no abre su localización")
		return false
	world_map.call("show_zone", "naranjal_del_rio", false)
	for _i in range(3):
		await process_frame
	left = main.find_child("WorldConnection_triana", true, false) as Button
	transitions.call("set_fast_mode", true)
	if not await _click_button(main.get_viewport(), left):
		return false
	for _i in range(12):
		await process_frame
	var navigated_state: Dictionary = main.get("state")
	if str(navigated_state.get("current_zone_id", "")) != "triana" or str(world_map.get("current_zone_id")) != "triana":
		_fail("Un clic real sobre la conexión no navega a Triana")
		return false
	if main.find_child("MapCharacter_ana", true, false) == null or main.find_child("MapCharacter_jony", true, false) == null:
		_fail("La pantalla temporal de Triana no permite visitar a Ana y Jony")
		return false
	var triana_return := main.find_child("WorldConnection_naranjal_del_rio", true, false) as Button
	var temporary_panel := main.find_child("TemporaryZonePanel", true, false) as PanelContainer
	var header_back := main.find_child("WorldMapBackButton", true, false) as Button
	if triana_return == null or temporary_panel == null or header_back == null or header_back.visible or triana_return.text.contains("\n") or not _button_at_panel_bottom_right(temporary_panel, triana_return):
		_fail("El regreso desde Triana no está abajo a la derecha o sigue duplicado en la cabecera")
		return false
	world_map.call("show_zone", "monte_del_toro", false)
	for _i in range(3):
		await process_frame
	var monte_return := main.find_child("WorldConnection_naranjal_del_rio", true, false) as Button
	if main.find_child("MapCharacter_carmen", true, false) == null or monte_return == null:
		_fail("Monte del Toro no permite visitar a Carmen y volver a Naranjal")
		return false
	temporary_panel = main.find_child("TemporaryZonePanel", true, false) as PanelContainer
	if temporary_panel == null or header_back.visible or monte_return.text.contains("\n") or not _button_at_panel_bottom_right(temporary_panel, monte_return):
		_fail("El regreso desde Monte del Toro no está abajo a la derecha o sigue duplicado en la cabecera")
		return false
	var first_excuse := str(transitions.call("_pick_missing_map_excuse"))
	var second_excuse := str(transitions.call("_pick_missing_map_excuse"))
	var excuses: Array = data_manager.call("get_missing_map_excuses")
	if first_excuse == second_excuse or not excuses.has(first_excuse) or not excuses.has(second_excuse):
		_fail("Las excusas no son data-driven o se repiten inmediatamente")
		return false
	if not _validate_touch_transition(main.get_viewport(), transitions):
		return false
	if not await _click_button(main.get_viewport(), monte_return):
		return false
	for _i in range(12):
		await process_frame
	if str(world_map.get("current_zone_id")) != "naranjal_del_rio" or not header_back.visible:
		_fail("El botón inferior no vuelve a Naranjal o no restaura su acceso al menú")
		return false
	return true


func _button_inside_viewport(viewport: Viewport, button: Button) -> bool:
	var viewport_rect := Rect2(Vector2.ZERO, viewport.get_visible_rect().size)
	var button_rect := button.get_global_rect()
	return viewport_rect.encloses(button_rect) and button_rect.size.x > 1.0 and button_rect.size.y > 1.0


func _button_at_panel_bottom_right(panel: Control, button: Button) -> bool:
	var panel_rect := panel.get_global_rect()
	var button_rect := button.get_global_rect()
	return panel_rect.encloses(button_rect) and button_rect.get_center().y > panel_rect.get_center().y and panel_rect.end.x - button_rect.end.x <= 40.0 and panel_rect.end.y - button_rect.end.y <= 40.0


func _validate_extras(main: Control, extras: Node) -> bool:
	for method_name in ["_show_achievements", "_show_statistics", "_show_collection"]:
		if not extras.has_method(method_name):
			_fail("Extras no expone la página " + method_name)
			return false
	var settings_screen := main.find_child("SettingsScreen060", true, false) as Control
	var settings_button := main.find_child("SettingsButton060", true, false) as Button
	var click_grid := main.find_child("ClickSoundGrid060", true, false) as GridContainer
	if settings_screen == null or settings_button == null or click_grid == null or click_grid.get_child_count() != 6:
		_fail("Ajustes no ofrece el selector táctil de sonidos de clic")
		return false
	extras.call("_show_achievements")
	for _i in range(2):
		await process_frame
	if main.find_child("AchievementCard_first_visit", true, false) == null:
		_fail("La pantalla de Logros no renderiza logros obtenidos/pendientes")
		return false
	extras.call("_show_statistics")
	for _i in range(2):
		await process_frame
	var page_host: Variant = extras.get("page_host")
	if page_host == null or not _tree_contains_text(page_host as Node, "Tiempo total jugado"):
		_fail("La pantalla de Estadísticas no muestra el perfil acumulado")
		return false
	extras.call("_show_collection")
	for _i in range(2):
		await process_frame
	if page_host == null or not _tree_contains_text(page_host as Node, "Retratos del grupo"):
		_fail("La Colección no consulta los desbloqueos globales")
		return false
	var illustrated_preview := main.find_child("CollectionPreview_illustration_group_illustrated", true, false) as Button
	var pixel_preview := main.find_child("CollectionPreview_illustration_group_pixel", true, false) as Button
	var illustrated_image := main.find_child("CollectionImage_illustration_group_illustrated", true, false) as TextureRect
	var pixel_image := main.find_child("CollectionImage_illustration_group_pixel", true, false) as TextureRect
	if illustrated_preview == null or pixel_preview == null or illustrated_image == null or pixel_image == null or illustrated_image.texture == null or pixel_image.texture == null:
		_fail("La compra no muestra los dos diseños del grupo en Colección")
		return false
	if illustrated_image.texture_filter != CanvasItem.TEXTURE_FILTER_LINEAR or pixel_image.texture_filter != CanvasItem.TEXTURE_FILTER_NEAREST:
		_fail("El pixel art no conserva píxeles nítidos o la ilustración pierde su filtrado suave")
		return false
	if main.find_child("CollectionLockedPreview_memory_naranjal_room", true, false) == null:
		_fail("Un coleccionable pendiente revela su imagen antes de comprarlo")
		return false
	illustrated_preview.emit_signal("pressed")
	await process_frame
	var fullscreen_preview := main.find_child("CollectionFullscreenPreview060", true, false) as Control
	var fullscreen_image := main.find_child("CollectionFullscreenImage060", true, false) as TextureRect
	if fullscreen_preview == null or not fullscreen_preview.visible or fullscreen_image == null or fullscreen_image.texture != illustrated_image.texture:
		_fail("El diseño ilustrado del grupo no se puede abrir en una vista grande")
		return false
	extras.call("_close_collection_preview")
	pixel_preview.emit_signal("pressed")
	await process_frame
	if not fullscreen_preview.visible or fullscreen_image.texture != pixel_image.texture or fullscreen_image.texture == illustrated_image.texture:
		_fail("El diseño pixel art no se abre como segundo arte independiente")
		return false
	extras.call("_close_collection_preview")
	extras.call("_show_character", "ana")
	for _i in range(5):
		await process_frame
	var cosmetics_tab := main.find_child("CharacterCosmeticsTab060", true, false) as Button
	if cosmetics_tab == null:
		_fail("La ficha de Ana no conserva la pestaña de Cosméticos")
		return false
	cosmetics_tab.emit_signal("pressed")
	await process_frame
	var skin_card := main.find_child("CharacterCosmetic_ana_skin_crimson_night", true, false)
	if skin_card == null or not _tree_contains_text(skin_card, "DESBLOQUEADO GLOBALMENTE"):
		_fail("La ficha de Ana no refleja la skin comprada en el perfil global")
		return false
	extras.call("_show_character", "sue")
	for _i in range(5):
		await process_frame
	cosmetics_tab = main.find_child("CharacterCosmeticsTab060", true, false) as Button
	if cosmetics_tab == null:
		_fail("Una ficha sin cosméticos pierde la pestaña informativa")
		return false
	cosmetics_tab.emit_signal("pressed")
	await process_frame
	var cosmetic_content := main.find_child("CharacterCosmeticsTabContent060", true, false)
	if cosmetic_content == null or not _tree_contains_text(cosmetic_content, "todavía no tiene cosméticos"):
		_fail("La ficha sin compras no informa de skins y mascotas futuras")
		return false
	return true


func _tree_contains_text(node: Node, expected: String) -> bool:
	if node is Label and (node as Label).text.contains(expected):
		return true
	if node is Button and (node as Button).text.contains(expected):
		return true
	for child in node.get_children():
		if _tree_contains_text(child, expected):
			return true
	return false


func _fail(message: String) -> void:
	push_error("V060 FAIL: " + message)
	quit(1)
