extends "res://scripts/version_084_compact_extras_patch.gd"

const DataAccess099 = preload("res://scripts/data_access.gd")


func _add_character_tabs(right: VBoxContainer, character_id: String) -> void:
	super(right, character_id)

	var tabs := right.find_child("CharacterTabs060", false, false) as HBoxContainer
	var info_content := right.find_child("CharacterInfoTabContent060", false, false) as Control
	var cosmetic_content := right.find_child("CharacterCosmeticsTabContent060", false, false) as Control
	var info_button := right.find_child("CharacterInfoTab060", true, false) as Button
	var cosmetic_button := right.find_child("CharacterCosmeticsTab060", true, false) as Button
	if tabs == null or info_content == null or cosmetic_content == null or info_button == null or cosmetic_button == null:
		return

	var appearance_button := main.call("_make_small_button", "Apariencia") as Button
	appearance_button.name = "CharacterAppearanceTab099"
	appearance_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tabs.add_child(appearance_button)

	var appearance_scroll := ScrollContainer.new()
	appearance_scroll.name = "CharacterAppearanceTabContent099"
	appearance_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	appearance_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	appearance_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	appearance_scroll.visible = false
	right.add_child(appearance_scroll)

	var appearance_list := VBoxContainer.new()
	appearance_list.name = "CharacterAppearanceList099"
	appearance_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	appearance_list.add_theme_constant_override("separation", 10)
	appearance_scroll.add_child(appearance_list)
	_populate_character_appearance(appearance_list, character_id)

	# Las conexiones originales siguen gestionando Ficha/Cosméticos; estas dos
	# conexiones adicionales solo cierran Apariencia cuando se cambia de pestaña.
	info_button.pressed.connect(func():
		appearance_scroll.visible = false
		appearance_button.disabled = false
	)
	cosmetic_button.pressed.connect(func():
		appearance_scroll.visible = false
		appearance_button.disabled = false
	)
	appearance_button.pressed.connect(_select_appearance_tab.bind(
		info_content,
		cosmetic_content,
		appearance_scroll,
		info_button,
		cosmetic_button,
		appearance_button
	))
	_bind_button_click(appearance_button)
	_refresh_character_detail_portrait(character_id)


func _select_appearance_tab(
	info_content: Control,
	cosmetic_content: Control,
	appearance_content: Control,
	info_button: Button,
	cosmetic_button: Button,
	appearance_button: Button
) -> void:
	info_content.visible = false
	cosmetic_content.visible = false
	appearance_content.visible = true
	info_button.disabled = false
	cosmetic_button.disabled = false
	appearance_button.disabled = true


func _populate_character_appearance(parent: VBoxContainer, character_id: String) -> void:
	_add_section_title(parent, "Apariencia")
	_add_body_label(parent, "Elige el aspecto que usará este personaje en el juego. Todas las apariencias disponibles aquí están desbloqueadas desde el principio y puedes cambiarlas cuando quieras.")

	var dm: Variant = DataAccess099.dm()
	if dm == null or not dm.has_method("get_character_skins"):
		_add_empty_panel(parent, "El sistema de apariencias no está disponible.")
		return
	var raw_skins: Variant = dm.call("get_character_skins", character_id)
	if typeof(raw_skins) != TYPE_ARRAY or (raw_skins as Array).is_empty():
		_add_empty_panel(parent, "Este personaje todavía no tiene apariencias configuradas.")
		return

	var selected := str(dm.call("get_selected_character_skin", character_id))
	var grid := GridContainer.new()
	grid.name = "CharacterAppearanceGrid099"
	grid.columns = 1 if get_viewport().get_visible_rect().size.x < 760.0 else 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	parent.add_child(grid)

	for raw_skin in raw_skins as Array:
		if typeof(raw_skin) != TYPE_DICTIONARY:
			continue
		_add_skin_card(grid, character_id, raw_skin as Dictionary, selected)


