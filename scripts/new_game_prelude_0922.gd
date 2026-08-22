extends Control

signal prelude_finished

const LOGO_TEXTURE := preload("res://assets/ui/naranjal-studio-logo.png")
const MONOCRAFT_FONT := preload("res://assets/ui/fonts/Monocraft.ttf")

const INTRO_QUOTES := [
    {
        "text": "Dicen que todas las buenas historias empiezan con alguien tomando una mala decisión.",
        "source": "Leído en un azucarillo del Bar Ávila"
    },
    {
        "text": "Con los años uno olvida los detalles. Por desgracia, los demás no.",
        "source": "Anotado en una servilleta del Bar Ávila"
    },
    {
        "text": "Hay recuerdos que mejoran con el tiempo. Otros solo se vuelven más sospechosos.",
        "source": "Filosofía encontrada junto a una máquina de tabaco"
    },
    {
        "text": "Toda pandilla tiene una historia que nadie cuenta igual dos veces.",
        "source": "Leído en la parte de atrás de un ticket de bar"
    },
    {
        "text": "Si algo ocurrió hace muchos años y todos lo recuerdan distinto, probablemente merece otra ronda.",
        "source": "Sabiduría popular del Bar Ávila"
    },
    {
        "text": "Volver a ver a viejos amigos es fácil. Recordar por qué dejaste de verlos ya es otra historia.",
        "source": "Escrito a boli en una mesa que no era nuestra"
    },
    {
        "text": "Nadie sospecha del pasado hasta que el pasado empieza a hacer cosas raras.",
        "source": "Leído en un azucarillo ligeramente mojado"
    },
    {
        "text": "Las mejores leyendas suelen empezar con alguien diciendo: yo estaba allí.",
        "source": "Atribuido a un señor del Bar Ávila que parecía saber demasiado"
    },
    {
        "text": "Una amistad puede sobrevivir al tiempo, la distancia y, con suerte, a ciertas decisiones cuestionables.",
        "source": "Máxima encontrada debajo de una tapa de cerveza"
    },
    {
        "text": "Esta historia está basada en hechos reales. Lo preocupante es averiguar cuáles.",
        "source": "Leído en un azucarillo del Bar Ávila"
    }
]

const QUOTE_FADE_IN_SECONDS := 4.0
const QUOTE_HOLD_SECONDS := 3.4
const QUOTE_FADE_OUT_SECONDS := 4.5
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
var intro_quote_screen: Control


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    z_index = 500
    _build_splash()
    _build_intro_quote_screen()
    await get_tree().process_frame
    await _run_intro_quote()
    await _play_opening()
    await get_tree().create_timer(LOGO_HOLD_SECONDS).timeout
    await _fade_to_black()

    if logo != null:
        logo.visible = false
    if splash_background != null:
        splash_background.visible = false

    # El callback prepara la partida y la transición del Día 1 mientras este
    # overlay todavía cubre la pantalla completamente en negro.
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
    splash_background.name = "NewGameSplashBackground0922"
    splash_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    splash_background.color = Color.BLACK
    splash_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(splash_background)

    logo = TextureRect.new()
    logo.name = "NaranjalStudioLogo0922"
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
    fade_overlay.name = "NewGameFadeToBlack0922"
    fade_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
    fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    fade_overlay.z_index = 10
    add_child(fade_overlay)


func _build_intro_quote_screen() -> void:
    intro_quote_screen = Control.new()
    intro_quote_screen.name = "StoryOpeningQuote0937"
    intro_quote_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    intro_quote_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
    intro_quote_screen.z_index = 20
    intro_quote_screen.visible = false
    intro_quote_screen.modulate.a = 0.0
    add_child(intro_quote_screen)

    var rng := RandomNumberGenerator.new()
    rng.randomize()
    var selected: Dictionary = INTRO_QUOTES[rng.randi_range(0, INTRO_QUOTES.size() - 1)]

    var paragraph := Label.new()
    paragraph.name = "StoryOpeningQuoteText0937"
    paragraph.anchor_left = 0.12
    paragraph.anchor_top = 0.24
    paragraph.anchor_right = 0.88
    paragraph.anchor_bottom = 0.60
    paragraph.text = str(selected.get("text", ""))
    paragraph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    paragraph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    paragraph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    paragraph.add_theme_font_override("font", MONOCRAFT_FONT)
    paragraph.add_theme_font_size_override("font_size", 24)
    paragraph.add_theme_color_override("font_color", Color("eee9e1"))
    paragraph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    intro_quote_screen.add_child(paragraph)

    var source := Label.new()
    source.name = "StoryOpeningQuoteSource0937"
    source.anchor_left = 0.16
    source.anchor_top = 0.58
    source.anchor_right = 0.84
    source.anchor_bottom = 0.73
    source.text = "— " + str(selected.get("source", ""))
    source.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    source.vertical_alignment = VERTICAL_ALIGNMENT_TOP
    source.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    source.add_theme_font_override("font", MONOCRAFT_FONT)
    source.add_theme_font_size_override("font_size", 17)
    source.add_theme_color_override("font_color", Color("aaa69f"))
    source.mouse_filter = Control.MOUSE_FILTER_IGNORE
    intro_quote_screen.add_child(source)


func _run_intro_quote() -> void:
    intro_quote_screen.visible = true
    intro_quote_screen.modulate.a = 0.0

    var tween := create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(intro_quote_screen, "modulate:a", 1.0, QUOTE_FADE_IN_SECONDS)
    tween.tween_interval(QUOTE_HOLD_SECONDS)
    tween.tween_property(intro_quote_screen, "modulate:a", 0.0, QUOTE_FADE_OUT_SECONDS)
    await tween.finished

    intro_quote_screen.visible = false
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
