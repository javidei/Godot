extends "res://scripts/naranjal_studio_splash_v0914.gd"

signal prelude_finished


# Preludio exclusivo de Nueva partida: Portugal -> Naranjal Studio ->
# transición al flujo narrativo que ya existía.
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

    # El siguiente flujo se prepara mientras seguimos completamente a negro.
    # Después retiramos el fondo del splash y revelamos suavemente la pantalla
    # que corresponda debajo.
    if logo != null:
        logo.visible = false
    if splash_background != null:
        splash_background.visible = false

    prelude_finished.emit()
    await get_tree().process_frame
    await get_tree().process_frame

    var reveal := create_tween()
    reveal.set_trans(Tween.TRANS_SINE)
    reveal.set_ease(Tween.EASE_IN_OUT)
    reveal.tween_method(Callable(self, "_set_fade_alpha"), 1.0, 0.0, MENU_REVEAL_SECONDS)
    await reveal.finished
    queue_free()


func _build_splash() -> void:
    super()
    if logo == null:
        return

    # El rectángulo anterior era 0.68 x 0.88 del viewport. Conservamos su
    # centro y reducimos ambas dimensiones exactamente a la mitad.
    logo.anchor_left = 0.33
    logo.anchor_top = 0.28
    logo.anchor_right = 0.67
    logo.anchor_bottom = 0.72
    logo.offset_left = 0.0
    logo.offset_top = 0.0
    logo.offset_right = 0.0
    logo.offset_bottom = 0.0
