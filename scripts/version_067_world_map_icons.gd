extends "res://scripts/world_map_manager.gd"

const MAP_STATUS_CHECK_ICON_PATH := "res://assets/ui/icons/status-check.svg"
const MAP_STATUS_PENDING_ICON_PATH := "res://assets/ui/icons/status-pending.svg"
const MAP_ARROW_LEFT_ICON_PATH := "res://assets/ui/icons/arrow-left.svg"
const MAP_ARROW_RIGHT_ICON_PATH := "res://assets/ui/icons/arrow-right.svg"
const MAP_SHOP_ICON_PATH := "res://assets/ui/icons/shop.svg"


func _add_character_marker(parent: Control, marker: Dictionary, ordinal: int, list_layout: bool) -> bool:
	var added := super(parent, marker, ordinal, list_layout)
	if not added:
		return false
	var character_id := str(marker.get("character_id", marker.get("id", "")))
	var button := parent.find_child("MapCharacter_" + character_id, false, false) as Button
	if button == null:
		return true
	var visited := bool(button.get_meta("visited", false))
	var display_name := str(marker.get("label", marker.get("name", _character_name(character_id))))
	button.text = "Visitar a " + display_name
	_set_map_button_icon(button, MAP_STATUS_CHECK_ICON_PATH if visited else MAP_STATUS_PENDING_ICON_PATH)
	return true


func _add_shop_marker(parent: Control, marker: Dictionary, ordinal: int, list_layout: bool) -> void:
	super(parent, marker, ordinal, list_layout)
	var button := parent.find_child("MapShopMarker", false, false) as Button
	if button == null:
		return
	button.text = str(marker.get("label", marker.get("name", "TIENDA"))).to_upper()
	_set_map_button_icon(button, MAP_SHOP_ICON_PATH)


func _add_marker_connection(parent: Control, marker: Dictionary, ordinal: int, list_layout: bool) -> void:
	super(parent, marker, ordinal, list_layout)
	var target := str(marker.get("to", marker.get("target_zone_id", marker.get("zone_id", ""))))
	if target.is_empty():
		return
	var button := parent.find_child("MapConnectionMarker_" + target, false, false) as Button
	if button == null:
		return
	button.text = _without_arrow_glyphs(button.text)
	_apply_connection_icon(button, str(marker.get("side", "")).to_lower(), target)


func _build_connections(zone: Dictionary) -> void:
	super(zone)
	if connection_layer == null:
		return
	var side_by_target := {}
	for connection in _connection_list(zone):
		var target := str(connection.get("to", connection.get("target_zone_id", "")))
		if not target.is_empty():
			side_by_target[target] = str(connection.get("side", "")).to_lower()
	for node in connection_layer.get_children():
		if node is not Button:
			continue
		var button := node as Button
		var node_name := str(button.name)
		if not node_name.begins_with("WorldConnection_"):
			continue
		var target := node_name.trim_prefix("WorldConnection_")
		button.text = _without_arrow_glyphs(button.text)
		_apply_connection_icon(button, str(side_by_target.get(target, "")), target)


func _refresh_header() -> void:
	super()
	if header_back_button == null or current_mode == "shop":
		return
	if current_zone_id == _default_zone_id():
		header_back_button.icon = null
		return
	header_back_button.text = "Naranjal"
	_set_map_button_icon(header_back_button, MAP_ARROW_LEFT_ICON_PATH)


func _open_shop(record_visit: bool = true) -> void:
	super(record_visit)
	if header_back_button == null:
		return
	header_back_button.text = "Mapa"
	_set_map_button_icon(header_back_button, MAP_ARROW_LEFT_ICON_PATH)


func _apply_connection_icon(button: Button, side: String, target: String) -> void:
	match side:
		"left":
			_set_map_button_icon(button, MAP_ARROW_LEFT_ICON_PATH, HORIZONTAL_ALIGNMENT_LEFT)
		"right":
			_set_map_button_icon(button, MAP_ARROW_RIGHT_ICON_PATH, HORIZONTAL_ALIGNMENT_RIGHT)
		"bottom_right":
			if target == _default_zone_id():
				_set_map_button_icon(button, MAP_ARROW_LEFT_ICON_PATH, HORIZONTAL_ALIGNMENT_LEFT)
			else:
				button.icon = null
		_:
			button.icon = null


func _set_map_button_icon(button: Button, icon_path: String, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> void:
	if button == null:
		return
	button.icon = null
	if ResourceLoader.exists(icon_path):
		button.icon = ResourceLoader.load(icon_path) as Texture2D
	button.expand_icon = true
	button.icon_alignment = alignment
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", 20)
	button.add_theme_constant_override("h_separation", 8)


func _without_arrow_glyphs(text: String) -> String:
	var cleaned := text.replace("←", "").replace("→", "")
	var lines := cleaned.split("\n", true)
	var normalized := PackedStringArray()
	for line in lines:
		normalized.append(str(line).strip_edges())
	return "\n".join(normalized)
