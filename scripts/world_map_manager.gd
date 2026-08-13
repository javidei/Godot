extends Node

const DataAccess = preload("res://scripts/data_access.gd")
const DataStory = preload("res://scripts/story.gd")

const VISIT_NODE := "__VISIT_SELECT__"
const DEFAULT_ZONE_FALLBACK := "naranjal_del_rio"
const MAP_MARGIN := 14.0
const HEADER_HEIGHT := 66.0
const MAP_BOTTOM_MARGIN := 12.0
const MARKER_DESKTOP_SIZE := Vector2(164, 58)
const MARKER_COMPACT_SIZE := Vector2(122, 48)
const CONNECTION_DESKTOP_SIZE := Vector2(286, 68)
const CONNECTION_COMPACT_SIZE := Vector2(210, 58)
const COIN_ICON_PATH := "res://assets/ui/icons/coin.svg"

var main: Control
var version_manager: Node
var transition_manager: Node
var progress_manager: Node

var overlay: Control
var backdrop: ColorRect
var header_panel: PanelContainer
var header_title: Label
var coins_label: Label
var header_back_button: Button
var header_back_spacer: Control
var content_root: Control

var map_canvas: Control
var map_texture: TextureRect
var marker_layer: Control
var connection_layer: Control
var shop_status: Label

var current_zone_id := ""
var current_zone: Dictionary = {}
var current_mode := "zone"
var map_texture_size := Vector2.ZERO
var last_recorded_entry := ""


func _ready() -> void:
	# Main construye toda su interfaz en tiempo de ejecución. Unos pocos frames
	# permiten reutilizar sus fábricas de botones y estilos sin duplicarlas.
	for _i in range(4):
		await get_tree().process_frame
	_resolve_dependencies()
	_ensure_built()
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _resolve_dependencies() -> void:
	if main == null:
		main = get_parent() as Control
	if main == null:
		return
	version_manager = main.get_node_or_null("Version040Manager")
	transition_manager = main.get_node_or_null("Version044VisitTransitions")
	progress_manager = main.get_node_or_null("ProgressManager")


func open_selector(state: Dictionary) -> void:
	_resolve_dependencies()
	_ensure_built()
	if overlay == null:
		return
	var migrated := _migrate_state(state)
	if not migrated.is_empty():
		state = migrated
	var requested_zone := str(state.get("current_zone_id", ""))
	if requested_zone.is_empty() or _zone(requested_zone).is_empty():
		requested_zone = _default_zone_id()
	state["current_zone_id"] = requested_zone
	_set_state(state, false)
	overlay.visible = true
	_render_zone(requested_zone, true)


func close_selector() -> void:
	if overlay != null:
		overlay.visible = false
	last_recorded_entry = ""


func is_open() -> bool:
	return overlay != null and overlay.visible


func return_to_map_from_room() -> void:
	_resolve_dependencies()
	var state := _state()
	if state.is_empty() or main == null:
		return
	var node_id := str(state.get("node_id", ""))
	if DataStory.character_for_node(node_id).is_empty() or node_id.ends_with("_outro_044"):
		return
	# MainDataDriven guarda el nodo actual como checkpoint en cada avance. Al ir
	# al sentinel técnico no se reemplaza, por lo que cada personaje conserva su
	# propia conversación aunque el jugador visite otra habitación entre medias.
	main.call("_save_game", false)
	main.call("_go_to", VISIT_NODE, false)


func show_zone(zone_id: String, record_visit: bool = true) -> void:
	_ensure_built()
	if overlay == null:
		return
	overlay.visible = true
	_render_zone(zone_id, record_visit)


func _ensure_built() -> void:
	if overlay != null or main == null:
		return
	overlay = Control.new()
	overlay.name = "WorldMapScreen"
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.z_index = 220
	overlay.visible = false
	main.add_child(overlay)

	backdrop = ColorRect.new()
	backdrop.name = "WorldMapBackdrop"
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.018, 0.024, 0.014, 1.0)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.add_child(backdrop)

	content_root = Control.new()
	content_root.name = "WorldMapContent"
	content_root.anchor_left = 0.0
	content_root.anchor_top = 0.0
	content_root.anchor_right = 1.0
	content_root.anchor_bottom = 1.0
	content_root.offset_left = MAP_MARGIN
	content_root.offset_top = HEADER_HEIGHT + MAP_MARGIN * 2.0
	content_root.offset_right = -MAP_MARGIN
	content_root.offset_bottom = -MAP_BOTTOM_MARGIN
	overlay.add_child(content_root)

	_build_header()


