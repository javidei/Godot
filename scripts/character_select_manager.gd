extends Node

const GameData = preload("res://scripts/game_data.gd")
const Story = preload("res://scripts/story.gd")

const SAVE_PATH := "user://godot_otome_save.json"

var main: Control
var flow_screen: Control
var selection_view: Control
var creation_view: Control
var map_view: Control
var character_grid: GridContainer
var selection_title: Label
var map_title: Label
var name_input: LineEdit
var gender_input: OptionButton
var appearance_input: LineEdit
var creation_error: Label
var pending_profile: Dictionary = {}
var character_cards: Array[Button] = []


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	main = get_parent() as Control
	if main == null:
		return
	_build_flow_screen()
	_rewire_game_flow()
	get_viewport().size_changed.connect(_queue_layout)
	call_deferred("_apply_layout")


func open_selection() -> void:
	if flow_screen == null:
		return
	pending_profile = {}
	_set_main_screens(false, false, false)
	flow_screen.visible = true
	selection_view.visible = true
	creation_view.visible = false
	map_view.visible = false
	selection_title.text = "Elige quién protagoniza esta partida"


func _rewire_game_flow() -> void:
	var menu_content: VBoxContainer = main.get("menu_content") as VBoxContainer
	var ending_screen: Control = main.get("ending_screen") as Control
	var new_button := _find_button(menu_content, "Nueva partida")
	var continue_button := _find_button(menu_content, "Continuar")
	var again_button := _find_button(ending_screen, "Jugar de nuevo")
	var old_new := Callable(main, "_start_new_game")
	var old_continue := Callable(main, "_continue_game")

	if new_button != null:
		if new_button.pressed.is_connected(old_new):
			new_button.pressed.disconnect(old_new)
		new_button.pressed.connect(open_selection)
	if again_button != null:
		if again_button.pressed.is_connected(old_new):
			again_button.pressed.disconnect(old_new)
		again_button.pressed.connect(open_selection)
	if continue_button != null:
		if continue_button.pressed.is_connected(old_continue):
			continue_button.pressed.disconnect(old_continue)
		continue_button.pressed.connect(_continue_with_migration)


func _build_flow_screen() -> void:
	flow_screen = Control.new()
	flow_screen.name = "NewGameFlow"
	flow_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flow_screen.z_index = 180
	flow_screen.visible = false
	main.add_child(flow_screen)

	var background := TextureRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var menu_background: TextureRect = main.get("menu_background") as TextureRect
	if menu_background != null:
		background.texture = menu_background.texture
	flow_screen.add_child(background)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.025, 0.016, 0.014, 0.84)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flow_screen.add_child(shade)

	selection_view = _build_selection_view()
	creation_view = _build_creation_view()
	map_view = _build_map_view()
	flow_screen.add_child(selection_view)
	flow_screen.add_child(creation_view)
	flow_screen.add_child(map_view)
	creation_view.visible = false
	map_view.visible = false


func _build_selection_view() -> Control:
	var view := Control.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.name = "SelectionPanel"
	panel.anchor_left = 0.055
	panel.anchor_top = 0.055
	panel.anchor_right = 0.945
	panel.anchor_bottom = 0.945
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.03, 0.025, 0.96), Color("d6a85f"), 2, 18))
	view.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_bottom", 22)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	selection_title = Label.new()
	selection_title.text = "Elige quién protagoniza esta partida"
	selection_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selection_title.add_theme_color_override("font_color", Color("f2c97e"))
	selection_title.add_theme_font_size_override("font_size", 28)
	box.add_child(selection_title)

	var subtitle := Label.new()
	subtitle.text = "Puedes elegir a cualquiera del grupo o crear un personaje nuevo. La elección queda guardada en la partida."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", Color("dbcab3"))
	subtitle.add_theme_font_size_override("font_size", 14)
	box.add_child(subtitle)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_child(scroll)

	character_grid = GridContainer.new()
	character_grid.columns = 3
	character_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_grid.add_theme_constant_override("h_separation", 12)
	character_grid.add_theme_constant_override("v_separation", 12)
	scroll.add_child(character_grid)

	for character_id in GameData.CHARACTER_ORDER:
		var card := _make_character_card(character_id)
		character_cards.append(card)
		character_grid.add_child(card)

	var custom_card := _make_custom_card()
	character_cards.append(custom_card)
	character_grid.add_child(custom_card)

	var back_result: Variant = main.call("_make_button", "Volver al menú", false)
	var back_button := back_result as Button
	back_button.custom_minimum_size = Vector2(0, 42)
	back_button.pressed.connect(_back_to_menu)
	box.add_child(back_button)
	return view


