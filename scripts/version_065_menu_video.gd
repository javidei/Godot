extends Node

const VIDEO_PATH := "res://assets/video/eclipse-menu.ogv"
const VIDEO_RATIO := 16.0 / 9.0

var menu_screen: Control
var video_container: AspectRatioContainer
var video_player: VideoStreamPlayer


func _ready() -> void:
	call_deferred("_install_menu_video")


func _install_menu_video() -> void:
	var main := get_parent()
	if main == null:
		return
	menu_screen = main.get("menu_screen") as Control
	if menu_screen == null:
		menu_screen = main.get_node_or_null("MenuScreen") as Control
	if menu_screen == null:
		push_warning("No se encontró MenuScreen para instalar el fondo eclipse.")
		return

	var stream := load(VIDEO_PATH) as VideoStream
	if stream == null:
		push_warning("No se pudo cargar " + VIDEO_PATH)
		return

	var fallback := main.get("menu_background") as TextureRect
	if fallback != null:
		fallback.z_index = -100

	video_container = AspectRatioContainer.new()
	video_container.name = "MenuEclipseVideoContainer065"
	video_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	video_container.ratio = VIDEO_RATIO
	video_container.stretch_mode = AspectRatioContainer.STRETCH_COVER
	video_container.clip_contents = true
	video_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	video_container.z_index = -90
	menu_screen.add_child(video_container)
	menu_screen.move_child(video_container, 0)

	video_player = VideoStreamPlayer.new()
	video_player.name = "MenuEclipseVideo065"
	video_player.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	video_player.expand = true
	video_player.loop = true
	video_player.autoplay = false
	video_player.volume_db = -80.0
	video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	video_player.stream = stream
	video_container.add_child(video_player)

	_soften_menu_shade()
	menu_screen.visibility_changed.connect(_sync_menu_video_playback)
	_sync_menu_video_playback()


func _soften_menu_shade() -> void:
	if menu_screen == null:
		return
	for child in menu_screen.get_children():
		if child is ColorRect:
			var shade := child as ColorRect
			var shade_color := shade.color
			shade_color.a = minf(shade_color.a, 0.50)
			shade.color = shade_color
			return


func _sync_menu_video_playback() -> void:
	if menu_screen == null or video_player == null:
		return
	if menu_screen.visible:
		video_player.paused = false
		if not video_player.is_playing():
			video_player.play()
	else:
		video_player.paused = true
