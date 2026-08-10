extends Node

const Story = preload("res://scripts/story.gd")
const GameData = preload("res://scripts/game_data.gd")

const VISIT_NODE := "__VISIT_SELECT__"
const RELEASE_VERSION := "0.4.0"
const TRACK_SETTINGS_PATH := "user://music_track_settings.cfg"
const TRACK_STEP := 0.05

var main: Control
var audio_manager: Node
var visit_overlay: Control
var visit_panel: PanelContainer
var visit_title: Label
var visit_status: Label
var visit_grid: GridContainer
var room_panel: PanelContainer
var room_label: Label
var room_mute: Button
var fullscreen_button: Button
var music_label: Label
var effects_label: Label
var music_mute: Button
var effects_mute: Button
var track_volumes: Dictionary = {}
var track_mutes: Dictionary = {}
var current_track := ""
var last_node := ""
var last_audio_signature := ""


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	main = get_parent() as Control
	if main == null:
		return
	audio_manager = main.get("audio_manager") as Node
	_patch_story()
	_load_track_settings()
	_build_visit_overlay()
	_compact_menu_audio()
	_build_room_audio()
	fullscreen_button = main.get("fullscreen_button") as Button
	get_viewport().size_changed.connect(_queue_layout)
	_apply_layout()


func _process(_delta: float) -> void:
	if main == null:
		return
	_keep_compact_ui()
	_watch_state()
	_apply_room_audio()


func _patch_story() -> void:
	Story.NODES[VISIT_NODE] = {
		"speaker": "Narrador", "text": "Elige a quién quieres visitar.",
		"background": "casa_asturias", "show": [], "focus": "all",
		"chapter": "ELIGE TU SIGUIENTE VISITA"
	}
	if not Story.NODES.has("__END__"):
		Story.NODES["__END__"] = {}
	for character_id in Story.ENCOUNTER_ORDER:
		for result in ["correct", "wrong"]:
			var feedback_id := "%s_q3_%s" % [character_id, result]
			if Story.NODES.has(feedback_id):
				Story.NODES[feedback_id]["next"] = VISIT_NODE


func _watch_state() -> void:
	var value: Variant = main.get("state")
	if typeof(value) != TYPE_DICTIONARY:
		return
	var state: Dictionary = value
	if state.is_empty():
		last_node = ""
		return
	var node_id := str(state.get("node_id", ""))
	if not state.has("visit_mode"):
		if _is_new_game(state, node_id):
			_init_visit_state(state)
			main.call("_go_to", VISIT_NODE, false)
			last_node = VISIT_NODE
			return
		_migrate_legacy_state(state)
		node_id = str(state.get("node_id", node_id))

	var game_screen := main.get("game_screen") as Control
	if game_screen == null or not game_screen.visible:
		_hide_selector()
		last_node = node_id
		return

	if node_id != last_node:
		if node_id == VISIT_NODE:
			_mark_completed(last_node, state)
			_open_selector(state)
		else:
			_hide_selector()
			_refresh_chapter(node_id, state)
		last_node = node_id
	elif node_id == VISIT_NODE and visit_overlay != null and not visit_overlay.visible:
		_open_selector(state)


func _is_new_game(state: Dictionary, node_id: String) -> bool:
	var history: Array = state.get("history", [])
	if history.size() > 1:
		return false
	return node_id == Story.start_for_player(_player_id(state))


func _init_visit_state(state: Dictionary) -> void:
	state["completed_characters"] = []
	state["visit_order"] = []
	state["visit_mode"] = true
	state["save_version"] = RELEASE_VERSION
	main.set("state", state)


