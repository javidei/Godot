extends Node

# 0.10.6: composición final del menú principal. Esta capa espera a que los
# managers históricos hayan creado sus botones y después los reorganiza sin
# sustituir sus callbacks ni duplicar lógica de guardado, historias o Extras.

var main: Control
var menu_screen: Control
var menu_content: VBoxContainer

var primary_row: HBoxContainer
var story_row: HBoxContainer
var secondary_row: HBoxContainer
var stories_box: VBoxContainer
var bottom_row: HBoxContainer

var new_button: Button
var continue_button: Button
var extras_button: Button
var settings_button: Button
var exit_button: Button
var fullscreen_button: Button
var manage_button: Button
var roster_button: Button
var audio_title: Label
var audio_row: HBoxContainer
var version_label: Label
var settings_content: VBoxContainer


func _ready() -> void:
	# StoryLibrary termina alrededor del frame 28 y SaveSlots alrededor del 32.
	# Esperamos algo más para convertir el árbol ya definitivo del menú.
	for _i in range(42):
		await get_tree().process_frame

	main = get_parent() as Control
	if main == null:
		return
	menu_screen = main.get("menu_screen") as Control
	menu_content = main.get("menu_content") as VBoxContainer
	if menu_screen == null or menu_content == null:
		push_error("MenuRedesign106: no se ha podido localizar el menú principal")
		return

	_capture_nodes()
	_build_main_composition()
	_move_controls_into_settings()
	_hide_legacy_menu_nodes()
	_place_version_label()
	_apply_layout()

	get_viewport().size_changed.connect(_queue_layout)


func _capture_nodes() -> void:
	primary_row = menu_content.find_child("MenuPrimaryActions045", true, false) as HBoxContainer
	story_row = menu_content.find_child("MenuStoryActions0101", true, false) as HBoxContainer
	secondary_row = menu_content.find_child("MenuSecondaryActions045", true, false) as HBoxContainer

	new_button = _find_menu_button(["Nueva partida"])
	continue_button = _find_menu_button(["Continuar", "Continuar partida"])
	extras_button = menu_content.find_child("ExtrasButton050", true, false) as Button
	settings_button = menu_content.find_child("SettingsButton060", true, false) as Button
	exit_button = menu_content.find_child("ExitGameButton", true, false) as Button
	fullscreen_button = menu_content.find_child("MenuFullscreenButton", true, false) as Button
	manage_button = menu_content.find_child("ManageSaveSlotsButton070", true, false) as Button
	roster_button = _find_menu_button(["Personajes de la historia"])
	audio_title = menu_content.find_child("AudioSettingsTitle", true, false) as Label
	audio_row = menu_content.find_child("MasterAudioControls084", true, false) as HBoxContainer
	if audio_row == null:
		audio_row = menu_content.find_child("AudioCombinedControls040", true, false) as HBoxContainer
	version_label = menu_content.find_child("VersionLabel", false, false) as Label


func _build_main_composition() -> void:
	if continue_button != null:
		continue_button.text = "Continuar partida"

	if primary_row == null:
		primary_row = HBoxContainer.new()
		primary_row.name = "MenuPrimaryActions106"
		menu_content.add_child(primary_row)
	primary_row.visible = true
	primary_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary_row.add_theme_constant_override("separation", 10)
	for button in [new_button, continue_button]:
		if button == null:
			continue
		if button.get_parent() != primary_row:
			button.reparent(primary_row)
		_prepare_main_button(button, 58)

	stories_box = menu_content.find_child("MenuStories106", false, false) as VBoxContainer
	if stories_box == null:
		stories_box = VBoxContainer.new()
		stories_box.name = "MenuStories106"
		stories_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stories_box.add_theme_constant_override("separation", 8)
		menu_content.add_child(stories_box)

	for node_name in ["StoryButton_historia_asesino", "StoryButton_trilogia_innecesaria"]:
		var story_button := menu_content.find_child(node_name, true, false) as Button
		if story_button == null:
			continue
		story_button.reparent(stories_box)
		_prepare_main_button(story_button, 52)

	if extras_button != null:
		extras_button.reparent(menu_content)
		_prepare_main_button(extras_button, 52)

	bottom_row = menu_content.find_child("MenuBottomActions106", false, false) as HBoxContainer
	if bottom_row == null:
		bottom_row = HBoxContainer.new()
		bottom_row.name = "MenuBottomActions106"
		bottom_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bottom_row.add_theme_constant_override("separation", 10)
		menu_content.add_child(bottom_row)

	for button in [settings_button, exit_button]:
		if button == null:
			continue
		button.reparent(bottom_row)
		_prepare_main_button(button, 52)

	_order_main_menu()


