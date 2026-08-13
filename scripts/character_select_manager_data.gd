extends "res://scripts/character_select_manager.gd"

const DataAccess = preload("res://scripts/data_access.gd")
const DataStory = preload("res://scripts/story.gd")
const RuntimeGameData = preload("res://scripts/game_data.gd")


func _rewire_game_flow() -> void:
	super()
	var menu_content: VBoxContainer = main.get("menu_content") as VBoxContainer
	var ending_screen: Control = main.get("ending_screen") as Control
	for button in [
		_find_button(menu_content, "Nueva partida"),
		_find_button(ending_screen, "Jugar de nuevo")
	]:
		if button == null:
			continue
		var direct_selection := Callable(self, "open_selection")
		if button.pressed.is_connected(direct_selection):
			button.pressed.disconnect(direct_selection)
		var intro_callback := Callable(self, "_begin_new_game")
		if not button.pressed.is_connected(intro_callback):
			button.pressed.connect(intro_callback)


func _begin_new_game() -> void:
	var transition := main.get_node_or_null("Version044VisitTransitions") if main != null else null
	if transition != null and transition.has_method("play_new_game_intro"):
		transition.call("play_new_game_intro", Callable(self, "open_selection"))
		return
	open_selection()


func _start_game() -> void:
	if pending_profile.is_empty():
		_show_character_selection()
		return
	var dm: Variant = DataAccess.dm()
	if dm == null:
		return
	var player_id := str(pending_profile.get("id", "custom"))
	var start_node: String = DataStory.start_for_player(player_id)
	var new_state := {
		"node_id": start_node,
		"affinity": {},
		"expressions": {},
		"history": [{"system": "protagonist", "id": player_id}],
		"player": pending_profile.duplicate(true),
		"intro_2026_seen": true
	}
	var ids: Array = dm.call("get_character_ids", false)
	for raw_id in ids:
		var character_id := str(raw_id)
		new_state["affinity"][character_id] = int(dm.call("get_initial_friendship", character_id))
		new_state["expressions"][character_id] = "neutral"
	if dm.has_method("migrate_save_state"):
		var migrated: Variant = dm.call("migrate_save_state", new_state)
		if typeof(migrated) == TYPE_DICTIONARY:
			new_state = migrated as Dictionary
	main.set("state", new_state)
	var progress := main.get_node_or_null("ProgressManager")
	if progress != null and progress.has_method("record_event"):
		progress.call("record_event", "new_game_started", {
			"protagonist_id": player_id
		}, new_state)
	flow_screen.visible = false
	_set_main_screens(false, true, false)
	main.call("_go_to", start_node, false)
	main.call("_show_toast", "Protagonista: " + str(pending_profile.get("display_name", "")))


func _continue_with_migration() -> void:
	var loaded: Variant = main.call("_read_save")
	if typeof(loaded) != TYPE_BOOL or not bool(loaded):
		open_selection()
		return
	var dm: Variant = DataAccess.dm()
	if dm == null:
		return
	var loaded_state: Dictionary = main.get("state")
	if dm.has_method("migrate_save_state"):
		var migrated: Variant = dm.call("migrate_save_state", loaded_state)
		if typeof(migrated) == TYPE_DICTIONARY:
			loaded_state = migrated as Dictionary
	if not loaded_state.has("player") or typeof(loaded_state["player"]) != TYPE_DICTIONARY:
		var fallback_ids: Array = dm.call("get_character_ids", true)
		var fallback_id := "javi" if fallback_ids.has("javi") else (str(fallback_ids[0]) if not fallback_ids.is_empty() else "custom")
		loaded_state["player"] = RuntimeGameData.character_profile(fallback_id) if fallback_id != "custom" else {"id": "custom", "name": "Jugador", "display_name": "Jugador", "custom": true}
	if not loaded_state.has("affinity") or typeof(loaded_state["affinity"]) != TYPE_DICTIONARY:
		loaded_state["affinity"] = {}
	if not loaded_state.has("expressions") or typeof(loaded_state["expressions"]) != TYPE_DICTIONARY:
		loaded_state["expressions"] = {}
	var ids: Array = dm.call("get_character_ids", false)
	for raw_id in ids:
		var character_id := str(raw_id)
		if not loaded_state["affinity"].has(character_id):
			loaded_state["affinity"][character_id] = int(dm.call("get_initial_friendship", character_id))
		if not loaded_state["expressions"].has(character_id):
			loaded_state["expressions"][character_id] = "neutral"
	var player: Dictionary = loaded_state["player"]
	var player_id := str(player.get("id", "custom"))
	var node_id := str(loaded_state.get("node_id", ""))
	if node_id.is_empty() or DataStory.LEGACY_START_NODES.has(node_id) or not DataStory.NODES.has(node_id):
		node_id = DataStory.start_for_player(player_id)
	else:
		node_id = DataStory.resolve_for_player(node_id, player_id)
	loaded_state["node_id"] = node_id
	main.set("state", loaded_state)
	flow_screen.visible = false
	_set_main_screens(false, true, false)
	main.call("_go_to", node_id, false)
	main.call("_show_toast", "Partida cargada")
