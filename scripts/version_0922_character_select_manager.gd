extends "res://scripts/version_0921_character_select_manager.gd"


# Antes de crear la partida y arrancar el Día 1 dejamos preparada la siguiente
# transición genérica para que nazca ya a negro total. El callback heredado
# crea después la partida y llama a _begin_day_intro() en ese mismo frame.
func _resume_new_game_after_prelude_0920() -> void:
	if main != null:
		var transition := main.get_node_or_null("Version044VisitTransitions")
		if transition != null and transition.has_method("prime_next_generic_from_black"):
			transition.call("prime_next_generic_from_black")
	super()
