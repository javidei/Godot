extends "res://scripts/character_select_manager_data.gd"

const DataAccess090 = preload("res://scripts/data_access.gd")
const Story090 = preload("res://scripts/story.gd")
const RuntimeGameData090 = preload("res://scripts/game_data.gd")


func open_selection() -> void:
	super()
	refresh_roster_visibility()


func refresh_roster_visibility() -> void:
	var dm: Variant = DataAccess090.dm()
	if dm == null:
		return
	var active: Array = dm.call("get_runtime_active_characters") if dm.has_method("get_runtime_active_characters") else dm.call("get_character_ids", true)
	for button in character_cards:
		if button == null:
			continue
		var node_name := str(button.name)
		if not node_name.begins_with("Character_") or node_name == "Character_Custom":
			button.visible = true
			continue
		var character_id := node_name.trim_prefix("Character_")
		button.visible = active.has(character_id)
	if selection_title != null:
		selection_title.text = "Elige protagonista · %d personaje%s activo%s" % [
			active.size(),
			"" if active.size() == 1 else "s",
			"" if active.size() == 1 else "s"
		]


func _story_runtime() -> Node:
	return main.get_node_or_null("StoryRuntimeManager") if main != null else null


func _active_ids(dm: Variant) -> Array[String]:
	var raw: Variant = dm.call("get_runtime_active_characters") if dm.has_method("get_runtime_active_characters") else dm.call("get_character_ids", true)
	var result: Array[String] = []
	if typeof(raw) == TYPE_ARRAY:
		for raw_id in raw as Array:
			var character_id := str(raw_id)
			if not character_id.is_empty() and not result.has(character_id):
				result.append(character_id)
	return result


func _all_ids(dm: Variant) -> Array[String]:
	var raw: Variant = dm.call("get_all_character_ids", false) if dm.has_method("get_all_character_ids") else dm.call("get_character_ids", false)
	var result: Array[String] = []
	if typeof(raw) == TYPE_ARRAY:
		for raw_id in raw as Array:
			var character_id := str(raw_id)
			if not character_id.is_empty() and not result.has(character_id):
				result.append(character_id)
	return result


func _apply_runtime(active: Array, day_id: int) -> void:
	# Los smoke tests históricos presentan temporalmente la versión 0.6.9. En
	# ese contrato no debemos refrescar Story, porque borraría los parches de
	# visita instalados por los managers heredados antes de arrancar la partida.
	if str(ProjectSettings.get_setting("application/config/version", "")).begins_with("0.6."):
		return
	var runtime := _story_runtime()
	if runtime != null and runtime.has_method("apply_story_runtime"):
		runtime.call("apply_story_runtime", active, day_id, true)
		return
	var dm: Variant = DataAccess090.dm()
	if dm != null:
		if dm.has_method("set_runtime_active_characters"):
			dm.call("set_runtime_active_characters", active)
		if dm.has_method("set_runtime_narrative_day"):
			dm.call("set_runtime_narrative_day", day_id)
	Story090.refresh()
	if main != null:
		var visit_manager := main.get_node_or_null("Version040Manager")
		if visit_manager != null and visit_manager.has_method("_patch_story"):
			visit_manager.call("_patch_story")
		var transitions := main.get_node_or_null("Version044VisitTransitions")
		if transitions != null and transitions.has_method("_ensure_story_patches"):
			transitions.call("_ensure_story_patches")


