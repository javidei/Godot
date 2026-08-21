extends "res://scripts/version_0921_character_select_manager.gd"


# Las tarjetas del selector se construyen una sola vez al arrancar la escena.
# Como la apariencia puede cambiar después desde Extras -> Personajes, refrescamos
# todas las miniaturas cada vez que se abre Nueva partida para usar la skin EN USO.
func open_selection() -> void:
	super()
	_refresh_selected_skin_portraits_0933()


func _show_character_selection() -> void:
	super()
	_refresh_selected_skin_portraits_0933()


func refresh_character_portrait(character_id: String) -> void:
	if character_grid == null or character_id.is_empty():
		return
	var card := character_grid.get_node_or_null("Character_" + character_id) as Button
	if card == null:
		return
	var portrait := card.find_child("Portrait", true, false) as TextureRect
	if portrait != null:
		portrait.texture = _character_portrait(character_id)


func _refresh_selected_skin_portraits_0933() -> void:
	for button in character_cards:
		if button == null:
			continue
		var node_name := str(button.name)
		if not node_name.begins_with("Character_") or node_name == "Character_Custom":
			continue
		refresh_character_portrait(node_name.trim_prefix("Character_"))


# Antes de crear la partida y arrancar el Día 1 dejamos preparada la siguiente
# transición genérica para que nazca ya a negro total. El callback heredado
# crea después la partida y llama a _begin_day_intro() en ese mismo frame.
func _resume_new_game_after_prelude_0920() -> void:
	if main != null:
		var transition := main.get_node_or_null("Version044VisitTransitions")
		if transition != null and transition.has_method("prime_next_generic_from_black"):
			transition.call("prime_next_generic_from_black")
	super()