func _build_header() -> void:
	header_panel = PanelContainer.new()
	header_panel.name = "WorldMapHeader"
	header_panel.anchor_left = 0.0
	header_panel.anchor_top = 0.0
	header_panel.anchor_right = 1.0
	header_panel.anchor_bottom = 0.0
	header_panel.offset_left = MAP_MARGIN
	header_panel.offset_top = MAP_MARGIN
	header_panel.offset_right = -MAP_MARGIN
	header_panel.offset_bottom = MAP_MARGIN + HEADER_HEIGHT
	header_panel.add_theme_stylebox_override(
		"panel",
		main.call("_panel_style", Color(0.025, 0.035, 0.020, 0.965), Color("d6a85f"), 2, 13)
	)
	overlay.add_child(header_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 7)
	header_panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)

	header_back_button = main.call("_make_small_button", "Menú") as Button
	header_back_button.name = "WorldMapBackButton"
	header_back_button.custom_minimum_size = Vector2(132, 46)
	header_back_button.pressed.connect(_on_header_back)
	row.add_child(header_back_button)

	header_back_spacer = Control.new()
	header_back_spacer.name = "WorldMapBackSpacer"
	header_back_spacer.custom_minimum_size = Vector2(132, 46)
	header_back_spacer.visible = false
	header_back_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(header_back_spacer)

	header_title = Label.new()
	header_title.name = "WorldMapTitle"
	header_title.text = "NARANJAL DEL RÍO"
	header_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_title.add_theme_color_override("font_color", Color("fff0d0"))
	header_title.add_theme_font_size_override("font_size", 25)
	row.add_child(header_title)

	var coin_icon := TextureRect.new()
	coin_icon.name = "WorldMapCoinIcon"
	coin_icon.custom_minimum_size = Vector2(32, 32)
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(COIN_ICON_PATH):
		coin_icon.texture = ResourceLoader.load(COIN_ICON_PATH) as Texture2D
	row.add_child(coin_icon)

	coins_label = Label.new()
	coins_label.name = "WorldMapCoins"
	coins_label.custom_minimum_size = Vector2(170, 46)
	coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	coins_label.add_theme_color_override("font_color", Color("f2c75e"))
	coins_label.add_theme_font_size_override("font_size", 17)
	row.add_child(coins_label)


func _render_zone(zone_id: String, record_visit: bool) -> void:
	var zone := _zone(zone_id)
	if zone.is_empty():
		zone_id = _default_zone_id()
		zone = _zone(zone_id)
	if zone.is_empty():
		_render_data_error("No hay ninguna localidad válida en los datos del mundo.")
		return

	current_mode = "zone"
	current_zone_id = zone_id
	current_zone = zone
	var state := _state()
	state["current_zone_id"] = current_zone_id
	_set_state(state, true)
	_clear_content()
	_refresh_header()

	var map_asset := str(zone.get("map_asset", ""))
	var temporary := bool(zone.get("temporary", false))
	var texture := _load_map_texture(map_asset)
	if not temporary and texture != null:
		_build_map_view(texture, zone)
	else:
		_build_temporary_view(zone)

	_build_connections(zone)
	_queue_layout()
	if record_visit:
		_record_zone_entry(zone)


func _render_data_error(message: String) -> void:
	_clear_content()
	current_mode = "error"
	header_title.text = "MAPA"
	_refresh_coins()
	var label := Label.new()
	label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	label.text = message
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color("f7d7c7"))
	label.add_theme_font_size_override("font_size", 20)
	content_root.add_child(label)


func _clear_content() -> void:
	if content_root == null:
		return
	for child in content_root.get_children():
		content_root.remove_child(child)
		child.queue_free()
	map_canvas = null
	map_texture = null
	marker_layer = null
	connection_layer = null
	shop_status = null
	map_texture_size = Vector2.ZERO


func _build_map_view(texture: Texture2D, zone: Dictionary) -> void:
	map_texture_size = texture.get_size()
	map_canvas = Control.new()
	map_canvas.name = "WorldMapCanvas"
	map_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(map_canvas)

	map_texture = TextureRect.new()
	map_texture.name = "WorldMapTexture"
	map_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	map_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	map_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	map_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_texture.texture = texture
	map_canvas.add_child(map_texture)

	var shade := ColorRect.new()
	shade.name = "WorldMapReadabilityShade"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.06)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_canvas.add_child(shade)

	marker_layer = Control.new()
	marker_layer.name = "WorldMapMarkers"
	marker_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# La capa solo posiciona controles. IGNORE deja que las zonas vacías no
	# intercepten el hit-test; los Button hijos conservan su propio STOP.
	marker_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	map_canvas.add_child(marker_layer)
	_build_markers(zone, marker_layer, false)


func _build_temporary_view(zone: Dictionary) -> void:
	var panel := PanelContainer.new()
	panel.name = "TemporaryZonePanel"
	var compact := _is_compact()
	panel.anchor_left = 0.04 if compact else 0.12
	panel.anchor_top = 0.03 if compact else 0.06
	panel.anchor_right = 0.96 if compact else 0.88
	panel.anchor_bottom = 0.94
	panel.add_theme_stylebox_override(
		"panel",
		main.call("_panel_style", Color(0.025, 0.020, 0.018, 0.97), Color(0.65, 0.48, 0.25, 0.88), 2, 16)
	)
	content_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title := Label.new()
	title.text = str(zone.get("name", current_zone_id)).to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("f2c97e"))
	title.add_theme_font_size_override("font_size", 31)
	box.add_child(title)

	var note := Label.new()
	note.text = str(zone.get("temporary_message", "El mapa definitivo de esta localidad todavía no está disponible."))
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.add_theme_color_override("font_color", Color("d8c8b2"))
	note.add_theme_font_size_override("font_size", 16)
	box.add_child(note)

	var scroll := ScrollContainer.new()
	scroll.name = "TemporaryResidentsScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	var grid := GridContainer.new()
	grid.name = "TemporaryResidentsGrid"
	grid.columns = 2 if not _is_compact() else 1
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(grid)
	_build_markers(zone, grid, true)

	# La conexión de regreso se dibuja sobre el panel, en su esquina inferior.
	# Este espacio evita que tape la última ficha aunque la lista necesite scroll.
	var return_space := Control.new()
	return_space.name = "TemporaryReturnSpace"
	return_space.custom_minimum_size = Vector2(0, 66 if compact else 76)
	return_space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(return_space)


