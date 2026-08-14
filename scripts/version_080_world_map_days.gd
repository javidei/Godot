extends "res://scripts/version_067_world_map_icons.gd"


func _day_manager() -> Node:
	if main == null:
		return null
	return main.get_node_or_null("NarrativeDayManager")


func _configure_character_status(button: Button, character_id: String, visited: bool, list_layout: bool) -> void:
	var day_manager := _day_manager()
	if day_manager == null or not day_manager.has_method("get_character_day_status"):
		super(button, character_id, visited, list_layout)
		return
	var status := str(day_manager.call("get_character_day_status", character_id))
	match status:
		"required_complete", "clue_complete":
			super(button, character_id, true, list_layout)
			button.tooltip_text = "Objetivo del día completado · " + button.text
		"required_pending":
			super(button, character_id, false, list_layout)
			button.tooltip_text = "Objetivo del día pendiente · " + button.text
		"clue_pending":
			super(button, character_id, false, list_layout)
			button.tooltip_text = "Aquí puede haber una pista · " + button.text
		_:
			super(button, character_id, false, list_layout)
			var icon := button.get_node_or_null("MapStatusIcon_" + character_id) as TextureRect
			if icon != null:
				icon.visible = false
			button.tooltip_text = "Visita opcional · " + button.text


func _all_visits_complete() -> bool:
	var day_manager := _day_manager()
	if day_manager != null and day_manager.has_method("is_arc_complete"):
		return bool(day_manager.call("is_arc_complete"))
	return super()
