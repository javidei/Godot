extends SceneTree

const Story = preload("res://scripts/story.gd")
const VISIT_NODE := "__VISIT_SELECT__"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var project_version := str(ProjectSettings.get_setting("application/config/version", ""))
	if not (project_version.begins_with("0.4.") or project_version.begins_with("0.5.") or project_version.begins_with("0.6.")):
		_fail("La versión del proyecto no pertenece a una rama compatible")
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(16):
		await process_frame

	var manager := main.get_node_or_null("Version040Manager")
	var layout_patch := main.get_node_or_null("Version042LayoutPatch")
	var hud_patch := main.get_node_or_null("Version043HudPatch")
	var world_map := main.get_node_or_null("WorldMapManager")
	var selection_manager := main.get_node_or_null("CharacterSelectManager")
	if manager == null or layout_patch == null or hud_patch == null or world_map == null or selection_manager == null:
		_fail("No están disponibles los gestores principales heredados de la rama 0.4.x")
		return
	if main.get_node_or_null("Version046RoomAudioPatch") != null:
		_fail("Sigue activo el parche incorrecto de tres botones de audio en habitaciones")
		return

	selection_manager.call("open_selection")
	await process_frame
	selection_manager.call("_select_existing_character", "javi")
	for _i in range(5):
		await process_frame

	var state: Dictionary = main.get("state")
	var player: Dictionary = state.get("player", {})
	if str(player.get("id", "")) != "javi":
		_fail("La selección de protagonista no conserva a Javi")
		return
	if str(state.get("node_id", "")) != VISIT_NODE:
		_fail("Tras elegir protagonista no se abre el selector libre de visitas")
		return

	if not bool(world_map.call("is_open")):
		_fail("El mapa del mundo no sustituye al selector histórico de visitas")
		return
	var map_screen := main.find_child("WorldMapScreen", true, false) as Control
	var map_texture := main.find_child("WorldMapTexture", true, false) as TextureRect
	if map_screen == null or map_texture == null or map_texture.texture == null:
		_fail("El mapa de Naranjal del Río no está visible tras elegir protagonista")
		return
	var dialogue_panel := main.get("dialogue_panel") as PanelContainer
	var hud_panel := hud_patch.get("hud_panel") as PanelContainer
	if dialogue_panel == null or hud_panel == null:
		_fail("No se pueden comprobar los paneles inferiores del juego")
		return
	if dialogue_panel.visible or hud_panel.visible:
		_fail("El selector de visitas deja visibles los paneles inferiores del juego")
		return

	var original_player: Dictionary = player.duplicate(true)
	state["player"] = {"id": "custom_test", "name": "Custom Test"}
	state["completed_characters"] = []
	main.set("state", state)
	manager.call("_open_selector", state)
	for _i in range(4):
		await process_frame
	for character_id in ["javi", "sue", "smokey", "argentino"]:
		if main.find_child("MapCharacter_" + character_id, true, false) == null:
			_fail("Naranjal no contiene el marcador de " + character_id)
			return
	if main.find_child("MapShopMarker", true, false) == null:
		_fail("Naranjal no contiene el acceso a la tienda")
		return
	world_map.call("show_zone", "triana", false)
	for _i in range(3):
		await process_frame
	for character_id in ["ana", "jony"]:
		if main.find_child("MapCharacter_" + character_id, true, false) == null:
			_fail("Triana no contiene el marcador de " + character_id)
			return
	world_map.call("show_zone", "monte_del_toro", false)
	for _i in range(3):
		await process_frame
	if main.find_child("MapCharacter_carmen", true, false) == null:
		_fail("Monte del Toro no contiene el marcador de Carmen")
		return

	state = main.get("state")
	state["player"] = original_player
	state["completed_characters"] = []
	main.set("state", state)
	manager.call("_open_selector", state)
	for _i in range(4):
		await process_frame

	var views_value: Variant = main.get("character_views")
	if typeof(views_value) != TYPE_DICTIONARY:
		_fail("No se pueden comprobar las vistas de personajes")
		return
	var views: Dictionary = views_value
	var carmen_view := views.get("carmen") as TextureRect
	if carmen_view == null or float(carmen_view.get_meta("height_shift", 0.0)) < 50.0:
		_fail("Carmen no está desplazada hacia abajo para reflejar su menor altura")
		return

	manager.call("_select_visit", "ana")
	for _i in range(6):
		await process_frame
	state = main.get("state")
	if str(state.get("node_id", "")) != "ana_intro_01":
		_fail("Elegir a Ana no abre su habitación")
		return
	if not dialogue_panel.visible or not hud_panel.visible:
		_fail("Los paneles inferiores no reaparecen al cerrar el selector de visitas")
		return

	var room_panel := manager.get("room_panel") as PanelContainer
	var room_music_icon := manager.get("room_music_icon") as TextureRect
	var room_label := manager.get("room_label") as Label
	var room_mute := manager.get("room_mute") as Button
	var hud_box := hud_patch.get("hud_box") as VBoxContainer
	if room_panel == null or room_music_icon == null or room_label == null or room_mute == null or hud_box == null:
		_fail("No está disponible el control de volumen de música de la habitación")
		return
	if room_panel.get_parent() != hud_box or not room_panel.visible:
		_fail("El volumen de la habitación no está abajo a la derecha dentro del HUD")
		return
	if room_music_icon.texture == null or not room_label.text.ends_with("%"):
		_fail("El control de música no muestra icono y porcentaje")
		return
	var row := room_panel.get_child(0) as HBoxContainer
	if row == null:
		_fail("El regulador de música no tiene su fila de controles")
		return
	var button_count := 0
	for child in row.get_children():
		if child is Button:
			button_count += 1
	if button_count != 3:
		_fail("El volumen local debe conservar bajar, subir y mute, sin añadir más controles")
		return

	main.call("_go_to", "ana_q3_correct", false)
	await process_frame
	main.call("_go_to", VISIT_NODE, false)
	for _i in range(4):
		await process_frame
	state = main.get("state")
	if not state.get("completed_characters", []).has("ana"):
		_fail("Ana no se marca como visita completada")
		return

	print("V040 OK: mecánicas heredadas, visitas por mapa, Carmen y volumen de habitación validados.")
	quit(0)


func _fail(message: String) -> void:
	push_error("V040 FAIL: " + message)
	quit(1)