func _build_markers(zone: Dictionary, parent: Control, list_layout: bool) -> void:
	var markers := _marker_list(zone)
	var explicit_characters: Array[String] = []
	var ordinal := 0
	for marker in markers:
		var kind := str(marker.get("type", marker.get("kind", "character" if marker.has("character_id") else "location"))).to_lower()
		var character_id := str(marker.get("character_id", ""))
		if not character_id.is_empty():
			explicit_characters.append(character_id)
		if kind in ["character", "resident", "person"] or not character_id.is_empty():
			if _add_character_marker(parent, marker, ordinal, list_layout):
				ordinal += 1
		elif kind in ["shop", "store", "tienda"] or str(marker.get("id", "")).to_lower() == "shop":
			_add_shop_marker(parent, marker, ordinal, list_layout)
			ordinal += 1
		elif kind in ["connection", "zone", "travel"]:
			_add_marker_connection(parent, marker, ordinal, list_layout)
			ordinal += 1

	# Una zona temporal puede declarar solo `residents`; el renderer genera las
	# entradas sin exigir duplicar cada persona como marcador.
	for resident_id in _resident_ids(zone):
		if explicit_characters.has(resident_id):
			continue
		var generated := {
			"id": "resident_" + resident_id,
			"type": "character",
			"character_id": resident_id,
			"label": _character_name(resident_id)
		}
		if _add_character_marker(parent, generated, ordinal, list_layout):
			ordinal += 1


func _add_character_marker(parent: Control, marker: Dictionary, ordinal: int, list_layout: bool) -> bool:
	var character_id := str(marker.get("character_id", marker.get("id", "")))
	if character_id.is_empty() or character_id == _player_id():
		return false
	var completed: Array = _state().get("completed_characters", [])
	var visited := completed.has(character_id)
	var display_name := str(marker.get("label", marker.get("name", _character_name(character_id))))
	var prefix := "✓ " if visited else "● "
	var button := main.call("_make_button", prefix + "Visitar a " + display_name, false) as Button
	button.name = "MapCharacter_" + character_id
	button.tooltip_text = ("Ya visitado · " if visited else "Pendiente · ") + "Visitar a " + display_name
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.set_meta("character_id", character_id)
	button.set_meta("visited", visited)
	button.pressed.connect(_on_character_pressed.bind(character_id))
	parent.add_child(button)
	_place_marker(button, marker, ordinal, list_layout)
	return true


func _add_shop_marker(parent: Control, marker: Dictionary, ordinal: int, list_layout: bool) -> void:
	var label := str(marker.get("label", marker.get("name", "TIENDA")))
	var button := main.call("_make_button", "◆ " + label.to_upper(), true) as Button
	button.name = "MapShopMarker"
	button.tooltip_text = "Entrar en la tienda"
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.pressed.connect(_open_shop)
	parent.add_child(button)
	_place_marker(button, marker, ordinal, list_layout)


func _add_marker_connection(parent: Control, marker: Dictionary, ordinal: int, list_layout: bool) -> void:
	var target := str(marker.get("to", marker.get("target_zone_id", marker.get("zone_id", ""))))
	if target.is_empty():
		return
	var label := str(marker.get("label", _zone_name(target)))
	var button := main.call("_make_button", label, false) as Button
	button.name = "MapConnectionMarker_" + target
	button.pressed.connect(_on_connection_pressed.bind(target))
	parent.add_child(button)
	_place_marker(button, marker, ordinal, list_layout)


func _place_marker(button: Button, marker: Dictionary, ordinal: int, list_layout: bool) -> void:
	if list_layout:
		button.custom_minimum_size = Vector2(0, 62)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		return
	var compact := _is_compact()
	var marker_size := MARKER_COMPACT_SIZE if compact else MARKER_DESKTOP_SIZE
	var position := _normalized_position(marker, ordinal)
	button.anchor_left = position.x
	button.anchor_top = position.y
	button.anchor_right = position.x
	button.anchor_bottom = position.y
	button.offset_left = -marker_size.x * 0.5
	button.offset_top = -marker_size.y * 0.5
	button.offset_right = marker_size.x * 0.5
	button.offset_bottom = marker_size.y * 0.5
	button.custom_minimum_size = marker_size
	button.add_theme_font_size_override("font_size", 13 if compact else 15)