func _build_creation_view() -> Control:
	var view := Control.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.22
	panel.anchor_top = 0.12
	panel.anchor_right = 0.78
	panel.anchor_bottom = 0.88
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.03, 0.025, 0.97), Color("d6a85f"), 2, 18))
	view.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	margin.add_child(box)

	var title := Label.new()
	title.text = "Crear protagonista"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("f2c97e"))
	title.add_theme_font_size_override("font_size", 30)
	box.add_child(title)

	var info := Label.new()
	info.text = "Por ahora el personaje creado no tendrá imagen propia, pero su ficha se guardará para poder ampliarla después."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_color_override("font_color", Color("dbcab3"))
	info.add_theme_font_size_override("font_size", 14)
	box.add_child(info)

	box.add_child(_field_label("Nombre"))
	name_input = LineEdit.new()
	name_input.placeholder_text = "Nombre del personaje"
	name_input.custom_minimum_size = Vector2(0, 44)
	name_input.max_length = 30
	box.add_child(name_input)

	box.add_child(_field_label("Género"))
	gender_input = OptionButton.new()
	gender_input.custom_minimum_size = Vector2(0, 44)
	for option in ["No especificar", "Hombre", "Mujer", "No binario / Otro"]:
		gender_input.add_item(option)
	box.add_child(gender_input)

	box.add_child(_field_label("Apariencia"))
	appearance_input = LineEdit.new()
	appearance_input.placeholder_text = "Descripción breve (opcional)"
	appearance_input.custom_minimum_size = Vector2(0, 44)
	appearance_input.max_length = 120
	box.add_child(appearance_input)

	creation_error = Label.new()
	creation_error.text = ""
	creation_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	creation_error.add_theme_color_override("font_color", Color("ffb49e"))
	creation_error.add_theme_font_size_override("font_size", 13)
	box.add_child(creation_error)

	var confirm_result: Variant = main.call("_make_button", "Continuar", true)
	var confirm_button := confirm_result as Button
	confirm_button.pressed.connect(_confirm_custom_character)
	box.add_child(confirm_button)

	var back_result: Variant = main.call("_make_button", "Volver a personajes", false)
	var back_button := back_result as Button
	back_button.pressed.connect(_show_character_selection)
	box.add_child(back_button)
	return view


func _build_map_view() -> Control:
	var view := Control.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	var panel := PanelContainer.new()
	panel.name = "MapPanel"
	panel.anchor_left = 0.10
	panel.anchor_top = 0.13
	panel.anchor_right = 0.90
	panel.anchor_bottom = 0.87
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.03, 0.025, 0.97), Color("d6a85f"), 2, 18))
	view.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_top", 25)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_bottom", 25)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	map_title = Label.new()
	map_title.text = "¿Dónde empieza la partida?"
	map_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	map_title.add_theme_color_override("font_color", Color("f2c97e"))
	map_title.add_theme_font_size_override("font_size", 29)
	box.add_child(map_title)

	var subtitle := Label.new()
	subtitle.text = "Elige un lugar del mapa. Esta base podrá ampliarse con nuevos escenarios y eventos."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", Color("dbcab3"))
	subtitle.add_theme_font_size_override("font_size", 14)
	box.add_child(subtitle)

	var location_grid := GridContainer.new()
	location_grid.columns = 3
	location_grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	location_grid.add_theme_constant_override("h_separation", 14)
	box.add_child(location_grid)

	for location_id in GameData.LOCATION_ORDER:
		location_grid.add_child(_make_location_card(location_id))

	var back_result: Variant = main.call("_make_button", "Volver a personajes", false)
	var back_button := back_result as Button
	back_button.custom_minimum_size = Vector2(0, 42)
	back_button.pressed.connect(_show_character_selection)
	box.add_child(back_button)
	return view


