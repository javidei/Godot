extends "res://scripts/version_066_compact_extras_patch.gd"


func _add_settings_audio_summary(parent: VBoxContainer) -> void:
	_add_section_title(parent, "Audio")
	var audio_manager := _audio_manager()
	if audio_manager == null:
		_add_body_label(parent, "El control de audio no está disponible.")
		return
	var percent := int(audio_manager.call("get_volume_percent"))
	var state := "silenciado" if bool(audio_manager.call("is_muted")) else "activo"
	_add_body_label(parent, "Volumen general: %d %% · %s\n\nEl mismo volumen controla música, efectos y sonidos de interfaz. Puedes cambiarlo desde el menú principal o desde cualquier habitación." % [percent, state])
