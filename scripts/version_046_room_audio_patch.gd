extends Node

const Story = preload("res://scripts/story.gd")
const ROOM_SETTINGS_PATH := "user://room_audio_settings.cfg"

const CHARACTER_BACKGROUNDS := {
	"javi": "habitacion_javi",
	"sue": "habitacion_sue",
	"smokey": "habitacion_fran",
	"carmen": "habitacion_fran",
	"jony": "habitacion_jony",
	"ana": "habitacion_ana",
	"argentino": "habitacion_argentino"
}

var main: Control
var audio_manager: Node
var legacy_manager: Node
var legacy_room_panel: PanelContainer
var room_panel: PanelContainer
var room_music_button: Button
var room_effects_button: Button
var room_all_button: Button
var room_music_mutes: Dictionary = {}
var room_effects_mutes: Dictionary = {}
var current_room := ""
var current_track := ""
var last_audio_signature := ""


func _ready() -> void:
	# Debe ejecutarse después del gestor 0.4.0 para reemplazar únicamente
	# su antigua botonera de habitación sin tocar el selector de visitas.
	process_priority = 100
	for _i in range(4):
		await get_tree().process_frame
	main = get_parent() as Control
	if main == null:
		return
	audio_manager = main.get("audio_manager") as Node
	legacy_manager = main.get_node_or_null("Version040Manager")
	_load_room_settings()
	_retire_legacy_room_controls()
	_build_room_controls()
	get_viewport().size_changed.connect(_queue_layout)
	_apply_layout()
	_apply_room_audio()


func _process(_delta: float) -> void:
	if main == null or audio_manager == null:
		return
	_retire_legacy_room_controls()
	_apply_room_audio()


func _retire_legacy_room_controls() -> void:
	if legacy_room_panel == null and legacy_manager != null:
		legacy_room_panel = legacy_manager.get("room_panel") as PanelContainer
	if legacy_room_panel == null:
		return
	# El gestor antiguo sigue usando esta referencia internamente. La dejamos viva
	# para no romper compatibilidad, pero queda completamente invisible e inerte.
	legacy_room_panel.modulate.a = 0.0
	legacy_room_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_disable_legacy_controls(legacy_room_panel)


func _disable_legacy_controls(node: Node) -> void:
	for child in node.get_children():
		if child is Control:
			(child as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
		if child is Button:
			var button := child as Button
			button.disabled = true
			button.focus_mode = Control.FOCUS_NONE
		_disable_legacy_controls(child)


func _build_room_controls() -> void:
	var game := main.get("game_screen") as Control
	if game == null:
		return

	room_panel = PanelContainer.new()
	room_panel.name = "RoomAudioButtons046"
	room_panel.z_index = 52
	room_panel.visible = false
	room_panel.add_theme_stylebox_override("panel", main.call("_panel_style", Color(0.04, 0.028, 0.024, 0.92), Color(0.76, 0.57, 0.32, 0.72), 1, 10))
	game.add_child(room_panel)

	var row := HBoxContainer.new()
	row.name = "RoomAudioButtonRow046"
	row.add_theme_constant_override("separation", 5)
	room_panel.add_child(row)

	room_music_button = _make_room_button("Silenciar música", "RoomMuteMusic046", "Silenciar o activar la música solo en esta habitación")
	room_music_button.pressed.connect(_toggle_room_music)
	row.add_child(room_music_button)

	room_effects_button = _make_room_button("Silenciar efectos", "RoomMuteEffects046", "Silenciar o activar los efectos de sonido solo en esta habitación")
	room_effects_button.pressed.connect(_toggle_room_effects)
	row.add_child(room_effects_button)

	room_all_button = _make_room_button("Silenciar ambos", "RoomMuteAll046", "Silenciar o activar música y efectos de esta habitación")
	room_all_button.pressed.connect(_toggle_room_all)
	row.add_child(room_all_button)


func _make_room_button(text: String, node_name: String, tooltip: String) -> Button:
	var button := main.call("_make_small_button", text) as Button
	button.name = node_name
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(122, 38)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 12)
	return button


func _toggle_room_music() -> void:
	if current_room.is_empty():
		return
	room_music_mutes[current_room] = not bool(room_music_mutes.get(current_room, false))
	_save_room_settings()
	last_audio_signature = ""
	_apply_room_audio()


func _toggle_room_effects() -> void:
	if current_room.is_empty():
		return
	room_effects_mutes[current_room] = not bool(room_effects_mutes.get(current_room, false))
	_save_room_settings()
	last_audio_signature = ""
	_apply_room_audio()


