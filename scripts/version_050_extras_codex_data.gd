extends "res://scripts/version_050_extras_codex.gd"

const DataAccess = preload("res://scripts/data_access.gd")
const ARROW_LEFT_ICON_PATH := "res://assets/ui/icons/arrow-left.svg"
const ARROW_RIGHT_ICON_PATH := "res://assets/ui/icons/arrow-right.svg"

const CLICK_SOUND_LABELS := {
	"soft": "Suave",
	"dry": "Seco",
	"digital": "Digital",
	"wood": "Madera",
	"pop": "Pop",
	"off": "Desactivado"
}
const CLICK_SOUND_IDS: Array[String] = ["soft", "dry", "digital", "wood", "pop", "off"]

const STAT_LABELS := {
	"total_play_seconds": "Tiempo total jugado",
	"sessions": "Sesiones",
	"total_sessions": "Sesiones",
	"platforms": "Plataformas utilizadas",
	"platform_usage": "Plataformas utilizadas",
	"touch_capable": "Dispositivo táctil detectado",
	"touch_capable_seen": "Dispositivo táctil detectado",
	"characters_visited": "Personajes visitados",
	"character_visits": "Visitas por personaje",
	"visits_by_character": "Visitas por personaje",
	"locations_visited": "Localizaciones visitadas",
	"location_visits": "Visitas por localización",
	"visits_by_location": "Visitas por localización",
	"protagonists_used": "Protagonistas utilizados",
	"games_by_protagonist": "Partidas por protagonista",
	"protagonist_games": "Partidas por protagonista",
	"conversations": "Conversaciones realizadas",
	"conversations_completed": "Conversaciones realizadas",
	"decisions": "Decisiones tomadas",
	"decisions_made": "Decisiones tomadas",
	"unique_scenes": "Escenas únicas",
	"unique_scenes_discovered": "Escenas únicas",
	"unique_events": "Eventos únicos",
	"coins_earned": "Monedas ganadas históricamente",
	"coins_spent": "Monedas gastadas históricamente",
	"collectibles_unlocked": "Coleccionables desbloqueados",
	"cosmetics_unlocked": "Cosméticos desbloqueados",
	"achievements_unlocked": "Logros desbloqueados",
	"most_visited_character": "Personaje más visitado",
	"most_visited_location": "Localización más visitada"
}

var settings_button: Button
var settings_screen: Control
var settings_panel: PanelContainer
var click_option_buttons: Dictionary = {}
var click_selection_label: Label


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
	_build_settings_screen()


func _patch_main_menu() -> void:
	super()
	if menu_content == null:
		return
	settings_button = main.call("_make_button", "Ajustes", false) as Button
	settings_button.name = "SettingsButton060"
	settings_button.tooltip_text = "Volumen y sonido de clic"
	settings_button.custom_minimum_size = Vector2(0, 56)
	settings_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	settings_button.add_theme_font_size_override("font_size", 16)
	settings_button.pressed.connect(_open_settings)
	if secondary_row != null:
		secondary_row.add_child(settings_button)
		if extras_button != null:
			secondary_row.move_child(settings_button, extras_button.get_index() + 1)
	else:
		menu_content.add_child(settings_button)
	_reorder_menu_bottom()
	_bind_button_click(settings_button)


