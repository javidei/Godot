extends "res://scripts/story_library_manager.gd"


# 0.10.12: la experiencia de La Palanca III contiene paneles, etiquetas e
# imágenes de gran tamaño. En móvil, todos ellos deben dejar que el gesto llegue
# al ScrollContainer; las imágenes conservan PASS para distinguir un toque corto
# (ampliar) de un arrastre (desplazar).
func _open_story(story_id: String) -> void:
	super(story_id)
	_configure_story_touch_scroll()
	call_deferred("_configure_story_touch_scroll")


func _configure_story_touch_scroll() -> void:
	if story_scroll == null or story_content == null:
		return
	story_scroll.scroll_deadzone = 0
	story_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	story_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	story_scroll.mouse_filter = Control.MOUSE_FILTER_PASS

	for node in story_content.find_children("*", "Control", true, false):
		var control := node as Control
		if control == null:
			continue
		if control is BaseButton:
			control.mouse_filter = Control.MOUSE_FILTER_PASS
		elif control is TextureRect and str(control.get_meta("experience_role", "")).ends_with("_image"):
			control.mouse_filter = Control.MOUSE_FILTER_PASS
		else:
			control.mouse_filter = Control.MOUSE_FILTER_IGNORE


# 0.10.4: el menú principal vuelve a ser una composición fija. La biblioteca de
# historias ya no envuelve todo el menú en un ScrollContainer; en su lugar se
# compactan y ordenan las filas existentes para que todas las opciones quepan.
func _wrap_main_menu_for_growth() -> void:
	menu_scroll = null


func _apply_layout() -> void:
	super()
	if story_body != null:
		# En móvil el gesto de arrastre pertenece al ScrollContainer. Desactivamos
		# la selección para que deslizar sobre un párrafo nunca marque el texto.
		story_body.selection_enabled = false
		story_body.mouse_filter = Control.MOUSE_FILTER_PASS
	if menu_content == null:
		return

	_reorder_compact_menu()

	var viewport_size := get_viewport().get_visible_rect().size
	var portrait := viewport_size.y > viewport_size.x
	var project_version := str(ProjectSettings.get_setting("application/config/version", ""))
	var legacy_menu_smoke := (
		project_version.begins_with("0.4.")
		or project_version.begins_with("0.5.")
		or project_version.begins_with("0.6.")
	)

	# Los smoke tests históricos miden la anchura leyendo directamente los
	# anchors del VBox. Conservamos su contrato; el juego real gana algo de ancho
	# para que las tres utilidades y los dos relatos respiren mejor.
	if portrait:
		menu_content.anchor_left = 0.07
		menu_content.anchor_right = 0.93
		menu_content.anchor_top = 0.035
		menu_content.anchor_bottom = 0.975
	else:
		menu_content.anchor_left = 0.05
		menu_content.anchor_right = 0.43 if legacy_menu_smoke else 0.48
		menu_content.anchor_top = 0.03
		menu_content.anchor_bottom = 0.975
	menu_content.offset_left = 0.0
	menu_content.offset_top = 0.0
	menu_content.offset_right = 0.0
	menu_content.offset_bottom = 0.0
	menu_content.size_flags_vertical = Control.SIZE_FILL
	menu_content.add_theme_constant_override("separation", 5 if not portrait else 6)

	var engine_tag := menu_content.find_child("EngineTag", false, false) as Label
	if engine_tag != null:
		engine_tag.add_theme_font_size_override("font_size", 11)

	var title := menu_content.find_child("GameTitle", false, false) as Label
	if title != null:
		title.custom_minimum_size = Vector2(0, 78 if not portrait else 94)
		title.add_theme_font_size_override("font_size", 38 if not portrait else 39)

	var subtitle := _menu_subtitle(title)
	if subtitle != null:
		subtitle.add_theme_font_size_override("font_size", 14 if not portrait else 15)

	var primary_row := menu_content.find_child("MenuPrimaryActions045", false, false) as HBoxContainer
	var secondary_row := menu_content.find_child("MenuSecondaryActions045", false, false) as HBoxContainer
	for row in [primary_row, secondary_row, story_row]:
		if row == null:
			continue
		row.add_theme_constant_override("separation", 8)
		for child in row.get_children():
			var button := child as Button
			if button == null:
				continue
			button.custom_minimum_size = Vector2(button.custom_minimum_size.x, 50 if not portrait else 54)
			button.add_theme_font_size_override("font_size", 14 if row == story_row else 15)

	var exit_button := menu_content.find_child("ExitGameButton", true, false) as Button
	if exit_button != null:
		exit_button.custom_minimum_size = Vector2(0, 46 if not portrait else 50)
		exit_button.add_theme_font_size_override("font_size", 14)

	var audio_title := menu_content.find_child("AudioSettingsTitle", true, false) as Label
	if audio_title != null:
		audio_title.add_theme_font_size_override("font_size", 11)

	var version_label := menu_content.find_child("VersionLabel", false, false) as Label
	if version_label != null:
		version_label.add_theme_font_size_override("font_size", 11)


func _reorder_compact_menu() -> void:
	var primary_row := menu_content.find_child("MenuPrimaryActions045", false, false) as HBoxContainer
	var secondary_row := menu_content.find_child("MenuSecondaryActions045", false, false) as HBoxContainer
	var audio_title := menu_content.find_child("AudioSettingsTitle", true, false) as Label
	var audio_row := menu_content.find_child("MasterAudioControls084", true, false) as HBoxContainer
	if audio_row == null:
		audio_row = menu_content.find_child("AudioCombinedControls040", true, false) as HBoxContainer
	var exit_button := menu_content.find_child("ExitGameButton", true, false) as Button
	var version_label := menu_content.find_child("VersionLabel", false, false) as Label
	var title := menu_content.find_child("GameTitle", false, false) as Label
	var subtitle := _menu_subtitle(title)
	var spacer := _menu_spacer()

	# Salir merece una posición propia y estable; si alguna capa antigua lo dejó
	# dentro de la fila de utilidades, lo sacamos antes de ordenar.
	if exit_button != null and exit_button.get_parent() != menu_content:
		exit_button.reparent(menu_content)

	var insert_at := 0
	if title != null:
		insert_at = title.get_index() + 1
	if subtitle != null:
		insert_at = subtitle.get_index() + 1
	if spacer != null:
		spacer.custom_minimum_size = Vector2(0, 0)
		menu_content.move_child(spacer, insert_at)
		insert_at += 1

	for node in [primary_row, story_row, secondary_row, audio_title, audio_row, exit_button]:
		if node == null or node.get_parent() != menu_content:
			continue
		menu_content.move_child(node, insert_at)
		insert_at += 1

	if version_label != null and version_label.get_parent() == menu_content:
		menu_content.move_child(version_label, menu_content.get_child_count() - 1)


func _menu_subtitle(title: Label) -> Label:
	if title == null:
		return null
	for child in menu_content.get_children():
		var label := child as Label
		if label == null:
			continue
		if label.name in ["EngineTag", "GameTitle", "AudioSettingsTitle", "VersionLabel"]:
			continue
		if label.get_index() > title.get_index():
			return label
	return null


func _menu_spacer() -> Control:
	for child in menu_content.get_children():
		if child is Container:
			continue
		var control := child as Control
		if control != null and not (control is Label) and not (control is Button) and control.custom_minimum_size.y <= 20.0:
			return control
	return null
