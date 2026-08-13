extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return

	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(16):
		await process_frame

	var hud_patch := main.get_node_or_null("Version043HudPatch")
	if hud_patch == null:
		_fail("No está disponible el gestor del HUD inferior")
		return

	var hud_panel := hud_patch.get("hud_panel") as PanelContainer
	var hud_box := hud_patch.get("hud_box") as VBoxContainer
	var utility_row := hud_patch.get("utility_row") as HBoxContainer
	var room_panel := hud_patch.get("room_panel") as PanelContainer
	var menu_button := hud_patch.get("menu_button") as Button
	var fullscreen_button := hud_patch.get("fullscreen_button") as Button
	var map_button := hud_patch.get("map_button") as Button
	var save_button := hud_patch.get("save_button") as Button
	var load_button := hud_patch.get("load_button") as Button

	if hud_panel == null or hud_box == null or utility_row == null or room_panel == null:
		_fail("El HUD inferior no se ha construido por completo")
		return
	if room_panel.get_parent() != hud_box:
		_fail("El control de música no está integrado en el panel inferior derecho")
		return
	if main.find_child("HudEffectsRow043", true, false) != null:
		_fail("La fila de efectos sigue apareciendo en el HUD ingame")
		return
	if menu_button == null or fullscreen_button == null or menu_button.get_parent() != utility_row or fullscreen_button.get_parent() != utility_row:
		_fail("Menú y pantalla completa no comparten la fila superior del HUD")
		return
	if map_button == null or map_button.get_parent() != utility_row or map_button.name != "ReturnToMapButton060":
		_fail("El HUD no ofrece el retorno al mapa desde las habitaciones")
		return
	if save_button != null and save_button.visible:
		_fail("Guardar manual sigue visible pese al autoguardado")
		return
	if load_button != null and load_button.visible:
		_fail("Cargar manual sigue visible pese a la carga automática")
		return

	# Los ajustes globales de efectos siguen disponibles en el menú, pero no en la habitación.
	var global_effects_label := main.get("effects_volume_label") as Label
	if global_effects_label == null:
		_fail("Se ha eliminado accidentalmente el ajuste global de efectos del menú")
		return

	# Reproduce un estado de partida válido antes de entrar directamente en una habitación.
	var state := main.call("_fresh_state") as Dictionary
	state["player"] = {"id": "hud_test", "name": "HUD Test"}
	state["visit_mode"] = true
	state["completed_characters"] = []
	state["visit_order"] = []
	state["intro_transitions_seen"] = ["javi"]
	state["outro_transitions_seen"] = []
	main.set("state", state)

	var game_screen := main.get("game_screen") as Control
	if game_screen != null:
		game_screen.visible = true
	main.call("_go_to", "javi_intro_01", false)
	for _i in range(6):
		await process_frame

	if not room_panel.visible:
		_fail("El control de música no aparece dentro de una habitación")
		return
	if not map_button.visible or map_button.text != "Mapa":
		_fail("El retorno al mapa no es visible y reconocible dentro de una habitación")
		return

	var viewport_size := root.get_visible_rect().size
	var hud_rect := hud_panel.get_global_rect()
	if hud_rect.position.x < -1.0 or hud_rect.position.y < -1.0:
		_fail("El panel HUD empieza fuera de la pantalla")
		return
	if hud_rect.end.x > viewport_size.x + 1.0 or hud_rect.end.y > viewport_size.y + 1.0:
		_fail("El panel HUD se corta fuera de los límites de la pantalla")
		return

	print("HUD OK: solo música ingame, utilidades compactas, efectos globales en menú y panel dentro de pantalla.")
	quit(0)


func _fail(message: String) -> void:
	push_error("HUD FAIL: " + message)
	quit(1)
