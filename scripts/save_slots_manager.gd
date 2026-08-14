extends Node

const MAX_VISIBLE_SLOTS := 10
const AUTOSAVE_SECONDS := 30.0

var main: Control
var data_manager: Node
var character_select_manager: Node
var menu_screen: Control
var menu_content: VBoxContainer
var new_button: Button
var continue_button: Button
var manage_button: Button

var slots_screen: Control
var slots_panel: PanelContainer
var slots_title: Label
var slots_subtitle: Label
var slots_scroll: ScrollContainer
var slots_grid: GridContainer
var slots_back_button: Button
var slot_cards: Dictionary = {}

var confirm_overlay: Control
var confirm_text: Label
var confirm_delete_button: Button
var pending_delete_slot := 0

var current_mode := "manage"
var _flush_accumulator := 0.0
var _has_focus := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# CharacterSelect, menú compacto y Extras reordenan botones durante sus
	# primeros frames. Esperar aquí evita competir con esas capas de compatibilidad.
	for _i in range(32):
		await get_tree().process_frame
	main = get_parent() as Control
	if main == null:
		return
	data_manager = get_node_or_null("/root/DataManager")
	character_select_manager = main.get_node_or_null("CharacterSelectManager")
	menu_screen = main.get("menu_screen") as Control
	menu_content = main.get("menu_content") as VBoxContainer
	if data_manager == null or menu_content == null:
		return
	data_manager.call("ensure_loaded")
	_build_slots_screen()
	_patch_main_menu()
	get_viewport().size_changed.connect(_queue_layout)
	_apply_layout()
	_refresh_continue_state()


func _process(delta: float) -> void:
	if main == null or data_manager == null:
		return
	if not _has_focus or get_tree().paused:
		return
	var slot_id := int(data_manager.call("get_active_save_slot")) if data_manager.has_method("get_active_save_slot") else 0
	if slot_id <= 0:
		return
	var state_value: Variant = main.get("state")
	if typeof(state_value) != TYPE_DICTIONARY:
		return
	var state := state_value as Dictionary
	if state.is_empty() or typeof(state.get("player", null)) != TYPE_DICTIONARY:
		return
	var game_screen: Control = main.get("game_screen") as Control
	var ending_screen: Control = main.get("ending_screen") as Control
	var in_active_run := (game_screen != null and game_screen.visible) or (ending_screen != null and ending_screen.visible)
	if not in_active_run:
		return
	var safe_delta := clampf(delta, 0.0, 1.0)
	state["slot_play_seconds"] = maxf(0.0, float(state.get("slot_play_seconds", 0.0))) + safe_delta
	main.set("state", state)
	_flush_accumulator += safe_delta
	if _flush_accumulator >= AUTOSAVE_SECONDS:
		_flush_accumulator = 0.0
		main.call("_save_game", false)


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_PAUSED:
			_has_focus = false
			_flush_active_slot()
		NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_APPLICATION_RESUMED:
			_has_focus = true


func _exit_tree() -> void:
	_flush_active_slot()


func open_new_game_slots() -> void:
	_open_slots("new")


func open_manage_slots() -> void:
	_open_slots("manage")


func continue_last_slot() -> void:
	if data_manager == null:
		return
	var slot_id := int(data_manager.call("get_last_used_save_slot")) if data_manager.has_method("get_last_used_save_slot") else 0
	if slot_id <= 0:
		_open_slots("new")
		return
	_continue_slot(slot_id)


func _patch_main_menu() -> void:
	new_button = _find_button_with_text(menu_content, "Nueva partida")
	continue_button = _find_button_with_text(menu_content, "Continuar")
	if new_button != null:
		_disconnect_pressed_methods(new_button, ["_start_new_game", "open_selection", "_begin_new_game", "open_new_game_slots"])
		new_button.pressed.connect(open_new_game_slots)
	if continue_button != null:
		_disconnect_pressed_methods(continue_button, ["_continue_game", "_continue_with_migration", "continue_last_slot"])
		continue_button.pressed.connect(continue_last_slot)

	var primary_row := menu_content.find_child("MenuPrimaryActions045", true, false) as HBoxContainer
	manage_button = main.call("_make_button", "Partidas", false) as Button
	manage_button.name = "ManageSaveSlotsButton070"
	manage_button.tooltip_text = "Ver, cargar o borrar partidas guardadas"
	manage_button.custom_minimum_size = Vector2(0, 60)
	manage_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	manage_button.add_theme_font_size_override("font_size", 16)
	manage_button.pressed.connect(open_manage_slots)
	if primary_row != null:
		primary_row.add_child(manage_button)
	else:
		menu_content.add_child(manage_button)
	_bind_click(manage_button)


