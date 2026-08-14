extends "res://scripts/version_063_mobile_extras_patch.gd"


func _show_home() -> void:
	super()
	_compact_home_options()
	call_deferred("_apply_compact_extras_layout")


func _extras_grid_columns() -> int:
	var width := get_viewport().get_visible_rect().size.x
	if width >= 1180.0:
		return 4
	if width >= 840.0:
		return 3
	if width >= 560.0:
		return 2
	return 1


func _add_extra_option(parent: GridContainer, title: String, subtitle: String, callback: Callable, node_name: String) -> void:
	var button := main.call("_make_button", title + "\n" + subtitle, false) as Button
	button.name = node_name
	button.custom_minimum_size = Vector2(175, 82)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_FILL
	button.add_theme_font_size_override("font_size", 15)
	button.pressed.connect(callback)
	parent.add_child(button)
	_bind_button_click(button)


func _show_achievements() -> void:
	current_page = "achievements"
	current_character_id = ""
	var profile := _global_profile()
	var definitions := _achievement_definitions()
	var unlocked := _id_set(profile.get("unlocked_achievements", profile.get("achievements", [])))
	_set_header("Logros", "%d de %d conseguidos" % [_count_known_unlocked(definitions, unlocked), definitions.size()])
	_clear_page()

	var scroll := ScrollContainer.new()
	scroll.name = "AchievementsScroll066"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_configure_touch_scroll(scroll)
	page_host.add_child(scroll)

	var content := VBoxContainer.new()
	content.name = "AchievementsContent066"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	scroll.add_child(content)

	if definitions.is_empty():
		_add_empty_panel(content, "Todavía no hay logros configurados.")
		call_deferred("_configure_scroll_tree", scroll)
		return

	var grid := GridContainer.new()
	grid.name = "AchievementsGrid066"
	grid.columns = _achievement_grid_columns()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(grid)

	var stats := _profile_statistics(profile)
	for definition_value in definitions:
		if typeof(definition_value) != TYPE_DICTIONARY:
			continue
		var achievement: Dictionary = definition_value
		if not bool(achievement.get("enabled", true)):
			continue
		_add_compact_achievement_card(grid, achievement, unlocked, stats)

	call_deferred("_configure_scroll_tree", scroll)
	call_deferred("_apply_compact_extras_layout")


func _add_compact_achievement_card(parent: GridContainer, achievement: Dictionary, unlocked: Dictionary, stats: Dictionary) -> void:
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
	panel.custom_minimum_size = Vector2(210, 118)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var border := GOLD if obtained else Color(0.37, 0.31, 0.25, 0.78)
	var background := Color(0.075, 0.052, 0.031, 0.98) if obtained else Color(0.035, 0.029, 0.026, 0.94)
	panel.add_theme_stylebox_override("panel", main.call("_panel_style", background, border, 2 if obtained else 1, 10))
	parent.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 9)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 9)
	panel.add_child(margin)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 9)
	margin.add_child(row)

	var icon_path := ACHIEVEMENT_STAR_ICON_PATH if obtained else (ACHIEVEMENT_SECRET_ICON_PATH if secret else STATUS_PENDING_ICON_PATH)
	var emblem := _make_icon_texture(icon_path, Vector2(30, 30))
	emblem.name = "AchievementStatusIcon063"
	emblem.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	row.add_child(emblem)

	var text_box := VBoxContainer.new()
	text_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_box.add_theme_constant_override("separation", 2)
	row.add_child(text_box)

	var title_label := Label.new()
	title_label.text = title
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title_label.max_lines_visible = 2
	title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	title_label.add_theme_color_override("font_color", Color("fff0d7") if obtained else TEXT)
	title_label.add_theme_font_size_override("font_size", 15)
	text_box.add_child(title_label)

	if not description.is_empty():
		var description_label := Label.new()
		description_label.text = description
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description_label.max_lines_visible = 2
		description_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		description_label.add_theme_color_override("font_color", TEXT_DIM)
		description_label.add_theme_font_size_override("font_size", 12)
		text_box.add_child(description_label)

	var progress_info := _achievement_progress(achievement, stats)
	var status := Label.new()
	status.text = "CONSEGUIDO" if obtained else "PENDIENTE"
	if not obtained and not secret and not progress_info.is_empty():
		status.text += " · " + str(progress_info.get("text", ""))
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.max_lines_visible = 1
	status.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	status.add_theme_color_override("font_color", GOLD if obtained else Color("aa9c8a"))
	status.add_theme_font_size_override("font_size", 11)
	text_box.add_child(status)

	if not obtained and not secret and not progress_info.is_empty():
		var progress := ProgressBar.new()
		progress.name = "AchievementProgress_" + achievement_id
		progress.custom_minimum_size = Vector2(0, 8)
		progress.show_percentage = false
		progress.max_value = maxf(1.0, float(progress_info.get("target", 1.0)))
		progress.value = clampf(float(progress_info.get("value", 0.0)), 0.0, progress.max_value)
		text_box.add_child(progress)


func _achievement_grid_columns() -> int:
	var width := get_viewport().get_visible_rect().size.x
	if width >= 1600.0:
		return 4
	if width >= 1040.0:
		return 3
	if width >= 650.0:
		return 2
	return 1


func _compact_home_options() -> void:
	if page_host == null:
		return
	var grid := page_host.find_child("ExtrasOptionsGrid050", true, false) as GridContainer
	if grid == null:
		return
	grid.columns = _extras_grid_columns()
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	for child in grid.get_children():
		if child is not Button:
			continue
		var button := child as Button
		button.custom_minimum_size = Vector2(175, 82)
		button.size_flags_vertical = Control.SIZE_FILL
		button.add_theme_font_size_override("font_size", 15)


func _apply_layout() -> void:
	super()
	_apply_compact_extras_layout()


func _apply_compact_extras_layout() -> void:
	_compact_home_options()
	if page_host == null:
		return
	var achievements_grid := page_host.find_child("AchievementsGrid066", true, false) as GridContainer
	if achievements_grid != null:
		achievements_grid.columns = _achievement_grid_columns()
