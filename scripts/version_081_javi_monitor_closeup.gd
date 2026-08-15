extends Node

const Story = preload("res://scripts/story.gd")
const PolygonHotspot = preload("res://scripts/polygon_hotspot.gd")

const JAVI_BACKGROUND_ID := "habitacion_javi"
const CLOSEUP_BACKGROUND_PATH := "res://assets/backgrounds/pantalla-javi-naranjal.png"
const PIXEL_ADVENTURE_URL := "https://javidei.github.io/pixel-adventure/"
const BACK_ICON_PATH := "res://assets/ui/icons/arrow-left.svg"

# Áreas normalizadas sobre las imágenes originales. Se han ajustado siguiendo
# las zonas marcadas por el usuario: en la habitación solo el conjunto de
# monitores/escritorio de la izquierda y, en el primer plano, únicamente la
# superficie de la pantalla derecha. El hit-test es poligonal, no rectangular.
const ROOM_MONITORS_POLYGON := [
	Vector2(0.0254, 0.3701),
	Vector2(0.0037, 0.4426),
	Vector2(0.0005, 0.6534),
	Vector2(0.0291, 0.7701),
	Vector2(0.1826, 0.7635),
	Vector2(0.2970, 0.7023),
	Vector2(0.2949, 0.4642),
	Vector2(0.2705, 0.4068),
	Vector2(0.1652, 0.3428),
	Vector2(0.0609, 0.3381),
]
const CLOSEUP_RIGHT_MONITOR_POLYGON := [
	Vector2(0.8279, 0.3933),
	Vector2(0.4881, 0.3952),
	Vector2(0.4790, 0.5500),
	Vector2(0.4854, 0.6822),
	Vector2(0.5061, 0.6964),
	Vector2(0.5661, 0.6822),
	Vector2(0.6102, 0.6945),
	Vector2(0.8290, 0.6954),
	Vector2(0.8354, 0.4924),
]

var main: Control
var game_screen: Control
var game_background: TextureRect
var interaction_patch: Node

var room_hotspot: Control
var closeup_overlay: Control
var closeup_background: TextureRect
var right_monitor_hotspot: Control
var back_button: Button

var closeup_active := false
var _main_unhandled_was_enabled := false
var _interaction_unhandled_was_enabled := false


func _ready() -> void:
	for _i in range(12):
		await get_tree().process_frame
	main = get_parent() as Control
	if main == null:
		return
	game_screen = main.get("game_screen") as Control
	game_background = main.get("game_background") as TextureRect
	interaction_patch = main.get_node_or_null("Version045InteractionMenuPatch")
	if game_screen == null or game_background == null:
		return
	_build_room_hotspot()
	_build_closeup()
	get_viewport().size_changed.connect(_queue_layout)
	_queue_layout()


func _process(_delta: float) -> void:
	if main == null or game_screen == null:
		return
	if closeup_active:
		# Si otra pantalla fuerza un cambio de escena mientras el primer plano está
		# abierto, lo cerramos sin alterar el estado narrativo ni la música.
		if not game_screen.visible or str(main.get("current_background")) != JAVI_BACKGROUND_ID:
			_close_closeup()
		return
	if room_hotspot != null:
		room_hotspot.visible = _is_javi_room_active()


func _build_room_hotspot() -> void:
	room_hotspot = PolygonHotspot.new() as Control
	room_hotspot.name = "JaviRoomMonitorsHotspot081"
	room_hotspot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	room_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	room_hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	room_hotspot.z_index = 24
	room_hotspot.visible = false
	room_hotspot.gui_input.connect(_on_room_monitors_input)
	game_screen.add_child(room_hotspot)


func _build_closeup() -> void:
	closeup_overlay = Control.new()
	closeup_overlay.name = "JaviMonitorCloseup081"
	closeup_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	closeup_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	closeup_overlay.z_index = 320
	closeup_overlay.visible = false
	game_screen.add_child(closeup_overlay)

	closeup_background = TextureRect.new()
	closeup_background.name = "JaviMonitorCloseupBackground081"
	closeup_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	closeup_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	closeup_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	closeup_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	closeup_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(CLOSEUP_BACKGROUND_PATH):
		closeup_background.texture = ResourceLoader.load(CLOSEUP_BACKGROUND_PATH) as Texture2D
	closeup_overlay.add_child(closeup_background)

	right_monitor_hotspot = PolygonHotspot.new() as Control
	right_monitor_hotspot.name = "PixelAdventureMonitorHotspot081"
	right_monitor_hotspot.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	right_monitor_hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
	right_monitor_hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	right_monitor_hotspot.z_index = 2
	right_monitor_hotspot.gui_input.connect(_on_right_monitor_input)
	closeup_overlay.add_child(right_monitor_hotspot)

	back_button = main.call("_make_small_button", "Volver") as Button
	back_button.name = "JaviMonitorBackButton081"
	back_button.custom_minimum_size = Vector2(126, 46)
	back_button.focus_mode = Control.FOCUS_ALL
	if ResourceLoader.exists(BACK_ICON_PATH):
		back_button.icon = ResourceLoader.load(BACK_ICON_PATH) as Texture2D
		back_button.expand_icon = true
		back_button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		back_button.add_theme_constant_override("icon_max_width", 17)
		back_button.add_theme_constant_override("h_separation", 7)
	back_button.pressed.connect(_close_closeup)
	closeup_overlay.add_child(back_button)


