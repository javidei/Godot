extends Control

const Story = preload("res://scripts/story.gd")
const SAVE_PATH := "user://godot_otome_save.json"
const ASSET_BASE := "https://raw.githubusercontent.com/javidei/juego-otome/main/assets/"
const ASSET_URLS := {
	"menu": ASSET_BASE + "key-art.webp",
	"background": ASSET_BASE + "bg-cafe.webp",
	"javi": ASSET_BASE + "javi-sheet.webp",
	"sue": ASSET_BASE + "sue-sheet.webp",
	"smokey": ASSET_BASE + "smokey-sheet.webp"
}
const CHARACTER_NAMES := {"javi": "Javi", "sue": "Sue", "smokey": "Smokey"}
const EXPRESSION_FRAME := {
	"neutral": 0,
	"happy": 1,
	"embarrassed": 1,
	"laugh": 1,
	"annoyed": 2,
	"thoughtful": 2,
	"teasing": 2
}

var state: Dictionary = {}
var current_node: Dictionary = {}
var source_textures: Dictionary = {}
var character_slots: Dictionary = {}
var character_views: Dictionary = {}
var placeholder_labels: Dictionary = {}

var menu_screen: Control
var game_screen: Control
var ending_screen: Control
var menu_background: TextureRect
var ending_background: TextureRect
var game_background: TextureRect
var continue_button: Button
var stage: Control
var speaker_label: Label
var dialogue_text: Label
var choices_box: VBoxContainer
var sfx_label: Label
var toast_label: Label
var ending_affinity: Label

var typing_full_text := ""
var typing_index := 0
var typing_accumulator := 0.0
var typing_interval := 0.018
var is_typing := false


func _ready() -> void:
	_build_interface()
	_load_remote_assets()
	_show_menu()
	print("Demo narrativa Godot cargada.")


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


func _build_menu() -> void:
	menu_screen = Control.new()
	menu_screen.name = "MenuScreen"
	menu_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(menu_screen)

	menu_background = TextureRect.new()
	menu_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	menu_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	menu_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_screen.add_child(menu_background)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.035, 0.023, 0.02, 0.72)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu_screen.add_child(shade)

	var content := VBoxContainer.new()
	content.anchor_left = 0.06
	content.anchor_top = 0.2
	content.anchor_right = 0.49
	content.anchor_bottom = 0.82
	content.add_theme_constant_override("separation", 13)
	menu_screen.add_child(content)

	var tag := Label.new()
	tag.text = "DEMO GODOT 4 · NOVELA VISUAL"
	tag.add_theme_color_override("font_color", Color("f2c97e"))
	tag.add_theme_font_size_override("font_size", 14)
	content.add_child(tag)

	var title := Label.new()
	title.text = "Entre líneas"
	title.add_theme_color_override("font_color", Color("fff1dc"))
	title.add_theme_font_size_override("font_size", 64)
	content.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "La misma idea de juego-otome, ahora construida sobre Godot."
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.add_theme_color_override("font_color", Color("dbcab3"))
	subtitle.add_theme_font_size_override("font_size", 18)
	content.add_child(subtitle)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	content.add_child(spacer)

	var new_button := _make_button("Nueva partida", true)
	new_button.pressed.connect(_start_new_game)
	content.add_child(new_button)

	continue_button = _make_button("Continuar", false)
	continue_button.pressed.connect(_continue_game)
	content.add_child(continue_button)

	var info := Label.new()
	info.text = "Base inicial: diálogos, decisiones, afinidad, guardado y efectos."
	info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info.add_theme_color_override("font_color", Color(0.75, 0.7, 0.64, 0.8))
	info.add_theme_font_size_override("font_size", 12)
	content.add_child(info)