func _build_slots_screen() -> void:
	slots_screen = Control.new()
	slots_screen.name = "SaveSlotsScreen070"
	slots_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	slots_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	slots_screen.z_index = 720
	slots_screen.visible = false
	main.add_child(slots_screen)

	var shade := ColorRect.new()
	shade.name = "SaveSlotsShade070"
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.012, 0.009, 0.007, 0.94)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	slots_screen.add_child(shade)

	slots_panel = PanelContainer.new()
	slots_panel.name = "SaveSlotsPanel070"
	slots_panel.anchor_left = 0.045
	slots_panel.anchor_top = 0.045
	slots_panel.anchor_right = 0.955
	slots_panel.anchor_bottom = 0.955
	slots_panel.add_theme_stylebox_override(
		"panel",
		main.call("_panel_style", Color(0.028, 0.020, 0.016, 0.985), Color("d6a85f"), 2, 18)
	)
	slots_screen.add_child(slots_panel)

	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 24)
	outer.add_theme_constant_override("margin_top", 20)
	outer.add_theme_constant_override("margin_right", 24)
	outer.add_theme_constant_override("margin_bottom", 20)
	slots_panel.add_child(outer)

	var root_box := VBoxContainer.new()
	root_box.add_theme_constant_override("separation", 10)
	outer.add_child(root_box)

	slots_title = Label.new()
	slots_title.name = "SaveSlotsTitle070"
	slots_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slots_title.add_theme_color_override("font_color", Color("f2c97e"))
	slots_title.add_theme_font_size_override("font_size", 29)
	root_box.add_child(slots_title)

	slots_subtitle = Label.new()
	slots_subtitle.name = "SaveSlotsSubtitle070"
	slots_subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	slots_subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	slots_subtitle.add_theme_color_override("font_color", Color("d3c2aa"))
	slots_subtitle.add_theme_font_size_override("font_size", 14)
	root_box.add_child(slots_subtitle)

	slots_scroll = ScrollContainer.new()
	slots_scroll.name = "SaveSlotsScroll070"
	slots_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	slots_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	slots_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	slots_scroll.scroll_deadzone = 0
	slots_scroll.mouse_force_pass_scroll_events = true
	root_box.add_child(slots_scroll)

	slots_grid = GridContainer.new()
	slots_grid.name = "SaveSlotsGrid070"
	slots_grid.columns = 2
	slots_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots_grid.add_theme_constant_override("h_separation", 12)
	slots_grid.add_theme_constant_override("v_separation", 12)
	slots_scroll.add_child(slots_grid)

	slots_back_button = main.call("_make_button", "Volver", false) as Button
	slots_back_button.name = "SaveSlotsBackButton070"
	slots_back_button.custom_minimum_size = Vector2(0, 48)
	slots_back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slots_back_button.pressed.connect(_close_slots)
	root_box.add_child(slots_back_button)
	_bind_click(slots_back_button)

	_build_delete_confirmation()


func _build_delete_confirmation() -> void:
	confirm_overlay = Control.new()
	confirm_overlay.name = "SaveSlotDeleteConfirmation070"
	confirm_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirm_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_overlay.z_index = 30
	confirm_overlay.visible = false
	slots_screen.add_child(confirm_overlay)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	confirm_overlay.add_child(shade)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	confirm_overlay.add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(500, 0)
	panel.add_theme_stylebox_override(
		"panel",
		main.call("_panel_style", Color(0.045, 0.028, 0.022, 0.995), Color("d6a85f"), 2, 16)
	)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 26)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_right", 26)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	margin.add_child(box)

	var title := Label.new()
	title.text = "ELIMINAR PARTIDA"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color("f2c97e"))
	title.add_theme_font_size_override("font_size", 24)
	box.add_child(title)

	confirm_text = Label.new()
	confirm_text.name = "SaveSlotDeleteText070"
	confirm_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	confirm_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	confirm_text.add_theme_color_override("font_color", Color("f3e5d2"))
	confirm_text.add_theme_font_size_override("font_size", 16)
	box.add_child(confirm_text)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)
	box.add_child(actions)

	var cancel := main.call("_make_button", "Cancelar", false) as Button
	cancel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel.pressed.connect(_cancel_delete)
	actions.add_child(cancel)
	_bind_click(cancel)

	confirm_delete_button = main.call("_make_button", "ELIMINAR", true) as Button
	confirm_delete_button.name = "ConfirmDeleteSaveSlot070"
	confirm_delete_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	confirm_delete_button.pressed.connect(_confirm_delete)
	actions.add_child(confirm_delete_button)
	_bind_click(confirm_delete_button)