func _migrate_legacy_state(state: Dictionary) -> void:
	var node_id := str(state.get("node_id", ""))
	var legacy_order: Array[String] = Story.encounter_order_for_player(_player_id(state))
	var completed: Array = []
	var visit_order: Array = []
	var current := Story.character_for_node(node_id)
	if node_id == "__END__":
		completed = legacy_order.duplicate()
		visit_order = legacy_order.duplicate()
	elif not current.is_empty():
		for character_id in legacy_order:
			if character_id == current:
				break
			completed.append(character_id)
			visit_order.append(character_id)
		visit_order.append(current)
	state["completed_characters"] = completed
	state["visit_order"] = visit_order
	state["visit_mode"] = true
	state["save_version"] = RELEASE_VERSION
	main.set("state", state)
	main.call("_save_game", false)


func _ensure_visit_state(state: Dictionary) -> void:
	if typeof(state.get("completed_characters", [])) != TYPE_ARRAY:
		state["completed_characters"] = []
	if typeof(state.get("visit_order", [])) != TYPE_ARRAY:
		state["visit_order"] = []
	state["visit_mode"] = true
	state["save_version"] = RELEASE_VERSION


func _mark_completed(previous_node: String, state: Dictionary) -> void:
	if not (previous_node.ends_with("_q3_correct") or previous_node.ends_with("_q3_wrong")):
		return
	var character_id := Story.character_for_node(previous_node)
	if character_id.is_empty():
		return
	_ensure_visit_state(state)
	var completed: Array = state["completed_characters"]
	if not completed.has(character_id):
		completed.append(character_id)
	state["completed_characters"] = completed
	main.set("state", state)
	main.call("_save_game", false)


func _build_visit_overlay() -> void:
	visit_overlay = Control.new()
	visit_overlay.name = "VisitSelector040"
	visit_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	visit_overlay.z_index = 210
	visit_overlay.visible = false
	main.add_child(visit_overlay)
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.025, 0.016, 0.014, 0.86)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	visit_overlay.add_child(shade)
	visit_panel = PanelContainer.new()
	visit_panel.add_theme_stylebox_override("panel", main.call("_panel_style", Color(0.045, 0.03, 0.025, 0.97), Color("d6a85f"), 2, 18))
	visit_overlay.add_child(visit_panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 26)
	visit_panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)
	visit_title = Label.new()
	visit_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	visit_title.add_theme_color_override("font_color", Color("f2c97e"))
	visit_title.add_theme_font_size_override("font_size", 28)
	box.add_child(visit_title)
	visit_status = Label.new()
	visit_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	visit_status.add_theme_color_override("font_color", Color("dbcab3"))
	visit_status.add_theme_font_size_override("font_size", 14)
	box.add_child(visit_status)
	visit_grid = GridContainer.new()
	visit_grid.columns = 3
	visit_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	visit_grid.add_theme_constant_override("h_separation", 12)
	visit_grid.add_theme_constant_override("v_separation", 12)
	box.add_child(visit_grid)
	var menu_button := main.call("_make_button", "No visitar a nadie · volver al menú", false) as Button
	menu_button.pressed.connect(_leave_to_menu)
	box.add_child(menu_button)


func _open_selector(state: Dictionary) -> void:
	_ensure_visit_state(state)
	var available := _available_visits(state)
	if available.is_empty():
		_hide_selector()
		main.call("_finish_demo")
		return
	var completed: Array = state["completed_characters"]
	var total := Story.encounter_order_for_player(_player_id(state)).size()
	visit_title.text = "¿A quién quieres visitar primero?" if completed.is_empty() else "¿A quién quieres visitar ahora?"
	visit_status.text = "%d/%d visitas completadas · el orden lo eliges tú" % [completed.size(), total]
	for child in visit_grid.get_children():
		child.queue_free()
	for character_id in available:
		var data: Dictionary = GameData.CHARACTERS.get(character_id, {})
		var display_name := str(data.get("alias", data.get("name", character_id.capitalize())))
		var button := main.call("_make_button", "Visitar a " + display_name, true) as Button
		button.custom_minimum_size = Vector2(180, 70)
		button.pressed.connect(_select_visit.bind(character_id))
		visit_grid.add_child(button)
	visit_overlay.visible = true
	_apply_layout()


