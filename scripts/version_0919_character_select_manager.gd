extends "res://scripts/version_0915_character_select_manager.gd"

var _pending_new_game_prelude_0919 := false


# Desde 0.9.19 la elección de protagonista va antes del preludio cinematográfico.
# El selector de slots sigue llamando a _begin_new_game(), pero aquí solo abrimos
# la selección y dejamos marcado que, al confirmar personaje, habrá preludio.
func _begin_new_game() -> void:
	_pending_new_game_prelude_0919 = true
	open_selection()


func _start_game() -> void:
	if pending_profile.is_empty():
		_show_character_selection()
		return

	var should_play_prelude := _pending_new_game_prelude_0919
	super()

	# Si el arranque no llegó a completarse, mantenemos el selector y no lanzamos
	# Portugal/Naranjal. En el arranque correcto, el juego queda preparado detrás
	# y el preludio se añade en el mismo frame, sin mostrar la escena intermedia.
	if not should_play_prelude or main == null or flow_screen == null or flow_screen.visible:
		return
	var raw_state: Variant = main.get("state")
	if typeof(raw_state) != TYPE_DICTIONARY or typeof((raw_state as Dictionary).get("player", null)) != TYPE_DICTIONARY:
		return

	_pending_new_game_prelude_0919 = false
	var transition := main.get_node_or_null("Version044VisitTransitions")
	if transition != null and transition.has_method("play_new_game_intro"):
		transition.call("play_new_game_intro")