func _show_home() -> void:
	current_page = "home"
	current_character_id = ""
	_set_header("Extras", "Códice, progreso global y colección")
	_clear_page()

	var scroll := ScrollContainer.new()
	scroll.name = "ExtrasHomeScroll060"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_host.add_child(scroll)

	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 14)
	scroll.add_child(box)

	var intro := Label.new()
	intro.text = "Consulta el grupo, el mundo y todo lo que has descubierto jugando. El progreso de estas páginas pertenece al perfil local global."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color", TEXT_DIM)
	intro.add_theme_font_size_override("font_size", 16)
	box.add_child(intro)

	var grid := GridContainer.new()
	grid.name = "ExtrasOptionsGrid050"
	grid.columns = _extras_grid_columns()
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 14)
	box.add_child(grid)

	_add_extra_option(grid, "Personajes", "Fichas del grupo", Callable(self, "_show_characters"), "CharactersOption050")
	_add_extra_option(grid, "Información del juego", "Historia, tono y jugabilidad", Callable(self, "_show_game_info"), "GameInfoOption050")
	_add_extra_option(grid, "Lugares", "Escenarios y habitaciones", Callable(self, "_show_places"), "PlacesOption050")
	_add_extra_option(grid, "Logros", "Conseguidos, pendientes y secretos", Callable(self, "_show_achievements"), "AchievementsOption060")
	_add_extra_option(grid, "Cosas que ha hecho el jugador", "Estadísticas de todas las partidas", Callable(self, "_show_statistics"), "StatisticsOption060")
	_add_extra_option(grid, "Colección", "Coleccionables y cosméticos globales", Callable(self, "_show_collection"), "CollectionOption060")
	_add_extra_option(grid, "Créditos", "Autoría y datos del proyecto", Callable(self, "_show_credits"), "CreditsOption050")


func _go_back() -> void:
	match current_page:
		"character_detail":
			_show_characters()
		"characters", "game_info", "places", "credits", "achievements", "statistics", "collection":
			_show_home()
		_:
			_close_extras()


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
	_bind_button_click(button)


func _build_settings_screen() -> void:
	if main == null or settings_screen != null:
		return
	settings_screen = Control.new()
	settings_screen.name = "SettingsScreen060"
	settings_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	settings_screen.z_index = 510
	settings_screen.visible = false
	main.add_child(settings_screen)

	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if asset_manager != null:
		background.texture = asset_manager.get_background("casa_asturias")
	settings_screen.add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.018, 0.012, 0.010, 0.88)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	settings_screen.add_child(shade)

	settings_panel = PanelContainer.new()
	settings_panel.name = "SettingsPanel060"
	settings_panel.anchor_left = 0.12
	settings_panel.anchor_top = 0.08
	settings_panel.anchor_right = 0.88
	settings_panel.anchor_bottom = 0.92
	settings_panel.add_theme_stylebox_override("panel", main.call("_panel_style", PANEL_BG, GOLD_SOFT, 2, 18))
	settings_screen.add_child(settings_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	settings_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 52)
	header.add_theme_constant_override("separation", 14)
	root.add_child(header)

	var close := main.call("_make_small_button", "Volver") as Button
	close.name = "SettingsBackButton060"
	close.custom_minimum_size = Vector2(118, 44)
	close.pressed.connect(_close_settings)
	header.add_child(close)
	_configure_nav_button(close, "Volver", ARROW_LEFT_ICON_PATH, false)

	var title := Label.new()
	title.text = "AJUSTES"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("fff0d7"))
	title.add_theme_font_size_override("font_size", 30)
	header.add_child(title)

	var line := ColorRect.new()
	line.color = Color(0.78, 0.56, 0.28, 0.55)
	line.custom_minimum_size = Vector2(0, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(line)

	var scroll := ScrollContainer.new()
	scroll.name = "SettingsScroll060"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)

	_add_settings_audio_summary(content)
	_add_section_title(content, "Sonido de clic")
	_add_body_label(content, "Elige el sonido que acompaña a botones y controles. La selección usa el volumen de Efectos y se guarda localmente.")

	click_selection_label = Label.new()
	click_selection_label.name = "ClickSoundSelection060"
	click_selection_label.add_theme_color_override("font_color", Color("f5d596"))
	click_selection_label.add_theme_font_size_override("font_size", 17)
	content.add_child(click_selection_label)

	var grid := GridContainer.new()
	grid.name = "ClickSoundGrid060"
	grid.columns = 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	content.add_child(grid)

	click_option_buttons.clear()
	for sound_id in CLICK_SOUND_IDS:
		var option := main.call("_make_button", str(CLICK_SOUND_LABELS.get(sound_id, sound_id.capitalize())), false) as Button
		option.name = "ClickSound_" + sound_id.capitalize()
		option.custom_minimum_size = Vector2(150, 58)
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.pressed.connect(_select_click_sound.bind(sound_id))
		grid.add_child(option)
		click_option_buttons[sound_id] = option
		# Este selector reproduce explícitamente el perfil recién elegido. Se retira
		# el clic automático de Main para no oír primero el perfil anterior.
		_disconnect_main_click(option)

	var hint := Label.new()
	hint.text = "Cada opción se reproduce al seleccionarla. «Desactivado» guarda silencio sin afectar al resto de efectos."
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint.add_theme_color_override("font_color", TEXT_DIM)
	hint.add_theme_font_size_override("font_size", 13)
	content.add_child(hint)

	_refresh_click_sound_controls()


