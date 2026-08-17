extends "res://scripts/naranjal_studio_splash.gd"

const PORTUGAL_FADE_IN_0914 := 4.0
const PORTUGAL_HOLD_0914 := 4.4
const PORTUGAL_FADE_OUT_0914 := 4.5


func _build_portugal_screen() -> void:
    portugal_screen = Control.new()
    portugal_screen.name = "PortugalDisclaimer0914"
    portugal_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    portugal_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portugal_screen.z_index = 20
    portugal_screen.visible = false
    portugal_screen.modulate.a = 0.0
    add_child(portugal_screen)

    var paragraph := Label.new()
    paragraph.name = "PortugalNoticeGeorgia0914"
    paragraph.anchor_left = 0.12
    paragraph.anchor_top = 0.30
    paragraph.anchor_right = 0.88
    paragraph.anchor_bottom = 0.70
    paragraph.offset_left = 0.0
    paragraph.offset_top = 0.0
    paragraph.offset_right = 0.0
    paragraph.offset_bottom = 0.0
    paragraph.text = PORTUGAL_NOTICE
    paragraph.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    paragraph.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    paragraph.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    paragraph.add_theme_font_override("font", _system_font(PackedStringArray(["Georgia", "Times New Roman", "serif"])))
    paragraph.add_theme_font_size_override("font_size", 24)
    paragraph.add_theme_color_override("font_color", Color("eee9e1"))
    paragraph.mouse_filter = Control.MOUSE_FILTER_IGNORE
    portugal_screen.add_child(paragraph)


func _run_portugal_notice() -> void:
    portugal_screen.visible = true
    portugal_screen.modulate.a = 0.0

    var tween := create_tween()
    tween.set_trans(Tween.TRANS_SINE)
    tween.set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(portugal_screen, "modulate:a", 1.0, PORTUGAL_FADE_IN_0914)
    tween.tween_interval(PORTUGAL_HOLD_0914)
    tween.tween_property(portugal_screen, "modulate:a", 0.0, PORTUGAL_FADE_OUT_0914)
    await tween.finished

    portugal_screen.visible = false
    await get_tree().create_timer(0.35).timeout
