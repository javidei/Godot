extends Node

const DATA_PATH := "res://data/detalles-juego.json"
const GOLD := Color("e0b25d")
const GOLD_SOFT := Color("c89b52")
const TEXT := Color("f6ead8")
const TEXT_DIM := Color("cdbda8")
const PANEL_BG := Color(0.035, 0.024, 0.02, 0.965)

var main: Control
var menu_screen: Control
var menu_content: VBoxContainer
var asset_manager
var data: Dictionary = {}
var characters: Array = []
var character_index: Dictionary = {}

var extras_button: Button
var exit_button: Button
var fullscreen_button: Button
var primary_row: HBoxContainer
var secondary_row: HBoxContainer
var exit_spacer: Control
var version_label: Label

var extras_screen: Control
var codex_panel: PanelContainer
var header_title: Label
var header_subtitle: Label
var back_button: Button
var page_host: MarginContainer
var current_page := "home"
var current_character_id := ""


func _ready() -> void:
	# Version045 reorganiza primero el menú. Este parche entra después y añade
	# Extras, manteniendo Salir como la última opción del bloque principal.
	for _i in range(24):
		await get_tree().process_frame
	main = get_parent() as Control
	if main == null:
		return
	menu_screen = main.get("menu_screen") as Control
	menu_content = main.get("menu_content") as VBoxContainer
	asset_manager = main.get("asset_manager")
	_load_data()
	_index_characters()
	_patch_main_menu()
	_build_extras_screen()
	get_viewport().size_changed.connect(_queue_layout)
	_apply_layout()


func _load_data() -> void:
	data = {}
	characters = []
	if not FileAccess.file_exists(DATA_PATH):
		push_error("No existe el archivo de datos de Extras: " + DATA_PATH)
		return
	var file := FileAccess.open(DATA_PATH, FileAccess.READ)
	if file == null:
		push_error("No se ha podido abrir el archivo de datos de Extras")
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("detalles-juego.json no contiene un objeto JSON válido")
		return
	data = parsed
	var people: Variant = data.get("personajes", [])
	if typeof(people) == TYPE_ARRAY:
		characters = people


func _index_characters() -> void:
	character_index.clear()
	for item in characters:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var person: Dictionary = item
		var id := str(person.get("id", ""))
		if not id.is_empty():
			character_index[id] = person


func _patch_main_menu() -> void:
	if menu_content == null:
		return
	primary_row = menu_content.find_child("MenuPrimaryActions045", true, false) as HBoxContainer
	secondary_row = menu_content.find_child("MenuSecondaryActions045", true, false) as HBoxContainer
	fullscreen_button = menu_content.find_child("MenuFullscreenButton", true, false) as Button
	exit_button = menu_content.find_child("ExitGameButton", true, false) as Button
	version_label = menu_content.find_child("VersionLabel", true, false) as Label

	if extras_button == null:
		extras_button = main.call("_make_button", "Extras", false) as Button
		extras_button.name = "ExtrasButton050"
		extras_button.tooltip_text = "Personajes, información, lugares y créditos"
		extras_button.custom_minimum_size = Vector2(0, 56)
		extras_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		extras_button.add_theme_font_size_override("font_size", 16)
		extras_button.pressed.connect(_open_extras)

	if secondary_row != null:
		if extras_button.get_parent() != secondary_row:
			secondary_row.add_child(extras_button)
		if fullscreen_button != null and fullscreen_button.get_parent() != secondary_row:
			fullscreen_button.reparent(secondary_row)
		if exit_button != null and exit_button.get_parent() == secondary_row:
			exit_button.reparent(menu_content)

	if exit_spacer == null:
		exit_spacer = Control.new()
		exit_spacer.name = "ExitSpacer050"
		exit_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		exit_spacer.custom_minimum_size = Vector2(0, 10)
		menu_content.add_child(exit_spacer)

	if exit_button != null:
		exit_button.custom_minimum_size = Vector2(0, 58)
		exit_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		exit_button.add_theme_font_size_override("font_size", 16)

	_reorder_menu_bottom()