func _build_game() -> void:
	game_screen = Control.new()
	game_screen.name = "GameScreen"
	game_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(game_screen)

	game_background = TextureRect.new()
	game_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game_background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	game_background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	game_background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_screen.add_child(game_background)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.035, 0.02, 0.012, 0.24)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_screen.add_child(shade)

	stage = Control.new()
	stage.anchor_left = 0.0
	stage.anchor_top = 0.07
	stage.anchor_right = 1.0
	stage.anchor_bottom = 0.77
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_screen.add_child(stage)

	_create_character("javi", 0.01, 0.36, Color(0.22, 0.38, 0.58, 0.35))
	_create_character("sue", 0.32, 0.68, Color(0.62, 0.47, 0.18, 0.35))
	_create_character("smokey", 0.64, 0.99, Color(0.38, 0.31, 0.26, 0.35))

	var topbar := HBoxContainer.new()
	topbar.anchor_left = 0.025
	topbar.anchor_top = 0.02
	topbar.anchor_right = 0.975
	topbar.anchor_bottom = 0.09
	topbar.add_theme_constant_override("separation", 8)
	game_screen.add_child(topbar)

	var chapter := Label.new()
	chapter.text = "✦ Una noche cualquiera"
	chapter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	chapter.add_theme_color_override("font_color", Color("f1c875"))
	chapter.add_theme_font_size_override("font_size", 17)
	topbar.add_child(chapter)

	var save_button := _make_small_button("Guardar")
	save_button.pressed.connect(func(): _save_game(true))
	topbar.add_child(save_button)

	var load_button := _make_small_button("Cargar")
	load_button.pressed.connect(_load_game_from_button)
	topbar.add_child(load_button)

	var menu_button := _make_small_button("Menú")
	menu_button.pressed.connect(_show_menu)
	topbar.add_child(menu_button)

	choices_box = VBoxContainer.new()
	choices_box.anchor_left = 0.16
	choices_box.anchor_top = 0.48
	choices_box.anchor_right = 0.84
	choices_box.anchor_bottom = 0.72
	choices_box.add_theme_constant_override("separation", 7)
	game_screen.add_child(choices_box)

	var dialogue_panel := PanelContainer.new()
	dialogue_panel.anchor_left = 0.07
	dialogue_panel.anchor_top = 0.73
	dialogue_panel.anchor_right = 0.93
	dialogue_panel.anchor_bottom = 0.965
	dialogue_panel.mouse_filter = Control.MOUSE_FILTER_STOP
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

	sfx_label = Label.new()
	sfx_label.anchor_left = 0.3
	sfx_label.anchor_top = 0.32
	sfx_label.anchor_right = 0.7
	sfx_label.anchor_bottom = 0.5
	sfx_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sfx_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sfx_label.add_theme_color_override("font_color", Color("fff0c3"))
	sfx_label.add_theme_font_size_override("font_size", 58)
	sfx_label.modulate.a = 0.0
	sfx_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_screen.add_child(sfx_label)

	toast_label = Label.new()
	toast_label.anchor_left = 0.3
	toast_label.anchor_top = 0.12
	toast_label.anchor_right = 0.7
	toast_label.anchor_bottom = 0.18
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.add_theme_color_override("font_color", Color("ffe0a4"))
	toast_label.add_theme_font_size_override("font_size", 14)
	toast_label.modulate.a = 0.0
	toast_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
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
	ending_background.modulate = Color(0.48, 0.48, 0.48, 1)
	ending_screen.add_child(ending_background)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.03, 0.02, 0.018, 0.75)
	ending_screen.add_child(shade)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.22
	panel.anchor_top = 0.2
	panel.anchor_right = 0.78
	panel.anchor_bottom = 0.8
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
	eyebrow.text = "FIN DE LA DEMO"
	eyebrow.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	eyebrow.add_theme_color_override("font_color", Color("e8b86a"))
	eyebrow.add_theme_font_size_override("font_size", 14)
	box.add_child(eyebrow)

	var title := Label.new()
	title.text = "Esto solo es el principio"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("fff1dc"))
	title.add_theme_font_size_override("font_size", 38)
	box.add_child(title)

	var text := Label.new()
	text.text = "La base ya funciona en Godot: ahora podemos ampliar escenas, rutas, animaciones y sistemas sin cambiar de motor."
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_color_override("font_color", Color("d9c7b0"))
	text.add_theme_font_size_override("font_size", 17)
	box.add_child(text)

	ending_affinity = Label.new()
	ending_affinity.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ending_affinity.add_theme_color_override("font_color", Color("f0b95e"))
	ending_affinity.add_theme_font_size_override("font_size", 21)
	box.add_child(ending_affinity)

	var again := _make_button("Jugar de nuevo", true)
	again.pressed.connect(_start_new_game)
	box.add_child(again)

	var menu_button := _make_button("Volver al menú", false)
	menu_button.pressed.connect(_show_menu)
	box.add_child(menu_button)


