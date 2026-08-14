extends "res://scripts/version_044_visit_transitions_data.gd"


func _complete_visit(character_id: String) -> void:
	super(character_id)
	if main == null:
		return
	var day_manager := main.get_node_or_null("NarrativeDayManager")
	if day_manager != null and day_manager.has_method("on_character_visit_completed"):
		day_manager.call_deferred("on_character_visit_completed", character_id)
