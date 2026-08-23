extends Node

const Story = preload("res://scripts/story.gd")
const DataAccess = preload("res://scripts/data_access.gd")

var main: Control
var data_manager: Node


func _ready() -> void:
	for _i in range(12):
		await get_tree().process_frame
	main = get_parent() as Control
	data_manager = DataAccess.dm() as Node
	if main == null or data_manager == null:
		return
	data_manager.call("ensure_loaded")
	apply_story_runtime(_all_ids(), _runtime_day(), true)


func apply_story_runtime(_character_ids: Array, day_id: int, update_title: bool = true) -> void:
	if data_manager == null:
		data_manager = DataAccess.dm() as Node
	if data_manager == null:
		return
	var active := _all_ids()
	if data_manager.has_method("set_runtime_active_characters"):
		data_manager.call("set_runtime_active_characters", active)
	if data_manager.has_method("set_runtime_narrative_day"):
		data_manager.call("set_runtime_narrative_day", maxi(1, day_id))
	Story.refresh()
	_repatch_story()
	if update_title:
		_update_dynamic_title()


func sync_from_state(state: Dictionary) -> void:
	if state.is_empty():
		return
	apply_story_runtime(_all_ids(), _state_day(state), true)


func _all_ids() -> Array[String]:
	if data_manager == null:
		data_manager = DataAccess.dm() as Node
	if data_manager == null:
		return []
	var raw: Variant = data_manager.call("get_all_character_ids", true) if data_manager.has_method("get_all_character_ids") else data_manager.call("get_character_ids", true)
	var result: Array[String] = []
	if typeof(raw) == TYPE_ARRAY:
		for raw_id in raw as Array:
			var character_id := str(raw_id)
			if not character_id.is_empty() and not result.has(character_id):
				result.append(character_id)
	return result


func _runtime_day() -> int:
	if data_manager != null and data_manager.has_method("get_runtime_narrative_day"):
		return maxi(1, int(data_manager.call("get_runtime_narrative_day")))
	if data_manager != null and data_manager.has_method("get_default_narrative_day"):
		return maxi(1, int(data_manager.call("get_default_narrative_day")))
	return 1


func _state_day(source: Dictionary) -> int:
	var progress: Variant = source.get("narrative_progress", {})
	return maxi(1, int((progress as Dictionary).get("current_day", 1))) if typeof(progress) == TYPE_DICTIONARY else 1


func _repatch_story() -> void:
	if main == null:
		return
	var visit_manager := main.get_node_or_null("Version040Manager")
	if visit_manager != null and visit_manager.has_method("_patch_story"):
		visit_manager.call("_patch_story")
	var transitions := main.get_node_or_null("Version044VisitTransitions")
	if transitions != null and transitions.has_method("_ensure_story_patches"):
		transitions.call("_ensure_story_patches")


func _update_dynamic_title() -> void:
	var title := Story.game_title()
	ProjectSettings.set_setting("application/config/name", title)
	if main == null:
		return
	main.get_window().title = title
	var label := main.find_child("GameTitle", true, false) as Label
	if label != null:
		label.text = Story.menu_title()