func _make_character_card(character_id: String) -> Button:
	var data: Dictionary = GameData.CHARACTERS.get(character_id, {})
	var button := Button.new()
	button.name = "Character_" + character_id
	button.text = ""
	button.custom_minimum_size = Vector2(210, 210)
	button.clip_contents = true
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.065, 0.043, 0.033, 0.95), Color(0.72, 0.51, 0.28, 0.55), 1, 14))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.12, 0.073, 0.048, 0.98), Color("efc371"), 2, 14))
	button.add_theme_stylebox_override("focus", _panel_style(Color(0.12, 0.073, 0.048, 0.98), Color("ffe0a0"), 2, 14))
	button.pressed.connect(func(): main.call("_play_ui_sound"))
	button.pressed.connect(_select_existing_character.bind(character_id))

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	button.add_child(margin)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)

	var portrait := TextureRect.new()
	portrait.custom_minimum_size = Vector2(0, 125)
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait.texture = _character_portrait(character_id)
	box.add_child(portrait)

	var name_label := Label.new()
	name_label.text = str(data.get("alias", data.get("name", character_id.capitalize())))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Color("fff1dc"))
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)

	var summary := Label.new()
	summary.text = str(data.get("summary", ""))
	summary.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary.add_theme_color_override("font_color", Color(0.79, 0.73, 0.66, 0.92))
	summary.add_theme_font_size_override("font_size", 11)
	summary.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(summary)
	return button


func _make_custom_card() -> Button:
	var button := Button.new()
	button.name = "Character_Custom"
	button.text = ""
	button.custom_minimum_size = Vector2(210, 210)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_stylebox_override("normal", _panel_style(Color(0.055, 0.038, 0.033, 0.95), Color(0.55, 0.48, 0.40, 0.55), 1, 14))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.11, 0.07, 0.05, 0.98), Color("efc371"), 2, 14))
	button.add_theme_stylebox_override("focus", _panel_style(Color(0.11, 0.07, 0.05, 0.98), Color("ffe0a0"), 2, 14))
	button.pressed.connect(func(): main.call("_play_ui_sound"))
	button.pressed.connect(_show_creation)

	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(box)

	var plus := Label.new()
	plus.text = "+"
	plus.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	plus.add_theme_color_override("font_color", Color("f2c97e"))
	plus.add_theme_font_size_override("font_size", 58)
	plus.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(plus)

	var title := Label.new()
	title.text = "Crear personaje"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("fff1dc"))
	title.add_theme_font_size_override("font_size", 20)
	title.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(title)

	var info := Label.new()
	info.text = "Nombre · género · apariencia"
	info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info.add_theme_color_override("font_color", Color(0.79, 0.73, 0.66, 0.92))
	info.add_theme_font_size_override("font_size", 11)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(info)
	return button


func _make_location_card(location_id: String) -> Button:
	var data: Dictionary = GameData.LOCATIONS.get(location_id, {})
	var result: Variant = main.call("_make_button", str(data.get("name", location_id.capitalize())), false)
	var button := result as Button
	button.custom_minimum_size = Vector2(0, 170)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.tooltip_text = str(data.get("description", ""))
	button.add_theme_font_size_override("font_size", 23)
	button.pressed.connect(_start_location.bind(location_id))
	return button


func _character_portrait(character_id: String) -> Texture2D:
	var assets: Variant = main.get("asset_manager")
	if assets == null:
		return null
	var texture: Texture2D = assets.call("get_character", character_id, "neutral") as Texture2D
	if texture == null:
		return null
	var size: Vector2 = texture.get_size()
	if size.x <= 0.0 or size.y <= 0.0:
		return texture
	var cropped := AtlasTexture.new()
	cropped.atlas = texture
	cropped.region = Rect2(0.0, 0.0, size.x, size.y * 0.50)
	return cropped


func _select_existing_character(character_id: String) -> void:
	pending_profile = GameData.character_profile(character_id)
	_show_map()


func _show_creation() -> void:
	selection_view.visible = false
	map_view.visible = false
	creation_view.visible = true
	creation_error.text = ""
	name_input.grab_focus()


func _show_character_selection() -> void:
	selection_view.visible = true
	creation_view.visible = false
	map_view.visible = false


func _confirm_custom_character() -> void:
	var custom_name := name_input.text.strip_edges()
	if custom_name.is_empty():
		creation_error.text = "Escribe un nombre para continuar."
		return
	var appearance := appearance_input.text.strip_edges()
	pending_profile = {
		"id": "custom",
		"name": custom_name,
		"display_name": custom_name,
		"gender": gender_input.get_item_text(gender_input.selected),
		"appearance": appearance,
		"role": "personalizado",
		"custom": true
	}
	creation_error.text = ""
	_show_map()


func _show_map() -> void:
	selection_view.visible = false
	creation_view.visible = false
	map_view.visible = true
	map_title.text = "%s · ¿Dónde empieza la partida?" % str(pending_profile.get("display_name", "Protagonista"))