func _reorder_menu_bottom() -> void:
	if menu_content == null:
		return
	var anchor_index := 0
	if secondary_row != null:
		anchor_index = secondary_row.get_index() + 1
	if exit_spacer != null:
		menu_content.move_child(exit_spacer, anchor_index)
		anchor_index += 1
	if exit_button != null:
		menu_content.move_child(exit_button, anchor_index)
		anchor_index += 1
	if version_label != null:
		menu_content.move_child(version_label, anchor_index)


func _build_extras_screen() -> void:
	extras_screen = Control.new()
	extras_screen.name = "ExtrasScreen050"
	extras_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	extras_screen.z_index = 500
	extras_screen.visible = false
	main.add_child(extras_screen)

	var background := TextureRect.new()
	background.name = "ExtrasBackground"
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if asset_manager != null:
		background.texture = asset_manager.get_background("casa_asturias")
	extras_screen.add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.018, 0.012, 0.01, 0.86)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	extras_screen.add_child(shade)

	codex_panel = PanelContainer.new()
	codex_panel.name = "CodexPanel050"
	codex_panel.anchor_left = 0.035
	codex_panel.anchor_top = 0.045
	codex_panel.anchor_right = 0.965
	codex_panel.anchor_bottom = 0.955
	codex_panel.add_theme_stylebox_override("panel", main.call("_panel_style", PANEL_BG, GOLD_SOFT, 2, 18))
	extras_screen.add_child(codex_panel)

	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 26)
	outer.add_theme_constant_override("margin_top", 20)
	outer.add_theme_constant_override("margin_right", 26)
	outer.add_theme_constant_override("margin_bottom", 22)
	codex_panel.add_child(outer)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 12)
	outer.add_child(root_box)

	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 62)
	header.add_theme_constant_override("separation", 14)
	root_box.add_child(header)

	back_button = main.call("_make_small_button", "← Volver") as Button
	back_button.name = "ExtrasBackButton050"
	back_button.custom_minimum_size = Vector2(112, 46)
	back_button.pressed.connect(_go_back)
	header.add_child(back_button)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 1)
	header.add_child(title_box)

	header_title = Label.new()
	header_title.text = "Extras"
	header_title.add_theme_color_override("font_color", Color("fff0d7"))
	header_title.add_theme_font_size_override("font_size", 31)
	title_box.add_child(header_title)

	header_subtitle = Label.new()
	header_subtitle.text = "El códice de La Octava Silla"
	header_subtitle.add_theme_color_override("font_color", TEXT_DIM)
	header_subtitle.add_theme_font_size_override("font_size", 13)
	title_box.add_child(header_subtitle)

	var line := ColorRect.new()
	line.color = Color(0.78, 0.56, 0.28, 0.55)
	line.custom_minimum_size = Vector2(0, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_box.add_child(line)

	page_host = MarginContainer.new()
	page_host.name = "ExtrasPageHost050"
	page_host.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page_host.add_theme_constant_override("margin_top", 4)
	root_box.add_child(page_host)

	_show_home()


func _open_extras() -> void:
	if extras_screen == null:
		return
	if menu_screen != null:
		menu_screen.visible = false
	extras_screen.visible = true
	_show_home()


func _close_extras() -> void:
	if extras_screen != null:
		extras_screen.visible = false
	if menu_screen != null:
		menu_screen.visible = true
	current_page = "home"
	current_character_id = ""


func _go_back() -> void:
	match current_page:
		"character_detail":
			_show_characters()
		"characters", "game_info", "places", "credits":
			_show_home()
		_:
			_close_extras()


func _clear_page() -> void:
	if page_host == null:
		return
	for child in page_host.get_children():
		child.queue_free()


func _show_home() -> void:
	current_page = "home"
	current_character_id = ""
	_set_header("Extras", "Personajes, mundo e información del proyecto")
	_clear_page()
	var box := VBoxContainer.new()
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 16)
	page_host.add_child(box)

	var intro := Label.new()
	intro.text = "Consulta el códice del grupo y los datos del juego. Todo este contenido se alimenta de detalles-juego.json."
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.add_theme_color_override("font_color", TEXT_DIM)
	intro.add_theme_font_size_override("font_size", 16)
	box.add_child(intro)

	var grid := GridContainer.new()
	grid.name = "ExtrasOptionsGrid050"
	grid.columns = 2
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	box.add_child(grid)

	_add_extra_option(grid, "Personajes", "Fichas del grupo", _show_characters, "CharactersOption050")
	_add_extra_option(grid, "Información del juego", "Historia, tono y jugabilidad", _show_game_info, "GameInfoOption050")
	_add_extra_option(grid, "Lugares", "Escenarios registrados en el JSON", _show_places, "PlacesOption050")
	_add_extra_option(grid, "Créditos", "Autoría y datos del proyecto", _show_credits, "CreditsOption050")


