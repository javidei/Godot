extends Control

const MAIN_SCENE := preload("res://scenes/main.tscn")
const LOGO_TEXTURE := preload("res://assets/ui/naranjal-studio-logo.png")

const SHINE_SHADER := """
shader_type canvas_item;

uniform float shine_progress : hint_range(-0.5, 1.5) = -0.35;
uniform float shine_intensity : hint_range(0.0, 2.0) = 0.0;
uniform float shine_width : hint_range(0.01, 0.35) = 0.10;

void fragment() {
    vec4 tex = texture(TEXTURE, UV);
    float diagonal = UV.x + UV.y * 0.30;
    float band = 1.0 - smoothstep(0.0, shine_width, abs(diagonal - shine_progress));
    vec3 glow = vec3(1.0, 0.88, 0.56) * band * shine_intensity * tex.a;
    COLOR = vec4(tex.rgb + glow, tex.a);
}
"""

var logo: TextureRect
var fade_overlay: ColorRect
var logo_material: ShaderMaterial


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    _build_splash()
    await get_tree().process_frame
    await _play_intro()
    get_tree().change_scene_to_packed(MAIN_SCENE)


func _build_splash() -> void:
    var background := ColorRect.new()
    background.name = "SplashBackground"
    background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    background.color = Color.BLACK
    background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(background)

    logo = TextureRect.new()
    logo.name = "NaranjalStudioLogo"
    logo.anchor_left = 0.16
    logo.anchor_top = 0.06
    logo.anchor_right = 0.84
    logo.anchor_bottom = 0.94
    logo.offset_left = 0.0
    logo.offset_top = 0.0
    logo.offset_right = 0.0
    logo.offset_bottom = 0.0
    logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
    logo.texture = LOGO_TEXTURE
    add_child(logo)

    var shader := Shader.new()
    shader.code = SHINE_SHADER
    logo_material = ShaderMaterial.new()
    logo_material.shader = shader
    logo_material.set_shader_parameter("shine_progress", -0.35)
    logo_material.set_shader_parameter("shine_intensity", 0.0)
    logo.material = logo_material

    fade_overlay = ColorRect.new()
    fade_overlay.name = "SplashFadeToBlack"
    fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
    fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fade_overlay.z_index = 10
    add_child(fade_overlay)


func _play_intro() -> void:
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_IN_OUT)

    # Arranque completamente negro y fundido de entrada del logo.
    tween.tween_interval(0.12)
    tween.tween_method(Callable(self, "_set_fade_alpha"), 1.0, 0.0, 0.55)
    tween.tween_interval(0.18)

    # Un único barrido diagonal de brillo, limitado a la silueta del PNG.
    tween.tween_callback(Callable(self, "_enable_shine"))
    tween.tween_method(Callable(self, "_set_shine_progress"), -0.35, 1.30, 0.85)
    tween.tween_callback(Callable(self, "_disable_shine"))

    # El logo respira un instante y vuelve a negro antes de cargar el menú.
    tween.tween_interval(0.65)
    tween.tween_method(Callable(self, "_set_fade_alpha"), 0.0, 1.0, 0.48)
    tween.tween_interval(0.12)
    await tween.finished


func _set_fade_alpha(value: float) -> void:
    if fade_overlay == null:
        return
    var color := fade_overlay.color
    color.a = clampf(value, 0.0, 1.0)
    fade_overlay.color = color


func _set_shine_progress(value: float) -> void:
    if logo_material != null:
        logo_material.set_shader_parameter("shine_progress", value)


func _enable_shine() -> void:
    if logo_material != null:
        logo_material.set_shader_parameter("shine_intensity", 0.95)


func _disable_shine() -> void:
    if logo_material != null:
        logo_material.set_shader_parameter("shine_intensity", 0.0)