func _add_settings_audio_summary(parent: VBoxContainer) -> void:
	_add_section_title(parent, "Audio")
	var audio_manager := _audio_manager()
	if audio_manager == null:
		_add_body_label(parent, "Los controles de audio no están disponibles.")
		return
	var music_percent := int(audio_manager.call("get_music_volume_percent"))
	var effects_percent := int(audio_manager.call("get_effects_volume_percent"))
	var music_state := "silenciada" if bool(audio_manager.call("is_music_muted")) else "activa"
	var effects_state := "silenciados" if bool(audio_manager.call("is_effects_muted")) else "activos"
	_add_body_label(parent, "Música: %d %% · %s\nEfectos: %d %% · %s\n\nEl volumen y silencio siguen disponibles en el menú principal." % [music_percent, music_state, effects_percent, effects_state])


func _open_settings() -> void:
	if settings_screen == null:
		return
	if menu_screen != null:
		menu_screen.visible = false
	if extras_screen != null:
		extras_screen.visible = false
	settings_screen.visible = true
	_refresh_click_sound_controls()


func _close_settings() -> void:
	if settings_screen != null:
		settings_screen.visible = false
	if menu_screen != null:
		menu_screen.visible = true


func _select_click_sound(sound_id: String) -> void:
	var audio_manager := _audio_manager()
	if audio_manager != null:
		audio_manager.call("set_click_sound", sound_id, false)
	_refresh_click_sound_controls(sound_id)
	if audio_manager != null:
		audio_manager.call("preview_click", sound_id)


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
		var prefix := "✓ " if sound_id == selected else ""
		button.text = prefix + str(CLICK_SOUND_LABELS.get(sound_id, sound_id.capitalize()))
		button.tooltip_text = "Sonido de clic seleccionado" if sound_id == selected else "Seleccionar y escuchar este sonido"


func _audio_manager() -> Node:
	if main == null:
		return null
	var candidate: Variant = main.get("audio_manager")
	return candidate as Node if candidate is Node else main.get_node_or_null("AudioManager")


func _bind_button_click(button: BaseButton) -> void:
	var audio_manager := _audio_manager()
	if audio_manager != null and audio_manager.has_method("bind_click"):
		audio_manager.call("bind_click", button)


func _disconnect_main_click(button: BaseButton) -> void:
	if button == null:
		return
	for connection_value in button.pressed.get_connections():
		if typeof(connection_value) != TYPE_DICTIONARY:
			continue
		var connection: Dictionary = connection_value
		var callback_value: Variant = connection.get("callable", Callable())
		if typeof(callback_value) != TYPE_CALLABLE:
			continue
		var callback: Callable = callback_value
		if callback.is_valid() and str(callback.get_method()) == "_play_ui_sound":
			button.pressed.disconnect(callback)


func _show_achievements() -> void:
	current_page = "achievements"
	current_character_id = ""
	var profile := _global_profile()
	var definitions := _achievement_definitions()
	var unlocked := _id_set(profile.get("unlocked_achievements", profile.get("achievements", [])))
	_set_header("Logros", "%d de %d conseguidos" % [_count_known_unlocked(definitions, unlocked), definitions.size()])
	_clear_page()
	var list := _make_scroll_details()
	if definitions.is_empty():
		_add_empty_panel(list, "Todavía no hay logros configurados.")
		return
	var stats := _profile_statistics(profile)
	for definition_value in definitions:
		if typeof(definition_value) != TYPE_DICTIONARY:
			continue
		var achievement: Dictionary = definition_value
		if not bool(achievement.get("enabled", true)):
			continue
		_add_achievement_card(list, achievement, unlocked, stats)


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

	var emblem := Label.new()
	emblem.text = "★" if obtained else ("?" if secret else "○")
	emblem.custom_minimum_size = Vector2(42, 42)
	emblem.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	emblem.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	emblem.add_theme_color_override("font_color", GOLD if obtained else TEXT_DIM)
	emblem.add_theme_font_size_override("font_size", 27)
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


