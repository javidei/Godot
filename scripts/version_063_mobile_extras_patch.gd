extends "res://scripts/version_050_extras_codex_data.gd"

const STATUS_CHECK_ICON_PATH := "res://assets/ui/icons/status-check.svg"
const STATUS_PENDING_ICON_PATH := "res://assets/ui/icons/status-pending.svg"
const ACHIEVEMENT_STAR_ICON_PATH := "res://assets/ui/icons/achievement-star.svg"
const ACHIEVEMENT_SECRET_ICON_PATH := "res://assets/ui/icons/achievement-secret.svg"


func _show_home() -> void:
	super()
	call_deferred("_configure_scroll_tree", page_host)


func _show_characters() -> void:
	super()
	call_deferred("_configure_scroll_tree", page_host)


func _show_places() -> void:
	super()
	call_deferred("_configure_scroll_tree", page_host)


func _patch_character_detail_layout(character_id: String) -> void:
	super(character_id)
	if page_host != null and current_page == "character_detail" and current_character_id == character_id:
		call_deferred("_configure_scroll_tree", page_host)


func _make_scroll_details() -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = "ExtrasTouchScroll063"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_configure_touch_scroll(scroll)
	page_host.add_child(scroll)

	var details := VBoxContainer.new()
	details.name = "ExtrasTouchScrollContent063"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 12)
	details.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(details)
	call_deferred("_configure_scroll_tree", scroll)
	return details


func _configure_scroll_tree(root: Node) -> void:
	if root == null or not is_instance_valid(root):
		return
	if root is ScrollContainer:
		_configure_touch_scroll(root as ScrollContainer)
	for candidate in root.find_children("*", "ScrollContainer", true, false):
		if candidate is ScrollContainer:
			_configure_touch_scroll(candidate as ScrollContainer)


func _configure_touch_scroll(scroll: ScrollContainer) -> void:
	if scroll == null or not is_instance_valid(scroll):
		return
	# El ScrollContainer debe recibir inmediatamente el gesto táctil. Los Labels,
	# PanelContainer y demás Controls de presentación no deben quedarse con el drag.
	scroll.scroll_deadzone = 0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = false
	scroll.mouse_filter = Control.MOUSE_FILTER_STOP
	scroll.mouse_force_pass_scroll_events = true
	_relax_scroll_descendant_filters(scroll, scroll)


func _relax_scroll_descendant_filters(node: Node, owner_scroll: ScrollContainer) -> void:
	for child in node.get_children():
		if child is ScrollContainer and child != owner_scroll:
			continue
		if child is BaseButton:
			var button := child as BaseButton
			button.mouse_filter = Control.MOUSE_FILTER_PASS
			button.mouse_force_pass_scroll_events = true
		elif child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		_relax_scroll_descendant_filters(child, owner_scroll)


func _add_collection_card(parent: Container, item: Dictionary, unlocked: bool) -> void:
	var panel := PanelContainer.new()
	panel.name = "CollectionCard_" + str(item.get("id", "item"))
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var border := GOLD if unlocked else Color(0.34, 0.29, 0.25, 0.70)
	panel.add_theme_stylebox_override("panel", main.call("_panel_style", Color(0.045, 0.032, 0.025, 0.96), border, 1, 10))
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 7)
	box.add_child(title_row)

	var status_icon := _make_icon_texture(STATUS_CHECK_ICON_PATH if unlocked else STATUS_PENDING_ICON_PATH, Vector2(20, 20))
	status_icon.name = "CollectionStatusIcon063"
	title_row.add_child(status_icon)

	var title := Label.new()
	title.name = "CollectionTitle063"
	title.text = str(item.get("name", item.get("nombre", _display_identifier(str(item.get("id", "Elemento"))))))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color", GOLD if unlocked else TEXT_DIM)
	title.add_theme_font_size_override("font_size", 15)
	title_row.add_child(title)

	var description := str(item.get("description", item.get("descripcion", "")))
	if not description.is_empty():
		var label := Label.new()
		label.text = description
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", TEXT_DIM)
		label.add_theme_font_size_override("font_size", 12)
		box.add_child(label)

	_add_collection_art(box, item, unlocked)

	var status := Label.new()
	status.text = "DESBLOQUEADO · pulsa cada imagen para verla completa" if unlocked and not _collection_artworks(item).is_empty() else ("DESBLOQUEADO GLOBALMENTE" if unlocked else "PENDIENTE · disponible en la tienda")
	status.add_theme_color_override("font_color", GOLD if unlocked else Color("aa9c8a"))
	status.add_theme_font_size_override("font_size", 12)
	box.add_child(status)


