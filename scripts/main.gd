extends Control

const Story = preload("res://scripts/story.gd")
const AssetManagerScript = preload("res://scripts/asset_manager.gd")
const AudioManagerScript = preload("res://scripts/audio_manager.gd")
const SAVE_PATH := "user://godot_otome_save.json"

const CHARACTER_NAMES := {
	"javi": "Javi",
	"sue": "Sue",
	"smokey": "Smokey",
	"carmen": "Carmen",
	"jony": "Jony",
	"ana": "Ana",
	"argentino": "El Argentino"
}
const CHARACTER_ORDER: Array[String] = ["javi", "sue", "smokey", "carmen", "jony", "ana", "argentino"]
const DEFAULT_POSITIONS := {"javi": "left", "sue": "center", "smokey": "right"}
const LANDSCAPE_CHARACTER_SCALE := 1.06
const PORTRAIT_CHARACTER_SCALE := 1.04
const LANDSCAPE_POSITIONS := {
	"left": Vector2(0.02, 0.43),
	"center": Vector2(0.295, 0.705),
	"right": Vector2(0.57, 0.98)
}
const PORTRAIT_POSITIONS := {
	"left": Vector2(-0.08, 0.58),
	"center": Vector2(0.17, 0.83),
	"right": Vector2(0.42, 1.08)
}

var state: Dictionary = {}
var current_node: Dictionary = {}
var character_slots: Dictionary = {}
var character_views: Dictionary = {}
var character_positions: Dictionary = DEFAULT_POSITIONS.duplicate()
var current_background := ""
var portrait_layout := false

var asset_manager
var audio_manager

var menu_screen: Control
var game_screen: Control
var ending_screen: Control
var menu_background: TextureRect
var menu_characters: TextureRect
var ending_background: TextureRect
var game_background: TextureRect
var menu_content: VBoxContainer
var continue_button: Button
var exit_confirmation: ConfirmationDialog
var stage: Control
var topbar: HBoxContainer
var chapter_label: Label
var fullscreen_button: Button
var speaker_label: Label
var dialogue_text: Label
var dialogue_panel: PanelContainer
var choices_box: GridContainer
var sfx_label: Label
var toast_label: Label
var ending_affinity: Label

var typing_full_text := ""
var typing_index := 0
var typing_accumulator := 0.0
var typing_interval := 0.018
var is_typing := false


func _ready() -> void:
	asset_manager = AssetManagerScript.new()
	audio_manager = AudioManagerScript.new()
	audio_manager.name = "AudioManager"
	add_child(audio_manager)
	_build_interface()
	_set_background("casa_asturias")
	_show_menu()
	get_viewport().size_changed.connect(_apply_responsive_layout)
	call_deferred("_apply_responsive_layout")
	print("Demo narrativa Godot cargada con recursos locales.")


func _process(delta: float) -> void:
	if not is_typing:
		return

	typing_accumulator += delta
	while typing_accumulator >= typing_interval and typing_index < typing_full_text.length():
		typing_accumulator -= typing_interval
		typing_index += 2 if typing_full_text.length() > 135 else 1
		typing_index = min(typing_index, typing_full_text.length())
		dialogue_text.text = typing_full_text.substr(0, typing_index)

	if typing_index >= typing_full_text.length():
		_finish_typing()


func _unhandled_input(event: InputEvent) -> void:
	if not game_screen.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_advance()


func _build_interface() -> void:
	_build_menu()
	_build_game()
	_build_ending()
	_build_exit_confirmation()