func _build_connections(zone: Dictionary) -> void:
	connection_layer = Control.new()
	connection_layer.name = "WorldMapConnections"
	connection_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# Esta capa se dibuja después del mapa. Si aceptase input en toda su área
	# bloquearía los marcadores situados detrás; solo sus botones deben capturarlo.
	connection_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content_root.add_child(connection_layer)
	var left_index := 0
	var right_index := 0
	var other_index := 0
	for connection in _connection_list(zone):
		var target := str(connection.get("to", connection.get("target_zone_id", "")))
		if target.is_empty():
			continue
		var side := str(connection.get("side", "")).to_lower()
		var compact := _is_compact()
		var label := str(connection.get("compact_label", connection.get("label", _zone_name(target)))) if compact else str(connection.get("label", _zone_name(target)))
		if side == "left" and not label.begins_with("←"):
			label = "← " + label
		elif side == "right" and not label.ends_with("→"):
			label += " →"
		var residents := _string_array(connection.get("residents", []))
		if bool(connection.get("show_residents", true)) and not residents.is_empty():
			var names := PackedStringArray()
			for resident_id in residents:
				names.append(_character_name(resident_id))
			label += "\n" + " · ".join(names)
		var button := main.call("_make_button", label, false) as Button
		button.name = "WorldConnection_" + target
		button.tooltip_text = "Viajar a " + _zone_name(target)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.pressed.connect(_on_connection_pressed.bind(target))
		connection_layer.add_child(button)
		var index := other_index
		if side == "left":
			index = left_index
			left_index += 1
		elif side == "right":
			index = right_index
			right_index += 1
		else:
			other_index += 1
		_place_connection(button, side, index)
	if current_zone_id == _default_zone_id() and _all_visits_complete():
		var summary := main.call("_make_button", "Ver resumen de la partida", true) as Button
		summary.name = "WorldMapSummaryButton"
		summary.custom_minimum_size = Vector2(280, 54)
		summary.anchor_left = 0.5
		summary.anchor_top = 1.0
		summary.anchor_right = 0.5
		summary.anchor_bottom = 1.0
		summary.offset_left = -140.0
		summary.offset_top = -64.0
		summary.offset_right = 140.0
		summary.offset_bottom = -10.0
		summary.pressed.connect(_finish_current_run)
		connection_layer.add_child(summary)


func _place_connection(button: Button, side: String, index: int) -> void:
	var compact := _is_compact()
	var button_size := CONNECTION_COMPACT_SIZE if compact else CONNECTION_DESKTOP_SIZE
	button.custom_minimum_size = button_size
	button.add_theme_font_size_override("font_size", 13 if compact else 15)
	if side == "bottom_right":
		var panel_right := 0.96 if compact else 0.88
		var panel_bottom := 0.94
		var inset := 12.0 if compact else 18.0
		button.anchor_left = panel_right
		button.anchor_right = panel_right
		button.anchor_top = panel_bottom
		button.anchor_bottom = panel_bottom
		button.offset_left = -inset - button_size.x
		button.offset_right = -inset
		button.offset_top = -inset - button_size.y
		button.offset_bottom = -inset
		return
	var temporary_compact := compact and bool(current_zone.get("temporary", false))
	var y := (0.86 if temporary_compact else 0.38) + float(index) * (0.10 if temporary_compact else (0.13 if compact else 0.15))
	button.anchor_top = y
	button.anchor_bottom = y
	button.offset_top = -button_size.y * 0.5
	button.offset_bottom = button_size.y * 0.5
	match side:
		"left":
			button.anchor_left = 0.0
			button.anchor_right = 0.0
			button.offset_left = MAP_MARGIN
			button.offset_right = MAP_MARGIN + button_size.x
		"right":
			button.anchor_left = 1.0
			button.anchor_right = 1.0
			button.offset_left = -MAP_MARGIN - button_size.x
			button.offset_right = -MAP_MARGIN
		_:
			button.anchor_left = 0.5
			button.anchor_right = 0.5
			button.offset_left = -button_size.x * 0.5
			button.offset_right = button_size.x * 0.5


func _on_character_pressed(character_id: String) -> void:
	if character_id.is_empty() or character_id == _player_id():
		return
	var state := _state()
	state["current_zone_id"] = current_zone_id
	_set_state(state, true)
	var room_id := "room_" + character_id
	var dm: Variant = _dm()
	if dm != null and dm.has_method("get_character_room_id"):
		var configured_room := str(dm.call("get_character_room_id", character_id))
		if not configured_room.is_empty():
			room_id = configured_room
	_record_event("location_visited", {
		"location_id": room_id,
		"zone_id": current_zone_id,
		"character_id": character_id
	}, state)
	_record_event("conversation_started", {
		"character_id": character_id,
		"zone_id": current_zone_id
	}, state)
	_resolve_dependencies()
	if transition_manager != null and transition_manager.has_method("begin_character_visit"):
		transition_manager.call("begin_character_visit", character_id)
	elif version_manager != null:
		version_manager.call("_select_visit", character_id)


func _on_connection_pressed(target_zone_id: String) -> void:
	if target_zone_id.is_empty() or target_zone_id == current_zone_id:
		return
	var target := _zone(target_zone_id)
	if target.is_empty():
		if main != null:
			main.call("_show_toast", "La localidad todavía no está disponible")
		return
	_resolve_dependencies()
	var callback := Callable(self, "_complete_zone_change").bind(target_zone_id)
	if transition_manager == null:
		callback.call()
		return
	if bool(target.get("temporary", false)) and transition_manager.has_method("play_missing_map_transition"):
		transition_manager.call("play_missing_map_transition", target_zone_id, str(target.get("name", target_zone_id)), callback)
	elif transition_manager.has_method("play_generic_transition"):
		transition_manager.call(
			"play_generic_transition",
			"EN CAMINO",
			"Te diriges a %s." % str(target.get("name", target_zone_id)),
			1.25,
			callback
		)
	else:
		callback.call()


