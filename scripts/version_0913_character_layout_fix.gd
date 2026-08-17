extends "res://scripts/version_0911_character_appearance_ui.gd"


func _fix_character_card_name_bands() -> void:
	super()
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
			portrait.anchor_bottom = 0.855

		for candidate in root.get_children():
			if candidate is ColorRect:
				var footer := candidate as ColorRect
				footer.anchor_top = 0.855
				footer.anchor_bottom = 1.0
				footer.color = Color(0.02, 0.014, 0.012, 0.78)
				var label := footer.get_child(0) as Label if footer.get_child_count() > 0 else null
				if label != null:
					label.add_theme_font_size_override("font_size", 15)
				break


func _add_skin_card(parent: GridContainer, character_id: String, skin: Dictionary, selected_skin_id: String) -> void:
	super(parent, character_id, skin, selected_skin_id)
	if parent.get_child_count() == 0:
		return

	var card := parent.get_child(parent.get_child_count() - 1) as Button
	if card == null:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var preview := card.find_child("SkinPreview099", true, false) as TextureRect
	var old_status := card.find_child("SkinStatus0911", true, false) as Label

	# El texto auxiliar inferior era el que terminaba saliendo fuera de la tarjeta
	# en determinadas relaciones de aspecto. La tarjeta completa ya es clicable,
	# por lo que no hace falta repetir esa instrucción debajo.
	if old_status != null:
		old_status.visible = false
		old_status.custom_minimum_size = Vector2.ZERO

	# Ajuste vertical según el alto real de la ventana. Se mantiene una tarjeta
	# compacta, pero se reserva espacio suficiente para título y descripción.
	if viewport_size.x < 760.0:
		card.custom_minimum_size.y = 250.0
		if preview != null:
			preview.custom_minimum_size.y = 132.0
	elif viewport_size.y < 800.0:
		card.custom_minimum_size.y = 210.0
		if preview != null:
			preview.custom_minimum_size.y = 100.0
	else:
		card.custom_minimum_size.y = 225.0
		if preview != null:
			preview.custom_minimum_size.y = 116.0

	var selected := str(skin.get("id", "default")) == selected_skin_id
	if selected:
		_add_active_skin_badge(card)


func _add_active_skin_badge(card: Button) -> void:
	if card.find_child("SkinActiveBadge0913", false, false) != null:
		return

	var badge := PanelContainer.new()
	badge.name = "SkinActiveBadge0913"
	badge.anchor_left = 1.0
	badge.anchor_top = 0.0
	badge.anchor_right = 1.0
	badge.anchor_bottom = 0.0
	badge.offset_left = -82.0
	badge.offset_top = 9.0
	badge.offset_right = -9.0
	badge.offset_bottom = 34.0
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_theme_stylebox_override(
		"panel",
		main.call("_panel_style", Color(0.12, 0.075, 0.035, 0.98), GOLD, 1, 7)
	)
	card.add_child(badge)

	var label := Label.new()
	label.text = "EN USO"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", GOLD)
	label.add_theme_font_size_override("font_size", 11)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	badge.add_child(label)
