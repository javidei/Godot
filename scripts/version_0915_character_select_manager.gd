extends "res://scripts/version_091_character_select_manager.gd"


func _build_selection_view() -> Control:
	var view := super()
	# El antiguo flujo permitía crear un protagonista rellenando un formulario.
	# Desde 0.9.15 la alternativa a los personajes del grupo es un invitado fijo,
	# sin datos que completar.
	for node in view.find_children("*", "Label", true, false):
		var label := node as Label
		if label != null and label.text.contains("También puedes crear un protagonista nuevo"):
			label.text = "El personaje que elijas serás tú y no aparecerá entre los encuentros. También puedes entrar directamente como Invitado al grupo."
	return view


func _build_creation_view() -> Control:
	# Se conserva un Control vacío por compatibilidad con el flujo heredado,
	# pero ya no existe una pantalla/formulario de creación de personaje.
	var view := Control.new()
	view.name = "GuestCompatibilityView0915"
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.visible = false
	return view


func _make_custom_card() -> Button:
	var button := Button.new()
	button.name = "Character_Custom"
	button.text = ""
	button.custom_minimum_size = Vector2(210, 210)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.055, 0.038, 0.033, 0.95), Color(0.55, 0.48, 0.40, 0.55), 1, 14))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.11, 0.07, 0.05, 0.98), Color("efc371"), 2, 14))
	button.add_theme_stylebox_override("focus", _panel_style(Color(0.11, 0.07, 0.05, 0.98), Color("ffe0a0"), 2, 14))
	_bind_click_once(button)
	button.pressed.connect(_select_guest_character)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 14)
	button.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	var kicker := Label.new()
	kicker.text = "INVITADO"
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kicker.add_theme_color_override("font_color", Color("f2c97e"))
	kicker.add_theme_font_size_override("font_size", 14)
	kicker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(kicker)

	var title := Label.new()
	title.text = "Invitado al grupo"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("fff1dc"))
	title.add_theme_font_size_override("font_size", 20)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)

	var info := Label.new()
	info.text = "Entrar directamente · sin rellenar datos"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_color_override("font_color", Color(0.79, 0.73, 0.66, 0.92))
	info.add_theme_font_size_override("font_size", 11)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(info)
	return button


func _select_guest_character() -> void:
	pending_profile = {
		"id": "custom",
		"name": "Invitado",
		"display_name": "Invitado",
		"gender": "No especificar",
		"appearance": "",
		"role": "invitado",
		"custom": true,
		"guest": true
	}
	_start_game()


# Si algún callback heredado intentase abrir el creador, lo redirigimos al
# invitado para que nunca reaparezca el formulario antiguo.
func _show_creation() -> void:
	_select_guest_character()


func _confirm_custom_character() -> void:
	_select_guest_character()
