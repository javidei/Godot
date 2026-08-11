extends "res://scripts/version_042_layout_patch.gd"


func _apply_carmen_height() -> void:
	var views_value: Variant = main.get("character_views")
	if typeof(views_value) != TYPE_DICTIONARY:
		return
	var views: Dictionary = views_value
	var viewport_size := get_viewport().get_visible_rect().size
	var portrait := viewport_size.y > viewport_size.x
	for character_id in DataManager.get_character_ids(false):
		var view := views.get(character_id) as TextureRect
		if view == null:
			continue
		var visual := DataManager.get_character_visual(character_id)
		var raw_shift: Variant = visual.get("height_shift", {})
		if typeof(raw_shift) != TYPE_DICTIONARY:
			continue
		var shift_data := raw_shift as Dictionary
		var ratio := float(shift_data.get("portrait_ratio", 0.0)) if portrait else float(shift_data.get("landscape_ratio", 0.0))
		var minimum := float(shift_data.get("min", 0.0))
		var maximum := float(shift_data.get("max", maxf(minimum, viewport_size.y)))
		var shift := clampf(viewport_size.y * ratio, minimum, maximum)
		view.offset_top = shift
		view.offset_bottom = shift
		view.set_meta("height_shift", shift)
