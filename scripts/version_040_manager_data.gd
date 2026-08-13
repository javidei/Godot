extends "res://scripts/version_040_manager.gd"

const DataAccess = preload("res://scripts/data_access.gd")
const DataStory = preload("res://scripts/story.gd")
const RuntimeGameData = preload("res://scripts/game_data.gd")


func _dm() -> Variant:
	return DataAccess.dm()


func _patch_story() -> void:
	DataStory.NODES[VISIT_NODE] = {
		"speaker": "Narrador", "text": "Elige a quién quieres visitar.",
		"background": "casa_asturias", "show": [], "focus": "all",
		"chapter": "ELIGE TU SIGUIENTE VISITA"
	}
	if not DataStory.NODES.has("__END__"):
		DataStory.NODES["__END__"] = {}
	for character_id in DataStory.ENCOUNTER_ORDER:
		for feedback_id in DataStory.final_feedback_ids(character_id):
			if DataStory.NODES.has(feedback_id):
				DataStory.NODES[feedback_id]["next"] = VISIT_NODE


func _world_map_manager() -> Node:
	if main == null:
		return null
	return main.get_node_or_null("WorldMapManager")


func _open_selector(state: Dictionary) -> void:
	_ensure_visit_state(state)
	var dm: Variant = _dm()
	if dm != null and dm.has_method("migrate_save_state"):
		var migrated: Variant = dm.call("migrate_save_state", state)
		if typeof(migrated) == TYPE_DICTIONARY:
			state = migrated as Dictionary
	main.set("state", state)
	var world_map := _world_map_manager()
	if world_map != null and world_map.has_method("open_selector"):
		# El overlay histórico queda como latch técnico bajo el mapa (z 210 frente
		# a z 220). El watcher original usa su visibilidad para no reabrir/recrear
		# el selector cada frame; no recibe input ni llega a verse.
		if visit_overlay != null:
			visit_overlay.visible = true
		world_map.call("open_selector", state)
		return
	# Rescate para escenas antiguas o pruebas que instancien el manager sin el
	# nuevo renderer. Sigue permitiendo visitas y no elimina las completadas.
	super(state)


func _hide_selector() -> void:
	if visit_overlay != null:
		visit_overlay.visible = false
	var world_map := _world_map_manager()
	if world_map != null and world_map.has_method("close_selector"):
		world_map.call("close_selector")


