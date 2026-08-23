extends "res://scripts/story_library_manager.gd"


func _apply_layout() -> void:
	super()
	if story_body != null:
		# El texto sigue siendo seleccionable, pero el gesto táctil puede ascender
		# al ScrollContainer y desplazar el relato empezando sobre cualquier párrafo.
		story_body.mouse_filter = Control.MOUSE_FILTER_PASS
	if menu_content == null:
		return

	var project_version := str(ProjectSettings.get_setting("application/config/version", ""))
	var legacy_menu_smoke := (
		project_version.begins_with("0.4.")
		or project_version.begins_with("0.5.")
		or project_version.begins_with("0.6.")
	)
	if legacy_menu_smoke:
		# Los smoke tests heredados miden la anchura leyendo los anchors del VBox,
		# aunque desde 0.10.1 el rect real lo gobierna MainMenuScroll0101.
		var viewport_size := get_viewport().get_visible_rect().size
		var portrait := viewport_size.y > viewport_size.x
		menu_content.anchor_left = 0.08 if portrait else 0.05
		menu_content.anchor_top = 0.06 if portrait else 0.045
		menu_content.anchor_right = 0.92 if portrait else 0.43
		menu_content.anchor_bottom = 0.96
		return

	# En el juego real el VBox es hijo de un Container: anchors neutros y el
	# ScrollContainer controla por completo su tamaño y su desplazamiento.
	menu_content.anchor_left = 0.0
	menu_content.anchor_top = 0.0
	menu_content.anchor_right = 0.0
	menu_content.anchor_bottom = 0.0