func _build_menu() -> void:
	menu_screen = Control.new()
	menu_screen.name = "MenuScreen"
	menu_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_screen)

	menu_background = TextureRect.new()
	menu_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	menu_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	menu_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_screen.add_child(menu_background)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.035, 0.023, 0.02, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_screen.add_child(shade)

	menu_characters = TextureRect.new()
	menu_characters.name = "MenuCharacters"
	menu_characters.anchor_left = 0.4
	menu_characters.anchor_top = 0.18
	menu_characters.anchor_right = 1.02
	menu_characters.anchor_bottom = 1.02
	menu_characters.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_characters.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	menu_characters.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	menu_characters.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_characters.texture = asset_manager.get_menu_characters()
	menu_characters.modulate = Color(1, 1, 1, 0.96)
	menu_characters.z_index = 1
	menu_screen.add_child(menu_characters)

	menu_content = VBoxContainer.new()
	menu_content.anchor_left = 0.06
	menu_content.anchor_top = 0.12
	menu_content.anchor_right = 0.54
	menu_content.anchor_bottom = 0.92
	menu_content.add_theme_constant_override("separation", 10)
	menu_content.z_index = 2
	menu_screen.add_child(menu_content)

	var tag := Label.new()
	tag.name = "EngineTag"
	tag.text = "GODOT 4 · NOVELA VISUAL"
	tag.add_theme_color_override("font_color", Color("f2c97e"))
	tag.add_theme_font_size_override("font_size", 14)
	menu_content.add_child(tag)

	var title := Label.new()
	title.name = "GameTitle"
	title.text = "Entre líneas:\nLa octava silla"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(0, 118)
	title.add_theme_color_override("font_color", Color("fff1dc"))
	title.add_theme_color_override("font_outline_color", Color(0.08, 0.035, 0.02, 0.95))
	title.add_theme_constant_override("outline_size", 7)
	title.add_theme_font_size_override("font_size", 50)
	var title_font := load("res://assets/ui/fonts/DejaVuSerif-Bold.ttf") as Font
	if title_font != null:
		title.add_theme_font_override("font", title_font)
	menu_content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Elige quién eres, conoce al resto del grupo y descubre cuánto sabes de cada persona."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", Color("dbcab3"))
	subtitle.add_theme_font_size_override("font_size", 18)
	menu_content.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	menu_content.add_child(spacer)

	var new_button := _make_button("Nueva partida", true)
	new_button.pressed.connect(_start_new_game)
	menu_content.add_child(new_button)

	continue_button = _make_button("Continuar", false)
	continue_button.pressed.connect(_continue_game)
	menu_content.add_child(continue_button)

	var exit_button := _make_button("Salir", false)
	exit_button.name = "ExitGameButton"
	exit_button.pressed.connect(_show_exit_confirmation)
	menu_content.add_child(exit_button)

	var info := Label.new()
	info.name = "VersionLabel"
	info.text = "EARLY ACCESS · Diálogos, preguntas, amistad, guardado, efectos y audio."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_color_override("font_color", Color(0.78, 0.73, 0.67, 0.86))
	info.add_theme_font_size_override("font_size", 12)
	menu_content.add_child(info)


