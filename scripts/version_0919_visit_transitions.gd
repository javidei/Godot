extends "res://scripts/version_0917_visit_transitions.gd"


# El preludio termina directamente sobre la partida ya preparada. La pantalla
# heredada «Los hechos acontecieron desde 2026.» desaparece por completo.
func _on_new_game_prelude_finished(on_finished: Callable) -> void:
	_new_game_prelude_0917 = null
	if on_finished.is_valid():
		on_finished.call()
