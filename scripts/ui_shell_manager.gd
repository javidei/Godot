extends Node

const DESKTOP_BUTTON_SIZE := 58.0
const COMPACT_BUTTON_SIZE := 48.0
const DESKTOP_ICON_SIZE := 28
const COMPACT_ICON_SIZE := 24
const COMPACT_WIDTH := 1000.0
const CHARACTER_DROP := 24.0
const ICON_PATHS := {
	"save": "res://assets/ui/icons/save.svg",
	"load": "res://assets/ui/icons/load.svg",
	"menu": "res://assets/ui/icons/menu.svg",
	"fullscreen": "res://assets/ui/icons/fullscreen.svg"
}

var main: Control
var game_screen: Control
var menu_content: VBoxContainer
var dialogue_panel: PanelContainer
var topbar: HBoxContainer
var stage: Control
var controls: Dictionary = {}
var menu_fullscreen_button: Button


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	main = get_parent() as Control
	if main == null:
		return
	_capture_interface()
	_move_game_controls()
	_add_menu_actions()
	_add_version_label()
	_arm_default_fullscreen()
	get_viewport().size_changed.connect(_queue_layout)
	call_deferred("_apply_layout")


func _capture_interface() -> void:
	game_screen = main.get("game_screen") as Control
	menu_content = main.get("menu_content") as VBoxContainer
	dialogue_panel = main.get("dialogue_panel") as PanelContainer
	topbar = main.get("topbar") as HBoxContainer
	stage = main.get("stage") as Control


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
		button.text = ""
		button.clip_text = true
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		var icon_path: String = str(ICON_PATHS.get(str(key), ""))
		if not icon_path.is_empty():
			button.icon = load(icon_path) as Texture2D

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
	_enforce_icon_only()


func _add_menu_actions() -> void:
	if menu_content == null:
		return

	var continue_index: int = -1
	for child in menu_content.get_children():
		if child is Button and (child as Button).text == "Continuar":
			continue_index = child.get_index()
			break

	var fullscreen_result: Variant = main.call("_make_button", "Pantalla completa", false)
	menu_fullscreen_button = fullscreen_result as Button
	if menu_fullscreen_button != null:
		menu_fullscreen_button.name = "MenuFullscreenButton"
		menu_fullscreen_button.custom_minimum_size = Vector2(0, 42)
		menu_fullscreen_button.tooltip_text = "Entrar o salir de pantalla completa"
		menu_fullscreen_button.pressed.connect(_request_fullscreen_from_menu)
		menu_content.add_child(menu_fullscreen_button)
		if continue_index >= 0:
			menu_content.move_child(menu_fullscreen_button, continue_index + 1)


func _add_version_label() -> void:
	if menu_content == null:
		return
	if menu_content.get_node_or_null("VersionLabel") != null:
		return
	var version: String = str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	var label := Label.new()
	label.name = "VersionLabel"
	label.text = "Versión " + version
	label.add_theme_color_override("font_color", Color(0.68, 0.63, 0.57, 0.9))
	label.add_theme_font_size_override("font_size", 11)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_content.add_child(label)


func _arm_default_fullscreen() -> void:
	if menu_content == null or not OS.has_feature("web"):
		return
	for child in menu_content.get_children():
		if not (child is Button):
			continue
		var button := child as Button
		if button.text == "Nueva partida" or button.text == "Continuar":
			button.button_down.connect(_request_web_fullscreen_once)


func _request_web_fullscreen_once() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("window.entreLineasRequestFullscreen && window.entreLineasRequestFullscreen();", true)


func _request_fullscreen_from_menu() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.entreLineasToggleFullscreen && window.entreLineasToggleFullscreen();", true)
	else:
		main.call("_toggle_fullscreen")


func _queue_layout() -> void:
	call_deferred("_apply_layout")


func _apply_layout() -> void:
	if dialogue_panel == null or controls.is_empty():
		return

	_enforce_icon_only()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var compact: bool = viewport_size.x < COMPACT_WIDTH
	var is_portrait: bool = viewport_size.y > viewport_size.x

	_apply_stage_drop(is_portrait)
	_apply_menu_layout(compact, is_portrait)

	if is_portrait:
		_apply_portrait_fallback(viewport_size, compact)
		return

	var button_size: float = COMPACT_BUTTON_SIZE if compact else DESKTOP_BUTTON_SIZE
	var gap: float = 8.0 if compact else 10.0
	var outer_margin: float = 12.0
	var panel_position: Vector2 = dialogue_panel.position
	var panel_size: Vector2 = dialogue_panel.size
	var stack_height: float = button_size * 2.0 + gap
	var first_y: float = clamp(panel_position.y + (panel_size.y - stack_height) * 0.5, outer_margin, viewport_size.y - outer_margin - stack_height)
	var left_x: float = max(outer_margin, panel_position.x - gap - button_size)
	var right_x: float = min(viewport_size.x - outer_margin - button_size, panel_position.x + panel_size.x + gap)

	_place_button_pixels("save", Vector2(left_x, first_y), button_size)
	_place_button_pixels("load", Vector2(left_x, first_y + button_size + gap), button_size)
	_place_button_pixels("menu", Vector2(right_x, first_y), button_size)
	_place_button_pixels("fullscreen", Vector2(right_x, first_y + button_size + gap), button_size)
	_apply_icon_sizes(compact)


func _apply_portrait_fallback(viewport_size: Vector2, compact: bool) -> void:
	var button_size: float = 44.0
	var gap: float = 8.0
	var total_width: float = button_size * 4.0 + gap * 3.0
	var start_x: float = max(8.0, (viewport_size.x - total_width) * 0.5)
	var keys: Array[String] = ["save", "load", "menu", "fullscreen"]
	for index in range(keys.size()):
		var key: String = keys[index]
		_place_button_pixels(key, Vector2(start_x + index * (button_size + gap), 10.0), button_size)
	_apply_icon_sizes(compact)


func _apply_stage_drop(is_portrait: bool) -> void:
	if stage == null:
		return
	var drop: float = 16.0 if is_portrait else CHARACTER_DROP
	stage.offset_top = drop
	stage.offset_bottom = drop


func _apply_menu_layout(compact: bool, is_portrait: bool) -> void:
	if menu_content == null:
		return
	if is_portrait:
		return
	menu_content.anchor_top = 0.08 if compact else 0.14
	menu_content.anchor_bottom = 0.96 if compact else 0.9


func _apply_icon_sizes(compact: bool) -> void:
	var icon_size: int = COMPACT_ICON_SIZE if compact else DESKTOP_ICON_SIZE
	for key in controls.keys():
		var button := _button(str(key))
		if button == null:
			continue
		button.text = ""
		button.clip_text = true
		button.add_theme_constant_override("icon_max_width", icon_size)
		button.add_theme_constant_override("h_separation", 0)


func _enforce_icon_only() -> void:
	for key in controls.keys():
		var button := _button(str(key))
		if button != null:
			button.text = ""


func _place_button_pixels(key: String, position: Vector2, side: float) -> void:
	var button := _button(key)
	if button == null:
		return
	button.anchor_left = 0.0
	button.anchor_top = 0.0
	button.anchor_right = 0.0
	button.anchor_bottom = 0.0
	button.offset_left = position.x
	button.offset_top = position.y
	button.offset_right = position.x + side
	button.offset_bottom = position.y + side
	button.custom_minimum_size = Vector2(side, side)


func _button(key: String) -> Button:
	return controls.get(key) as Button