func _available_visits(state: Dictionary) -> Array[String]:
	var result: Array[String] = []
	var completed: Array = state.get("completed_characters", [])
	var player_id := _player_id(state)
	for character_id in Story.ENCOUNTER_ORDER:
		if character_id != player_id and not completed.has(character_id):
			result.append(character_id)
	return result


func _select_visit(character_id: String) -> void:
	var state: Dictionary = main.get("state")
	_ensure_visit_state(state)
	var order: Array = state["visit_order"]
	if not order.has(character_id):
		order.append(character_id)
	state["visit_order"] = order
	main.set("state", state)
	main.call("_save_game", false)
	_hide_selector()
	main.call("_go_to", character_id + "_intro_01", false)


func _leave_to_menu() -> void:
	main.call("_save_game", false)
	_hide_selector()
	main.call("_show_menu")


func _hide_selector() -> void:
	if visit_overlay != null:
		visit_overlay.visible = false


func _player_id(state: Dictionary) -> String:
	var player: Dictionary = state.get("player", {})
	return str(player.get("id", ""))


func _refresh_chapter(node_id: String, state: Dictionary) -> void:
	var label := main.get("chapter_label") as Label
	var character_id := Story.character_for_node(node_id)
	if label == null or character_id.is_empty():
		return
	var order: Array = state.get("visit_order", [])
	var index := order.find(character_id)
	if index < 0:
		index = int(state.get("completed_characters", []).size())
	var total := Story.encounter_order_for_player(_player_id(state)).size()
	var data: Dictionary = GameData.CHARACTERS.get(character_id, {})
	var text := "ENCUENTRO %d/%d · %s" % [index + 1, total, str(data.get("alias", character_id)).to_upper()]
	var current: Dictionary = main.get("current_node")
	if current.has("question_number"):
		text += " · PREGUNTA %d/3" % int(current["question_number"])
	label.text = text


func _compact_menu_audio() -> void:
	var menu := main.get("menu_content") as VBoxContainer
	var music_row := main.find_child("MusicControls", true, false) as HBoxContainer
	var effects_row := main.find_child("EffectsControls", true, false) as HBoxContainer
	if menu == null or music_row == null or effects_row == null:
		return
	var row := HBoxContainer.new()
	row.name = "AudioCombinedControls040"
	row.add_theme_constant_override("separation", 5)
	menu.add_child(row)
	menu.move_child(row, music_row.get_index())
	for child in music_row.get_children():
		child.reparent(row)
	var divider := Label.new()
	divider.text = "|"
	divider.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(divider)
	for child in effects_row.get_children():
		child.reparent(row)
	music_row.visible = false
	effects_row.visible = false
	music_label = main.get("music_volume_label") as Label
	effects_label = main.get("effects_volume_label") as Label
	music_mute = main.get("music_mute_button") as Button
	effects_mute = main.get("effects_mute_button") as Button
	for label in [music_label, effects_label]:
		if label != null:
			label.custom_minimum_size = Vector2(78, 40)
	for button in [music_mute, effects_mute]:
		if button != null:
			button.custom_minimum_size = Vector2(50, 40)
			button.add_theme_font_size_override("font_size", 11)


func _keep_compact_ui() -> void:
	if audio_manager != null:
		if music_label != null:
			music_label.text = "♫ %d%%" % int(audio_manager.call("get_music_volume_percent"))
		if effects_label != null:
			effects_label.text = "FX %d%%" % int(audio_manager.call("get_effects_volume_percent"))
		if music_mute != null:
			music_mute.text = "On" if bool(audio_manager.call("is_music_muted")) else "Mute"
		if effects_mute != null:
			effects_mute.text = "On" if bool(audio_manager.call("is_effects_muted")) else "Mute"
	if fullscreen_button != null:
		fullscreen_button.text = "⛶"
		fullscreen_button.tooltip_text = "Pantalla completa / ventana"
		fullscreen_button.custom_minimum_size = Vector2(46, 42)


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
	room_label = Label.new()
	room_label.text = "♫ 100%"
	room_label.custom_minimum_size = Vector2(82, 38)
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(room_label)
	for data in [["−", -TRACK_STEP], ["+", TRACK_STEP]]:
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
	var value := float(track_volumes.get(current_track, 1.0))
	track_volumes[current_track] = clampf(snappedf(value + delta, TRACK_STEP), 0.0, 1.0)
	_save_track_settings()
	last_audio_signature = ""


