extends "res://scripts/version_099_character_appearance.gd"

const DataAccess0911 = preload("res://scripts/data_access.gd")

var _active_character_tab := "info"


func _show_characters() -> void:
	# Volver al listado reinicia la próxima ficha en Ficha. La persistencia de
	# pestaña se mantiene únicamente al navegar Anterior/Siguiente entre fichas.
	_active_character_tab = "info"
	super()
	call_deferred("_fix_character_card_name_bands")


func _fix_character_card_name_bands() -> void:
	if page_host == null or current_page != "characters":
		return
	var grid := page_host.find_child("CharacterCodexGrid050", true, false) as GridContainer
	if grid == null:
		return
	for child in grid.get_children():
		var card := child as Button
		if card == null or card.get_child_count() == 0:
			continue
		var root := card.get_child(0) as Control
		if root == null:
			continue
		var portrait := root.find_child("CharacterCardPortrait", true, false) as TextureRect
		if portrait != null:
			portrait.anchor_bottom = 0.78
		for candidate in root.get_children():
			if candidate is ColorRect:
				var footer := candidate as ColorRect
				# El bloque del nombre empieza justo donde termina el retrato: ya no
				# tapa pantalones, manos ni la parte inferior de la ilustración.
				footer.anchor_top = 0.78
				break


func _add_character_tabs(right: VBoxContainer, character_id: String) -> void:
	super(right, character_id)

	var info_content := right.find_child("CharacterInfoTabContent060", false, false) as Control
	var cosmetic_content := right.find_child("CharacterCosmeticsTabContent060", false, false) as Control
	var appearance_content := right.find_child("CharacterAppearanceTabContent099", false, false) as Control
	var info_button := right.find_child("CharacterInfoTab060", true, false) as Button
	var cosmetic_button := right.find_child("CharacterCosmeticsTab060", true, false) as Button
	var appearance_button := right.find_child("CharacterAppearanceTab099", true, false) as Button
	if info_content == null or cosmetic_content == null or appearance_content == null:
		return
	if info_button == null or cosmetic_button == null or appearance_button == null:
		return

	info_button.pressed.connect(_remember_character_tab.bind("info"))
	cosmetic_button.pressed.connect(_remember_character_tab.bind("cosmetics"))
	appearance_button.pressed.connect(_remember_character_tab.bind("appearance"))

	_apply_active_character_tab(
		info_content,
		cosmetic_content,
		appearance_content,
		info_button,
		cosmetic_button,
		appearance_button
	)


func _remember_character_tab(tab_id: String) -> void:
	_active_character_tab = tab_id


func _apply_active_character_tab(
	info_content: Control,
	cosmetic_content: Control,
	appearance_content: Control,
	info_button: Button,
	cosmetic_button: Button,
	appearance_button: Button
) -> void:
	match _active_character_tab:
		"appearance":
			_select_appearance_tab(
				info_content,
				cosmetic_content,
				appearance_content,
				info_button,
				cosmetic_button,
				appearance_button
			)
		"cosmetics":
			_select_character_tab("cosmetics", info_content, cosmetic_content, info_button, cosmetic_button)
			appearance_content.visible = false
			appearance_button.disabled = false
		_:
			_active_character_tab = "info"
			_select_character_tab("info", info_content, cosmetic_content, info_button, cosmetic_button)
			appearance_content.visible = false
			appearance_button.disabled = false