func _complete_zone_change(target_zone_id: String) -> void:
	var state := _state()
	state["current_zone_id"] = target_zone_id
	_set_state(state, true)
	_render_zone(target_zone_id, true)


func _on_header_back() -> void:
	if current_mode == "shop":
		_render_zone(current_zone_id, false)
		return
	var default_zone := _default_zone_id()
	if current_zone_id != default_zone:
		_on_connection_pressed(default_zone)
		return
	close_selector()
	if version_manager != null:
		version_manager.call("_leave_to_menu")
	elif main != null:
		main.call("_show_menu")


func _all_visits_complete() -> bool:
	var completed_value: Variant = _state().get("completed_characters", [])
	if typeof(completed_value) != TYPE_ARRAY:
		return false
	var completed := completed_value as Array
	var player_id := _player_id()
	var expected := 0
	for zone in _zones():
		for resident_id in _resident_ids(zone):
			if resident_id == player_id:
				continue
			expected += 1
			if not completed.has(resident_id):
				return false
	return expected > 0


func _finish_current_run() -> void:
	_set_state(_state(), true)
	close_selector()
	if version_manager != null:
		version_manager.call("_hide_selector")
	if main != null:
		main.call("_finish_demo")


func _open_shop(record_visit: bool = true) -> void:
	current_mode = "shop"
	_clear_content()
	_refresh_header()
	header_title.text = "TIENDA"
	header_back_button.visible = true
	header_back_spacer.visible = false
	header_back_button.text = "← Mapa"
	if record_visit:
		_record_event("location_visited", {"location_id": "shop", "zone_id": current_zone_id}, _state())

	var panel := PanelContainer.new()
	panel.name = "WorldShopPanel"
	panel.anchor_left = 0.07
	panel.anchor_top = 0.03
	panel.anchor_right = 0.93
	panel.anchor_bottom = 0.97
	panel.add_theme_stylebox_override(
		"panel",
		main.call("_panel_style", Color(0.030, 0.023, 0.018, 0.98), Color("d6a85f"), 2, 16)
	)
	content_root.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var heading := Label.new()
	heading.text = "COLECCIONABLES Y COSMÉTICOS"
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Color("f2c97e"))
	heading.add_theme_font_size_override("font_size", 25)
	box.add_child(heading)

	shop_status = Label.new()
	shop_status.name = "ShopStatus"
	shop_status.text = "El contenido comprado se desbloquea globalmente."
	shop_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shop_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_status.add_theme_color_override("font_color", Color("d7c7b1"))
	shop_status.add_theme_font_size_override("font_size", 14)
	box.add_child(shop_status)

	var scroll := ScrollContainer.new()
	scroll.name = "ShopCatalogScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	box.add_child(scroll)

	var list := VBoxContainer.new()
	list.name = "ShopCatalogList"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 10)
	scroll.add_child(list)

	var visible_items := 0
	for item in _shop_items():
		if not bool(item.get("enabled", true)):
			continue
		_add_shop_item(list, item)
		visible_items += 1
	if visible_items == 0:
		var empty := Label.new()
		empty.text = "La tienda todavía no tiene artículos disponibles."
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty.add_theme_color_override("font_color", Color("d7c7b1"))
		empty.add_theme_font_size_override("font_size", 17)
		list.add_child(empty)
	_queue_layout()


func _add_shop_item(parent: VBoxContainer, item: Dictionary) -> void:
	var item_id := str(item.get("id", ""))
	if item_id.is_empty():
		return
	var price := maxi(0, int(item.get("price", 0)))
	var category := str(item.get("category", "coleccionable"))
	var category_name := str(item.get("category_name", category.replace("_", " ").capitalize()))
	var owned := _is_item_owned(item_id, category)
	var enough := _coins() >= price

	var card := PanelContainer.new()
	card.name = "ShopItem_" + item_id
	card.add_theme_stylebox_override(
		"panel",
		main.call("_panel_style", Color(0.045, 0.032, 0.025, 0.96), Color(0.57, 0.40, 0.21, 0.78), 1, 11)
	)
	parent.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 11)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 11)
	card.add_child(margin)

	var row: BoxContainer
	if _is_compact():
		row = VBoxContainer.new()
	else:
		row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)

	var asset_path := str(item.get("asset", ""))
	if not asset_path.is_empty() and ResourceLoader.exists(asset_path):
		var preview := TextureRect.new()
		preview.custom_minimum_size = Vector2(72, 72)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.texture = ResourceLoader.load(asset_path) as Texture2D
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(preview)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	row.add_child(info)

	var name_label := Label.new()
	name_label.text = str(item.get("name", item.get("nombre", item_id)))
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_color_override("font_color", Color("fff0d4"))
	name_label.add_theme_font_size_override("font_size", 19)
	info.add_child(name_label)

	var category_label := Label.new()
	category_label.text = category_name.to_upper()
	category_label.add_theme_color_override("font_color", Color("e2b765"))
	category_label.add_theme_font_size_override("font_size", 12)
	info.add_child(category_label)

	var description := Label.new()
	description.text = str(item.get("description", item.get("descripcion", "")))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", Color("cfbfaa"))
	description.add_theme_font_size_override("font_size", 14)
	info.add_child(description)

	var buy := main.call("_make_button", "", false) as Button
	buy.name = "ShopBuy_" + item_id
	buy.custom_minimum_size = Vector2(184, 60)
	if _is_compact():
		buy.custom_minimum_size = Vector2(0, 60)
		buy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if owned:
		buy.text = "COMPRADO\nDESBLOQUEADO"
		buy.disabled = true
	elif not enough:
		buy.text = "● %d MONEDAS\nINSUFICIENTE" % price
		buy.disabled = true
	else:
		buy.text = "COMPRAR\n● %d MONEDAS" % price
		buy.pressed.connect(_purchase_item.bind(item))
	row.add_child(buy)


