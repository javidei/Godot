extends "res://scripts/main_data_driven.gd"


# Cualquier acceso al menú durante una partida debe actuar como punto de
# guardado. El botón de menú del HUD llama directamente a _show_menu(), por lo
# que no pasaba por el _leave_to_menu() del mapa y podía abandonar el estado
# actual sin forzar el slot a disco.
func _show_menu() -> void:
	var has_player := not state.is_empty() and typeof(state.get("player", null)) == TYPE_DICTIONARY
	if has_player:
		_save_game(false)
	super()
	var save_slots := get_node_or_null("SaveSlotsManager")
	if save_slots != null and save_slots.has_method("_refresh_continue_state"):
		save_slots.call("_refresh_continue_state")