func _move_controls_into_settings() -> void:
	settings_content = _find_settings_content()
	if settings_content == null:
		push_error("MenuRedesign106: no se ha encontrado el contenido de Ajustes")
		return

	# El resumen estático de Audio deja paso a los controles reales que antes
	# ocupaban el menú principal.
	for child in settings_content.get_children():
		var label := child as Label
		if label == null:
			continue
		var text := label.text.strip_edges()
		if text == "Audio" or text.contains("Volumen general:") or text.contains("El mismo volumen controla"):
			label.visible = false

	var insert_at := 0
	if audio_title != null:
		audio_title.reparent(settings_content)
		audio_title.visible = true
		audio_title.text = "VOLUMEN GENERAL"
		audio_title.add_theme_font_size_override("font_size", 13)
		settings_content.move_child(audio_title, insert_at)
		insert_at += 1

	if audio_row != null:
		audio_row.reparent(settings_content)
		audio_row.visible = true
		audio_row.custom_minimum_size = Vector2(0, 48)
		audio_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		audio_row.add_theme_constant_override("separation", 8)
		for child in audio_row.get_children():
			var control := child as Control
			if control != null:
				control.custom_minimum_size.y = 44
		settings_content.move_child(audio_row, insert_at)
		insert_at += 1

	if fullscreen_button != null:
		fullscreen_button.reparent(settings_content)
		fullscreen_button.visible = true
		fullscreen_button.text = "Pantalla completa"
		_prepare_settings_button(fullscreen_button)
		settings_content.move_child(fullscreen_button, insert_at)
		insert_at += 1

	# La selección del reparto es una preferencia de la próxima partida, no una
	# ficha del códice. Recuperamos aquí su acceso y conservamos el overlay y la
	# persistencia que ya proporciona StoryRuntimeManager.
	if roster_button != null:
		roster_button.reparent(settings_content)
		roster_button.visible = true
		roster_button.text = "Personajes de la historia"
		_prepare_settings_button(roster_button)
		settings_content.move_child(roster_button, insert_at)
		insert_at += 1

	# Gestión de slots deja de ocupar el menú, pero se conserva accesible dentro
	# de Ajustes para no perder ninguna función existente.
	if manage_button != null:
		manage_button.reparent(settings_content)
		manage_button.visible = true
		manage_button.text = "Partidas guardadas"
		_prepare_settings_button(manage_button)
		settings_content.move_child(manage_button, insert_at)


func _hide_legacy_menu_nodes() -> void:
	var engine_tag := menu_content.find_child("EngineTag", false, false) as Label
	if engine_tag != null:
		engine_tag.visible = false
	if story_row != null:
		story_row.visible = false
	if secondary_row != null:
		secondary_row.visible = false
	var exit_spacer := menu_content.find_child("ExitSpacer050", true, false) as Control
	if exit_spacer != null:
		exit_spacer.visible = false


func _place_version_label() -> void:
	if version_label == null or menu_screen == null:
		return
	var version := str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	version_label.text = "v%s · EARLY ACCESS" % version
	version_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	version_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	version_label.z_index = 3
	if version_label.get_parent() != menu_screen:
		version_label.reparent(menu_screen)
	version_label.anchor_left = 0.0
	version_label.anchor_top = 1.0
	version_label.anchor_right = 0.0
	version_label.anchor_bottom = 1.0
	version_label.offset_left = 18.0
	version_label.offset_top = -36.0
	version_label.offset_right = 300.0
	version_label.offset_bottom = -12.0
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	version_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM


func _order_main_menu() -> void:
	var title := menu_content.find_child("GameTitle", false, false) as Label
	var subtitle := _menu_subtitle(title)
	var spacer := _menu_spacer()
	var insert_at := 0
	if title != null:
		insert_at = title.get_index() + 1
	if subtitle != null:
		insert_at = subtitle.get_index() + 1
	if spacer != null:
		spacer.visible = true
		spacer.custom_minimum_size = Vector2(0, 6)
		menu_content.move_child(spacer, insert_at)
		insert_at += 1

	for node in [primary_row, stories_box, extras_button, bottom_row]:
		if node == null or node.get_parent() != menu_content:
			continue
		menu_content.move_child(node, insert_at)
		insert_at += 1

	if version_label != null and version_label.get_parent() == menu_content:
		menu_content.move_child(version_label, menu_content.get_child_count() - 1)


func _find_settings_content() -> VBoxContainer:
	var settings_screen := main.find_child("SettingsScreen060", true, false) as Control
	if settings_screen == null:
		return null
	var click_label := settings_screen.find_child("ClickSoundSelection060", true, false) as Label
	if click_label != null and click_label.get_parent() is VBoxContainer:
		return click_label.get_parent() as VBoxContainer
	var panel := settings_screen.find_child("SettingsPanel060", true, false) as PanelContainer
	if panel == null:
		return null
	for candidate in panel.find_children("*", "VBoxContainer", true, false):
		var box := candidate as VBoxContainer
		if box != null:
			return box
	return null


func _find_menu_button(texts: Array[String]) -> Button:
	for candidate in menu_content.find_children("*", "Button", true, false):
		var button := candidate as Button
		if button != null and texts.has(button.text):
			return button
	return null


func _prepare_main_button(button: Button, height: float) -> void:
	button.visible = true
	button.custom_minimum_size = Vector2(0, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 16)


func _prepare_settings_button(button: Button) -> void:
	button.custom_minimum_size = Vector2(0, 50)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 15)


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


func _queue_layout() -> void:
	call_deferred("_apply_layout")


func _apply_layout() -> void:
	if menu_content == null:
		return

	_order_main_menu()
	var viewport_size := get_viewport().get_visible_rect().size
	var portrait := viewport_size.y > viewport_size.x
	menu_content.offset_left = 0.0
	menu_content.offset_top = 0.0
	menu_content.offset_right = 0.0
	menu_content.offset_bottom = 0.0
	menu_content.size_flags_vertical = Control.SIZE_FILL
	menu_content.add_theme_constant_override("separation", 7 if not portrait else 6)

	if portrait:
		menu_content.anchor_left = 0.06
		menu_content.anchor_right = 0.94
		menu_content.anchor_top = 0.025
		menu_content.anchor_bottom = 0.975
	else:
		menu_content.anchor_left = 0.025
		menu_content.anchor_right = 0.43
		menu_content.anchor_top = 0.025
		menu_content.anchor_bottom = 0.975

	var title := menu_content.find_child("GameTitle", false, false) as Label
	if title != null:
		title.custom_minimum_size = Vector2(0, 88 if not portrait else 82)
		title.add_theme_font_size_override("font_size", 42 if not portrait else 38)

	var subtitle := _menu_subtitle(title)
	if subtitle != null:
		subtitle.add_theme_font_size_override("font_size", 14 if not portrait else 13)

	if primary_row != null:
		primary_row.add_theme_constant_override("separation", 10)
		for child in primary_row.get_children():
			var button := child as Button
			if button != null:
				_prepare_main_button(button, 58 if not portrait else 52)
	if stories_box != null:
		stories_box.add_theme_constant_override("separation", 8 if not portrait else 6)
		for child in stories_box.get_children():
			var button := child as Button
			if button != null:
				_prepare_main_button(button, 52 if not portrait else 48)
	if extras_button != null:
		_prepare_main_button(extras_button, 52 if not portrait else 48)
	if bottom_row != null:
		bottom_row.add_theme_constant_override("separation", 10)
		for child in bottom_row.get_children():
			var button := child as Button
			if button != null:
				_prepare_main_button(button, 52 if not portrait else 48)
	if version_label != null:
		_place_version_label()
		version_label.add_theme_font_size_override("font_size", 10 if portrait else 11)
