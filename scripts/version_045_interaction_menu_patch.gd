extends Node

const LANDSCAPE_LEFT := 0.05
const LANDSCAPE_RIGHT := 0.43

var main: Control
var menu_content: VBoxContainer
var game_screen: Control
var transition_manager: Node
var primary_row: HBoxContainer
var secondary_row: HBoxContainer
var audio_row: HBoxContainer
var audio_title: Label
var new_button: Button
var continue_button: Button
var fullscreen_button: Button
var exit_button: Button


func _ready() -> void:
	for _i in range(12):
		await get_tree().process_frame
	main = get_parent() as Control
	if main == null:
		return
	menu_content = main.get("menu_content") as VBoxContainer
	game_screen = main.get("game_screen") as Control
	transition_manager = main.get_node_or_null("Version044VisitTransitions")
	_capture_menu_nodes()
	_build_action_rows()
	_compact_audio_row()
	_order_menu()
	_connect_game_screen_input()
	_apply_layout()
	get_viewport().size_changed.connect(_queue_layout)


func _connect_game_screen_input() -> void:
	if game_screen == null:
		return
	var callback := Callable(self, "_on_game_screen_input")
	if not game_screen.gui_input.is_connected(callback):
		game_screen.gui_input.connect(callback)


func _on_game_screen_input(event: InputEvent) -> void:
	_handle_screen_advance(event)


func _unhandled_input(event: InputEvent) -> void:
	_handle_screen_advance(event)


func _handle_screen_advance(event: InputEvent) -> void:
	if main == null or game_screen == null or not game_screen.visible:
		return
	if transition_manager != null and bool(transition_manager.get("transition_active")):
		return

	var advance := false
	if event is InputEventMouseButton:
		advance = event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	elif event is InputEventScreenTouch:
		advance = event.pressed
	elif event is InputEventKey and event.pressed and not event.echo:
		advance = event.keycode == KEY_SPACE or event.keycode == KEY_ENTER
	if not advance:
		return

	main.call("_advance")
	get_viewport().set_input_as_handled()


func _capture_menu_nodes() -> void:
	if menu_content == null:
		return
	audio_row = menu_content.find_child("AudioCombinedControls040", true, false) as HBoxContainer
	audio_title = menu_content.find_child("AudioSettingsTitle", true, false) as Label
	fullscreen_button = menu_content.find_child("MenuFullscreenButton", true, false) as Button
	exit_button = menu_content.find_child("ExitGameButton", true, false) as Button
	for child in menu_content.get_children():
		var button := child as Button
		if button == null:
			continue
		match button.text:
			"Nueva partida":
				new_button = button
			"Continuar":
				continue_button = button


func _build_action_rows() -> void:
	if menu_content == null:
		return
	primary_row = HBoxContainer.new()
	primary_row.name = "MenuPrimaryActions045"
	primary_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary_row.add_theme_constant_override("separation", 12)
	menu_content.add_child(primary_row)

	secondary_row = HBoxContainer.new()
	secondary_row.name = "MenuSecondaryActions045"
	secondary_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	secondary_row.add_theme_constant_override("separation", 12)
	menu_content.add_child(secondary_row)

	for button in [new_button, continue_button]:
		if button == null:
			continue
		button.reparent(primary_row)
		_prepare_action_button(button, 60)
	for button in [fullscreen_button, exit_button]:
		if button == null:
			continue
		button.reparent(secondary_row)
		_prepare_action_button(button, 56)


func _prepare_action_button(button: Button, height: float) -> void:
	button.custom_minimum_size = Vector2(0, height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 16)


func _compact_audio_row() -> void:
	if audio_row == null:
		return
	audio_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	audio_row.add_theme_constant_override("separation", 4)
	for child in audio_row.get_children():
		if child is Label:
			var label := child as Label
			if label.text == "|":
				label.custom_minimum_size = Vector2(8, 32)
				label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			elif label.name == "MusicVolumeLabel":
				label.custom_minimum_size = Vector2(76, 32)
				label.add_theme_font_size_override("font_size", 12)
			elif label.name == "EffectsVolumeLabel":
				label.custom_minimum_size = Vector2(62, 32)
				label.add_theme_font_size_override("font_size", 12)
		elif child is Button:
			var button := child as Button
			var width := 40.0 if button.name.contains("Mute") else 32.0
			button.custom_minimum_size = Vector2(width, 32)
			button.add_theme_font_size_override("font_size", 11)
	if audio_title != null:
		audio_title.add_theme_font_size_override("font_size", 12)


func _order_menu() -> void:
	if menu_content == null:
		return
	var subtitle: Label
	var spacer: Control
	var version_label: Label
	for child in menu_content.get_children():
		if child is Label:
			var label := child as Label
			if label.name == "VersionLabel":
				version_label = label
			elif label.name != "EngineTag" and label.name != "GameTitle" and label != audio_title and label.text.begins_with("Elige quién eres"):
				subtitle = label
		elif child is Control and not (child is Container) and child.custom_minimum_size.y <= 20.0:
			spacer = child

	if spacer != null:
		spacer.custom_minimum_size = Vector2(0, 2)

	var insert_after := 0
	if subtitle != null:
		insert_after = subtitle.get_index() + 1
	if spacer != null:
		menu_content.move_child(spacer, insert_after)
		insert_after += 1
	if audio_title != null:
		menu_content.move_child(audio_title, insert_after)
		insert_after += 1
	if audio_row != null:
		menu_content.move_child(audio_row, insert_after)
		insert_after += 1
	if primary_row != null:
		menu_content.move_child(primary_row, insert_after)
		insert_after += 1
	if secondary_row != null:
		menu_content.move_child(secondary_row, insert_after)
	if version_label != null:
		menu_content.move_child(version_label, menu_content.get_child_count() - 1)


func _queue_layout() -> void:
	call_deferred("_apply_layout")


func _apply_layout() -> void:
	if menu_content == null:
		return
	var viewport_size := get_viewport().get_visible_rect().size
	var portrait := viewport_size.y > viewport_size.x
	menu_content.add_theme_constant_override("separation", 8)
	if portrait:
		menu_content.anchor_left = 0.08
		menu_content.anchor_right = 0.92
		menu_content.anchor_top = 0.06
		menu_content.anchor_bottom = 0.96
	else:
		menu_content.anchor_left = LANDSCAPE_LEFT
		menu_content.anchor_right = LANDSCAPE_RIGHT
		menu_content.anchor_top = 0.045
		menu_content.anchor_bottom = 0.96
	menu_content.offset_left = 0.0
	menu_content.offset_top = 0.0
	menu_content.offset_right = 0.0
	menu_content.offset_bottom = 0.0

	var title := menu_content.find_child("GameTitle", true, false) as Label
	if title != null:
		title.custom_minimum_size = Vector2(0, 100 if not portrait else 116)
		title.add_theme_font_size_override("font_size", 43 if not portrait else 42)

	_compact_audio_row()


func _process(_delta: float) -> void:
	if main == null:
		return
	var value: Variant = main.get("state")
	if typeof(value) != TYPE_DICTIONARY:
		return
	var state: Dictionary = value
	if state.is_empty() or not bool(state.get("visit_mode", false)):
		return
	var project_version := str(ProjectSettings.get_setting("application/config/version", "0.4.9"))
	if str(state.get("save_version", "")) == project_version:
		return
	state["save_version"] = project_version
	main.set("state", state)