func _start_location(location_id: String) -> void:
	if pending_profile.is_empty():
		_show_character_selection()
		return
	var start_node: String = str(Story.START_BY_LOCATION.get(location_id, Story.START))
	var new_state := {
		"node_id": start_node,
		"affinity": {},
		"expressions": {},
		"history": [
			{"system": "protagonist", "id": str(pending_profile.get("id", "custom"))},
			{"system": "location", "id": location_id}
		],
		"player": pending_profile.duplicate(true),
		"location_id": location_id
	}
	for character_id in GameData.CHARACTER_ORDER:
		new_state["affinity"][character_id] = 0
		new_state["expressions"][character_id] = "neutral"
	main.set("state", new_state)
	flow_screen.visible = false
	_set_main_screens(false, true, false)
	var chapter_label: Label = main.get("chapter_label") as Label
	if chapter_label != null:
		chapter_label.text = GameData.location_chapter(location_id)
	main.call("_go_to", start_node, false)
	main.call("_show_toast", "Protagonista: " + str(pending_profile.get("display_name", "")))


func _continue_with_migration() -> void:
	var loaded: Variant = main.call("_read_save")
	if typeof(loaded) != TYPE_BOOL or not bool(loaded):
		open_selection()
		return
	var loaded_state: Dictionary = main.get("state")
	if not loaded_state.has("player") or typeof(loaded_state["player"]) != TYPE_DICTIONARY:
		loaded_state["player"] = GameData.character_profile("javi")
	if not loaded_state.has("location_id"):
		loaded_state["location_id"] = "bar"
	if not loaded_state.has("affinity") or typeof(loaded_state["affinity"]) != TYPE_DICTIONARY:
		loaded_state["affinity"] = {}
	if not loaded_state.has("expressions") or typeof(loaded_state["expressions"]) != TYPE_DICTIONARY:
		loaded_state["expressions"] = {}
	for character_id in GameData.CHARACTER_ORDER:
		if not loaded_state["affinity"].has(character_id):
			loaded_state["affinity"][character_id] = 0
		if not loaded_state["expressions"].has(character_id):
			loaded_state["expressions"][character_id] = "neutral"
	var location_id := str(loaded_state.get("location_id", "bar"))
	if location_id == "calle":
		location_id = "bosque"
		loaded_state["location_id"] = location_id
	var node_id := str(loaded_state.get("node_id", ""))
	if node_id.begins_with("calle_"):
		node_id = "bosque_" + node_id.trim_prefix("calle_")
	if node_id.is_empty() or not Story.NODES.has(node_id):
		node_id = str(Story.START_BY_LOCATION.get(location_id, Story.START))
		loaded_state["node_id"] = node_id
	main.set("state", loaded_state)
	flow_screen.visible = false
	_set_main_screens(false, true, false)
	var chapter_label: Label = main.get("chapter_label") as Label
	if chapter_label != null:
		chapter_label.text = GameData.location_chapter(location_id)
	main.call("_go_to", node_id, false)
	main.call("_show_toast", "Partida cargada")


func _back_to_menu() -> void:
	flow_screen.visible = false
	main.call("_show_menu")


func _set_main_screens(menu_visible: bool, game_visible: bool, ending_visible: bool) -> void:
	var menu_screen: Control = main.get("menu_screen") as Control
	var game_screen: Control = main.get("game_screen") as Control
	var ending_screen: Control = main.get("ending_screen") as Control
	if menu_screen != null:
		menu_screen.visible = menu_visible
	if game_screen != null:
		game_screen.visible = game_visible
	if ending_screen != null:
		ending_screen.visible = ending_visible


func _find_button(root: Node, text: String) -> Button:
	if root == null:
		return null
	if root is Button and (root as Button).text == text:
		return root as Button
	for child in root.get_children():
		var result := _find_button(child, text)
		if result != null:
			return result
	return null


func _field_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", Color("f4b853"))
	label.add_theme_font_size_override("font_size", 14)
	return label


func _panel_style(background: Color, border: Color, width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_left = width
	style.border_width_top = width
	style.border_width_right = width
	style.border_width_bottom = width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.content_margin_left = 12
	style.content_margin_top = 8
	style.content_margin_right = 12
	style.content_margin_bottom = 8
	return style


func _queue_layout() -> void:
	call_deferred("_apply_layout")


func _apply_layout() -> void:
	if character_grid == null:
		return
	var size: Vector2 = get_viewport().get_visible_rect().size
	character_grid.columns = 3 if size.x >= 900.0 else 2
	var card_height: float = 210.0
	if size.y < 560.0:
		card_height = 155.0
	elif size.y < 700.0:
		card_height = 180.0
	for card in character_cards:
		card.custom_minimum_size = Vector2(190.0, card_height)
