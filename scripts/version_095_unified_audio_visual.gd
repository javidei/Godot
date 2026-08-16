extends "res://scripts/version_090_unified_audio_manager.gd"

# Capa visual del mute: se dibuja un único TextureRect interno por botón.
# Es importante NO llamar a super() en _refresh_master_ui(), porque la versión
# anterior también asigna Button.icon y eso provoca dos iconos superpuestos.
const MUTE_ICON_NODE_NAME := "MuteStateIcon090"
const MUTE_ICON_INSET := 8.0


func _refresh_master_ui() -> void:
	if _legacy_audio_contract() or audio_manager == null or main == null:
		return
	var percent := int(audio_manager.call("get_volume_percent"))
	var muted := bool(audio_manager.call("is_muted"))

	if master_menu_label != null:
		master_menu_label.text = "Volumen · %d %%" % percent
	if room_label != null:
		room_label.text = "%d%%" % percent

	_refresh_mute_visuals(muted)


func _toggle_master_mute() -> void:
	if _legacy_audio_contract():
		super()
		return
	if audio_manager == null:
		return
	var muted := bool(audio_manager.call("toggle_mute"))
	_refresh_mute_visuals(muted)
	call_deferred("_refresh_master_ui")


func _refresh_mute_visuals(muted: bool) -> void:
	if main == null:
		return
	var visited := {}
	for candidate in [master_menu_mute, room_mute]:
		var button := candidate as Button
		if button != null and is_instance_valid(button):
			_set_mute_button_visual(button, muted)
			visited[button.get_instance_id()] = true
	for node in main.find_children("*Mute*", "Button", true, false):
		var button := node as Button
		if button == null or visited.has(button.get_instance_id()):
			continue
		_set_mute_button_visual(button, muted)


func _set_mute_button_visual(button: Button, muted: bool) -> void:
	# El Button no debe dibujar icono propio: toda la imagen la pinta el único
	# TextureRect hijo. Así nunca pueden verse sound-on y mute a la vez.
	button.icon = null
	button.expand_icon = false
	if button.name in ["MasterMute084", "RoomMasterMute084"]:
		button.text = ""
	button.tooltip_text = "Activar todo el audio" if muted else "Silenciar todo el audio"
	button.set_meta("audio_muted_visual", muted)

	# Limpiar posibles duplicados creados por builds anteriores/deferred calls.
	var icon_views: Array[Node] = []
	for child in button.get_children():
		if child.name == MUTE_ICON_NODE_NAME:
			icon_views.append(child)
	var icon_view: TextureRect = null
	if not icon_views.is_empty():
		icon_view = icon_views[0] as TextureRect
		for index in range(1, icon_views.size()):
			icon_views[index].queue_free()

	if icon_view == null:
		icon_view = TextureRect.new()
		icon_view.name = MUTE_ICON_NODE_NAME
		icon_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		button.add_child(icon_view)
		icon_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_view.offset_left = MUTE_ICON_INSET
		icon_view.offset_top = MUTE_ICON_INSET
		icon_view.offset_right = -MUTE_ICON_INSET
		icon_view.offset_bottom = -MUTE_ICON_INSET

	icon_view.texture = _mute_state_icon(muted)
	icon_view.visible = true
	icon_view.queue_redraw()
	button.queue_redraw()
