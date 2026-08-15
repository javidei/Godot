extends "res://scripts/version_084_unified_audio_manager.gd"

const MUTE_ICON_MAX_WIDTH := 30
const MENU_MUTE_MIN_SIZE := Vector2(52, 44)
const ROOM_MUTE_MIN_SIZE := Vector2(52, 46)


func _refresh_master_ui() -> void:
	super()
	if _legacy_audio_contract() or audio_manager == null or main == null:
		return
	var muted := bool(audio_manager.call("is_muted"))
	var icon := _mute_state_icon(muted)
	for node in main.find_children("*Mute*", "Button", true, false):
		var button := node as Button
		if button == null:
			continue
		button.icon = icon
		button.expand_icon = true
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.add_theme_constant_override("icon_max_width", MUTE_ICON_MAX_WIDTH)
		if button.name == "MasterMute084":
			button.custom_minimum_size = MENU_MUTE_MIN_SIZE
			button.text = ""
		elif button.name == "RoomMasterMute084":
			button.custom_minimum_size = ROOM_MUTE_MIN_SIZE
			button.text = ""
		button.tooltip_text = "Activar todo el audio" if muted else "Silenciar todo el audio"