func _build_game() -> void:
	game_screen = Control.new()
	game_screen.name = "GameScreen"
	game_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(game_screen)

	game_background = TextureRect.new()
	game_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	game_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	game_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	game_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_background.z_index = -20
	game_screen.add_child(game_background)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.035, 0.02, 0.012, 0.18)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.z_index = -10
	game_screen.add_child(shade)

	stage = Control.new()
	stage.anchor_left = 0.0
	stage.anchor_top = 0.07
	stage.anchor_right = 1.0
	stage.anchor_bottom = 1.0
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.z_index = 0
	game_screen.add_child(stage)

	_create_character("javi", "left")
	_create_character("sue", "center")
	_create_character("smokey", "right")
	_create_character("carmen", "left")
	_create_character("jony", "center")
	_create_character("ana", "right")
	_create_character("argentino", "center")

	sfx_label = Label.new()
	sfx_label.anchor_left = 0.27
	sfx_label.anchor_top = 0.25
	sfx_label.anchor_right = 0.73
	sfx_label.anchor_bottom = 0.49
	sfx_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sfx_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sfx_label.add_theme_color_override("font_color", Color("fff3c7"))
	sfx_label.add_theme_color_override("font_outline_color", Color(0.13, 0.07, 0.035, 0.96))
	sfx_label.add_theme_constant_override("outline_size", 10)
	sfx_label.add_theme_font_size_override("font_size", 66)
	sfx_label.modulate.a = 0.0
	sfx_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sfx_label.z_index = 20
	game_screen.add_child(sfx_label)

	topbar = HBoxContainer.new()
	topbar.anchor_left = 0.025
	topbar.anchor_top = 0.02
	topbar.anchor_right = 0.975
	topbar.anchor_bottom = 0.09
	topbar.add_theme_constant_override("separation", 8)
	topbar.z_index = 40
	game_screen.add_child(topbar)

	chapter_label = Label.new()
	chapter_label.text = "UNA NOCHE CUALQUIERA"
	chapter_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chapter_label.add_theme_color_override("font_color", Color("f1c875"))
	chapter_label.add_theme_font_size_override("font_size", 17)
	topbar.add_child(chapter_label)

	var save_button := _make_small_button("Guardar")
	save_button.pressed.connect(func(): _save_game(true))
	topbar.add_child(save_button)

	var load_button := _make_small_button("Cargar")
	load_button.pressed.connect(_load_game_from_button)
	topbar.add_child(load_button)

	var menu_button := _make_small_button("Menú")
	menu_button.pressed.connect(_show_menu)
	topbar.add_child(menu_button)

	fullscreen_button = _make_small_button("Pantalla completa")
	fullscreen_button.custom_minimum_size = Vector2(132, 42)
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	topbar.add_child(fullscreen_button)

	choices_box = GridContainer.new()
	choices_box.name = "ChoicesGrid"
	choices_box.columns = 2
	choices_box.anchor_left = 0.08
	choices_box.anchor_top = 0.47
	choices_box.anchor_right = 0.92
	choices_box.anchor_bottom = 0.75
	choices_box.add_theme_constant_override("h_separation", 14)
	choices_box.add_theme_constant_override("v_separation", 12)
	choices_box.z_index = 35
	game_screen.add_child(choices_box)

	dialogue_panel = PanelContainer.new()
	dialogue_panel.anchor_left = 0.07
	dialogue_panel.anchor_top = 0.79
	dialogue_panel.anchor_right = 0.93
	dialogue_panel.anchor_bottom = 0.965
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	dialogue_panel.z_index = 30
	dialogue_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.045, 0.03, 0.025, 0.94), Color("d6a85f"), 2, 12))
	dialogue_panel.gui_input.connect(_on_dialogue_input)
	game_screen.add_child(dialogue_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 25)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 25)
	margin.add_theme_constant_override("margin_bottom", 18)
	dialogue_panel.add_child(margin)

	var dialogue_box := VBoxContainer.new()
	dialogue_box.add_theme_constant_override("separation", 8)
	margin.add_child(dialogue_box)

	speaker_label = Label.new()
	speaker_label.text = "Narrador"
	speaker_label.add_theme_color_override("font_color", Color("f4b853"))
	speaker_label.add_theme_font_size_override("font_size", 21)
	dialogue_box.add_child(speaker_label)

	dialogue_text = Label.new()
	dialogue_text.text = ""
	dialogue_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dialogue_text.add_theme_color_override("font_color", Color("f7ead4"))
	dialogue_text.add_theme_font_size_override("font_size", 19)
	dialogue_box.add_child(dialogue_text)

	toast_label = Label.new()
	toast_label.anchor_left = 0.3
	toast_label.anchor_top = 0.12
	toast_label.anchor_right = 0.7
	toast_label.anchor_bottom = 0.18
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_color", Color("ffe0a4"))
	toast_label.add_theme_color_override("font_outline_color", Color(0.08, 0.05, 0.03, 0.95))
	toast_label.add_theme_constant_override("outline_size", 5)
	toast_label.add_theme_font_size_override("font_size", 14)
	toast_label.modulate.a = 0.0
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_label.z_index = 45
	game_screen.add_child(toast_label)


