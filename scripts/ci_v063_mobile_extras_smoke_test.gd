extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate() as Control
	root.add_child(main)
	for _i in range(36):
		await process_frame

	var extras := main.get_node_or_null("Version050ExtrasCodex")
	if extras == null:
		_fail("No se encuentra Version050ExtrasCodex")
		return

	extras.call("_open_extras")
	for _i in range(3):
		await process_frame
	var page_host := extras.get("page_host") as MarginContainer
	if page_host == null:
		_fail("Extras no expone el contenedor de páginas")
		return
	var home_scroll := _first_scroll(page_host)
	if home_scroll == null:
		_fail("La portada de Extras no está dentro de ScrollContainer")
		return
	if home_scroll.scroll_deadzone != 0 or home_scroll.horizontal_scroll_mode != ScrollContainer.SCROLL_MODE_DISABLED:
		_fail("El scroll táctil no tiene sensibilidad inmediata o permite desplazamiento horizontal")
		return
	var grid := page_host.find_child("ExtrasOptionsGrid050", true, false) as GridContainer
	if grid == null or grid.get_child_count() == 0:
		_fail("No se encuentra la cuadrícula de opciones de Extras")
		return
	var first_button := grid.get_child(0) as BaseButton
	if first_button == null or first_button.mouse_filter != Control.MOUSE_FILTER_PASS:
		_fail("Los botones dentro del scroll siguen bloqueando el gesto táctil")
		return

	extras.call("_show_collection")
	for _i in range(3):
		await process_frame
	var collection_scroll := _first_scroll(page_host)
	if collection_scroll == null or collection_scroll.scroll_deadzone != 0:
		_fail("Colección no usa el scroll táctil corregido")
		return
	var collection_card := page_host.find_child("CollectionCard_illustration_group", true, false) as PanelContainer
	if collection_card == null:
		_fail("No se encuentra la tarjeta Retratos del grupo")
		return
	var collection_icon := collection_card.find_child("CollectionStatusIcon063", true, false) as TextureRect
	var collection_title := collection_card.find_child("CollectionTitle063", true, false) as Label
	if collection_icon == null or collection_icon.texture == null or collection_title == null:
		_fail("La tarjeta de colección no usa icono SVG real")
		return
	if collection_title.text.contains("✓") or collection_title.text.contains("○"):
		_fail("La colección todavía depende de glifos Unicode para el estado")
		return
	if collection_title.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("El texto de colección sigue interceptando el drag táctil")
		return

	extras.call("_show_achievements")
	for _i in range(3):
		await process_frame
	var achievement_icon := page_host.find_child("AchievementStatusIcon063", true, false) as TextureRect
	if achievement_icon == null or achievement_icon.texture == null:
		_fail("Los logros no usan iconos SVG reales")
		return

	extras.call("_refresh_click_sound_controls", "soft")
	var click_buttons_value: Variant = extras.get("click_option_buttons")
	if typeof(click_buttons_value) != TYPE_DICTIONARY:
		_fail("No se puede validar el selector de sonidos")
		return
	var click_buttons := click_buttons_value as Dictionary
	var selected := click_buttons.get("soft") as Button
	var unselected := click_buttons.get("dry") as Button
	if selected == null or selected.icon == null or selected.text.contains("✓"):
		_fail("El sonido seleccionado sigue usando un check Unicode en vez de SVG")
		return
	if unselected != null and unselected.icon != null:
		_fail("Un sonido no seleccionado muestra el icono de selección")
		return

	print("V063 MOBILE EXTRAS OK: scroll táctil inmediato, eventos propagados e iconos SVG validados.")
	quit(0)


func _first_scroll(root_node: Node) -> ScrollContainer:
	if root_node is ScrollContainer:
		return root_node as ScrollContainer
	for node in root_node.find_children("*", "ScrollContainer", true, false):
		if node is ScrollContainer:
			return node as ScrollContainer
	return null


func _fail(message: String) -> void:
	push_error("V063 MOBILE EXTRAS FAIL: " + message)
	quit(1)
