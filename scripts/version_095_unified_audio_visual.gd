extends "res://scripts/version_090_unified_audio_manager.gd"

# Capa visual 0.9.5: usa un TextureRect interno en vez de Button.icon para
# garantizar que el estado visible se redibuja al alternar mute en Web y native.
const MUTE_ICON_NODE_NAME := "MuteStateIcon090"
const MUTE_ICON_INSET := 8.0


func _refresh_master_ui() -> void:
	super()
	if _legacy_audio_contract() or audio_manager == null or main == null:
		return
	_refresh_mute_visuals(bool(audio_manager.call("is_muted")))


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
	button.icon = null
	button.expand_icon = false
	button.text = "" if button.name in ["MasterMute084", "RoomMasterMute084"] else button.text
	button.tooltip_text = "Activar todo el audio" if muted else "Silenciar todo el audio"
	button.set_meta("audio_muted_visual", muted)

	var icon_view := button.get_node_or_null(MUTE_ICON_NODE_NAME) as TextureRect
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
