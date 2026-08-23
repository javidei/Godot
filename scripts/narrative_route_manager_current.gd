extends "res://scripts/narrative_route_manager.gd"


func _apply_actions(progress: Dictionary, raw_actions: Variant) -> String:
	var message := super(progress, raw_actions)
	if typeof(raw_actions) == TYPE_DICTIONARY:
		_append_unique_values(progress, "easter_eggs_seen", (raw_actions as Dictionary).get("easter_eggs", []))
	return message