func _show_statistics() -> void:
	current_page = "statistics"
	current_character_id = ""
	_set_header("Cosas que ha hecho el jugador", "Estadísticas acumuladas de todas las partidas")
	_clear_page()
	var profile := _global_profile()
	var stats := _profile_statistics(profile)
	var details := _make_scroll_details()
	_add_statistics_summary(details, stats, profile)


func _add_statistics_summary(parent: VBoxContainer, stats: Dictionary, profile: Dictionary) -> void:
	var character_visits := _first_dictionary(stats, ["character_visits", "visits_by_character", "characters_visited"])
	var location_visits := _first_dictionary(stats, ["location_visits", "visits_by_location", "locations_visited"])
	var protagonist_games := _first_dictionary(stats, ["protagonist_games", "games_by_protagonist", "protagonists_used"])
	var most_character := str(stats.get("most_visited_character", _largest_key(character_visits)))
	var most_location := str(stats.get("most_visited_location", _largest_key(location_visits)))
	var play_seconds := float(stats.get("total_play_seconds", stats.get("play_seconds", 0.0)))
	var known := {
		"total_play_seconds": _format_duration(play_seconds),
		"sessions": int(stats.get("total_sessions", stats.get("sessions", 0))),
		"platforms": stats.get("platforms", stats.get("platform_usage", {})),
		"touch_capable": stats.get("touch_capable_seen", stats.get("touch_capable", false)),
		"characters_visited": _visited_count(stats.get("characters_visited", character_visits)),
		"character_visits": character_visits,
		"locations_visited": _visited_count(stats.get("locations_visited", location_visits)),
		"location_visits": location_visits,
		"protagonists_used": _visited_count(protagonist_games),
		"games_by_protagonist": protagonist_games,
		"conversations": int(stats.get("conversations", stats.get("conversations_completed", 0))),
		"decisions": int(stats.get("decisions", stats.get("decisions_made", 0))),
		"unique_scenes": _visited_count(stats.get("unique_scenes", stats.get("unique_scenes_discovered", []))),
		"unique_events": _visited_count(stats.get("unique_events", [])),
		"coins_earned": int(stats.get("coins_earned", 0)),
		"coins_spent": int(stats.get("coins_spent", 0)),
		"collectibles_unlocked": _id_set(profile.get("unlocked_collectibles", [])).size(),
		"cosmetics_unlocked": _id_set(profile.get("unlocked_cosmetics", [])).size(),
		"achievements_unlocked": _id_set(profile.get("unlocked_achievements", [])).size(),
		"most_visited_character": _character_display_from_id(most_character) if not most_character.is_empty() else "—",
		"most_visited_location": _display_identifier(most_location) if not most_location.is_empty() else "—"
	}
	for key in known.keys():
		_add_stat_row(parent, str(STAT_LABELS.get(key, _humanize(str(key)))), known[key])

	var shown_keys: Array = known.keys()
	var extra_keys: Array = stats.keys()
	extra_keys.sort()
	var extras_started := false
	for raw_key in extra_keys:
		var key := str(raw_key)
		if shown_keys.has(key) or key in ["play_seconds", "total_sessions", "platform_usage", "touch_capable_seen", "visits_by_character", "visits_by_location", "protagonist_games", "conversations_completed", "decisions_made", "unique_scenes_discovered"]:
			continue
		if not extras_started:
			_add_section_title(parent, "Otros datos registrados")
			extras_started = true
		_add_stat_row(parent, str(STAT_LABELS.get(key, _humanize(key))), stats[raw_key])


