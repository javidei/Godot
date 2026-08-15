extends Node

const Story090 = preload("res://scripts/story.gd")
const DataAccess090 = preload("res://scripts/data_access.gd")

var main: Control
var data_manager: Node
var menu_content: VBoxContainer

var roster_button: Button
var roster_overlay: Control
var roster_panel: PanelContainer
var roster_grid: GridContainer
var roster_preview: Label
var roster_apply: Button
var roster_checks: Dictionary = {}
var pending_ids: Array[String] = []


func _ready() -> void:
	if _legacy_contract():
		return
	for _i in range(40):
		await get_tree().process_frame
	main = get_parent() as Control
	data_manager = DataAccess090.dm() as Node
	if main == null or data_manager == null:
		return
	data_manager.call("ensure_loaded")
	menu_content = main.get("menu_content") as VBoxContainer
	pending_ids = _runtime_ids()
	_build_menu_button()
	_build_roster_overlay()
	apply_story_runtime(pending_ids, _runtime_day(), true)


func _legacy_contract() -> bool:
	return str(ProjectSettings.get_setting("application/config/version", "")).begins_with("0.6.")


func _runtime_ids() -> Array[String]:
	if data_manager != null and data_manager.has_method("get_runtime_active_characters"):
		var raw: Variant = data_manager.call("get_runtime_active_characters")
		if typeof(raw) == TYPE_ARRAY:
			var result: Array[String] = []
			for raw_id in raw as Array:
				var character_id := str(raw_id)
				if not character_id.is_empty() and not result.has(character_id):
					result.append(character_id)
			if not result.is_empty():
				return result
	return _all_ids()


func _all_ids() -> Array[String]:
	if data_manager == null:
		return []
	var raw: Variant = data_manager.call("get_all_character_ids", true) if data_manager.has_method("get_all_character_ids") else data_manager.call("get_character_ids", true)
	var result: Array[String] = []
	if typeof(raw) == TYPE_ARRAY:
		for raw_id in raw as Array:
			var character_id := str(raw_id)
			if not character_id.is_empty() and not result.has(character_id):
				result.append(character_id)
	return result


func _runtime_day() -> int:
	if data_manager != null and data_manager.has_method("get_runtime_narrative_day"):
		return int(data_manager.call("get_runtime_narrative_day"))
	if data_manager != null and data_manager.has_method("get_default_narrative_day"):
		return int(data_manager.call("get_default_narrative_day"))
	return 1


func _build_menu_button() -> void:
	if menu_content == null or roster_button != null:
		return
	roster_button = main.call("_make_button", "Personajes de la historia", false) as Button
	roster_button.name = "StoryRosterButton090"
	roster_button.tooltip_text = "Elegir qué personajes aparecerán en la próxima partida"
	roster_button.custom_minimum_size = Vector2(0, 48)
	roster_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_button.add_theme_font_size_override("font_size", 15)
	roster_button.pressed.connect(open_roster)
	menu_content.add_child(roster_button)
	var audio_title := menu_content.find_child("AudioSettingsTitle", true, false) as Label
	if audio_title != null:
		menu_content.move_child(roster_button, audio_title.get_index())
	_bind_click(roster_button)


func _build_roster_overlay() -> void:
	if main == null or roster_overlay != null:
		return
	roster_overlay = Control.new()
	roster_overlay.name = "StoryRosterOverlay090"
	roster_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	roster_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	roster_overlay.z_index = 930
	roster_overlay.visible = false
	main.add_child(roster_overlay)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.008, 0.007, 0.006, 0.94)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	roster_overlay.add_child(shade)

	roster_panel = PanelContainer.new()
	roster_panel.name = "StoryRosterPanel090"
	roster_panel.anchor_left = 0.14
	roster_panel.anchor_top = 0.08
	roster_panel.anchor_right = 0.86
	roster_panel.anchor_bottom = 0.92
	roster_panel.add_theme_stylebox_override("panel", main.call("_panel_style", Color(0.035, 0.025, 0.020, 0.99), Color("d6a85f"), 2, 16))
	roster_overlay.add_child(roster_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	roster_panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	margin.add_child(root)

	var title := Label.new()
	title.text = "PERSONAJES DE LA HISTORIA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("f2c97e"))
	title.add_theme_font_size_override("font_size", 28)
	root.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Marca los personajes que podrán aparecer y ser elegidos como protagonista en la próxima partida. Debe quedar al menos uno."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", Color("d8c8b2"))
	subtitle.add_theme_font_size_override("font_size", 14)
	root.add_child(subtitle)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)

	roster_grid = GridContainer.new()
	roster_grid.name = "StoryRosterGrid090"
	roster_grid.columns = 2
	roster_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_grid.add_theme_constant_override("h_separation", 12)
	roster_grid.add_theme_constant_override("v_separation", 10)
	scroll.add_child(roster_grid)

	for character_id in _all_ids():
		var character: Dictionary = data_manager.call("get_character", character_id)
		var check := CheckButton.new()
		check.name = "StoryRosterCheck_" + character_id
		check.text = str(character.get("display_name", character.get("name", character_id.capitalize())))
		check.button_pressed = pending_ids.has(character_id)
		check.custom_minimum_size = Vector2(0, 48)
		check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		check.add_theme_font_size_override("font_size", 16)
		check.toggled.connect(_on_character_toggled.bind(character_id))
		roster_checks[character_id] = check
		roster_grid.add_child(check)

	roster_preview = Label.new()
	roster_preview.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	roster_preview.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	roster_preview.add_theme_color_override("font_color", Color("f2c97e"))
	roster_preview.add_theme_font_size_override("font_size", 16)
	root.add_child(roster_preview)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 10)
	root.add_child(actions)

	var all_button := main.call("_make_button", "Marcar todos", false) as Button
	all_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	all_button.pressed.connect(_select_all)
	actions.add_child(all_button)
	_bind_click(all_button)

	var cancel := main.call("_make_button", "Cancelar", false) as Button
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(close_roster)
	actions.add_child(cancel)
	_bind_click(cancel)

	roster_apply = main.call("_make_button", "Aplicar", true) as Button
	roster_apply.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_apply.pressed.connect(_apply_roster)
	actions.add_child(roster_apply)
	_bind_click(roster_apply)

	get_viewport().size_changed.connect(_apply_layout)
	_apply_layout()
	_refresh_roster_preview()


