extends "res://scripts/save_slots_manager.gd"


func _patch_main_menu() -> void:
	new_button = _find_button_with_text(menu_content, "Nueva partida")
	continue_button = _find_button_with_text(menu_content, "Continuar")
	if new_button != null:
		_disconnect_pressed_methods(new_button, ["_start_new_game", "open_selection", "_begin_new_game", "open_new_game_slots"])
		new_button.pressed.connect(open_new_game_slots)
	if continue_button != null:
		_disconnect_pressed_methods(continue_button, ["_continue_game", "_continue_with_migration", "continue_last_slot"])
		continue_button.pressed.connect(continue_last_slot)

	# La fila principal forma una pareja estable Nueva partida + Continuar. El
	# acceso a Partidas vive justo debajo para no romper el layout ni los tests
	# heredados que protegen esa composición en PC y móvil.
	var primary_row := menu_content.find_child("MenuPrimaryActions045", true, false) as HBoxContainer
	manage_button = main.call("_make_button", "Partidas", false) as Button
	manage_button.name = "ManageSaveSlotsButton070"
	manage_button.tooltip_text = "Ver, cargar o borrar partidas guardadas"
	manage_button.custom_minimum_size = Vector2(0, 54)
	manage_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	manage_button.add_theme_font_size_override("font_size", 16)
	manage_button.pressed.connect(open_manage_slots)
	menu_content.add_child(manage_button)
	if primary_row != null:
		menu_content.move_child(manage_button, mini(primary_row.get_index() + 1, menu_content.get_child_count() - 1))
	_bind_click(manage_button)


func _apply_layout() -> void:
	if slots_panel == null or slots_grid == null:
		return
	var viewport := get_viewport().get_visible_rect().size
	var portrait := viewport.y > viewport.x
	var narrow := viewport.x < 760.0
	slots_grid.columns = 1 if portrait or narrow else 2
	slots_panel.anchor_left = 0.025 if portrait else 0.045
	slots_panel.anchor_right = 0.975 if portrait else 0.955
	slots_panel.anchor_top = 0.025 if portrait else 0.045
	slots_panel.anchor_bottom = 0.975 if portrait else 0.955
	if slots_title != null:
		slots_title.add_theme_font_size_override("font_size", 23 if portrait or narrow else 29)
	# El CenterContainer del diálogo de borrado se centra solo. No hacemos un
	# find_child vacío: además de no ser necesario, Godot lo registra como error.
	for raw_card in slot_cards.values():
		var card := raw_card as PanelContainer
		if card != null:
			card.custom_minimum_size.x = 270.0 if portrait or narrow else 360.0
