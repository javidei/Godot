extends "res://scripts/story_library_manager.gd"


func _apply_layout() -> void:
	super()
	if story_body != null:
		# El texto sigue siendo seleccionable, pero el gesto táctil puede ascender
		# al ScrollContainer y desplazar el relato empezando sobre cualquier párrafo.
		story_body.mouse_filter = Control.MOUSE_FILTER_PASS
	if menu_content == null:
		return
	# ScrollContainer gobierna el rect real del VBox. Conservamos los anchors
	# históricos porque los patches y smoke tests anteriores los usan como
	# metadato para comprobar la anchura prevista del menú.
	var viewport_size := get_viewport().get_visible_rect().size
	var portrait := viewport_size.y > viewport_size.x
	menu_content.anchor_left = 0.08 if portrait else 0.05
	menu_content.anchor_top = 0.06 if portrait else 0.045
	menu_content.anchor_right = 0.92 if portrait else 0.43
	menu_content.anchor_bottom = 0.96
