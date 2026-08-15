extends SceneTree


func _initialize() -> void:
	var scene := load("res://scenes/main.tscn") as PackedScene
	if scene == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := scene.instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	await process_frame
	var menu := main.get_node_or_null("MenuScreen") as Control
	if menu == null:
		_fail("No existe MenuScreen")
		return
	var logo := menu.get_node_or_null("NaranjalStudioMenuLogo093") as TextureRect
	if logo == null:
		_fail("No se ha instalado el logo de Naranjal Studio")
		return
	if logo.texture == null:
		_fail("El logo no tiene textura")
		return
	if logo.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("El logo intercepta clics del menú")
		return
	if logo.position.x + logo.size.x > menu.size.x + 1.0 or logo.position.y + logo.size.y > menu.size.y + 1.0:
		_fail("El logo queda fuera del área visible")
		return
	print("V093 MENU BRANDING OK: logo blanco de Naranjal Studio integrado abajo a la derecha.")
	main.queue_free()
	quit(0)


func _fail(message: String) -> void:
	push_error("V093 MENU BRANDING FAIL: " + message)
	quit(1)
