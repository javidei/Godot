extends "res://scripts/new_game_prelude_0922.gd"

const FilmCreditTextEffect0923 = preload("res://scripts/film_credit_text_effect.gd")
const MONOCRAFT_FONT_0923 := preload("res://assets/ui/fonts/Monocraft.ttf")
const PORTUGAL_NOTICE_0923 := "En este juego no se realizará mención alguna a los hechos acontecidos en Portugal, ya que es un tema bastante gastado."


# 0.9.23 aplica al aviso de Portugal el preset reutilizable de créditos de
# película analógica. El flujo y los tiempos del preludio siguen heredándose de
# 0.9.22; únicamente cambia la construcción visual del texto.
func _build_portugal_screen() -> void:
    portugal_screen = Control.new()
    portugal_screen.name = "PortugalDisclaimer0923"
    portugal_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    portugal_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portugal_screen.z_index = 20
    portugal_screen.visible = false
    portugal_screen.modulate.a = 0.0
    add_child(portugal_screen)

    var paragraph := Label.new()
    paragraph.name = "PortugalNoticeMonocraft0923"
    paragraph.anchor_left = 0.12
    paragraph.anchor_top = 0.30
    paragraph.anchor_right = 0.88
    paragraph.anchor_bottom = 0.70
    paragraph.text = PORTUGAL_NOTICE_0923
    paragraph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    paragraph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    paragraph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    paragraph.add_theme_font_override("font", MONOCRAFT_FONT_0923)
    paragraph.add_theme_font_size_override("font_size", 24)
    paragraph.add_theme_color_override("font_color", Color("eee9e1"))
    paragraph.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    paragraph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portugal_screen.add_child(paragraph)

    var film_effect := FilmCreditTextEffect0923.attach(paragraph, "subtle_35mm_titles")
    if film_effect != null:
        film_effect.name = "PortugalFilmCreditEffect0923"