func _purchase_item(item: Dictionary) -> void:
	var item_id := str(item.get("id", ""))
	var price := maxi(0, int(item.get("price", 0)))
	if _coins() < price:
		_set_shop_status("No tienes suficientes MONEDAS.", true)
		return
	_resolve_dependencies()
	if progress_manager == null or not progress_manager.has_method("purchase"):
		_set_shop_status("La compra no está disponible en este momento.", true)
		return

	var state := _state()
	var result: Variant = _call_purchase(item_id, item, state)
	var success := false
	var message := "Compra realizada."
	if typeof(result) == TYPE_BOOL:
		success = bool(result)
	elif typeof(result) == TYPE_DICTIONARY:
		var response := result as Dictionary
		success = bool(response.get("success", response.get("purchased", false)))
		message = str(response.get("message", response.get("reason", message if success else "No se ha podido completar la compra.")))
		var returned_state: Variant = response.get("state", null)
		if typeof(returned_state) == TYPE_DICTIONARY:
			state = returned_state as Dictionary
	if success:
		if _collection_category_for_shop(item) == "collectible":
			message += " Puedes verlo en Extras → Colección."
		_set_state(state, true)
		_open_shop(false)
		_set_shop_status(message, false)
	else:
		_set_shop_status(message, true)


func _collection_category_for_shop(item: Dictionary) -> String:
	var category := str(item.get("category", "")).to_lower().strip_edges()
	return "collectible" if category in ["collectible", "collectibles", "coleccionable", "coleccionables"] else category


func _call_purchase(item_id: String, item: Dictionary, state: Dictionary) -> Variant:
	var argument_count := _method_argument_count(progress_manager, "purchase")
	if argument_count >= 3:
		return progress_manager.call("purchase", item_id, item, state)
	if argument_count == 1:
		return progress_manager.call("purchase", item_id)
	# Contrato principal del sistema de progreso.
	return progress_manager.call("purchase", item_id, state)


func _set_shop_status(message: String, is_error: bool) -> void:
	if shop_status == null:
		return
	shop_status.text = message
	shop_status.add_theme_color_override("font_color", Color("f0a090") if is_error else Color("bde49a"))


func _refresh_header() -> void:
	if header_title == null:
		return
	header_title.text = str(current_zone.get("name", current_zone_id)).to_upper()
	var temporary := bool(current_zone.get("temporary", false))
	header_back_button.visible = not temporary
	header_back_spacer.visible = temporary
	header_back_button.text = "Menú" if current_zone_id == _default_zone_id() else "← Naranjal"
	_refresh_coins()


func _refresh_coins() -> void:
	if coins_label != null:
		coins_label.text = "MONEDAS: %d" % _coins()


func _record_zone_entry(zone: Dictionary) -> void:
	var signature := str(zone.get("id", current_zone_id)) + ":" + str(Time.get_ticks_msec())
	# Cada apertura real del selector/entrada por conexión cuenta una vez. Los
	# relayouts no pasan por este método con `record_visit=true`.
	if signature == last_recorded_entry:
		return
	last_recorded_entry = signature
	_record_event("location_visited", {
		"location_id": current_zone_id,
		"zone_id": current_zone_id
	}, _state())


func _record_event(event_type: String, context: Dictionary, state: Dictionary) -> void:
	_resolve_dependencies()
	if progress_manager != null and progress_manager.has_method("record_event"):
		progress_manager.call("record_event", event_type, context, state)


func _migrate_state(state: Dictionary) -> Dictionary:
	var dm: Variant = DataAccess.dm()
	if dm != null and dm.has_method("migrate_save_state"):
		var migrated: Variant = dm.call("migrate_save_state", state)
		if typeof(migrated) == TYPE_DICTIONARY:
			return migrated as Dictionary
	return state


func _state() -> Dictionary:
	if main == null:
		return {}
	var value: Variant = main.get("state")
	return value as Dictionary if typeof(value) == TYPE_DICTIONARY else {}


func _set_state(state: Dictionary, save: bool) -> void:
	if main == null:
		return
	main.set("state", state)
	if save and not state.is_empty():
		main.call("_save_game", false)


func _coins() -> int:
	_resolve_dependencies()
	if progress_manager != null and progress_manager.has_method("get_coins"):
		return maxi(0, int(progress_manager.call("get_coins", _state())))
	return maxi(0, int(_state().get("coins", 0)))