func _create_character(character: String, left: float, right: float, fallback_color: Color) -> void:
	var slot := Control.new()
	slot.anchor_left = left
	slot.anchor_top = 0.0
	slot.anchor_right = right
	slot.anchor_bottom = 1.0
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(slot)
	character_slots[character] = slot

	var fallback := ColorRect.new()
	fallback.anchor_left = 0.18
	fallback.anchor_top = 0.14
	fallback.anchor_right = 0.82
	fallback.anchor_bottom = 0.95
	fallback.color = fallback_color
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(fallback)

	var view := TextureRect.new()
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	view.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(view)
	character_views[character] = view

	var placeholder := Label.new()
	placeholder.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	placeholder.text = CHARACTER_NAMES[character] + "\n(cargando sprite)"
	placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	placeholder.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	placeholder.add_theme_color_override("font_color", Color(1, 1, 1, 0.72))
	placeholder.add_theme_font_size_override("font_size", 19)
	placeholder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slot.add_child(placeholder)
	placeholder_labels[character] = placeholder


func _make_button(text: String, primary: bool) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 48)
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color("f7ead8"))
	var normal_color := Color(0.25, 0.15, 0.1, 0.94) if primary else Color(0.07, 0.045, 0.035, 0.86)
	button.add_theme_stylebox_override("normal", _panel_style(normal_color, Color(0.82, 0.61, 0.32, 0.62), 1, 11))
	button.add_theme_stylebox_override("hover", _panel_style(Color(0.31, 0.19, 0.12, 0.98), Color("ecc26f"), 2, 11))
	button.add_theme_stylebox_override("pressed", _panel_style(Color(0.18, 0.1, 0.07, 1), Color("ffd17d"), 2, 11))
	return button


func _make_small_button(text: String) -> Button:
	var button := _make_button(text, false)
	button.custom_minimum_size = Vector2(90, 38)
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
		"affinity": {"javi": 0, "sue": 0, "smokey": 0},
		"expressions": {"javi": "neutral", "sue": "neutral", "smokey": "neutral"},
		"history": []
	}


func _show_menu() -> void:
	menu_screen.visible = true
	game_screen.visible = false
	ending_screen.visible = false
	continue_button.disabled = not FileAccess.file_exists(SAVE_PATH)


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
	if node_id == "__END__":
		_finish_demo()
		return

	var node: Dictionary = Story.NODES.get(node_id, {})
	if node.is_empty():
		_show_toast("No se ha encontrado la escena: " + node_id)
		return

	current_node = node
	state["node_id"] = node_id

	var shown: Array = node.get("show", ["javi", "sue", "smokey"])
	for character in character_slots.keys():
		character_slots[character].visible = shown.has(character)

	var expression_changes: Dictionary = node.get("expressions", {})
	for character in expression_changes.keys():
		state["expressions"][character] = expression_changes[character]
		_apply_expression(character, expression_changes[character])

	_set_focus(str(node.get("focus", "all")))
	speaker_label.text = str(node.get("speaker", "Narrador"))
	_start_typing(str(node.get("text", "")))

	if add_to_history:
		state["history"].append({"speaker": speaker_label.text, "text": str(node.get("text", ""))})

	if node.has("effect"):
		_play_effect(node["effect"])

	_save_game(false)


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
		button.custom_minimum_size = Vector2(0, 44)
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
		var active: bool = focus == "all" or focus == str(character)
		character_slots[character].modulate = Color(1, 1, 1, 1) if active else Color(0.58, 0.58, 0.58, 0.82)


func _apply_expression(character: String, expression: String) -> void:
	if not source_textures.has(character) or not character_views.has(character):
		return
	var texture: Texture2D = source_textures[character]
	var frame := int(EXPRESSION_FRAME.get(expression, 0))
	var frame_width := float(texture.get_width()) / 3.0
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = Rect2(frame_width * frame, 0.0, frame_width, float(texture.get_height()))
	character_views[character].texture = atlas