func _add_extra_option(parent: GridContainer, title: String, subtitle: String, callback: Callable, node_name: String) -> void:
	var button := main.call("_make_button", title + "\n" + subtitle, false) as Button
	button.name = node_name
	button.custom_minimum_size = Vector2(260, 118)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 17)
	button.pressed.connect(callback)
	parent.add_child(button)


func _show_characters() -> void:
	current_page = "characters"
	current_character_id = ""
	_set_header("Personajes", "Siete fichas del grupo")
	_clear_page()
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_host.add_child(scroll)

	var grid := GridContainer.new()
	grid.name = "CharacterCodexGrid050"
	grid.columns = 4
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 13)
	grid.add_theme_constant_override("v_separation", 13)
	scroll.add_child(grid)

	for item in characters:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var person: Dictionary = item
		var id := str(person.get("id", ""))
		var name := _person_display_name(person)
		var card := Button.new()
		card.name = "CharacterCard_" + id
		card.custom_minimum_size = Vector2(210, 235)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.clip_contents = true
		card.add_theme_stylebox_override("normal", main.call("_panel_style", Color(0.055, 0.037, 0.029, 0.97), Color(0.62, 0.43, 0.22, 0.85), 1, 12))
		card.add_theme_stylebox_override("hover", main.call("_panel_style", Color(0.095, 0.06, 0.04, 0.98), GOLD, 2, 12))
		card.pressed.connect(_show_character.bind(id))
		grid.add_child(card)

		var root := Control.new()
		root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		root.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(root)

		var portrait := TextureRect.new()
		portrait.name = "CharacterCardPortrait"
		portrait.anchor_left = 0.04
		portrait.anchor_top = 0.03
		portrait.anchor_right = 0.96
		portrait.anchor_bottom = 0.78
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CONTAINED
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.texture = _character_texture(id)
		root.add_child(portrait)

		var footer := ColorRect.new()
		footer.anchor_left = 0.0
		footer.anchor_top = 0.72
		footer.anchor_right = 1.0
		footer.anchor_bottom = 1.0
		footer.color = Color(0.02, 0.014, 0.012, 0.90)
		footer.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(footer)

		var label := Label.new()
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.text = name
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color("f5d596"))
		label.add_theme_font_size_override("font_size", 17)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		footer.add_child(label)


