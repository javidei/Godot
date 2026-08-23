extends "res://scripts/version_090_world_map_days.gd"


func return_to_map_from_room() -> void:
	_resolve_dependencies()
	var current_state := _state()
	if current_state.is_empty() or main == null:
		return
	var node_id := str(current_state.get("node_id", ""))
	if DataStory.character_for_node(node_id).is_empty() or node_id.ends_with("_outro_044"):
		return
	# Persistimos el checkpoint real antes de volver al sentinel técnico. Después
	# abrimos explícitamente el mapa: depender de efectos laterales de _go_to()
	# dejaba el juego en la habitación con el sentinel ya guardado.
	main.call("_save_game", false)
	main.call("_go_to", VISIT_NODE, false)
	open_selector(_state())