func _build_ending() -> void:
	ending_screen = Control.new()
	ending_screen.name = "EndingScreen"
	ending_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(ending_screen)

	ending_background = TextureRect.new()
	ending_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ending_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	ending_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	ending_background.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	ending_background.modulate = Color(0.52, 0.52, 0.52, 1)
	ending_screen.add_child(ending_background)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03, 0.02, 0.018, 0.75)
	ending_screen.add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.16
	panel.anchor_top = 0.08
	panel.anchor_right = 0.84
	panel.anchor_bottom = 0.92
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.055, 0.035, 0.027, 0.94), Color("d6a85f"), 2, 18))
	ending_screen.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 34)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 34)
	margin.add_theme_constant_override("margin_bottom", 30)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 16)
	margin.add_child(box)

	var eyebrow := Label.new()
	eyebrow.text = "RESULTADO DE AMISTAD"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_color_override("font_color", Color("e8b86a"))
	eyebrow.add_theme_font_size_override("font_size", 14)
	box.add_child(eyebrow)

	var title := Label.new()
	title.text = "Así has quedado con el grupo"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("fff1dc"))
	title.add_theme_font_size_override("font_size", 38)
	box.add_child(title)

	var text := Label.new()
	text.text = "Cada respuesta correcta suma un punto de amistad. Estos son tus resultados con los personajes que has conocido."
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_color_override("font_color", Color("d9c7b0"))
	text.add_theme_font_size_override("font_size", 17)
	box.add_child(text)

	ending_affinity = Label.new()
	ending_affinity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_affinity.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	ending_affinity.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ending_affinity.size_flags_vertical = Control.SIZE_EXPAND_FILL
	ending_affinity.add_theme_color_override("font_color", Color("f0b95e"))
	ending_affinity.add_theme_font_size_override("font_size", 17)
	box.add_child(ending_affinity)

	var again := _make_button("Jugar de nuevo", true)
	again.pressed.connect(_start_new_game)
	box.add_child(again)

	var menu_button := _make_button("Volver al menú", false)
	menu_button.pressed.connect(_show_menu)
	box.add_child(menu_button)


func _create_character(character: String, position_id: String) -> void:
	var slot := Control.new()
	slot.name = CHARACTER_NAMES.get(character, character)
	slot.anchor_top = 0.0
	slot.anchor_bottom = 1.0
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(slot)
	character_slots[character] = slot
	character_positions[character] = position_id

	var view := TextureRect.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.texture = asset_manager.get_character(character, "neutral")
	slot.add_child(view)
	character_views[character] = view
	_set_character_position(character, position_id)
	slot.visible = false


func _set_character_position(character: String, position_id: String) -> void:
	if not character_slots.has(character):
		return
	var layouts := PORTRAIT_POSITIONS if portrait_layout else LANDSCAPE_POSITIONS
	var anchors: Vector2 = layouts.get(position_id, layouts["center"])
	var slot: Control = character_slots[character]
	slot.anchor_left = anchors.x
	slot.anchor_right = anchors.y
	slot.offset_left = 0.0
	slot.offset_top = 0.0
	slot.offset_right = 0.0
	slot.offset_bottom = 0.0
	character_positions[character] = position_id


func _make_button(button_text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = button_text
	button.custom_minimum_size = Vector2(0, 48)
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("f7ead8"))
	var normal_color := Color(0.25, 0.15, 0.1, 0.94) if primary else Color(0.07, 0.045, 0.035, 0.9)
	button.add_theme_stylebox_override("normal", _panel_style(normal_color, Color(0.82, 0.61, 0.32, 0.62), 1, 11))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.31, 0.19, 0.12, 0.98), Color("ecc26f"), 2, 11))
	button.add_theme_stylebox_override("focus", _panel_style(Color(0.31, 0.19, 0.12, 0.98), Color("ffe0a0"), 2, 11))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.18, 0.1, 0.07, 1), Color("ffd17d"), 2, 11))
	button.pressed.connect(_play_ui_sound)
	return button


func _make_small_button(button_text: String) -> Button:
	var button := _make_button(button_text, false)
	button.custom_minimum_size = Vector2(90, 42)
	button.add_theme_font_size_override("font_size", 13)
	return button


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


func _fresh_state() -> Dictionary:
	return {
		"node_id": Story.START,
		"affinity": _empty_affinity(),
		"expressions": _neutral_expressions(),
		"history": []
	}


func _empty_affinity() -> Dictionary:
	var affinity := {}
	for character_id in CHARACTER_ORDER:
		affinity[character_id] = 0
	return affinity


