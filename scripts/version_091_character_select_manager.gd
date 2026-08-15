extends "res://scripts/version_090_character_select_manager.gd"


# El slot debe existir en cuanto el protagonista queda confirmado, sin depender
# de que el primer cambio de nodo, el autosave o una salida concreta del mapa
# lleguen a ejecutarse después.
func _start_game() -> void:
	super()
	if main == null:
		return
	var raw_state: Variant = main.get("state")
	if typeof(raw_state) != TYPE_DICTIONARY:
		return
	var current_state := raw_state as Dictionary
	if current_state.is_empty() or typeof(current_state.get("player", null)) != TYPE_DICTIONARY:
		return
	main.call("_save_game", false)
