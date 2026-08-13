extends Node

const DataAccess = preload("res://scripts/data_access.gd")

signal click_sound_changed(sound_id: String)

# Valores cargados desde game_config.json; los literales son solo rescate.
static var DEFAULT_MUSIC_VOLUME: float = _config_float("default_music_volume", 0.3)
static var DEFAULT_EFFECTS_VOLUME: float = _config_float("default_effects_volume", 1.0)
static var VOLUME_STEP: float = _config_float("volume_step", 0.1)
static var MUSIC_OUTPUT_MAX: float = _config_float("music_output_max", 0.1)

const SFX_FILES := {}
const UI_FILES := {}

# Los sonidos de interfaz son completamente procedurales: no necesitan assets ni
# licencias externas. El orden de esta lista es también el orden del selector de
# Ajustes, por lo que añadir un perfil nuevo solo requiere ampliar estos datos y
# su forma de onda en _click_sample().
const DEFAULT_CLICK_SOUND := "soft"
const CLICK_SOUND_OPTIONS: Array[Dictionary] = [
	{"id": "soft", "label": "Suave", "description": "Un toque corto y cálido."},
	{"id": "dry", "label": "Seco", "description": "Un clic breve y preciso."},
	{"id": "digital", "label": "Digital", "description": "Un pulso electrónico ascendente."},
	{"id": "wood", "label": "Madera", "description": "Un golpe grave y orgánico."},
	{"id": "pop", "label": "Pop", "description": "Una burbuja ligera y juguetona."},
	{"id": "off", "label": "Desactivado", "description": "No reproduce sonidos al pulsar."}
]
const CLICK_BOUND_META := &"entre_lineas_click_bound"

var music_player: AudioStreamPlayer
var menu_music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer
var music_volume := 0.3
var effects_volume := 1.0
var music_muted := false
var effects_muted := false
var current_music_id := ""
var current_menu_music_id := ""
var music_suspended := false
var current_music_gain := 1.0
var music_fade_tween: Tween
var click_sound_id := DEFAULT_CLICK_SOUND


static func refresh_configuration() -> void:
	DEFAULT_MUSIC_VOLUME = _config_float("default_music_volume", 0.3)
	DEFAULT_EFFECTS_VOLUME = _config_float("default_effects_volume", 1.0)
	VOLUME_STEP = _config_float("volume_step", 0.1)
	MUSIC_OUTPUT_MAX = _config_float("music_output_max", 0.1)


static func _config_float(key: String, fallback: float) -> float:
	var dm: Variant = DataAccess.dm()
	if dm == null:
		return fallback
	dm.call("ensure_loaded")
	var audio: Dictionary = dm.call("get_audio_defaults")
	return float(audio.get(key, fallback))


func _ready() -> void:
	refresh_configuration()
	music_volume = DEFAULT_MUSIC_VOLUME
	effects_volume = DEFAULT_EFFECTS_VOLUME
	_ensure_audio_bus("Music")
	_ensure_audio_bus("MenuMusic")
	_ensure_audio_bus("SFX")
	_ensure_audio_bus("UI")
	music_player = _make_player("Music")
	menu_music_player = _make_player("MenuMusic")
	sfx_player = _make_player("SFX")
	ui_player = _make_player("UI")
	_load_settings()
	_apply_audio_settings()
	if not get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.connect(_on_tree_node_added)
	_bind_existing_buttons()


func _exit_tree() -> void:
	if get_tree() != null and get_tree().node_added.is_connected(_on_tree_node_added):
		get_tree().node_added.disconnect(_on_tree_node_added)


func play_background_music(background_id: String) -> bool:
	if music_suspended:
		return not current_music_id.is_empty() and music_player != null and music_player.playing
	var dm: Variant = DataAccess.dm()
	var music_id := str(dm.call("get_music_for_background", background_id)) if dm != null else ""
	if music_id.is_empty():
		stop_music()
		return false
	if music_id == current_music_id and music_player != null and music_player.playing:
		return true
	return play_music(music_id)


