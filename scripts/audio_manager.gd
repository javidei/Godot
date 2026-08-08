extends Node

# Los ficheros reales se pueden registrar aquí cuando existan. Mientras tanto,
# los SFX principales reutilizan el concepto de tonos generados de la demo HTML.
const SFX_FILES := {}
const UI_FILES := {}
const MUSIC_FILES := {}

var music_player: AudioStreamPlayer
var sfx_player: AudioStreamPlayer
var ui_player: AudioStreamPlayer


func _ready() -> void:
	music_player = _make_player("Music")
	sfx_player = _make_player("SFX")
	ui_player = _make_player("UI")


func play_music(sound_id: String) -> void:
	_play_registered(music_player, MUSIC_FILES, sound_id)


func stop_music() -> void:
	if music_player != null:
		music_player.stop()


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


func _make_player(player_name: String) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	add_child(player)
	return player


func _play_registered(player: AudioStreamPlayer, registry: Dictionary, sound_id: String) -> bool:
	if player == null or not registry.has(sound_id):
		return false
	var path := str(registry[sound_id])
	if path.is_empty() or not ResourceLoader.exists(path):
		return false
	var stream := ResourceLoader.load(path) as AudioStream
	if stream == null:
		return false
	player.stream = stream
	player.play()
	return true


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