func _toggle_room_all() -> void:
	if current_room.is_empty():
		return
	var music_muted := bool(room_music_mutes.get(current_room, false))
	var effects_muted := bool(room_effects_mutes.get(current_room, false))
	var mute_both := not (music_muted and effects_muted)
	room_music_mutes[current_room] = mute_both
	room_effects_mutes[current_room] = mute_both
	_save_room_settings()
	last_audio_signature = ""
	_apply_room_audio()


func _apply_room_audio() -> void:
	var game := main.get("game_screen") as Control
	var state_value: Variant = main.get("state")
	var state: Dictionary = state_value if typeof(state_value) == TYPE_DICTIONARY else {}
	var node_id := str(state.get("node_id", ""))
	var character_id := Story.character_for_node(node_id)
	current_room = _background_for_character(character_id) if not character_id.is_empty() else ""
	current_track = str(audio_manager.get("current_music_id"))
	var in_room := game != null and game.visible and not current_room.is_empty()

	if room_panel != null:
		room_panel.visible = in_room

	var local_music_muted := bool(room_music_mutes.get(current_room, false)) if in_room else false
	var local_effects_muted := bool(room_effects_mutes.get(current_room, false)) if in_room else false
	_refresh_room_buttons(local_music_muted, local_effects_muted)

	var global_music_muted := bool(audio_manager.call("is_music_muted"))
	var global_effects_muted := bool(audio_manager.call("is_effects_muted"))
	var music_volume := float(audio_manager.call("get_music_output_linear"))
	var effects_volume := float(audio_manager.call("get_effects_volume_percent")) / 100.0
	var signature := "%s|%s|%s|%s|%s|%.4f|%.4f" % [
		current_room,
		str(local_music_muted),
		str(local_effects_muted),
		str(global_music_muted),
		str(global_effects_muted),
		music_volume,
		effects_volume
	]
	if signature == last_audio_signature:
		return

	_apply_bus("Music", music_volume, global_music_muted or local_music_muted)
	_apply_bus("SFX", effects_volume, global_effects_muted or local_effects_muted)
	# Los sonidos de interfaz siguen dependiendo únicamente del ajuste global.
	# Así los propios botones continúan dando feedback aunque se silencien los FX de la habitación.
	_apply_bus("UI", effects_volume, global_effects_muted)
	last_audio_signature = signature


func _refresh_room_buttons(music_muted: bool, effects_muted: bool) -> void:
	if room_music_button != null:
		room_music_button.text = "Activar música" if music_muted else "Silenciar música"
		room_music_button.disabled = current_track.is_empty()
	if room_effects_button != null:
		room_effects_button.text = "Activar efectos" if effects_muted else "Silenciar efectos"
	if room_all_button != null:
		var both_muted := music_muted and effects_muted
		room_all_button.text = "Activar ambos" if both_muted else "Silenciar ambos"


func _apply_bus(bus_name: String, volume: float, muted: bool) -> void:
	var bus := AudioServer.get_bus_index(bus_name)
	if bus < 0:
		return
	AudioServer.set_bus_volume_db(bus, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(bus, muted or volume <= 0.0)


func _background_for_character(character_id: String) -> String:
	return str(CHARACTER_BACKGROUNDS.get(character_id, ""))


func _load_room_settings() -> void:
	var config := ConfigFile.new()
	if config.load(ROOM_SETTINGS_PATH) != OK:
		return
	for key in config.get_section_keys("music_muted"):
		room_music_mutes[str(key)] = bool(config.get_value("music_muted", key, false))
	for key in config.get_section_keys("effects_muted"):
		room_effects_mutes[str(key)] = bool(config.get_value("effects_muted", key, false))


func _save_room_settings() -> void:
	var config := ConfigFile.new()
	for key in room_music_mutes.keys():
		config.set_value("music_muted", str(key), bool(room_music_mutes[key]))
	for key in room_effects_mutes.keys():
		config.set_value("effects_muted", str(key), bool(room_effects_mutes[key]))
	config.save(ROOM_SETTINGS_PATH)


func _queue_layout() -> void:
	call_deferred("_apply_layout")


func _apply_layout() -> void:
	if room_panel == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var portrait := viewport_size.y > viewport_size.x
	if portrait:
		room_panel.anchor_left = 0.08
		room_panel.anchor_top = 0.095
		room_panel.anchor_right = 0.92
		room_panel.anchor_bottom = 0.16
	else:
		room_panel.anchor_left = 0.65
		room_panel.anchor_top = 0.105
		room_panel.anchor_right = 0.975
		room_panel.anchor_bottom = 0.18
	room_panel.offset_left = 0.0
	room_panel.offset_top = 0.0
	room_panel.offset_right = 0.0
	room_panel.offset_bottom = 0.0
