extends "res://scripts/version_063_mobile_extras_patch.gd"

const ROOM_ZOOM_MIN := 1.0
const ROOM_ZOOM_MAX := 5.0
const ROOM_ZOOM_DOUBLE_TAP := 2.0

var room_fullscreen_overlay: Control
var room_fullscreen_texture: TextureRect
var room_zoom := ROOM_ZOOM_MIN
var room_pan := Vector2.ZERO
var room_touches: Dictionary = {}
var room_pinch_distance := 0.0
var room_pinch_center := Vector2.ZERO


func _build_extras_screen() -> void:
	super()
	_build_room_fullscreen_viewer()


func _show_places() -> void:
	super()
	_enable_room_image_selection()


func _go_back() -> void:
	if room_fullscreen_overlay != null and room_fullscreen_overlay.visible:
		_close_room_fullscreen()
		return
	super()


func _close_extras() -> void:
	_close_room_fullscreen()
	super()


func _input(event: InputEvent) -> void:
	if room_fullscreen_overlay == null or not room_fullscreen_overlay.visible:
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			room_touches[touch.index] = touch.position
			if touch.double_tap and room_touches.size() == 1:
				_toggle_room_zoom(touch.position)
		else:
			room_touches.erase(touch.index)
			room_pinch_distance = 0.0

		if room_touches.size() >= 2:
			_prime_room_pinch()
		return

	if event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		room_touches[drag.index] = drag.position
		if room_touches.size() >= 2:
			_update_room_pinch()
		elif room_zoom > ROOM_ZOOM_MIN:
			room_pan += drag.relative
			_apply_room_transform()
		return

	if event is InputEventMagnifyGesture:
		var magnify := event as InputEventMagnifyGesture
		_set_room_zoom_around(magnify.position, room_zoom * magnify.factor)
		return

	if event is InputEventPanGesture and room_zoom > ROOM_ZOOM_MIN:
		var pan := event as InputEventPanGesture
		room_pan -= pan.delta * 18.0
		_apply_room_transform()
		return

	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.pressed and mouse.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var factor := 1.15 if mouse.button_index == MOUSE_BUTTON_WHEEL_UP else (1.0 / 1.15)
			_set_room_zoom_around(mouse.position, room_zoom * factor)


func _enable_room_image_selection() -> void:
	if page_host == null:
		return
	for candidate in page_host.find_children("RoomImagePanel052", "PanelContainer", true, false):
		var image_panel := candidate as PanelContainer
		if image_panel == null:
			continue
		var image := image_panel.find_child("RoomImage052", true, false) as TextureRect
		if image == null or image.texture == null:
			continue
		var selector := Button.new()
		selector.name = "RoomImageFullscreenButton064"
		selector.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		selector.flat = true
		selector.focus_mode = Control.FOCUS_ALL
		selector.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		selector.tooltip_text = "Ver imagen a pantalla completa"
		selector.pressed.connect(_show_room_fullscreen.bind(image.texture))
		image_panel.add_child(selector)


func _build_room_fullscreen_viewer() -> void:
	if extras_screen == null or room_fullscreen_overlay != null:
		return

	room_fullscreen_overlay = Control.new()
	room_fullscreen_overlay.name = "RoomFullscreenPreview064"
	room_fullscreen_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	room_fullscreen_overlay.z_index = 80
	room_fullscreen_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	room_fullscreen_overlay.visible = false
	extras_screen.add_child(room_fullscreen_overlay)

	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color.BLACK
	background.mouse_filter = Control.MOUSE_FILTER_STOP
	room_fullscreen_overlay.add_child(background)

	room_fullscreen_texture = TextureRect.new()
	room_fullscreen_texture.name = "RoomFullscreenImage064"
	room_fullscreen_texture.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	room_fullscreen_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	room_fullscreen_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	room_fullscreen_texture.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	room_fullscreen_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room_fullscreen_overlay.add_child(room_fullscreen_texture)

	var back := main.call("_make_small_button", "Atrás") as Button
	back.name = "RoomFullscreenBack064"
	back.offset_left = 20.0
	back.offset_top = 20.0
	back.offset_right = 154.0
	back.offset_bottom = 72.0
	back.custom_minimum_size = Vector2(134, 52)
	back.z_index = 10
	back.pressed.connect(_close_room_fullscreen)
	_configure_nav_button(back, "Atrás", ARROW_LEFT_ICON_PATH, false)
	room_fullscreen_overlay.add_child(back)