func _add_stat_row(parent: VBoxContainer, title: String, value: Variant) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", main.call("_panel_style", Color(0.04, 0.03, 0.025, 0.94), Color(0.39, 0.29, 0.19, 0.72), 1, 9))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 8)
	panel.add_child(margin)
	var compact := get_viewport().get_visible_rect().size.x < 540.0
	var row: BoxContainer = VBoxContainer.new() if compact else HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	margin.add_child(row)
	var name_label := Label.new()
	name_label.text = title
	name_label.custom_minimum_size = Vector2(0 if compact else 245, 0)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.add_theme_color_override("font_color", TEXT_DIM)
	name_label.add_theme_font_size_override("font_size", 14)
	row.add_child(name_label)
	var value_label := Label.new()
	value_label.text = _format_stat_value(value)
	value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if compact else HORIZONTAL_ALIGNMENT_RIGHT
	value_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	value_label.add_theme_color_override("font_color", Color("f5d596"))
	value_label.add_theme_font_size_override("font_size", 15)
	row.add_child(value_label)


func _show_collection() -> void:
	current_page = "collection"
	current_character_id = ""
	var profile := _global_profile()
	var collectibles := _id_set(profile.get("unlocked_collectibles", []))
	var cosmetics := _id_set(profile.get("unlocked_cosmetics", []))
	var catalog := _catalog_items()
	var visible_items: Array[Dictionary] = []
	for item_value in catalog:
		if typeof(item_value) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_value
		if bool(item.get("enabled", true)) and _collection_category(item) != "":
			visible_items.append(item)
	_set_header("Colección", "%d desbloqueos globales" % (collectibles.size() + cosmetics.size()))
	_clear_page()
	var details := _make_scroll_details()
	_add_collection_category(details, "Coleccionables / Extras", "collectible", visible_items, collectibles)
	_add_collection_category(details, "Decoración / Cosméticos", "cosmetic", visible_items, cosmetics)


func _add_collection_category(parent: VBoxContainer, title: String, category: String, items: Array[Dictionary], unlocked: Dictionary) -> void:
	_add_section_title(parent, title)
	var added := 0
	for item in items:
		if _collection_category(item) != category:
			continue
		_add_collection_card(parent, item, unlocked.has(str(item.get("id", ""))))
		added += 1
	if added == 0:
		var ids: Array = unlocked.keys()
		ids.sort()
		if ids.is_empty():
			_add_body_label(parent, "Aún no has desbloqueado elementos de esta categoría.")
		else:
			for raw_id in ids:
				_add_collection_card(parent, {"id": str(raw_id), "name": _display_identifier(str(raw_id)), "description": "Desbloqueado globalmente."}, true)


func _add_collection_card(parent: VBoxContainer, item: Dictionary, unlocked: bool) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var border := GOLD if unlocked else Color(0.34, 0.29, 0.25, 0.70)
	panel.add_theme_stylebox_override("panel", main.call("_panel_style", Color(0.045, 0.032, 0.025, 0.96), border, 1, 10))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 10)
	panel.add_child(margin)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 4)
	margin.add_child(box)
	var title := Label.new()
	title.text = ("✓ " if unlocked else "○ ") + str(item.get("name", item.get("nombre", _display_identifier(str(item.get("id", "Elemento"))))))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.add_theme_color_override("font_color", GOLD if unlocked else TEXT_DIM)
	title.add_theme_font_size_override("font_size", 17)
	box.add_child(title)
	var description := str(item.get("description", item.get("descripcion", "")))
	if not description.is_empty():
		var label := Label.new()
		label.text = description
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_color_override("font_color", TEXT_DIM)
		label.add_theme_font_size_override("font_size", 14)
		box.add_child(label)
	var status := Label.new()
	status.text = "DESBLOQUEADO GLOBALMENTE" if unlocked else "PENDIENTE · disponible en la tienda"
	status.add_theme_color_override("font_color", GOLD if unlocked else Color("aa9c8a"))
	status.add_theme_font_size_override("font_size", 12)
	box.add_child(status)


func _add_empty_panel(parent: VBoxContainer, text: String) -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_theme_stylebox_override("panel", main.call("_panel_style", Color(0.04, 0.03, 0.025, 0.94), Color(0.39, 0.29, 0.19, 0.72), 1, 10))
	parent.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", TEXT_DIM)
	label.add_theme_font_size_override("font_size", 15)
	margin.add_child(label)


