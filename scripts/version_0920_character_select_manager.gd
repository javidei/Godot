extends "res://scripts/version_0919_character_select_manager.gd"

var _waiting_for_new_game_prelude_0920 := false


# 0.9.20: confirmar protagonista no crea todavía la partida. Primero se
# reproduce Portugal -> Naranjal Studio y solo al terminar se continúa con el
# arranque heredado. De este modo el gestor de jornadas no puede mostrar
# «DÍA 1 · EL REENCUENTRO» antes de que termine el logo.
func _start_game() -> void:
	if pending_profile.is_empty():
		_show_character_selection()
		return

	if _pending_new_game_prelude_0919 and not _waiting_for_new_game_prelude_0920:
		var transition := main.get_node_or_null("Version044VisitTransitions") if main != null else null
		if transition != null and transition.has_method("play_new_game_intro"):
			_waiting_for_new_game_prelude_0920 = true
			transition.call("play_new_game_intro", Callable(self, "_resume_new_game_after_prelude_0920"))
			return
		_pending_new_game_prelude_0919 = false

	super()


func _resume_new_game_after_prelude_0920() -> void:
	_pending_new_game_prelude_0919 = false
	_waiting_for_new_game_prelude_0920 = false
	_start_game()
