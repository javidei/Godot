extends "res://scripts/new_game_prelude_0922.gd"

const FilmCreditTextEffect0925 = preload("res://scripts/film_credit_text_effect.gd")
const MONOCRAFT_FONT_0925 := preload("res://assets/ui/fonts/Monocraft.ttf")

const PORTUGAL_NOTICE_0925 := "En este juego no se realizará mención alguna a los hechos acontecidos en Portugal, ya que es un tema bastante gastado."

const VARIANTS_0925 := [
    ["01", "LIMPIO", "compare_01_clean_print"],
    ["02", "RGB MARCADO", "compare_02_rgb_bold"],
    ["03", "PROYECCIÓN SUAVE", "compare_03_soft_projection"],
    ["04", "GRANO / SUCIEDAD", "compare_04_grainy_release"],
    ["05", "HALATION", "compare_05_halation_warm"],
    ["06", "RGB EXTREMO", "compare_06_misregister_extreme"],
    ["07", "GATE WEAVE", "compare_07_gate_weave"],
    ["08", "FLICKER / EXPOSICIÓN", "compare_08_flicker_exposure"],
    ["09", "ARCHIVO GASTADO", "compare_09_archive_dirty"],
    ["10", "CINE MARCADO", "compare_10_cinema_bold"]
]


# 0.9.25: pantalla temporal de comparación. Muestra diez configuraciones
# reutilizables a la vez para escoger visualmente el preset definitivo.
func _build_portugal_screen() -> void:
    portugal_screen = Control.new()
    portugal_screen.name = "PortugalDisclaimerCompare0925"
    portugal_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    portugal_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portugal_screen.z_index = 20
    portugal_screen.visible = false
    portugal_screen.modulate.a = 0.0
    add_child(portugal_screen)

    var header := Label.new()
    header.name = "FilmComparisonHeader0925"
    header.anchor_left = 0.03
    header.anchor_top = 0.018
    header.anchor_right = 0.97
    header.anchor_bottom = 0.075
    header.text = "COMPARATIVA DE CRÉDITOS 35 MM · ELIGE 01–10"
    header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    header.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    header.add_theme_font_override("font", MONOCRAFT_FONT_0925)
    header.add_theme_font_size_override("font_size", 17)
    header.add_theme_color_override("font_color", Color("a9a49c"))
    header.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portugal_screen.add_child(header)

    var divider := ColorRect.new()
    divider.name = "FilmComparisonDivider0925"
    divider.anchor_left = 0.5
    divider.anchor_top = 0.09
    divider.anchor_right = 0.5
    divider.anchor_bottom = 0.965
    divider.offset_left = -0.5
    divider.offset_right = 0.5
    divider.color = Color(1.0, 1.0, 1.0, 0.10)
    divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portugal_screen.add_child(divider)

    for index in range(VARIANTS_0925.size()):
        _add_comparison_variant_0925(index, VARIANTS_0925[index])


func _add_comparison_variant_0925(index: int, variant: Array) -> void:
    var column := index % 2
    var row := int(index / 2)

    var x0 := 0.035 + float(column) * 0.495
    var x1 := x0 + 0.435
    var row_top := 0.092 + float(row) * 0.174

    var title := Label.new()
    title.name = "FilmVariantTitle%s0925" % str(variant[0])
    title.anchor_left = x0
    title.anchor_top = row_top
    title.anchor_right = x1
    title.anchor_bottom = row_top + 0.032
    title.text = "%s · %s" % [str(variant[0]), str(variant[1])]
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    title.add_theme_font_override("font", MONOCRAFT_FONT_0925)
    title.add_theme_font_size_override("font_size", 13)
    title.add_theme_color_override("font_color", Color("8c8780"))
    title.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portugal_screen.add_child(title)

    var paragraph := Label.new()
    paragraph.name = "PortugalVariant%s0925" % str(variant[0])
    paragraph.anchor_left = x0
    paragraph.anchor_top = row_top + 0.032
    paragraph.anchor_right = x1
    paragraph.anchor_bottom = row_top + 0.158
    paragraph.text = PORTUGAL_NOTICE_0925
    paragraph.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
    paragraph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    paragraph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    paragraph.add_theme_font_override("font", MONOCRAFT_FONT_0925)
    paragraph.add_theme_font_size_override("font_size", 14)
    paragraph.add_theme_color_override("font_color", Color("eee9e1"))
    paragraph.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    paragraph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portugal_screen.add_child(paragraph)

    var film_effect := FilmCreditTextEffect0925.attach(paragraph, str(variant[2]))
    if film_effect != null:
        film_effect.name = "FilmVariantEffect%s0925" % str(variant[0])