func _show_character(character_id: String) -> void:
	if not character_index.has(character_id):
		return
	current_page = "character_detail"
	current_character_id = character_id
	var person: Dictionary = character_index[character_id]
	var display_name := _person_display_name(person)
	_set_header(display_name, "Ficha de personaje · datos cargados desde el JSON")
	_clear_page()

	var row := HBoxContainer.new()
	row.name = "CharacterDetailRow050"
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	row.add_theme_constant_override("separation", 18)
	page_host.add_child(row)

	var portrait_panel := PanelContainer.new()
	portrait_panel.name = "CharacterPortraitPanel050"
	portrait_panel.custom_minimum_size = Vector2(320, 0)
	portrait_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait_panel.add_theme_stylebox_override("panel", main.call("_panel_style", Color(0.025, 0.017, 0.014, 0.96), Color(0.58, 0.39, 0.20, 0.90), 1, 12))
	row.add_child(portrait_panel)

	var portrait_margin := MarginContainer.new()
	portrait_margin.add_theme_constant_override("margin_left", 14)
	portrait_margin.add_theme_constant_override("margin_top", 14)
	portrait_margin.add_theme_constant_override("margin_right", 14)
	portrait_margin.add_theme_constant_override("margin_bottom", 14)
	portrait_panel.add_child(portrait_margin)

	var portrait_box := VBoxContainer.new()
	portrait_box.add_theme_constant_override("separation", 8)
	portrait_margin.add_child(portrait_box)

	var portrait := TextureRect.new()
	portrait.name = "CharacterPortrait050"
	portrait.custom_minimum_size = Vector2(0, 430)
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CONTAINED
	portrait.texture = _character_texture(character_id)
	portrait_box.add_child(portrait)

	var name_label := Label.new()
	name_label.text = str(person.get("nombre", display_name))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color("fff0d7"))
	name_label.add_theme_font_size_override("font_size", 27)
	portrait_box.add_child(name_label)

	var alias := str(person.get("apodo", ""))
	if not alias.is_empty() and alias != str(person.get("nombre", "")):
		var alias_label := Label.new()
		alias_label.text = "“%s”" % alias
		alias_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		alias_label.add_theme_color_override("font_color", GOLD)
		alias_label.add_theme_font_size_override("font_size", 17)
		portrait_box.add_child(alias_label)

	var role_label := Label.new()
	role_label.text = str(person.get("rol", "Personaje")).capitalize()
	role_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	role_label.add_theme_color_override("font_color", TEXT_DIM)
	role_label.add_theme_font_size_override("font_size", 13)
	portrait_box.add_child(role_label)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 8)
	row.add_child(right)

	var scroll := ScrollContainer.new()
	scroll.name = "CharacterDetailsScroll050"
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(scroll)

	var details := VBoxContainer.new()
	details.name = "CharacterDetails050"
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 11)
	scroll.add_child(details)

	for key in person.keys():
		var key_string := str(key)
		if key_string in ["id", "nombre", "apodo", "rol", "jugable", "imagen_por_defecto"]:
			continue
		var value: Variant = person[key]
		if _is_empty_value(value):
			continue
		_add_data_section(details, key_string, value)

	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	nav.add_theme_constant_override("separation", 10)
	right.add_child(nav)
	var previous := main.call("_make_small_button", "← Anterior") as Button
	previous.custom_minimum_size = Vector2(118, 40)
	previous.pressed.connect(_cycle_character.bind(-1))
	nav.add_child(previous)
	var next := main.call("_make_small_button", "Siguiente →") as Button
	next.custom_minimum_size = Vector2(118, 40)
	next.pressed.connect(_cycle_character.bind(1))
	nav.add_child(next)


func _cycle_character(direction: int) -> void:
	if characters.is_empty() or current_character_id.is_empty():
		return
	var index := 0
	for i in range(characters.size()):
		var item: Variant = characters[i]
		if typeof(item) == TYPE_DICTIONARY and str((item as Dictionary).get("id", "")) == current_character_id:
			index = i
			break
	index = posmod(index + direction, characters.size())
	var next_item: Variant = characters[index]
	if typeof(next_item) == TYPE_DICTIONARY:
		_show_character(str((next_item as Dictionary).get("id", "")))


func _show_game_info() -> void:
	current_page = "game_info"
	current_character_id = ""
	_set_header("Información del juego", "Datos generales, narrativa y jugabilidad")
	_clear_page()
	var details := _make_scroll_details()
	for key in ["juego", "historia", "jugabilidad", "tono", "ideas"]:
		if data.has(key) and not _is_empty_value(data[key]):
			_add_data_section(details, key, data[key])


