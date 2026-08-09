extends Node

const DESKTOP_FONT_SIZE := 12
const COMPACT_FONT_SIZE := 10
const COMPACT_WIDTH := 1000.0

var main: Control
var game_screen: Control
var menu_content: VBoxContainer
var dialogue_panel: PanelContainer
var topbar: HBoxContainer
var controls: Dictionary = {}


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	main = get_parent() as Control
	if main == null:
		return
	_capture_interface()
	_move_game_controls()
	_add_version_label()
	get_viewport().size_changed.connect(_queue_layout)
	call_deferred("_apply_layout")


func _capture_interface() -> void:
	game_screen = main.get("game_screen") as Control
	menu_content = main.get("menu_content") as VBoxContainer
	dialogue_panel = main.get("dialogue_panel") as PanelContainer
	topbar = main.get("topbar") as HBoxContainer


func _move_game_controls() -> void:
	if game_screen == null or topbar == null:
		return

	for child in topbar.get_children():
		if not (child is Button):
			continue
		var button := child as Button
		match button.text:
			"Guardar":
				controls["save"] = button
			"Cargar":
				controls["load"] = button
			"Menú":
				controls["menu"] = button
			"Pantalla completa", "Pantalla":
				controls["fullscreen"] = button

	for key in controls.keys():
		var button := _button(str(key))
		if button == null:
			continue
		button.reparent(game_screen)
		button.z_index = 42
		button.focus_mode = Control.FOCUS_ALL
		button.custom_minimum_size = Vector2.ZERO

	var save_button := _button("save")
	var load_button := _button("load")
	var menu_button := _button("menu")
	var screen_button := _button("fullscreen")
	if save_button != null:
		save_button.tooltip_text = "Guardar partida"
	if load_button != null:
		load_button.tooltip_text = "Cargar partida"
	if menu_button != null:
		menu_button.tooltip_text = "Volver al menú"
	if screen_button != null:
		screen_button.tooltip_text = "Pantalla completa"


func _add_version_label() -> void:
	if menu_content == null:
		return
	if menu_content.get_node_or_null("VersionLabel") != null:
		return
	var version := str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	var label := Label.new()
	label.name = "VersionLabel"
	label.text = "Versión " + version
	label.add_theme_color_override("font_color", Color(0.68, 0.63, 0.57, 0.9))
	label.add_theme_font_size_override("font_size", 11)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_content.add_child(label)


func _queue_layout() -> void:
	call_deferred("_apply_layout")


func _apply_layout() -> void:
	if dialogue_panel == null or controls.is_empty():
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var compact := viewport_size.x < COMPACT_WIDTH
	var is_portrait := viewport_size.y > viewport_size.x

	if is_portrait:
		_apply_portrait_fallback(compact)
		return

	var outer_margin := 0.012
	var gap_x := 0.008
	var gap_y := 0.012
	var panel_left := dialogue_panel.anchor_left
	var panel_right := dialogue_panel.anchor_right
	var panel_top := dialogue_panel.anchor_top
	var panel_bottom := dialogue_panel.anchor_bottom
	var middle_y := (panel_top + panel_bottom) * 0.5

	var left_right: float = max(outer_margin + 0.035, panel_left - gap_x)
	var right_left: float = min(1.0 - outer_margin - 0.035, panel_right + gap_x)

	_place_button("save", outer_margin, panel_top, left_right, middle_y - gap_y * 0.5)
	_place_button("load", outer_margin, middle_y + gap_y * 0.5, left_right, panel_bottom)
	_place_button("menu", right_left, panel_top, 1.0 - outer_margin, middle_y - gap_y * 0.5)
	_place_button("fullscreen", right_left, middle_y + gap_y * 0.5, 1.0 - outer_margin, panel_bottom)

	_apply_button_labels(compact)


func _apply_portrait_fallback(compact: bool) -> void:
	# En web móvil el shell muestra una pantalla de "gira el dispositivo".
	# Este fallback mantiene los controles accesibles en otros destinos.
	_place_button("save", 0.03, 0.02, 0.24, 0.08)
	_place_button("load", 0.26, 0.02, 0.47, 0.08)
	_place_button("menu", 0.53, 0.02, 0.72, 0.08)
	_place_button("fullscreen", 0.74, 0.02, 0.97, 0.08)
	_apply_button_labels(compact)


func _apply_button_labels(compact: bool) -> void:
	var save_button := _button("save")
	var load_button := _button("load")
	var menu_button := _button("menu")
	var screen_button := _button("fullscreen")

	if save_button != null:
		save_button.text = "G" if compact else "Guardar"
	if load_button != null:
		load_button.text = "C" if compact else "Cargar"
	if menu_button != null:
		menu_button.text = "M" if compact else "Menú"
	if screen_button != null:
		screen_button.text = "P" if compact else "Pantalla"

	for key in controls.keys():
		var button := _button(str(key))
		if button != null:
			button.add_theme_font_size_override("font_size", COMPACT_FONT_SIZE if compact else DESKTOP_FONT_SIZE)


func _place_button(key: String, left: float, top: float, right: float, bottom: float) -> void:
	var button := _button(key)
	if button == null:
		return
	button.anchor_left = left
	button.anchor_top = top
	button.anchor_right = right
	button.anchor_bottom = bottom
	button.offset_left = 0.0
	button.offset_top = 0.0
	button.offset_right = 0.0
	button.offset_bottom = 0.0


func _button(key: String) -> Button:
	return controls.get(key) as Button
