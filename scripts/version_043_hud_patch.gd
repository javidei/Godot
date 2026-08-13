extends Node

const Story = preload("res://scripts/story.gd")

const RELEASE_VERSION := "0.4.5"
const MUTE_ICON_PATH := "res://assets/ui/icons/mute.svg"
const MAP_ICON_PATH := "res://assets/ui/icons/arrow-left.svg"
const DESKTOP_BREAKPOINT := 1000.0

var main: Control
var game_screen: Control
var dialogue_panel: PanelContainer
var version_manager: Node
var hud_panel: PanelContainer
var hud_box: VBoxContainer
var utility_row: HBoxContainer
var menu_button: Button
var fullscreen_button: Button
var map_button: Button
var room_panel: PanelContainer
var room_music_icon: TextureRect
var room_label: Label
var room_mute: Button
var save_button: Button
var load_button: Button


func _ready() -> void:
	for _i in range(6):
		await get_tree().process_frame
	main = get_parent() as Control
	if main == null:
		return
	game_screen = main.get("game_screen") as Control
	dialogue_panel = main.get("dialogue_panel") as PanelContainer
	version_manager = main.get_node_or_null("Version040Manager")
	_capture_existing_controls()
	_build_hud_panel()
	_move_room_music_controls()
	_hide_manual_save_load()
	_apply_layout()
	get_viewport().size_changed.connect(_queue_layout)


func _process(_delta: float) -> void:
	if main == null:
		return
	_hide_manual_save_load()
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
	margin.add_theme_constant_override("margin_left", 7)
	margin.add_theme_constant_override("margin_top", 6)
	margin.add_theme_constant_override("margin_right", 7)
	margin.add_theme_constant_override("margin_bottom", 6)
	hud_panel.add_child(margin)

	hud_box = VBoxContainer.new()
	hud_box.name = "HudContent"
	hud_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hud_box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	hud_box.add_theme_constant_override("separation", 4)
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
	map_button = main.call("_make_small_button", "") as Button
	map_button.name = "ReturnToMapButton060"
	map_button.icon = load(MAP_ICON_PATH) as Texture2D
	map_button.pressed.connect(_return_to_map)
	utility_row.add_child(map_button)
	_prepare_utility_button(map_button, "Volver al mapa y continuar esta conversación más tarde")
	map_button.text = "Mapa"
	map_button.custom_minimum_size.x = 82.0


func _prepare_utility_button(button: Button, tooltip: String) -> void:
	button.visible = true
	button.text = ""
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(44, 32)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.clip_text = true
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", 20)


func _move_room_music_controls() -> void:
	if version_manager == null or hud_box == null:
		return
	room_panel = version_manager.get("room_panel") as PanelContainer
	room_music_icon = version_manager.get("room_music_icon") as TextureRect
	room_label = version_manager.get("room_label") as Label
	room_mute = version_manager.get("room_mute") as Button
	if room_panel == null:
		return

	room_panel.reparent(hud_box)
	room_panel.name = "HudMusicRow043"
	room_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	room_panel.custom_minimum_size = Vector2(0, 32)
	room_panel.add_theme_stylebox_override("panel", main.call("_panel_style", Color(0.02, 0.013, 0.011, 0.55), Color(0.70, 0.50, 0.25, 0.58), 1, 8))

	var row := room_panel.get_child(0) as HBoxContainer
	if row != null:
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_theme_constant_override("separation", 4)
		for child in row.get_children():
			var button := child as Button
			if button != null:
				button.custom_minimum_size = Vector2(32, 28)
				button.add_theme_font_size_override("font_size", 12)

	if room_music_icon != null:
		room_music_icon.custom_minimum_size = Vector2(20, 20)
	if room_label != null:
		room_label.custom_minimum_size = Vector2(48, 28)
		room_label.add_theme_font_size_override("font_size", 12)
	if room_mute != null:
		room_mute.text = ""
		room_mute.tooltip_text = "Silenciar o activar la canción de esta habitación"
		room_mute.custom_minimum_size = Vector2(32, 28)
		room_mute.expand_icon = true
		room_mute.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		room_mute.add_theme_constant_override("icon_max_width", 17)
		room_mute.icon = load(MUTE_ICON_PATH) as Texture2D


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
	if map_button != null:
		map_button.visible = _can_return_to_map()
		map_button.text = "Mapa"
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
		_set_rect(hud_panel, 0.18, 0.61, 0.82, 0.74)
	elif compact_landscape:
		_set_rect(dialogue_panel, 0.025, 0.77, 0.715, 0.975)
		_set_rect(hud_panel, 0.725, 0.77, 0.975, 0.975)
	else:
		_set_rect(dialogue_panel, 0.028, 0.79, 0.748, 0.965)
		_set_rect(hud_panel, 0.758, 0.79, 0.975, 0.965)

	if utility_row != null:
		utility_row.add_theme_constant_override("separation", 10 if compact_landscape else 16)
	var utility_size := Vector2(40, 30) if compact_landscape else Vector2(44, 32)
	for button in [menu_button, fullscreen_button]:
		if button != null:
			button.custom_minimum_size = utility_size
	if map_button != null:
		map_button.custom_minimum_size = Vector2(72 if compact_landscape else 82, utility_size.y)

	var old_effects := main.find_child("HudEffectsRow043", true, false)
	if old_effects != null:
		old_effects.queue_free()


func _set_rect(control: Control, left: float, top: float, right: float, bottom: float) -> void:
	control.anchor_left = left
	control.anchor_top = top
	control.anchor_right = right
	control.anchor_bottom = bottom
	control.offset_left = 0.0
	control.offset_top = 0.0
	control.offset_right = 0.0
	control.offset_bottom = 0.0


func _can_return_to_map() -> bool:
	if game_screen == null or not game_screen.visible:
		return false
	var value: Variant = main.get("state")
	if typeof(value) != TYPE_DICTIONARY:
		return false
	var node_id := str((value as Dictionary).get("node_id", ""))
	return not Story.character_for_node(node_id).is_empty() and not node_id.ends_with("_outro_044")


func _return_to_map() -> void:
	var world_map := main.get_node_or_null("WorldMapManager") if main != null else null
	if world_map != null and world_map.has_method("return_to_map_from_room"):
		world_map.call("return_to_map_from_room")


func _upgrade_save_version() -> void:
	var value: Variant = main.get("state")
	if typeof(value) != TYPE_DICTIONARY:
		return
	var state: Dictionary = value
	if state.is_empty() or not bool(state.get("visit_mode", false)):
		return
	var target_version := str(ProjectSettings.get_setting("application/config/version", RELEASE_VERSION))
	if str(state.get("save_version", "")) == target_version:
		return
	state["save_version"] = target_version
	main.set("state", state)