func _global_profile() -> Dictionary:
	var dm: Variant = DataAccess.dm()
	if dm != null and dm.has_method("get_profile"):
		var value: Variant = dm.call("get_profile")
		if typeof(value) == TYPE_DICTIONARY:
			return (value as Dictionary).duplicate(true)
	if main != null:
		var progress_manager := main.get_node_or_null("ProgressManager")
		if progress_manager != null and progress_manager.has_method("get_profile"):
			var fallback: Variant = progress_manager.call("get_profile")
			if typeof(fallback) == TYPE_DICTIONARY:
				return (fallback as Dictionary).duplicate(true)
	return {}


func _achievement_definitions() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var dm: Variant = DataAccess.dm()
	if dm == null or not dm.has_method("get_achievements"):
		return result
	var value: Variant = dm.call("get_achievements")
	var source: Variant = value
	if typeof(value) == TYPE_DICTIONARY:
		var wrapper: Dictionary = value
		if wrapper.has("achievements"):
			source = wrapper["achievements"]
		elif wrapper.has("items"):
			source = wrapper["items"]
		else:
			for raw_id in wrapper.keys():
				if typeof(wrapper[raw_id]) != TYPE_DICTIONARY:
					continue
				var mapped: Dictionary = (wrapper[raw_id] as Dictionary).duplicate(true)
				mapped["id"] = str(mapped.get("id", raw_id))
				result.append(mapped)
			return result
	if typeof(source) == TYPE_ARRAY:
		for item_value in source as Array:
			if typeof(item_value) == TYPE_DICTIONARY:
				result.append((item_value as Dictionary).duplicate(true))
	return result


func _catalog_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var dm: Variant = DataAccess.dm()
	if dm == null or not dm.has_method("get_shop_catalog"):
		return result
	var value: Variant = dm.call("get_shop_catalog")
	var source: Variant = value
	if typeof(value) == TYPE_DICTIONARY:
		var wrapper: Dictionary = value
		if wrapper.has("items"):
			source = wrapper["items"]
		elif wrapper.has("catalog"):
			source = wrapper["catalog"]
		else:
			for raw_id in wrapper.keys():
				if typeof(wrapper[raw_id]) != TYPE_DICTIONARY:
					continue
				var mapped: Dictionary = (wrapper[raw_id] as Dictionary).duplicate(true)
				mapped["id"] = str(mapped.get("id", raw_id))
				result.append(mapped)
			return result
	if typeof(source) == TYPE_ARRAY:
		for item_value in source as Array:
			if typeof(item_value) == TYPE_DICTIONARY:
				result.append((item_value as Dictionary).duplicate(true))
	return result


func _profile_statistics(profile: Dictionary) -> Dictionary:
	var value: Variant = profile.get("statistics", profile.get("stats", {}))
	return (value as Dictionary).duplicate(true) if typeof(value) == TYPE_DICTIONARY else {}


func _id_set(value: Variant) -> Dictionary:
	var result := {}
	if typeof(value) == TYPE_ARRAY:
		for item in value as Array:
			if typeof(item) == TYPE_DICTIONARY:
				var entry: Dictionary = item
				var item_id := str(entry.get("id", entry.get("achievement_id", entry.get("item_id", ""))))
				if not item_id.is_empty():
					result[item_id] = true
			else:
				var item_id := str(item)
				if not item_id.is_empty():
					result[item_id] = true
	elif typeof(value) == TYPE_DICTIONARY:
		for raw_id in (value as Dictionary).keys():
			var state: Variant = (value as Dictionary)[raw_id]
			if typeof(state) != TYPE_BOOL or bool(state):
				result[str(raw_id)] = true
	return result


func _count_known_unlocked(definitions: Array[Dictionary], unlocked: Dictionary) -> int:
	var count := 0
	for achievement in definitions:
		if unlocked.has(str(achievement.get("id", ""))):
			count += 1
	return count


