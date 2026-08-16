extends "res://scripts/version_090_unified_audio_manager.gd"

# 0.9.6: cada botón de mute dibuja UN solo icono mediante Button.icon.
# La capa TextureRect introducida en 0.9.5 podía coexistir con Button.icon y
# provocar que sound-on y mute apareciesen superpuestos.
const LEGACY_MUTE_ICON_NODE_NAME := "MuteStateIcon090"


func _process(delta: float) -> void:
	# Ejecutar primero toda la lógica heredada del HUD/audio y fijar el icono al
	# final del frame. Hay refrescos antiguos que pueden tocar el botón durante
	# _process; esta última escritura garantiza que la imagen visible corresponde
	# siempre al estado real del mute general.
	super(delta)
	if not _legacy_audio_contract() and audio_manager != null and main != null:
		_apply_single_mute_icon(bool(audio_manager.call("is_muted")))


func _refresh_master_ui() -> void:
	super()
	_cleanup_legacy_mute_overlays()
	if not _legacy_audio_contract() and audio_manager != null:
		_apply_single_mute_icon(bool(audio_manager.call("is_muted")))


func _toggle_master_mute() -> void:
	if _legacy_audio_contract():
		super()
		return
	if audio_manager == null:
		return
	var muted := bool(audio_manager.call("toggle_mute"))
	_apply_single_mute_icon(muted)
	call_deferred("_refresh_master_ui")


func _apply_single_mute_icon(muted: bool) -> void:
	if main == null:
		return
	var icon := _mute_state_icon(muted)
	for node in main.find_children("*Mute*", "Button", true, false):
		var button := node as Button
		if button == null:
			continue
		_remove_legacy_overlay(button)
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
		button.set_meta("audio_muted_visual", muted)
		button.queue_redraw()


func _cleanup_legacy_mute_overlays() -> void:
	if main == null:
		return
	for node in main.find_children("*Mute*", "Button", true, false):
		var button := node as Button
		if button != null:
			_remove_legacy_overlay(button)


func _remove_legacy_overlay(button: Button) -> void:
	for child in button.get_children():
		if child.name == LEGACY_MUTE_ICON_NODE_NAME:
			button.remove_child(child)
			child.queue_free()