func _neutral_expressions() -> Dictionary:
	var expressions := {}
	for character_id in CHARACTER_ORDER:
		expressions[character_id] = "neutral"
	return expressions


func _show_menu() -> void:
	_set_background("casa_asturias")
	menu_screen.visible = true
	game_screen.visible = false
	ending_screen.visible = false
	continue_button.disabled = not FileAccess.file_exists(SAVE_PATH)


func _build_exit_confirmation() -> void:
	exit_confirmation = ConfirmationDialog.new()
	exit_confirmation.name = "ExitGameConfirmation"
	exit_confirmation.title = "Salir del juego"
	exit_confirmation.dialog_text = "Se va a cerrar \"El Mejor juego the best GOTY of the year del año\".\n\n¿Seguro que quieres salir?"
	exit_confirmation.ok_button_text = "Sí, salir"
	exit_confirmation.cancel_button_text = "Cancelar"
	exit_confirmation.exclusive = true
	exit_confirmation.confirmed.connect(_quit_game)
	add_child(exit_confirmation)


func _show_exit_confirmation() -> void:
	exit_confirmation.popup_centered_clamped(Vector2i(620, 240), 0.9)


func _quit_game() -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("(()=>{const closeGame=()=>window.close();if(document.fullscreenElement&&document.exitFullscreen){document.exitFullscreen().catch(()=>{}).finally(closeGame);}else{closeGame();}})();", true)
		return
	get_tree().quit()


func _start_new_game() -> void:
	state = _fresh_state()
	menu_screen.visible = false
	ending_screen.visible = false
	game_screen.visible = true
	_go_to(Story.START, false)


func _continue_game() -> void:
	if not _read_save():
		_start_new_game()
		return
	menu_screen.visible = false
	ending_screen.visible = false
	game_screen.visible = true
	_go_to(str(state.get("node_id", Story.START)), false)
	_show_toast("Partida cargada")


func _load_game_from_button() -> void:
	if not _read_save():
		_show_toast("Todavía no hay una partida guardada")
		return
	_go_to(str(state.get("node_id", Story.START)), false)
	_show_toast("Partida cargada")


func _go_to(node_id: String, add_to_history: bool = true) -> void:
	_clear_choices()
	var resolved_node_id := Story.resolve_for_player(node_id, _player_character_id())
	if resolved_node_id == "__END__":
		_finish_demo()
		return

	var node: Dictionary = Story.NODES.get(resolved_node_id, {})
	if node.is_empty():
		_show_toast("No se ha encontrado la escena: " + resolved_node_id)
		return

	current_node = node
	state["node_id"] = resolved_node_id
	chapter_label.text = _chapter_for_node(resolved_node_id, node)

	if node.has("background"):
		_set_background(str(node["background"]))

	var shown: Array = node.get("show", ["javi", "sue", "smokey"])
	for character in character_slots.keys():
		character_slots[character].visible = shown.has(character)

	var positions: Dictionary = node.get("positions", {})
	for character in positions.keys():
		_set_character_position(str(character), str(positions[character]))

	var expression_changes: Dictionary = node.get("expressions", {})
	for character in expression_changes.keys():
		state["expressions"][character] = expression_changes[character]
		_apply_expression(str(character), str(expression_changes[character]))

	_set_focus(str(node.get("focus", "all")))
	speaker_label.text = str(node.get("speaker", "Narrador"))
	_start_typing(str(node.get("text", "")))

	if add_to_history:
		state["history"].append({"speaker": speaker_label.text, "text": str(node.get("text", ""))})

	if node.has("effect"):
		_play_effect(node["effect"])

	_preload_followups(node)
	_save_game(false)


func _set_background(background_id: String) -> void:
	if background_id == current_background and game_background.texture != null:
		return
	var texture: Texture2D = asset_manager.get_background(background_id)
	if texture == null:
		return
	current_background = background_id
	menu_background.texture = texture
	game_background.texture = texture
	ending_background.texture = texture
	game_background.modulate.a = 0.72
	var tween := create_tween()
	tween.tween_property(game_background, "modulate:a", 1.0, 0.28)