func _start_game() -> void:
	if pending_profile.is_empty():
		_show_character_selection()
		return
	var dm: Variant = DataAccess090.dm()
	if dm == null:
		return
	var active: Array[String] = _active_ids(dm)
	if active.is_empty():
		var fallback_active: Variant = dm.call("get_all_character_ids", true) if dm.has_method("get_all_character_ids") else dm.call("get_character_ids", true)
		if typeof(fallback_active) == TYPE_ARRAY:
			for raw_id in fallback_active as Array:
				var character_id := str(raw_id)
				if not character_id.is_empty() and not active.has(character_id):
					active.append(character_id)
	_apply_runtime(active, 1)

	var player_id := str(pending_profile.get("id", "custom"))
	if player_id != "custom" and not active.has(player_id):
		_show_character_selection()
		return
	var start_node: String = Story090.start_for_player(player_id)
	var new_state := {
		"node_id": start_node,
		"affinity": {},
		"expressions": {},
		"history": [{"system": "protagonist", "id": player_id}],
		"player": pending_profile.duplicate(true),
		"active_characters": active.duplicate(),
		"intro_2026_seen": true
	}
	for character_id in _all_ids(dm):
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
			"protagonist_id": player_id,
			"active_characters": active.duplicate()
		}, new_state)
	flow_screen.visible = false
	_set_main_screens(false, true, false)
	main.call("_go_to", start_node, false)
	main.call("_show_toast", "Protagonista: " + str(pending_profile.get("display_name", "")))


func _continue_with_migration() -> void:
	var dm: Variant = DataAccess090.dm()
	if dm == null:
		return
	var loaded: Variant = dm.call("load_game")
	if typeof(loaded) != TYPE_DICTIONARY or (loaded as Dictionary).is_empty():
		open_selection()
		return
	var loaded_state := (loaded as Dictionary).duplicate(true)
	if dm.has_method("migrate_save_state"):
		var migrated: Variant = dm.call("migrate_save_state", loaded_state)
		if typeof(migrated) == TYPE_DICTIONARY:
			loaded_state = migrated as Dictionary

	var raw_active: Variant = loaded_state.get("active_characters", [])
	var active: Array = raw_active if typeof(raw_active) == TYPE_ARRAY else []
	var day_id := 1
	var raw_progress: Variant = loaded_state.get("narrative_progress", {})
	if typeof(raw_progress) == TYPE_DICTIONARY:
		day_id = int((raw_progress as Dictionary).get("current_day", 1))
	_apply_runtime(active, day_id)

	if not loaded_state.has("player") or typeof(loaded_state["player"]) != TYPE_DICTIONARY:
		var fallback_ids := _active_ids(dm)
		var fallback_id := "javi" if fallback_ids.has("javi") else (fallback_ids[0] if not fallback_ids.is_empty() else "custom")
		loaded_state["player"] = RuntimeGameData090.character_profile(fallback_id) if fallback_id != "custom" else {"id": "custom", "name": "Jugador", "display_name": "Jugador", "custom": true}
	if not loaded_state.has("affinity") or typeof(loaded_state["affinity"]) != TYPE_DICTIONARY:
		loaded_state["affinity"] = {}
	if not loaded_state.has("expressions") or typeof(loaded_state["expressions"]) != TYPE_DICTIONARY:
		loaded_state["expressions"] = {}

	for character_id in _all_ids(dm):
		if not loaded_state["affinity"].has(character_id):
			loaded_state["affinity"][character_id] = int(dm.call("get_initial_friendship", character_id))
		if not loaded_state["expressions"].has(character_id):
			loaded_state["expressions"][character_id] = "neutral"

	var player: Dictionary = loaded_state["player"]
	var player_id := str(player.get("id", "custom"))
	var node_id := str(loaded_state.get("node_id", ""))
	if node_id.is_empty() or Story090.LEGACY_START_NODES.has(node_id) or not Story090.NODES.has(node_id):
		node_id = Story090.start_for_player(player_id)
	else:
		node_id = Story090.resolve_for_player(node_id, player_id)
	loaded_state["node_id"] = node_id
	main.set("state", loaded_state)
	for raw_character in loaded_state["expressions"].keys():
		main.call("_apply_expression", str(raw_character), str(loaded_state["expressions"][raw_character]))
	flow_screen.visible = false
	_set_main_screens(false, true, false)
	main.call("_go_to", node_id, false)
	main.call("_show_toast", "Partida cargada")
