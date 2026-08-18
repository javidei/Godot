extends "res://scripts/naranjal_studio_splash_v0914.gd"


# Desde 0.9.16 el arranque solo conserva la petición inicial de pantalla
# completa. El aviso de Portugal y el logo de Naranjal Studio pertenecen al
# comienzo de una nueva partida, no al lanzamiento de la aplicación.
func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_STOP
    z_index = 100
    _build_splash()
    _build_fullscreen_prompt()
    await get_tree().process_frame
    await _run_fullscreen_prompt()
    await _prepare_main_scene()
    await _reveal_prepared_main()