func _show_places() -> void:
	current_page = "places"
	current_character_id = ""
	_set_header("Lugares", "Escenarios registrados en detalles-juego.json")
	_clear_page()
	var details := _make_scroll_details()
	var places: Variant = data.get("lugares", [])
	if typeof(places) != TYPE_ARRAY:
		return
	for item in places:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var place: Dictionary = item
		var title := str(place.get("nombre", place.get("id", "Lugar")))
		_add_section_title(details, title)
		for key in place.keys():
			var key_string := str(key)
			if key_string in ["id", "nombre"] or _is_empty_value(place[key]):
				continue
			_add_nested_value(details, key_string, place[key], 1)


func _show_credits() -> void:
	current_page = "credits"
	current_character_id = ""
	_set_header("Créditos", "Quién está detrás de La Octava Silla")
	_clear_page()
	var details := _make_scroll_details()
	var credits: Dictionary = data.get("creditos", {})
	if credits.is_empty():
		credits = {
			"creador": "Javi Díaz",
			"diseño_y_programación": "Javi Díaz",
			"motor": "Godot 4"
		}
	_add_data_section(details, "creditos", credits)
	if data.has("juego"):
		_add_data_section(details, "juego", data["juego"])


func _make_scroll_details() -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	page_host.add_child(scroll)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 12)
	scroll.add_child(details)
	return details


func _add_data_section(parent: VBoxContainer, key: String, value: Variant) -> void:
	if _is_empty_value(value):
		return
	_add_section_title(parent, _humanize(key))
	if typeof(value) == TYPE_DICTIONARY:
		var dictionary: Dictionary = value
		for child_key in dictionary.keys():
			if _is_empty_value(dictionary[child_key]):
				continue
			_add_nested_value(parent, str(child_key), dictionary[child_key], 1)
	elif typeof(value) == TYPE_ARRAY:
		_add_array_value(parent, key, value as Array, 0)
	else:
		_add_body_label(parent, _format_scalar(value))


func _add_nested_value(parent: VBoxContainer, key: String, value: Variant, depth: int) -> void:
	if _is_empty_value(value):
		return
	if typeof(value) == TYPE_DICTIONARY:
		_add_subtitle(parent, _humanize(key), depth)
		var dictionary: Dictionary = value
		for child_key in dictionary.keys():
			if not _is_empty_value(dictionary[child_key]):
				_add_nested_value(parent, str(child_key), dictionary[child_key], depth + 1)
	elif typeof(value) == TYPE_ARRAY:
		_add_subtitle(parent, _humanize(key), depth)
		_add_array_value(parent, key, value as Array, depth)
	else:
		var line := "%s: %s" % [_humanize(key), _format_scalar(value)]
		_add_body_label(parent, line, depth)


func _add_array_value(parent: VBoxContainer, key: String, values: Array, depth: int) -> void:
	if values.is_empty():
		return
	if key == "relaciones":
		var relation_lines := PackedStringArray()
		for item in values:
			if typeof(item) != TYPE_DICTIONARY:
				continue
			var relation: Dictionary = item
			var target := str(relation.get("personaje", ""))
			var relation_type := str(relation.get("tipo", ""))
			relation_lines.append("• %s — %s" % [_character_display_from_id(target), relation_type])
		if not relation_lines.is_empty():
			_add_body_label(parent, "\n".join(relation_lines), depth)
		return

	var scalar_lines := PackedStringArray()
	for item in values:
		if typeof(item) == TYPE_DICTIONARY:
			var dictionary: Dictionary = item
			var parts := PackedStringArray()
			for child_key in dictionary.keys():
				if not _is_empty_value(dictionary[child_key]):
					parts.append("%s: %s" % [_humanize(str(child_key)), _format_scalar(dictionary[child_key])])
			if not parts.is_empty():
				scalar_lines.append("• " + " · ".join(parts))
		elif not _is_empty_value(item):
			scalar_lines.append("• " + _format_scalar(item))
	if not scalar_lines.is_empty():
		_add_body_label(parent, "\n".join(scalar_lines), depth)


