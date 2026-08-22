extends "res://scripts/version_063_mobile_extras_patch.gd"

var room_fullscreen_overlay: Control
var room_fullscreen_texture: TextureRect


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
	back.z_index = 1
	back.pressed.connect(_close_room_fullscreen)
	_configure_nav_button(back, "Atrás", ARROW_LEFT_ICON_PATH, false)
	room_fullscreen_overlay.add_child(back)


func _show_room_fullscreen(texture: Texture2D) -> void:
	if room_fullscreen_overlay == null or room_fullscreen_texture == null or texture == null:
		return
	room_fullscreen_texture.texture = texture
	room_fullscreen_overlay.visible = true
	room_fullscreen_overlay.move_to_front()


func _close_room_fullscreen() -> void:
	if room_fullscreen_overlay != null:
		room_fullscreen_overlay.visible = false
	if room_fullscreen_texture != null:
		room_fullscreen_texture.texture = null