func play_music(sound_id: String) -> bool:
	if music_player == null:
		return false
	music_player.stop()
	music_player.volume_db = 0.0
	current_music_id = ""
	var stream := _load_music(sound_id)
	if stream == null:
		music_player.stream = null
		return false
	_enable_loop(stream)
	current_music_id = sound_id
	music_player.stream = stream
	music_player.play()
	return true


func play_menu_music() -> bool:
	var dm: Variant = DataAccess.dm()
	var menu_music: Dictionary = dm.call("get_menu_music") if dm != null and dm.has_method("get_menu_music") else {}
	if menu_music.is_empty():
		stop_menu_music()
		return false
	return _play_menu_music_configured(
		str(menu_music.get("id", "menu")),
		float(menu_music.get("fade_seconds", 4.0)),
		float(menu_music.get("volume", 0.35)),
		bool(menu_music.get("loop", true))
	)


func stop_menu_music() -> void:
	var dm: Variant = DataAccess.dm()
	var menu_music: Dictionary = dm.call("get_menu_music") if dm != null and dm.has_method("get_menu_music") else {}
	var menu_music_id := str(menu_music.get("id", "menu"))
	if current_menu_music_id != menu_music_id:
		return
	_cancel_music_fade()
	current_menu_music_id = ""
	current_music_gain = 1.0
	if menu_music_player != null:
		menu_music_player.stop()
		menu_music_player.volume_db = 0.0
	_apply_audio_settings()


func _play_menu_music_configured(sound_id: String, fade_seconds: float, gain: float, should_loop: bool) -> bool:
	if menu_music_player == null:
		return false
	_cancel_music_fade()
	menu_music_player.stop()
	menu_music_player.volume_db = 0.0
	current_menu_music_id = ""
	var stream := _load_music(sound_id)
	if stream == null:
		menu_music_player.stream = null
		return false
	if should_loop:
		_enable_loop(stream)
	current_menu_music_id = sound_id
	current_music_gain = clampf(gain, 0.0, 1.0)
	_apply_audio_settings()
	menu_music_player.stream = stream
	var safe_fade := maxf(0.0, fade_seconds)
	if safe_fade > 0.0:
		menu_music_player.volume_db = -60.0
	menu_music_player.play()
	if safe_fade > 0.0:
		music_fade_tween = create_tween()
		music_fade_tween.set_trans(Tween.TRANS_SINE)
		music_fade_tween.set_ease(Tween.EASE_OUT)
		music_fade_tween.tween_property(menu_music_player, "volume_db", 0.0, safe_fade)
	return true


func stop_music() -> void:
	current_music_id = ""
	if music_player != null:
		music_player.stop()
		music_player.volume_db = 0.0


func _cancel_music_fade() -> void:
	if music_fade_tween != null and music_fade_tween.is_valid():
		music_fade_tween.kill()
	music_fade_tween = null


func suspend_music() -> void:
	music_suspended = true
	_apply_audio_settings()


func resume_music() -> void:
	music_suspended = false
	_apply_audio_settings()


func is_music_suspended() -> bool:
	return music_suspended


func adjust_music_volume(delta: float) -> void:
	set_music_volume(music_volume + delta)


func set_music_volume(value: float) -> void:
	music_volume = clampf(snappedf(value, 0.01), 0.0, 1.0)
	_apply_audio_settings()
	_save_settings()


func adjust_effects_volume(delta: float) -> void:
	set_effects_volume(effects_volume + delta)


func set_effects_volume(value: float) -> void:
	effects_volume = clampf(snappedf(value, 0.01), 0.0, 1.0)
	_apply_audio_settings()
	_save_settings()


func toggle_music_mute() -> bool:
	music_muted = not music_muted
	_apply_audio_settings()
	_save_settings()
	return music_muted


func toggle_effects_mute() -> bool:
	effects_muted = not effects_muted
	_apply_audio_settings()
	_save_settings()
	return effects_muted


func get_music_volume_percent() -> int:
	return roundi(music_volume * 100.0)


func get_music_output_linear() -> float:
	return music_volume * MUSIC_OUTPUT_MAX


