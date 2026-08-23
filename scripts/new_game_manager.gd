extends Node

const DataAccess = preload("res://scripts/data_access.gd")
const Story = preload("res://scripts/story.gd")

const GUEST_PROFILE := {
	"id": "custom",
	"name": "Invitado",
	"display_name": "Invitado",
	"gender": "No especificar",
	"appearance": "",
	"role": "invitado",
	"custom": true,
	"guest": true
}

var main: Control
var _waiting_for_prelude := false


func _ready() -> void:
	for _i in range(4):
		await get_tree().process_frame
	main = get_parent() as Control
	if main == null:
		return
	_rewire_fallback_buttons()


# Compatibilidad con llamadas antiguas: ya no existe selector de protagonista.
func open_selection() -> void:
	if main != null:
		var slots := main.get_node_or_null("SaveSlotsManager")
		if slots != null and slots.has_method("open_new_game_slots") and slots.get("slots_screen") != null:
			slots.call("open_new_game_slots")
			return
	_begin_new_game()


func _begin_new_game() -> void:
	if _waiting_for_prelude:
		return
	var transition := _transition_manager()
	if transition != null and transition.has_method("play_new_game_intro"):
		_waiting_for_prelude = true
		transition.call("play_new_game_intro", Callable(self, "_finish_new_game_prelude"))
		return
	_start_guest_game()


func _finish_new_game_prelude() -> void:
	_waiting_for_prelude = false
	var transition := _transition_manager()
	if transition != null and transition.has_method("prime_next_generic_from_black"):
		transition.call("prime_next_generic_from_black")
	_start_guest_game()
	_begin_day_one_intro()


func _start_guest_game() -> void:
	if main == null:
		return
	var dm: Variant = DataAccess.dm()
	if dm == null:
		return
	dm.call("ensure_loaded")

	var active := _active_character_ids(dm)
	_apply_runtime(active, 1)
	var start_node := Story.start_for_player("custom")
	var new_state := {
		"node_id": start_node,
		"affinity": {},
		"expressions": {},
		"history": [{"system": "player", "id": "guest"}],
		"player": GUEST_PROFILE.duplicate(true),
		"active_characters": active.duplicate()
	}
	for character_id in _all_character_ids(dm):
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
			"protagonist_id": "custom",
			"active_characters": active.duplicate()
		}, new_state)
	_show_game_screen()
	main.call("_go_to", start_node, false)
	main.call("_save_game", false)


func _continue_with_migration() -> void:
	if main == null:
		return
	var dm: Variant = DataAccess.dm()
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

	if not loaded_state.has("player") or typeof(loaded_state["player"]) != TYPE_DICTIONARY:
		loaded_state["player"] = GUEST_PROFILE.duplicate(true)
	if not loaded_state.has("affinity") or typeof(loaded_state["affinity"]) != TYPE_DICTIONARY:
		loaded_state["affinity"] = {}
	if not loaded_state.has("expressions") or typeof(loaded_state["expressions"]) != TYPE_DICTIONARY:
		loaded_state["expressions"] = {}

	var active: Array[String] = []
	var raw_active: Variant = loaded_state.get("active_characters", [])
	if typeof(raw_active) == TYPE_ARRAY:
		for raw_id in raw_active as Array:
			var character_id := str(raw_id)
			if not character_id.is_empty() and not active.has(character_id):
				active.append(character_id)
	if active.is_empty():
		active = _active_character_ids(dm)
	loaded_state["active_characters"] = active

	for character_id in _all_character_ids(dm):
		if not loaded_state["affinity"].has(character_id):
			loaded_state["affinity"][character_id] = int(dm.call("get_initial_friendship", character_id))
		if not loaded_state["expressions"].has(character_id):
			loaded_state["expressions"][character_id] = "neutral"

	var day_id := _state_day(loaded_state)
	_apply_runtime(active, day_id)
	var player := loaded_state["player"] as Dictionary
	var player_id := str(player.get("id", "custom"))
	var node_id := str(loaded_state.get("node_id", ""))
	if node_id.is_empty() or Story.LEGACY_START_NODES.has(node_id) or not Story.NODES.has(node_id):
		node_id = Story.start_for_player(player_id)
	else:
		node_id = Story.resolve_for_player(node_id, player_id)
	loaded_state["node_id"] = node_id
	main.set("state", loaded_state)
	for raw_character in loaded_state["expressions"].keys():
		main.call("_apply_expression", str(raw_character), str(loaded_state["expressions"][raw_character]))
	_show_game_screen()
	main.call("_go_to", node_id, false)
	main.call("_show_toast", "Partida cargada")


