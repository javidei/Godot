extends Control

signal fullscreen_confirmed

const MAIN_SCENE := preload("res://scenes/main.tscn")
const LOGO_TEXTURE := preload("res://assets/ui/naranjal-studio-logo.png")
const DEJAVU_SERIF_BOLD := preload("res://assets/ui/fonts/DejaVuSerif-Bold.ttf")

const FULLSCREEN_TEXT := "PULSA PARA ACTIVAR LA PANTALLA COMPLETA\n\nESTE JUEGO SE DISFRUTA MEJOR ASÍ"
const PORTUGAL_NOTICE := "En este juego no se realizará mención alguna a los hechos acontecidos en Portugal, ya que es un tema bastante gastado."

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
const DISCLAIMER_FADE_IN_SECONDS := 1.65
const DISCLAIMER_HOLD_SECONDS := 4.4
const DISCLAIMER_FADE_OUT_SECONDS := 1.85

var splash_background: ColorRect
var logo: TextureRect
var fade_overlay: ColorRect
var logo_material: ShaderMaterial
var prepared_main: Control

var fullscreen_prompt: Control
var fullscreen_message: Label
var portugal_screen: Control
var startup_phase := ""
var fullscreen_request_consumed := false


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    z_index = 100
    _build_splash()
    _build_fullscreen_prompt()
    _build_portugal_screen()
    await get_tree().process_frame
    await _run_fullscreen_prompt()
    await _run_portugal_notice()
    await _play_opening()
    await _prepare_main_scene()
    await get_tree().create_timer(LOGO_HOLD_SECONDS).timeout
    await _fade_to_black()
    await _reveal_prepared_main()


func _input(event: InputEvent) -> void:
    if startup_phase != "fullscreen" or fullscreen_request_consumed:
        return

    var confirmed := false
    if event is InputEventMouseButton:
        confirmed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT
    elif event is InputEventScreenTouch:
        confirmed = event.pressed
    elif event is InputEventKey:
        confirmed = event.pressed and not event.echo
    elif event is InputEventJoypadButton:
        confirmed = event.pressed

    if not confirmed:
        return

    fullscreen_request_consumed = true
    _request_fullscreen()
    fullscreen_confirmed.emit()
    get_viewport().set_input_as_handled()


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


func _build_fullscreen_prompt() -> void:
    fullscreen_prompt = Control.new()
    fullscreen_prompt.name = "FullscreenPrompt092"
    fullscreen_prompt.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    fullscreen_prompt.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fullscreen_prompt.z_index = 20
    add_child(fullscreen_prompt)

    fullscreen_message = Label.new()
    fullscreen_message.name = "FullscreenPromptText092"
    fullscreen_message.anchor_left = 0.08
    fullscreen_message.anchor_top = 0.30
    fullscreen_message.anchor_right = 0.92
    fullscreen_message.anchor_bottom = 0.70
    fullscreen_message.offset_left = 0.0
    fullscreen_message.offset_top = 0.0
    fullscreen_message.offset_right = 0.0
    fullscreen_message.offset_bottom = 0.0
    fullscreen_message.text = FULLSCREEN_TEXT
    fullscreen_message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    fullscreen_message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    fullscreen_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    fullscreen_message.add_theme_font_override("font", _system_font(PackedStringArray(["Courier New", "Liberation Mono", "DejaVu Sans Mono"])))
    fullscreen_message.add_theme_font_size_override("font_size", 25)
    fullscreen_message.add_theme_color_override("font_color", Color("a6a2ff"))
    fullscreen_message.add_theme_color_override("font_outline_color", Color(0.05, 0.04, 0.10, 0.95))
    fullscreen_message.add_theme_constant_override("outline_size", 4)
    fullscreen_message.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fullscreen_prompt.add_child(fullscreen_message)

    var hint := Label.new()
    hint.name = "FullscreenPromptHint092"
    hint.anchor_left = 0.12
    hint.anchor_top = 0.72
    hint.anchor_right = 0.88
    hint.anchor_bottom = 0.82
    hint.text = "CLIC · TOQUE · TECLA · MANDO"
    hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    hint.add_theme_font_override("font", _system_font(PackedStringArray(["Courier New", "Liberation Mono", "DejaVu Sans Mono"])))
    hint.add_theme_font_size_override("font_size", 14)
    hint.add_theme_color_override("font_color", Color(0.58, 0.56, 0.86, 0.82))
    hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fullscreen_prompt.add_child(hint)


