extends "res://scripts/version_050_extras_codex.gd"

const DataAccess = preload("res://scripts/data_access.gd")
const ARROW_LEFT_ICON_PATH := "res://assets/ui/icons/arrow-left.svg"
const ARROW_RIGHT_ICON_PATH := "res://assets/ui/icons/arrow-right.svg"


func _load_data() -> void:
	var dm: Variant = DataAccess.dm()
	data = dm.call("get_codex_data") if dm != null else {}
	characters = []
	var people: Variant = data.get("personajes", [])
	if typeof(people) == TYPE_ARRAY:
		characters = people


func _build_extras_screen() -> void:
	super()
	_configure_nav_button(back_button, "Volver", ARROW_LEFT_ICON_PATH, false)


func _show_character(character_id: String) -> void:
	super(character_id)
	call_deferred("_patch_character_detail_layout", character_id)


func _patch_character_detail_layout(character_id: String) -> void:
	if page_host == null or current_page != "character_detail" or current_character_id != character_id:
		return

	var old_row: HBoxContainer = null
	for child in page_host.get_children():
		if child.name == "CharacterDetailRow050" and not child.is_queued_for_deletion():
			old_row = child as HBoxContainer
	if old_row == null:
		return

	var portrait_panel := old_row.find_child("CharacterPortraitPanel050", true, false) as PanelContainer
	var portrait := old_row.find_child("CharacterPortrait050", true, false) as TextureRect
	var right: VBoxContainer = null
	if old_row.get_child_count() > 1:
		right = old_row.get_child(1) as VBoxContainer
	if portrait_panel == null or portrait == null or right == null:
		return

	var nav: HBoxContainer = null
	var previous: Button = null
	var next: Button = null
	for child in right.get_children():
		if child is not HBoxContainer:
			continue
		var candidate := child as HBoxContainer
		var buttons := candidate.find_children("*", "Button", true, false)
		for node in buttons:
			var button := node as Button
			if button == null:
				continue
			if button.text.contains("Anterior"):
				previous = button
			elif button.text.contains("Siguiente"):
				next = button
		if previous != null or next != null:
			nav = candidate
			break

	var viewport_size := get_viewport().get_visible_rect().size
	var compact := viewport_size.x < 760.0

	var root := VBoxContainer.new()
	root.name = "CharacterDetailLayout052"
	root.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_theme_constant_override("separation", 8)
	page_host.add_child(root)

	var content: BoxContainer
	if compact:
		content = VBoxContainer.new()
	else:
		content = HBoxContainer.new()
	content.name = "CharacterDetailContent052"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 18 if not compact else 8)
	root.add_child(content)

	if nav != null:
		nav.reparent(root)
		nav.custom_minimum_size = Vector2(0, 42)
		nav.size_flags_vertical = Control.SIZE_SHRINK_END

	portrait_panel.reparent(content)
	right.reparent(content)
	old_row.queue_free()

	portrait.custom_minimum_size = Vector2(0, 170 if compact else 245)
	portrait_panel.custom_minimum_size = Vector2(0 if compact else 285, 0)
	portrait_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_SHRINK_BEGIN
	portrait_panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN if compact else Control.SIZE_EXPAND_FILL
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_configure_nav_button(previous, "Anterior", ARROW_LEFT_ICON_PATH, false)
	_configure_nav_button(next, "Siguiente", ARROW_RIGHT_ICON_PATH, true)


func _configure_nav_button(button: Button, label: String, icon_path: String, icon_on_right: bool) -> void:
	if button == null:
		return
	button.text = label
	button.expand_icon = true
	button.icon = load(icon_path) as Texture2D
	button.add_theme_constant_override("icon_max_width", 18)
	button.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT if icon_on_right else HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size = Vector2(118, 40)