func _play_effect(effect: Dictionary) -> void:
	var kind := str(effect.get("type", ""))
	var text := str(effect.get("text", ""))
	if not text.is_empty():
		_show_sfx(text)

	if kind == "shake":
		_shake_stage()
	elif kind == "zoom":
		_zoom_character(str(effect.get("character", "")))
	elif kind == "emote":
		_zoom_character(str(effect.get("character", "")), 1.04)


func _show_sfx(text: String) -> void:
	sfx_label.text = text
	sfx_label.pivot_offset = sfx_label.size * 0.5
	sfx_label.scale = Vector2(0.5, 0.5)
	sfx_label.modulate.a = 0.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sfx_label, "modulate:a", 1.0, 0.12)
	tween.tween_property(sfx_label, "scale", Vector2(1.2, 1.2), 0.16)
	tween.chain().tween_interval(0.45)
	tween.chain().set_parallel(true)
	tween.tween_property(sfx_label, "modulate:a", 0.0, 0.25)
	tween.tween_property(sfx_label, "scale", Vector2(1.0, 1.0), 0.25)


func _shake_stage() -> void:
	var origin := stage.position
	var tween := create_tween()
	for offset in [Vector2(-8, 3), Vector2(7, -2), Vector2(-5, -3), Vector2(4, 2)]:
		tween.tween_property(stage, "position", origin + offset, 0.055)
	tween.tween_property(stage, "position", origin, 0.06)


func _zoom_character(character: String, amount: float = 1.1) -> void:
	if not character_slots.has(character):
		return
	var slot: Control = character_slots[character]
	slot.pivot_offset = slot.size * 0.5
	var tween := create_tween()
	tween.tween_property(slot, "scale", Vector2(amount, amount), 0.18)
	tween.tween_interval(0.28)
	tween.tween_property(slot, "scale", Vector2.ONE, 0.24)


func _show_toast(text: String) -> void:
	toast_label.text = text
	toast_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(toast_label, "modulate:a", 1.0, 0.12)
	tween.tween_interval(1.25)
	tween.tween_property(toast_label, "modulate:a", 0.0, 0.28)


func _finish_demo() -> void:
	_save_game(false)
	game_screen.visible = false
	menu_screen.visible = false
	ending_screen.visible = true
	var affinity: Dictionary = state.get("affinity", {})
	ending_affinity.text = "Javi  " + _hearts(int(affinity.get("javi", 0))) + "    ·    Sue  " + _hearts(int(affinity.get("sue", 0))) + "    ·    Smokey  " + _hearts(int(affinity.get("smokey", 0)))


func _hearts(value: int) -> String:
	if value <= 0:
		return "♡"
	var result := ""
	for _i in range(value):
		result += "♥"
	return result


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
		state["affinity"] = {"javi": 0, "sue": 0, "smokey": 0}
	if not state.has("expressions"):
		state["expressions"] = {"javi": "neutral", "sue": "neutral", "smokey": "neutral"}
	if not state.has("history"):
		state["history"] = []
	for character in state["expressions"].keys():
		_apply_expression(character, str(state["expressions"][character]))
	return true


func _load_remote_assets() -> void:
	for key in ASSET_URLS.keys():
		var request := HTTPRequest.new()
		request.name = "AssetRequest_" + str(key)
		add_child(request)
		request.request_completed.connect(_on_asset_loaded.bind(str(key), request))
		var error := request.request(str(ASSET_URLS[key]))
		if error != OK:
			request.queue_free()


func _on_asset_loaded(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, key: String, request: HTTPRequest) -> void:
	request.queue_free()
	if response_code < 200 or response_code >= 300 or body.is_empty():
		return

	var image := Image.new()
	var error := image.load_webp_from_buffer(body)
	if error != OK:
		return

	var texture := ImageTexture.create_from_image(image)
	if key == "menu":
		menu_background.texture = texture
		ending_background.texture = texture
	elif key == "background":
		game_background.texture = texture
	elif character_views.has(key):
		source_textures[key] = texture
		placeholder_labels[key].visible = false
		var expression := "neutral"
		if not state.is_empty():
			expression = str(state.get("expressions", {}).get(key, "neutral"))
		_apply_expression(key, expression)