func _add_achievement_card(parent: VBoxContainer, achievement: Dictionary, unlocked: Dictionary, stats: Dictionary) -> void:
	var achievement_id := str(achievement.get("id", ""))
	var obtained := unlocked.has(achievement_id)
	var secret := bool(achievement.get("secret", achievement.get("hidden", false)))
	var title := str(achievement.get("name", achievement.get("nombre", _humanize(achievement_id))))
	var description := str(achievement.get("description", achievement.get("descripcion", "")))
	if secret and not obtained:
		title = "Logro secreto"
		description = "Sigue explorando para descubrirlo."

	var panel := PanelContainer.new()
	panel.name = "AchievementCard_" + achievement_id
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var border := GOLD if obtained else Color(0.37, 0.31, 0.25, 0.78)
	var background := Color(0.075, 0.052, 0.031, 0.98) if obtained else Color(0.035, 0.029, 0.026, 0.94)
	panel.add_theme_stylebox_override("panel", main.call("_panel_style", background, border, 2 if obtained else 1, 12))
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	margin.add_child(row)

	var icon_path := ACHIEVEMENT_STAR_ICON_PATH if obtained else (ACHIEVEMENT_SECRET_ICON_PATH if secret else STATUS_PENDING_ICON_PATH)
	var emblem := _make_icon_texture(icon_path, Vector2(42, 42))
	emblem.name = "AchievementStatusIcon063"
	row.add_child(emblem)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 4)
	row.add_child(text_box)

	var title_label := Label.new()
	title_label.text = title
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.add_theme_color_override("font_color", Color("fff0d7") if obtained else TEXT)
	title_label.add_theme_font_size_override("font_size", 18)
	text_box.add_child(title_label)

	if not description.is_empty():
		var description_label := Label.new()
		description_label.text = description
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.add_theme_color_override("font_color", TEXT_DIM)
		description_label.add_theme_font_size_override("font_size", 14)
		text_box.add_child(description_label)

	var progress_info := _achievement_progress(achievement, stats)
	var status := Label.new()
	status.text = "CONSEGUIDO" if obtained else "PENDIENTE"
	if not obtained and not secret and not progress_info.is_empty():
		status.text += " · " + str(progress_info.get("text", ""))
	status.add_theme_color_override("font_color", GOLD if obtained else Color("aa9c8a"))
	status.add_theme_font_size_override("font_size", 12)
	text_box.add_child(status)

	if not obtained and not secret and not progress_info.is_empty():
		var progress := ProgressBar.new()
		progress.name = "AchievementProgress_" + achievement_id
		progress.custom_minimum_size = Vector2(0, 12)
		progress.show_percentage = false
		progress.max_value = maxf(1.0, float(progress_info.get("target", 1.0)))
		progress.value = clampf(float(progress_info.get("value", 0.0)), 0.0, progress.max_value)
		text_box.add_child(progress)


func _refresh_click_sound_controls(selected_override: String = "") -> void:
	var selected := selected_override
	var audio_manager := _audio_manager()
	if selected.is_empty() and audio_manager != null:
		selected = str(audio_manager.call("get_click_sound"))
	if selected.is_empty():
		var dm: Variant = DataAccess.dm()
		var settings: Dictionary = dm.call("get_settings") if dm != null else {}
		var audio: Dictionary = settings.get("audio", {})
		selected = str(audio.get("click_sound", "soft"))
	if not CLICK_SOUND_IDS.has(selected):
		selected = "soft"
	if click_selection_label != null:
		click_selection_label.text = "Seleccionado: " + str(CLICK_SOUND_LABELS.get(selected, selected.capitalize()))
	for raw_id in click_option_buttons.keys():
		var sound_id := str(raw_id)
		var button := click_option_buttons[raw_id] as Button
		if button == null:
			continue
		button.text = str(CLICK_SOUND_LABELS.get(sound_id, sound_id.capitalize()))
		button.icon = load(STATUS_CHECK_ICON_PATH) as Texture2D if sound_id == selected else null
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.add_theme_constant_override("icon_max_width", 18)
		button.tooltip_text = "Sonido de clic seleccionado" if sound_id == selected else "Seleccionar y escuchar este sonido"


func _make_icon_texture(path: String, minimum: Vector2) -> TextureRect:
	var icon := TextureRect.new()
	icon.custom_minimum_size = minimum
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = load(path) as Texture2D
	return icon