func _toggle_track_mute() -> void:
	if current_track.is_empty():
		return
	track_mutes[current_track] = not bool(track_mutes.get(current_track, false))
	_save_track_settings()
	last_audio_signature = ""


func _apply_room_audio() -> void:
	if audio_manager == null:
		return
	current_track = str(audio_manager.get("current_music_id"))
	var state: Dictionary = main.get("state")
	var node_id := str(state.get("node_id", "")) if not state.is_empty() else ""
	var game := main.get("game_screen") as Control
	var in_room := not Story.character_for_node(node_id).is_empty()
	if room_panel != null:
		room_panel.visible = game != null and game.visible and in_room and not current_track.is_empty()
	if current_track.is_empty():
		return
	var track_volume := float(track_volumes.get(current_track, 1.0))
	var track_muted := bool(track_mutes.get(current_track, false))
	var global_volume := float(audio_manager.call("get_music_output_linear"))
	var global_muted := bool(audio_manager.call("is_music_muted"))
	if room_label != null:
		room_label.text = "♫ %d%%" % roundi(track_volume * 100.0)
	if room_mute != null:
		room_mute.text = "On" if track_muted else "Mute"
	var signature := "%s|%.3f|%s|%.3f|%s" % [current_track, track_volume, str(track_muted), global_volume, str(global_muted)]
	if signature == last_audio_signature:
		return
	var bus := AudioServer.get_bus_index("Music")
	if bus >= 0:
		AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(global_volume * track_volume, 0.0001)))
		AudioServer.set_bus_mute(bus, global_muted or track_muted or track_volume <= 0.0)
	last_audio_signature = signature


func _load_track_settings() -> void:
	var config := ConfigFile.new()
	if config.load(TRACK_SETTINGS_PATH) != OK:
		return
	for key in config.get_section_keys("volumes"):
		track_volumes[str(key)] = clampf(float(config.get_value("volumes", key, 1.0)), 0.0, 1.0)
	for key in config.get_section_keys("muted"):
		track_mutes[str(key)] = bool(config.get_value("muted", key, false))


func _save_track_settings() -> void:
	var config := ConfigFile.new()
	for key in track_volumes.keys():
		config.set_value("volumes", str(key), float(track_volumes[key]))
	for key in track_mutes.keys():
		config.set_value("muted", str(key), bool(track_mutes[key]))
	config.save(TRACK_SETTINGS_PATH)


func _queue_layout() -> void:
	call_deferred("_apply_layout")


func _apply_layout() -> void:
	var size := get_viewport().get_visible_rect().size
	var portrait := size.y > size.x
	if visit_panel != null:
		visit_panel.anchor_left = 0.055 if portrait else 0.14
		visit_panel.anchor_top = 0.10 if portrait else 0.12
		visit_panel.anchor_right = 0.945 if portrait else 0.86
		visit_panel.anchor_bottom = 0.90 if portrait else 0.88
		visit_panel.offset_left = 0.0
		visit_panel.offset_top = 0.0
		visit_panel.offset_right = 0.0
		visit_panel.offset_bottom = 0.0
	if visit_grid != null:
		visit_grid.columns = 2 if portrait or size.x < 900.0 else 3
	if room_panel != null:
		room_panel.anchor_left = 0.50 if portrait else 0.72
		room_panel.anchor_top = 0.095 if portrait else 0.105
		room_panel.anchor_right = 0.975
		room_panel.anchor_bottom = 0.15 if portrait else 0.165
		room_panel.offset_left = 0.0
		room_panel.offset_top = 0.0
		room_panel.offset_right = 0.0
		room_panel.offset_bottom = 0.0