func get_effects_volume_percent() -> int:
	return roundi(effects_volume * 100.0)


func is_music_muted() -> bool:
	return music_muted


func is_effects_muted() -> bool:
	return effects_muted


func adjust_volume(delta: float) -> void:
	set_master_volume(maxf(music_volume, effects_volume) + delta)


func set_master_volume(value: float) -> void:
	var normalized := clampf(snappedf(value, 0.01), 0.0, 1.0)
	music_volume = normalized
	effects_volume = normalized
	_apply_audio_settings()
	_save_settings()


func toggle_mute() -> bool:
	var should_mute := not (music_muted and effects_muted)
	music_muted = should_mute
	effects_muted = should_mute
	_apply_audio_settings()
	_save_settings()
	return should_mute


func get_volume_percent() -> int:
	return get_music_volume_percent()


func is_muted() -> bool:
	return music_muted and effects_muted


func music_for_background(background_id: String) -> String:
	var dm: Variant = DataAccess.dm()
	return str(dm.call("get_music_for_background", background_id)) if dm != null else ""


func path_for_music(music_id: String) -> String:
	var dm: Variant = DataAccess.dm()
	return str(dm.call("get_music_path", music_id)) if dm != null else ""


func play_sfx(sound_id: String) -> void:
	if _play_registered(sfx_player, SFX_FILES, sound_id):
		return
	match sound_id:
		"clonk":
			_play_generated(sfx_player, [105.0, 68.0], 0.28, 0.16)
		"strum":
			_play_generated(sfx_player, [196.0, 247.0, 294.0, 392.0], 0.34, 0.07)
		_:
			pass


func play_ui(sound_id: String = "confirm") -> void:
	# Los callers históricos usan "confirm". Se conserva esa API, pero ahora
	# siempre resuelve al perfil elegido por el usuario.
	if sound_id != "confirm" and sound_id != "click" and _play_registered(ui_player, UI_FILES, sound_id):
		return
	_play_click_profile(click_sound_id)


func get_click_sound() -> String:
	return click_sound_id


func get_click_sound_label(sound_id: String = "") -> String:
	var requested := click_sound_id if sound_id.is_empty() else _normalized_click_sound(sound_id)
	for option in CLICK_SOUND_OPTIONS:
		if str(option.get("id", "")) == requested:
			return str(option.get("label", requested.capitalize()))
	return requested.capitalize()


func get_click_sound_options() -> Array[Dictionary]:
	return CLICK_SOUND_OPTIONS.duplicate(true)


func get_click_profiles() -> Array[Dictionary]:
	return get_click_sound_options()


func set_click_sound(sound_id: String, preview: bool = true) -> bool:
	var normalized := _normalized_click_sound(sound_id)
	if normalized == click_sound_id:
		if preview:
			preview_click(normalized)
		return true
	click_sound_id = normalized
	_save_settings()
	click_sound_changed.emit(click_sound_id)
	if preview:
		preview_click(click_sound_id)
	return true


func select_click_sound(sound_id: String, preview: bool = true) -> bool:
	return set_click_sound(sound_id, preview)


func preview_click(sound_id: String = "") -> void:
	var requested := click_sound_id if sound_id.is_empty() else _normalized_click_sound(sound_id)
	_play_click_profile(requested)


func preview_click_sound(sound_id: String = "") -> void:
	preview_click(sound_id)


func bind_click(button: BaseButton) -> void:
	if button == null or not is_instance_valid(button) or button.has_meta(CLICK_BOUND_META):
		return
	button.set_meta(CLICK_BOUND_META, true)
	# _make_button() ya enruta el sonido a play_ui() mediante Main. Reconocer esa
	# conexión mantiene exactamente un clic por pulsación. Los controles creados
	# directamente (tarjetas, iconos o futuros mapas) sí se enlazan aquí.
	if _button_routes_through_main(button):
		return
	button.pressed.connect(_on_bound_button_pressed.bind(button))


func _on_tree_node_added(node: Node) -> void:
	if node is BaseButton:
		bind_click(node as BaseButton)