func _add_skin_card(parent: GridContainer, character_id: String, skin: Dictionary, selected_skin_id: String) -> void:
	var skin_id := str(skin.get("id", "default"))
	var selected := skin_id == selected_skin_id
	var card := PanelContainer.new()
	card.name = "CharacterSkin_%s_%s" % [character_id, skin_id]
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.custom_minimum_size = Vector2(0, 300)
	card.add_theme_stylebox_override(
		"panel",
		main.call("_panel_style", Color(0.075, 0.050, 0.038, 0.97), GOLD if selected else Color(0.42, 0.31, 0.20, 0.86), 2 if selected else 1, 12)
	)
	parent.add_child(card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	card.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	margin.add_child(box)

	var preview := TextureRect.new()
	preview.name = "SkinPreview099"
	preview.custom_minimum_size = Vector2(0, 190)
	preview.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	preview.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	var asset := str(skin.get("asset", ""))
	if not asset.is_empty() and ResourceLoader.exists(asset):
		preview.texture = ResourceLoader.load(asset) as Texture2D
	box.add_child(preview)

	var title := Label.new()
	title.text = str(skin.get("name", skin_id.capitalize()))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", GOLD if selected else Color("f7ead8"))
	title.add_theme_font_size_override("font_size", 17)
	box.add_child(title)

	var description := Label.new()
	description.text = str(skin.get("description", ""))
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.add_theme_color_override("font_color", TEXT_DIM)
	description.add_theme_font_size_override("font_size", 13)
	box.add_child(description)

	var choose := main.call("_make_button", "Seleccionada" if selected else "Usar esta apariencia", selected) as Button
	choose.name = "SelectSkin_%s_%s" % [character_id, skin_id]
	choose.disabled = selected
	choose.custom_minimum_size = Vector2(0, 44)
	choose.pressed.connect(_select_character_skin.bind(character_id, skin_id))
	box.add_child(choose)
	_bind_button_click(choose)


func _select_character_skin(character_id: String, skin_id: String) -> void:
	var dm: Variant = DataAccess099.dm()
	if dm == null or not dm.has_method("set_selected_character_skin"):
		return
	if not bool(dm.call("set_selected_character_skin", character_id, skin_id)):
		if main != null:
			main.call("_show_toast", "No se ha podido cambiar la apariencia")
		return
	_refresh_runtime_character_visual(character_id)
	_refresh_character_detail_portrait(character_id)
	# La pantalla de Nueva partida vive durante toda la sesión. Sincronizamos su
	# tarjeta inmediatamente para que no conserve la textura anterior en memoria.
	if main != null:
		var selector := main.get_node_or_null("CharacterSelectManager")
		if selector != null and selector.has_method("refresh_character_portrait"):
			selector.call("refresh_character_portrait", character_id)
		main.call("_show_toast", "Apariencia cambiada")
	# Reconstruir la ficha refresca inmediatamente previews, borde y botón activo.
	_show_character(character_id)


func _refresh_runtime_character_visual(character_id: String) -> void:
	if main == null:
		return
	var manager: Variant = main.get("asset_manager")
	var raw_views: Variant = main.get("character_views")
	if manager == null or typeof(raw_views) != TYPE_DICTIONARY:
		return
	var views := raw_views as Dictionary
	if not views.has(character_id):
		return
	var view := views[character_id] as TextureRect
	if view == null:
		return
	var expression := "neutral"
	var raw_state: Variant = main.get("state")
	if typeof(raw_state) == TYPE_DICTIONARY:
		var raw_expressions: Variant = (raw_state as Dictionary).get("expressions", {})
		if typeof(raw_expressions) == TYPE_DICTIONARY:
			expression = str((raw_expressions as Dictionary).get(character_id, "neutral"))
	view.texture = manager.call("get_character", character_id, expression) as Texture2D


func _refresh_character_detail_portrait(character_id: String) -> void:
	if page_host == null:
		return
	var portrait := page_host.find_child("CharacterPortrait050", true, false) as TextureRect
	var dm: Variant = DataAccess099.dm()
	if portrait == null or dm == null:
		return
	var path := str(dm.call("get_character_image_path", character_id, "neutral"))
	if not path.is_empty() and ResourceLoader.exists(path):
		portrait.texture = ResourceLoader.load(path) as Texture2D
