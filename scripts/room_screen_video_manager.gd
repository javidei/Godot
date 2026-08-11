extends Node

const DataAccess = preload("res://scripts/data_access.gd")

const SCREEN_SHADER := """
shader_type canvas_item;

uniform float brightness : hint_range(0.0, 1.5) = 0.58;
uniform float saturation : hint_range(0.0, 1.5) = 0.72;
uniform float warmth : hint_range(0.0, 1.0) = 0.16;
uniform float vignette : hint_range(0.0, 1.0) = 0.22;
uniform float scanlines : hint_range(0.0, 0.2) = 0.025;
uniform float source_height = 180.0;
uniform vec3 homography_row_0 = vec3(1.0, 0.0, 0.0);
uniform vec3 homography_row_1 = vec3(0.0, 1.0, 0.0);
uniform vec3 homography_row_2 = vec3(0.0, 0.0, 1.0);
uniform vec2 uv_min = vec2(0.0);
uniform vec2 uv_max = vec2(1.0);

varying vec2 polygon_position;

void vertex() {
	polygon_position = VERTEX;
}

void fragment() {
	vec3 position = vec3(polygon_position, 1.0);
	vec3 projected = vec3(
		dot(homography_row_0, position),
		dot(homography_row_1, position),
		dot(homography_row_2, position)
	);
	vec2 perspective_uv = projected.xy / projected.z;
	vec2 sample_uv = mix(uv_min, uv_max, perspective_uv);
	vec4 source = texture(TEXTURE, sample_uv);
	float luminance = dot(source.rgb, vec3(0.299, 0.587, 0.114));
	vec3 color = mix(vec3(luminance), source.rgb, saturation);
	color *= vec3(1.0 + warmth * 0.12, 1.0 - warmth * 0.04, 1.0 - warmth * 0.30);
	float edge = smoothstep(0.22, 0.72, length((perspective_uv - vec2(0.5)) * vec2(1.0, 0.82)));
	color *= brightness * (1.0 - vignette * edge);
	float scanline = 0.5 + 0.5 * sin(perspective_uv.y * source_height * 3.14159265);
	color *= 1.0 - scanlines * scanline;
	color *= 0.99 + 0.01 * sin(TIME * 2.3);
	COLOR = vec4(color, source.a);
}
"""

var main: Control
var game_screen: Control
var game_background: TextureRect
var video_player: VideoStreamPlayer
var screen_glow: Sprite2D
var screen_backdrop: Polygon2D
var video_surface: Polygon2D
var active_background_id := ""
var active_config: Dictionary = {}


func _ready() -> void:
	for _i in range(4):
		await get_tree().process_frame
	main = get_parent() as Control
	if main == null:
		return
	game_screen = main.get("game_screen") as Control
	game_background = main.get("game_background") as TextureRect
	if game_screen == null or game_background == null:
		return
	_build_video_surface()
	get_viewport().size_changed.connect(_queue_layout)
	_sync_background()


func _process(_delta: float) -> void:
	if main == null or video_player == null:
		return
	var background_id := str(main.get("current_background"))
	if background_id != active_background_id:
		_sync_background()


func _build_video_surface() -> void:
	screen_glow = Sprite2D.new()
	screen_glow.name = "RoomScreenGlow"
	screen_glow.z_index = -17
	screen_glow.texture = _build_glow_texture()
	screen_glow.visible = false
	game_screen.add_child(screen_glow)

	screen_backdrop = Polygon2D.new()
	screen_backdrop.name = "RoomScreenBackdrop"
	screen_backdrop.z_index = -16
	screen_backdrop.color = Color.BLACK
	screen_backdrop.visible = false
	game_screen.add_child(screen_backdrop)

	video_surface = Polygon2D.new()
	video_surface.name = "RoomScreenVideoSurface"
	video_surface.z_index = -15
	video_surface.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	video_surface.material = _build_screen_material()
	video_surface.visible = false
	game_screen.add_child(video_surface)

	video_player = VideoStreamPlayer.new()
	video_player.name = "RoomScreenVideo"
	video_player.z_index = -100
	video_player.mouse_filter = Control.MOUSE_FILTER_IGNORE
	video_player.expand = true
	video_player.position = Vector2(-4096.0, -4096.0)
	video_player.size = Vector2.ONE
	video_player.visible = false
	game_screen.add_child(video_player)


func _build_screen_material() -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = SCREEN_SHADER
	var material := ShaderMaterial.new()
	material.shader = shader
	return material


func _build_glow_texture() -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	gradient.colors = PackedColorArray([
		Color(1.0, 0.76, 0.48, 1.0),
		Color(0.92, 0.55, 0.28, 0.35),
		Color(0.75, 0.38, 0.16, 0.0),
	])
	var texture := GradientTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = gradient
	return texture