func _add_section_title(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text.to_upper()
	label.add_theme_color_override("font_color", GOLD)
	label.add_theme_font_size_override("font_size", 19)
	label.add_theme_color_override("font_outline_color", Color(0.05, 0.025, 0.015, 0.9))
	label.add_theme_constant_override("outline_size", 3)
	parent.add_child(label)
	var line := ColorRect.new()
	line.color = Color(0.64, 0.43, 0.22, 0.42)
	line.custom_minimum_size = Vector2(0, 1)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(line)


func _add_subtitle(parent: VBoxContainer, text: String, depth: int) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color("e7c183"))
	label.add_theme_font_size_override("font_size", 15 if depth <= 1 else 13)
	parent.add_child(label)


func _add_body_label(parent: VBoxContainer, text: String, depth: int = 0) -> void:
	if text.strip_edges().is_empty():
		return
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", TEXT if depth == 0 else TEXT_DIM)
	label.add_theme_font_size_override("font_size", 15 if depth <= 1 else 14)
	parent.add_child(label)


func _is_empty_value(value: Variant) -> bool:
	match typeof(value):
		TYPE_NIL:
			return true
		TYPE_STRING, TYPE_STRING_NAME:
			return str(value).strip_edges().is_empty()
		TYPE_ARRAY:
			return (value as Array).is_empty()
		TYPE_DICTIONARY:
			var dictionary: Dictionary = value
			if dictionary.is_empty():
				return true
			for key in dictionary.keys():
				if not _is_empty_value(dictionary[key]):
					return false
			return true
	return false


func _format_scalar(value: Variant) -> String:
	match typeof(value):
		TYPE_BOOL:
			return "Sí" if bool(value) else "No"
		TYPE_FLOAT:
			var number := float(value)
			return "%.2f" % number
		TYPE_DICTIONARY:
			var dictionary: Dictionary = value
			var parts := PackedStringArray()
			for key in dictionary.keys():
				if not _is_empty_value(dictionary[key]):
					parts.append("%s: %s" % [_humanize(str(key)), _format_scalar(dictionary[key])])
			return " · ".join(parts)
		TYPE_ARRAY:
			var parts := PackedStringArray()
			for item in value as Array:
				if not _is_empty_value(item):
					parts.append(_format_scalar(item))
			return ", ".join(parts)
		_:
			return str(value)


func _humanize(key: String) -> String:
	var text := key.replace("_", " ").strip_edges()
	if text.is_empty():
		return key
	return text.capitalize()


func _person_display_name(person: Dictionary) -> String:
	var alias := str(person.get("apodo", ""))
	if not alias.is_empty():
		return alias
	return str(person.get("nombre", person.get("id", "Personaje")))


func _character_display_from_id(character_id: String) -> String:
	if character_index.has(character_id):
		return _person_display_name(character_index[character_id] as Dictionary)
	return character_id.capitalize()


func _character_texture(character_id: String) -> Texture2D:
	if asset_manager == null:
		return null
	return asset_manager.get_character(character_id, "neutral")


func _set_header(title: String, subtitle: String) -> void:
	if header_title != null:
		header_title.text = title
	if header_subtitle != null:
		header_subtitle.text = subtitle


func _queue_layout() -> void:
	call_deferred("_apply_layout")


func _apply_layout() -> void:
	if codex_panel == null:
		return
	var size := get_viewport().get_visible_rect().size
	var portrait := size.y > size.x
	if portrait:
		codex_panel.anchor_left = 0.025
		codex_panel.anchor_top = 0.025
		codex_panel.anchor_right = 0.975
		codex_panel.anchor_bottom = 0.975
	else:
		codex_panel.anchor_left = 0.035
		codex_panel.anchor_top = 0.045
		codex_panel.anchor_right = 0.965
		codex_panel.anchor_bottom = 0.955
	codex_panel.offset_left = 0.0
	codex_panel.offset_top = 0.0
	codex_panel.offset_right = 0.0
	codex_panel.offset_bottom = 0.0

	if current_page == "characters":
		var grid := page_host.find_child("CharacterCodexGrid050", true, false) as GridContainer
		if grid != null:
			grid.columns = 2 if portrait or size.x < 1050.0 else 4
