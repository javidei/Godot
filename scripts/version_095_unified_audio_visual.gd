extends "res://scripts/version_090_unified_audio_manager.gd"

# 0.9.6 separa por completo estado y presentación del mute.
# Este manager conserva volumen/mute y textos; Version096MuteVisualGuard es el
# ÚNICO nodo autorizado a pintar los iconos sound-on/mute.


func _refresh_master_ui() -> void:
	if _legacy_audio_contract():
		super()
		return
	if audio_manager == null:
		return

	var percent := int(audio_manager.call("get_volume_percent"))
	var muted := bool(audio_manager.call("is_muted"))
	if master_menu_label != null:
		master_menu_label.text = "Volumen · %d %%" % percent
	if room_label != null:
		room_label.text = "%d%%" % percent

	for candidate in [master_menu_mute, room_mute]:
		var button := candidate as Button
		if button == null:
			continue
		# Nunca dejar un Button.icon heredado: evita que se superponga al estado
		# que dibuja el guard 0.9.6 mediante sus dos TextureRect exclusivos.
		button.icon = null
		button.expand_icon = false
		button.text = ""
		button.tooltip_text = "Activar todo el audio" if muted else "Silenciar todo el audio"
		if button.name == "MasterMute084":
			button.custom_minimum_size = MENU_MUTE_MIN_SIZE
		elif button.name == "RoomMasterMute084":
			button.custom_minimum_size = ROOM_MUTE_MIN_SIZE

	var guard := main.get_node_or_null("Version096MuteVisualGuard") if main != null else null
	if guard != null and guard.has_method("refresh_now"):
		guard.call("refresh_now")


func _toggle_master_mute() -> void:
	if _legacy_audio_contract():
		super()
		return
	if audio_manager == null:
		return
	audio_manager.call("toggle_mute")
	_refresh_master_ui()