func _sync_background() -> void:
	active_background_id = str(main.get("current_background"))
	active_config = {}
	video_player.stop()
	video_player.visible = false
	screen_glow.visible = false
	screen_backdrop.visible = false
	video_surface.visible = false
	video_surface.texture = null

	var dm: Variant = DataAccess.dm()
	var room: Dictionary = dm.call("get_room_for_background", active_background_id) if dm != null else {}
	var raw_config: Variant = room.get("screen_video", {})
	if typeof(raw_config) != TYPE_DICTIONARY:
		return
	active_config = (raw_config as Dictionary).duplicate(true)
	var path := str(active_config.get("path", ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return
	var stream := ResourceLoader.load(path) as VideoStream
	if stream == null:
		return

	video_player.stream = stream
	video_player.loop = bool(active_config.get("loop", true))
	video_player.volume = 0.0 if bool(active_config.get("muted", true)) else clampf(float(active_config.get("volume", 1.0)), 0.0, 1.0)
	video_surface.texture = video_player.get_video_texture()
	_apply_appearance()
	_apply_layout()
	screen_glow.visible = true
	screen_backdrop.visible = str(active_config.get("fit_mode", "perspective")) == "contain"
	video_surface.visible = true
	video_player.visible = true
	video_player.play()


func _queue_layout() -> void:
	call_deferred("_apply_layout")


func _apply_layout() -> void:
	if video_surface == null or game_background == null or game_background.texture == null:
		return
	var raw_quad: Variant = active_config.get("quad", [])
	if typeof(raw_quad) != TYPE_ARRAY or (raw_quad as Array).size() != 4:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var texture_size := game_background.texture.get_size()
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0 or texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var scale := maxf(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
	var rendered_size := texture_size * scale
	var rendered_origin := (viewport_size - rendered_size) * 0.5
	var screen_quad := PackedVector2Array()
	for raw_point in raw_quad as Array:
		if typeof(raw_point) != TYPE_ARRAY or (raw_point as Array).size() != 2:
			return
		var point := raw_point as Array
		screen_quad.append(rendered_origin + Vector2(
			float(point[0]) * rendered_size.x,
			float(point[1]) * rendered_size.y
		))

	var source_size := _get_source_size()
	var source_aspect := source_size.x / source_size.y
	screen_backdrop.polygon = screen_quad
	var full_uv := PackedVector2Array([
		Vector2.ZERO,
		Vector2(source_size.x, 0.0),
		source_size,
		Vector2(0.0, source_size.y),
	])
	var fit_mode := str(active_config.get("fit_mode", "perspective"))
	if fit_mode == "contain":
		video_surface.polygon = _fit_contained_quad(screen_quad, source_aspect)
		video_surface.uv = full_uv
	elif fit_mode == "cover":
		video_surface.polygon = screen_quad
		video_surface.uv = _get_cover_uv(screen_quad, source_size)
	else:
		video_surface.polygon = screen_quad
		video_surface.uv = full_uv
	_apply_perspective_mapping(video_surface.polygon, video_surface.uv, source_size)
	_layout_glow(screen_quad, scale)


func _apply_appearance() -> void:
	var material := video_surface.material as ShaderMaterial
	if material == null:
		return
	material.set_shader_parameter("brightness", clampf(float(active_config.get("brightness", 0.58)), 0.0, 1.5))
	material.set_shader_parameter("saturation", clampf(float(active_config.get("saturation", 0.72)), 0.0, 1.5))
	material.set_shader_parameter("warmth", clampf(float(active_config.get("warmth", 0.16)), 0.0, 1.0))
	material.set_shader_parameter("vignette", clampf(float(active_config.get("vignette", 0.22)), 0.0, 1.0))
	material.set_shader_parameter("scanlines", clampf(float(active_config.get("scanlines", 0.025)), 0.0, 0.2))
	material.set_shader_parameter("source_height", _get_source_size().y)
	var glow_strength := clampf(float(active_config.get("glow", 0.07)), 0.0, 0.3)
	screen_glow.modulate = Color(1.0, 0.72, 0.45, glow_strength)


func _get_source_size() -> Vector2:
	var raw_size: Variant = active_config.get("source_size", [16.0, 9.0])
	if typeof(raw_size) != TYPE_ARRAY or (raw_size as Array).size() != 2:
		return Vector2(16.0, 9.0)
	var source_size := Vector2(float(raw_size[0]), float(raw_size[1]))
	if source_size.x <= 0.0 or source_size.y <= 0.0:
		return Vector2(16.0, 9.0)
	return source_size


func _get_quad_aspect(quad: PackedVector2Array) -> float:
	var average_width := (quad[0].distance_to(quad[1]) + quad[3].distance_to(quad[2])) * 0.5
	var average_height := (quad[0].distance_to(quad[3]) + quad[1].distance_to(quad[2])) * 0.5
	return average_width / average_height if average_height > 0.0 else 1.0


func _get_cover_uv(quad: PackedVector2Array, source_size: Vector2) -> PackedVector2Array:
	var surface_aspect := _get_quad_aspect(quad)
	var source_aspect := source_size.x / source_size.y
	var left := 0.0
	var top := 0.0
	var right := source_size.x
	var bottom := source_size.y
	if source_aspect > surface_aspect:
		var visible_width := source_size.y * surface_aspect
		left = (source_size.x - visible_width) * 0.5
		right = left + visible_width
	else:
		var visible_height := source_size.x / surface_aspect
		top = (source_size.y - visible_height) * 0.5
		bottom = top + visible_height
	return PackedVector2Array([
		Vector2(left, top),
		Vector2(right, top),
		Vector2(right, bottom),
		Vector2(left, bottom),
	])


func _apply_perspective_mapping(quad: PackedVector2Array, texture_uv: PackedVector2Array, source_size: Vector2) -> void:
	var rows := _get_inverse_homography(quad)
	if rows.size() != 3:
		return
	var material := video_surface.material as ShaderMaterial
	if material == null:
		return
	material.set_shader_parameter("homography_row_0", rows[0])
	material.set_shader_parameter("homography_row_1", rows[1])
	material.set_shader_parameter("homography_row_2", rows[2])
	material.set_shader_parameter("uv_min", texture_uv[0] / source_size)
	material.set_shader_parameter("uv_max", texture_uv[2] / source_size)


func _get_inverse_homography(quad: PackedVector2Array) -> PackedVector3Array:
	var p0 := quad[0]
	var p1 := quad[1]
	var p2 := quad[2]
	var p3 := quad[3]
	var dx1 := p1.x - p2.x
	var dx2 := p3.x - p2.x
	var dx3 := p0.x - p1.x + p2.x - p3.x
	var dy1 := p1.y - p2.y
	var dy2 := p3.y - p2.y
	var dy3 := p0.y - p1.y + p2.y - p3.y
	var denominator := dx1 * dy2 - dx2 * dy1
	if is_zero_approx(denominator):
		return PackedVector3Array()
	var g := (dx3 * dy2 - dx2 * dy3) / denominator
	var h := (dx1 * dy3 - dx3 * dy1) / denominator
	var a := p1.x - p0.x + g * p1.x
	var b := p3.x - p0.x + h * p3.x
	var c := p0.x
	var d := p1.y - p0.y + g * p1.y
	var e := p3.y - p0.y + h * p3.y
	var f := p0.y
	var determinant := a * (e - f * h) - b * (d - f * g) + c * (d * h - e * g)
	if is_zero_approx(determinant):
		return PackedVector3Array()
	return PackedVector3Array([
		Vector3(e - f * h, c * h - b, b * f - c * e) / determinant,
		Vector3(f * g - d, a - c * g, c * d - a * f) / determinant,
		Vector3(d * h - e * g, b * g - a * h, a * e - b * d) / determinant,
	])


func _layout_glow(quad: PackedVector2Array, background_scale: float) -> void:
	var minimum := quad[0]
	var maximum := quad[0]
	for point in quad:
		minimum = minimum.min(point)
		maximum = maximum.max(point)
	var glow_size := maximum - minimum + Vector2(70.0, 54.0) * background_scale
	screen_glow.position = (minimum + maximum) * 0.5
	screen_glow.scale = glow_size / screen_glow.texture.get_size()


func _fit_contained_quad(quad: PackedVector2Array, source_aspect: float) -> PackedVector2Array:
	var top_width := quad[0].distance_to(quad[1])
	var bottom_width := quad[3].distance_to(quad[2])
	var left_height := quad[0].distance_to(quad[3])
	var right_height := quad[1].distance_to(quad[2])
	var average_width := (top_width + bottom_width) * 0.5
	var average_height := (left_height + right_height) * 0.5
	if average_height <= 0.0 or source_aspect <= 0.0:
		return quad
	var surface_aspect := average_width / average_height
	if source_aspect > surface_aspect:
		var height_fraction := surface_aspect / source_aspect
		var vertical_margin := (1.0 - height_fraction) * 0.5
		return PackedVector2Array([
			quad[0].lerp(quad[3], vertical_margin),
			quad[1].lerp(quad[2], vertical_margin),
			quad[1].lerp(quad[2], 1.0 - vertical_margin),
			quad[0].lerp(quad[3], 1.0 - vertical_margin),
		])
	var width_fraction := source_aspect / surface_aspect
	var horizontal_margin := (1.0 - width_fraction) * 0.5
	return PackedVector2Array([
		quad[0].lerp(quad[1], horizontal_margin),
		quad[0].lerp(quad[1], 1.0 - horizontal_margin),
		quad[3].lerp(quad[2], 1.0 - horizontal_margin),
		quad[3].lerp(quad[2], horizontal_margin),
	])