func _apply_runtime(active: Array[String], day_id: int) -> void:
	if main == null:
		return
	var runtime := main.get_node_or_null("StoryRuntimeManager")
	if runtime != null and runtime.has_method("apply_story_runtime"):
		runtime.call("apply_story_runtime", active, day_id, true)
		return
	var dm: Variant = DataAccess.dm()
	if dm != null:
		if dm.has_method("set_runtime_active_characters"):
			dm.call("set_runtime_active_characters", active)
		if dm.has_method("set_runtime_narrative_day"):
			dm.call("set_runtime_narrative_day", day_id)
	Story.refresh()
	var battle_manager := main.get_node_or_null("Version040Manager")
	if battle_manager != null and battle_manager.has_method("_patch_story"):
		battle_manager.call("_patch_story")
	var transitions := _transition_manager()
	if transitions != null and transitions.has_method("_ensure_story_patches"):
		transitions.call("_ensure_story_patches")


func _begin_day_one_intro() -> void:
	if main == null:
		return
	var day_manager := main.get_node_or_null("NarrativeDayManager")
	if day_manager != null and day_manager.has_method("_begin_day_intro"):
		day_manager.call("_begin_day_intro")


func _show_game_screen() -> void:
	if main == null:
		return
	var menu := main.get("menu_screen") as Control
	var game := main.get("game_screen") as Control
	var ending := main.get("ending_screen") as Control
	if menu != null:
		menu.visible = false
	if ending != null:
		ending.visible = false
	if game != null:
		game.visible = true


func _transition_manager() -> Node:
	return main.get_node_or_null("Version044VisitTransitions") if main != null else null


func _active_character_ids(dm: Variant) -> Array[String]:
	var raw: Variant = dm.call("get_runtime_active_characters") if dm.has_method("get_runtime_active_characters") else dm.call("get_all_character_ids", true)
	var result: Array[String] = []
	if typeof(raw) == TYPE_ARRAY:
		for raw_id in raw as Array:
			var character_id := str(raw_id)
			if not character_id.is_empty() and not result.has(character_id):
				result.append(character_id)
	if result.is_empty():
		var fallback: Variant = dm.call("get_all_character_ids", true)
		if typeof(fallback) == TYPE_ARRAY:
			for raw_id in fallback as Array:
				var character_id := str(raw_id)
				if not character_id.is_empty() and not result.has(character_id):
					result.append(character_id)
	return result


func _all_character_ids(dm: Variant) -> Array[String]:
	var raw: Variant = dm.call("get_all_character_ids", false) if dm.has_method("get_all_character_ids") else dm.call("get_character_ids", false)
	var result: Array[String] = []
	if typeof(raw) == TYPE_ARRAY:
		for raw_id in raw as Array:
			var character_id := str(raw_id)
			if not character_id.is_empty() and not result.has(character_id):
				result.append(character_id)
	return result


func _state_day(source: Dictionary) -> int:
	var progress: Variant = source.get("narrative_progress", {})
	return int((progress as Dictionary).get("current_day", 1)) if typeof(progress) == TYPE_DICTIONARY else 1


func _rewire_fallback_buttons() -> void:
	var menu_content := main.get("menu_content") as VBoxContainer
	var ending_screen := main.get("ending_screen") as Control
	var new_button := _find_button(menu_content, "Nueva partida")
	var again_button := _find_button(ending_screen, "Jugar de nuevo")
	var old_new := Callable(main, "_start_new_game")
	for button in [new_button, again_button]:
		if button == null:
			continue
		if button.pressed.is_connected(old_new):
			button.pressed.disconnect(old_new)
		var callback := Callable(self, "open_selection") if button == new_button else Callable(self, "_begin_new_game")
		if not button.pressed.is_connected(callback):
			button.pressed.connect(callback)


func _find_button(root: Node, text: String) -> Button:
	if root == null:
		return null
	for node in root.find_children("*", "Button", true, false):
		var button := node as Button
		if button != null and button.text == text:
			return button
	return null