func _player_id() -> String:
	var player: Variant = _state().get("player", {})
	if typeof(player) != TYPE_DICTIONARY:
		return ""
	return str((player as Dictionary).get("id", ""))


func _dm() -> Variant:
	return DataAccess.dm()


func _world_data() -> Dictionary:
	var dm: Variant = _dm()
	if dm == null:
		return {}
	var value: Variant = {}
	if dm.has_method("get_world_data"):
		value = dm.call("get_world_data")
	elif dm.has_method("get_world_maps"):
		value = dm.call("get_world_maps")
	return value as Dictionary if typeof(value) == TYPE_DICTIONARY else {}


func _zone(zone_id: String) -> Dictionary:
	var dm: Variant = _dm()
	if dm != null and (dm.has_method("get_zone") or dm.has_method("get_world_map")):
		var value: Variant = dm.call("get_zone", zone_id) if dm.has_method("get_zone") else dm.call("get_world_map", zone_id)
		if typeof(value) == TYPE_DICTIONARY and not (value as Dictionary).is_empty():
			return (value as Dictionary).duplicate(true)
	for zone in _zones():
		if str(zone.get("id", "")) == zone_id:
			return zone.duplicate(true)
	return {}


func _zones() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var raw: Variant = _world_data().get("zones", [])
	if typeof(raw) == TYPE_ARRAY:
		for item in raw as Array:
			if typeof(item) == TYPE_DICTIONARY:
				result.append((item as Dictionary).duplicate(true))
	elif typeof(raw) == TYPE_DICTIONARY:
		for raw_id in (raw as Dictionary).keys():
			var item: Variant = (raw as Dictionary)[raw_id]
			if typeof(item) != TYPE_DICTIONARY:
				continue
			var zone := (item as Dictionary).duplicate(true)
			if not zone.has("id"):
				zone["id"] = str(raw_id)
			result.append(zone)
	return result


func _default_zone_id() -> String:
	var world := _world_data()
	var dm: Variant = _dm()
	if dm != null and dm.has_method("get_default_zone_id"):
		var backend_default := str(dm.call("get_default_zone_id"))
		if not backend_default.is_empty():
			return backend_default
	for key in ["default_zone_id", "default_zone", "start_zone", "initial_zone"]:
		var configured := str(world.get(key, ""))
		if not configured.is_empty() and not _zone_without_default_lookup(configured).is_empty():
			return configured
	for zone in _zones():
		var zone_id := str(zone.get("id", ""))
		var normalized := zone_id.to_lower()
		if normalized.contains("naranjal"):
			return zone_id
	var zones := _zones()
	return str(zones[0].get("id", DEFAULT_ZONE_FALLBACK)) if not zones.is_empty() else DEFAULT_ZONE_FALLBACK


func _zone_without_default_lookup(zone_id: String) -> Dictionary:
	var dm: Variant = _dm()
	if dm != null and (dm.has_method("get_zone") or dm.has_method("get_world_map")):
		var direct: Variant = dm.call("get_zone", zone_id) if dm.has_method("get_zone") else dm.call("get_world_map", zone_id)
		if typeof(direct) == TYPE_DICTIONARY:
			return direct as Dictionary
	for zone in _zones():
		if str(zone.get("id", "")) == zone_id:
			return zone
	return {}


func _zone_name(zone_id: String) -> String:
	var zone := _zone(zone_id)
	return str(zone.get("name", zone_id.replace("_", " ").capitalize()))


func _marker_list(zone: Dictionary) -> Array[Dictionary]:
	return _dictionary_array(zone.get("markers", zone.get("locations", [])))


func _connection_list(zone: Dictionary) -> Array[Dictionary]:
	return _dictionary_array(zone.get("connections", []))


func _dictionary_array(value: Variant) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if typeof(value) == TYPE_ARRAY:
		for item in value as Array:
			if typeof(item) == TYPE_DICTIONARY:
				result.append((item as Dictionary).duplicate(true))
	elif typeof(value) == TYPE_DICTIONARY:
		for raw_id in (value as Dictionary).keys():
			var item: Variant = (value as Dictionary)[raw_id]
			if typeof(item) != TYPE_DICTIONARY:
				continue
			var entry := (item as Dictionary).duplicate(true)
			if not entry.has("id"):
				entry["id"] = str(raw_id)
			result.append(entry)
	return result


func _resident_ids(zone: Dictionary) -> Array[String]:
	return _string_array(zone.get("residents", []))


func _string_array(value: Variant) -> Array[String]:
	var result: Array[String] = []
	if typeof(value) != TYPE_ARRAY:
		return result
	for raw in value as Array:
		var item := str(raw)
		if not item.is_empty():
			result.append(item)
	return result


func _normalized_position(marker: Dictionary, ordinal: int) -> Vector2:
	var raw: Variant = marker.get("position", {})
	if typeof(raw) == TYPE_DICTIONARY:
		var position := raw as Dictionary
		return Vector2(
			clampf(float(position.get("x", 0.5)), 0.03, 0.97),
			clampf(float(position.get("y", 0.5)), 0.06, 0.94)
		)
	if typeof(raw) == TYPE_ARRAY and (raw as Array).size() >= 2:
		return Vector2(
			clampf(float((raw as Array)[0]), 0.03, 0.97),
			clampf(float((raw as Array)[1]), 0.06, 0.94)
		)
	var column := ordinal % 3
	var row := int(ordinal / 3)
	return Vector2(0.28 + float(column) * 0.22, 0.34 + float(row) * 0.24)