func _populate_character_appearance(parent: VBoxContainer, character_id: String) -> void:
	_add_section_title(parent, "Apariencia")
	_add_body_label(parent, "Elige el aspecto que usará este personaje en el juego. Todas las apariencias disponibles aquí están desbloqueadas desde el principio y puedes cambiarlas cuando quieras.")

	var dm: Variant = DataAccess0911.dm()
	if dm == null or not dm.has_method("get_character_skins"):
		_add_empty_panel(parent, "El sistema de apariencias no está disponible.")
		return
	var raw_skins: Variant = dm.call("get_character_skins", character_id)
	if typeof(raw_skins) != TYPE_ARRAY or (raw_skins as Array).is_empty():
		_add_empty_panel(parent, "Este personaje todavía no tiene apariencias configuradas.")
		return

	var skins := raw_skins as Array
	var selected := str(dm.call("get_selected_character_skin", character_id))
	var viewport_width := get_viewport().get_visible_rect().size.x
	var compact := viewport_width < 760.0

	var appearance_scroll := parent.get_parent() as ScrollContainer
	if appearance_scroll != null:
		# En escritorio, de una a cuatro skins deben caber sin pedir scroll.
		# A partir de la quinta se activa el desplazamiento. En móvil se conserva
		# scroll automático para no recortar contenido en pantallas estrechas.
		appearance_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if compact or skins.size() >= 5 else ScrollContainer.SCROLL_MODE_DISABLED

	var grid := GridContainer.new()
	grid.name = "CharacterAppearanceGrid099"
	if viewport_width >= 1180.0:
		grid.columns = clampi(skins.size(), 1, 4)
	elif viewport_width >= 760.0:
		grid.columns = mini(skins.size(), 2)
	else:
		grid.columns = 1
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	parent.add_child(grid)

	for raw_skin in skins:
		if typeof(raw_skin) != TYPE_DICTIONARY:
			continue
		_add_skin_card(grid, character_id, raw_skin as Dictionary, selected)


func _add_skin_card(parent: GridContainer, character_id: String, skin: Dictionary, selected_skin_id: String) -> void:
	var skin_id := str(skin.get("id", "default"))
	var selected := skin_id == selected_skin_id
	var viewport_width := get_viewport().get_visible_rect().size.x

	var card := Button.new()
	card.name = "CharacterSkin_%s_%s" % [character_id, skin_id]
	card.text = ""
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 205 if viewport_width >= 1180.0 else (220 if viewport_width >= 760.0 else 250))
	card.clip_contents = true
	card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	card.focus_mode = Control.FOCUS_NONE if selected else Control.FOCUS_ALL
	card.tooltip_text = "Apariencia en uso" if selected else "Usar esta apariencia"

	var normal_border := GOLD if selected else Color(0.42, 0.31, 0.20, 0.86)
	var normal_width := 2 if selected else 1
	var normal_style: StyleBox = main.call("_panel_style", Color(0.075, 0.050, 0.038, 0.97), normal_border, normal_width, 12)
	var hover_style: StyleBox = main.call("_panel_style", Color(0.105, 0.068, 0.046, 0.99), GOLD, 2, 12)
	var pressed_style: StyleBox = main.call("_panel_style", Color(0.055, 0.037, 0.030, 1.0), GOLD, 2, 12)
	card.add_theme_stylebox_override("normal", normal_style)
	card.add_theme_stylebox_override("hover", hover_style)
	card.add_theme_stylebox_override("pressed", pressed_style)
	card.add_theme_stylebox_override("focus", hover_style)
	card.add_theme_stylebox_override("disabled", normal_style)
	card.disabled = selected
	parent.add_child(card)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	card.add_child(margin)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	var preview := TextureRect.new()
	preview.name = "SkinPreview099"
	preview.custom_minimum_size = Vector2(0, 118 if viewport_width >= 1180.0 else (126 if viewport_width >= 760.0 else 145))
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var asset := str(skin.get("asset", ""))
	if not asset.is_empty() and ResourceLoader.exists(asset):
		preview.texture = ResourceLoader.load(asset) as Texture2D
	box.add_child(preview)

	var title := Label.new()
	title.text = str(skin.get("name", skin_id.capitalize()))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", GOLD if selected else Color("f7ead8"))
	title.add_theme_font_size_override("font_size", 16)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)

	var description := Label.new()
	description.text = str(skin.get("description", ""))
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.max_lines_visible = 2
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	description.add_theme_color_override("font_color", TEXT_DIM)
	description.add_theme_font_size_override("font_size", 12)
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(description)

	var status := Label.new()
	status.name = "SkinStatus0911"
	status.text = "EN USO" if selected else "Pulsa la tarjeta para usarla"
	status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status.add_theme_color_override("font_color", GOLD if selected else Color("aa9c8a"))
	status.add_theme_font_size_override("font_size", 11)
	status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(status)

	if not selected:
		card.pressed.connect(_select_character_skin.bind(character_id, skin_id))
		_bind_button_click(card)
