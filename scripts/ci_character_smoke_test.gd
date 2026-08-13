extends SceneTree

const CHARACTER_IDS: Array[String] = ["javi", "sue", "smokey", "carmen", "jony", "ana", "argentino"]
const CHARACTER_NAMES := {
	"javi": "Javi",
	"sue": "Sue",
	"smokey": "Smokey",
	"carmen": "Carmen",
	"jony": "Jony",
	"ana": "Ana",
	"argentino": "El Argentino"
}
const EXPECTED_BACKGROUNDS := {
	"javi": "habitacion_javi",
	"sue": "habitacion_sue",
	"smokey": "habitacion_fran",
	"carmen": "habitacion_fran",
	"jony": "habitacion_jony",
	"ana": "habitacion_ana",
	"argentino": "habitacion_argentino"
}
const BACKGROUND_IDS: Array[String] = [
	"bar",
	"bosque",
	"casa_asturias",
	"habitacion_ana",
	"habitacion_argentino",
	"habitacion_fran",
	"habitacion_sue",
	"habitacion_jony",
	"habitacion_javi"
]
const Story = preload("res://scripts/story.gd")


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var project_version := str(ProjectSettings.get_setting("application/config/version", ""))
	if not project_version.begins_with("0.6."):
		_fail("La versión del proyecto no pertenece a la rama 0.6.x")
		return
	if Story.game_title() != "Entre líneas: La octava silla":
		_fail("El título actual no se calcula desde los siete personajes")
		return
	if Story.title_for_character_count(13) != "Entre líneas: La decimocuarta silla":
		_fail("El título no calcula correctamente la silla para trece personajes")
		return
	if not _validate_story_data():
		return

	var packed := load("res://scenes/main.tscn") as PackedScene
	if packed == null:
		_fail("No se puede cargar main.tscn")
		return
	var main := packed.instantiate()
	root.add_child(main)
	for _i in range(10):
		await process_frame
	if str(ProjectSettings.get_setting("application/config/name", "")) != Story.game_title() or root.title != Story.game_title():
		_fail("El título dinámico no se aplica a la ventana del juego")
		return

	var slots: Dictionary = main.get("character_slots")
	var views: Dictionary = main.get("character_views")
	var assets: Variant = main.get("asset_manager")
	var audio: Variant = main.get("audio_manager")
	if assets == null:
		_fail("AssetManager no está disponible")
		return
	if audio == null:
		_fail("AudioManager no está disponible")
		return
	for background_id in BACKGROUND_IDS:
		var background_texture: Texture2D = assets.call("get_background", background_id) as Texture2D
		if background_texture == null or background_texture.get_size().x <= 0.0 or background_texture.get_size().y <= 0.0:
			_fail("No carga el fondo: " + background_id)
			return
		var music_id := str(audio.call("music_for_background", background_id))
		var music_path := str(audio.call("path_for_music", music_id))
		if music_id.is_empty() or not music_path.begins_with("res://assets/audio/music/") or not music_path.ends_with(".ogg"):
			_fail("El fondo no tiene una canción OGG preparada: " + background_id)
			return

	var menu_background := main.get("menu_background") as TextureRect
	var home_background: Texture2D = assets.call("get_background", "casa_asturias") as Texture2D
	if menu_background == null or menu_background.texture == null or menu_background.texture.resource_path != home_background.resource_path:
		_fail("La pantalla principal no usa Casa Asturias")
		return

	var test_state := {
		"node_id": Story.START,
		"affinity": {},
		"expressions": {},
		"history": [],
		"player": {"id": "custom", "display_name": "Prueba", "custom": true},
		"visit_mode": true,
		"completed_characters": [],
		"visit_order": [],
		"coins": 0,
		"claimed_rewards": {},
		"current_zone_id": "naranjal_del_rio"
	}
	for character_id in CHARACTER_IDS:
		if not slots.has(character_id) or not views.has(character_id):
			_fail("Falta la vista del personaje: " + character_id)
			return
		var texture: Texture2D = assets.call("get_character", character_id, "neutral") as Texture2D
		if texture == null or texture.get_size().x <= 0.0 or texture.get_size().y <= 0.0:
			_fail("No carga la textura PNG de: " + character_id)
			return
		test_state["affinity"][character_id] = 0
		test_state["expressions"][character_id] = "neutral"
	main.set("state", test_state)

	var selection_ok: bool = await _validate_selection(main)
	if not selection_ok:
		return
	main.set("state", test_state)

	for character_id in CHARACTER_IDS:
		main.call("_go_to", character_id + "_intro_01", false)
		await process_frame
		if not _only_character_visible(slots, character_id):
			_fail("El encuentro no muestra exclusivamente a: " + character_id)
			return
		var expected_background_id := str(EXPECTED_BACKGROUNDS[character_id])
		var expected_background: Texture2D = assets.call("get_background", expected_background_id) as Texture2D
		var current_background := main.get("game_background") as TextureRect
		if current_background == null or current_background.texture == null or current_background.texture.resource_path != expected_background.resource_path:
			_fail("El fondo no corresponde al personaje: " + character_id)
			return

	main.call("_go_to", "ana_q2", false)
	main.call("_finish_typing")
	await process_frame
	var choices_box: GridContainer = main.get("choices_box") as GridContainer
	if choices_box == null or choices_box.columns != 2 or choices_box.get_child_count() != 4:
		_fail("Las preguntas no muestran cuatro respuestas en dos columnas")
		return
	for child in choices_box.get_children():
		var answer_button := child as Button
		if answer_button == null or answer_button.custom_minimum_size.y < 64.0 or (answer_button.size_flags_horizontal & Control.SIZE_EXPAND) == 0:
			_fail("Una respuesta no tiene el área táctil ancha esperada")
			return

	var title := _find_named(main, "GameTitle") as Label
	var engine_tag := _find_named(main, "EngineTag") as Label
	var narrative_font := load("res://assets/ui/fonts/DejaVuSerif-Bold.ttf") as Font
	var exit_button := _find_named(main, "ExitGameButton") as Button
	var version_label := _find_named(main, "VersionLabel") as Label
	var music_down_button := _find_named(main, "MusicVolumeDownButton") as Button
	var music_up_button := _find_named(main, "MusicVolumeUpButton") as Button
	var music_volume_label := _find_named(main, "MusicVolumeLabel") as Label
	var music_mute_button := _find_named(main, "MusicMuteButton") as Button
	var effects_down_button := _find_named(main, "EffectsVolumeDownButton") as Button
	var effects_up_button := _find_named(main, "EffectsVolumeUpButton") as Button
	var effects_volume_label := _find_named(main, "EffectsVolumeLabel") as Label
	var effects_mute_button := _find_named(main, "EffectsMuteButton") as Button
	var menu_content: VBoxContainer = main.get("menu_content") as VBoxContainer
	var menu_characters := main.get("menu_characters") as TextureRect
	if title == null or title.text != Story.menu_title() or narrative_font == null or not title.has_theme_font_override("font"):
		_fail("El menú no muestra el título dinámico y su tipografía narrativa")
		return
	if engine_tag == null or engine_tag.text != "GODOT 4 · NOVELA VISUAL" or engine_tag.text.contains("DEMO"):
		_fail("La cabecera del menú todavía muestra DEMO")
		return
	if exit_button == null or exit_button.text != "Salir":
		_fail("El menú principal no contiene el botón Salir")
		return
	if _count_buttons_with_text(menu_content, "Salir") != 1:
		_fail("El menú principal no contiene exactamente un botón Salir")
		return
	if _find_named(main, "ExitGameConfirmation") != null:
		_fail("El popup de confirmación de salida no se ha eliminado")
		return
	if version_label == null or not version_label.text.contains("Versión %s · EARLY ACCESS" % project_version):
		_fail("La versión actual no se muestra en el menú")
		return
	if music_down_button == null or music_up_button == null or music_volume_label == null or music_mute_button == null:
		_fail("El menú no contiene todos los controles de música")
		return
	if effects_down_button == null or effects_up_button == null or effects_volume_label == null or effects_mute_button == null:
		_fail("El menú no contiene todos los controles de efectos")
		return
	if int(audio.call("get_music_volume_percent")) != 30 or int(audio.call("get_effects_volume_percent")) != 100:
		_fail("Los volúmenes iniciales no son música 30 % y efectos 100 %")
		return
	if not is_equal_approx(float(audio.call("get_music_output_linear")), 0.03):
		_fail("El 30 % de música no equivale al 3 % de la escala anterior")
		return
	var music_bus := AudioServer.get_bus_index("Music")
	var effects_bus := AudioServer.get_bus_index("SFX")
	if music_bus < 0 or effects_bus < 0:
		_fail("No se han creado los buses de música y efectos")
		return
	if not is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(music_bus)), 0.03):
		_fail("El bus Music no aplica el límite de salida del 10 %")
		return
	if not is_equal_approx(db_to_linear(AudioServer.get_bus_volume_db(effects_bus)), 1.0):
		_fail("El bus SFX ya no conserva su escala completa")
		return
	audio.call("set_music_volume", 0.4)
	audio.call("set_effects_volume", 0.8)
	main.call("_refresh_audio_controls")
	if not music_volume_label.text.contains("40 %") or not effects_volume_label.text.contains("80 %"):
		_fail("Los indicadores separados no reflejan sus niveles")
		return
	audio.call("set_music_volume", 1.0)
	if not is_equal_approx(float(audio.call("get_music_output_linear")), 0.1):
		_fail("El 100 % de música no equivale al 10 % de la escala anterior")
		return
	var effects_was_muted := bool(audio.call("is_effects_muted"))
	main.call("_toggle_music_mute")
	var music_is_muted := bool(audio.call("is_music_muted"))
	var expected_music_text := "Activar música" if music_is_muted else "Silenciar música"
	if not music_is_muted or music_mute_button.text != expected_music_text or bool(audio.call("is_effects_muted")) != effects_was_muted:
		_fail("El silencio de música no funciona de forma independiente")
		return
	main.call("_toggle_music_mute")
	main.call("_toggle_effects_mute")
	var effects_are_muted := bool(audio.call("is_effects_muted"))
	var expected_effects_text := "Activar efectos" if effects_are_muted else "Silenciar efectos"
	if not effects_are_muted or effects_mute_button.text != expected_effects_text or bool(audio.call("is_music_muted")):
		_fail("El silencio de efectos no funciona de forma independiente")
		return
	main.call("_toggle_effects_mute")
	if menu_characters == null or not is_equal_approx(menu_characters.anchor_left, 1.0) or not is_equal_approx(menu_characters.anchor_top, 1.0) or not is_zero_approx(menu_characters.offset_right) or not is_zero_approx(menu_characters.offset_bottom):
		_fail("El trío del menú no está anclado abajo a la derecha")
		return
	if menu_content == null or menu_content.anchor_right - menu_content.anchor_left < 0.35:
		_fail("Los botones del menú no conservan un ancho usable")
		return

	main.call("_go_to", "sue_intro_01", false)
	await process_frame
	var habitacion_sue: Texture2D = assets.call("get_background", "habitacion_sue") as Texture2D
	var game_background := main.get("game_background") as TextureRect
	if habitacion_sue == null or game_background == null or game_background.texture == null or game_background.texture.resource_path != habitacion_sue.resource_path:
		_fail("El fondo de la habitación de Sue no carga")
		return

	var scored_state: Dictionary = main.get("state")
	for index in range(CHARACTER_IDS.size()):
		scored_state["affinity"][CHARACTER_IDS[index]] = index % 4
	scored_state["player"] = {"id": "javi", "display_name": "Javi", "custom": false}
	main.set("state", scored_state)
	main.call("_finish_demo")
	await process_frame
	var ending_affinity: Label = main.get("ending_affinity") as Label
	if ending_affinity == null or not ending_affinity.text.contains("TOTAL") or not ending_affinity.text.contains("/18"):
		_fail("El resumen final no adapta el total a seis encuentros")
		return
	if ending_affinity.text.contains(str(CHARACTER_NAMES["javi"])):
		_fail("El protagonista elegido aparece en el resumen final")
		return
	for index in range(1, CHARACTER_IDS.size()):
		var character_id: String = CHARACTER_IDS[index]
		if not ending_affinity.text.contains(str(CHARACTER_NAMES[character_id])):
			_fail("El resumen final no incluye a: " + character_id)
			return

	scored_state["player"] = {"id": "custom", "display_name": "Prueba", "custom": true}
	main.set("state", scored_state)
	main.call("_finish_demo")
	await process_frame
	if not ending_affinity.text.contains("/21"):
		_fail("El personaje personalizado no conserva los siete encuentros")
		return
	for character_id in CHARACTER_IDS:
		if not ending_affinity.text.contains(str(CHARACTER_NAMES[character_id])):
			_fail("El resumen personalizado no incluye a: " + character_id)
			return

	if _find_named(main, "InstallMobileButton") != null or _find_named(main, "InstallMobileConfirmation") != null or _find_named(main, "SelectionInstallMobileButton") != null:
		_fail("Han reaparecido controles de instalación móvil")
		return

	print("SMOKE OK: protagonista excluido, mapa integrado, 6/7 encuentros dinámicos, fondos, 4 respuestas y resumen adaptado.")
	quit(0)


