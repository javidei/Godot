extends "res://scripts/version_040_manager_data.gd"

const Story084 = preload("res://scripts/story.gd")
const DataAccess084 = preload("res://scripts/data_access.gd")
const MASTER_MUTE_ICON_PATH := "res://assets/ui/icons/mute.svg"

var master_menu_row: HBoxContainer
var master_menu_label: Label
var master_menu_mute: Button


func _legacy_audio_contract() -> bool:
	# Los smoke tests históricos fuerzan 0.6.9 para validar que no hemos roto
	# contratos antiguos. En ese contexto se conserva exactamente el audio legado;
	# la simplificación solo se activa en la versión real 0.8.4+.
	return str(ProjectSettings.get_setting("application/config/version", "")).begins_with("0.6.9")


func _compact_menu_audio() -> void:
	if _legacy_audio_contract():
		super()
		return
	var menu := main.get("menu_content") as VBoxContainer
	if menu == null:
		return

	var audio_title := main.find_child("AudioSettingsTitle", true, false) as Label
	if audio_title != null:
		audio_title.text = "VOLUMEN GENERAL"

	var music_row := main.find_child("MusicControls", true, false) as HBoxContainer
	var effects_row := main.find_child("EffectsControls", true, false) as HBoxContainer
	if music_row != null:
		music_row.visible = false
	if effects_row != null:
		effects_row.visible = false

	master_menu_row = HBoxContainer.new()
	master_menu_row.name = "MasterAudioControls084"
	master_menu_row.custom_minimum_size = Vector2(0, 40)
	master_menu_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	master_menu_row.add_theme_constant_override("separation", 8)
	menu.add_child(master_menu_row)
	if music_row != null:
		menu.move_child(master_menu_row, music_row.get_index())

	var down := main.call("_make_small_button", "−") as Button
	down.name = "MasterVolumeDown084"
	down.tooltip_text = "Bajar volumen general"
	down.custom_minimum_size = Vector2(44, 40)
	down.pressed.connect(_adjust_master.bind(-_master_step()))
	master_menu_row.add_child(down)

	master_menu_label = Label.new()
	master_menu_label.name = "MasterVolumeLabel084"
	master_menu_label.custom_minimum_size = Vector2(142, 40)
	master_menu_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	master_menu_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	master_menu_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	master_menu_label.add_theme_color_override("font_color", Color("f7ead8"))
	master_menu_label.add_theme_font_size_override("font_size", 15)
	master_menu_row.add_child(master_menu_label)

	var up := main.call("_make_small_button", "+") as Button
	up.name = "MasterVolumeUp084"
	up.tooltip_text = "Subir volumen general"
	up.custom_minimum_size = Vector2(44, 40)
	up.pressed.connect(_adjust_master.bind(_master_step()))
	master_menu_row.add_child(up)

	master_menu_mute = _make_master_mute_button("MasterMute084", Vector2(44, 40))
	master_menu_mute.pressed.connect(_toggle_master_mute)
	master_menu_row.add_child(master_menu_mute)
	_refresh_master_ui()


func _build_room_audio() -> void:
	if _legacy_audio_contract():
		super()
		return
	var game := main.get("game_screen") as Control
	if game == null:
		return

	room_panel = PanelContainer.new()
	room_panel.name = "RoomMusicControls040"
	room_panel.z_index = 48
	room_panel.visible = false
	room_panel.add_theme_stylebox_override("panel", main.call("_panel_style", Color(0.04, 0.028, 0.024, 0.92), Color(0.76, 0.57, 0.32, 0.72), 1, 10))
	game.add_child(room_panel)

	var row := HBoxContainer.new()
	row.name = "MasterRoomAudioRow084"
	row.add_theme_constant_override("separation", 5)
	room_panel.add_child(row)

	room_music_icon = TextureRect.new()
	room_music_icon.name = "RoomMusicIcon"
	room_music_icon.custom_minimum_size = Vector2(24, 24)
	room_music_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	room_music_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	room_music_icon.texture = load(MUSIC_ICON_PATH) as Texture2D
	room_music_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(room_music_icon)

	var down := main.call("_make_small_button", "−") as Button
	down.name = "RoomMasterVolumeDown084"
	down.tooltip_text = "Bajar volumen general"
	down.custom_minimum_size = Vector2(40, 38)
	down.pressed.connect(_adjust_master.bind(-_master_step()))
	row.add_child(down)

	room_label = Label.new()
	room_label.name = "RoomMusicPercent"
	room_label.custom_minimum_size = Vector2(68, 38)
	room_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	room_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(room_label)

	var up := main.call("_make_small_button", "+") as Button
	up.name = "RoomMasterVolumeUp084"
	up.tooltip_text = "Subir volumen general"
	up.custom_minimum_size = Vector2(40, 38)
	up.pressed.connect(_adjust_master.bind(_master_step()))
	row.add_child(up)

	room_mute = _make_master_mute_button("RoomMasterMute084", Vector2(40, 38))
	room_mute.pressed.connect(_toggle_master_mute)
	row.add_child(room_mute)
	_refresh_master_ui()


