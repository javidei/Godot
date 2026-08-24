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
	for _i in range(42):
		await process_frame

	var manager := main.get_node_or_null("StoryLibraryManager")
	if manager == null:
		_fail("No se encuentra StoryLibraryManager")
		return

	var canon_path := "res://data/stories/la_palanca_iii_experience.json"
	var canon_file := FileAccess.open(canon_path, FileAccess.READ)
	if canon_file == null:
		_fail("No se puede leer el canon de La Palanca III")
		return
	var canon_text := canon_file.get_as_text()
	for forbidden_name in ["Javi", "Fran", "Jony", "Carlos", "Carmen"]:
		if canon_text.contains(forbidden_name):
			_fail("El relato todavía menciona un nombre real: " + forbidden_name)
			return
	for forbidden_term in ["detrás de la cámara", "para el espectador", "la película", "fuera de plano"]:
		if canon_text.to_lower().contains(forbidden_term):
			_fail("El relato rompe la ficción con lenguaje de rodaje: " + forbidden_term)
			return
	if not canon_text.contains("espacio-temporal") or not canon_text.contains("iglesia") or not canon_text.contains("dos líneas") or not canon_text.contains("Gaucho Saltarín") or not canon_text.contains("Carmela"):
		_fail("Faltan el túnel hacia la iglesia, la bifurcación o los nombres ficticios nuevos")
		return
	if not canon_text.contains("La división ocurrió allí; no la causó el láser ni el combate posterior"):
		_fail("No queda claro que la bifurcación ocurre en la iglesia y no por el láser")
		return

	if not canon_text.contains("construido por Rojo B") or not canon_text.contains("línea B") or not canon_text.contains("bucle causal"):
		_fail("Falta la revelación del Rojo alternativo como creador y villano real")
		return
	if not canon_text.contains("pretendía matarlo") or not canon_text.contains("Carmela rompió el plan"):
		_fail("La intención homicida del Robot o la intervención de Carmela no quedan claras")
		return
	if not canon_text.contains("El Gran Libro sobre las Palancas del Mundo") or not canon_text.contains("había llegado muy recientemente") or not canon_text.contains("papelería"):
		_fail("Faltan el libro, su llegada reciente o la papelería")
		return
	if not canon_text.contains("La Profecía de la Palanca") or not canon_text.contains("Bajo unas piedras") or not canon_text.contains("aniquilarlos a todos"):
		_fail("Falta la profecía cutre escondida bajo las piedras")
		return
	if not canon_text.contains("echando fuego por la boca") or not canon_text.contains("Pero así imponía más"):
		_fail("El dibujo del fuego no revela la autoría del Gaucho")
		return
	if not canon_text.contains("Huye, y no mires atrás"):
		_fail("Falta la orden directa de Rojo")
		return
	if not canon_text.contains("Negro no abandonó a Rojo") or not canon_text.contains("conoce al Gaucho Saltarín desde hace muchos años"):
		_fail("La relación de Negro con Rojo o con el Gaucho conserva el canon antiguo")
		return
	for forbidden_canon in ["Negro huyó", "fue abandonado por Negro", "conoce al Gaucho Saltarín: un monje"]:
		if canon_text.contains(forbidden_canon):
			_fail("El relato conserva una contradicción de continuidad: " + forbidden_canon)
			return
	if not canon_text.contains("EL ARCO DE LOS DOS ROJOS CONTINUARÁ"):
		_fail("La Palanca III cierra el arco que debe quedar abierto")
		return
	if not canon_text.contains("Él preparó el dibujo") or not canon_text.contains("introdujo las coordenadas"):
		_fail("No queda cerrado el montaje del Gaucho")
		return
	if not canon_text.contains("El Gaucho no enseñó a Rojo B") or not canon_text.contains("Instituto del GPS"):
		_fail("El origen del conocimiento de Rojo B sigue atribuido al Gaucho")
		return
	if not canon_text.contains("pidió al Gaucho que protegiera a Negro") or not canon_text.contains("rastrear la huella temporal"):
		_fail("Falta la misión secreta de protección encargada por Rojo A")
		return
	if not canon_text.contains("Rojo B ha localizado a Negro"):
		_fail("Carmela no tiene un detonante para romper el secreto")
		return
	for discarded_idea in ["mapa temporal", "mapa de los pasos", "Gaucho también formó", "conocimientos que había recibido del Gaucho"]:
		if canon_text.to_lower().contains(discarded_idea.to_lower()):
			_fail("El relato conserva una idea descartada: " + discarded_idea)
			return

	manager.call("_open_story", "trilogia_innecesaria")
	for _i in range(3):
		await process_frame

	var story_screen := manager.get("story_screen") as Control
	var experience := manager.get("story_experience") as VBoxContainer
	var story_body := manager.get("story_body") as RichTextLabel
	var gallery := manager.get("story_gallery") as GridContainer
	if story_screen == null or not story_screen.visible:
		_fail("La pantalla de La Palanca III no se abre")
		return
	if experience == null or not experience.visible or experience.get_child_count() != 9:
		_fail("La experiencia no contiene portada y ocho capítulos")
		return
	if story_body == null or story_body.visible or gallery == null or gallery.visible:
		_fail("La presentación antigua sigue visible detrás de la experiencia")
		return

	var story_scroll := manager.get("story_scroll") as ScrollContainer
	if story_scroll == null or story_scroll.scroll_deadzone != 0:
		_fail("La Palanca III no tiene desplazamiento táctil inmediato")
		return
	var first_chapter := experience.find_child("PalancaChapter", true, false) as PanelContainer
	if first_chapter == null or first_chapter.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("Las tarjetas narrativas siguen interceptando el arrastre táctil")
		return
	var first_body: RichTextLabel
	for node in experience.find_children("*", "RichTextLabel", true, false):
		first_body = node as RichTextLabel
		break
	if first_body == null or first_body.mouse_filter != Control.MOUSE_FILTER_IGNORE:
		_fail("El texto de La Palanca III sigue bloqueando el scroll móvil")
		return

	var logo_count := 0
	var comic_count := 0
	var comic_image: TextureRect
	for node in experience.find_children("*", "TextureRect", true, false):
		var image := node as TextureRect
		if image == null or image.texture == null:
			continue
		var role := str(image.get_meta("experience_role", ""))
		if role == "hero_image":
			logo_count += 1
		elif role == "comic_image":
			comic_count += 1
			if comic_image == null:
				comic_image = image
	if logo_count != 1 or comic_count != 5 or comic_image == null:
		_fail("No se han cargado el logo y las cinco páginas del cómic")
		return

	manager.call("_show_comic_lightbox", comic_image.texture, str(comic_image.get_meta("experience_caption", "")))
	var lightbox := manager.get("comic_lightbox") as ColorRect
	var lightbox_image := manager.get("comic_lightbox_image") as TextureRect
	if lightbox == null or not lightbox.visible or lightbox_image == null or lightbox_image.texture == null:
		_fail("El visor ampliado no abre la página seleccionada")
		return
	manager.call("_close_comic_lightbox")
	if lightbox.visible:
		_fail("El visor ampliado no se cierra")
		return

	manager.call("_open_story", "historia_asesino")
	for _i in range(3):
		await process_frame
	if experience.visible or not story_body.visible:
		_fail("La experiencia de La Palanca invade Historia de un asesino")
		return

	print("V01011 PALANCA OK: portada, capítulos, scroll táctil, cómic, ampliación y aislamiento validados.")
	quit(0)


func _fail(message: String) -> void:
	push_error("V01011 PALANCA FAIL: " + message)
	quit(1)