func _open_slots(mode: String) -> void:
	if slots_screen == null or data_manager == null:
		return
	current_mode = "new" if mode == "new" else "manage"
	pending_delete_slot = 0
	confirm_overlay.visible = false
	slots_title.text = "ELIGE DÓNDE GUARDAR" if current_mode == "new" else "PARTIDAS GUARDADAS"
	slots_subtitle.text = (
		"Selecciona un espacio vacío. Las partidas ocupadas no se sobrescriben por accidente: bórralas primero si quieres reutilizar ese slot."
		if current_mode == "new"
		else
		"Carga cualquier partida o elimina un slot que ya no quieras conservar. Continuar usa automáticamente la partida más reciente."
	)
	slots_screen.visible = true
	_refresh_slots()
	_apply_layout()


func _close_slots() -> void:
	if confirm_overlay != null and confirm_overlay.visible:
		_cancel_delete()
		return
	if slots_screen != null:
		slots_screen.visible = false
	pending_delete_slot = 0
	_refresh_continue_state()


func _refresh_slots() -> void:
	if slots_grid == null or data_manager == null:
		return
	for child in slots_grid.get_children():
		slots_grid.remove_child(child)
		child.queue_free()
	slot_cards.clear()
	var summaries: Array = data_manager.call("list_save_slots") if data_manager.has_method("list_save_slots") else []
	for slot_id in range(1, MAX_VISIBLE_SLOTS + 1):
		var summary: Dictionary = {}
		if slot_id - 1 < summaries.size() and typeof(summaries[slot_id - 1]) == TYPE_DICTIONARY:
			summary = summaries[slot_id - 1] as Dictionary
		if summary.is_empty():
			summary = {"slot_id": slot_id, "occupied": false}
		var card := _make_slot_card(summary)
		slot_cards[slot_id] = card
		slots_grid.add_child(card)
	call_deferred("_relax_slot_scroll_controls")


