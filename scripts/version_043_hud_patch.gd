extends Node

const RELEASE_VERSION := "0.4.3"
const EFFECTS_ICON_PATH := "res://assets/ui/icons/effects.svg"
const MUTE_ICON_PATH := "res://assets/ui/icons/mute.svg"
const AUDIO_STEP := 0.1
const DESKTOP_BREAKPOINT := 1000.0

var main: Control
var game_screen: Control
var dialogue_panel: PanelContainer
var audio_manager: Node
var version_manager: Node
var hud_panel: PanelContainer
var hud_box: VBoxContainer
var utility_row: HBoxContainer
var effects_panel: PanelContainer
var effects_label: Label
var effects_mute: Button
var menu_button: Button
var fullscreen_button: Button
var room_panel: PanelContainer
var room_mute: Button
var save_button: Button
var load_button: Button
var last_effects_signature := ""


func _ready() -> void:
	for _i in range(6):
		await get_tree().process_frame
	main = get_parent() as Control
	if main == null:
		return
	game_screen = main.get("game_screen") as Control
	dialogue_panel = main.get("dialogue_panel") as PanelContainer
	audio_manager = main.get("audio_manager") as Node
	version_manager = main.get_node_or_null("Version040Manager")
	_capture_existing_controls()
	_build_hud_panel()
	_move_room_music_controls()
	_build_effects_controls()
	_hide_manual_save_load()
	_apply_layout()
	get_viewport().size_changed.connect(_queue_layout)


func _process(_delta: float) -> void:
	if main == null:
		return
	_hide_manual_save_load()
	_refresh_effects_controls()
	_enforce_hud_controls()
	_upgrade_save_version()


func _capture_existing_controls() -> void:
	if game_screen == null:
		return
	for node in game_screen.find_children("*", "Button", true, false):
		var button := node as Button
		if button == null:
			continue
		match button.tooltip_text:
			"Guardar partida":
				save_button = button
			"Cargar partida":
				load_button = button
			"Volver al menú":
				menu_button = button
			"Pantalla completa", "Pantalla completa / ventana":
				fullscreen_button = button
	if fullscreen_button == null:
		fullscreen_button = main.get("fullscreen_button") as Button


func _build_hud_panel() -> void:
	if game_screen == null:
		return
	hud_panel = PanelContainer.new()
	hud_panel.name = "GameHudPanel043"
	hud_panel.z_index = 44
	hud_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	hud_panel.add_theme_stylebox_override("panel", main.call("_panel_style", Color(0.035, 0.023, 0.019, 0.965), Color("d6a85f"), 2, 12))
	game_screen.add_child(hud_panel)

	var margin := MarginContainer.new()
	margin.name = "HudMargin"
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_top", 7)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_bottom", 7)
	hud_panel.add_child(margin)

	hud_box = VBoxContainer.new()
	hud_box.name = "HudContent"
	hud_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hud_box.add_theme_constant_override("separation", 5)
	margin.add_child(hud_box)

	utility_row = HBoxContainer.new()
	utility_row.name = "HudUtilityRow"
	utility_row.alignment = BoxContainer.ALIGNMENT_CENTER
	utility_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	utility_row.add_theme_constant_override("separation", 30)
	hud_box.add_child(utility_row)

	if menu_button != null:
		menu_button.reparent(utility_row)
		_prepare_utility_button(menu_button, "Volver al menú")
	if fullscreen_button != null:
		fullscreen_button.reparent(utility_row)
		_prepare_utility_button(fullscreen_button, "Pantalla completa / ventana")


func _prepare_utility_button(button: Button, tooltip: String) -> void:
	button.visible = true
	button.text = ""
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(48, 36)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.clip_text = true
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", 22)


func _move_room_music_controls() -> void:
	if version_manager == null or hud_box == null:
		return
	room_panel = version_manager.get("room_panel") as PanelContainer
	room_mute = version_manager.get("room_mute") as Button
	if room_panel == null:
		return
	room_panel.reparent(hud_box)
	room_panel.name = "HudMusicRow043"
	room_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room_panel.custom_minimum_size = Vector2(0, 38)
	room_panel.add_theme_stylebox_override("panel", main.call("_panel_style", Color(0.02, 0.013, 0.011, 0.55), Color(0.70, 0.50, 0.25, 0.58), 1, 8))
	var row := room_panel.get_child(0) as HBoxContainer
	if row != null:
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 5)
	if room_mute != null:
		room_mute.text = ""
		room_mute.tooltip_text = "Silenciar o activar la canción de esta habitación"
		room_mute.custom_minimum_size = Vector2(36, 30)
		room_mute.expand_icon = true
		room_mute.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		room_mute.add_theme_constant_override("icon_max_width", 18)
		room_mute.icon = load(MUTE_ICON_PATH) as Texture2D