func _build_portugal_screen() -> void:
    portugal_screen = Control.new()
    portugal_screen.name = "PortugalDisclaimer092"
    portugal_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    portugal_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portugal_screen.z_index = 20
    portugal_screen.visible = false
    portugal_screen.modulate.a = 0.0
    add_child(portugal_screen)

    var content := VBoxContainer.new()
    content.name = "PortugalFontComparison092"
    content.anchor_left = 0.075
    content.anchor_top = 0.075
    content.anchor_right = 0.925
    content.anchor_bottom = 0.925
    content.offset_left = 0.0
    content.offset_top = 0.0
    content.offset_right = 0.0
    content.offset_bottom = 0.0
    content.alignment = BoxContainer.ALIGNMENT_CENTER
    content.add_theme_constant_override("separation", 24)
    content.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portugal_screen.add_child(content)

    _add_notice_sample(content, DEJAVU_SERIF_BOLD, "DejaVu Serif Bold", 21)
    _add_notice_sample(content, _system_font(PackedStringArray(["Georgia", "Times New Roman", "serif"])), "Georgia", 21)
    _add_notice_sample(content, _system_font(PackedStringArray(["Courier New", "Liberation Mono", "DejaVu Sans Mono"])), "Courier New", 20)


func _add_notice_sample(parent: VBoxContainer, font: Font, font_name: String, font_size: int) -> void:
    var block := VBoxContainer.new()
    block.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    block.add_theme_constant_override("separation", 5)
    block.mouse_filter = Control.MOUSE_FILTER_IGNORE
    parent.add_child(block)

    var paragraph := Label.new()
    paragraph.text = PORTUGAL_NOTICE
    paragraph.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    paragraph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    paragraph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    paragraph.add_theme_font_override("font", font)
    paragraph.add_theme_font_size_override("font_size", font_size)
    paragraph.add_theme_color_override("font_color", Color("eee9e1"))
    paragraph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    block.add_child(paragraph)

    var font_label := Label.new()
    font_label.text = "Fuente: " + font_name
    font_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    font_label.add_theme_font_override("font", _system_font(PackedStringArray(["Arial", "Helvetica", "sans-serif"])))
    font_label.add_theme_font_size_override("font_size", 12)
    font_label.add_theme_color_override("font_color", Color(0.58, 0.56, 0.53, 0.88))
    font_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    block.add_child(font_label)


func _system_font(names: PackedStringArray) -> Font:
    var font := SystemFont.new()
    font.font_names = names
    return font


func _run_fullscreen_prompt() -> void:
    startup_phase = "fullscreen"
    fullscreen_request_consumed = false
    fullscreen_prompt.visible = true
    fullscreen_prompt.modulate.a = 1.0
    fullscreen_message.modulate.a = 1.0

    var blink := create_tween()
    blink.set_loops()
    blink.set_trans(Tween.TRANS_SINE)
    blink.set_ease(Tween.EASE_IN_OUT)
    blink.tween_property(fullscreen_message, "modulate:a", 0.22, 0.58)
    blink.tween_property(fullscreen_message, "modulate:a", 1.0, 0.58)

    await fullscreen_confirmed
    startup_phase = ""
    blink.kill()
    fullscreen_message.modulate.a = 1.0

    var fade := create_tween()
    fade.set_trans(Tween.TRANS_SINE)
    fade.set_ease(Tween.EASE_IN_OUT)
    fade.tween_property(fullscreen_prompt, "modulate:a", 0.0, 0.38)
    await fade.finished
    fullscreen_prompt.visible = false
    await get_tree().create_timer(0.25).timeout


func _request_fullscreen() -> void:
    var mode := DisplayServer.window_get_mode()
    if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
        return
    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _run_portugal_notice() -> void:
    portugal_screen.visible = true
    portugal_screen.modulate.a = 0.0

    var tween := create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(portugal_screen, "modulate:a", 1.0, DISCLAIMER_FADE_IN_SECONDS)
    tween.tween_interval(DISCLAIMER_HOLD_SECONDS)
    tween.tween_property(portugal_screen, "modulate:a", 0.0, DISCLAIMER_FADE_OUT_SECONDS)
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