func _make_slot_card(summary: Dictionary) -> PanelContainer:
	var slot_id := int(summary.get("slot_id", 0))
	var occupied := bool(summary.get("occupied", false))
	var card := PanelContainer.new()
	card.name = "SaveSlotCard_%02d" % slot_id
	card.custom_minimum_size = Vector2(360, 184 if occupied else 142)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var border := Color("d6a85f") if occupied else Color(0.42, 0.34, 0.25, 0.72)
	card.add_theme_stylebox_override(
		"panel",
		main.call("_panel_style", Color(0.047, 0.033, 0.026, 0.97), border, 1, 12)
	)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_bottom", 12)
	card.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	margin.add_child(box)

	var heading := Label.new()
	heading.text = "SLOT %02d%s" % [slot_id, (" · " + str(summary.get("protagonist_name", "Partida"))) if occupied else ""]
	heading.add_theme_color_override("font_color", Color("f5d28d") if occupied else Color("b8a58f"))
	heading.add_theme_font_size_override("font_size", 18)
	box.add_child(heading)

	if not occupied:
		var empty := Label.new()
		empty.text = "ESPACIO VACÍO"
		empty.add_theme_color_override("font_color", Color("aa9b89"))
		empty.add_theme_font_size_override("font_size", 14)
		box.add_child(empty)
		var empty_action := main.call("_make_button", "NUEVA PARTIDA" if current_mode == "new" else "VACÍO", current_mode == "new") as Button
		empty_action.name = "SaveSlotAction_%02d" % slot_id
		empty_action.custom_minimum_size = Vector2(0, 48)
		empty_action.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		empty_action.disabled = current_mode != "new"
		if current_mode == "new":
			empty_action.pressed.connect(_start_new_game_in_slot.bind(slot_id))
		box.add_child(empty_action)
		_bind_click(empty_action)
		return card

	var zone := Label.new()
	zone.text = str(summary.get("current_zone_name", "Naranjal del Río"))
	zone.add_theme_color_override("font_color", Color("d3c2aa"))
	zone.add_theme_font_size_override("font_size", 13)
	box.add_child(zone)

	var progress_row := HBoxContainer.new()
	progress_row.add_theme_constant_override("separation", 10)
	box.add_child(progress_row)
	var progress_label := Label.new()
	progress_label.text = "Progreso %d %%" % int(summary.get("progress_percent", 0))
	progress_label.custom_minimum_size = Vector2(112, 24)
	progress_label.add_theme_color_override("font_color", Color("f2c97e"))
	progress_label.add_theme_font_size_override("font_size", 13)
	progress_row.add_child(progress_label)
	var progress_bar := ProgressBar.new()
	progress_bar.name = "SaveSlotProgress_%02d" % slot_id
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.value = float(summary.get("progress_percent", 0))
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(0, 12)
	progress_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	progress_row.add_child(progress_bar)

	var details := Label.new()
	details.text = "%d/%d personajes · %s · %d MONEDAS" % [
		int(summary.get("visits_completed", 0)),
		int(summary.get("visits_total", 0)),
		_format_duration(float(summary.get("play_seconds", 0.0))),
		int(summary.get("coins", 0))
	]
	details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	details.add_theme_color_override("font_color", Color("d7c7b1"))
	details.add_theme_font_size_override("font_size", 13)
	box.add_child(details)

	var saved := Label.new()
	saved.text = "Guardado: %s%s" % [
		_format_saved_date(int(summary.get("updated_at_unix", 0))),
		(" · v" + str(summary.get("save_version", ""))) if not str(summary.get("save_version", "")).is_empty() else ""
	]
	saved.add_theme_color_override("font_color", Color("a99a88"))
	saved.add_theme_font_size_override("font_size", 11)
	box.add_child(saved)

	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 8)
	box.add_child(actions)
	var primary := main.call("_make_button", "OCUPADO" if current_mode == "new" else "CONTINUAR", false) as Button
	primary.name = "SaveSlotAction_%02d" % slot_id
	primary.custom_minimum_size = Vector2(0, 44)
	primary.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	primary.disabled = current_mode == "new"
	if current_mode != "new":
		primary.pressed.connect(_continue_slot.bind(slot_id))
	actions.add_child(primary)
	_bind_click(primary)
	var delete_button := main.call("_make_button", "Borrar", false) as Button
	delete_button.name = "DeleteSaveSlot_%02d" % slot_id
	delete_button.custom_minimum_size = Vector2(108, 44)
	delete_button.pressed.connect(_ask_delete_slot.bind(slot_id))
	actions.add_child(delete_button)
	_bind_click(delete_button)
	return card


func _start_new_game_in_slot(slot_id: int) -> void:
	if data_manager == null or character_select_manager == null:
		return
	if bool(data_manager.call("save_slot_exists", slot_id)):
		_refresh_slots()
		return
	if not bool(data_manager.call("set_active_save_slot", slot_id)):
		return
	# Es fundamental descartar el estado anterior antes de seleccionar el nuevo
	# protagonista: así ningún autosave puede copiar por error la partida previa
	# al slot vacío recién elegido.
	main.set("state", {})
	_flush_accumulator = 0.0
	slots_screen.visible = false
	if character_select_manager.has_method("_begin_new_game"):
		character_select_manager.call("_begin_new_game")
	elif character_select_manager.has_method("open_selection"):
		character_select_manager.call("open_selection")


func _continue_slot(slot_id: int) -> void:
	if data_manager == null or character_select_manager == null:
		return
	if not bool(data_manager.call("save_slot_exists", slot_id)):
		_refresh_slots()
		return
	if not bool(data_manager.call("set_active_save_slot", slot_id)):
		return
	_flush_accumulator = 0.0
	if slots_screen != null:
		slots_screen.visible = false
	if character_select_manager.has_method("_continue_with_migration"):
		character_select_manager.call("_continue_with_migration")
	else:
		main.call("_continue_game")