func _character_name(character_id: String) -> String:
	var dm: Variant = _dm()
	if dm != null and dm.has_method("get_character"):
		var value: Variant = dm.call("get_character", character_id)
		if typeof(value) == TYPE_DICTIONARY:
			var data := value as Dictionary
			# En el mapa se usa el nombre geográfico/narrativo (Jony, Carmen), no
			# necesariamente el apodo mostrado en su ficha (Jon, Carmela).
			return str(data.get("name", data.get("display_name", character_id.capitalize())))
	return character_id.replace("_", " ").capitalize()


func _load_map_texture(path: String) -> Texture2D:
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path) as Texture2D


func _shop_items() -> Array[Dictionary]:
	var dm: Variant = _dm()
	if dm == null or not dm.has_method("get_shop_catalog"):
		return []
	var catalog: Variant = dm.call("get_shop_catalog")
	if typeof(catalog) == TYPE_DICTIONARY:
		var root := catalog as Dictionary
		for key in ["items", "catalog", "products"]:
			if root.has(key):
				return _dictionary_array(root[key])
	return _dictionary_array(catalog)


func _is_item_owned(item_id: String, category: String) -> bool:
	_resolve_dependencies()
	if progress_manager == null:
		return false
	if progress_manager.has_method("is_item_unlocked"):
		var count := _method_argument_count(progress_manager, "is_item_unlocked")
		return bool(progress_manager.call("is_item_unlocked", item_id, category)) if count >= 2 else bool(progress_manager.call("is_item_unlocked", item_id))
	if progress_manager.has_method("is_unlocked"):
		return bool(progress_manager.call("is_unlocked", item_id))
	var profile: Dictionary = {}
	if progress_manager.has_method("get_profile"):
		var raw_profile: Variant = progress_manager.call("get_profile")
		if typeof(raw_profile) == TYPE_DICTIONARY:
			profile = raw_profile as Dictionary
	elif _has_property(progress_manager, "profile"):
		var profile_property: Variant = progress_manager.get("profile")
		if typeof(profile_property) == TYPE_DICTIONARY:
			profile = profile_property as Dictionary
	if profile.is_empty():
		var dm: Variant = _dm()
		if dm != null and dm.has_method("get_profile"):
			var stored_profile: Variant = dm.call("get_profile")
			if typeof(stored_profile) == TYPE_DICTIONARY:
				profile = stored_profile as Dictionary
	for key in ["unlocked_collectibles", "collectibles", "unlocked_cosmetics", "cosmetics", "purchased_items", "unlocks"]:
		var values: Variant = profile.get(key, [])
		if typeof(values) == TYPE_ARRAY and (values as Array).has(item_id):
			return true
	return false


func _method_argument_count(object: Object, method_name: String) -> int:
	if object == null:
		return -1
	for info in object.get_method_list():
		if str(info.get("name", "")) == method_name:
			var args: Variant = info.get("args", [])
			return (args as Array).size() if typeof(args) == TYPE_ARRAY else -1
	return -1


func _has_property(object: Object, property_name: String) -> bool:
	if object == null:
		return false
	for info in object.get_property_list():
		if str(info.get("name", "")) == property_name:
			return true
	return false


func _queue_layout() -> void:
	call_deferred("_apply_layout")


func _on_viewport_size_changed() -> void:
	call_deferred("_rebuild_after_resize")


func _rebuild_after_resize() -> void:
	if overlay == null or not overlay.visible:
		return
	if current_mode == "shop":
		_open_shop(false)
	elif current_mode == "zone" and not current_zone_id.is_empty():
		_render_zone(current_zone_id, false)
	else:
		_apply_layout()


func _apply_layout() -> void:
	if overlay == null or not overlay.visible:
		return
	var compact := _is_compact()
	if header_title != null:
		header_title.add_theme_font_size_override("font_size", 18 if compact else 25)
	if coins_label != null:
		coins_label.custom_minimum_size = Vector2(122 if compact else 170, 46)
		coins_label.add_theme_font_size_override("font_size", 13 if compact else 17)
	if header_back_button != null:
		header_back_button.custom_minimum_size = Vector2(104 if compact else 132, 46)
	if map_canvas != null and map_texture_size.x > 0.0 and map_texture_size.y > 0.0 and content_root != null:
		var available := content_root.size
		var scale_factor := minf(available.x / map_texture_size.x, available.y / map_texture_size.y)
		var display_size := map_texture_size * maxf(scale_factor, 0.001)
		var top_left := (available - display_size) * 0.5
		map_canvas.anchor_left = 0.0
		map_canvas.anchor_top = 0.0
		map_canvas.anchor_right = 0.0
		map_canvas.anchor_bottom = 0.0
		map_canvas.offset_left = top_left.x
		map_canvas.offset_top = top_left.y
		map_canvas.offset_right = top_left.x + display_size.x
		map_canvas.offset_bottom = top_left.y + display_size.y


func _is_compact() -> bool:
	var size := get_viewport().get_visible_rect().size
	return size.x < 820.0 or size.y > size.x