func _available_visits(state: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var player_id := _player_id(state)
	for character_id in DataStory.ENCOUNTER_ORDER:
		# Las visitas completadas continúan accesibles. El estado se representa en
		# el mapa y las recompensas únicas evitan que una revisita genere monedas
		# infinitas.
		if character_id != player_id:
			result.append(character_id)
	return result


func _mark_completed(previous_node: String, state: Dictionary) -> void:
	if not DataStory.is_final_feedback_node(previous_node):
		return
	var character_id := DataStory.character_for_node(previous_node)
	if character_id.is_empty():
		return
	_ensure_visit_state(state)
	var completed: Array = state["completed_characters"]
	if not completed.has(character_id):
		completed.append(character_id)
	state["completed_characters"] = completed
	main.set("state", state)
	main.call("_save_game", false)


func _background_for_character(character_id: String) -> String:
	var dm: Variant = _dm()
	var background_id := str(dm.call("get_character_background_id", character_id)) if dm != null else ""
	return "casa_asturias" if background_id.is_empty() else background_id


func _refresh_chapter(node_id: String, state: Dictionary) -> void:
	var label := main.get("chapter_label") as Label
	var character_id := DataStory.character_for_node(node_id)
	if label == null or character_id.is_empty():
		return
	var order: Array = state.get("visit_order", [])
	var index := order.find(character_id)
	if index < 0:
		index = int(state.get("completed_characters", []).size())
	var total := DataStory.encounter_order_for_player(_player_id(state)).size()
	var data: Dictionary = RuntimeGameData.CHARACTERS.get(character_id, {})
	var text := "ENCUENTRO %d/%d · %s" % [index + 1, total, str(data.get("alias", character_id)).to_upper()]
	var current: Dictionary = main.get("current_node")
	if current.has("question_number"):
		var count := maxi(1, DataStory.question_count(character_id))
		text += " · PREGUNTA %d/%d" % [int(current["question_number"]), count]
	label.text = text


func _build_room_audio() -> void:
	var game := main.get("game_screen") as Control
	if game == null:
		return
	room_panel = PanelContainer.new()
	room_panel.name = "RoomMusicControls040"
	room_panel.z_index = 48
	room_panel.visible = false
	room_panel.add_theme_stylebox_override("panel", main.call("_panel_style", Color(0.04, 0.028, 0.024, 0.92), Color(0.76, 0.57, 0.32, 0.72), 1, 10))
	game.add_child(room_panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 5)
	room_panel.add_child(row)

	room_music_icon = TextureRect.new()
	room_music_icon.name = "RoomMusicIcon"
	room_music_icon.custom_minimum_size = Vector2(24, 24)
	room_music_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	room_music_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	room_music_icon.texture = load(MUSIC_ICON_PATH) as Texture2D
	room_music_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(room_music_icon)

	room_label = Label.new()
	room_label.name = "RoomMusicPercent"
	room_label.text = "100%"
	room_label.custom_minimum_size = Vector2(58, 38)
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(room_label)

	var dm: Variant = _dm()
	var audio_defaults: Dictionary = dm.call("get_audio_defaults") if dm != null else {}
	var step := clampf(float(audio_defaults.get("track_step", 0.05)), 0.01, 1.0)
	for data in [["-", -step], ["+", step]]:
		var button := main.call("_make_small_button", data[0]) as Button
		button.custom_minimum_size = Vector2(40, 38)
		button.pressed.connect(_adjust_track.bind(float(data[1])))
		row.add_child(button)

	room_mute = main.call("_make_small_button", "Mute") as Button
	room_mute.custom_minimum_size = Vector2(54, 38)
	room_mute.pressed.connect(_toggle_track_mute)
	row.add_child(room_mute)


func _adjust_track(delta: float) -> void:
	if current_track.is_empty():
		return
	var dm: Variant = _dm()
	if dm == null:
		return
	var state: Dictionary = main.get("state")
	var character_id := DataStory.character_for_node(str(state.get("node_id", "")))
	var default_volume := float(dm.call("get_music_default_volume", current_track, character_id))
	var value := float(track_volumes.get(current_track, default_volume))
	var audio_defaults: Dictionary = dm.call("get_audio_defaults")
	var step := clampf(float(audio_defaults.get("track_step", 0.05)), 0.01, 1.0)
	track_volumes[current_track] = clampf(snappedf(value + delta, step), 0.0, 1.0)
	_save_track_settings()
	last_audio_signature = ""


func _apply_room_audio() -> void:
	if audio_manager == null:
		return
	current_track = str(audio_manager.get("current_music_id"))
	var state: Dictionary = main.get("state")
	var node_id := str(state.get("node_id", "")) if not state.is_empty() else ""
	var character_id := DataStory.character_for_node(node_id)
	var game := main.get("game_screen") as Control
	var in_room := not character_id.is_empty()
	if room_panel != null:
		room_panel.visible = game != null and game.visible and in_room and not current_track.is_empty()
	if current_track.is_empty():
		return
	var dm: Variant = _dm()
	var default_volume := float(dm.call("get_music_default_volume", current_track, character_id)) if dm != null else 1.0
	var track_volume := float(track_volumes.get(current_track, default_volume))
	var track_muted := bool(track_mutes.get(current_track, false))
	var global_volume := float(audio_manager.call("get_music_output_linear"))
	var global_muted := bool(audio_manager.call("is_music_muted"))
	var suspended := bool(audio_manager.call("is_music_suspended"))
	if room_label != null:
		room_label.text = "%d%%" % roundi(track_volume * 100.0)
	if room_mute != null:
		room_mute.text = "On" if track_muted else "Mute"
	var signature := "%s|%s|%.3f|%s|%.3f|%s|%s" % [current_track, character_id, track_volume, str(track_muted), global_volume, str(global_muted), str(suspended)]
	if signature == last_audio_signature:
		return
	var bus := AudioServer.get_bus_index("Music")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(global_volume * track_volume, 0.0001)))
		AudioServer.set_bus_mute(bus, suspended or global_muted or track_muted or track_volume <= 0.0)
	last_audio_signature = signature


func _load_track_settings() -> void:
	track_volumes.clear()
	track_mutes.clear()
	var dm: Variant = _dm()
	var tracks: Dictionary = dm.call("get_track_settings") if dm != null else {}
	for raw_id in tracks.keys():
		var music_id := str(raw_id)
		var raw_entry: Variant = tracks[raw_id]
		if typeof(raw_entry) != TYPE_DICTIONARY:
			continue
		var entry := raw_entry as Dictionary
		if entry.has("volume"):
			track_volumes[music_id] = clampf(float(entry["volume"]), 0.0, 1.0)
		if entry.has("muted"):
			track_mutes[music_id] = bool(entry["muted"])


func _save_track_settings() -> void:
	var dm: Variant = _dm()
	if dm != null:
		dm.call("set_track_settings", track_volumes, track_mutes)
