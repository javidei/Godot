extends Node

const RELEASE_VERSION := "0.4.3"
const DESKTOP_CARDS_PER_ROW := 4
const COMPACT_CARDS_PER_ROW := 2
const DESKTOP_CARD_SIZE := Vector2(240, 150)
const COMPACT_CARD_SIZE := Vector2(220, 145)
const CARD_SEPARATION := 10

var main: Control
var manager: Node
var visit_grid: GridContainer
var visit_rows: VBoxContainer
var visit_menu_button: Button
var last_compact := false


func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	main = get_parent() as Control
	if main == null:
		return
	manager = main.get_node_or_null("Version040Manager")
	_setup_visit_rows()
	_apply_carmen_height()
	_upgrade_save_version()
	get_viewport().size_changed.connect(_on_viewport_size_changed)


func _process(_delta: float) -> void:
	if main == null:
		return
	if manager == null:
		manager = main.get_node_or_null("Version040Manager")
		_setup_visit_rows()
	if visit_grid != null and visit_grid.get_child_count() > 0:
		_rebuild_rows_from_grid()
	_apply_carmen_height()
	_upgrade_save_version()


func _setup_visit_rows() -> void:
	if manager == null or visit_rows != null:
		return
	visit_grid = manager.get("visit_grid") as GridContainer
	visit_menu_button = manager.get("visit_menu_button") as Button
	if visit_grid == null:
		return
	var parent := visit_grid.get_parent() as VBoxContainer
	if parent == null:
		return

	visit_rows = VBoxContainer.new()
	visit_rows.name = "VisitCardsRows042"
	visit_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visit_rows.add_theme_constant_override("separation", CARD_SEPARATION)
	parent.add_child(visit_rows)
	parent.move_child(visit_rows, visit_grid.get_index() + 1)

	visit_grid.visible = false
	visit_grid.custom_minimum_size = Vector2.ZERO
	last_compact = _is_compact()


func _rebuild_rows_from_grid() -> void:
	if visit_grid == null or visit_rows == null:
		return

	_clear_existing_rows(false)
	var cards: Array[Node] = visit_grid.get_children()
	if cards.is_empty():
		return

	var compact := _is_compact()
	last_compact = compact
	var per_row := COMPACT_CARDS_PER_ROW if compact else DESKTOP_CARDS_PER_ROW
	var card_size := COMPACT_CARD_SIZE if compact else DESKTOP_CARD_SIZE
	var row: HBoxContainer

	for index in range(cards.size()):
		if index % per_row == 0:
			row = HBoxContainer.new()
			row.name = "VisitRow_%d" % int(index / per_row)
			row.alignment = BoxContainer.ALIGNMENT_CENTER
			row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_theme_constant_override("separation", CARD_SEPARATION)
			visit_rows.add_child(row)

		var card := cards[index] as Button
		if card == null:
			continue
		card.reparent(row)
		card.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card.custom_minimum_size = card_size
		card.set_meta("visit_row", int(index / per_row))
		card.set_meta("visit_row_index", index % per_row)

	visit_grid.custom_minimum_size = Vector2.ZERO


func _clear_existing_rows(move_cards_to_grid: bool) -> void:
	if visit_rows == null:
		return
	for child in visit_rows.get_children():
		var row := child as HBoxContainer
		if row != null and move_cards_to_grid and visit_grid != null:
			for card in row.get_children():
				card.reparent(visit_grid)
		visit_rows.remove_child(child)
		child.queue_free()


func _on_viewport_size_changed() -> void:
	call_deferred("_reflow_after_resize")


func _reflow_after_resize() -> void:
	if visit_rows == null or visit_grid == null:
		return
	var compact := _is_compact()
	if compact == last_compact and visit_grid.get_child_count() == 0:
		return
	_clear_existing_rows(true)
	call_deferred("_rebuild_rows_from_grid")


func _is_compact() -> bool:
	var viewport_size := get_viewport().get_visible_rect().size
	return viewport_size.y > viewport_size.x or viewport_size.x < 980.0


func _apply_carmen_height() -> void:
	var views_value: Variant = main.get("character_views")
	if typeof(views_value) != TYPE_DICTIONARY:
		return
	var views: Dictionary = views_value
	var carmen_view := views.get("carmen") as TextureRect
	if carmen_view == null:
		return

	var viewport_size := get_viewport().get_visible_rect().size
	var portrait := viewport_size.y > viewport_size.x
	var shift := clampf(viewport_size.y * (0.075 if portrait else 0.10), 52.0, 78.0)
	carmen_view.offset_top = shift
	carmen_view.offset_bottom = shift
	carmen_view.set_meta("height_shift", shift)


func _upgrade_save_version() -> void:
	var state_value: Variant = main.get("state")
	if typeof(state_value) != TYPE_DICTIONARY:
		return
	var state: Dictionary = state_value
	if state.is_empty() or not bool(state.get("visit_mode", false)):
		return
	var target_version := str(ProjectSettings.get_setting("application/config/version", RELEASE_VERSION))
	if str(state.get("save_version", "")) == target_version:
		return
	state["save_version"] = target_version
	main.set("state", state)
