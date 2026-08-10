extends Node

const SETTINGS_PATH := "user://audio_settings.cfg"
const DEFAULT_MUSIC_VOLUME := 0.3
const DEFAULT_EFFECTS_VOLUME := 1.0
const VOLUME_STEP := 0.1

# Para añadir o cambiar canciones solo hay que:
# 1. Copiar el .ogg en assets/audio/music/.
# 2. Cambiar la ruta correspondiente en MUSIC_FILES.
# 3. Asociar su identificador al fondo en BACKGROUND_MUSIC.
# Se recomienda OGG porque funciona bien tanto en web como en escritorio.
const MUSIC_FILES := {
	"casa_asturias": "res://assets/audio/music/casa-asturias.ogg",
	"bosque_misterioso": "res://assets/audio/music/bosque-misterioso.ogg",
	"bar_nocturno": "res://assets/audio/music/bar-nocturno.ogg",
	"ana_vampirica": "res://assets/audio/music/ana-vampirica.ogg",
	"argentino_rock": "res://assets/audio/music/argentino-rock.ogg",
	"fran_electronica": "res://assets/audio/music/fran-electronica.ogg",
	"sue_fantasia": "res://assets/audio/music/sue-fantasia.ogg",
	"jony_rock": "res://assets/audio/music/jony-rock.ogg",
	"javi_lofi_rock": "res://assets/audio/music/javi-lofi-rock.ogg"
}

const BACKGROUND_MUSIC := {
	"casa_asturias": "casa_asturias",
	"bosque": "bosque_misterioso",
	"bar": "bar_nocturno",
	"habitacion_ana": "ana_vampirica",
	"habitacion_argentino": "argentino_rock",
	"habitacion_fran": "fran_electronica",
	"habitacion_sue": "sue_fantasia",
	"habitacion_jony": "jony_rock",
	"habitacion_javi": "javi_lofi_rock"
}

const SFX_FILES := {}
const UI_FILES := {}

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer
var music_volume := DEFAULT_MUSIC_VOLUME
var effects_volume := DEFAULT_EFFECTS_VOLUME
var music_muted := false
var effects_muted := false
var current_music_id := ""


func _ready() -> void:
	_ensure_audio_bus("Music")
	_ensure_audio_bus("SFX")
	_ensure_audio_bus("UI")
	music_player = _make_player("Music")
	sfx_player = _make_player("SFX")
	ui_player = _make_player("UI")
	_load_settings()
	_apply_audio_settings()


func play_background_music(background_id: String) -> bool:
	var music_id := str(BACKGROUND_MUSIC.get(background_id, ""))
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
	current_music_id = sound_id
	var stream := _load_registered(MUSIC_FILES, sound_id)
	if stream == null:
		return false
	_enable_loop(stream)
	music_player.stream = stream
	music_player.play()
	return true


func stop_music() -> void:
	current_music_id = ""
	if music_player != null:
		music_player.stop()


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


func get_effects_volume_percent() -> int:
	return roundi(effects_volume * 100.0)


func is_music_muted() -> bool:
	return music_muted


func is_effects_muted() -> bool:
	return effects_muted


# Alias de compatibilidad con la versión 0.3.7: afecta a ambos canales.
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
	return str(BACKGROUND_MUSIC.get(background_id, ""))


func path_for_music(music_id: String) -> String:
	return str(MUSIC_FILES.get(music_id, ""))


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
	if _play_registered(ui_player, UI_FILES, sound_id):
		return
	_play_generated(ui_player, [520.0, 760.0], 0.09, 0.045)


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
	_apply_bus_settings("Music", music_volume, music_muted)
	_apply_bus_settings("SFX", effects_volume, effects_muted)
	_apply_bus_settings("UI", effects_volume, effects_muted)


func _apply_bus_settings(bus_name: String, volume: float, muted: bool) -> void:
	var bus_index := AudioServer.get_bus_index(bus_name)
	if bus_index < 0:
		return
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(volume, 0.0001)))
	AudioServer.set_bus_mute(bus_index, muted)


func _load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) != OK:
		return
	var legacy_muted := bool(config.get_value("audio", "muted", false))
	music_volume = clampf(float(config.get_value("audio", "music_volume", DEFAULT_MUSIC_VOLUME)), 0.0, 1.0)
	effects_volume = clampf(float(config.get_value("audio", "effects_volume", DEFAULT_EFFECTS_VOLUME)), 0.0, 1.0)
	music_muted = bool(config.get_value("audio", "music_muted", legacy_muted))
	effects_muted = bool(config.get_value("audio", "effects_muted", legacy_muted))


func _save_settings() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "effects_volume", effects_volume)
	config.set_value("audio", "music_muted", music_muted)
	config.set_value("audio", "effects_muted", effects_muted)
	config.save(SETTINGS_PATH)


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