func _build_effects_controls() -> void:
	if hud_box == null or audio_manager == null:
		return
	effects_panel = PanelContainer.new()
	effects_panel.name = "HudEffectsRow043"
	effects_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effects_panel.custom_minimum_size = Vector2(0, 38)
	effects_panel.add_theme_stylebox_override("panel", main.call("_panel_style", Color(0.02, 0.013, 0.011, 0.55), Color(0.70, 0.50, 0.25, 0.58), 1, 8))
	hud_box.add_child(effects_panel)

	var row := HBoxContainer.new()
	row.name = "EffectsControlsRow"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 5)
	effects_panel.add_child(row)

	var icon := TextureRect.new()
	icon.name = "EffectsIcon"
	icon.custom_minimum_size = Vector2(22, 22)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = load(EFFECTS_ICON_PATH) as Texture2D
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(icon)

	effects_label = Label.new()
	effects_label.name = "EffectsPercent043"
	effects_label.custom_minimum_size = Vector2(50, 30)
	effects_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effects_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	effects_label.add_theme_color_override("font_color", Color("f7ead8"))
	effects_label.add_theme_font_size_override("font_size", 13)
	row.add_child(effects_label)

	var down := main.call("_make_small_button", "-") as Button
	down.name = "EffectsDown043"
	_prepare_audio_button(down, "Bajar volumen de efectos")
	down.pressed.connect(_change_effects.bind(-AUDIO_STEP))
	row.add_child(down)

	var up := main.call("_make_small_button", "+") as Button
	up.name = "EffectsUp043"
	_prepare_audio_button(up, "Subir volumen de efectos")
	up.pressed.connect(_change_effects.bind(AUDIO_STEP))
	row.add_child(up)

	effects_mute = main.call("_make_small_button", "") as Button
	effects_mute.name = "EffectsMute043"
	_prepare_audio_button(effects_mute, "Silenciar o activar efectos")
	effects_mute.expand_icon = true
	effects_mute.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effects_mute.add_theme_constant_override("icon_max_width", 18)
	effects_mute.icon = load(MUTE_ICON_PATH) as Texture2D
	effects_mute.pressed.connect(_toggle_effects)
	row.add_child(effects_mute)
	_refresh_effects_controls()


func _prepare_audio_button(button: Button, tooltip: String) -> void:
	button.custom_minimum_size = Vector2(36, 30)
	button.tooltip_text = tooltip
	button.add_theme_font_size_override("font_size", 13)


func _change_effects(delta: float) -> void:
	if audio_manager == null:
		return
	audio_manager.call("adjust_effects_volume", delta)
	last_effects_signature = ""


func _toggle_effects() -> void:
	if audio_manager == null:
		return
	audio_manager.call("toggle_effects_mute")
	last_effects_signature = ""


func _refresh_effects_controls() -> void:
	if audio_manager == null or effects_label == null or effects_mute == null:
		return
	var percent := int(audio_manager.call("get_effects_volume_percent"))
	var muted := bool(audio_manager.call("is_effects_muted"))
	var signature := "%d|%s" % [percent, str(muted)]
	if signature == last_effects_signature:
		return
	effects_label.text = "%d%%" % percent
	effects_mute.modulate = Color(0.72, 0.72, 0.72, 0.72) if muted else Color.WHITE
	effects_mute.tooltip_text = "Activar efectos" if muted else "Silenciar efectos"
	last_effects_signature = signature


func _hide_manual_save_load() -> void:
	for button in [save_button, load_button]:
		if button == null:
			continue
		button.visible = false
		button.focus_mode = Control.FOCUS_NONE
		button.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _enforce_hud_controls() -> void:
	if hud_panel == null:
		return
	if menu_button != null:
		menu_button.visible = true
		menu_button.text = ""
	if fullscreen_button != null:
		fullscreen_button.visible = true
		fullscreen_button.text = ""
	if room_mute != null:
		room_mute.text = ""
		room_mute.icon = load(MUTE_ICON_PATH) as Texture2D


func _queue_layout() -> void:
	call_deferred("_apply_layout")


func _apply_layout() -> void:
	if dialogue_panel == null or hud_panel == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var portrait := viewport_size.y > viewport_size.x
	var compact_landscape := not portrait and viewport_size.x < DESKTOP_BREAKPOINT

	if portrait:
		_set_rect(dialogue_panel, 0.035, 0.755, 0.965, 0.985)
		_set_rect(hud_panel, 0.18, 0.57, 0.82, 0.745)
	elif compact_landscape:
		_set_rect(dialogue_panel, 0.025, 0.77, 0.685, 0.975)
		_set_rect(hud_panel, 0.695, 0.77, 0.975, 0.975)
	else:
		_set_rect(dialogue_panel, 0.028, 0.79, 0.748, 0.965)
		_set_rect(hud_panel, 0.758, 0.79, 0.975, 0.965)

	if utility_row != null:
		utility_row.add_theme_constant_override("separation", 24 if compact_landscape else 34)
	var utility_size := Vector2(44, 34) if compact_landscape else Vector2(48, 36)
	for button in [menu_button, fullscreen_button]:
		if button != null:
			button.custom_minimum_size = utility_size


func _set_rect(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _upgrade_save_version() -> void:
	var value: Variant = main.get("state")
	if typeof(value) != TYPE_DICTIONARY:
		return
	var state: Dictionary = value
	if state.is_empty() or not bool(state.get("visit_mode", false)):
		return
	if str(state.get("save_version", "")) == RELEASE_VERSION:
		return
	state["save_version"] = RELEASE_VERSION
	main.set("state", state)