func _show_places() -> void:
	current_page = "places"
	current_character_id = ""
	_set_header("Lugares", "Habitaciones de los personajes")
	_clear_page()

	var scroll := ScrollContainer.new()
	scroll.name = "RoomCodexScroll052"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_host.add_child(scroll)

	var list := VBoxContainer.new()
	list.name = "RoomCodexList052"
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 18)
	scroll.add_child(list)

	var dm: Variant = DataAccess.dm()
	if dm == null:
		_add_body_label(list, "No se han podido cargar las habitaciones.")
		return

	var room_ids := PackedStringArray()
	var character_ids_value: Variant = dm.call("get_character_ids", true)
	if typeof(character_ids_value) == TYPE_ARRAY:
		for raw_character_id in character_ids_value as Array:
			var room_id := str(dm.call("get_character_room_id", str(raw_character_id)))
			if not room_id.is_empty() and not room_ids.has(room_id):
				room_ids.append(room_id)

	var compact := get_viewport().get_visible_rect().size.x < 900.0
	var visible_index := 0
	for room_id in room_ids:
		var room_value: Variant = dm.call("get_room", room_id)
		if typeof(room_value) != TYPE_DICTIONARY:
			continue
		var room := room_value as Dictionary
		var owners_value: Variant = room.get("owners", [])
		if typeof(owners_value) != TYPE_ARRAY or (owners_value as Array).is_empty():
			continue
		if not bool(room.get("codex_visible", true)):
			continue
		_add_room_entry(list, room, visible_index, compact)
		visible_index += 1

	if visible_index == 0:
		_add_body_label(list, "Todavía no hay habitaciones visibles en el códice.")


func _add_room_entry(parent: VBoxContainer, room: Dictionary, index: int, compact: bool) -> void:
	var panel := PanelContainer.new()
	panel.name = "RoomCodexCard_" + str(room.get("id", index))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override(
		"panel",
		main.call("_panel_style", Color(0.045, 0.030, 0.024, 0.97), Color(0.62, 0.43, 0.22, 0.82), 1, 14)
	)
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	panel.add_child(margin)

	var layout: BoxContainer
	if compact:
		layout = VBoxContainer.new()
	else:
		layout = HBoxContainer.new()
	layout.add_theme_constant_override("separation", 20)
	margin.add_child(layout)

	var image_panel := PanelContainer.new()
	image_panel.name = "RoomImagePanel052"
	image_panel.custom_minimum_size = Vector2(0, 205) if compact else Vector2(430, 245)
	image_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL if compact else Control.SIZE_SHRINK_BEGIN
	image_panel.add_theme_stylebox_override(
		"panel",
		main.call("_panel_style", Color(0.018, 0.012, 0.010, 1.0), Color(0.50, 0.34, 0.17, 0.72), 1, 10)
	)

	var image_margin := MarginContainer.new()
	image_margin.add_theme_constant_override("margin_left", 6)
	image_margin.add_theme_constant_override("margin_top", 6)
	image_margin.add_theme_constant_override("margin_right", 6)
	image_margin.add_theme_constant_override("margin_bottom", 6)
	image_panel.add_child(image_margin)

	var image := TextureRect.new()
	image.name = "RoomImage052"
	image.custom_minimum_size = Vector2(0, 190 if compact else 230)
	image.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	image.size_flags_vertical = Control.SIZE_EXPAND_FILL
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if asset_manager != null:
		image.texture = asset_manager.get_background(str(room.get("background_id", "")))
	image_margin.add_child(image)

	var text_box := VBoxContainer.new()
	text_box.name = "RoomDescription052"
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	text_box.alignment = BoxContainer.ALIGNMENT_CENTER
	text_box.add_theme_constant_override("separation", 9)

	var title := Label.new()
	title.text = str(room.get("display_name", _humanize(str(room.get("id", "Habitación")))))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color", GOLD)
	title.add_theme_font_size_override("font_size", 23)
	text_box.add_child(title)

	var owners_text := _room_owner_names(room)
	if not owners_text.is_empty():
		var owners := Label.new()
		owners.text = owners_text
		owners.add_theme_color_override("font_color", Color("e7c183"))
		owners.add_theme_font_size_override("font_size", 14)
		text_box.add_child(owners)

	var description := Label.new()
	description.text = str(room.get("description", ""))
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.add_theme_color_override("font_color", TEXT_DIM)
	description.add_theme_font_size_override("font_size", 16)
	text_box.add_child(description)

	if compact or index % 2 == 0:
		layout.add_child(image_panel)
		layout.add_child(text_box)
	else:
		layout.add_child(text_box)
		layout.add_child(image_panel)


func _room_owner_names(room: Dictionary) -> String:
	var owners_value: Variant = room.get("owners", [])
	if typeof(owners_value) != TYPE_ARRAY:
		return ""
	var names := PackedStringArray()
	for raw_owner in owners_value as Array:
		var owner_id := str(raw_owner)
		var display := _character_display_from_id(owner_id)
		if not display.is_empty():
			names.append(display)
	if names.is_empty():
		return ""
	return "Habitación de " + " y ".join(names)


func _apply_layout() -> void:
	super()
	_configure_nav_button(back_button, "Volver", ARROW_LEFT_ICON_PATH, false)