func _bind_existing_buttons() -> void:
	var root := get_tree().root
	if root == null:
		return
	for node in root.find_children("*", "BaseButton", true, false):
		bind_click(node as BaseButton)


func _on_bound_button_pressed(button: BaseButton) -> void:
	# Una conexión a Main puede añadirse después de que el nodo entre en el árbol.
	# Se vuelve a comprobar al pulsar para seguir evitando audio duplicado.
	if button != null and _button_routes_through_main(button):
		return
	play_ui("click")


func _button_routes_through_main(button: BaseButton) -> bool:
	for connection_value in button.pressed.get_connections():
		if typeof(connection_value) != TYPE_DICTIONARY:
			continue
		var connection: Dictionary = connection_value
		var callback_value: Variant = connection.get("callable", Callable())
		if typeof(callback_value) != TYPE_CALLABLE:
			continue
		var callback: Callable = callback_value
		if callback.is_valid() and str(callback.get_method()) == "_play_ui_sound":
			return true
	return false


func _ensure_audio_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) >= 0:
		return
	AudioServer.add_bus()
	AudioServer.set_bus_name(AudioServer.get_bus_count() - 1, bus_name)


func _make_player(player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.bus = player_name
	add_child(player)
	return player


func _load_music(sound_id: String) -> AudioStream:
	var dm: Variant = DataAccess.dm()
	var path := str(dm.call("get_music_path", sound_id)) if dm != null else ""
	if path.is_empty() or not ResourceLoader.exists(path):
		push_warning("Canción no registrada o inexistente: %s -> %s" % [sound_id, path])
		return null
	return ResourceLoader.load(path) as AudioStream


func _load_registered(registry: Dictionary, sound_id: String) -> AudioStream:
	if not registry.has(sound_id):
		return null
	var path := str(registry[sound_id])
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	return ResourceLoader.load(path) as AudioStream


func _play_registered(player: AudioStreamPlayer, registry: Dictionary, sound_id: String) -> bool:
	if player == null:
		return false
	var stream := _load_registered(registry, sound_id)
	if stream == null:
		return false
	player.stream = stream
	player.play()
	return true


func _enable_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD


func _apply_audio_settings() -> void:
	_apply_bus_settings("Music", get_music_output_linear(), music_muted or music_suspended)
	_apply_bus_settings("MenuMusic", get_music_output_linear() * current_music_gain, music_muted)
	_apply_bus_settings("SFX", effects_volume, effects_muted)
	_apply_bus_settings("UI", effects_volume, effects_muted)


func _apply_bus_settings(bus_name: String, volume: float, muted: bool) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(bus_index, muted)


func _load_settings() -> void:
	var dm: Variant = DataAccess.dm()
	var settings: Dictionary = dm.call("get_settings") if dm != null else {}
	var audio: Dictionary = settings.get("audio", {})
	music_volume = clampf(float(audio.get("music_volume", DEFAULT_MUSIC_VOLUME)), 0.0, 1.0)
	effects_volume = clampf(float(audio.get("effects_volume", DEFAULT_EFFECTS_VOLUME)), 0.0, 1.0)
	music_muted = bool(audio.get("music_muted", false))
	effects_muted = bool(audio.get("effects_muted", false))
	click_sound_id = _normalized_click_sound(str(audio.get("click_sound", DEFAULT_CLICK_SOUND)))


func _save_settings() -> void:
	var dm: Variant = DataAccess.dm()
	if dm == null:
		return
	dm.call("update_audio_settings", {
		"music_volume": music_volume,
		"effects_volume": effects_volume,
		"music_muted": music_muted,
		"effects_muted": effects_muted,
		"click_sound": click_sound_id
	})


func _normalized_click_sound(sound_id: String) -> String:
	var candidate := sound_id.strip_edges().to_lower()
	# Acepta tanto ids estables como las etiquetas visibles para facilitar
	# migraciones manuales de settings.json.
	var aliases := {
		"suave": "soft",
		"seco": "dry",
		"digital": "digital",
		"madera": "wood",
		"pop": "pop",
		"desactivado": "off",
		"disabled": "off",
		"none": "off"
	}
	if aliases.has(candidate):
		candidate = str(aliases[candidate])
	for option in CLICK_SOUND_OPTIONS:
		if str(option.get("id", "")) == candidate:
			return candidate
	return DEFAULT_CLICK_SOUND


func _play_click_profile(sound_id: String) -> void:
	var profile := _normalized_click_sound(sound_id)
	if profile == "off" or ui_player == null:
		return
	var duration := 0.065
	match profile:
		"dry":
			duration = 0.038
		"digital":
			duration = 0.075
		"wood":
			duration = 0.095
		"pop":
			duration = 0.082
	_play_generated_click(ui_player, profile, duration)


func _play_generated_click(player: AudioStreamPlayer, profile: String, duration: float) -> void:
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	generator.buffer_length = maxf(0.2, duration + 0.06)
	player.stop()
	player.stream = generator
	player.play()
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var sample_count := int(generator.mix_rate * duration)
	var frames := PackedVector2Array()
	frames.resize(sample_count)
	for index in range(sample_count):
		var time := float(index) / generator.mix_rate
		var progress := float(index) / float(maxi(1, sample_count - 1))
		var sample := _click_sample(profile, time, progress)
		frames[index] = Vector2(sample, sample)
	playback.push_buffer(frames)


func _click_sample(profile: String, time: float, progress: float) -> float:
	var attack := minf(1.0, progress * 32.0)
	match profile:
		"dry":
			var dry_envelope := attack * pow(1.0 - progress, 5.2)
			var dry_tick := sin(TAU * 1320.0 * time) + 0.45 * sin(TAU * 2430.0 * time)
			return dry_tick * 0.052 * dry_envelope
		"digital":
			var digital_envelope := attack * pow(1.0 - progress, 2.7)
			var sweep := lerpf(720.0, 1480.0, progress)
			var digital_wave := sin(TAU * sweep * time)
			digital_wave += 0.30 * sin(TAU * sweep * 2.0 * time)
			return digital_wave * 0.047 * digital_envelope
		"wood":
			var wood_envelope := attack * pow(1.0 - progress, 3.4)
			var body := sin(TAU * 185.0 * time) + 0.62 * sin(TAU * 296.0 * time)
			var grain := sin(TAU * 1789.0 * time) * sin(TAU * 997.0 * time)
			return (body * 0.046 + grain * 0.014) * wood_envelope
		"pop":
			var pop_envelope := attack * pow(1.0 - progress, 2.4)
			var falling_frequency := lerpf(760.0, 245.0, progress)
			return sin(TAU * falling_frequency * time) * 0.065 * pop_envelope
		_:
			var soft_envelope := attack * pow(1.0 - progress, 2.8)
			var soft_wave := sin(TAU * 430.0 * time) + 0.45 * sin(TAU * 650.0 * time)
			return soft_wave * 0.038 * soft_envelope


func _play_generated(player: AudioStreamPlayer, frequencies: Array, duration: float, volume: float) -> void:
	if player == null or frequencies.is_empty():
		return
	var generator := AudioStreamGenerator.new()
	generator.mix_rate = 44100.0
	generator.buffer_length = max(0.25, duration + 0.08)
	player.stream = generator
	player.play()
	var playback := player.get_stream_playback() as AudioStreamGeneratorPlayback
	if playback == null:
		return
	var sample_count := int(generator.mix_rate * duration)
	var frames := PackedVector2Array()
	frames.resize(sample_count)
	for index in range(sample_count):
		var time := float(index) / generator.mix_rate
		var progress := float(index) / float(max(1, sample_count - 1))
		var envelope := pow(1.0 - progress, 2.2)
		var sample := 0.0
		for frequency in frequencies:
			sample += sin(TAU * float(frequency) * time)
		sample = sample / float(frequencies.size()) * volume * envelope
		frames[index] = Vector2(sample, sample)
	playback.push_buffer(frames)