func _achievement_progress(achievement: Dictionary, stats: Dictionary) -> Dictionary:
	if main != null:
		var progress_manager := main.get_node_or_null("ProgressManager")
		if progress_manager != null and progress_manager.has_method("get_achievement_progress"):
			var progress_value: Variant = progress_manager.call("get_achievement_progress", str(achievement.get("id", "")))
			if typeof(progress_value) == TYPE_DICTIONARY:
				var backend_progress := progress_value as Dictionary
				if backend_progress.has("current") and backend_progress.has("target"):
					var current_number := float(backend_progress.get("current", 0.0))
					var target_number := float(backend_progress.get("target", 0.0))
					var metric := ""
					var conditions_value: Variant = achievement.get("conditions", [])
					if typeof(conditions_value) == TYPE_ARRAY and not (conditions_value as Array).is_empty():
						var first_condition: Variant = (conditions_value as Array)[0]
						if typeof(first_condition) == TYPE_DICTIONARY:
							metric = str((first_condition as Dictionary).get("metric", ""))
					var is_time_metric := metric.contains("play_seconds") or metric.ends_with("seconds")
					var progress_text := "%s / %s" % [_format_duration(current_number), _format_duration(target_number)] if is_time_metric else "%s / %s" % [_compact_number(current_number), _compact_number(target_number)]
					return {"value": current_number, "target": target_number, "text": progress_text}
	var condition: Dictionary = {}
	for key in ["condition", "requirement", "criteria"]:
		var value: Variant = achievement.get(key, {})
		if typeof(value) == TYPE_DICTIONARY:
			condition = value
			break
	if condition.is_empty():
		var conditions_value: Variant = achievement.get("conditions", [])
		if typeof(conditions_value) == TYPE_ARRAY and not (conditions_value as Array).is_empty():
			var first: Variant = (conditions_value as Array)[0]
			if typeof(first) == TYPE_DICTIONARY:
				condition = first
	var stat_id := str(condition.get("stat", condition.get("statistic", condition.get("metric", achievement.get("stat", achievement.get("statistic", ""))))))
	if stat_id.is_empty():
		return {}
	var stat_key := str(condition.get("key", condition.get("id", condition.get("subject", ""))))
	if not stat_key.is_empty() and not stat_id.ends_with("." + stat_key):
		stat_id += "." + stat_key
	var target := float(condition.get("target", condition.get("threshold", condition.get("value", achievement.get("target", achievement.get("threshold", 0.0))))))
	if target <= 0.0:
		return {}
	var current_value := _numeric_stat(stats, stat_id)
	var is_time := stat_id.contains("play_seconds") or stat_id.ends_with("seconds")
	var text := "%s / %s" % [_format_duration(current_value), _format_duration(target)] if is_time else "%s / %s" % [_compact_number(current_value), _compact_number(target)]
	return {"value": current_value, "target": target, "text": text}


func _numeric_stat(stats: Dictionary, stat_id: String) -> float:
	var current: Variant = stats
	for part in stat_id.split(".", false):
		if typeof(current) != TYPE_DICTIONARY:
			return 0.0
		current = (current as Dictionary).get(part, 0)
	match typeof(current):
		TYPE_INT, TYPE_FLOAT:
			return float(current)
		TYPE_ARRAY, TYPE_DICTIONARY:
			return float(current.size())
		TYPE_BOOL:
			return 1.0 if bool(current) else 0.0
	return 0.0


func _first_dictionary(source: Dictionary, keys: Array) -> Dictionary:
	for key in keys:
		var value: Variant = source.get(key, {})
		if typeof(value) == TYPE_DICTIONARY:
			return (value as Dictionary).duplicate(true)
	return {}


func _largest_key(values: Dictionary) -> String:
	var result := ""
	var maximum := -INF
	for raw_key in values.keys():
		var value := float(values[raw_key]) if typeof(values[raw_key]) in [TYPE_INT, TYPE_FLOAT] else 0.0
		if value > maximum:
			maximum = value
			result = str(raw_key)
	return result