func _validate_story_data() -> bool:
	if Story.ENCOUNTER_ORDER.size() != 7:
		_fail("La historia no contiene siete encuentros")
		return false
	var question_counts := {}
	for character_id in CHARACTER_IDS:
		var order: Array[String] = Story.encounter_order_for_player(character_id)
		if order.size() != 6 or order.has(character_id):
			_fail("El recorrido no excluye al protagonista: " + character_id)
			return false
		var start_node := Story.start_for_player(character_id)
		if Story.character_for_node(start_node) == character_id:
			_fail("La partida empieza mostrando al protagonista: " + character_id)
			return false
		var resolved_node := Story.resolve_for_player(character_id + "_intro_01", character_id)
		if Story.character_for_node(resolved_node) == character_id:
			_fail("La navegación no salta el encuentro del protagonista: " + character_id)
			return false
		question_counts[character_id] = 0
		if not Story.NODES.has(character_id + "_intro_01"):
			_fail("Falta la presentación de: " + character_id)
			return false
		var encounter: Dictionary = Story.ENCOUNTERS.get(character_id, {})
		if str(encounter.get("background", "")) != str(EXPECTED_BACKGROUNDS[character_id]):
			_fail("El catálogo no asigna el fondo correcto a: " + character_id)
			return false
		var intro_text := ""
		var intro_lines: Array = encounter.get("intro", [])
		for intro_line_value in intro_lines:
			var intro_line: Dictionary = intro_line_value
			intro_text += " " + str(intro_line.get("text", ""))
		var encounter_questions: Array = encounter.get("questions", [])
		for question_value in encounter_questions:
			var question: Dictionary = question_value
			var labels: Array = question.get("choices", [])
			var correct_index := int(question.get("correct", -1))
			if labels.size() != 4 or correct_index < 0 or correct_index >= labels.size():
				_fail("Una pregunta de %s no tiene cuatro respuestas válidas" % character_id)
				return false
			var correct_answer := str(labels[correct_index])
			if _normalize_text(intro_text).contains(_normalize_text(correct_answer)):
				_fail("La presentación de %s revela una respuesta: %s" % [character_id, correct_answer])
				return false

	for node_id in Story.NODES.keys():
		var node: Dictionary = Story.NODES[node_id]
		var shown: Array = node.get("show", [])
		if shown.size() != 1:
			_fail("La escena %s no muestra exactamente un personaje" % node_id)
			return false
		if node.has("next"):
			var next_id := str(node["next"])
			if next_id != "__END__" and not Story.NODES.has(next_id):
				_fail("La escena %s apunta a una escena inexistente" % node_id)
				return false
		if str(node.get("speaker", "")) != "Narrador":
			var shown_character := str(shown[0])
			if str(node.get("background", "")) != str(EXPECTED_BACKGROUNDS.get(shown_character, "")):
				_fail("La escena %s no conserva el fondo de %s" % [node_id, shown_character])
				return false
		if not node.has("question_character"):
			continue
		var character_id := str(node["question_character"])
		question_counts[character_id] = int(question_counts.get(character_id, 0)) + 1
		var choices: Array = node.get("choices", [])
		if choices.size() != 4:
			_fail("La pregunta %s no tiene cuatro respuestas" % node_id)
			return false
		var scoring_choices := 0
		for choice in choices:
			var next_id := str(choice.get("next", ""))
			if not Story.NODES.has(next_id):
				_fail("Una respuesta de %s no tiene continuación" % node_id)
				return false
			var affinity: Dictionary = choice.get("affinity", {})
			if int(affinity.get(character_id, 0)) == 1:
				scoring_choices += 1
		if scoring_choices != 1:
			_fail("La pregunta %s no tiene una única respuesta correcta" % node_id)
			return false

	for character_id in CHARACTER_IDS:
		if int(question_counts[character_id]) != 3:
			_fail("%s no tiene exactamente tres preguntas" % character_id)
			return false
	return true