func _on_room_monitors_input(event: InputEvent) -> void:
	if not _is_primary_press(event):
		return
	room_hotspot.accept_event()
	_open_closeup()


func _on_right_monitor_input(event: InputEvent) -> void:
	if not _is_primary_press(event):
		return
	right_monitor_hotspot.accept_event()
	_open_pixel_adventure()


func _is_primary_press(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		return (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and (event as InputEventMouseButton).pressed
	if event is InputEventScreenTouch:
		return (event as InputEventScreenTouch).pressed
	return false


func _open_closeup() -> void:
	if closeup_active or closeup_overlay == null or closeup_background == null:
		return
	if closeup_background.texture == null:
		if main != null:
			main.call("_show_toast", "No se ha podido abrir la vista de los monitores")
		return
	closeup_active = true
	if room_hotspot != null:
		room_hotspot.visible = false
	closeup_overlay.visible = true
	_disable_story_advance()
	_apply_layout()
	if back_button != null:
		back_button.grab_focus()


func _close_closeup() -> void:
	if not closeup_active:
		if closeup_overlay != null:
			closeup_overlay.visible = false
		return
	closeup_active = false
	if closeup_overlay != null:
		closeup_overlay.visible = false
	_restore_story_advance()
	if room_hotspot != null:
		room_hotspot.visible = _is_javi_room_active()


func _disable_story_advance() -> void:
	if main != null:
		_main_unhandled_was_enabled = main.is_processing_unhandled_input()
		main.set_process_unhandled_input(false)
	if interaction_patch != null:
		_interaction_unhandled_was_enabled = interaction_patch.is_processing_unhandled_input()
		interaction_patch.set_process_unhandled_input(false)


func _restore_story_advance() -> void:
	if main != null:
		main.set_process_unhandled_input(_main_unhandled_was_enabled)
	if interaction_patch != null:
		interaction_patch.set_process_unhandled_input(_interaction_unhandled_was_enabled)


func _open_pixel_adventure() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.open('" + PIXEL_ADVENTURE_URL + "', '_blank', 'noopener,noreferrer');", true)
		return
	OS.shell_open(PIXEL_ADVENTURE_URL)


func _is_javi_room_active() -> bool:
	if main == null or game_screen == null or not game_screen.visible or closeup_active:
		return false
	if str(main.get("current_background")) != JAVI_BACKGROUND_ID:
		return false
	var raw_state: Variant = main.get("state")
	if typeof(raw_state) != TYPE_DICTIONARY:
		return false
	var node_id := str((raw_state as Dictionary).get("node_id", ""))
	return not node_id.is_empty() and Story.character_for_node(node_id) == "javi"


func _queue_layout() -> void:
	call_deferred("_apply_layout")


func _apply_layout() -> void:
	if game_screen == null:
		return
	if room_hotspot != null and game_background != null:
		_set_hotspot_from_image_polygon(room_hotspot, game_background, ROOM_MONITORS_POLYGON)
	if right_monitor_hotspot != null and closeup_background != null:
		_set_hotspot_from_image_polygon(right_monitor_hotspot, closeup_background, CLOSEUP_RIGHT_MONITOR_POLYGON)
	if back_button != null:
		var viewport := get_viewport().get_visible_rect().size
		var compact := viewport.x < 760.0 or viewport.y > viewport.x
		back_button.set_anchors_preset(Control.PRESET_TOP_LEFT)
		back_button.offset_left = 14.0 if compact else 20.0
		back_button.offset_top = 14.0 if compact else 20.0
		back_button.offset_right = back_button.offset_left + (112.0 if compact else 126.0)
		back_button.offset_bottom = back_button.offset_top + (42.0 if compact else 46.0)


func _set_hotspot_from_image_polygon(hotspot: Control, texture_rect: TextureRect, normalized_points: Array) -> void:
	if hotspot == null or texture_rect == null or texture_rect.texture == null:
		return
	var container_rect := texture_rect.get_global_rect()
	var texture_size := texture_rect.texture.get_size()
	if container_rect.size.x <= 0.0 or container_rect.size.y <= 0.0 or texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var scale := maxf(container_rect.size.x / texture_size.x, container_rect.size.y / texture_size.y)
	var drawn_size := texture_size * scale
	var drawn_origin := container_rect.position + (container_rect.size - drawn_size) * 0.5
	var hotspot_origin := hotspot.get_global_rect().position
	var local_points := PackedVector2Array()
	for raw_point in normalized_points:
		var point: Vector2 = raw_point
		var global_point := drawn_origin + Vector2(point.x * drawn_size.x, point.y * drawn_size.y)
		local_points.append(global_point - hotspot_origin)
	hotspot.call("set_hit_polygon", local_points)


func is_closeup_open() -> bool:
	return closeup_active


func get_pixel_adventure_url() -> String:
	return PIXEL_ADVENTURE_URL


func get_closeup_background_path() -> String:
	return CLOSEUP_BACKGROUND_PATH
