extends Control

signal prelude_finished

const LOGO_TEXTURE := preload("res://assets/ui/naranjal-studio-logo.png")
const PORTUGAL_NOTICE := "En este juego no se realizará mención alguna a los hechos acontecidos en Portugal, ya que es un tema bastante gastado."

const PORTUGAL_FADE_IN_SECONDS := 4.0
const PORTUGAL_HOLD_SECONDS := 4.4
const PORTUGAL_FADE_OUT_SECONDS := 4.5
const LOGO_HOLD_SECONDS := 2.65
const REVEAL_SECONDS := 0.35

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

var splash_background: ColorRect
var logo: TextureRect
var fade_overlay: ColorRect
var logo_material: ShaderMaterial
var portugal_screen: Control


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    z_index = 500
    _build_splash()
    _build_portugal_screen()
    await get_tree().process_frame
    await _run_portugal_notice()
    await _play_opening()
    await get_tree().create_timer(LOGO_HOLD_SECONDS).timeout
    await _fade_to_black()

    if logo != null:
        logo.visible = false
    if splash_background != null:
        splash_background.visible = false

    # El flujo normal de nueva partida se prepara detrás mientras esta capa
    # continúa completamente a negro, evitando cualquier destello del menú.
    prelude_finished.emit()
    await get_tree().process_frame
    await get_tree().process_frame

    var reveal := create_tween()
    reveal.set_trans(Tween.TRANS_SINE)
    reveal.set_ease(Tween.EASE_IN_OUT)
    reveal.tween_method(Callable(self, "_set_fade_alpha"), 1.0, 0.0, REVEAL_SECONDS)
    await reveal.finished
    queue_free()


func _build_splash() -> void:
    splash_background = ColorRect.new()
    splash_background.name = "NewGameSplashBackground0917"
    splash_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    splash_background.color = Color.BLACK
    splash_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(splash_background)

    logo = TextureRect.new()
    logo.name = "NaranjalStudioLogo0917"
    # Mitad exacta del rectángulo usado originalmente, manteniendo el centro.
    logo.anchor_left = 0.33
    logo.anchor_top = 0.28
    logo.anchor_right = 0.67
    logo.anchor_bottom = 0.72
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
    fade_overlay.name = "NewGameFadeToBlack0917"
    fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
    fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fade_overlay.z_index = 10
    add_child(fade_overlay)


func _build_portugal_screen() -> void:
    portugal_screen = Control.new()
    portugal_screen.name = "PortugalDisclaimer0917"
    portugal_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    portugal_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portugal_screen.z_index = 20
    portugal_screen.visible = false
    portugal_screen.modulate.a = 0.0
    add_child(portugal_screen)

    var paragraph := Label.new()
    paragraph.name = "PortugalNoticeGeorgia0917"
    paragraph.anchor_left = 0.12
    paragraph.anchor_top = 0.30
    paragraph.anchor_right = 0.88
    paragraph.anchor_bottom = 0.70
    paragraph.text = PORTUGAL_NOTICE
    paragraph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    paragraph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    paragraph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    paragraph.add_theme_font_override("font", _system_font(PackedStringArray(["Georgia", "Times New Roman", "serif"])))
    paragraph.add_theme_font_size_override("font_size", 24)
    paragraph.add_theme_color_override("font_color", Color("eee9e1"))
    paragraph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portugal_screen.add_child(paragraph)


func _system_font(names: PackedStringArray) -> Font:
    var font := SystemFont.new()
    font.font_names = names
    return font


func _run_portugal_notice() -> void:
    portugal_screen.visible = true
    portugal_screen.modulate.a = 0.0

    var tween := create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(portugal_screen, "modulate:a", 1.0, PORTUGAL_FADE_IN_SECONDS)
    tween.tween_interval(PORTUGAL_HOLD_SECONDS)
    tween.tween_property(portugal_screen, "modulate:a", 0.0, PORTUGAL_FADE_OUT_SECONDS)
    await tween.finished

    portugal_screen.visible = false
    await get_tree().create_timer(0.35).timeout


func _play_opening() -> void:
    logo.visible = true
    splash_background.visible = true
    _set_fade_alpha(1.0)

    var tween := create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.tween_interval(0.12)
    tween.tween_method(Callable(self, "_set_fade_alpha"), 1.0, 0.0, 0.55)
    tween.tween_interval(0.18)
    tween.tween_callback(Callable(self, "_enable_shine"))
    tween.tween_method(Callable(self, "_set_shine_progress"), -0.35, 1.30, 0.85)
    tween.tween_callback(Callable(self, "_disable_shine"))
    await tween.finished


func _fade_to_black() -> void:
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_IN_OUT)
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