func open_roster() -> void:
	if roster_overlay == null:
		return
	pending_ids = _runtime_ids()
	for character_id in roster_checks.keys():
		var check := roster_checks[character_id] as CheckButton
		if check != null:
			check.set_pressed_no_signal(pending_ids.has(str(character_id)))
	_refresh_roster_preview()
	roster_overlay.visible = true


func close_roster() -> void:
	if roster_overlay != null:
		roster_overlay.visible = false


func _on_character_toggled(enabled: bool, character_id: String) -> void:
	if enabled:
		if not pending_ids.has(character_id):
			pending_ids.append(character_id)
	else:
		pending_ids.erase(character_id)
	_refresh_roster_preview()


func _select_all() -> void:
	pending_ids = _all_ids()
	for character_id in roster_checks.keys():
		var check := roster_checks[character_id] as CheckButton
		if check != null:
			check.set_pressed_no_signal(true)
	_refresh_roster_preview()


func _apply_roster() -> void:
	if pending_ids.is_empty():
		if main != null:
			main.call("_show_toast", "Debe quedar al menos un personaje")
		return
	apply_story_runtime(pending_ids, 1, true)
	close_roster()
	if main != null:
		main.call("_show_toast", "Personajes preparados para la próxima partida")


func apply_story_runtime(character_ids: Array, day_id: int, update_title: bool = true) -> void:
	if data_manager == null:
		data_manager = DataAccess090.dm() as Node
	if data_manager == null:
		return
	if data_manager.has_method("set_runtime_active_characters"):
		data_manager.call("set_runtime_active_characters", character_ids)
	if data_manager.has_method("set_runtime_narrative_day"):
		data_manager.call("set_runtime_narrative_day", day_id)
	Story090.refresh()
	_repatch_story()
	if update_title:
		_update_dynamic_title()
	var selection := main.get_node_or_null("CharacterSelectManager") if main != null else null
	if selection != null and selection.has_method("refresh_roster_visibility"):
		selection.call_deferred("refresh_roster_visibility")


func sync_from_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	var active: Variant = state.get("active_characters", [])
	var ids: Array = active if typeof(active) == TYPE_ARRAY else _all_ids()
	var day_id := 1
	var progress: Variant = state.get("narrative_progress", {})
	if typeof(progress) == TYPE_DICTIONARY:
		day_id = int((progress as Dictionary).get("current_day", 1))
	apply_story_runtime(ids, day_id, true)
	pending_ids = _runtime_ids()


func _repatch_story() -> void:
	if main == null:
		return
	var visit_manager := main.get_node_or_null("Version040Manager")
	if visit_manager != null and visit_manager.has_method("_patch_story"):
		visit_manager.call("_patch_story")
	var transitions := main.get_node_or_null("Version044VisitTransitions")
	if transitions != null and transitions.has_method("_ensure_story_patches"):
		transitions.call("_ensure_story_patches")


func _update_dynamic_title() -> void:
	var title := Story090.game_title()
	ProjectSettings.set_setting("application/config/name", title)
	if main != null:
		main.get_window().title = title
		var label := main.find_child("GameTitle", true, false) as Label
		if label != null:
			label.text = Story090.menu_title()
	_refresh_roster_preview()


func _refresh_roster_preview() -> void:
	if roster_preview == null:
		return
	var count := pending_ids.size()
	if count <= 0:
		roster_preview.text = "Selecciona al menos un personaje."
		if roster_apply != null:
			roster_apply.disabled = true
		return
	roster_preview.text = "%d personaje%s · %s" % [count, "" if count == 1 else "s", Story090.title_for_character_count(count)]
	if roster_apply != null:
		roster_apply.disabled = false


func _apply_layout() -> void:
	if roster_panel == null:
		return
	var viewport := get_viewport().get_visible_rect().size
	var compact := viewport.x < 760.0 or viewport.y > viewport.x
	roster_panel.anchor_left = 0.025 if compact else 0.14
	roster_panel.anchor_right = 0.975 if compact else 0.86
	roster_panel.anchor_top = 0.025 if compact else 0.08
	roster_panel.anchor_bottom = 0.975 if compact else 0.92
	if roster_grid != null:
		roster_grid.columns = 1 if compact else 2


func _bind_click(button: Button) -> void:
	if button == null or main == null:
		return
	var manager: Variant = main.get("audio_manager")
	if manager != null and manager.has_method("bind_click"):
		manager.call("bind_click", button)