func _preload_followups(node: Dictionary) -> void:
	if node.has("next"):
		var next_id := Story.resolve_for_player(str(node["next"]), _player_character_id())
		var next_node: Dictionary = Story.NODES.get(next_id, {})
		if not next_node.is_empty():
			asset_manager.warm_scene(next_node)
	if node.has("choices"):
		for choice in node["choices"]:
			var next_choice_id := Story.resolve_for_player(str(choice.get("next", "")), _player_character_id())
			var choice_node: Dictionary = Story.NODES.get(next_choice_id, {})
			if not choice_node.is_empty():
				asset_manager.warm_scene(choice_node)


func _player_character_id() -> String:
	var player: Dictionary = state.get("player", {})
	return str(player.get("id", ""))


func _chapter_for_node(node_id: String, node: Dictionary) -> String:
	var character_id: String = Story.character_for_node(node_id)
	var encounter_order: Array[String] = Story.encounter_order_for_player(_player_character_id())
	var encounter_index := encounter_order.find(character_id)
	if encounter_index < 0:
		return str(node.get("chapter", "ENCUENTRO"))
	var chapter := "ENCUENTRO %d/%d · %s" % [
		encounter_index + 1,
		encounter_order.size(),
		str(CHARACTER_NAMES.get(character_id, character_id)).to_upper()
	]
	if node.has("question_number"):
		chapter += " · PREGUNTA %d/3" % int(node["question_number"])
	return chapter


func _start_typing(text: String) -> void:
	typing_full_text = text
	typing_index = 0
	typing_accumulator = 0.0
	dialogue_text.text = ""
	is_typing = true


func _finish_typing() -> void:
	is_typing = false
	typing_index = typing_full_text.length()
	dialogue_text.text = typing_full_text
	if current_node.has("choices"):
		_render_choices(current_node["choices"])


func _complete_typing() -> bool:
	if not is_typing:
		return false
	_finish_typing()
	return true


func _advance() -> void:
	if _complete_typing():
		return
	if current_node.has("choices"):
		return
	if current_node.has("next"):
		_go_to(str(current_node["next"]))


func _on_dialogue_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_advance()
	elif event is InputEventScreenTouch and event.pressed:
		_advance()


func _render_choices(choices: Array) -> void:
	_clear_choices()
	for choice in choices:
		var button := _make_button(str(choice.get("label", "Elegir")), false)
		button.custom_minimum_size = Vector2(0, 64)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.size_flags_vertical = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
		button.pressed.connect(_choose.bind(choice))
		choices_box.add_child(button)
	choices_box.visible = true


func _clear_choices() -> void:
	if choices_box == null:
		return
	for child in choices_box.get_children():
		child.queue_free()
	choices_box.visible = false


func _choose(choice: Dictionary) -> void:
	var affinity: Dictionary = choice.get("affinity", {})
	for character in affinity.keys():
		var amount := int(affinity[character])
		state["affinity"][character] = int(state["affinity"].get(character, 0)) + amount
		_show_toast(CHARACTER_NAMES.get(character, character) + " +" + str(amount) + " afinidad")
	state["history"].append({"choice": str(choice.get("label", ""))})
	_go_to(str(choice.get("next", "__END__")))


func _set_focus(focus: String) -> void:
	for character in character_slots.keys():
		var slot: Control = character_slots[character]
		var active: bool = focus == "all" or focus == str(character)
		# Escalamos desde los pies para que todos conserven la misma linea de suelo.
		slot.pivot_offset = Vector2(slot.size.x * 0.5, slot.size.y)
		slot.z_index = 3 if active and focus != "all" else 1
		var target_color := Color.WHITE if active else Color(0.56, 0.56, 0.56, 0.82)
		var base_scale := PORTRAIT_CHARACTER_SCALE if portrait_layout else LANDSCAPE_CHARACTER_SCALE
		var focus_scale := 1.025 if active and focus != "all" else 1.0
		var target_scale := Vector2.ONE * base_scale * focus_scale
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(slot, "modulate", target_color, 0.18)
		tween.tween_property(slot, "scale", target_scale, 0.18)