func _show_room_fullscreen(texture: Texture2D) -> void:
	if room_fullscreen_overlay == null or room_fullscreen_texture == null or texture == null:
		return
	room_fullscreen_texture.texture = texture
	_reset_room_zoom()
	room_fullscreen_overlay.visible = true
	room_fullscreen_overlay.move_to_front()
	call_deferred("_apply_room_transform")


func _close_room_fullscreen() -> void:
	_reset_room_zoom()
	if room_fullscreen_overlay != null:
		room_fullscreen_overlay.visible = false
	if room_fullscreen_texture != null:
		room_fullscreen_texture.texture = null


func _toggle_room_zoom(point: Vector2) -> void:
	if room_zoom > ROOM_ZOOM_MIN + 0.01:
		room_zoom = ROOM_ZOOM_MIN
		room_pan = Vector2.ZERO
		_apply_room_transform()
	else:
		_set_room_zoom_around(point, ROOM_ZOOM_DOUBLE_TAP)


func _prime_room_pinch() -> void:
	var points := _first_two_room_touch_points()
	if points.size() < 2:
		room_pinch_distance = 0.0
		return
	room_pinch_distance = (points[0] as Vector2).distance_to(points[1] as Vector2)
	room_pinch_center = ((points[0] as Vector2) + (points[1] as Vector2)) * 0.5


func _update_room_pinch() -> void:
	var points := _first_two_room_touch_points()
	if points.size() < 2:
		room_pinch_distance = 0.0
		return

	var first := points[0] as Vector2
	var second := points[1] as Vector2
	var current_distance := first.distance_to(second)
	var current_center := (first + second) * 0.5
	if room_pinch_distance <= 0.0:
		room_pinch_distance = current_distance
		room_pinch_center = current_center
		return

	var viewport_center := room_fullscreen_texture.size * 0.5
	var old_zoom := room_zoom
	var image_point := (room_pinch_center - viewport_center - room_pan) / old_zoom
	room_zoom = clampf(old_zoom * current_distance / room_pinch_distance, ROOM_ZOOM_MIN, ROOM_ZOOM_MAX)
	room_pan = current_center - viewport_center - image_point * room_zoom
	room_pinch_distance = current_distance
	room_pinch_center = current_center
	_apply_room_transform()


func _set_room_zoom_around(point: Vector2, requested_zoom: float) -> void:
	if room_fullscreen_texture == null:
		return
	var new_zoom := clampf(requested_zoom, ROOM_ZOOM_MIN, ROOM_ZOOM_MAX)
	var viewport_center := room_fullscreen_texture.size * 0.5
	var image_point := (point - viewport_center - room_pan) / room_zoom
	room_zoom = new_zoom
	room_pan = point - viewport_center - image_point * room_zoom
	if is_equal_approx(room_zoom, ROOM_ZOOM_MIN):
		room_pan = Vector2.ZERO
	_apply_room_transform()


func _apply_room_transform() -> void:
	if room_fullscreen_texture == null:
		return
	room_fullscreen_texture.pivot_offset = room_fullscreen_texture.size * 0.5
	room_pan = _clamp_room_pan(room_pan)
	room_fullscreen_texture.scale = Vector2.ONE * room_zoom
	room_fullscreen_texture.position = room_pan


func _clamp_room_pan(value: Vector2) -> Vector2:
	if room_fullscreen_texture == null or room_fullscreen_texture.texture == null or room_zoom <= ROOM_ZOOM_MIN:
		return Vector2.ZERO

	var viewport_size := room_fullscreen_texture.size
	var texture_size := room_fullscreen_texture.texture.get_size()
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return value

	var fit := minf(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	var scaled_image := texture_size * fit * room_zoom
	var limits := Vector2(
		maxf(0.0, (scaled_image.x - viewport_size.x) * 0.5),
		maxf(0.0, (scaled_image.y - viewport_size.y) * 0.5)
	)
	return Vector2(
		clampf(value.x, -limits.x, limits.x),
		clampf(value.y, -limits.y, limits.y)
	)


func _first_two_room_touch_points() -> Array[Vector2]:
	var result: Array[Vector2] = []
	for key in room_touches.keys():
		result.append(room_touches[key] as Vector2)
		if result.size() == 2:
			break
	return result


func _reset_room_zoom() -> void:
	room_zoom = ROOM_ZOOM_MIN
	room_pan = Vector2.ZERO
	room_touches.clear()
	room_pinch_distance = 0.0
	room_pinch_center = Vector2.ZERO
	if room_fullscreen_texture != null:
		room_fullscreen_texture.scale = Vector2.ONE
		room_fullscreen_texture.position = Vector2.ZERO