func _normalize_text(value: String) -> String:
	return value.to_lower().replace("á", "a").replace("é", "e").replace("í", "i").replace("ó", "o").replace("ú", "u").replace("ü", "u")


func _validate_selection(main: Control) -> bool:
	var selection_manager := main.get_node_or_null("CharacterSelectManager")
	if selection_manager == null:
		_fail("CharacterSelectManager no está disponible")
		return false
	selection_manager.call("open_selection")
	await process_frame
	var character_grid := selection_manager.get("character_grid") as GridContainer
	var character_cards: Array = selection_manager.get("character_cards") as Array
	if character_grid == null or character_grid.columns != 4 or character_cards.size() != 8:
		_fail("La selección no conserva sus ocho tarjetas en cuatro columnas")
		return false
	for character_id in CHARACTER_IDS:
		var card := _find_named(main, "Character_" + character_id)
		var portrait := _find_texture_rect(card)
		if portrait == null or portrait.texture == null or not portrait.is_visible_in_tree():
			_fail("Retrato vacío en selección: " + character_id)
			return false
		if portrait.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_CENTERED:
			_fail("El retrato puede volver a cortar la cabeza: " + character_id)
			return false
	selection_manager.call("_select_existing_character", "javi")
	for _i in range(8):
		await process_frame
	var selected_state: Dictionary = main.get("state")
	var selected_player: Dictionary = selected_state.get("player", {})
	if str(selected_player.get("id", "")) != "javi" or str(selected_state.get("node_id", "")) != "__VISIT_SELECT__":
		_fail("Elegir a Javi no abre el mapa técnico de visitas")
		return false
	var world_map := main.get_node_or_null("WorldMapManager")
	if world_map == null or not bool(world_map.call("is_open")):
		_fail("El mapa no sustituye al antiguo selector tras elegir protagonista")
		return false
	if _find_named(main, "MapCharacter_javi") != null or _find_named(main, "MapCharacter_sue") == null:
		_fail("El mapa no excluye al protagonista o no ofrece al resto del grupo")
		return false
	var flow_screen := selection_manager.get("flow_screen") as Control
	if flow_screen == null or flow_screen.visible:
		_fail("La selección no se cierra al elegir protagonista")
		return false
	selection_manager.call("_set_main_screens", false, true, false)
	return true


func _only_character_visible(slots: Dictionary, expected_id: String) -> bool:
	var visible_count := 0
	for character_id in CHARACTER_IDS:
		var slot: Control = slots.get(character_id) as Control
		if slot != null and slot.is_visible_in_tree():
			visible_count += 1
			if character_id != expected_id:
				return false
	return visible_count == 1


func _find_named(node: Node, target_name: String) -> Node:
	if node == null:
		return null
	if str(node.name) == target_name:
		return node
	for child in node.get_children():
		var found := _find_named(child, target_name)
		if found != null:
			return found
	return null


func _count_buttons_with_text(node: Node, target_text: String) -> int:
	var count := 0
	for child in node.get_children():
		if child is Button and (child as Button).text == target_text:
			count += 1
		count += _count_buttons_with_text(child, target_text)
	return count


func _find_texture_rect(node: Node) -> TextureRect:
	if node == null:
		return null
	for child in node.get_children():
		if child is TextureRect:
			return child as TextureRect
		var found := _find_texture_rect(child)
		if found != null:
			return found
	return null


func _fail(message: String) -> void:
	push_error("SMOKE FAIL: " + message)
	quit(1)
