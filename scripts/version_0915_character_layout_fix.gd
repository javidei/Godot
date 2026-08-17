extends "res://scripts/version_0913_character_layout_fix.gd"


func _fix_character_card_name_bands() -> void:
	super()
	if page_host == null or current_page != "characters":
		return
	var grid := page_host.find_child("CharacterCodexGrid050", true, false) as GridContainer
	if grid == null:
		return

	for child in grid.get_children():
		var card := child as Button
		if card == null or card.get_child_count() == 0:
			continue
		var root := card.get_child(0) as Control
		if root == null:
			continue

		var portrait := root.find_child("CharacterCardPortrait", true, false) as TextureRect
		if portrait != null:
			portrait.anchor_bottom = 0.87

		for candidate in root.get_children():
			if candidate is ColorRect:
				var footer := candidate as ColorRect
				# Etiqueta interior: ya no toca el marco ni ocupa toda la anchura.
				footer.anchor_left = 0.025
				footer.anchor_top = 0.875
				footer.anchor_right = 0.975
				footer.anchor_bottom = 0.975
				footer.offset_left = 0.0
				footer.offset_top = 0.0
				footer.offset_right = 0.0
				footer.offset_bottom = 0.0
				footer.color = Color(0.02, 0.014, 0.012, 0.72)
				var label := footer.get_child(0) as Label if footer.get_child_count() > 0 else null
				if label != null:
					label.add_theme_font_size_override("font_size", 14)
				break
