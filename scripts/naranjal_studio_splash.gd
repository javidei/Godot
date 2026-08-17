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

const LOGO_HOLD_SECONDS := 2.65
const MENU_READY_MAX_FRAMES := 120
const MENU_REVEAL_SECONDS := 0.35

var splash_background: ColorRect
var logo: TextureRect
var fade_overlay: ColorRect
var logo_material: ShaderMaterial
var prepared_main: Control


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    z_index = 100
    _build_splash()
    await get_tree().process_frame
    await _play_opening()
    await _prepare_main_scene()
    await get_tree().create_timer(LOGO_HOLD_SECONDS).timeout
    await _fade_to_black()
    await _reveal_prepared_main()


func _build_splash() -> void:
    splash_background = ColorRect.new()
    splash_background.name = "SplashBackground"
    splash_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    splash_background.color = Color.BLACK
    splash_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(splash_background)

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


func _play_opening() -> void:
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


func _prepare_main_scene() -> void:
    prepared_main = MAIN_SCENE.instantiate() as Control
    if prepared_main == null:
        get_tree().change_scene_to_packed(MAIN_SCENE)
        return

    prepared_main.visible = false
    prepared_main.z_index = -100
    get_tree().root.add_child(prepared_main)

    while not prepared_main.is_node_ready():
        await get_tree().process_frame

    for _frame in range(MENU_READY_MAX_FRAMES):
        var menu_screen := prepared_main.get("menu_screen") as Control
        var menu_characters := prepared_main.get("menu_characters") as TextureRect
        var menu_video := prepared_main.find_child("MenuEclipseVideo065", true, false)
        var studio_logo := prepared_main.find_child("NaranjalStudioMenuLogo093", true, false)
        var base_ready := menu_screen != null and menu_characters != null and menu_characters.texture != null
        var deferred_ready := menu_video != null and studio_logo != null
        if base_ready and deferred_ready:
            break
        await get_tree().process_frame

    _stop_prepared_menu_music()


func _fade_to_black() -> void:
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.tween_method(Callable(self, "_set_fade_alpha"), 0.0, 1.0, 0.48)
    tween.tween_interval(0.12)
    await tween.finished


func _reveal_prepared_main() -> void:
    if prepared_main == null or not is_instance_valid(prepared_main):
        get_tree().change_scene_to_packed(MAIN_SCENE)
        return

    # Ya estamos completamente a negro. A partir de este punto el logo no debe
    # volver a participar en el render: si se desvanece el Control completo,
    # la capa negra se hace translúcida y deja ver el logo durante unos frames.
    if logo != null:
        logo.visible = false
    if splash_background != null:
        splash_background.visible = false

    prepared_main.visible = true
    prepared_main.z_index = -100
    if prepared_main.has_method("_sync_menu_music_scope"):
        prepared_main.call("_sync_menu_music_scope")
    await get_tree().process_frame
    await get_tree().process_frame

    # Revelar el menú desvaneciendo únicamente la capa negra. El logo ya está
    # oculto, por lo que no puede reaparecer durante la transición.
    var tween := create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.tween_method(Callable(self, "_set_fade_alpha"), 1.0, 0.0, MENU_REVEAL_SECONDS)
    await tween.finished

    prepared_main.z_index = 0
    get_tree().current_scene = prepared_main
    queue_free()


func _stop_prepared_menu_music() -> void:
    if prepared_main == null:
        return
    var prepared_audio := prepared_main.get("audio_manager") as Node
    if prepared_audio != null and prepared_audio.has_method("stop_menu_music"):
        prepared_audio.call("stop_menu_music")


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
