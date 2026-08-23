extends SceneTree

const VISIT_NODE := "__VISIT_SELECT__"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var dm := root.get_node_or_null("DataManager")
	if dm == null:
		_fail("DataManager no está disponible")
		return
	dm.call("reload_all")
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(22):
		await process_frame

	var manager := main.get_node_or_null("Version040Manager")
	var hud_patch := main.get_node_or_null("Version043HudPatch")
	var world_map := main.get_node_or_null("WorldMapManager")
	if manager == null or hud_patch == null or world_map == null:
		_fail("No están disponibles los gestores de visitas, HUD y mapa")
		return

	var active: Array = dm.call("get_all_character_ids", true) if dm.has_method("get_all_character_ids") else dm.call("get_character_ids", true)
	if dm.has_method("set_runtime_active_characters"):
		dm.call("set_runtime_active_characters", active)
	if dm.has_method("set_runtime_narrative_day"):
		dm.call("set_runtime_narrative_day", 1)
	var state: Dictionary = dm.call("migrate_save_state", {
		"node_id": VISIT_NODE,
		"player": {"id": "custom", "name": "Invitado", "display_name": "Invitado", "guest": true},
		"active_characters": active,
		"affinity": {},
		"expressions": {},
		"history": [],
		"visit_mode": true,
		"completed_characters": [],
		"visit_order": [],
		"current_zone_id": "naranjal_del_rio"
	})
	main.set("state", state)
	manager.call("_open_selector", state)
	for _i in range(5):
		await process_frame
	if not bool(world_map.call("is_open")):
		_fail("El mapa no sustituye al selector histórico de visitas")
		return
	for character_id in ["javi", "sue", "smokey", "argentino", "charlie"]:
		if main.find_child("MapCharacter_" + character_id, true, false) == null:
			_fail("Naranjal no contiene el marcador de " + character_id)
			return
	if main.find_child("MapShopMarker", true, false) == null:
		_fail("Naranjal no contiene el acceso a la tienda")
		return

	world_map.call("show_zone", "triana", false)
	for _i in range(3):
		await process_frame
	if main.find_child("MapCharacter_ana", true, false) == null or main.find_child("MapCharacter_jony", true, false) == null:
		_fail("Triana no contiene a Ana y Jony")
		return
	world_map.call("show_zone", "monte_del_toro", false)
	for _i in range(3):
		await process_frame
	if main.find_child("MapCharacter_carmen", true, false) == null:
		_fail("Monte del Toro no contiene a Carmen")
		return

	var views: Dictionary = main.get("character_views")
	var charlie_view := views.get("charlie") as TextureRect
	if charlie_view == null or charlie_view.texture != null:
		_fail("Charlie no conserva su slot sin retrato")
		return
	var carmen_view := views.get("carmen") as TextureRect
	if carmen_view == null or float(carmen_view.get_meta("height_shift", 0.0)) < 50.0:
		_fail("Carmen no conserva su ajuste de altura")
		return

	print("V040 OK: Invitado, mapa, ocho NPC, Charlie sin foto y mecánicas heredadas validados.")
	quit(0)


func _fail(message: String) -> void:
	push_error("V040 FAIL: " + message)
	quit(1)