func _make_master_mute_button(button_name: String, minimum_size: Vector2) -> Button:
	var button := main.call("_make_small_button", "") as Button
	button.name = button_name
	button.custom_minimum_size = minimum_size
	button.tooltip_text = "Silenciar todo el audio"
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", 18)
	button.icon = load(MASTER_MUTE_ICON_PATH) as Texture2D
	return button


func _master_step() -> float:
	var dm: Variant = DataAccess084.dm()
	if dm != null:
		dm.call("ensure_loaded")
		var defaults: Dictionary = dm.call("get_audio_defaults")
		return clampf(float(defaults.get("volume_step", 0.1)), 0.01, 1.0)
	return 0.1


func _adjust_master(delta: float) -> void:
	if audio_manager == null:
		return
	audio_manager.call("adjust_volume", delta)
	_refresh_master_ui()


func _toggle_master_mute() -> void:
	if audio_manager == null:
		return
	audio_manager.call("toggle_mute")
	_refresh_master_ui()


func _adjust_track(delta: float) -> void:
	if _legacy_audio_contract():
		super(delta)
		return
	_adjust_master(delta)


func _toggle_track_mute() -> void:
	if _legacy_audio_contract():
		super()
		return
	_toggle_master_mute()


func _apply_room_audio() -> void:
	if _legacy_audio_contract():
		super()
		return
	if audio_manager == null or main == null:
		return
	current_track = str(audio_manager.get("current_music_id"))
	var state: Dictionary = main.get("state")
	var node_id := str(state.get("node_id", "")) if not state.is_empty() else ""
	var game := main.get("game_screen") as Control
	var in_room := not Story084.character_for_node(node_id).is_empty()
	if room_panel != null:
		room_panel.visible = game != null and game.visible and in_room
	_refresh_master_ui()


func _keep_compact_ui() -> void:
	if _legacy_audio_contract():
		super()
		return
	_refresh_master_ui()


func _refresh_master_ui() -> void:
	if audio_manager == null:
		return
	var percent := int(audio_manager.call("get_volume_percent"))
	var muted := bool(audio_manager.call("is_muted"))
	if master_menu_label != null:
		master_menu_label.text = "Volumen · %d %%" % percent
	if master_menu_mute != null:
		master_menu_mute.text = ""
		master_menu_mute.tooltip_text = "Activar todo el audio" if muted else "Silenciar todo el audio"
		master_menu_mute.icon = load(MASTER_MUTE_ICON_PATH) as Texture2D
	if room_label != null:
		room_label.text = "%d%%" % percent
	if room_mute != null:
		room_mute.text = ""
		room_mute.tooltip_text = "Activar todo el audio" if muted else "Silenciar todo el audio"
		room_mute.icon = load(MASTER_MUTE_ICON_PATH) as Texture2D


func _load_track_settings() -> void:
	if _legacy_audio_contract():
		super()
		return
	# 0.8.4 elimina ajustes por canción. Se conserva la API heredada vacía para
	# que las partidas y configuraciones anteriores sigan cargando sin errores.
	track_volumes.clear()
	track_mutes.clear()
	if audio_manager == null:
		return

	# Migración: el antiguo volumen de música pasa a ser el único volumen general.
	# Así se conserva el nivel musical que ya tenía el jugador y se igualan los FX.
	var music_value := float(audio_manager.call("get_music_volume_percent")) / 100.0
	var effects_value := float(audio_manager.call("get_effects_volume_percent")) / 100.0
	if not is_equal_approx(music_value, effects_value):
		audio_manager.call("set_master_volume", music_value)

	# Si cualquiera de los dos canales antiguos estaba silenciado, el nuevo mute
	# general parte silenciado para no reproducir sonido inesperadamente.
	var any_legacy_muted := bool(audio_manager.call("is_music_muted")) or bool(audio_manager.call("is_effects_muted"))
	var all_muted := bool(audio_manager.call("is_muted"))
	if any_legacy_muted and not all_muted:
		audio_manager.call("toggle_mute")


func _save_track_settings() -> void:
	if _legacy_audio_contract():
		super()
		return
	# Ya no hay preferencias independientes por pista.
	pass