func _apply_expression(character: String, expression: String) -> void:
	if not character_views.has(character):
		return
	var texture: Texture2D = asset_manager.get_character(character, expression)
	if texture == null:
		return
	character_views[character].texture = texture


func _play_effect(effect: Dictionary) -> void:
	var kind := str(effect.get("type", ""))
	var text := str(effect.get("text", ""))
	var sound_id := str(effect.get("sfx", ""))
	if not text.is_empty():
		_show_sfx(text)
	if not sound_id.is_empty():
		audio_manager.play_sfx(sound_id)

	if kind == "shake":
		_shake_stage()
	elif kind == "zoom":
		_zoom_character(str(effect.get("character", "")))
	elif kind == "emote":
		_zoom_character(str(effect.get("character", "")), 1.045)


func _show_sfx(text: String) -> void:
	sfx_label.text = text
	sfx_label.pivot_offset = sfx_label.size * 0.5
	sfx_label.scale = Vector2(0.56, 0.56)
	sfx_label.rotation = deg_to_rad(-4.0)
	sfx_label.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sfx_label, "modulate:a", 1.0, 0.09)
	tween.tween_property(sfx_label, "scale", Vector2(1.16, 1.16), 0.14)
	tween.tween_property(sfx_label, "rotation", deg_to_rad(2.0), 0.14)
	tween.set_parallel(false)
	tween.tween_interval(0.42)
	tween.set_parallel(true)
	tween.tween_property(sfx_label, "modulate:a", 0.0, 0.24)
	tween.tween_property(sfx_label, "scale", Vector2(0.96, 0.96), 0.24)
	tween.tween_property(sfx_label, "rotation", 0.0, 0.24)


func _shake_stage() -> void:
	var origin := stage.position
	var tween := create_tween()
	for offset in [Vector2(-7, 3), Vector2(6, -2), Vector2(-4, -2), Vector2(3, 2)]:
		tween.tween_property(stage, "position", origin + offset, 0.05)
	tween.tween_property(stage, "position", origin, 0.06)


func _zoom_character(character: String, amount: float = 1.08) -> void:
	if not character_slots.has(character):
		return
	var slot: Control = character_slots[character]
	slot.pivot_offset = Vector2(slot.size.x * 0.5, slot.size.y)
	var base_scale := slot.scale
	var tween := create_tween()
	tween.tween_property(slot, "scale", base_scale * amount, 0.16)
	tween.tween_interval(0.24)
	tween.tween_property(slot, "scale", base_scale, 0.22)


func _show_toast(text: String) -> void:
	toast_label.text = text
	toast_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(toast_label, "modulate:a", 1.0, 0.12)
	tween.tween_interval(1.25)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.28)


func _play_ui_sound() -> void:
	audio_manager.play_ui("confirm")


func _toggle_fullscreen() -> void:
	var mode := DisplayServer.window_get_mode()
	var is_fullscreen := mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if is_fullscreen else DisplayServer.WINDOW_MODE_FULLSCREEN)


func _finish_demo() -> void:
	_save_game(false)
	game_screen.visible = false
	menu_screen.visible = false
	ending_screen.visible = true
	var affinity: Dictionary = state.get("affinity", {})
	var encounter_order: Array[String] = Story.encounter_order_for_player(_player_character_id())
	var result_lines := PackedStringArray()
	var total := 0
	for character_id in encounter_order:
		var value: int = clampi(int(affinity.get(character_id, 0)), 0, 3)
		total += value
		result_lines.append("%s  %s · %s" % [CHARACTER_NAMES.get(character_id, character_id), _score(value), _friendship_level(value)])
	result_lines.append("")
	result_lines.append("TOTAL  %d/%d" % [total, encounter_order.size() * 3])
	ending_affinity.text = "\n".join(result_lines)


func _score(value: int) -> String:
	return str(clamp(value, 0, 3)) + "/3"


func _friendship_level(value: int) -> String:
	match clamp(value, 0, 3):
		0:
			return "Aún os estáis conociendo"
		1:
			return "Primer punto de conexión"
		2:
			return "Buena amistad"
		_:
			return "Amistad muy fuerte"