func _visited_count(value: Variant) -> int:
	if typeof(value) == TYPE_DICTIONARY:
		var count := 0
		for raw_value in (value as Dictionary).values():
			if typeof(raw_value) in [TYPE_INT, TYPE_FLOAT] and float(raw_value) > 0.0:
				count += 1
			elif typeof(raw_value) == TYPE_BOOL and bool(raw_value):
				count += 1
		return count
	if typeof(value) == TYPE_ARRAY:
		return (value as Array).size()
	if typeof(value) in [TYPE_INT, TYPE_FLOAT]:
		return int(value)
	return 0


func _collection_category(item: Dictionary) -> String:
	var category := str(item.get("category", item.get("categoria", item.get("type", "")))).to_lower().strip_edges()
	if category in ["collectible", "collectibles", "extra", "extras", "coleccionable", "coleccionables", "music", "gallery", "galeria", "galería"]:
		return "collectible"
	if category in ["cosmetic", "cosmetics", "decoration", "decoracion", "decoración", "cosmetico", "cosmético", "cosmeticos", "cosméticos"]:
		return "cosmetic"
	return ""


func _format_duration(seconds_value: float) -> String:
	var total := maxi(0, int(seconds_value))
	var hours := int(total / 3600)
	var minutes := int((total % 3600) / 60)
	var seconds := total % 60
	if hours > 0:
		return "%d h %02d min" % [hours, minutes]
	if minutes > 0:
		return "%d min %02d s" % [minutes, seconds]
	return "%d s" % seconds


func _compact_number(value: float) -> String:
	return str(int(value)) if is_equal_approx(value, roundf(value)) else "%.1f" % value


func _format_stat_value(value: Variant) -> String:
	if typeof(value) == TYPE_DICTIONARY:
		var parts := PackedStringArray()
		var keys: Array = (value as Dictionary).keys()
		keys.sort()
		for raw_key in keys:
			parts.append("%s: %s" % [_display_identifier(str(raw_key)), _format_scalar((value as Dictionary)[raw_key])])
		return " · ".join(parts) if not parts.is_empty() else "—"
	if typeof(value) == TYPE_ARRAY:
		var parts := PackedStringArray()
		for item in value as Array:
			parts.append(_display_identifier(str(item)))
		return ", ".join(parts) if not parts.is_empty() else "—"
	if typeof(value) == TYPE_BOOL:
		return "Sí" if bool(value) else "No"
	return str(value) if not str(value).is_empty() else "—"


func _display_identifier(identifier: String) -> String:
	if identifier.is_empty():
		return "—"
	if character_index.has(identifier):
		return _character_display_from_id(identifier)
	var aliases := {
		"naranjal_del_rio": "Naranjal del Río",
		"triana": "Triana",
		"monte_del_toro": "Monte del Toro",
		"pc": "PC",
		"web": "Web",
		"android": "Android",
		"windows": "Windows",
		"linux": "Linux",
		"macos": "macOS"
	}
	return str(aliases.get(identifier.to_lower(), _humanize(identifier)))


func _extras_grid_columns() -> int:
	var width := get_viewport().get_visible_rect().size.x
	return 1 if width < 660.0 else 2


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
	var viewport_size := get_viewport().get_visible_rect().size
	var portrait := viewport_size.y > viewport_size.x
	var extras_grid := page_host.find_child("ExtrasOptionsGrid050", true, false) as GridContainer if page_host != null else null
	if extras_grid != null:
		extras_grid.columns = 1 if viewport_size.x < 660.0 else 2
	var click_grid := settings_screen.find_child("ClickSoundGrid060", true, false) as GridContainer if settings_screen != null else null
	if click_grid != null:
		click_grid.columns = 1 if viewport_size.x < 540.0 else (2 if portrait or viewport_size.x < 920.0 else 3)
	if settings_panel != null:
		if portrait:
			settings_panel.anchor_left = 0.025
			settings_panel.anchor_top = 0.025
			settings_panel.anchor_right = 0.975
			settings_panel.anchor_bottom = 0.975
		else:
			settings_panel.anchor_left = 0.12
			settings_panel.anchor_top = 0.08
			settings_panel.anchor_right = 0.88
			settings_panel.anchor_bottom = 0.92
		settings_panel.offset_left = 0.0
		settings_panel.offset_top = 0.0
		settings_panel.offset_right = 0.0
		settings_panel.offset_bottom = 0.0
