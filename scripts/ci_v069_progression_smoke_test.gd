extends "res://scripts/ci_v060_progression_smoke_test.gd"

# El smoke completo nació en 0.6 y conserva una guard clause histórica que
# exige 0.6.x. Desde 0.7 seguimos validando exactamente esas mecánicas
# heredadas, así que solo dentro de este proceso headless presentamos 0.6.9 al
# test base aunque la versión real del juego ya sea 0.7, 0.8 o 0.9.
func _initialize() -> void:
	var current_version := str(ProjectSettings.get_setting("application/config/version", ""))
	if current_version.begins_with("0.7.") or current_version.begins_with("0.8.") or current_version.begins_with("0.9."):
		ProjectSettings.set_setting("application/config/version", "0.6.9")
	super()


# Desde 0.9.19 el flujo es: slot -> selección de protagonista -> Portugal ->
# Naranjal Studio -> partida. Ya no existe la pantalla intermedia de 2026.
# El test comprueba el orden sin esperar los temporizadores cinematográficos.
func _validate_new_game_intro(main: Control, transitions: Node) -> bool:
	var new_game := _find_button_with_text(main, "Nueva partida")
	var continue_game := _find_button_with_text(main, "Continuar")
	if new_game == null or not _button_has_callback(new_game, "open_new_game_slots"):
		_fail("Nueva partida no está enlazada al selector de slots 0.7+")
		return false
	if continue_game == null or not _button_has_callback(continue_game, "continue_last_slot"):
		_fail("Continuar no está enlazado al último slot utilizado")
		return false
	if _button_has_callback(new_game, "_begin_new_game") or _button_has_callback(continue_game, "_begin_new_game"):
		_fail("El menú salta el selector de slots o reproduce el preludio al continuar")
		return false

	var character_select := main.get_node_or_null("CharacterSelectManager")
	if character_select == null:
		_fail("No está disponible el selector de protagonista")
		return false

	var menu_screen := main.get("menu_screen") as Control
	var game_screen := main.get("game_screen") as Control
	var ending_screen := main.get("ending_screen") as Control
	var menu_was_visible := menu_screen != null and menu_screen.visible
	var game_was_visible := game_screen != null and game_screen.visible
	var ending_was_visible := ending_screen != null and ending_screen.visible

	character_select.call("_begin_new_game")
	await process_frame
	var flow_screen := character_select.get("flow_screen") as Control
	if flow_screen == null or not flow_screen.visible:
		_fail("Nueva partida no abre la selección de protagonista antes del preludio")
		return false
	if main.get_node_or_null("NewGamePrelude0917") != null:
		_fail("Portugal/Naranjal aparece antes de elegir protagonista")
		return false
	if not bool(character_select.get("_pending_new_game_prelude_0919")):
		_fail("La selección no deja preparado el preludio posterior al protagonista")
		return false

	# Validamos el preludio de forma aislada y adelantamos su final solo en CI.
	intro_callback_called = false
	transitions.call("set_fast_mode", false)
	transitions.call("play_new_game_intro", Callable(self, "_on_intro_finished"))
	await process_frame
	var cinematic := main.get_node_or_null("NewGamePrelude0917")
	if cinematic == null:
		_fail("No se crea el preludio Portugal/Naranjal")
		return false
	if intro_callback_called:
		_fail("El preludio termina antes de reproducirse")
		return false
	cinematic.emit_signal("prelude_finished")
	cinematic.queue_free()
	await process_frame
	await process_frame
	if not intro_callback_called:
		_fail("El preludio no entrega el control al terminar")
		return false
	if bool(transitions.get("waiting_for_continue")) or bool(transitions.get("transition_active")):
		_fail("Sigue existiendo una transición interactiva después del logo de Naranjal")
		return false
	var message_label: Variant = transitions.get("message_label")
	if message_label != null and str(message_label.text) == "Los hechos acontecieron desde 2026.":
		_fail("La pantalla de 2026 sigue presente")
		return false

	# Restauramos la visibilidad previa para no interferir con el resto del smoke.
	flow_screen.visible = false
	if menu_screen != null:
		menu_screen.visible = menu_was_visible
	if game_screen != null:
		game_screen.visible = game_was_visible
	if ending_screen != null:
		ending_screen.visible = ending_was_visible
	return true


# La 0.6.9 mantiene el smoke completo de progreso 0.6, pero el retorno desde
# las localidades temporales ahora es direccional: Triana vuelve por la derecha
# y Monte del Toro por la izquierda. El test heredado llama a este helper para
# ambos casos, así que usamos la alineación del SVG como contrato de dirección.
func _button_at_panel_bottom_right(panel: Control, button: Button) -> bool:
	var panel_rect := panel.get_global_rect()
	var button_rect := button.get_global_rect()
	var at_bottom := panel_rect.encloses(button_rect) \
		and button_rect.get_center().y > panel_rect.get_center().y \
		and panel_rect.end.y - button_rect.end.y <= 40.0
	if not at_bottom or button.icon == null:
		return false
	if button.icon_alignment == HORIZONTAL_ALIGNMENT_RIGHT:
		# Triana -> Naranjal: esquina inferior derecha, flecha a la derecha.
		return panel_rect.end.x - button_rect.end.x <= 40.0
	if button.icon_alignment == HORIZONTAL_ALIGNMENT_LEFT:
		# Monte del Toro -> Naranjal: esquina inferior izquierda, flecha a la izquierda.
		return button_rect.position.x - panel_rect.position.x <= 40.0
	return false