func _save_game(show_message: bool) -> void:
	if state.is_empty():
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		if show_message:
			_show_toast("No se ha podido guardar")
		return
	file.store_string(JSON.stringify(state))
	if show_message:
		_show_toast("Partida guardada")


func _read_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	state = parsed
	if not state.has("affinity"):
		state["affinity"] = _empty_affinity()
	if not state.has("expressions"):
		state["expressions"] = _neutral_expressions()
	if not state.has("history"):
		state["history"] = []
	for character_id in CHARACTER_ORDER:
		if not state["affinity"].has(character_id):
			state["affinity"][character_id] = 0
		if not state["expressions"].has(character_id):
			state["expressions"][character_id] = "neutral"
	var saved_node := str(state.get("node_id", Story.START))
	if saved_node != "__END__":
		if Story.LEGACY_START_NODES.has(saved_node) or not Story.NODES.has(saved_node):
			saved_node = Story.start_for_player(_player_character_id())
		else:
			saved_node = Story.resolve_for_player(saved_node, _player_character_id())
		state["node_id"] = saved_node
	for character in state["expressions"].keys():
		_apply_expression(str(character), str(state["expressions"][character]))
	return true


func _apply_responsive_layout() -> void:
	var window_size := get_window().size
	portrait_layout = window_size.y > window_size.x

	if portrait_layout:
		menu_content.anchor_left = 0.08
		menu_content.anchor_top = 0.14
		menu_content.anchor_right = 0.92
		menu_content.anchor_bottom = 0.88
		menu_characters.anchor_left = 0.02
		menu_characters.anchor_top = 0.58
		menu_characters.anchor_right = 0.98
		menu_characters.anchor_bottom = 1.02
		menu_characters.modulate = Color(1, 1, 1, 0.68)
		stage.anchor_top = 0.08
		stage.anchor_bottom = 1.0
		topbar.anchor_left = 0.025
		topbar.anchor_right = 0.975
		topbar.anchor_bottom = 0.085
		chapter_label.add_theme_font_size_override("font_size", 12)
		choices_box.anchor_left = 0.035
		choices_box.anchor_top = 0.44
		choices_box.anchor_right = 0.965
		choices_box.anchor_bottom = 0.68
		dialogue_panel.anchor_left = 0.035
		dialogue_panel.anchor_top = 0.69
		dialogue_panel.anchor_right = 0.965
		dialogue_panel.anchor_bottom = 0.98
		dialogue_text.add_theme_font_size_override("font_size", 18)
		sfx_label.anchor_left = 0.12
		sfx_label.anchor_right = 0.88
		fullscreen_button.text = "Pantalla"
		fullscreen_button.custom_minimum_size = Vector2(86, 42)
	else:
		menu_content.anchor_left = 0.06
		menu_content.anchor_top = 0.12
		menu_content.anchor_right = 0.54
		menu_content.anchor_bottom = 0.92
		menu_characters.anchor_left = 0.4
		menu_characters.anchor_top = 0.18
		menu_characters.anchor_right = 1.02
		menu_characters.anchor_bottom = 1.02
		menu_characters.modulate = Color(1, 1, 1, 0.96)
		stage.anchor_top = 0.07
		stage.anchor_bottom = 1.0
		topbar.anchor_left = 0.025
		topbar.anchor_right = 0.975
		topbar.anchor_bottom = 0.09
		chapter_label.add_theme_font_size_override("font_size", 17)
		choices_box.anchor_left = 0.08
		choices_box.anchor_top = 0.47
		choices_box.anchor_right = 0.92
		choices_box.anchor_bottom = 0.75
		dialogue_panel.anchor_left = 0.07
		dialogue_panel.anchor_top = 0.79
		dialogue_panel.anchor_right = 0.93
		dialogue_panel.anchor_bottom = 0.965
		dialogue_text.add_theme_font_size_override("font_size", 19)
		sfx_label.anchor_left = 0.27
		sfx_label.anchor_right = 0.73
		fullscreen_button.text = "Pantalla completa"
		fullscreen_button.custom_minimum_size = Vector2(132, 42)

	for character in character_positions.keys():
		_set_character_position(str(character), str(character_positions[character]))
