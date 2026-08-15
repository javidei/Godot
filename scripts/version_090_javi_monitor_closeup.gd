extends "res://scripts/version_081_javi_monitor_closeup.gd"


func _is_javi_room_active() -> bool:
	if not super():
		return false
	var raw_state: Variant = main.get("state") if main != null else {}
	if typeof(raw_state) != TYPE_DICTIONARY:
		return false
	var progress: Variant = (raw_state as Dictionary).get("narrative_progress", {})
	if typeof(progress) != TYPE_DICTIONARY:
		return false
	return int((progress as Dictionary).get("current_day", 1)) == 3