func _ask_delete_slot(slot_id: int) -> void:
	if data_manager == null or confirm_overlay == null:
		return
	var summary: Dictionary = data_manager.call("get_save_slot_summary", slot_id)
	if not bool(summary.get("occupied", false)):
		_refresh_slots()
		return
	pending_delete_slot = slot_id
	confirm_text.text = "¿Eliminar la partida del Slot %02d?\n%s · %d %% · %s\n\nEsta acción no se puede deshacer." % [
		slot_id,
		str(summary.get("protagonist_name", "Partida")),
		int(summary.get("progress_percent", 0)),
		_format_duration(float(summary.get("play_seconds", 0.0)))
	]
	confirm_overlay.visible = true


func _cancel_delete() -> void:
	pending_delete_slot = 0
	if confirm_overlay != null:
		confirm_overlay.visible = false


func _confirm_delete() -> void:
	if data_manager == null or pending_delete_slot <= 0:
		_cancel_delete()
		return
	var slot_id := pending_delete_slot
	if bool(data_manager.call("delete_save_slot", slot_id)):
		main.call("_show_toast", "Partida del Slot %02d eliminada" % slot_id)
	else:
		main.call("_show_toast", "No se ha podido borrar la partida")
	_cancel_delete()
	_refresh_slots()
	_refresh_continue_state()


func _refresh_continue_state() -> void:
	if continue_button != null and data_manager != null:
		continue_button.disabled = not bool(data_manager.call("has_save"))


func _flush_active_slot() -> void:
	if main == null or data_manager == null:
		return
	var state_value: Variant = main.get("state")
	if typeof(state_value) != TYPE_DICTIONARY or (state_value as Dictionary).is_empty():
		return
	if int(data_manager.call("get_active_save_slot")) <= 0:
		return
	if typeof((state_value as Dictionary).get("player", null)) != TYPE_DICTIONARY:
		return
	_flush_accumulator = 0.0
	main.call("_save_game", false)


func _relax_slot_scroll_controls() -> void:
	if slots_scroll == null:
		return
	for node in slots_scroll.find_children("*", "Control", true, false):
		if node is BaseButton:
			(node as BaseButton).mouse_filter = Control.MOUSE_FILTER_PASS
			(node as BaseButton).mouse_force_pass_scroll_events = true
		elif node is Control and node != slots_scroll:
			(node as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE


func _queue_layout() -> void:
	call_deferred("_apply_layout")


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
	var confirm_panel := confirm_overlay.find_child("", true, false) if confirm_overlay != null else null
	# El CenterContainer ya mantiene el diálogo centrado; las tarjetas son las que
	# necesitan adaptarse de forma explícita en Android/vertical.
	for raw_card in slot_cards.values():
		var card := raw_card as PanelContainer
		if card != null:
			card.custom_minimum_size.x = 270.0 if portrait or narrow else 360.0


func _disconnect_pressed_methods(button: Button, method_names: Array) -> void:
	if button == null:
		return
	for connection in button.pressed.get_connections():
		var callable: Callable = connection.get("callable", Callable())
		if callable.is_valid() and method_names.has(str(callable.get_method())) and button.pressed.is_connected(callable):
			button.pressed.disconnect(callable)


func _find_button_with_text(root: Node, expected: String) -> Button:
	if root == null:
		return null
	if root is Button and (root as Button).text == expected:
		return root as Button
	for child in root.get_children():
		var found := _find_button_with_text(child, expected)
		if found != null:
			return found
	return null


func _bind_click(button: Button) -> void:
	if button == null or main == null:
		return
	var extras := main.get_node_or_null("Version050ExtrasCodex")
	if extras != null and extras.has_method("_bind_button_click"):
		extras.call("_bind_button_click", button)


func _format_duration(seconds: float) -> String:
	var total_minutes := maxi(0, int(seconds / 60.0))
	var hours := int(total_minutes / 60)
	var minutes := total_minutes % 60
	if hours > 0:
		return "%d h %02d min" % [hours, minutes]
	return "%d min" % minutes


func _format_saved_date(unix_time: int) -> String:
	if unix_time <= 0:
		return "sin fecha"
	var date := Time.get_datetime_dict_from_unix_time(unix_time)
	return "%02d/%02d/%04d %02d:%02d" % [
		int(date.get("day", 1)),
		int(date.get("month", 1)),
		int(date.get("year", 1970)),
		int(date.get("hour", 0)),
		int(date.get("minute", 0))
	]
