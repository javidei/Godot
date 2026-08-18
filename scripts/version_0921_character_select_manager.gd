extends "res://scripts/version_0920_character_select_manager.gd"


# 0.9.21: el preludio emite su final mientras mantiene la pantalla totalmente
# negra. Aprovechamos ese mismo frame para crear la partida y arrancar la
# introducción del Día 1 antes de que la capa de Naranjal empiece a retirarse.
# Así nunca queda un frame intermedio en el que pueda verse el mapa.
func _resume_new_game_after_prelude_0920() -> void:
	super()
	if main == null:
		return
	var narrative_days := main.get_node_or_null("NarrativeDayManager")
	if narrative_days == null or not narrative_days.has_method("_begin_day_intro"):
		return
	var raw_state: Variant = main.get("state")
	if typeof(raw_state) != TYPE_DICTIONARY:
		return
	var state := raw_state as Dictionary
	if state.is_empty() or typeof(state.get("player", null)) != TYPE_DICTIONARY:
		return
	var progress: Variant = state.get("narrative_progress", {})
	if typeof(progress) == TYPE_DICTIONARY:
		var day_states: Variant = (progress as Dictionary).get("day_states", {})
		if typeof(day_states) == TYPE_DICTIONARY:
			var day_state: Variant = (day_states as Dictionary).get("1", {})
			if typeof(day_state) == TYPE_DICTIONARY and bool((day_state as Dictionary).get("intro_seen", false)):
				return
	narrative_days.call("_begin_day_intro")
